import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/share/share_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/glass_card.dart';
import '../profile/profile_provider.dart';
import 'millionaire_repository.dart';

class MillionaireScreen extends ConsumerStatefulWidget {
  const MillionaireScreen({super.key});

  @override
  ConsumerState<MillionaireScreen> createState() => _MillionaireScreenState();
}

class _MillionaireScreenState extends ConsumerState<MillionaireScreen> {
  final Random _random = Random();

  Timer? _timer;
  bool _isLoading = true;
  bool _isFinalizing = false;
  String? _error;
  String? _sessionId;
  List<Map<String, dynamic>> _questions = const [];
  int _questionIndex = 0;
  int _currentPrize = 0;
  int _safePointReached = 0;
  int _correctAnswers = 0;
  int _totalAnswered = 0;
  int _timeRemaining = _steps.first.timeLimit;
  String? _selectedAnswer;
  String? _revealedAnswer;
  String? _firstWrongAnswer;
  bool _doubleAnswerActive = false;
  Map<String, int>? _audienceResult;
  ({String suggestion, int confidence})? _phoneResult;
  final Set<String> _usedJokers = <String>{};
  final Set<String> _eliminatedOptions = <String>{};
  Map<String, int> _jokerStock = <String, int>{};
  _GameSummary? _result;

  static const List<_MillionaireStep> _steps = [
    _MillionaireStep(
      questionNumber: 1,
      points: 100,
      difficulty: 1,
      isSafePoint: false,
      timeLimit: 30,
    ),
    _MillionaireStep(
      questionNumber: 2,
      points: 200,
      difficulty: 1,
      isSafePoint: false,
      timeLimit: 30,
    ),
    _MillionaireStep(
      questionNumber: 3,
      points: 500,
      difficulty: 1,
      isSafePoint: false,
      timeLimit: 30,
    ),
    _MillionaireStep(
      questionNumber: 4,
      points: 1000,
      difficulty: 2,
      isSafePoint: false,
      timeLimit: 25,
    ),
    _MillionaireStep(
      questionNumber: 5,
      points: 2000,
      difficulty: 2,
      isSafePoint: true,
      timeLimit: 25,
    ),
    _MillionaireStep(
      questionNumber: 6,
      points: 4000,
      difficulty: 3,
      isSafePoint: false,
      timeLimit: 25,
    ),
    _MillionaireStep(
      questionNumber: 7,
      points: 8000,
      difficulty: 3,
      isSafePoint: false,
      timeLimit: 25,
    ),
    _MillionaireStep(
      questionNumber: 8,
      points: 16000,
      difficulty: 4,
      isSafePoint: false,
      timeLimit: 20,
    ),
    _MillionaireStep(
      questionNumber: 9,
      points: 32000,
      difficulty: 4,
      isSafePoint: false,
      timeLimit: 20,
    ),
    _MillionaireStep(
      questionNumber: 10,
      points: 64000,
      difficulty: 4,
      isSafePoint: true,
      timeLimit: 20,
    ),
    _MillionaireStep(
      questionNumber: 11,
      points: 125000,
      difficulty: 4,
      isSafePoint: false,
      timeLimit: 20,
    ),
    _MillionaireStep(
      questionNumber: 12,
      points: 250000,
      difficulty: 4,
      isSafePoint: false,
      timeLimit: 20,
    ),
    _MillionaireStep(
      questionNumber: 13,
      points: 500000,
      difficulty: 5,
      isSafePoint: false,
      timeLimit: 15,
    ),
    _MillionaireStep(
      questionNumber: 14,
      points: 750000,
      difficulty: 5,
      isSafePoint: false,
      timeLimit: 15,
    ),
    _MillionaireStep(
      questionNumber: 15,
      points: 1000000,
      difficulty: 5,
      isSafePoint: false,
      timeLimit: 15,
    ),
  ];

  static const List<String> _jokerOrder = [
    'fifty_fifty',
    'audience',
    'phone',
    'freeze_time',
    'skip',
    'double_answer',
  ];

  static const Map<String, String> _jokerLabels = {
    'fifty_fifty': '50/50',
    'audience': 'Seyirci',
    'phone': 'Telefon',
    'freeze_time': '+15 sn',
    'skip': 'Pas',
    'double_answer': 'Çift',
  };

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

