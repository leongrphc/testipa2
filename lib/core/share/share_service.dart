import 'package:share_plus/share_plus.dart';

class ShareService {
  Future<void> shareGameResult({
    required String mode,
    required int score,
    required int correctAnswers,
    required int totalAnswered,
  }) async {
    final accuracy = totalAnswered == 0
        ? 0
        : ((correctAnswers / totalAnswered) * 100).round();
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Futbol Bilgi sonucu',
        text:
            'Futbol Bilgi $mode sonucum: $score puan, $correctAnswers/$totalAnswered doğru, %$accuracy başarı.',
      ),
    );
  }

  Future<void> shareText({
    required String subject,
    required String text,
  }) async {
    await SharePlus.instance.share(ShareParams(subject: subject, text: text));
  }
}

final shareService = ShareService();
