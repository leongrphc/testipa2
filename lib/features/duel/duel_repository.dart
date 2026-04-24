import '../../core/api/api_client.dart';

class DuelRepository {
  Future<Map<String, dynamic>> startGame({String? inviteId}) async {
    final response = await apiClient.post('/api/game/duel', data: {
      if (inviteId != null) 'inviteId': inviteId,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> finishGame({
    required String sessionId,
    required String result,
    required int score,
    required int correctAnswers,
    required int totalAnswered,
    required int opponentElo,
    int answerTimeMs = 0,
    String? inviteId,
  }) async {
    final response = await apiClient.patch('/api/game/duel', data: {
      'sessionId': sessionId,
      'result': result,
      'score': score,
      'correctAnswers': correctAnswers,
      'totalAnswered': totalAnswered,
      'opponentElo': opponentElo,
      'answerTimeMs': answerTimeMs,
      if (inviteId != null) 'inviteId': inviteId,
    });

    return response.data['data'] as Map<String, dynamic>;
  }
}

final duelRepository = DuelRepository();
