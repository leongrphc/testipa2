import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../api/api_client.dart';

class IapCatalog {
  const IapCatalog({
    required this.isAvailable,
    required this.products,
    required this.notFoundIds,
  });

  final bool isAvailable;
  final Map<String, ProductDetails> products;
  final Set<String> notFoundIds;
}

class IapProductInfo {
  const IapProductInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.fallbackPrice,
    required this.isConsumable,
  });

  final String id;
  final String title;
  final String description;
  final String fallbackPrice;
  final bool isConsumable;
}

class IapService {
  IapService({InAppPurchase? inAppPurchase})
    : _iap = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  static const products = [
    IapProductInfo(
      id: 'gems_small',
      title: 'Küçük Gem Paketi',
      description: '50 gem hesabına eklenir.',
      fallbackPrice: '50 gem',
      isConsumable: true,
    ),
    IapProductInfo(
      id: 'gems_medium',
      title: 'Orta Gem Paketi',
      description: '200 gem hesabına eklenir.',
      fallbackPrice: '200 gem',
      isConsumable: true,
    ),
    IapProductInfo(
      id: 'gems_large',
      title: 'Büyük Gem Paketi',
      description: '500 gem hesabına eklenir.',
      fallbackPrice: '500 gem',
      isConsumable: true,
    ),
    IapProductInfo(
      id: 'starter_pack',
      title: 'Başlangıç Paketi',
      description: '100 gem ve 5000 coin tek seferlik paket.',
      fallbackPrice: '100 gem + 5000 coin',
      isConsumable: false,
    ),
    IapProductInfo(
      id: 'premium_pass',
      title: 'Premium Pass',
      description: 'Premium durumunu açar ve günlük premium gem hakkı verir.',
      fallbackPrice: 'Premium',
      isConsumable: false,
    ),
  ];

  static Set<String> get productIds => products.map((item) => item.id).toSet();

  Future<IapCatalog> loadCatalog() async {
    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      return IapCatalog(
        isAvailable: false,
        products: const {},
        notFoundIds: productIds,
      );
    }

    final response = await _iap.queryProductDetails(productIds);
    return IapCatalog(
      isAvailable: true,
      products: {
        for (final product in response.productDetails) product.id: product,
      },
      notFoundIds: response.notFoundIDs.toSet(),
    );
  }

  Future<bool> buy(ProductDetails product) {
    final purchaseParam = PurchaseParam(productDetails: product);
    final productInfo = products.firstWhere((item) => item.id == product.id);
    if (productInfo.isConsumable) {
      return _iap.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true,
      );
    }
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<Map<String, dynamic>> verifyPurchase(PurchaseDetails purchase) async {
    final platform = _platformName;
    final verificationData = purchase.verificationData.serverVerificationData;
    final response = await apiClient.post(
      '/api/iap/verify',
      data: {
        'platform': platform,
        'productId': purchase.productID,
        if (purchase.purchaseID != null) 'transactionId': purchase.purchaseID,
        if (platform == 'ios') 'receipt': verificationData,
        if (platform == 'android') 'purchaseToken': verificationData,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> claimPremiumGems() async {
    final response = await apiClient.post('/api/iap/premium-claim');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'android';
    }
  }
}

final iapService = IapService();
