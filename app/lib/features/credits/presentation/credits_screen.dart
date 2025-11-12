import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/supabase_service.dart';
import '../../../widgets/futuristic_container.dart';

class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  Future<void> _launchCheckout(BuildContext context, WidgetRef ref, CreditPackage pkg) async {
    try {
      final url = await ref.read(supabaseServiceProvider).buildCheckoutUrl(pkg.id);
      if (!context.mounted) return;
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Checkout could not be opened');
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credit Packs')),
      body: FuturisticBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: CreditPackage.defaults
              .map(
                (pkg) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FuturisticCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(pkg.title, style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text('${pkg.credits} credits • ${pkg.description}'),
                      trailing: FilledButton(
                        onPressed: () => _launchCheckout(context, ref, pkg),
                        child: const Text('Buy'),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
