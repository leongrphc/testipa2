import '../../core/api/api_client.dart';

class ProfileRepository {
  Future<Map<String, dynamic>?> fetchProfile() async {
    final response = await apiClient.get('/api/me');
    return response.data['data'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>> claimDailyReward() async {
    final response = await apiClient.post(
      '/api/me/progression',
      data: {'action': 'claim_daily_reward'},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> settings,
  ) async {
    final response = await apiClient.patch(
      '/api/me',
      data: {'settings': settings},
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}

final profileRepository = ProfileRepository();
