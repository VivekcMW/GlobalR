#!/usr/bin/env bash
#
# Provisions the GCP/Firebase backend this app needs beyond `flutterfire
# configure` (run tools/setup_firebase.sh FIRST — it creates the Firebase
# project and native config files this script assumes already exist):
#
#   1. Adds Firebase to the GCP project (no-op if already a Firebase project)
#   2. Creates the Firestore database (Native mode, free tier — no billing
#      account required)
#   3. Deploys firestore.rules (locks the premium-entitlement fields to
#      server-only writes)
#   4. Optionally deploys the `verifyPurchase` Cloud Function that validates
#      Google Play / App Store purchases server-side (requires a billing
#      account on the project — the script will tell you if that's missing
#      and let you finish the rest of the setup without it)
#
# Every step is idempotent — safe to re-run if it fails partway or you add
# billing later and want to finish step 4.
#
# Run from the global_radio/ directory: bash tools/setup_gcp_backend.sh

set -euo pipefail
BLUE='\033[1;34m'; YELLOW='\033[1;33m'; GREEN='\033[1;32m'; RED='\033[1;31m'; NC='\033[0m'
step() { echo -e "\n${BLUE}==> $1${NC}"; }
todo() { echo -e "${YELLOW}   MANUAL: $1${NC}"; }
ok()   { echo -e "${GREEN}   $1${NC}"; }
fail() { echo -e "${RED}   ERROR: $1${NC}"; exit 1; }

command -v gcloud >/dev/null 2>&1 || fail "gcloud CLI not found. Install: https://cloud.google.com/sdk/docs/install"
command -v node >/dev/null 2>&1 || fail "Node.js not found (needed to build API requests and deploy the function)."
command -v curl >/dev/null 2>&1 || fail "curl not found."

# --- small JSON helpers (node, so this has no extra dependency beyond what
# the Cloud Function deploy step already needs) -----------------------------
json_field() { # json_field '<json>' 'fieldName' -> value or ''
  node -e "try{const j=JSON.parse(process.argv[1]);const v=j[process.argv[2]];console.log(v===undefined?'':v)}catch(e){console.log('')}" "$1" "$2"
}
json_error_status() { # json_error_status '<json>' -> error.status or ''
  node -e "try{const j=JSON.parse(process.argv[1]);console.log((j.error&&j.error.status)||'')}catch(e){console.log('')}" "$1"
}

step "0. Sign in to Google Cloud"
gcloud auth print-access-token >/dev/null 2>&1 || gcloud auth login
access_token() { gcloud auth print-access-token; }

step "1. Which Firebase/GCP project?"
DEFAULT_PROJECT=""
if [ -f .firebaserc ]; then
  DEFAULT_PROJECT=$(node -e "try{console.log(require('./.firebaserc').projects.default)}catch(e){console.log('')}")
fi
read -rp "Project ID${DEFAULT_PROJECT:+ [$DEFAULT_PROJECT]}: " PROJECT_ID
PROJECT_ID="${PROJECT_ID:-$DEFAULT_PROJECT}"
[ -n "$PROJECT_ID" ] || fail "A project ID is required. Run tools/setup_firebase.sh first if you haven't created one."
gcloud config set project "$PROJECT_ID" >/dev/null
ok "Using project: $PROJECT_ID"

step "2. Add Firebase to this GCP project (no-op if already added)"
ADD_FIREBASE=$(curl -s -X POST "https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}:addFirebase" \
  -H "Authorization: Bearer $(access_token)" -H "x-goog-user-project: ${PROJECT_ID}" -H "Content-Type: application/json" -d '{}')
STATUS=$(json_error_status "$ADD_FIREBASE")
if [ -n "$STATUS" ] && [ "$STATUS" != "ALREADY_EXISTS" ]; then
  echo "$ADD_FIREBASE"; fail "Could not add Firebase to $PROJECT_ID."
fi
ok "Firebase is enabled on $PROJECT_ID."

step "3. Enable Firestore + Play Developer APIs (free — no billing required)"
gcloud services enable firestore.googleapis.com androidpublisher.googleapis.com --project="$PROJECT_ID"
ok "APIs enabled."

