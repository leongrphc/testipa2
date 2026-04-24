import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_state_panel.dart';
import '../../core/widgets/glass_card.dart';
import 'social_repository.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  late Future<Map<String, dynamic>> _future;
  final _usernameController = TextEditingController();
  String? _message;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() {
    return socialRepository.fetchSnapshot();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _sendFriendRequest() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _message = 'Kullanıcı adı gir.');
      return;
    }

    try {
      await socialRepository.sendFriendRequest(username);
      _usernameController.clear();
      setState(() => _message = 'Arkadaş isteği gönderildi.');
      _reload();
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _acceptRequest(String requesterId) async {
    try {
      await socialRepository.acceptFriendRequest(requesterId);
      setState(() => _message = 'Arkadaş isteği kabul edildi.');
      _reload();
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _rejectRequest(String requesterId) async {
    try {
      await socialRepository.rejectFriendRequest(requesterId);
      setState(() => _message = 'Arkadaş isteği reddedildi.');
      _reload();
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _sendDuelInvite(String toUserId) async {
    try {
      await socialRepository.sendDuelInvite(toUserId);
      setState(() => _message = 'Düello daveti gönderildi.');
      _reload();
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _acceptDuelInvite(String inviteId) async {
    try {
      await socialRepository.acceptDuelInvite(inviteId);
      setState(() => _message = 'Düello daveti kabul edildi.');
      _reload();
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _rejectDuelInvite(String inviteId) async {
    try {
      await socialRepository.rejectDuelInvite(inviteId);
      setState(() => _message = 'Düello daveti reddedildi.');
      _reload();
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _cancelDuelInvite(String inviteId) async {
    try {
      await socialRepository.cancelDuelInvite(inviteId);
      setState(() => _message = 'Düello daveti iptal edildi.');
      _reload();
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Social')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppStatePanel.loading(message: 'Sosyal veriler yükleniyor...');
          }

          if (snapshot.hasError) {
            return AppStatePanel.error(
              message: 'Sosyal veriler alınamadı: ${snapshot.error}',
              onAction: _reload,
            );
          }

          final payload = snapshot.data ?? <String, dynamic>{};
          final profiles = (payload['profiles'] as List<dynamic>? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final friendships =
              (payload['friendships'] as List<dynamic>? ?? const [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
          final invites = (payload['duelInvites'] as List<dynamic>? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          final profileById = {
            for (final profile in profiles)
              profile['id']?.toString() ?? '': profile,
          };

          final acceptedFriendIds = friendships
              .where((item) => item['status'] == 'accepted')
              .map((item) {
                final userId = item['user_id']?.toString();
                final friendId = item['friend_id']?.toString();
                if (currentUserId != null && userId == currentUserId) {
                  return friendId;
                }
                return userId;
              })
              .whereType<String>()
              .toSet();
          final pendingIncoming = friendships
              .where(
                (item) =>
                    item['status'] == 'pending' &&
                    item['friend_id']?.toString() == currentUserId,
              )
              .toList();

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
                        'Sosyal Merkez',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Arkadaş listeni büyüt, gelen istekleri yanıtla ve düelloları başlat.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  variant: GlassCardVariant.elevated,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Arkadaş ekle', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı adı',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _sendFriendRequest,
                        child: const Text('İstek Gönder'),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(_message!, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primaryBright)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Bekleyen istekler', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                if (pendingIncoming.isEmpty)
                  const AppStatePanel.empty(message: 'Bekleyen arkadaş isteği yok.')
                else
                  ...pendingIncoming.map((item) {
                    final requesterId = item['user_id']?.toString() ?? '';
                    final requesterName = _displayName(
                      profileById[requesterId],
                      requesterId,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SocialCard(
                        title: requesterName,
                        subtitle: 'Arkadaş isteği gönderdi',
                        primaryLabel: 'Kabul',
                        secondaryLabel: 'Reddet',
                        onPrimary: () => _acceptRequest(requesterId),
                        onSecondary: () => _rejectRequest(requesterId),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
                Text('Oyuncular', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                ...profiles.map((profile) {
                  final id = profile['id']?.toString() ?? '';
                  final isFriend = acceptedFriendIds.contains(id);
                  final xp = profile['xp'] ?? profile['score'] ?? 0;
                  final leagueTier = profile['league_tier'] ?? 'bronze';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      variant: GlassCardVariant.elevated,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              profile['username']?.toString().substring(0, 1).toUpperCase() ?? 'O',
                              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        profile['username']?.toString() ?? 'Oyuncu',
                                        style: theme.textTheme.titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isFriend)
                                      const AppBadge(label: 'Arkadaş', tone: AppBadgeTone.success),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('$leagueTier · $xp XP', style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          if (isFriend) ...[
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              onPressed: () => _sendDuelInvite(id),
                              icon: const Icon(Icons.sports_martial_arts_rounded),
                              tooltip: 'Düello daveti gönder',
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Text('Düello davetleri', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                if (invites.isEmpty)
                  const AppStatePanel.empty(message: 'Aktif düello daveti yok.')
                else
                  ...invites.map((invite) {
                    final inviteId = invite['id']?.toString() ?? '';
                    final fromUserId = invite['from_user_id']?.toString() ?? '';
                    final toUserId = invite['to_user_id']?.toString() ?? '';
                    final status = invite['status']?.toString() ?? 'pending';
                    final isIncoming =
                        currentUserId != null && toUserId == currentUserId;
                    final isOutgoing =
                        currentUserId != null && fromUserId == currentUserId;
                    final fromName = _displayName(
                      profileById[fromUserId],
                      fromUserId,
                    );
                    final toName = _displayName(
                      profileById[toUserId],
                      toUserId,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SocialCard(
                        title: '$fromName → $toName',
                        subtitle: 'Durum: $status',
                        primaryLabel: status == 'pending' && isIncoming
                            ? 'Kabul'
                            : status == 'pending' && isOutgoing
                            ? 'İptal'
                            : null,
                        secondaryLabel: status == 'pending' && isIncoming
                            ? 'Reddet'
                            : null,
                        onPrimary: status == 'pending' && isIncoming
                            ? () => _acceptDuelInvite(inviteId)
                            : status == 'pending' && isOutgoing
                            ? () => _cancelDuelInvite(inviteId)
                            : null,
                        onSecondary: status == 'pending' && isIncoming
                            ? () => _rejectDuelInvite(inviteId)
                            : null,
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

String _displayName(Map<String, dynamic>? profile, String fallbackId) {
  final username = profile?['username']?.toString();
  if (username != null && username.isNotEmpty) {
    return username;
  }
  if (fallbackId.length > 8) {
    return 'Oyuncu ${fallbackId.substring(0, 8)}';
  }
  return fallbackId.isEmpty ? 'Oyuncu' : 'Oyuncu $fallbackId';
}

class _SocialCard extends StatelessWidget {
  const _SocialCard({
    required this.title,
    required this.subtitle,
    this.primaryLabel,
    this.secondaryLabel,
    this.onPrimary,
    this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String? primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle),
          if (primaryLabel != null || secondaryLabel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (primaryLabel != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: onPrimary,
                      child: Text(primaryLabel!),
                    ),
                  ),
                if (primaryLabel != null && secondaryLabel != null)
                  const SizedBox(width: 12),
                if (secondaryLabel != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSecondary,
                      child: Text(secondaryLabel!),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