  Map<String, dynamic>? get _currentQuestion {
    if (_questionIndex < 0 || _questionIndex >= _questions.length) {
      return null;
    }
    return _questions[_questionIndex];
  }

  _MillionaireStep get _currentStep => _steps[_questionIndex];

  Future<void> _initializeGame() async {
    _timer?.cancel();
    setState(() {
      _isLoading = true;
      _isFinalizing = false;
      _error = null;
      _result = null;
      _selectedAnswer = null;
      _revealedAnswer = null;
      _firstWrongAnswer = null;
      _doubleAnswerActive = false;
      _audienceResult = null;
      _phoneResult = null;
      _usedJokers.clear();
      _eliminatedOptions.clear();
    });

    try {
      final data = await millionaireRepository.startGame();
      final questions = (data['questions'] as List<dynamic>? ?? [])
          .map((question) => Map<String, dynamic>.from(question as Map))
          .toList();
      final profile = Map<String, dynamic>.from(
        data['profile'] as Map? ?? <String, dynamic>{},
      );
      final sessionId = data['sessionId']?.toString();

      if (questions.length < _steps.length ||
          sessionId == null ||
          sessionId.isEmpty) {
        throw Exception('Millionaire akışı için yeterli veri gelmedi.');
      }

      setState(() {
        _sessionId = sessionId;
        _questions = questions;
        _questionIndex = 0;
        _currentPrize = 0;
        _safePointReached = 0;
        _correctAnswers = 0;
        _totalAnswered = 0;
        _jokerStock = _readJokerStock(profile);
        _timeRemaining = _steps.first.timeLimit;
        _isLoading = false;
      });

      ref.invalidate(profileProvider);
      analyticsService.track('game_started', {'mode': 'millionaire'});
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
        _handleTimeout();
        return;
      }

      setState(() => _timeRemaining -= 1);
    });
  }

  Future<void> _handleTimeout() async {
    await _finalizeGame(result: 'timeout', score: _safePointReached);
  }

  Future<void> _handleAnswerTap(String key) async {
    if (_selectedAnswer != null ||
        _isFinalizing ||
        _result != null ||
        _eliminatedOptions.contains(key)) {
      return;
    }

    final question = _currentQuestion;
    if (question == null) {
      return;
    }

    final correctAnswer = question['correct_answer']?.toString();

    if (_doubleAnswerActive &&
        _firstWrongAnswer == null &&
        key != correctAnswer) {
      setState(() {
        _firstWrongAnswer = key;
        _eliminatedOptions.add(key);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çift cevap jokeri aktif. Bir tahmin hakkın daha var.'),
        ),
      );
      return;
    }

    _timer?.cancel();
    setState(() => _selectedAnswer = key);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }

    final isCorrect = key == correctAnswer;
    final nextAnswered = _totalAnswered + 1;
    final nextCorrect = _correctAnswers + (isCorrect ? 1 : 0);
    final nextPrize = isCorrect ? _currentStep.points : _currentPrize;
    final nextSafePoint = isCorrect && _currentStep.isSafePoint
        ? _currentStep.points
        : _safePointReached;

    setState(() {
      _revealedAnswer = correctAnswer;
      _totalAnswered = nextAnswered;
      _correctAnswers = nextCorrect;
      _currentPrize = nextPrize;
      _safePointReached = nextSafePoint;
    });

    await Future<void>.delayed(const Duration(milliseconds: 950));

    if (!mounted) {
      return;
    }

    if (!isCorrect) {
      await _finalizeGame(result: 'loss', score: _safePointReached);
      return;
    }

    if (_questionIndex == _steps.length - 1) {
      await _finalizeGame(result: 'win', score: _currentStep.points);
      return;
    }

    _goToNextQuestion();
  }

  void _goToNextQuestion() {
    setState(() {
      _questionIndex += 1;
      _selectedAnswer = null;
      _revealedAnswer = null;
      _firstWrongAnswer = null;
      _doubleAnswerActive = false;
      _audienceResult = null;
      _phoneResult = null;
      _eliminatedOptions.clear();
      _timeRemaining = _steps[_questionIndex].timeLimit;
    });
    _startTimer();
  }

  Future<void> _useJoker(String jokerType) async {
    if (_isFinalizing || _result != null || _selectedAnswer != null) {
      return;
    }

    final question = _currentQuestion;
    if (question == null) {
      return;
    }

    final stock = _jokerStock[jokerType] ?? 0;
    if (stock <= 0 || _usedJokers.contains(jokerType)) {
      return;
    }

    try {
      final data = await millionaireRepository.useJoker(jokerType);
      final profile = Map<String, dynamic>.from(
        data['profile'] as Map? ?? <String, dynamic>{},
      );

      setState(() {
        _jokerStock = _readJokerStock(profile);
        _usedJokers.add(jokerType);
      });
      ref.invalidate(profileProvider);

      switch (jokerType) {
        case 'fifty_fifty':
          final correct = question['correct_answer']?.toString();
          final wrongOptions =
              _options
                  .where(
                    (option) =>
                        option.key != correct &&
                        !_eliminatedOptions.contains(option.key),
                  )
                  .map((option) => option.key)
                  .toList()
                ..shuffle(_random);
          setState(() {
            _eliminatedOptions.addAll(wrongOptions.take(2));
          });
          break;
        case 'audience':
          final correct = question['correct_answer']?.toString() ?? 'A';
          final correctPercent = 40 + _random.nextInt(31);
          final remaining = 100 - correctPercent;
          final others = _options
              .map((item) => item.key)
              .where((key) => key != correct)
              .toList();
          final r1 = _random.nextInt(remaining + 1);
          final r2 = _random.nextInt(remaining - r1 + 1);
          final r3 = remaining - r1 - r2;
          setState(() {
            _audienceResult = {
              correct: correctPercent,
              others[0]: r1,
              others[1]: r2,
              others[2]: r3,
            };
          });
          break;
        case 'phone':
          final correct = question['correct_answer']?.toString() ?? 'A';
          final confidence = 60 + _random.nextInt(31);
          final suggestion = _random.nextDouble() < 0.8
              ? correct
              : _options
                    .map((item) => item.key)
                    .where((key) => key != correct)
                    .toList()[_random.nextInt(3)];
          setState(() {
            _phoneResult = (suggestion: suggestion, confidence: confidence);
          });
          break;
        case 'freeze_time':
          setState(() => _timeRemaining += 15);
          break;
        case 'skip':
          setState(() {
            _totalAnswered += 1;
          });
          if (_questionIndex == _steps.length - 1) {
            await _finalizeGame(result: 'win', score: _currentPrize);
            return;
          }
          _goToNextQuestion();
          break;
        case 'double_answer':
          setState(() {
            _doubleAnswerActive = true;
          });
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_humanizeError(error))));
    }
  }

  Future<void> _finalizeGame({
    required String result,
    required int score,
  }) async {
    if (_isFinalizing || _sessionId == null) {
      return;
    }

    _timer?.cancel();
    setState(() {
      _isFinalizing = true;
      _selectedAnswer ??= 'LOCKED';
    });

    try {
      final data = await millionaireRepository.finishGame(
        sessionId: _sessionId!,
        result: result,
        score: score,
        correctAnswers: _correctAnswers,
        totalAnswered: _totalAnswered,
        safePointReached: _safePointReached,
        jokersUsed: _usedJokers.toList(),
      );
      final profile = Map<String, dynamic>.from(
        data['profile'] as Map? ?? <String, dynamic>{},
      );
      final rewards = Map<String, dynamic>.from(
        data['rewards'] as Map? ?? <String, dynamic>{},
      );
      analyticsService.track('game_completed', {
        'mode': 'millionaire',
        'result': result,
        'score': score,
        'correct_answers': _correctAnswers,
        'total_answered': _totalAnswered,
      });

      setState(() {
        _result = _GameSummary(
          result: result,
          score: score,
          safePointReached: _safePointReached,
          correctAnswers: _correctAnswers,
          totalAnswered: _totalAnswered,
          questionReached: _questionIndex + (result == 'win' ? 1 : 0),
          xpEarned: _asInt(rewards['xp']),
          coinsEarned: _asInt(rewards['coins']),
          profile: profile,
        );
      });
      ref.invalidate(profileProvider);
    } catch (error) {
      setState(() {
        _error = _humanizeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFinalizing = false;
          if (_selectedAnswer == 'LOCKED') {
            _selectedAnswer = null;
          }
        });
      }
    }
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

  Map<String, int> _readJokerStock(Map<String, dynamic>? profile) {
    final settings = profile?['settings'];
    if (settings is! Map) {
      return {for (final joker in _jokerOrder) joker: 0};
    }

    final jokers = settings['jokers'];
    if (jokers is! Map) {
      return {for (final joker in _jokerOrder) joker: 0};
    }

    return {for (final joker in _jokerOrder) joker: _asInt(jokers[joker])};
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _humanizeError(Object error) {
    final text = error.toString();
    if (text.contains('Insufficient energy')) {
      return 'Millionaire için yeterli enerji yok.';
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

  void _showPrizeLadder() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Ödül Basamakları',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            for (final step in _steps.reversed)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: step.questionNumber == _questionIndex + 1
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('Soru ${step.questionNumber}')),
                    if (step.isSafePoint)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          'Güvenli',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    Text(
                      _formatCompact(step.points),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null && _result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Millionaire')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _initializeGame,
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_result != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Oyun Özeti')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassCard(
              variant: GlassCardVariant.gold,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_result!.headline, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Skor: ${_formatCompact(_result!.score)} · Güvenli nokta: ${_formatCompact(_result!.safePointReached)}',
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
                  label: 'Ulaşılan soru',
                  value: '${_result!.questionReached}/15',
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Güncel profil', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text('Level: ${_asInt(_result!.profile['level'])}'),
                  Text('XP: ${_formatCompact(_asInt(_result!.profile['xp']))}'),
                  Text(
                    'Coin: ${_formatCompact(_asInt(_result!.profile['coins']))}',
                  ),
                  Text('Enerji: ${_asInt(_result!.profile['energy'])}/5'),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                mode: 'Millionaire',
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
    final options = _options;
    if (question == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final prizeProgress = _currentStep.points / _steps.last.points;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Millionaire'),
        actions: [
          IconButton(
            onPressed: _showPrizeLadder,
            tooltip: 'Ödül basamakları',
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: _TopMetricCard(
                    label: 'Soru',
                    value: '${_questionIndex + 1}/15',
                    icon: Icons.help_outline_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TopMetricCard(
                    label: 'Süre',
                    value: '$_timeRemaining sn',
                    icon: Icons.timer_outlined,
                    accent: _timeRemaining <= 5
                        ? theme.colorScheme.error
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TopMetricCard(
                    label: 'Güvenli',
                    value: _formatCompact(_safePointReached),
                    icon: Icons.lock_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppProgressBar(
              value: (_timeRemaining / _currentStep.timeLimit).clamp(0, 1),
              tone: _timeRemaining <= 3
                  ? AppProgressTone.danger
                  : _timeRemaining <= 5
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
                    'Ödül: ${_formatCompact(_currentStep.points)}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kategori: ${question['category'] ?? '-'} · Zorluk ${_currentStep.difficulty}/5',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question['question_text']?.toString() ?? '-',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  AppProgressBar(
                    value: prizeProgress,
                    tone: AppProgressTone.gold,
                    height: 8,
                  ),
                ],
              ),
            ),
            if (_audienceResult != null) ...[
              const SizedBox(height: 16),
              _AudienceCard(result: _audienceResult!),
            ],
            if (_phoneResult != null) ...[
              const SizedBox(height: 16),
              _PhoneCard(data: _phoneResult!),
            ],
            const SizedBox(height: 16),
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AnswerButton(
                  option: option,
                  isDisabled:
                      _isFinalizing ||
                      _selectedAnswer != null ||
                      _eliminatedOptions.contains(option.key),
                  isSelected: _selectedAnswer == option.key,
                  isCorrect:
                      _revealedAnswer == option.key &&
                      question['correct_answer']?.toString() == option.key,
                  isWrong:
                      _revealedAnswer != null &&
                      _selectedAnswer == option.key &&
                      question['correct_answer']?.toString() != option.key,
                  isEliminated: _eliminatedOptions.contains(option.key),
                  onTap: () => _handleAnswerTap(option.key),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Jokerler', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _jokerOrder.map((jokerType) {
                final stock = _jokerStock[jokerType] ?? 0;
                return _JokerButton(
                  label: _jokerLabels[jokerType] ?? jokerType,
                  stock: stock,
                  isUsed: _usedJokers.contains(jokerType),
                  onTap: () => _useJoker(jokerType),
                );
              }).toList(),
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

class _MillionaireStep {
  const _MillionaireStep({
    required this.questionNumber,
    required this.points,
    required this.difficulty,
    required this.isSafePoint,
    required this.timeLimit,
  });

  final int questionNumber;
  final int points;
  final int difficulty;
  final bool isSafePoint;
  final int timeLimit;
}

class _OptionItem {
  const _OptionItem({required this.key, required this.text});

  final String key;
  final String text;
}

class _GameSummary {
  const _GameSummary({
    required this.result,
    required this.score,
    required this.safePointReached,
    required this.correctAnswers,
    required this.totalAnswered,
    required this.questionReached,
    required this.xpEarned,
    required this.coinsEarned,
    required this.profile,
  });

  final String result;
  final int score;
  final int safePointReached;
  final int correctAnswers;
  final int totalAnswered;
  final int questionReached;
  final int xpEarned;
  final int coinsEarned;
  final Map<String, dynamic> profile;

  String get headline {
    switch (result) {
      case 'win':
        return 'Tebrikler, büyük ödülü kazandın!';
      case 'timeout':
        return 'Süre doldu.';
      default:
        return 'Oyun bitti.';
    }
  }
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
    required this.isEliminated,
  });

  final _OptionItem option;
  final VoidCallback onTap;
  final bool isDisabled;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool isEliminated;

  @override
  Widget build(BuildContext context) {
    Color accent = Colors.white;
    var variant = GlassCardVariant.elevated;

    if (isCorrect) {
      accent = AppColors.success;
      variant = GlassCardVariant.highlighted;
    } else if (isWrong) {
      accent = AppColors.danger;
      variant = GlassCardVariant.highlighted;
    } else if (isSelected) {
      accent = AppColors.gold;
      variant = GlassCardVariant.gold;
    }

    return Opacity(
      opacity: isEliminated ? 0.38 : 1,
      child: GlassCard(
        onTap: isDisabled ? null : onTap,
        variant: variant,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: accent.withValues(alpha: 0.18),
              child: Text(
                option.key,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(option.text)),
            if (isCorrect) const Icon(Icons.check_circle_rounded, color: AppColors.success),
            if (isWrong) const Icon(Icons.cancel_rounded, color: AppColors.danger),
          ],
        ),
      ),
    );
  }
}

class _JokerButton extends StatelessWidget {
  const _JokerButton({
    required this.label,
    required this.stock,
    required this.isUsed,
    required this.onTap,
  });

  final String label;
  final int stock;
  final bool isUsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = stock > 0 && !isUsed;

    return SizedBox(
      width: 104,
      child: GlassCard(
        onTap: enabled ? onTap : null,
        variant: enabled ? GlassCardVariant.highlighted : GlassCardVariant.elevated,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            AppBadge(
              label: isUsed ? 'Kullanıldı' : 'Stok: $stock',
              tone: enabled ? AppBadgeTone.primary : AppBadgeTone.neutral,
            ),
          ],
        ),
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  const _AudienceCard({required this.result});

  final Map<String, int> result;

  @override
  Widget build(BuildContext context) {
    final maxValue = result.values.fold<int>(
      1,
      (max, value) => value > max ? value : max,
    );

    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seyirci jokeri', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: result.entries.map((entry) {
              final height = (entry.value / maxValue) * 80;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text('%${entry.value}'),
                      const SizedBox(height: 6),
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(entry.key),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.data});

  final ({String suggestion, int confidence}) data;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.elevated,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Telefon jokeri', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('Arkadaşın ${data.suggestion} cevabını öneriyor.'),
          const SizedBox(height: 6),
          Text('Güven: %${data.confidence}'),
        ],
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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
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