step "4. Create the Firestore database (Native mode, free tier)"
EXISTING_DB=$(curl -s -X GET \
  "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)" \
  -H "Authorization: Bearer $(access_token)")
if [ -n "$(json_field "$EXISTING_DB" "name")" ]; then
  ok "Firestore database already exists — skipping creation."
else
  read -rp "Firestore region [us-central1]: " REGION
  REGION="${REGION:-us-central1}"
  # NOTE: no x-goog-user-project header here — adding it makes this specific
  # API re-evaluate full billing preconditions instead of using the free-tier
  # allowance new projects get, and creation then fails asking for billing.
  DB_RESULT=$(curl -s -X POST \
    "https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases?databaseId=(default)" \
    -H "Authorization: Bearer $(access_token)" -H "Content-Type: application/json" \
    -d "{\"type\":\"FIRESTORE_NATIVE\",\"locationId\":\"${REGION}\"}")
  STATUS=$(json_error_status "$DB_RESULT")
  if [ -n "$STATUS" ] && [ "$STATUS" != "ALREADY_EXISTS" ]; then
    echo "$DB_RESULT"; fail "Firestore database creation failed."
  fi
  ok "Firestore database ready in $REGION."
fi

step "5. Deploy firestore.rules"
[ -f "firestore.rules" ] || fail "firestore.rules not found — run this from the global_radio/ directory."
RULESET_BODY=$(node -e "const fs=require('fs');console.log(JSON.stringify({source:{files:[{name:'firestore.rules',content:fs.readFileSync('firestore.rules','utf8')}]}}))")
RULESET=$(curl -s -X POST "https://firebaserules.googleapis.com/v1/projects/${PROJECT_ID}/rulesets" \
  -H "Authorization: Bearer $(access_token)" -H "x-goog-user-project: ${PROJECT_ID}" -H "Content-Type: application/json" \
  -d "$RULESET_BODY")
RULESET_NAME=$(json_field "$RULESET" "name")
[ -n "$RULESET_NAME" ] || { echo "$RULESET"; fail "Could not create the Firestore ruleset."; }

RELEASE_NAME="projects/${PROJECT_ID}/releases/cloud.firestore"
CREATE_BODY=$(node -e "console.log(JSON.stringify({name:process.argv[1],rulesetName:process.argv[2]}))" "$RELEASE_NAME" "$RULESET_NAME")
RELEASE_RESULT=$(curl -s -X POST "https://firebaserules.googleapis.com/v1/projects/${PROJECT_ID}/releases" \
  -H "Authorization: Bearer $(access_token)" -H "x-goog-user-project: ${PROJECT_ID}" -H "Content-Type: application/json" \
  -d "$CREATE_BODY")
STATUS=$(json_error_status "$RELEASE_RESULT")
if [ "$STATUS" = "ALREADY_EXISTS" ]; then
  # Release already exists (re-run) — update it to point at the new ruleset.
  # UpdateRelease expects the resource nested under "release", not inline.
  UPDATE_BODY=$(node -e "console.log(JSON.stringify({release:{name:process.argv[1],rulesetName:process.argv[2]}}))" "$RELEASE_NAME" "$RULESET_NAME")
  RELEASE_RESULT=$(curl -s -X PATCH "https://firebaserules.googleapis.com/v1/${RELEASE_NAME}" \
    -H "Authorization: Bearer $(access_token)" -H "x-goog-user-project: ${PROJECT_ID}" -H "Content-Type: application/json" \
    -d "$UPDATE_BODY")
  STATUS=$(json_error_status "$RELEASE_RESULT")
fi
[ -z "$STATUS" ] || { echo "$RELEASE_RESULT"; fail "Could not publish Firestore rules."; }
ok "Firestore security rules are live."

