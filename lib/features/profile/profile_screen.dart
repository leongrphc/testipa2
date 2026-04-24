import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/share/share_service.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/glass_card.dart';
import 'profile_provider.dart';
import 'profile_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _updatingSettingKey;

  Future<void> _updateSetting(String key, bool enabled) async {
    setState(() => _updatingSettingKey = key);
    try {
      await profileRepository.updateSettings({key: enabled});
      analyticsService.track('profile_settings_updated', {key: enabled});
      ref.invalidate(profileProvider);
      if (!mounted) {
        return;
      }
      final label = switch (key) {
        'sound_enabled' => 'Ses',
        'vibration_enabled' => 'Titreşim',
        'notifications_enabled' => 'Bildirim',
        _ => 'Ayar',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled ? '$label tercihi açıldı.' : '$label tercihi kapatıldı.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingSettingKey = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ProfileStateMessage(
        title: 'Profil alınamadı',
        description: '$error',
        actionLabel: 'Tekrar dene',
        onPressed: () => ref.invalidate(profileProvider),
      ),
      data: (profile) {
        if (profile == null) {
          return _ProfileStateMessage(
            title: 'Profil bulunamadı',
            description: 'Bu hesap için profil kaydı henüz hazır değil.',
            actionLabel: 'Yenile',
            onPressed: () => ref.invalidate(profileProvider),
          );
        }

        final username = profile['username']?.toString() ?? 'Oyuncu';
        final level = _asInt(profile['level']);
        final xp = _asInt(profile['xp']);
        final coins = _asInt(profile['coins']);
        final gems = _asInt(profile['gems']);
        final energy = _asInt(profile['energy']);
        final elo = _asInt(profile['elo_rating']);
        final streak = _asInt(profile['streak_days']);
        final leagueTier = profile['league_tier']?.toString() ?? 'bronze';
        final favoriteTeam =
            profile['favorite_team']?.toString() ?? 'Takım seçilmedi';
        final correctAnswers = _asInt(profile['total_correct_answers']);
        final totalAnswered = _asInt(profile['total_questions_answered']);
        final accuracy = totalAnswered == 0
            ? 0
            : ((correctAnswers / totalAnswered) * 100).round();
        final settings = profile['settings'] is Map
            ? Map<String, dynamic>.from(profile['settings'] as Map)
            : <String, dynamic>{};
        final jokers = settings['jokers'] is Map
            ? Map<String, dynamic>.from(settings['jokers'] as Map)
            : <String, dynamic>{};
        final soundEnabled = settings['sound_enabled'] != false;
        final vibrationEnabled = settings['vibration_enabled'] != false;
        final notificationsEnabled = settings['notifications_enabled'] != false;
        final activeTheme = _activeThemeLabel(settings);
        final avatarFrame = profile['avatar_frame']?.toString();

        return RefreshIndicator(
          onRefresh: () async => ref.refresh(profileProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ProfileHeroCard(
                username: username,
                level: level,
                xp: xp,
                accuracy: accuracy,
                favoriteTeam: favoriteTeam,
                leagueTier: leagueTier,
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatCard(
                    label: 'Enerji',
                    value: '$energy/5',
                    icon: Icons.bolt_rounded,
                  ),
                  _StatCard(
                    label: 'Coin',
                    value: _formatCompact(coins),
                    icon: Icons.monetization_on_rounded,
                  ),
                  _StatCard(
                    label: 'Gem',
                    value: _formatCompact(gems),
                    icon: Icons.diamond_rounded,
                  ),
                  _StatCard(
                    label: 'ELO',
                    value: '$elo',
                    icon: Icons.shield_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Oyuncu Özeti',
                child: Column(
                  children: [
                    _InfoRow(label: 'Seviye', value: '$level'),
                    _InfoRow(label: 'Toplam XP', value: _formatCompact(xp)),
                    _InfoRow(label: 'Doğru cevap', value: '$correctAnswers'),
                    _InfoRow(label: 'Toplam soru', value: '$totalAnswered'),
                    _InfoRow(label: 'Doğruluk', value: '%$accuracy'),
                    _InfoRow(label: 'Streak', value: '$streak gün'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Lig ve Kimlik',
                child: Column(
                  children: [
                    _InfoRow(label: 'Lig', value: leagueTier),
                    _InfoRow(label: 'Favori takım', value: favoriteTeam),
                    _InfoRow(
                      label: 'Premium',
                      value: profile['is_premium'] == true ? 'Aktif' : 'Kapalı',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Kozmetik',
                child: Column(
                  children: [
                    _InfoRow(label: 'Aktif tema', value: activeTheme),
                    _InfoRow(
                      label: 'Avatar frame',
                      value: avatarFrame == null || avatarFrame.isEmpty
                          ? 'Varsayılan'
                          : avatarFrame,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _JokerInventoryPanel(jokers: jokers),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Tercihler',
                child: Column(
                  children: [
                    _SettingsSwitch(
                      title: 'Ses',
                      subtitle: soundEnabled
                          ? 'Oyun sesleri ve feedback sesleri açık.'
                          : 'Oyun sesleri kapalı.',
                      value: soundEnabled,
                      isUpdating: _updatingSettingKey == 'sound_enabled',
                      onChanged: (value) =>
                          _updateSetting('sound_enabled', value),
                    ),
                    _SettingsSwitch(
                      title: 'Titreşim',
                      subtitle: vibrationEnabled
                          ? 'Cevap ve sonuç feedback titreşimleri açık.'
                          : 'Titreşim feedback kapalı.',
                      value: vibrationEnabled,
                      isUpdating: _updatingSettingKey == 'vibration_enabled',
                      onChanged: (value) =>
                          _updateSetting('vibration_enabled', value),
                    ),
                    _SettingsSwitch(
                      title: 'Bildirimler',
                      subtitle: notificationsEnabled
                          ? 'Düello daveti ve sezon bildirimleri için açık.'
                          : 'Mobil bildirim aboneliği kapalı tutulacak.',
                      value: notificationsEnabled,
                      isUpdating:
                          _updatingSettingKey == 'notifications_enabled',
                      onChanged: (value) =>
                          _updateSetting('notifications_enabled', value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Pazar Hazırlığı',
                child: Column(
                  children: [
                    _InfoRow(label: 'IAP', value: 'Mobil altyapı hazır'),
                    _InfoRow(label: 'Reklam', value: 'Test birimleri bağlı'),
                    const _InfoRow(
                      label: 'Push',
                      value: 'Firebase hesabı bekliyor',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Profil Paylaşımı',
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareProfile(
                      username: username,
                      level: level,
                      xp: xp,
                      accuracy: accuracy,
                      leagueTier: leagueTier,
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Profili Paylaş'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
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

  String _activeThemeLabel(Map<String, dynamic> settings) {
    final theme = settings['theme'];
    if (theme is String && theme.isNotEmpty) {
      return theme;
    }
    final displayTheme = settings['display_theme'];
    if (displayTheme is String && displayTheme.isNotEmpty) {
      return displayTheme;
    }
    return 'Koyu tema';
  }

  Future<void> _shareProfile({
    required String username,
    required int level,
    required int xp,
    required int accuracy,
    required String leagueTier,
  }) {
    analyticsService.track('profile_shared', {
      'level': level,
      'league_tier': leagueTier,
    });
    return shareService.shareText(
      subject: 'Futbol Bilgi profilim',
      text:
          'Futbol Bilgi profilim: $username · Level $level · $xp XP · %$accuracy doğruluk · $leagueTier ligi.',
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.username,
    required this.level,
    required this.xp,
    required this.accuracy,
    required this.favoriteTeam,
    required this.leagueTier,
  });

  final String username;
  final int level;
  final int xp;
  final int accuracy;
  final String favoriteTeam;
  final String leagueTier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.highlighted,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.onPrimaryContainer.withValues(
              alpha: 0.12,
            ),
            child: Text(
              username.isEmpty ? 'O' : username.characters.first.toUpperCase(),
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          Text(username, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Level $level · $xp XP · %$accuracy doğruluk',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          AppProgressBar(value: (xp % 1000) / 1000, tone: AppProgressTone.gold),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaChip(label: leagueTier),
              _MetaChip(label: favoriteTeam),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppBadge(label: label, tone: AppBadgeTone.primary);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 16),
          Text(value, style: theme.textTheme.titleLarge),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _JokerInventoryPanel extends StatelessWidget {
  const _JokerInventoryPanel({required this.jokers});

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
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Joker Envanteri', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.08,
            physics: const NeverScrollableScrollPhysics(),
            children: _items.map((item) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: theme.colorScheme.surfaceContainerHighest,
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

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isUpdating,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: isUpdating ? null : onChanged,
      title: Text(title),
      subtitle: Text(isUpdating ? 'Güncelleniyor...' : subtitle),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ProfileStateMessage extends StatelessWidget {
  const _ProfileStateMessage({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassCard(
            variant: GlassCardVariant.elevated,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(description, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(onPressed: onPressed, child: Text(actionLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
