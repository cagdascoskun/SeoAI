import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../../../widgets/futuristic_container.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FuturisticBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FuturisticCard(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(user?.email ?? ''),
                subtitle: const Text('Profile'),
              ),
            ),
            const SizedBox(height: 12),
            FuturisticCard(
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
                  await ref.read(supabaseServiceProvider).signOut();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
