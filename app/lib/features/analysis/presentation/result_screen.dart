import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_models/shared_models.dart';

import '../../../core/providers/app_providers.dart';
import '../../../widgets/futuristic_container.dart';
import '../../../widgets/motion/motion.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key, required this.analysisId, this.initial});

  final String analysisId;
  final AnalysisModel? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisFuture = ref.watch(analysisDetailProvider(analysisId));
    final analysis = analysisFuture.when(
      data: (value) => value,
      loading: () => initial,
      error: (_, __) => initial,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: analysis?.seoOutput == null
                ? null
                : () {
                    final seo = analysis!.seoOutput!;
                    final text =
                        'Title: ${seo.title}\nKeywords: ${seo.seoKeywords.join(', ')}\nTags: ${seo.etsyTags.join(', ')}\nDescription: ${seo.description}';
                    Share.share(text, subject: seo.title);
                  },
          ),
        ],
      ),
      body: FuturisticBackground(
        child: analysis == null
            ? const Center(
                child: MotionScale(child: CircularProgressIndicator()),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (analysis.imageUrl != null)
                    MotionFadeSlide(
                      child: Hero(
                        tag: 'analysis-image-${analysis.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            analysis.imageUrl!,
                            height: 260,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  MotionScale(
                    child: FuturisticCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            analysis.seoOutput?.title ??
                                'Title is being generated...',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            analysis.seoOutput?.description ??
                                'Description is being generated...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'SEO Keywords',
                    children: analysis.seoOutput?.seoKeywords ?? const [],
                  ),
                  _Section(
                    title: 'Etsy Tags',
                    children: analysis.seoOutput?.etsyTags ?? const [],
                  ),
                ],
              ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<String> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return MotionFadeSlide(
      child: FuturisticCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: children
                  .map((item) => Chip(label: Text(item)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
