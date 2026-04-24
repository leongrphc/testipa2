import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/iap/iap_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_stat_chip.dart';
import '../../core/widgets/glass_card.dart';
import '../profile/profile_provider.dart';
import 'shop_repository.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  late Future<Map<String, dynamic>> _future;
  late StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  String? _message;
  String _activeTab = 'themes';
  IapCatalog? _iapCatalog;
  bool _isLoadingIap = true;
  String? _iapProductInProgress;

  static const _utilityItems = [
    (
      'joker_fifty_fifty',
      '50/50 Joker',
      'İki yanlış şıkkı eler.',
      50,
      'fifty_fifty',
      Icons.percent_rounded,
    ),
    (
      'joker_audience',
      'Seyirci Jokeri',
      'Seyirci dağılımını gösterir.',
      75,
      'audience',
      Icons.groups_rounded,
    ),
    (
      'joker_phone',
      'Telefon Jokeri',
      'Tahmini doğru cevabı söyler.',
      100,
      'phone',
      Icons.phone_rounded,
    ),
    (
      'joker_freeze_time',
      'Süre Dondur',
      'Ek süre kazandırır.',
      60,
      'freeze_time',
      Icons.timer_rounded,
    ),
    (
      'joker_skip',
      'Pas Geç',
      'Soruyu değiştirir.',
      120,
      'skip',
      Icons.skip_next_rounded,
    ),
    (
      'joker_double_answer',
      'Çift Cevap',
      'Bir yanlış tahmin hakkı verir.',
      80,
      'double_answer',
      Icons.copy_rounded,
    ),
    (
      'energy_refill_small',
      '+1 Enerji',
      'Hemen 1 enerji doldurur.',
      30,
      null,
      Icons.battery_charging_full_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();
    _purchaseSubscription = iapService.purchaseStream.listen(
      _handlePurchaseUpdates,
    );
    unawaited(_loadIapCatalog());
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() {
    return shopRepository.fetchShopBundle();
  }

  Future<void> _loadIapCatalog() async {
    try {
      final catalog = await iapService.loadCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        _iapCatalog = catalog;
        _isLoadingIap = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message =
            'Mağaza ürünleri yüklenemedi: ${error.toString().replaceFirst('Exception: ', '')}';
        _isLoadingIap = false;
      });
    }
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _buyTheme(String itemId) async {
    try {
      await shopRepository.buyTheme(itemId);
      setState(() => _message = 'Tema satın alındı.');
      ref.invalidate(profileProvider);
      _reload();
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _equipTheme(String itemId) async {
    try {
      await shopRepository.equipTheme(itemId);
      setState(() => _message = 'Tema kuşanıldı.');
      ref.invalidate(profileProvider);
      _reload();
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _buyFrame(String itemId) async {
    try {
      await shopRepository.buyFrame(itemId);
      setState(() => _message = 'Frame satın alındı.');
      ref.invalidate(profileProvider);
      _reload();
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _equipFrame(String frameKey) async {
    try {
      await shopRepository.equipFrame(frameKey);
      setState(() => _message = 'Frame kuşanıldı.');
      ref.invalidate(profileProvider);
      _reload();
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _buyUtility(String itemKey) async {
    try {
      await shopRepository.buyUtility(itemKey);
      setState(() => _message = 'Satın alma tamamlandı.');
      ref.invalidate(profileProvider);
      _reload();
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _buyIapProduct(String productId) async {
    final product = _iapCatalog?.products[productId];
    if (product == null) {
      setState(() => _message = 'Bu ürün mağazada henüz tanımlı değil.');
      return;
    }

    setState(() {
      _iapProductInProgress = productId;
      _message = null;
    });

    try {
      await iapService.buy(product);
    } catch (error) {
      setState(() {
        _iapProductInProgress = null;
        _message = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _claimPremiumGems() async {
    setState(() => _message = null);
    try {
      await iapService.claimPremiumGems();
      setState(() => _message = 'Günlük 20 gem hesabına işlendi.');
      ref.invalidate(profileProvider);
    } catch (error) {
      final text = error.toString();
      final message = text.contains('Premium gems already claimed today')
          ? 'Bugünkü premium gem ödülü zaten alınmış.'
          : text.contains('Verified premium pass required')
          ? 'Premium Pass doğrulaması gerekiyor.'
          : text.replaceFirst('Exception: ', '');
      setState(() => _message = message);
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        setState(() => _iapProductInProgress = purchase.productID);
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        setState(() {
          _iapProductInProgress = null;
          _message = purchase.error?.message ?? 'Satın alma tamamlanamadı.';
        });
        await iapService.complete(purchase);
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        try {
          await iapService.verifyPurchase(purchase);
          await iapService.complete(purchase);
          ref.invalidate(profileProvider);
          _reload();
          setState(() {
            _iapProductInProgress = null;
            _message = 'Satın alma doğrulandı ve hesabına işlendi.';
          });
        } catch (error) {
          await iapService.complete(purchase);
          setState(() {
            _iapProductInProgress = null;
            _message = error.toString().replaceFirst('Exception: ', '');
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref
        .watch(profileProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final coins = _asInt(profile?['coins']);
    final gems = _asInt(profile?['gems']);
    final energy = _asInt(profile?['energy']);
    final isPremium = profile?['is_premium'] == true;
    final settings = profile?['settings'] is Map
        ? Map<String, dynamic>.from(profile!['settings'] as Map)
        : <String, dynamic>{};
    final jokers = settings['jokers'] is Map
        ? Map<String, dynamic>.from(settings['jokers'] as Map)
        : <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Mağaza')),
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
                      'Mağaza yüklenemedi: ${snapshot.error}',
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
          final themeItems =
              (payload['themeShopItems'] as List<dynamic>? ?? const [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
          final themeInventory =
              (payload['themeInventory'] as List<dynamic>? ?? const [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
          final frameItems =
              (payload['frameShopItems'] as List<dynamic>? ?? const [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
          final frameInventory =
              (payload['frameInventory'] as List<dynamic>? ?? const [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
          final ownedThemeItemIds = themeInventory
              .map((item) => item['item_id']?.toString())
              .whereType<String>()
              .toSet();
          final equippedThemeItemIds = themeInventory
              .where((item) => item['is_equipped'] == true)
              .map((item) => item['item_id']?.toString())
              .whereType<String>()
              .toSet();
          final ownedFrameItemIds = frameInventory
              .map((item) => item['item_id']?.toString())
              .whereType<String>()
              .toSet();
          final equippedFrameItemIds = frameInventory
              .where((item) => item['is_equipped'] == true)
              .map((item) => item['item_id']?.toString())
              .whereType<String>()
              .toSet();
          final frameItemById = {
            for (final item in frameItems) item['id']?.toString() ?? '': item,
          };
          final themeItemById = {
            for (final item in themeItems) item['id']?.toString() ?? '': item,
          };

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                variant: GlassCardVariant.gold,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mağaza', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Tema, frame, joker ve enerji ile hesabını zenginleştir.',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _BalanceChip(
                          label: 'Coin',
                          value: _formatCompact(coins),
                          icon: Icons.monetization_on_rounded,
                        ),
                        _BalanceChip(
                          label: 'Gem',
                          value: _formatCompact(gems),
                          icon: Icons.diamond_rounded,
                        ),
                        _BalanceChip(
                          label: 'Enerji',
                          value: '$energy/5',
                          icon: Icons.bolt_rounded,
                        ),
                        if (isPremium)
                          const _BalanceChip(
                            label: 'Premium',
                            value: 'Aktif',
                            icon: Icons.auto_awesome_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(_message!),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Jokerler'),
                    selected: _activeTab == 'jokers',
                    onSelected: (_) => setState(() => _activeTab = 'jokers'),
                  ),
                  ChoiceChip(
                    label: const Text('Enerji'),
                    selected: _activeTab == 'energy',
                    onSelected: (_) => setState(() => _activeTab = 'energy'),
                  ),
                  ChoiceChip(
                    label: const Text('Frame'),
                    selected: _activeTab == 'frames',
                    onSelected: (_) => setState(() => _activeTab = 'frames'),
                  ),
                  ChoiceChip(
                    label: const Text('Temalar'),
                    selected: _activeTab == 'themes',
                    onSelected: (_) => setState(() => _activeTab = 'themes'),
                  ),
                  ChoiceChip(
                    label: const Text('Premium / Gem'),
                    selected: _activeTab == 'iap',
                    onSelected: (_) => setState(() => _activeTab = 'iap'),
                  ),
                  ChoiceChip(
                    label: const Text('Koleksiyon'),
                    selected: _activeTab == 'collection',
                    onSelected: (_) =>
                        setState(() => _activeTab = 'collection'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_activeTab == 'jokers') ...[
                Text('Jokerler', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                ..._utilityItems.where((item) => item.$5 != null).map((item) {
                  final stock = _asInt(jokers[item.$5]);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShopCard(
                      title: item.$2,
                      description: item.$3,
                      priceLabel: '${item.$4} coin · Stok: $stock',
                      actionLabel: coins >= item.$4
                          ? 'Satın Al'
                          : 'Yetersiz Coin',
                      icon: item.$6,
                      onPressed: coins >= item.$4
                          ? () => _buyUtility(item.$1)
                          : null,
                    ),
                  );
                }),
              ] else if (_activeTab == 'energy') ...[
                Text('Enerji', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                ..._utilityItems
                    .where((item) => item.$5 == null)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ShopCard(
                          title: item.$2,
                          description: item.$3,
                          priceLabel: '${item.$4} coin · Mevcut: $energy/5',
                          actionLabel: energy >= 5
                              ? 'Dolu'
                              : coins >= item.$4
                              ? 'Satın Al'
                              : 'Yetersiz Coin',
                          icon: item.$6,
                          onPressed: energy < 5 && coins >= item.$4
                              ? () => _buyUtility(item.$1)
                              : null,
                        ),
                      ),
                    ),
              ] else if (_activeTab == 'themes') ...[
                Text('Temalar', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                ...themeItems.map((item) {
                  final id = item['id']?.toString() ?? '';
                  final isOwned =
                      ownedThemeItemIds.contains(id) ||
                      id == 'theme-dark-default';
                  final isEquipped =
                      equippedThemeItemIds.contains(id) ||
                      (item['theme_key']?.toString() == 'dark' &&
                          equippedThemeItemIds.isEmpty);
                  final priceCoins = _asInt(item['price_coins']);
                  final priceGems = _asInt(item['price_gems']);
                  final requiresPremium = _isPremiumItem(item) && !isPremium;
                  final canAfford = coins >= priceCoins && gems >= priceGems;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShopCard(
                      title: item['name']?.toString() ?? 'Tema',
                      description: item['description']?.toString() ?? '',
                      priceLabel: isEquipped
                          ? 'Aktif'
                          : isOwned
                          ? 'Sahip Olundu'
                          : 'Coin: $priceCoins · Gem: $priceGems',
                      actionLabel: isOwned
                          ? (isEquipped ? 'Kuşanılı' : 'Kuşan')
                          : requiresPremium
                          ? 'Premium Gerekli'
                          : canAfford
                          ? 'Satın Al'
                          : 'Yetersiz Bakiye',
                      icon: Icons.palette_rounded,
                      onPressed: isOwned
                          ? isEquipped
                                ? null
                                : () => _equipTheme(
                                    id == 'theme-dark-default'
                                        ? 'theme-dark-default'
                                        : id,
                                  )
                          : requiresPremium || !canAfford
                          ? null
                          : () => _buyTheme(id),
                    ),
                  );
                }),
              ] else if (_activeTab == 'frames') ...[
                Text('Frame', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                ...frameItems.map((item) {
                  final id = item['id']?.toString() ?? '';
                  final frameKey = item['frame_key']?.toString() ?? 'default';
                  final isOwned = ownedFrameItemIds.contains(id);
                  final isEquipped = frameInventory.any(
                    (entry) =>
                        entry['item_id']?.toString() == id &&
                        entry['is_equipped'] == true,
                  );
                  final priceCoins = _asInt(item['price_coins']);
                  final priceGems = _asInt(item['price_gems']);
                  final requiresPremium = _isPremiumItem(item) && !isPremium;
                  final canAfford = coins >= priceCoins && gems >= priceGems;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ShopCard(
                      title: item['name']?.toString() ?? 'Frame',
                      description: item['description']?.toString() ?? '',
                      priceLabel: isEquipped
                          ? 'Aktif'
                          : isOwned
                          ? 'Sahip Olundu'
                          : 'Coin: $priceCoins · Gem: $priceGems',
                      actionLabel: isOwned
                          ? (isEquipped ? 'Kuşanılı' : 'Kuşan')
                          : requiresPremium
                          ? 'Premium Gerekli'
                          : canAfford
                          ? 'Satın Al'
                          : 'Yetersiz Bakiye',
                      icon: Icons.account_circle_rounded,
                      onPressed: isOwned
                          ? isEquipped
                                ? null
                                : () => _equipFrame(frameKey)
                          : requiresPremium || !canAfford
                          ? null
                          : () => _buyFrame(id),
                    ),
                  );
                }),
              ] else if (_activeTab == 'iap') ...[
                Text(
                  'Premium ve Gem Paketleri',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (_isLoadingIap)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (_iapCatalog?.isAvailable != true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InfoPanel(
                        icon: Icons.store_mall_directory_outlined,
                        title: 'Mağaza bağlantısı hazır değil',
                        description:
                            'App Store / Play Store ürünleri tanımlandığında bu paketler gerçek satın alma akışını açacak.',
                      ),
                    ),
                  if (isPremium)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ShopCard(
                        title: 'Günlük Premium Gem',
                        description:
                            'Premium kullanıcılar günde 20 gem alabilir.',
                        priceLabel: '+20 gem',
                        actionLabel: 'Günlük Ödülü Al',
                        icon: Icons.auto_awesome_rounded,
                        onPressed: _claimPremiumGems,
                      ),
                    ),
                  ...IapService.products.map((item) {
                    final product = _iapCatalog?.products[item.id];
                    final isUnavailable = product == null;
                    final priceLabel = product?.price ?? item.fallbackPrice;
                    final isBusy = _iapProductInProgress == item.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ShopCard(
                        title: product?.title ?? item.title,
                        description: product?.description.isNotEmpty == true
                            ? product!.description
                            : item.description,
                        priceLabel: isUnavailable
                            ? '$priceLabel · Store ürünü eksik'
                            : priceLabel,
                        actionLabel: isBusy
                            ? 'İşleniyor...'
                            : isUnavailable
                            ? 'Hazır Değil'
                            : 'Satın Al',
                        icon: item.id == 'premium_pass'
                            ? Icons.workspace_premium_rounded
                            : Icons.diamond_rounded,
                        onPressed: isBusy || isUnavailable
                            ? null
                            : () => _buyIapProduct(item.id),
                      ),
                    );
                  }),
                ],
              ] else ...[
                Text('Koleksiyonum', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                if (themeInventory.isEmpty && frameInventory.isEmpty)
                  const Text('Henüz koleksiyon öğen yok.')
                else ...[
                  ...themeInventory.map((entry) {
                    final itemId = entry['item_id']?.toString() ?? '';
                    final item = themeItemById[itemId] ?? entry;
                    final isEquipped = entry['is_equipped'] == true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ShopCard(
                        title: item['name']?.toString() ?? 'Tema',
                        description:
                            item['description']?.toString() ??
                            'Sahip olunan tema',
                        priceLabel: isEquipped ? 'Aktif tema' : 'Sahip Olundu',
                        actionLabel: isEquipped ? 'Kuşanılı' : 'Kuşan',
                        icon: Icons.palette_rounded,
                        onPressed: isEquipped
                            ? null
                            : () => _equipTheme(itemId),
                      ),
                    );
                  }),
                  ...frameInventory.map((entry) {
                    final itemId = entry['item_id']?.toString() ?? '';
                    final item = frameItemById[itemId] ?? entry;
                    final isEquipped = equippedFrameItemIds.contains(itemId);
                    final frameKey = item['frame_key']?.toString() ?? 'default';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ShopCard(
                        title: item['name']?.toString() ?? 'Frame',
                        description:
                            item['description']?.toString() ??
                            'Sahip olunan frame',
                        priceLabel: isEquipped ? 'Aktif frame' : 'Sahip Olundu',
                        actionLabel: isEquipped ? 'Kuşanılı' : 'Kuşan',
                        icon: Icons.account_circle_rounded,
                        onPressed: isEquipped
                            ? null
                            : () => _equipFrame(frameKey),
                      ),
                    );
                  }),
                ],
              ],
            ],
          );
        },
      ),
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

  bool _isPremiumItem(Map<String, dynamic> item) {
    if (item['is_premium'] == true) return true;
    final metadata = item['metadata'];
    return metadata is Map && metadata['isPremium'] == true;
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.actionLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String priceLabel;
  final String actionLabel;
  final IconData icon;
  final VoidCallback? onPressed;

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
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 4),
          Text(description),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(priceLabel)),
              FilledButton.tonal(
                onPressed: onPressed,
                child: Text(actionLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
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
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppStatChip(
      label: label,
      value: value,
      icon: icon,
      color: label == 'Gem' ? AppColors.info : label == 'Premium' ? AppColors.expert : AppColors.gold,
    );
  }
}
