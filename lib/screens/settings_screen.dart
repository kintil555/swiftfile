import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final downloadDirProvider = StateProvider<String>((ref) => 'Downloads');

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: 'Transfer', children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Download Folder'),
              subtitle: Text(ref.watch(downloadDirProvider)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Parallel Chunks'),
              subtitle: const Text('4 chunks (IDM-style, faster for large files)'),
            ),
          ]),
          _Section(title: 'Network', children: [
            ListTile(
              leading: const Icon(Icons.wifi),
              title: const Text('WiFi Port'),
              subtitle: const Text('54321'),
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Firewall Help'),
              subtitle: const Text('Allow port 54321 in Windows Firewall'),
            ),
          ]),
          _Section(title: 'About', children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('SwiftShare'),
              subtitle: const Text('v1.0.0 — Fast cross-platform file sharing'),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 0, 4),
          child: Text(title,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold)),
        ),
        Card(child: Column(children: children)),
        const SizedBox(height: 8),
      ],
    );
  }
}
