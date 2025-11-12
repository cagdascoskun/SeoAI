import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';

import '../../features/about/presentation/about_screen.dart';
import '../../features/analysis/presentation/batch_analysis_screen.dart';
import '../../features/analysis/presentation/my_analyses_screen.dart';
import '../../features/analysis/presentation/new_analysis_screen.dart';
import '../../features/analysis/presentation/result_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/credits/presentation/credits_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../providers/app_providers.dart';
import '../../services/supabase_service.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStream = ref.watch(supabaseServiceProvider).authChanges();
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(authStream),
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/analysis/new', builder: (_, __) => const NewAnalysisScreen()),
      GoRoute(path: '/analysis/batch', builder: (_, __) => const BatchAnalysisScreen()),
      GoRoute(path: '/analysis/list', builder: (_, __) => const MyAnalysesScreen()),
      GoRoute(
        path: '/analysis/result/:id',
        builder: (_, state) => ResultScreen(
          analysisId: state.pathParameters['id']!,
          initial: state.extra is AnalysisModel ? state.extra as AnalysisModel : null,
        ),
      ),
      GoRoute(path: '/credits', builder: (_, __) => const CreditsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
    ],
    redirect: (_, state) {
      final loggedIn = authState.asData?.value != null;
      final loggingIn = state.fullPath == '/auth';
      if (!loggedIn) {
        return loggingIn ? null : '/auth';
      }
      if (loggedIn && loggingIn) {
        return '/dashboard';
      }
      return null;
    },
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
