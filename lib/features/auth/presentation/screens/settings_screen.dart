import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';

/// Settings screen that provides access to Profile and Group management.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profilo'),
            subtitle: const Text('Gestisci il tuo profilo personale'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.profile),
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Gruppo'),
            subtitle: const Text('Gestisci il gruppo familiare'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.groupDetails),
          ),
        ],
      ),
    );
  }
}
