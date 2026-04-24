import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_badge.dart';
import '../../core/widgets/glass_card.dart';
import '../profile/profile_provider.dart';

class PlayScreen extends ConsumerWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyun Modları'),
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Oyun modları için profil alınamadı: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(profileProvider),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
        data: (profile) {
          final energy = _asInt(profile?['energy']);
          final streak = _asInt(profile?['streak_days']);
          final lastDailyClaim = profile?['last_daily_claim']?.toString();
          final canClaimToday = _canClaimDailyReward(lastDailyClaim);

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(profileProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GlassCard(
                  variant: GlassCardVariant.highlighted,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        child: Icon(Icons.sports_esports_rounded),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Oyun Modları',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enerji: $energy/5 · Seri: $streak gün',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._gameModes.map(
                  (mode) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _GameModeCard(
                      mode: mode,
                      energy: energy,
                      streak: streak,
                      canClaimToday: canClaimToday,
                    ),
                  ),
                ),
                if (energy < 5) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.battery_charging_full_rounded),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Enerji her 30 dakikada yenilenir veya mağazadan doldurulabilir.',
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () => context.push('/shop'),
                          child: const Text('Mağaza'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
}

class _GameMode {
  const _GameMode({
    required this.title,
    required this.description,
    required this.route,
    required this.energyCost,
    required this.rules,
    required this.reward,
    required this.icon,
    required this.color,
    this.duelCta = false,
    this.daily = false,
  });

  final String title;
  final String description;
  final String route;
  final int energyCost;
  final List<String> rules;
  final String reward;
  final IconData icon;
  final Color color;
  final bool duelCta;
  final bool daily;
}

const _gameModes = [
  _GameMode(
    title: 'Milyoner Yarışması',
    description: '15 soru, güvenli noktalar ve jokerlerle ana yarışma.',
    route: '/millionaire',
    energyCost: 1,
    rules: [
      '15 soru, artan zorluk',
      '5. ve 10. soruda güvenli nokta',
      'Yanlış cevapta güvenli ödüle düşersin',
    ],
    reward: '1M puana kadar kazanç',
    icon: Icons.emoji_events_rounded,
    color: Colors.green,
  ),
  _GameMode(
    title: 'Hızlı Maç',
    description: 'Zamana karşı 10 soruluk hızlı yarış.',
    route: '/quick',
    energyCost: 0,
    rules: [
      '10 soru, 120 saniye',
      'Her doğru cevap +100 puan',
      'Yanlış cevapta ceza yok',
    ],
    reward: 'Ücretsiz XP ve coin kazanımı',
    icon: Icons.flash_on_rounded,
    color: Colors.amber,
  ),
  _GameMode(
    title: 'Düello',
    description: 'Mock rakibe karşı 5 soruluk 1v1 bilgi yarışı.',
    route: '/duel',
    energyCost: 1,
    rules: [
      'Aynı 5 soru, 2 oyuncu',
      'Doğru cevap ve hız bonusu puan getirir',
      'Beraberlikte toplam süre belirleyici olur',
    ],
    reward: 'Kazanana XP, coin ve ELO ödülü',
    icon: Icons.sports_martial_arts_rounded,
    color: Colors.deepOrange,
    duelCta: true,
  ),
  _GameMode(
    title: 'Günlük Meydan Okuma',
    description: 'Her gün yeni 5 özel soru.',
    route: '/daily',
    energyCost: 0,
    rules: [
      'Günde 1 kez oynanabilir',
      '5 özel seçilmiş soru',
      'Streak bonusu kazandırır',
    ],
    reward: 'Günlük bonus ve seri çarpanı',
    icon: Icons.calendar_today_rounded,
    color: Colors.purple,
    daily: true,
  ),
  _GameMode(
    title: 'Turnuva Modu',
    description: '3 turlu eleme serisi.',
    route: '/tournament',
    energyCost: 1,
    rules: [
      'Çeyrek final, yarı final, final formatı',
      'Her tur 4 soru içerir',
      'İleri turda zorluk artar',
    ],
    reward: 'Tamamlayana büyük XP ve coin bonusu',
    icon: Icons.military_tech_rounded,
    color: Colors.blue,
  ),
];

class _GameModeCard extends StatelessWidget {
  const _GameModeCard({
    required this.mode,
    required this.energy,
    required this.streak,
    required this.canClaimToday,
  });

  final _GameMode mode;
  final int energy;
  final int streak;
  final bool canClaimToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEnergy = energy >= mode.energyCost;
    final canPlay = mode.energyCost == 0 || hasEnergy;

    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              color: mode.color.withValues(alpha: 0.14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: mode.color.withValues(alpha: 0.20),
                  child: Icon(mode.icon, color: mode.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mode.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(mode.description),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kurallar', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final rule in mode.rules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(rule)),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.surface,
                  ),
                  child: Text('Ödül: ${mode.reward}'),
                ),
                if (mode.daily) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: theme.colorScheme.tertiaryContainer,
                    ),
                    child: Text(
                      canClaimToday
                          ? 'Bugünün serisi için ödül alınabilir. Mevcut seri: $streak gün.'
                          : 'Bugünün serisi korunmuş. Mevcut seri: $streak gün.',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppBadge(
                        label: mode.energyCost == 0
                            ? 'Ücretsiz'
                            : '${mode.energyCost} enerji',
                        tone: canPlay ? AppBadgeTone.primary : AppBadgeTone.danger,
                      ),
                    ),
                    FilledButton(
                      onPressed: canPlay
                          ? () => context.push(mode.route)
                          : null,
                      child: Text(mode.duelCta ? 'Eşleş' : 'Oyna'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
