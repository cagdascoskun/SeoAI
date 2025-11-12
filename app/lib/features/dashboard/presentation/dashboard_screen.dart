import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../widgets/analysis_card.dart';
import '../../../widgets/futuristic_container.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final credits = ref.watch(creditsProvider);
    final analyses = ref.watch(analysisListProvider);

    return Scaffold(
      body: FuturisticBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(analysisListProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                expandedHeight: 160,
                centerTitle: false,
                title: const Text('Dashboard'),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.bottomLeft,
                    child: const Text(
                      'Welcome 👋\nBoost your store with AI SEO Tagger.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.list(
                  children: [
                    _CreditCard(credits: credits, onBuyTap: () => context.push('/credits')),
                    const SizedBox(height: 16),
                    _ActionGrid(loc: loc, onNavigate: (path) => context.push(path)),
                    const SizedBox(height: 24),
                    Text('Latest Analyses', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    analyses.when(
                      data: (list) => list.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('No analyses yet')),
                            )
                          : Column(
                              children: list
                                  .take(10)
                                  .map((analysis) => AnalysisCard(
                                        analysis: analysis,
                                        onTap: () => context.push('/analysis/result/${analysis.id}', extra: analysis),
                                      ))
                                  .toList(),
                            ),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Error: $error'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.credits, required this.onBuyTap});

  final AsyncValue<int> credits;
  final VoidCallback onBuyTap;

  @override
  Widget build(BuildContext context) {
    return FuturisticCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Credit balance', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                credits.when(
                  data: (value) => Text(
                    '$value',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  loading: () => const CircularProgressIndicator(color: Colors.white),
                  error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blueGrey),
            onPressed: onBuyTap,
            child: const Text('Buy credits'),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.loc, required this.onNavigate});

  final AppLocalizations loc;
  final void Function(String path) onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionItem(icon: Icons.add_photo_alternate, label: loc.translate('new_analysis'), path: '/analysis/new'),
      _ActionItem(icon: Icons.list_alt, label: 'My Analyses', path: '/analysis/list'),
      _ActionItem(icon: Icons.table_chart, label: loc.translate('batch_analysis'), path: '/analysis/batch'),
      _ActionItem(icon: Icons.shopping_bag, label: loc.translate('credits'), path: '/credits'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => onNavigate(item.path),
          child: FuturisticCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  child: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.label, style: Theme.of(context).textTheme.titleSmall)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final String path;

  _ActionItem({required this.icon, required this.label, required this.path});
}
