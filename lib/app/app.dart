import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/supabase/supabase_provider.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/auth_screen.dart';
import '../features/achievements/achievements_screen.dart';
import '../features/daily/daily_screen.dart';
import '../features/duel/duel_screen.dart';
import '../features/home/home_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/league/league_screen.dart';
import '../features/millionaire/millionaire_screen.dart';
import '../features/play/play_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/quick/quick_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/social/social_screen.dart';
import '../features/tournament/tournament_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authChanges = AppConfig.isSupabaseConfigured
      ? ref.watch(authStateChangesProvider)
      : const Stream<Session?>.empty();

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authChanges),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/play', builder: (context, state) => const PlayScreen()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/millionaire',
        builder: (context, state) => const MillionaireScreen(),
      ),
      GoRoute(path: '/quick', builder: (context, state) => const QuickScreen()),
      GoRoute(path: '/duel', builder: (context, state) => const DuelScreen()),
      GoRoute(path: '/daily', builder: (context, state) => const DailyScreen()),
      GoRoute(path: '/shop', builder: (context, state) => const ShopScreen()),
      GoRoute(path: '/themes', builder: (context, state) => const ShopScreen()),
      GoRoute(
        path: '/tournament',
        builder: (context, state) => const TournamentScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/league',
        builder: (context, state) => const LeagueScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/social',
        builder: (context, state) => const SocialScreen(),
      ),
      GoRoute(
        path: '/config',
        builder: (context, state) => const _ConfigurationScreen(),
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;

      if (!AppConfig.isSupabaseConfigured) {
        return location == '/config' ? null : '/config';
      }

      final hasSession = supabaseClient.auth.currentSession != null;
      final goingToAuth = location == '/auth';

      if (!hasSession && !goingToAuth) {
        return '/auth';
      }

      if (hasSession && (goingToAuth || location == '/config')) {
        return '/';
      }

      return null;
    },
  );
});

class FutbolBilgiMobileApp extends ConsumerWidget {
  const FutbolBilgiMobileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Futbol Bilgi Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _ConfigurationScreen extends StatelessWidget {
  const _ConfigurationScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yapılandırma eksik',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Uygulamanın açılması için aşağıdaki dart-define değerlerini vermen gerekiyor:',
                      ),
                      const SizedBox(height: 16),
                      for (final key in AppConfig.missingConfiguration)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• $key',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'API_BASE_URL şu an ${AppConfig.apiBaseUrl} olarak çözülüyor. Gerçek cihazda localhost yerine makinenin LAN IP adresini kullan.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
