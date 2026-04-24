import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/glass_card.dart';
import '../league/league_repository.dart';
import '../profile/profile_provider.dart';
import 'achievements_repository.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final season = await leagueRepository.fetchCurrentSeason();
    final entries = await leagueRepository.fetchEntries(
      seasonId: season?['id']?.toString(),
    );
    final payload = await achievementsRepository.syncAchievements(
      leagueEntries: entries,
      currentSeasonId: season?['id']?.toString(),
    );
    ref.invalidate(profileProvider);
    return payload;
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Achievement senkronu başarısız: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            );
          }

          final payload = snapshot.data ?? <String, dynamic>{};
          final unlocked =
              (payload['newlyUnlocked'] as List<dynamic>? ?? const [])
                  .map((e) => e.toString())
                  .toList();
          final rewards = Map<String, dynamic>.from(
            payload['rewards'] as Map? ?? <String, dynamic>{},
          );
          final profile = Map<String, dynamic>.from(
            payload['profile'] as Map? ?? <String, dynamic>{},
          );
          final achievementCards = _achievementDefinitions
              .map(
                (definition) => _AchievementProgress(
                  definition: definition,
                  progress: _progressFor(definition, profile),
                  newlyUnlocked: unlocked.contains(definition.id),
                ),
              )
              .toList();
          final completedCount = achievementCards
              .where((item) => item.completed)
              .length;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GlassCard(
                variant: GlassCardVariant.highlighted,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Başarımlar', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      '$completedCount/${_achievementDefinitions.length} başarım tamamlandı.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yeni açılan: ${unlocked.isEmpty ? 'Yok' : unlocked.map(_achievementTitle).join(', ')}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _RewardCard(
                    label: 'Coin',
                    value: '+${_asInt(rewards['coins'])}',
                    icon: Icons.monetization_on_rounded,
                  ),
                  _RewardCard(
                    label: 'Gem',
                    value: '+${_asInt(rewards['gems'])}',
                    icon: Icons.diamond_rounded,
                  ),
                  _RewardCard(
                    label: 'XP',
                    value: '+${_asInt(rewards['xp'])}',
                    icon: Icons.auto_awesome_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Katalog', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...achievementCards.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AchievementCard(item: item),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _reload,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Başarımları Yeniden Senkronla'),
              ),
            ],
          );
        },
      ),
    );
  }

  int _progressFor(
    _AchievementDefinition definition,
    Map<String, dynamic> profile,
  ) {
    return switch (definition.id) {
      'ilk_adim' => _asInt(profile['total_questions_answered']),
      'mukemmel_10' ||
      'bilgi_krali' => _asInt(profile['total_correct_answers']),
      'streak_ustasi' => _asInt(profile['streak_days']),
      'duello_sampiyonu' => _asInt(profile['duel_wins']),
      'milyoner' => _asInt(profile['best_millionaire_score']),
      'hiz_seytani' => _asInt(profile['fast_correct_answers']),
      'sosyal_kelebek' => _asInt(profile['friends_count']),
      _ => 0,
    };
  }
}

class _AchievementDefinition {
  const _AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.rarity,
    required this.coins,
    required this.gems,
    required this.xp,
    required this.target,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String rarity;
  final int coins;
  final int gems;
  final int xp;
  final int target;
  final IconData icon;
}

class _AchievementProgress {
  const _AchievementProgress({
    required this.definition,
    required this.progress,
    required this.newlyUnlocked,
  });

  final _AchievementDefinition definition;
  final int progress;
  final bool newlyUnlocked;

  bool get completed => newlyUnlocked || progress >= definition.target;
  double get ratio => definition.target <= 0
      ? 0
      : (progress / definition.target).clamp(0, 1).toDouble();
}

const _achievementDefinitions = [
  _AchievementDefinition(
    id: 'ilk_adim',
    title: 'İlk Adım',
    description: 'İlk sorunu cevapla.',
    category: 'Starter',
    rarity: 'Bronze',
    coins: 50,
    gems: 0,
    xp: 10,
    target: 1,
    icon: Icons.flag_rounded,
  ),
  _AchievementDefinition(
    id: 'mukemmel_10',
    title: 'Müthiş 10',
    description: 'Toplam 10 doğru cevap ver.',
    category: 'Mastery',
    rarity: 'Silver',
    coins: 200,
    gems: 0,
    xp: 30,
    target: 10,
    icon: Icons.check_circle_rounded,
  ),
  _AchievementDefinition(
    id: 'bilgi_krali',
    title: 'Bilgi Kralı',
    description: 'Toplam 100 doğru cevaba ulaş.',
    category: 'Mastery',
    rarity: 'Gold',
    coins: 500,
    gems: 0,
    xp: 100,
    target: 100,
    icon: Icons.workspace_premium_rounded,
  ),
  _AchievementDefinition(
    id: 'streak_ustasi',
    title: 'Streak Ustası',
    description: '7 günlük giriş serisi yakala.',
    category: 'Streak',
    rarity: 'Gold',
    coins: 300,
    gems: 5,
    xp: 75,
    target: 7,
    icon: Icons.local_fire_department_rounded,
  ),
  _AchievementDefinition(
    id: 'duello_sampiyonu',
    title: 'Düello Şampiyonu',
    description: '5 düello kazan.',
    category: 'Duel',
    rarity: 'Gold',
    coins: 500,
    gems: 0,
    xp: 100,
    target: 5,
    icon: Icons.sports_martial_arts_rounded,
  ),
  _AchievementDefinition(
    id: 'hiz_seytani',
    title: 'Hız Şeytanı',
    description: '5 hızlı doğru cevap ver.',
    category: 'Speed',
    rarity: 'Silver',
    coins: 200,
    gems: 0,
    xp: 40,
    target: 5,
    icon: Icons.bolt_rounded,
  ),
  _AchievementDefinition(
    id: 'sosyal_kelebek',
    title: 'Sosyal Kelebek',
    description: '3 arkadaş ekle.',
    category: 'Social',
    rarity: 'Silver',
    coins: 150,
    gems: 0,
    xp: 30,
    target: 3,
    icon: Icons.group_rounded,
  ),
  _AchievementDefinition(
    id: 'milyoner',
    title: 'Milyoner',
    description: 'Milyoner modunda 1.000.000 puana ulaş.',
    category: 'Mastery',
    rarity: 'Platinum',
    coins: 1000,
    gems: 10,
    xp: 250,
    target: 1000000,
    icon: Icons.emoji_events_rounded,
  ),
];

String _achievementTitle(String id) {
  for (final definition in _achievementDefinitions) {
    if (definition.id == id) return definition.title;
  }
  return id;
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const Spacer(),
          Text(value, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});

  final _AchievementProgress item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final definition = item.definition;
    final rewardParts = [
      '+${definition.coins} coin',
      if (definition.gems > 0) '+${definition.gems} gem',
      '+${definition.xp} XP',
    ];

    return GlassCard(
      variant: item.completed ? GlassCardVariant.highlighted : GlassCardVariant.elevated,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: item.completed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                foregroundColor: item.completed
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                child: Icon(definition.icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            definition.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (item.newlyUnlocked)
                          const Icon(Icons.new_releases_rounded, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      definition.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppProgressBar(
            value: item.ratio,
            tone: item.completed ? AppProgressTone.success : AppProgressTone.gold,
            height: 8,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.progress.clamp(0, definition.target)} / ${definition.target}',
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Text(
                '${definition.category} • ${definition.rarity}',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rewardParts.join(' • '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
