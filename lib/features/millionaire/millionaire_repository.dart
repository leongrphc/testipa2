import '../../core/api/api_client.dart';

class MillionaireRepository {
  Future<Map<String, dynamic>> startGame({String scope = 'turkey'}) async {
    final response = await apiClient.post('/api/game/millionaire', queryParameters: {'scope': scope});
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> finishGame({
    required String sessionId,
    required String result,
    required int score,
    required int correctAnswers,
    required int totalAnswered,
    required int safePointReached,
    required List<String> jokersUsed,
  }) async {
    final response = await apiClient.patch('/api/game/millionaire', data: {
      'sessionId': sessionId,
      'result': result,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalAnswered': totalAnswered,
      'safePointReached': safePointReached,
      'jokersUsed': jokersUsed,
    });

    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> useJoker(String jokerType) async {
    final response = await apiClient.post('/api/me/jokers/use', data: {
      'jokerType': jokerType,
    });

    return response.data['data'] as Map<String, dynamic>;
  }
}

final millionaireRepository = MillionaireRepository();
