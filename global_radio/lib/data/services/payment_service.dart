/// Subscription + entitlement abstraction (docs design-and-payments-spec §6-7).
///
/// Platform rule: in-app subscription MUST use Apple IAP / Google Play Billing.
/// Web checkout uses Razorpay UPI AutoPay (~2% vs 15-30%). A purchase alone
/// never grants premium: the receipt/token is sent to the `verifyPurchase`
/// Cloud Function (functions/index.js), which checks it against Google
/// Play / Apple and writes `isPremium` to Firestore. [isPremium] here just
/// mirrors the last server response for immediate UI feedback — the
/// Firestore-backed stream in [UserDbService.watchPremiumStatus] is the
/// actual source of truth the rest of the app should read.
import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class PaymentService {
  bool get isPremium;

  /// Last server-verified entitlement, emitted after every purchase/restore
  /// is checked against the store. UI should prefer this (or the Firestore
  /// stream) over polling [isPremium].
  Stream<bool> get premiumUpdates;

  /// Launches the store purchase sheet. Returns once the flow has been
  /// *started* — completion/verification arrives asynchronously via
  /// [premiumUpdates]. Throws [PaymentException] if it can't even start.
  Future<void> purchaseInApp();

  /// Opens the web checkout (Razorpay UPI AutoPay, best margin). In a real
  /// build this launches the website; entitlement arrives via webhook → cache.
  Future<void> openWebCheckout();

  /// Re-checks past purchases against the store (e.g. on app launch /
  /// resume / "Restore purchases"). Verified results flow through
  /// [premiumUpdates] the same as a fresh purchase.
  Future<void> refreshEntitlement();

  void dispose();
}

class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);
  @override
  String toString() => message;
}

class StorePaymentService implements PaymentService {
  static const String _premiumProductId = 'premium_subscription';

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final _premiumController = StreamController<bool>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _premium = false;

  StorePaymentService() {
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {/* transient store errors; UI drives retries */},
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _premiumController.close();
  }

  @override
  bool get isPremium => _premium;

  @override
  Stream<bool> get premiumUpdates => _premiumController.stream;

  @override
  Future<void> purchaseInApp() async {
    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      throw const PaymentException('Store is unavailable on this device');
    }

    final response = await _iap.queryProductDetails({_premiumProductId});
    if (response.productDetails.isEmpty) {
      throw const PaymentException('Premium product is not configured in the store');
    }

    final purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
    // Fires purchaseStream on completion; entitlement is only granted once
    // _onPurchaseUpdate verifies the receipt with the server.
    final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!started) {
      throw const PaymentException('Could not start the purchase flow');
    }
  }

  @override
  Future<void> openWebCheckout() async {
    final url = Uri.parse('https://globalradio.app/premium');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Future<void> refreshEntitlement() async {
    // Replays past purchases through purchaseStream so they get re-verified.
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyWithServer(purchase);
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
        case PurchaseStatus.pending:
          break;
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Sends the raw receipt/token to the `verifyPurchase` Cloud Function,
  /// which is the only thing allowed to set `isPremium` (Firestore rules
  /// reject the field from clients). Never trusts [PurchaseDetails.status]
  /// alone — that only means the store *reported* a purchase, not that it's
  /// still valid.
  Future<void> _verifyWithServer(PurchaseDetails purchase) async {
    try {
      final platform = (!kIsWeb && Platform.isIOS) ? 'ios' : 'android';
      final data = <String, dynamic>{
        'platform': platform,
        'productId': purchase.productID,
      };
      if (platform == 'android') {
        data['purchaseToken'] = purchase.verificationData.serverVerificationData;
      } else {
        data['receiptData'] = purchase.verificationData.serverVerificationData;
      }

      final result = await _functions.httpsCallable('verifyPurchase').call(data);
      _premium = result.data['isPremium'] == true;
      _premiumController.add(_premium);
    } on FirebaseFunctionsException catch (e) {
      // Leave entitlement unchanged; the Firestore-backed stream stays
      // authoritative and the user can retry via "Restore purchases".
      _premiumController.addError(e);
    }
  }
}
