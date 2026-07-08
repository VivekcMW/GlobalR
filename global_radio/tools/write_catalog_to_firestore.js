#!/usr/bin/env node
/**
 * Writes cdn_dist/catalog.json items into Firestore's `catalog_items`
 * collection, replacing the old "fetch a static catalog.json from a CDN"
 * model with live Firestore documents (see lib/data/repositories/
 * catalog_repository.dart -> FirestoreCatalogSource).
 *
 * Auth: uses the caller's own gcloud credentials (no service account key
 * needed) — same pattern as tools/setup_gcp_backend.sh.
 *
 * Usage:
 *   node tools/write_catalog_to_firestore.js --project=globalir \
 *     --catalog=cdn_dist/catalog.json
 */
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

function arg(name, fallback) {
  const prefix = `--${name}=`;
  const found = process.argv.find((a) => a.startsWith(prefix));
  return found ? found.slice(prefix.length) : fallback;
}

const PROJECT = arg("project");
const CATALOG_PATH = arg("catalog", path.join(__dirname, "..", "cdn_dist", "catalog.json"));
if (!PROJECT) {
  console.error("Usage: node write_catalog_to_firestore.js --project=<gcp-project-id> [--catalog=path]");
  process.exit(1);
}

function accessToken() {
  return execSync("gcloud auth print-access-token", { encoding: "utf8" }).trim();
}

// Converts a plain JS value into a Firestore REST API "Value" message.
function toFirestoreValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === "string") return { stringValue: v };
  if (typeof v === "boolean") return { booleanValue: v };
  if (typeof v === "number") {
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  }
  if (Array.isArray(v)) {
    return { arrayValue: { values: v.map(toFirestoreValue) } };
  }
  if (typeof v === "object") {
    return { mapValue: { fields: toFirestoreFields(v) } };
  }
  throw new Error(`Unsupported value type for Firestore conversion: ${typeof v}`);
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) fields[k] = toFirestoreValue(v);
  return fields;
}

async function writeDoc(token, docId, fields) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/catalog_items/${encodeURIComponent(docId)}`;
  const res = await fetch(url, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields: toFirestoreFields(fields) }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Failed to write ${docId}: ${res.status} ${body}`);
  }
}

async function main() {
  const raw = fs.readFileSync(CATALOG_PATH, "utf8");
  const catalog = JSON.parse(raw);
  const items = catalog.items || [];
  console.log(`Writing ${items.length} catalog item(s) to Firestore project '${PROJECT}'...`);

  const token = accessToken();
  let ok = 0;
  for (const item of items) {
    try {
      await writeDoc(token, item.id, item);
      ok += 1;
      console.log(`  ✓ ${item.id}`);
    } catch (e) {
      console.error(`  ✗ ${item.id}: ${e.message}`);
    }
  }
  console.log(`\nWrote ${ok}/${items.length} items. Catalog version: ${catalog.version}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
