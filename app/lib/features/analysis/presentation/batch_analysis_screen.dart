import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../services/file_service.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/futuristic_container.dart';

class BatchAnalysisScreen extends ConsumerWidget {
  const BatchAnalysisScreen({super.key});

  Future<void> _upload(WidgetRef ref, BuildContext context) async {
    final file = await ref.read(fileServiceProvider).pickCsv();
    if (file == null) return;
    try {
      await ref.read(supabaseServiceProvider).enqueueBatch(file);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch queued for processing')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(batchStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Batch Analysis')),
      body: FuturisticBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: () => _upload(ref, context),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Upload CSV'),
            ),
            const SizedBox(height: 16),
            batches.when(
              data: (items) => Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FuturisticCard(
                          child: ListTile(
                            title: Text('Batch ${item['id']}'),
                            subtitle: Text('Status: ${item['status']}'),
                            trailing: Text((item['stats'] ?? {}).toString()),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }
}
