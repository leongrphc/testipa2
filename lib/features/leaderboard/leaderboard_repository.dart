import '../../core/api/api_client.dart';

class LeaderboardRepository {
  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    String period = 'weekly',
    String mode = 'overall',
    int limit = 50,
  }) async {
    final response = await apiClient.get('/api/leaderboard/overall', queryParameters: {
      'period': period,
      'mode': mode,
      'limit': '$limit',
    });

    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
}

final leaderboardRepository = LeaderboardRepository();
