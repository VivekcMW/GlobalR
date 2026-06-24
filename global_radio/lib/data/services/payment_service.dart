/// Subscription + entitlement abstraction (docs design-and-payments-spec §6-7).
///
/// Platform rule: in-app subscription MUST use Apple IAP / Google Play Billing.
/// Web checkout uses Razorpay UPI AutoPay (~2% vs 15-30%). Entitlement is
/// validated server-side (Cloud Function) and cached locally; this interface is
/// the client read/trigger surface.
///
/// The stub flips a local flag so premium gating is testable end-to-end without
/// store accounts. Replace with [StorePaymentService] + a validation Cloud
/// Function for production — see SETUP.md "Payments".
abstract class PaymentService {
  bool get isPremium;

  /// In-app purchase channel (store billing, 15-30% cut).
  Future<bool> purchaseInApp();

  /// Opens the web checkout (Razorpay UPI AutoPay, best margin). In a real
  /// build this launches the website; entitlement arrives via webhook → cache.
  Future<void> openWebCheckout();

  /// Re-read entitlement (e.g. on app launch / resume).
  Future<void> refreshEntitlement();
}

class StubPaymentService implements PaymentService {
  bool _premium = false;

  @override
  bool get isPremium => _premium;

  @override
  Future<bool> purchaseInApp() async {
    // Simulated success — wire real in_app_purchase here.
    _premium = true;
    return true;
  }

  @override
  Future<void> openWebCheckout() async {
    // Wire url_launcher → https://globalradio.app/premium (Razorpay).
  }

  @override
  Future<void> refreshEntitlement() async {
    // Wire: read {isPremium} from Firestore user doc (server-validated).
  }
}
