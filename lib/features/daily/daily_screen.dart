import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/share/share_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/app_state_panel.dart';
import '../../core/widgets/glass_card.dart';
import '../profile/profile_provider.dart';
import 'daily_repository.dart';

class DailyScreen extends ConsumerStatefulWidget {
  const DailyScreen({super.key});

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen> {
  static const int _questionCount = 5;
  static const int _timeLimit = 75;
  static const int _pointsPerCorrect = 150;

  Timer? _timer;
  bool _isLoading = true;
  bool _isFinalizing = false;
  String? _error;
  String? _sessionId;
  List<Map<String, dynamic>> _questions = const [];
  int _questionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  int _totalAnswered = 0;
  int _timeRemaining = _timeLimit;
  String? _selectedAnswer;
  String? _revealedAnswer;
  _DailyResult? _result;

  Map<String, dynamic>? get _currentQuestion {
    if (_questionIndex < 0 || _questionIndex >= _questions.length) {
      return null;
    }
    return _questions[_questionIndex];
  }

  List<_OptionItem> get _options {
    final raw = (_currentQuestion?['options'] as List<dynamic>? ?? []);
    return raw
        .map((option) => Map<String, dynamic>.from(option as Map))
        .map(
          (option) => _OptionItem(
            key: option['key']?.toString() ?? '-',
            text: option['text']?.toString() ?? '-',
          ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeGame());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeGame() async {
    _timer?.cancel();
    setState(() {
      _isLoading = true;
      _isFinalizing = false;
      _error = null;
      _result = null;
      _sessionId = null;
      _questions = const [];
      _questionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _totalAnswered = 0;
      _timeRemaining = _timeLimit;
      _selectedAnswer = null;
      _revealedAnswer = null;
    });

    try {
      final data = await dailyRepository.startGame();
      final questions = (data['questions'] as List<dynamic>? ?? [])
          .map((question) => Map<String, dynamic>.from(question as Map))
          .toList();
      final sessionId = data['sessionId']?.toString();

      if (questions.length < _questionCount ||
          sessionId == null ||
          sessionId.isEmpty) {
        throw Exception('Günlük meydan okuma için yeterli veri gelmedi.');
      }

      setState(() {
        _questions = questions;
        _sessionId = sessionId;
        _isLoading = false;
      });
      analyticsService.track('game_started', {'mode': 'daily'});

      _startTimer();
    } catch (error) {
      setState(() {
        _error = _humanizeError(error);
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted ||
          _isFinalizing ||
          _result != null ||
          _selectedAnswer != null) {
        return;
      }

      if (_timeRemaining <= 1) {
        timer.cancel();
        _finalizeGame(result: 'timeout');
        return;
      }

      setState(() => _timeRemaining -= 1);
    });
  }

  Future<void> _handleAnswerTap(String key) async {
    if (_selectedAnswer != null || _isFinalizing || _result != null) {
      return;
    }

    final question = _currentQuestion;
    if (question == null) {
      return;
    }

    final correctAnswer = question['correct_answer']?.toString();
    final isCorrect = key == correctAnswer;

    _timer?.cancel();
    setState(() {
      _selectedAnswer = key;
      _revealedAnswer = correctAnswer;
      _totalAnswered += 1;
      if (isCorrect) {
        _correctAnswers += 1;
        _score += _pointsPerCorrect;
      }
    });

    await Future<void>.delayed(const Duration(milliseconds: 950));

    if (!mounted) {
      return;
    }

    if (_questionIndex == _questionCount - 1) {
      await _finalizeGame(result: 'win');
      return;
    }

    setState(() {
      _questionIndex += 1;
      _selectedAnswer = null;
      _revealedAnswer = null;
    });
    _startTimer();
  }

  Future<void> _finalizeGame({required String result}) async {
    if (_isFinalizing || _sessionId == null) {
      return;
    }

    _timer?.cancel();
    setState(() => _isFinalizing = true);

    try {
      final data = await dailyRepository.finishGame(
        sessionId: _sessionId!,
        result: result,
        score: _score,
        correctAnswers: _correctAnswers,
        totalAnswered: _totalAnswered,
      );

      final rewards = Map<String, dynamic>.from(
        data['rewards'] as Map? ?? <String, dynamic>{},
      );
      analyticsService.track('game_completed', {
        'mode': 'daily',
        'result': result,
        'score': _score,
        'correct_answers': _correctAnswers,
        'total_answered': _totalAnswered,
      });
      setState(() {
        _result = _DailyResult(
          result: result,
          score: _score,
          correctAnswers: _correctAnswers,
          totalAnswered: _totalAnswered,
          questionReached: _questionIndex + 1,
          xpEarned: _asInt(rewards['xp']),
          coinsEarned: _asInt(rewards['coins']),
          profile: Map<String, dynamic>.from(
            data['profile'] as Map? ?? <String, dynamic>{},
          ),
        );
      });
      ref.invalidate(profileProvider);
    } catch (error) {
      setState(() => _error = _humanizeError(error));
    } finally {
      if (mounted) {
        setState(() => _isFinalizing = false);
      }
    }
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _humanizeError(Object error) {
    final text = error.toString();
    if (text.contains('Daily challenge already started today')) {
      return 'Bugünkü daily challenge zaten oynanmış.';
    }
    if (text.contains('Unauthorized')) {
      return 'Oturum geçersiz. Lütfen tekrar giriş yap.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  String _formatCompact(int value) {
    if (value >= 1000000) {
      final compact = value / 1000000;
      return compact % 1 == 0
          ? '${compact.toInt()}M'
          : '${compact.toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      final compact = value / 1000;
      return compact % 1 == 0
          ? '${compact.toInt()}K'
          : '${compact.toStringAsFixed(1)}K';
    }
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: AppStatePanel.loading(message: 'Daily Challenge hazırlanıyor...'),
      );
    }

    if (_error != null && _result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Challenge')),
        body: AppStatePanel.error(
          message: _error!,
          onAction: _initializeGame,
        ),
      );
    }

    if (_result != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily Özeti')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassCard(
              variant: GlassCardVariant.highlighted,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_result!.headline, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Skor: ${_formatCompact(_result!.score)} · XP: +${_result!.xpEarned} · Coin: +${_result!.coinsEarned}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ResultStat(
                  label: 'Doğru',
                  value: '${_result!.correctAnswers}/${_result!.totalAnswered}',
                  icon: Icons.track_changes_rounded,
                ),
                _ResultStat(
                  label: 'Soru',
                  value: '${_result!.questionReached}/$_questionCount',
                  icon: Icons.flag_rounded,
                ),
                _ResultStat(
                  label: 'XP',
                  value: '+${_result!.xpEarned}',
                  icon: Icons.auto_awesome_rounded,
                ),
                _ResultStat(
                  label: 'Coin',
                  value: '+${_result!.coinsEarned}',
                  icon: Icons.monetization_on_rounded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _initializeGame,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Tekrar Oyna'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => shareService.shareGameResult(
                mode: 'Daily Challenge',
                score: _result!.score,
                correctAnswers: _result!.correctAnswers,
                totalAnswered: _result!.totalAnswered,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Sonucu Paylaş'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      );
    }

    final question = _currentQuestion;
    if (question == null) {
      return const Scaffold(
        body: AppStatePanel.loading(message: 'Soru yükleniyor...'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Challenge')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: _TopMetricCard(
                    label: 'Soru',
                    value: '${_questionIndex + 1}/$_questionCount',
                    icon: Icons.calendar_today_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TopMetricCard(
                    label: 'Süre',
                    value: '$_timeRemaining sn',
                    icon: Icons.timer_outlined,
                    accent: _timeRemaining <= 10
                        ? AppColors.danger
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TopMetricCard(
                    label: 'Skor',
                    value: _formatCompact(_score),
                    icon: Icons.local_fire_department_rounded,
                    accent: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppProgressBar(
              value: (_timeRemaining / _timeLimit).clamp(0, 1),
              tone: _timeRemaining <= 10
                  ? AppProgressTone.danger
                  : _timeRemaining <= 25
                      ? AppProgressTone.warning
                      : AppProgressTone.primary,
              height: 10,
            ),
            const SizedBox(height: 16),
            GlassCard(
              variant: GlassCardVariant.elevated,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soru ${_questionIndex + 1}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question['question_text']?.toString() ?? '-',
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ..._options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AnswerButton(
                  option: option,
                  isDisabled: _selectedAnswer != null || _isFinalizing,
                  isSelected: _selectedAnswer == option.key,
                  isCorrect:
                      _revealedAnswer == option.key &&
                      question['correct_answer']?.toString() == option.key,
                  isWrong:
                      _revealedAnswer != null &&
                      _selectedAnswer == option.key &&
                      question['correct_answer']?.toString() != option.key,
                  onTap: () => _handleAnswerTap(option.key),
                ),
              ),
            ),
            if (_isFinalizing) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionItem {
  const _OptionItem({required this.key, required this.text});

  final String key;
  final String text;
}

class _DailyResult {
  const _DailyResult({
    required this.result,
    required this.score,
    required this.correctAnswers,
    required this.totalAnswered,
    required this.questionReached,
    required this.xpEarned,
    required this.coinsEarned,
    required this.profile,
  });

  final String result;
  final int score;
  final int correctAnswers;
  final int totalAnswered;
  final int questionReached;
  final int xpEarned;
  final int coinsEarned;
  final Map<String, dynamic> profile;

  String get headline =>
      result == 'timeout' ? 'Süre doldu.' : 'Daily challenge tamamlandı.';
}

class _TopMetricCard extends StatelessWidget {
  const _TopMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      variant: accent != null ? GlassCardVariant.highlighted : GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.option,
    required this.onTap,
    required this.isDisabled,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
  });

  final _OptionItem option;
  final VoidCallback onTap;
  final bool isDisabled;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color foreground = theme.colorScheme.onSurface;
    var variant = GlassCardVariant.elevated;
    Color? accent;

    if (isCorrect) {
      foreground = AppColors.success;
      variant = GlassCardVariant.highlighted;
      accent = AppColors.success;
    } else if (isWrong) {
      foreground = AppColors.danger;
      variant = GlassCardVariant.highlighted;
      accent = AppColors.danger;
    } else if (isSelected) {
      foreground = AppColors.gold;
      variant = GlassCardVariant.gold;
    }

    return GlassCard(
      variant: variant,
      padding: EdgeInsets.zero,
      onTap: isDisabled ? null : onTap,
      child: Container(
        decoration: accent != null
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
                color: accent.withValues(alpha: 0.1),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: foreground.withValues(alpha: 0.15),
              foregroundColor: foreground,
              child: Text(
                option.key,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option.text,
                style: theme.textTheme.bodyLarge?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const Spacer(),
          Text(value, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
