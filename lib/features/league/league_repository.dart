import '../../core/api/api_client.dart';

class LeagueRepository {
  Future<Map<String, dynamic>?> fetchCurrentSeason() async {
    final response = await apiClient.get('/api/league/season');
    return response.data['data'] as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> fetchEntries({String? seasonId, String? tier}) async {
    final response = await apiClient.get('/api/league/entries', queryParameters: {
      if (seasonId != null) 'season_id': seasonId,
      if (tier != null) 'tier': tier,
    });

    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
}

final leagueRepository = LeagueRepository();
