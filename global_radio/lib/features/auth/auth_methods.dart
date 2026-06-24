import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/providers.dart';

/// The shared sign-in surface: Google + (iOS) Apple + Phone/OTP. Embedded both
/// in the full-screen [SignInScreen] and the optional onboarding step.
///
/// On a successful sign-in it calls [onSignedIn] so the host can advance / pop.
class AuthMethods extends ConsumerStatefulWidget {
  final VoidCallback onSignedIn;
  const AuthMethods({super.key, required this.onSignedIn});

  @override
  ConsumerState<AuthMethods> createState() => _AuthMethodsState();
}

class _AuthMethodsState extends ConsumerState<AuthMethods> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  String? _verificationId; // set once a code has been "sent"
  bool _busy = false;
  String? _error;

  bool get _showApple => !kIsWeb && Platform.isIOS;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) widget.onSignedIn();
    } on Object catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendOtp() async {
    final phone = _phone.text.trim();
    if (phone.length < 8) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await ref.read(authControllerProvider.notifier).sendOtp(phone);
      if (mounted) setState(() => _verificationId = id);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authControllerProvider.notifier);
    return AbsorbPointer(
      absorbing: _busy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SocialButton(
            icon: Icons.g_mobiledata,
            label: 'Continue with Google',
            onPressed: () => _run(auth.signInWithGoogle),
          ),
          if (_showApple) ...[
            const SizedBox(height: 12),
            _SocialButton(
              icon: Icons.apple,
              label: 'Continue with Apple',
              onPressed: () => _run(auth.signInWithApple),
            ),
          ],
          const SizedBox(height: 20),
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: Theme.of(context).textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),
          if (_verificationId == null) ...[
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '+91 98765 43210',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _sendOtp,
              child: const Text('Send code'),
            ),
          ] else ...[
            Text('Enter the 6-digit code sent to ${_phone.text.trim()}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Verification code',
                prefixIcon: Icon(Icons.sms_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _run(() => auth.verifyOtp(
                    _verificationId!,
                    _otp.text.trim(),
                    phone: _phone.text.trim(),
                  )),
              child: const Text('Verify & continue'),
            ),
            TextButton(
              onPressed: () => setState(() {
                _verificationId = null;
                _otp.clear();
              }),
              child: const Text('Change number'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_busy) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _SocialButton(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: onPressed,
    );
  }
}
