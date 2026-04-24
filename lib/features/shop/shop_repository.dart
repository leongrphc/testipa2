import '../../core/api/api_client.dart';

class ShopRepository {
  Future<Map<String, dynamic>> fetchThemes() async {
    final response = await apiClient.get('/api/shop/themes');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchFrames() async {
    final response = await apiClient.get('/api/shop/frames');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchShopBundle() async {
    final themes = await fetchThemes();
    final frames = await fetchFrames();
    return {
      'themeShopItems': themes['shopItems'] ?? const [],
      'themeInventory': themes['inventory'] ?? const [],
      'frameShopItems': frames['shopItems'] ?? const [],
      'frameInventory': frames['inventory'] ?? const [],
    };
  }

  Future<Map<String, dynamic>> buyTheme(String itemId) async {
    final response = await apiClient.post('/api/shop/themes', data: {
      'itemId': itemId,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> equipTheme(String itemId) async {
    final response = await apiClient.patch('/api/shop/themes', data: {
      'itemId': itemId,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> buyFrame(String itemId) async {
    final response = await apiClient.post('/api/shop/frames', data: {
      'itemId': itemId,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> equipFrame(String frameKey) async {
    final response = await apiClient.patch('/api/shop/frames', data: {
      'frameKey': frameKey,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> buyUtility(String itemKey) async {
    final response = await apiClient.post('/api/shop/purchase', data: {
      'itemKey': itemKey,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptDuelInvite(String inviteId) async {
    final response = await apiClient.patch('/api/social/duel-invites', data: {
      'inviteId': inviteId,
      'action': 'accept',
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rejectDuelInvite(String inviteId) async {
    final response = await apiClient.patch('/api/social/duel-invites', data: {
      'inviteId': inviteId,
      'action': 'reject',
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelDuelInvite(String inviteId) async {
    final response = await apiClient.patch('/api/social/duel-invites', data: {
      'inviteId': inviteId,
      'action': 'cancel',
    });
    return response.data['data'] as Map<String, dynamic>;
  }
}

final shopRepository = ShopRepository();
