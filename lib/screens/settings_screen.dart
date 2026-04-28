import 'package:flutter/material.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState(),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle between Light and Dark themes'),
                value: AppState().isDarkMode,
                onChanged: (val) {
                  AppState().toggleTheme();
                },
              ),
              SwitchListTile(
                title: const Text('Enable Down Swipe'),
                subtitle: const Text('Allow swiping down on cards (UX demo)'),
                value: AppState().enableDownSwipe,
                onChanged: (val) {
                  AppState().toggleDownSwipe();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
