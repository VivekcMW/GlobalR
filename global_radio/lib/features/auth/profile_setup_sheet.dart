import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/providers.dart';

/// Avatar choices — friendly, neutral glyphs.
const kAvatarChoices = [
  '🎧', '🎙️', '🌟', '🦚', '🪔', '🌸',
  '🐯', '🦁', '🐘', '🎵', '☀️', '🌙',
];

/// Display-name field + emoji avatar picker. Reused in onboarding and Settings.
/// Calls [onChanged] with the latest (name, avatar) so the host can enable a
/// Save/Continue action.
class ProfileFields extends StatefulWidget {
  final String? initialName;
  final String? initialAvatar;
  final void Function(String name, String? avatar) onChanged;
  const ProfileFields({
    super.key,
    this.initialName,
    this.initialAvatar,
    required this.onChanged,
  });

  @override
  State<ProfileFields> createState() => _ProfileFieldsState();
}

class _ProfileFieldsState extends State<ProfileFields> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  late String? _avatar = widget.initialAvatar ?? kAvatarChoices.first;

  @override
  void initState() {
    super.initState();
    _name.addListener(_emit);
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  void _emit() => widget.onChanged(_name.text.trim(), _avatar);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Your name',
            hintText: 'e.g. Asha',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 20),
        Text('Pick an avatar', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kAvatarChoices.map((e) {
            final on = e == _avatar;
            return InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => setState(() {
                _avatar = e;
                _emit();
              }),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: on
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Modal bottom sheet to create/edit the display name + avatar. Returns true if
/// saved. Pops on its own [sheetContext] (shell-navigator-safe).
Future<bool?> showProfileSetupSheet(BuildContext context, WidgetRef ref) {
  final profile = ref.read(profileProvider);
  var name = profile.name ?? '';
  String? avatar = profile.avatar;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Make it yours',
                style: Theme.of(sheetContext).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Used only to greet you and personalize the app.',
                style: Theme.of(sheetContext).textTheme.bodySmall),
            const SizedBox(height: 20),
            ProfileFields(
              initialName: profile.name,
              initialAvatar: profile.avatar,
              onChanged: (n, a) {
                name = n;
                avatar = a;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await ref.read(profileProvider.notifier).setProfile(
                        name: name.isEmpty ? null : name,
                        avatar: avatar,
                      );
                  if (sheetContext.mounted) Navigator.pop(sheetContext, true);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
