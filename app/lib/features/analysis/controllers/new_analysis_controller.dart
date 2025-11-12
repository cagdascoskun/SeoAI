import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../../services/file_service.dart';
import '../../../services/supabase_service.dart';

final newAnalysisControllerProvider =
    AsyncNotifierProvider.autoDispose<NewAnalysisController, AnalysisModel?>(
  NewAnalysisController.new,
);

class NewAnalysisController extends AsyncNotifier<AnalysisModel?> {
  @override
  Future<AnalysisModel?> build() async {
    return null;
  }

  Future<AnalysisModel?> analyze(PickedFileData image) async {
    state = const AsyncLoading();
    try {
      final service = ref.read(supabaseServiceProvider);
      final created = await service.startImageAnalysis(image);
      final completed = await service.waitForAnalysis(created.id);
      state = AsyncData(completed);
      return completed;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
