import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:to_do_list/screens/achievements.dart';
import 'package:to_do_list/screens/login.dart';
import 'package:to_do_list/screens/stats.dart';
import 'package:to_do_list/services/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName ?? '').trim();
    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : ((user?.email ?? '?')[0]).toUpperCase();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0066cc),
        foregroundColor: Colors.white,
        elevation: 13,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: CircleAvatar(child: Text(initial)),
              title: Text(name.isEmpty ? 'My account' : name),
              subtitle: Text(user?.email ?? ''),
            ),
            const Divider(),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.mode,
              builder: (context, mode, _) => SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark mode'),
                value: mode == ThemeMode.dark,
                onChanged: (value) => ThemeController.setDark(value),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistics'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Achievements'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AchievementsScreen()),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
