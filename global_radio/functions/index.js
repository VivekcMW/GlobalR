const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const { google } = require("googleapis");

admin.initializeApp();
const db = admin.firestore();

const APPLE_SHARED_SECRET = defineSecret("APPLE_SHARED_SECRET");

// Must match android/app/build.gradle.kts applicationId.
const ANDROID_PACKAGE_NAME = "com.globalradio.global_radio";

/**
 * Verifies a completed store purchase against Google Play / Apple servers and
 * writes the resulting entitlement to Firestore. This is the ONLY code path
 * allowed to set `isPremium` — Firestore rules reject client writes to it.
 *
 * Request data: { platform: 'android'|'ios', productId: string,
 *                  purchaseToken?: string (android), receiptData?: string (ios) }
 */
exports.verifyPurchase = onCall(
  { secrets: [APPLE_SHARED_SECRET], region: "us-central1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const { platform, productId, purchaseToken, receiptData } = request.data ?? {};
    if (!platform || !productId) {
      throw new HttpsError("invalid-argument", "platform and productId are required.");
    }

    let entitlement;
    try {
      if (platform === "android") {
        if (!purchaseToken) {
          throw new HttpsError("invalid-argument", "purchaseToken is required for android.");
        }
        entitlement = await verifyAndroidPurchase(productId, purchaseToken);
      } else if (platform === "ios") {
        if (!receiptData) {
          throw new HttpsError("invalid-argument", "receiptData is required for ios.");
        }
        entitlement = await verifyIosReceipt(receiptData, productId, APPLE_SHARED_SECRET.value());
      } else {
        throw new HttpsError("invalid-argument", `Unsupported platform: ${platform}`);
      }
    } catch (err) {
      if (err instanceof HttpsError) throw err;
      logger.error("Purchase verification failed", { uid, platform, productId, error: String(err) });
      throw new HttpsError("internal", "Could not verify purchase with the store.");
    }

    await db.collection("users").doc(uid).set(
      {
        isPremium: entitlement.isPremium,
        premiumProductId: productId,
        premiumPlatform: platform,
        premiumExpiresAt: entitlement.expiresAt
          ? admin.firestore.Timestamp.fromMillis(entitlement.expiresAt)
          : null,
        premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    logger.info("Entitlement updated", { uid, platform, productId, isPremium: entitlement.isPremium });
    return entitlement;
  }
);

async function androidPublisherClient() {
  const auth = new google.auth.GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  return google.androidpublisher({ version: "v3", auth });
}

/**
 * Tries the subscription API first (v2), falls back to the one-time product
 * API — this way the same callable works whichever way `productId` is
 * actually configured in Play Console, without hardcoding an assumption here.
 */
async function verifyAndroidPurchase(productId, purchaseToken) {
  const publisher = await androidPublisherClient();

  try {
    const res = await publisher.purchases.subscriptionsv2.get({
      packageName: ANDROID_PACKAGE_NAME,
      token: purchaseToken,
    });
    const sub = res.data;
    const activeStates = ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"];
    const isPremium = activeStates.includes(sub.subscriptionState);
    const expiryTime = sub.lineItems?.[0]?.expiryTime;
    return { isPremium, expiresAt: expiryTime ? Date.parse(expiryTime) : undefined };
  } catch (err) {
    const status = err.code || err.response?.status;
    if (status !== 404 && status !== 400) throw err;
    // Not a subscription purchase token — fall through to one-time product check.
  }

  const res = await publisher.purchases.products.get({
    packageName: ANDROID_PACKAGE_NAME,
    productId,
    token: purchaseToken,
  });
  // purchaseState: 0 = purchased, 1 = canceled, 2 = pending.
  const isPremium = res.data.purchaseState === 0;

  if (isPremium && res.data.acknowledgementState === 0) {
    await publisher.purchases.products.acknowledge({
      packageName: ANDROID_PACKAGE_NAME,
      productId,
      token: purchaseToken,
      requestBody: {},
    });
  }

  return { isPremium, expiresAt: undefined };
}

async function verifyIosReceipt(receiptData, productId, sharedSecret) {
  const body = JSON.stringify({
    "receipt-data": receiptData,
    password: sharedSecret,
    "exclude-old-transactions": true,
  });

  let json = await postAppleReceipt("https://buy.itunes.apple.com/verifyReceipt", body);
  // 21007: this receipt is from the sandbox environment; retry there.
  if (json.status === 21007) {
    json = await postAppleReceipt("https://sandbox.itunes.apple.com/verifyReceipt", body);
  }

  if (json.status !== 0) {
    return { isPremium: false, expiresAt: undefined };
  }

  const transactions = json.latest_receipt_info ?? json.receipt?.in_app ?? [];
  const relevant = transactions.filter((t) => t.product_id === productId);
  if (relevant.length === 0) {
    return { isPremium: false, expiresAt: undefined };
  }

  const withExpiry = relevant.filter((t) => t.expires_date_ms);
  if (withExpiry.length > 0) {
    const newest = withExpiry.reduce((a, b) =>
      Number(a.expires_date_ms) > Number(b.expires_date_ms) ? a : b
    );
    const expiresAt = Number(newest.expires_date_ms);
    return { isPremium: expiresAt > Date.now(), expiresAt };
  }

  // No expiry field => non-renewing / one-time in-app purchase.
  return { isPremium: true, expiresAt: undefined };
}

async function postAppleReceipt(url, body) {
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body,
  });
  return res.json();
}
