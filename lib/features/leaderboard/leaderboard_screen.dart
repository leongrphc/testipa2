import 'package:flutter/material.dart';

import '../../core/share/share_service.dart';
import '../../core/widgets/glass_card.dart';
import 'leaderboard_repository.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _period = 'weekly';
  String _mode = 'overall';
  late Future<List<Map<String, dynamic>>> _future;

  static const _periodOptions = [
    ('daily', 'Günlük'),
    ('weekly', 'Haftalık'),
    ('monthly', 'Aylık'),
    ('all_time', 'Tüm Zamanlar'),
  ];

  static const _modeOptions = [
    ('overall', 'Genel'),
    ('millionaire', 'Millionaire'),
    ('duel', 'Düello'),
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() {
    return leaderboardRepository.fetchLeaderboard(period: _period, mode: _mode);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
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

  int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
                      'Leaderboard yüklenemedi: ${snapshot.error}',
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

          final players = snapshot.data ?? const [];
          final topThree = players.take(3).toList();
          final rest = players.length > 3
              ? players.sublist(3)
              : const <Map<String, dynamic>>[];
          final leader = players.isNotEmpty ? players.first : null;

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                GlassCard(
                  variant: GlassCardVariant.highlighted,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sıralama', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(
                        'En iyi oyuncuları filtreleyip kendi sıralamanı takip et.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (leader != null) ...[
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: () => shareService.shareText(
                            subject: 'Futbol Bilgi sıralaması',
                            text:
                                'Futbol Bilgi ${_labelFor(_modeOptions, _mode)} ${_labelFor(_periodOptions, _period)} lideri: ${leader['username'] ?? 'Oyuncu'} (${_formatCompact(_asInt(leader['score']))} puan).',
                          ),
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Sıralamayı Paylaş'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Periyot', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _periodOptions.map((entry) {
                    final selected = _period == entry.$1;
                    return ChoiceChip(
                      label: Text(entry.$2),
                      selected: selected,
                      onSelected: (_) {
                        _period = entry.$1;
                        _reload();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Mod', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _modeOptions.map((entry) {
                    final selected = _mode == entry.$1;
                    return ChoiceChip(
                      label: Text(entry.$2),
                      selected: selected,
                      onSelected: (_) {
                        _mode = entry.$1;
                        _reload();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                if (players.isEmpty)
                  const Center(child: Text('Henüz gösterilecek oyuncu yok.'))
                else ...[
                  Text('Podium', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (topThree.length > 1)
                        Expanded(
                          child: _PodiumCard(
                            rank: 2,
                            player: topThree[1],
                            height: 144,
                          ),
                        ),
                      if (topThree.length > 1) const SizedBox(width: 12),
                      if (topThree.isNotEmpty)
                        Expanded(
                          child: _PodiumCard(
                            rank: 1,
                            player: topThree[0],
                            height: 176,
                            highlighted: true,
                          ),
                        ),
                      if (topThree.length > 2) const SizedBox(width: 12),
                      if (topThree.length > 2)
                        Expanded(
                          child: _PodiumCard(
                            rank: 3,
                            player: topThree[2],
                            height: 132,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Genel Liste', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...rest.asMap().entries.map((entry) {
                    final index = entry.key + 4;
                    final player = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        variant: GlassCardVariant.elevated,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 22, child: Text('$index')),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player['username']?.toString() ?? 'Oyuncu',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    player['league_tier']?.toString() ??
                                        'bronze',
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatCompact(_asInt(player['score'])),
                              style: theme.textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _labelFor(List<(String, String)> options, String key) {
    return options
        .firstWhere((item) => item.$1 == key, orElse: () => (key, key))
        .$2;
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.rank,
    required this.player,
    required this.height,
    this.highlighted = false,
  });

  final int rank;
  final Map<String, dynamic> player;
  final double height;
  final bool highlighted;

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

  int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: height,
      child: GlassCard(
        variant: highlighted ? GlassCardVariant.gold : GlassCardVariant.elevated,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CircleAvatar(radius: 22, child: Text('$rank')),
            const SizedBox(height: 12),
            Text(
              player['username']?.toString() ?? 'Oyuncu',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _formatCompact(_asInt(player['score'])),
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
