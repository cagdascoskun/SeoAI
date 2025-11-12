import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../services/file_service.dart';
import '../controllers/new_analysis_controller.dart';
import '../../../widgets/futuristic_container.dart';
import '../../../widgets/motion/motion.dart';

class NewAnalysisScreen extends ConsumerStatefulWidget {
  const NewAnalysisScreen({super.key});

  @override
  ConsumerState<NewAnalysisScreen> createState() => _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends ConsumerState<NewAnalysisScreen> {
  PickedFileData? _image;
  int _currentStep = 0;

  Future<void> _pickImage() async {
    final file = await ref.read(fileServiceProvider).pickImage();
    if (file != null) {
      setState(() {
        _image = file;
        _currentStep = 1;
      });
    }
  }

  Future<void> _submit() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }
    final controller = ref.read(newAnalysisControllerProvider.notifier);
    try {
      final analysis = await controller.analyze(_image!);
      if (!mounted) return;
      if (analysis != null) {
        context.push('/analysis/result/${analysis.id}', extra: analysis);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(newAnalysisControllerProvider);
    final creditsState = ref.watch(creditsProvider);
    final credits = creditsState.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final hasCredits = (credits ?? 1) > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('new_analysis')),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/analysis/list'),
            icon: const Icon(Icons.list_alt, color: Colors.white),
            label: const Text(
              'My Analyses',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FilledButton.icon(
          onPressed: (!hasCredits || _image == null || state.isLoading)
              ? null
              : _submit,
          icon: state.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.auto_fix_high),
          label: Text(
            hasCredits ? loc.translate('analyze') : 'Not enough credits',
          ),
        ),
      ),
      body: FuturisticBackground(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                MotionFadeSlide(
                  delay: Motion.stagger(0),
                  child: _StepHeader(currentStep: _currentStep),
                ),
                const SizedBox(height: 16),
                MotionScale(
                  delay: Motion.stagger(1),
                  child: _UploadCard(image: _image, onPick: _pickImage),
                ),
                const SizedBox(height: 16),
                MotionScale(
                  delay: Motion.stagger(2),
                  child: _CreditsCard(
                    creditsState: creditsState,
                    hasCredits: hasCredits,
                  ),
                ),
                const SizedBox(height: 16),
                MotionFadeSlide(
                  delay: Motion.stagger(3),
                  child: _TimelineCard(step: _currentStep),
                ),
              ],
            ),
            if (state.isLoading)
              const ColoredBox(
                color: Color(0x88000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepModel('Upload image', 'Add the primary product photo'),
      _StepModel('AI analysis', 'Generate SEO insights with Vision'),
      _StepModel('Results', 'Titles, keywords, Etsy tags'),
    ];
    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${currentStep + 1} / ${steps.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(steps.length, (index) {
              final active = index <= currentStep;
              return Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsets.only(left: index == 0 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            steps[currentStep.clamp(0, steps.length - 1)].title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            steps[currentStep.clamp(0, steps.length - 1)].subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.onPick, required this.image});

  final VoidCallback onPick;
  final PickedFileData? image;

  @override
  Widget build(BuildContext context) {
    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Upload your image',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onPick,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(18),
                image: image == null
                    ? null
                    : DecorationImage(
                        image: MemoryImage(image!.bytes),
                        fit: BoxFit.cover,
                      ),
              ),
              child: image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.cloud_upload, size: 40),
                        SizedBox(height: 8),
                        Text('Tap or drag & drop'),
                      ],
                    )
                  : null,
            ),
          ),
          if (image != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                image!.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepModel {
  final String title;
  final String subtitle;
  _StepModel(this.title, this.subtitle);
}

class _CreditsCard extends StatelessWidget {
  const _CreditsCard({required this.creditsState, required this.hasCredits});

  final AsyncValue<int> creditsState;
  final bool hasCredits;

  @override
  Widget build(BuildContext context) {
    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2. Credits overview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          creditsState.when(
            data: (value) => Text('Remaining credits: $value'),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Unable to read credits: $error'),
          ),
          if (!hasCredits)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Not enough credits',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final timeline = [
      _TimelineStep('Upload', 'Attach your product photo'),
      _TimelineStep('AI Vision', 'gpt-4o-mini analyzes the details'),
      _TimelineStep('SEO JSON', 'Structured SEO JSON is generated'),
    ];
    return FuturisticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis timeline',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(timeline.length, (index) {
              final item = timeline[index];
              final active = index <= step;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: active
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15)
                      : Colors.grey.shade800,
                  child: Icon(
                    active ? Icons.check : Icons.watch_later_outlined,
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  _TimelineStep(this.title, this.subtitle);
}
