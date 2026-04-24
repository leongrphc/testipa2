import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ads/ad_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_stat_chip.dart';
import '../../core/widgets/glass_card.dart';
import '../profile/profile_provider.dart';
import '../profile/profile_repository.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;
    final titles = ['Ana Sayfa', 'Profil'];
    final selectedNavIndex = _index == 0 ? 0 : 3;

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            onPressed: _signOut,
            tooltip: 'Çıkış yap',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            _HomeOverview(
              email: user?.email,
              fallbackUsername: user?.userMetadata?['username']?.toString(),
            ),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: selectedNavIndex,
        onTap: (value) {
          switch (value) {
            case 0:
              setState(() => _index = 0);
            case 1:
              context.push('/play');
            case 2:
              context.push('/leaderboard');
            case 3:
              setState(() => _index = 1);
            case 4:
              context.push('/shop');
          }
        },
        items: const [
          AppBottomNavItem(
            icon: Icons.sports_soccer_outlined,
            selectedIcon: Icons.sports_soccer,
            label: 'Ana',
          ),
          AppBottomNavItem(
            icon: Icons.sports_esports_outlined,
            selectedIcon: Icons.sports_esports_rounded,
            label: 'Oyna',
          ),
          AppBottomNavItem(
            icon: Icons.emoji_events_outlined,
            selectedIcon: Icons.emoji_events_rounded,
            label: 'Lig',
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profil',
          ),
          AppBottomNavItem(
            icon: Icons.palette_outlined,
            selectedIcon: Icons.palette_rounded,
            label: 'Shop',
          ),
        ],
      ),
    );
  }
}

class _HomeOverview extends ConsumerWidget {
  const _HomeOverview({required this.email, required this.fallbackUsername});

  final String? email;
  final String? fallbackUsername;

  Future<void> _claimDailyReward(BuildContext context, WidgetRef ref) async {
    try {
      final payload = await profileRepository.claimDailyReward();
      final reward = Map<String, dynamic>.from(
        payload['reward'] as Map? ?? <String, dynamic>{},
      );
      ref.invalidate(profileProvider);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Günlük ödül alındı: +${reward['xp'] ?? 0} XP, +${reward['coins'] ?? 0} coin',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = error.toString().contains('Reward already claimed today')
          ? 'Bugünkü ödül zaten alınmış.'
          : error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _claimAdReward(
    BuildContext context,
    WidgetRef ref,
    String rewardType,
  ) async {
    final adResult = await adService.showRewardedAd(
      placement: 'dashboard_reward',
    );
    if (!context.mounted) {
      return;
    }
    if (!adResult.completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adResult.message ?? 'Reklam tamamlanmadı.')),
      );
      return;
    }

