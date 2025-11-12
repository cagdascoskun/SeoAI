import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'file_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(Supabase.instance.client);
});

class SupabaseService {
  SupabaseService(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  SupabaseClient get client => _client;

  Stream<User?> authChanges() async* {
    yield _client.auth.currentUser;
    yield* _client.auth.onAuthStateChange.map((event) => event.session?.user);
  }

  Future<void> signInWithPassword(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithPassword(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Stream<int> watchCredits() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _client
        .from('credits')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', user.id)
        .map((rows) => rows.isEmpty ? 0 : rows.first['balance'] as int? ?? 0);
  }

  Stream<List<AnalysisModel>> watchAnalyses() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _client
        .from('analyses')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => AnalysisModel.fromJson(row)).toList());
  }

  Future<AnalysisModel> fetchAnalysis(String id) async {
    final row = await _client.from('analyses').select().eq('id', id).single();
    return AnalysisModel.fromJson(row);
  }

  Future<List<CompetitorItem>> fetchCompetitors(String analysisId) async {
    final rows = await _client.from('competitor_items').select().eq('analysis_id', analysisId);
    return rows.map<CompetitorItem>((row) => CompetitorItem.fromJson(row)).toList();
  }

  Stream<List<Map<String, dynamic>>> watchBatches() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _client
        .from('batches')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
  }

  Future<AnalysisModel> startImageAnalysis(PickedFileData image) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Session not found');

    final signedUrl = await _uploadImage(user.id, image);

    final inserted = await _client
        .from('analyses')
        .insert({
          'user_id': user.id,
          'image_url': signedUrl,
          'status': 'processing',
        })
        .select()
        .single();
    final analysis = AnalysisModel.fromJson(inserted);

    await _invokeFunction('analyze-image', {
      'analysis_id': analysis.id,
      'image_url': signedUrl,
      'user_id': user.id,
    });

    return analysis;
  }

  Future<AnalysisModel> waitForAnalysis(String analysisId) async {
    for (var i = 0; i < 90; i++) {
      final current = await fetchAnalysis(analysisId);
      if (current.status == 'done' && current.seoOutput != null) {
        return current;
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    throw Exception('Analysis timed out');
  }

  Future<String> enqueueBatch(PickedFileData csvData) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Session not found');
    final storage = _client.storage.from('batch-imports');
    final path = 'user-${user.id}/${_uuid.v4()}-${csvData.name}';
    await storage.uploadBinary(path, csvData.bytes, fileOptions: FileOptions(contentType: csvData.mimeType, upsert: true));
    final signed = await storage.createSignedUrl(path, 60 * 60 * 24);

    final batch = await _client
        .from('batches')
        .insert({
          'user_id': user.id,
          'status': 'queued',
          'file_url': signed,
        })
        .select()
        .single();

    await _invokeFunction('batch-dispatcher', {
      'user_id': user.id,
      'batch_id': batch['id'],
      'file_url': signed,
    });

    return batch['id'] as String;
  }

  Future<String> buildCheckoutUrl(String variantId) async {
    final user = _client.auth.currentUser;
    final email = user?.email ?? '';
    final uri = Uri.https('checkout.lemonsqueezy.com', '/buy/$variantId', {
      'checkout[email]': email,
    });
    return uri.toString();
  }

  Future<String> _uploadImage(String userId, PickedFileData file) async {
    final storage = _client.storage.from('product-images');
    final path = 'user-$userId/${DateTime.now().millisecondsSinceEpoch}-${file.name}';
    await storage.uploadBinary(path, file.bytes, fileOptions: FileOptions(contentType: file.mimeType, upsert: true));
    final signed = await storage.createSignedUrl(path, 60 * 60 * 24 * 7);
    return signed;
  }

  Future<void> _invokeFunction(String name, Map<String, dynamic> body) async {
    try {
      await _client.functions.invoke(name, body: body);
    } catch (error) {
      throw Exception('Function $name failed: $error');
    }
  }
}
