import '../../core/api/api_client.dart';

class AchievementsRepository {
  Future<Map<String, dynamic>> syncAchievements({
    required List<Map<String, dynamic>> leagueEntries,
    String? currentSeasonId,
  }) async {
    final response = await apiClient.post('/api/achievements/sync', data: {
      'leagueEntries': leagueEntries,
      'currentSeasonId': currentSeasonId,
    });

    return response.data['data'] as Map<String, dynamic>;
  }
}

final achievementsRepository = AchievementsRepository();
