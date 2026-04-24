import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/app_state_panel.dart';
import '../../core/widgets/glass_card.dart';
import 'league_repository.dart';

class LeagueScreen extends StatefulWidget {
  const LeagueScreen({super.key});

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  late Future<_LeaguePayload> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_LeaguePayload> _load() async {
    final season = await leagueRepository.fetchCurrentSeason();
    final entries = await leagueRepository.fetchEntries(
      seasonId: season?['id']?.toString(),
    );
    return _LeaguePayload(season: season, entries: entries);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  String _zoneLabel(int rank, int total) {
    if (total <= 0) return 'Belirsiz';
    if (rank <= (total / 4).ceil()) return 'Terfi Hattı';
    if (rank > total - (total / 4).ceil()) return 'Düşme Hattı';
    return 'Güvende';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('League')),
      body: FutureBuilder<_LeaguePayload>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppStatePanel.loading(message: 'League verisi yükleniyor...');
          }

          if (snapshot.hasError) {
            return AppStatePanel.error(
              message: 'League verisi alınamadı: ${snapshot.error}',
              onAction: _reload,
            );
          }

          final payload = snapshot.data!;
          final season = payload.season;
          final entries = payload.entries;

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
                      Text(
                        'Haftalık Lig',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aktif sezon: ${season?['name'] ?? 'Bilinmiyor'}',
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (season?['ends_at'] != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text('Bitiş: ${season!['ends_at']}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const AppProgressBar(value: 0.75, tone: AppProgressTone.gold, height: 6),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Lig Tablosu', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  const AppStatePanel.empty(message: 'Bu sezon için henüz giriş yok.')
                else
                  ...entries.take(20).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final rank = index + 1;
                    final zone = _zoneLabel(rank, entries.length);
                    final isPromotion = zone == 'Terfi Hattı';
                    final isRelegation = zone == 'Düşme Hattı';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        variant: GlassCardVariant.elevated,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isPromotion
                                  ? AppColors.success.withValues(alpha: 0.2)
                                  : isRelegation
                                      ? AppColors.danger.withValues(alpha: 0.2)
                                      : theme.colorScheme.surfaceContainerHighest,
                              foregroundColor: isPromotion
                                  ? AppColors.success
                                  : isRelegation
                                      ? AppColors.danger
                                      : theme.colorScheme.onSurface,
                              child: Text('$rank'),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _displayName(item),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  AppBadge(
                                    label: zone,
                                    tone: isPromotion
                                        ? AppBadgeTone.success
                                        : isRelegation
                                            ? AppBadgeTone.danger
                                            : AppBadgeTone.neutral,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item['season_score'] ?? 0}',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _displayName(Map<String, dynamic> item) {
  final profile = item['profiles'];
  if (profile is Map && profile['username'] != null) {
    return profile['username'].toString();
  }

  final userId = item['user_id']?.toString() ?? '';
  if (userId.length > 8) {
    return 'Oyuncu ${userId.substring(0, 8)}';
  }
  return userId.isEmpty ? 'Oyuncu' : 'Oyuncu $userId';
}

class _LeaguePayload {
  const _LeaguePayload({required this.season, required this.entries});

  final Map<String, dynamic>? season;
  final List<Map<String, dynamic>> entries;
}
