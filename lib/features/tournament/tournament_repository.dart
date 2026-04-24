import '../../core/api/api_client.dart';

class TournamentRepository {
  Future<List<Map<String, dynamic>>> fetchTournaments() async {
    final response = await apiClient.get('/api/tournaments');
    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> joinTournament(String tournamentId) async {
    final response = await apiClient.post('/api/tournaments', data: {
      'tournamentId': tournamentId,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchTournamentDetails(String id) async {
    final response = await apiClient.get('/api/tournaments/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> fetchQuestions(String id, int round) async {
    final response = await apiClient.get('/api/tournaments/$id/questions', queryParameters: {
      'round': '$round',
    });
    final data = response.data['data']['questions'] as List<dynamic>? ?? const [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> updateRun({
    required String id,
    required int score,
    required int roundReached,
    required bool completed,
  }) async {
    final response = await apiClient.patch('/api/tournaments/$id', data: {
      'score': score,
      'round_reached': roundReached,
      'completed': completed,
    });
    return response.data['data'] as Map<String, dynamic>;
  }
}

final tournamentRepository = TournamentRepository();
