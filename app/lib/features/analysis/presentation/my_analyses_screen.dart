import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../widgets/futuristic_container.dart';

class MyAnalysesScreen extends ConsumerWidget {
  const MyAnalysesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyses = ref.watch(analysisListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Analyses')),
      body: FuturisticBackground(
        child: analyses.when(
          data: (items) => items.isEmpty
              ? const Center(child: Text('No analyses yet'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final analysis = items[index];
                    return GestureDetector(
                      onTap: () => context.push('/analysis/result/${analysis.id}', extra: analysis),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          image: analysis.imageUrl == null
                              ? null
                              : DecorationImage(image: NetworkImage(analysis.imageUrl!), fit: BoxFit.cover),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(analysis.status.toUpperCase()),
                                backgroundColor: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                analysis.seoOutput?.title ?? 'Analysis in progress',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}
