import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'parental_provider.dart';

/// Screen for managing parental controls.
class ParentalControlsScreen extends ConsumerWidget {
  const ParentalControlsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(parentalSettingsProvider);
    final notifier = ref.read(parentalSettingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parental Controls'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Enable toggle
          _SettingsCard(
            child: SwitchListTile(
              title: const Text('Enable Parental Controls'),
              subtitle: Text(
                settings.hasPin
                    ? 'PIN protected'
                    : 'Set a PIN to enable',
              ),
              value: settings.isEnabled,
              onChanged: settings.hasPin
                  ? (value) => notifier.toggleEnabled(value)
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // PIN setup
          _SettingsCard(
            child: ListTile(
              leading: Icon(
                settings.hasPin ? Icons.lock : Icons.lock_open,
                color: settings.hasPin ? scheme.primary : scheme.outline,
              ),
              title: Text(settings.hasPin ? 'Change PIN' : 'Set PIN'),
              subtitle: Text(
                settings.hasPin
                    ? 'Change your 4-digit PIN'
                    : 'Create a 4-digit PIN to protect settings',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPinDialog(context, ref, isChange: settings.hasPin),
            ),
          ),
          const SizedBox(height: 16),

          if (settings.isEnabled) ...[
            // Content restrictions
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Content Restrictions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ..._interests.map((interest) {
                    final isBlocked = settings.blockedInterests.contains(interest);
                    return CheckboxListTile(
                      title: Text(_interestLabel(interest)),
                      subtitle: Text('Block ${_interestLabel(interest).toLowerCase()} content'),
                      value: isBlocked,
                      onChanged: (_) => notifier.toggleBlockedInterest(interest),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Time limits
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Time Limits',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ListTile(
                    title: const Text('Daily limit'),
                    subtitle: Text(
                      settings.maxPlaybackMinutesPerDay > 0
                          ? '${settings.maxPlaybackMinutesPerDay} minutes per day'
                          : 'No limit',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showTimeLimitDialog(context, ref),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Night mode'),
                    subtitle: Text(
                      settings.nightModeEnabled
                          ? 'Blocked ${settings.nightModeStartHour}:00 - ${settings.nightModeEndHour}:00'
                          : 'Allow playback at all hours',
                    ),
                    value: settings.nightModeEnabled,
                    onChanged: (value) => notifier.setNightMode(enabled: value),
                  ),
                  if (settings.nightModeEnabled)
                    ListTile(
                      title: const Text('Night mode hours'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showNightModeDialog(context, ref),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Remove PIN
            if (settings.hasPin)
              _SettingsCard(
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: scheme.error),
                  title: Text(
                    'Remove Parental Controls',
                    style: TextStyle(color: scheme.error),
                  ),
                  subtitle: const Text('Disable all restrictions and remove PIN'),
                  onTap: () => _confirmRemovePin(context, ref),
                ),
              ),
          ],
        ],
      ),
    );
  }

  static const _interests = ['astrology', 'devotion', 'moral', 'kids', 'news'];

  String _interestLabel(String interest) {
    switch (interest) {
      case 'astrology':
        return 'Astrology';
      case 'devotion':
        return 'Devotion';
      case 'moral':
        return 'Moral Stories';
      case 'kids':
        return 'Kids Content';
      case 'news':
        return 'News';
      default:
        return interest;
    }
  }

  void _showPinDialog(BuildContext context, WidgetRef ref, {bool isChange = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PinSetupDialog(isChange: isChange),
    );
  }

  void _showTimeLimitDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(parentalSettingsProvider);
    final notifier = ref.read(parentalSettingsProvider.notifier);

    showDialog(
      context: context,
      builder: (ctx) {
        int selectedMinutes = settings.maxPlaybackMinutesPerDay;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Daily Limit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Set maximum playback time per day'),
                  const SizedBox(height: 16),
                  DropdownButton<int>(
                    value: selectedMinutes,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('No limit')),
                      DropdownMenuItem(value: 30, child: Text('30 minutes')),
                      DropdownMenuItem(value: 60, child: Text('1 hour')),
                      DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                      DropdownMenuItem(value: 120, child: Text('2 hours')),
                      DropdownMenuItem(value: 180, child: Text('3 hours')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedMinutes = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    notifier.setDailyLimit(selectedMinutes);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNightModeDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(parentalSettingsProvider);
    final notifier = ref.read(parentalSettingsProvider.notifier);

    showDialog(
      context: context,
      builder: (ctx) {
        int startHour = settings.nightModeStartHour;
        int endHour = settings.nightModeEndHour;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Night Mode Hours'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Block playback during these hours'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: startHour,
                          decoration: const InputDecoration(labelText: 'Start'),
                          items: List.generate(24, (i) {
                            return DropdownMenuItem(
                              value: i,
                              child: Text('${i.toString().padLeft(2, '0')}:00'),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => startHour = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: endHour,
                          decoration: const InputDecoration(labelText: 'End'),
                          items: List.generate(24, (i) {
                            return DropdownMenuItem(
                              value: i,
                              child: Text('${i.toString().padLeft(2, '0')}:00'),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => endHour = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    notifier.setNightMode(startHour: startHour, endHour: endHour);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmRemovePin(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Parental Controls?'),
        content: const Text(
          'This will remove the PIN and disable all content restrictions. '
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _verifyAndRemovePin(context, ref);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _verifyAndRemovePin(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PinVerifyDialog(
        title: 'Enter PIN to confirm',
        onVerified: null, // Will be handled differently
      ),
    ).then((verified) {
      if (verified == true) {
        ref.read(parentalSettingsProvider.notifier).removePin();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parental controls removed')),
        );
      }
    });
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: child,
    );
  }
}

/// Dialog for setting up or changing PIN.
class PinSetupDialog extends ConsumerStatefulWidget {
  final bool isChange;

  const PinSetupDialog({super.key, this.isChange = false});

  @override
  ConsumerState<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends ConsumerState<PinSetupDialog> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String? _error;
  bool _verifyingCurrent = false;

  @override
  void initState() {
    super.initState();
    _verifyingCurrent = widget.isChange;
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isChange ? 'Change PIN' : 'Set PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_verifyingCurrent) ...[
            const Text('Enter current PIN'),
            const SizedBox(height: 16),
            _PinTextField(controller: _currentPinController),
          ] else ...[
            const Text('Create a 4-digit PIN'),
            const SizedBox(height: 16),
            _PinTextField(
              controller: _newPinController,
              label: 'New PIN',
            ),
            const SizedBox(height: 16),
            _PinTextField(
              controller: _confirmPinController,
              label: 'Confirm PIN',
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _verifyingCurrent ? _verifyCurrentPin : _savePin,
          child: Text(_verifyingCurrent ? 'Next' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _verifyCurrentPin() async {
    final pin = _currentPinController.text;
    if (pin.length != 4) {
      setState(() => _error = 'PIN must be 4 digits');
      return;
    }

    final verified = await ref.read(parentalSettingsProvider.notifier).verifyPin(pin);
    if (verified) {
      setState(() {
        _verifyingCurrent = false;
        _error = null;
      });
    } else {
      setState(() => _error = 'Incorrect PIN');
    }
  }

  Future<void> _savePin() async {
    final newPin = _newPinController.text;
    final confirmPin = _confirmPinController.text;

    if (newPin.length != 4) {
      setState(() => _error = 'PIN must be 4 digits');
      return;
    }

    if (newPin != confirmPin) {
      setState(() => _error = 'PINs do not match');
      return;
    }

    await ref.read(parentalSettingsProvider.notifier).setPin(newPin);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN saved successfully')),
      );
    }
  }
}

/// Dialog for verifying PIN.
class PinVerifyDialog extends ConsumerStatefulWidget {
  final String title;
  final VoidCallback? onVerified;

  const PinVerifyDialog({
    super.key,
    this.title = 'Enter PIN',
    this.onVerified,
  });

  @override
  ConsumerState<PinVerifyDialog> createState() => _PinVerifyDialogState();
}

class _PinVerifyDialogState extends ConsumerState<PinVerifyDialog> {
  final _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PinTextField(controller: _pinController),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _verifyPin,
          child: const Text('Verify'),
        ),
      ],
    );
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text;
    if (pin.length != 4) {
      setState(() => _error = 'PIN must be 4 digits');
      return;
    }

    final verified = await ref.read(parentalSettingsProvider.notifier).verifyPin(pin);
    if (verified) {
      if (widget.onVerified != null) {
        widget.onVerified!();
      }
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() => _error = 'Incorrect PIN');
    }
  }
}

class _PinTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;

  const _PinTextField({required this.controller, this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 4,
      obscureText: true,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        letterSpacing: 8,
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
    );
  }
}
