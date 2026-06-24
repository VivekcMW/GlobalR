import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'mini_player.dart';

/// App shell: persistent bottom nav + a mini-player that floats above it
/// whenever a radio session is active.
class ScaffoldWithNav extends StatelessWidget {
  final StatefulNavigationShell shell;
  const ScaffoldWithNav({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(
              i,
              initialLocation: i == shell.currentIndex,
            ),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.headphones_outlined),
                selectedIcon: Icon(Icons.headphones_rounded),
                label: 'Listen',
              ),
              NavigationDestination(
                icon: Icon(Icons.wb_sunny_outlined),
                selectedIcon: Icon(Icons.wb_sunny),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmarks_outlined),
                selectedIcon: Icon(Icons.bookmarks),
                label: 'Saved',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'You',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