    try {
      await adService.claimReward(rewardType);
      ref.invalidate(profileProvider);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reklam ödülü hesabına işlendi.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Profil özetini alırken hata oluştu: $error'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.invalidate(profileProvider),
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
      data: (profile) {
        final username =
            profile?['username']?.toString() ??
            fallbackUsername ??
            email?.split('@').first ??
            'Oyuncu';
        final energy = _asInt(profile?['energy']);
        final level = _asInt(profile?['level']);
        final coins = _asInt(profile?['coins']);
        final xp = _asInt(profile?['xp']);
        final gems = _asInt(profile?['gems']);
        final correctAnswers = _asInt(profile?['total_correct_answers']);
        final totalAnswered = _asInt(profile?['total_questions_answered']);
        final accuracy = totalAnswered == 0
            ? 0
            : ((correctAnswers / totalAnswered) * 100).round();
        final streak = _asInt(profile?['streak_days']);
        final isPremium = profile?['is_premium'] == true;
        final settings = profile?['settings'] is Map
            ? Map<String, dynamic>.from(profile!['settings'] as Map)
            : <String, dynamic>{};
        final jokers = settings['jokers'] is Map
            ? Map<String, dynamic>.from(settings['jokers'] as Map)
            : <String, dynamic>{};
        final canClaimDailyReward = _canClaimDailyReward(
          profile?['last_daily_claim']?.toString(),
        );
        final nextStreak = _nextStreak(
          profile?['last_daily_claim']?.toString(),
          streak,
        );
        final dailyRewardCoins = 25 + (nextStreak.clamp(0, 30).toInt() * 5);

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(profileProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                variant: GlassCardVariant.highlighted,
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBright.withValues(alpha: 0.18),
                        AppColors.accent.withValues(alpha: 0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppBadge(
                        label: 'Stadium Night',
                        icon: Icons.sports_soccer_rounded,
                        tone: AppBadgeTone.primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Merhaba, $username',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Level $level · ${_formatCompact(xp)} XP · %$accuracy doğruluk',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ChipStat(
                            label: 'Enerji',
                            value: '$energy/5',
                            icon: Icons.bolt_rounded,
                            color: AppColors.gold,
                          ),
                          _ChipStat(
                            label: 'Coin',
                            value: _formatCompact(coins),
                            icon: Icons.monetization_on_rounded,
                            color: AppColors.goldSoft,
                          ),
                          _ChipStat(
                            label: 'Gem',
                            value: _formatCompact(gems),
                            icon: Icons.diamond_rounded,
                            color: AppColors.info,
                          ),
                          _ChipStat(
                            label: 'Doğru',
                            value: '$correctAnswers/$totalAnswered',
                            icon: Icons.track_changes_rounded,
                            color: AppColors.success,
                          ),
                          _ChipStat(
                            label: 'Streak',
                            value: '$streak gün',
                            icon: Icons.local_fire_department_rounded,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _DailyRewardCard(
                canClaim: canClaimDailyReward,
                xp: 50,
                coins: dailyRewardCoins,
                nextStreak: nextStreak,
                onClaim: () => _claimDailyReward(context, ref),
              ),
              const SizedBox(height: 20),
              _JokerInventoryCard(jokers: jokers),
              const SizedBox(height: 20),
              if (!isPremium) ...[
                _RewardedAdCard(
                  onClaim: (rewardType) =>
                      _claimAdReward(context, ref, rewardType),
                ),
                const SizedBox(height: 20),
              ],
              Text('Oyun Modları', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _ModeTile(
                    title: 'Millionaire',
                    description: 'Ana yarışma',
                    badge: '1 ⚡',
                    icon: Icons.emoji_events_rounded,
                    route: '/millionaire',
                  ),
                  _ModeTile(
                    title: 'Quick',
                    description: '10 soru / 120 sn',
                    badge: 'Ücretsiz',
                    icon: Icons.flash_on_rounded,
                    route: '/quick',
                  ),
                  _ModeTile(
                    title: 'Daily',
                    description: 'Bugünün 5 sorusu',
                    badge: 'Günlük',
                    icon: Icons.calendar_today_rounded,
                    route: '/daily',
                  ),
                  _ModeTile(
                    title: 'Düello',
                    description: '1v1 hız maçı',
                    badge: '1 ⚡',
                    icon: Icons.sports_martial_arts_rounded,
                    route: '/duel',
                  ),
                  _ModeTile(
                    title: 'Tournament',
                    description: '3 tur eleme',
                    badge: 'Canlı',
                    icon: Icons.military_tech_rounded,
                    route: '/tournament',
                  ),
                  _ModeTile(
                    title: 'Mağaza',
                    description: 'Tema / frame / joker',
                    badge: 'Shop',
                    icon: Icons.storefront_rounded,
                    route: '/shop',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Rekabet ve Sosyal', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _FeatureStrip(
                title: 'Leaderboard',
                description: 'Genel, millionaire ve düello sıralamalarını gör.',
                icon: Icons.leaderboard_rounded,
                route: '/leaderboard',
              ),
              const SizedBox(height: 12),
              _FeatureStrip(
                title: 'League',
                description: 'Aktif sezonu ve haftalık pozisyonunu takip et.',
                icon: Icons.shield_rounded,
                route: '/league',
              ),
              const SizedBox(height: 12),
              _FeatureStrip(
                title: 'Achievements',
                description: 'Başarım ödüllerini ve açılan rozetleri gör.',
                icon: Icons.workspace_premium_rounded,
                route: '/achievements',
              ),
              const SizedBox(height: 12),
              _FeatureStrip(
                title: 'Social',
                description: 'Arkadaşlar, davetler ve düello girişleri.',
                icon: Icons.groups_rounded,
                route: '/social',
              ),
            ],
          ),
        );
      },
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatCompact(int value) {
    if (value >= 1000000) {
      final compact = value / 1000000;
      return compact % 1 == 0
          ? '${compact.toInt()}M'
          : '${compact.toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      final compact = value / 1000;
      return compact % 1 == 0
          ? '${compact.toInt()}K'
          : '${compact.toStringAsFixed(1)}K';
    }
    return '$value';
  }

  bool _canClaimDailyReward(String? lastClaim) {
    if (lastClaim == null || lastClaim.isEmpty) {
      return true;
    }
    final parsed = DateTime.tryParse(lastClaim);
    if (parsed == null) {
      return true;
    }
    final now = DateTime.now();
    return parsed.year != now.year ||
        parsed.month != now.month ||
        parsed.day != now.day;
  }

  int _nextStreak(String? lastClaim, int currentStreak) {
    if (!_canClaimDailyReward(lastClaim)) {
      return currentStreak;
    }
    final parsed = DateTime.tryParse(lastClaim ?? '');
    if (parsed == null) {
      return 1;
    }
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final lastClaimDay = DateTime(parsed.year, parsed.month, parsed.day);
    return lastClaimDay == yesterday ? currentStreak + 1 : 1;
  }
}

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({
    required this.canClaim,
    required this.xp,
    required this.coins,
    required this.nextStreak,
    required this.onClaim,
  });

  final bool canClaim;
  final int xp;
  final int coins;
  final int nextStreak;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.gold,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.onSecondaryContainer.withValues(
              alpha: 0.10,
            ),
            child: const Icon(Icons.card_giftcard_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canClaim ? 'Günlük Ödülünü Al' : 'Günlük ödül alındı',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('Bugün: +$xp XP, +$coins coin · Streak $nextStreak'),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: canClaim ? onClaim : null,
            child: Text(canClaim ? 'Al' : 'Tamam'),
          ),
        ],
      ),
    );
  }
}