step "6. Server-side purchase verification (Cloud Function) — optional"
BILLING_ENABLED=$(gcloud beta billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" 2>/dev/null || echo "False")
if [ "$BILLING_ENABLED" != "True" ]; then
  todo "Billing is not enabled on $PROJECT_ID. verifyPurchase needs it (Cloud Run /"
  echo "          Cloud Build / Artifact Registry / Secret Manager all require billing)."
  echo "          Enable it at: https://console.cloud.google.com/billing/linkedaccount?project=${PROJECT_ID}"
  read -rp "   Press Enter once billing is enabled to continue, or type 'skip' to finish this later: " CONT
  if [ "$CONT" != "skip" ]; then
    BILLING_ENABLED=$(gcloud beta billing projects describe "$PROJECT_ID" --format="value(billingEnabled)" 2>/dev/null || echo "False")
  fi
fi

if [ "$BILLING_ENABLED" = "True" ]; then
  step "6a. Enable Cloud Functions infra"
  gcloud services enable cloudfunctions.googleapis.com cloudbuild.googleapis.com \
    artifactregistry.googleapis.com run.googleapis.com secretmanager.googleapis.com \
    iam.googleapis.com --project="$PROJECT_ID"

  step "6b. Create the play-billing-verifier service account"
  SA_EMAIL="play-billing-verifier@${PROJECT_ID}.iam.gserviceaccount.com"
  if ! gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
    gcloud iam service-accounts create play-billing-verifier \
      --display-name="Play Billing Verifier" --project="$PROJECT_ID"
  fi
  ok "Service account: $SA_EMAIL"

  step "6c. Apple in-app-purchase shared secret (leave blank to skip iOS verification for now)"
  read -rsp "   App Store Connect shared secret: " APPLE_SECRET; echo
  DEPLOY_ARGS=(--gen2 --runtime=nodejs20 --region=us-central1 --source=functions \
    --entry-point=verifyPurchase --trigger-http --no-allow-unauthenticated \
    --service-account="$SA_EMAIL" --project="$PROJECT_ID")
  if [ -n "$APPLE_SECRET" ]; then
    if gcloud secrets describe apple-shared-secret --project="$PROJECT_ID" >/dev/null 2>&1; then
      printf '%s' "$APPLE_SECRET" | gcloud secrets versions add apple-shared-secret --project="$PROJECT_ID" --data-file=-
    else
      printf '%s' "$APPLE_SECRET" | gcloud secrets create apple-shared-secret --project="$PROJECT_ID" --data-file=-
    fi
    gcloud secrets add-iam-policy-binding apple-shared-secret --project="$PROJECT_ID" \
      --member="serviceAccount:${SA_EMAIL}" --role="roles/secretmanager.secretAccessor" >/dev/null
    DEPLOY_ARGS+=(--set-secrets="APPLE_SHARED_SECRET=apple-shared-secret:latest")
    ok "Apple shared secret stored in Secret Manager."
  else
    todo "Skipped — Apple purchases won't verify until you run:"
    echo "          echo -n YOUR_SECRET | gcloud secrets create apple-shared-secret --project=${PROJECT_ID} --data-file=-"
    echo "          gcloud secrets add-iam-policy-binding apple-shared-secret --project=${PROJECT_ID} \\"
    echo "            --member=serviceAccount:${SA_EMAIL} --role=roles/secretmanager.secretAccessor"
    echo "          then re-run this script to redeploy with the secret attached."
  fi

  step "6d. Deploy verifyPurchase"
  (cd functions && npm install --no-fund --no-audit)
  gcloud functions deploy verifyPurchase "${DEPLOY_ARGS[@]}"
  ok "verifyPurchase deployed."

  echo
  todo "Play Console → Setup → API access → link project '${PROJECT_ID}', then grant"
  echo "          ${SA_EMAIL} the 'View financial data' + 'Manage orders and"
  echo "          subscriptions' permissions. This step has no CLI/API equivalent —"
  echo "          Play Console requires it to be done by hand."
else
  todo "Skipped the Cloud Function. Re-run this script after enabling billing to"
  echo "          finish server-side purchase verification (steps 1-5 above will"
  echo "          just no-op since they're already done)."
fi

echo -e "\n${GREEN}Backend setup complete.${NC}"
