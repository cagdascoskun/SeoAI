import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(supabaseServiceProvider).authChanges();
});

final creditsProvider = StreamProvider<int>((ref) {
  return ref.watch(supabaseServiceProvider).watchCredits();
});

final analysisListProvider = StreamProvider<List<AnalysisModel>>((ref) {
  return ref.watch(supabaseServiceProvider).watchAnalyses();
});

final analysisDetailProvider = FutureProvider.autoDispose.family<AnalysisModel, String>((ref, id) async {
  return ref.watch(supabaseServiceProvider).fetchAnalysis(id);
});

final competitorItemsProvider = FutureProvider.autoDispose.family<List<CompetitorItem>, String>((ref, analysisId) async {
  return ref.watch(supabaseServiceProvider).fetchCompetitors(analysisId);
});

final batchStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(supabaseServiceProvider).watchBatches();
});