class _RewardedAdCard extends StatelessWidget {
  const _RewardedAdCard({required this.onClaim});

  final ValueChanged<String> onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: const Icon(Icons.play_circle_outline_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rewarded Reklam', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    const Text('İzle, ödülünü al.'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => onClaim('energy_refill'),
                child: const Text('+1 Enerji'),
              ),
              FilledButton.tonal(
                onPressed: () => onClaim('coins_small'),
                child: const Text('+50 Coin'),
              ),
              FilledButton.tonal(
                onPressed: () => onClaim('double_answer_joker'),
                child: const Text('Çift Cevap'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JokerInventoryCard extends StatelessWidget {
  const _JokerInventoryCard({required this.jokers});

  final Map<String, dynamic> jokers;

  static const _items = [
    ('fifty_fifty', '%50', Icons.percent_rounded),
    ('audience', 'Seyirci', Icons.groups_rounded),
    ('phone', 'Telefon', Icons.phone_rounded),
    ('freeze_time', 'Süre', Icons.timer_rounded),
    ('skip', 'Pas', Icons.skip_next_rounded),
    ('double_answer', 'Çift', Icons.copy_rounded),
  ];

  int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Joker Envanteri', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Coin ile alınan ve ödüllerden gelen joker stokların.'),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
            physics: const NeverScrollableScrollPhysics(),
            children: _items.map((item) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: theme.colorScheme.surfaceContainer,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$3, size: 20),
                    const SizedBox(height: 8),
                    Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${_asInt(jokers[item.$1])}',
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppStatChip(label: label, value: value, icon: icon, color: color);
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.description,
    required this.badge,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final String badge;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      onTap: () => context.push(route),
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon),
          ),
          const Spacer(),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          AppBadge(label: badge, tone: AppBadgeTone.primary),
        ],
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
  });

  final String title;
  final String description;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      onTap: () => context.push(route),
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}
