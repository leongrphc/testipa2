import '../../core/api/api_client.dart';

class QuickRepository {
  Future<Map<String, dynamic>> startGame({String scope = 'turkey'}) async {
    final response = await apiClient.post('/api/game/quick', queryParameters: {'scope': scope});
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> finishGame({
    required String sessionId,
    required String result,
    required int score,
    required int correctAnswers,
    required int totalAnswered,
  }) async {
    final response = await apiClient.patch('/api/game/quick', data: {
      'sessionId': sessionId,
      'result': result,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalAnswered': totalAnswered,
    });

    return response.data['data'] as Map<String, dynamic>;
  }
}

final quickRepository = QuickRepository();
