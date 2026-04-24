import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/share/share_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/app_state_panel.dart';
import '../../core/widgets/glass_card.dart';
import '../profile/profile_provider.dart';
import 'tournament_repository.dart';

class TournamentScreen extends ConsumerStatefulWidget {
  const TournamentScreen({super.key});

  @override
  ConsumerState<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends ConsumerState<TournamentScreen> {
  static const int _questionsPerRound = 4;
  static const int _totalRounds = 3;
  static const int _timePerQuestion = 18;
  static const int _pointsPerCorrect = 120;
  static const int _completionXp = 180;
  static const int _completionCoins = 90;

  Timer? _timer;
  bool _isLoading = true;
  bool _isJoining = false;
  bool _isFinalizing = false;
  String? _error;
  List<Map<String, dynamic>> _tournaments = const [];
  Map<String, dynamic>? _selectedTournament;
  List<Map<String, dynamic>> _leaderboard = const [];
  List<Map<String, dynamic>> _questions = const [];
  int _round = 1;
  int _questionIndex = 0;
  int _roundScore = 0;
  int _accumulatedScore = 0;
  int _correctAnswers = 0;
  int _totalAnswered = 0;
  int _timeRemaining = _timePerQuestion;
  String? _selectedAnswer;
  String? _revealedAnswer;
  _TournamentResult? _result;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTournaments());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournaments = await tournamentRepository.fetchTournaments();
      setState(() {
        _tournaments = tournaments;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _joinTournament(Map<String, dynamic> tournament) async {
    final tournamentId = tournament['id']?.toString();
    if (tournamentId == null || tournamentId.isEmpty) {
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
      _selectedTournament = tournament;
      _result = null;
      _accumulatedScore = 0;
      _correctAnswers = 0;
      _totalAnswered = 0;
      _round = 1;
    });

    try {
      await tournamentRepository.joinTournament(tournamentId);
      final details = await tournamentRepository.fetchTournamentDetails(
        tournamentId,
      );
      final questions = await tournamentRepository.fetchQuestions(
        tournamentId,
        1,
      );

      setState(() {
        _leaderboard = (details['leaderboard'] as List<dynamic>? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _questions = questions;
        _questionIndex = 0;
        _roundScore = 0;
        _timeRemaining = _timePerQuestion;
      });
      analyticsService.track('tournament_run_started', {
        'tournament_id': tournamentId,
      });

      _startTimer();
    } catch (error) {
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _selectedTournament = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted ||
          _isFinalizing ||
          _selectedAnswer != null ||
          _result != null) {
        return;
      }

      if (_timeRemaining <= 1) {
        timer.cancel();
        _handleAnswer(null);
        return;
      }

      setState(() => _timeRemaining -= 1);
    });
  }

  Future<void> _handleAnswer(String? answer) async {
    if (_selectedAnswer != null || _isFinalizing || _result != null) {
      return;
    }

    final question = _currentQuestion;
    if (question == null) {
      return;
    }

    final correct = question['correct_answer']?.toString();
    final isCorrect = answer == correct;

    _timer?.cancel();
    setState(() {
      _selectedAnswer = answer ?? 'TIMEOUT';
      _revealedAnswer = correct;
      _totalAnswered += 1;
      if (isCorrect) {
        _correctAnswers += 1;
        _roundScore += _pointsPerCorrect;
      }
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (!mounted) {
      return;
    }

    if (_questionIndex == _questionsPerRound - 1) {
      await _completeRound();
      return;
    }

    setState(() {
      _questionIndex += 1;
      _selectedAnswer = null;
      _revealedAnswer = null;
      _timeRemaining = _timePerQuestion;
    });
    _startTimer();
  }

  Future<void> _completeRound() async {
    if (_selectedTournament == null) {
      return;
    }

    final tournamentId = _selectedTournament!['id']?.toString();
    if (tournamentId == null || tournamentId.isEmpty) {
      return;
    }

    setState(() => _isFinalizing = true);
    final totalScore = _accumulatedScore + _roundScore;

    try {
      await tournamentRepository.updateRun(
        id: tournamentId,
        score: totalScore,
        roundReached: _round,
        completed: _round >= _totalRounds,
      );

      if (_round >= _totalRounds) {
        final details = await tournamentRepository.fetchTournamentDetails(
          tournamentId,
        );
        setState(() {
          _leaderboard = (details['leaderboard'] as List<dynamic>? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _result = _TournamentResult(
            score: totalScore,
            roundReached: _round,
            correctAnswers: _correctAnswers,
            totalAnswered: _totalAnswered,
            xpEarned: _completionXp,
            coinsEarned: _completionCoins,
          );
        });
        analyticsService.track('tournament_run_completed', {
          'tournament_id': tournamentId,
          'score': totalScore,
          'correct_answers': _correctAnswers,
          'total_answered': _totalAnswered,
        });
        ref.invalidate(profileProvider);
      } else {
        final nextRound = _round + 1;
        final details = await tournamentRepository.fetchTournamentDetails(
          tournamentId,
        );
        final questions = await tournamentRepository.fetchQuestions(
          tournamentId,
          nextRound,
        );
        setState(() {
          _leaderboard = (details['leaderboard'] as List<dynamic>? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _accumulatedScore = totalScore;
          _round = nextRound;
          _questions = questions;
          _questionIndex = 0;
          _roundScore = 0;
          _selectedAnswer = null;
          _revealedAnswer = null;
          _timeRemaining = _timePerQuestion;
        });
        _startTimer();
      }
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isFinalizing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: AppStatePanel.loading(message: 'Turnuvalar yükleniyor...'),
      );
    }

    if (_error != null && _selectedTournament == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Turnuva')),
        body: AppStatePanel.error(
          message: _error!,
          onAction: _loadTournaments,
        ),
      );
    }

    if (_selectedTournament == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Turnuva')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GlassCard(
              variant: GlassCardVariant.highlighted,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Canlı Turnuvalar',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Eleme tablosuna katıl, round round ilerle ve sezon ödülünü kap.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_tournaments.isEmpty)
              const AppStatePanel.empty(message: 'Aktif turnuva bulunamadı.')
            else
              ..._tournaments.map((tournament) {
                final title = tournament['title']?.toString() ?? 'Turnuva';
                final description = tournament['description']?.toString() ?? '';
                final status = tournament['status']?.toString() ?? 'scheduled';
                final currentPlayers = tournament['current_players'] ?? 0;
                final maxPlayers = tournament['max_players'] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    variant: GlassCardVariant.elevated,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                            if (status == 'live')
                              const AppBadge(label: 'LIVE', tone: AppBadgeTone.danger)
                            else
                              const AppBadge(label: 'BEKLİYOR', tone: AppBadgeTone.warning),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(description),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text('Oyuncu: $currentPlayers/$maxPlayers'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: status == 'live' && !_isJoining
                              ? () => _joinTournament(tournament)
                              : null,
                          child: Text(
                            _isJoining
                                ? 'Katılıyor...'
                                : status == 'live'
                                ? 'Katıl ve Oyna'
                                : 'Henüz Başlamadı',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      );
    }

    if (_result != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Turnuva Özeti')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            GlassCard(
              variant: GlassCardVariant.gold,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Turnuva tamamlandı',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Skor: ${_result!.score} · Round: ${_result!.roundReached}/$_totalRounds\nXP: +${_result!.xpEarned} · Coin: +${_result!.coinsEarned}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => shareService.shareGameResult(
                mode: 'Turnuva',
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
            FilledButton.icon(
              onPressed: () => context.go('/'),
              style: FilledButton.styleFrom(
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
      appBar: AppBar(title: const Text('Turnuva')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GlassCard(
              variant: GlassCardVariant.elevated,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tur $_round/$_totalRounds',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const AppBadge(label: 'Skor:', tone: AppBadgeTone.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${_accumulatedScore + _roundScore}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppProgressBar(
              value: (_timeRemaining / _timePerQuestion).clamp(0, 1),
              tone: _timeRemaining <= 5
                  ? AppProgressTone.danger
                  : _timeRemaining <= 10
                      ? AppProgressTone.warning
                      : AppProgressTone.primary,
              height: 10,
            ),
            const SizedBox(height: 16),
            GlassCard(
              variant: GlassCardVariant.highlighted,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Soru ${_questionIndex + 1}/$_questionsPerRound', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    question['question_text']?.toString() ?? '-',
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                  onTap: () => _handleAnswer(option.key),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Leaderboard', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ..._leaderboard.take(10).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final profile = item['profiles'];
              final username = profile is List && profile.isNotEmpty
                  ? (profile.first['username']?.toString() ?? 'Oyuncu')
                  : profile is Map
                  ? (profile['username']?.toString() ?? 'Oyuncu')
                  : 'Oyuncu';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  variant: index < 3 ? GlassCardVariant.highlighted : GlassCardVariant.elevated,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: index == 0 ? AppColors.gold.withValues(alpha: 0.2) : theme.colorScheme.surfaceContainerHighest,
                        foregroundColor: index == 0 ? AppColors.gold : theme.colorScheme.onSurface,
                        child: Text('${index + 1}'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(username, style: theme.textTheme.titleMedium)),
                      Text('${item['score'] ?? 0}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }),
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

class _TournamentResult {
  const _TournamentResult({
    required this.score,
    required this.roundReached,
    required this.correctAnswers,
    required this.totalAnswered,
    required this.xpEarned,
    required this.coinsEarned,
  });

  final int score;
  final int roundReached;
  final int correctAnswers;
  final int totalAnswered;
  final int xpEarned;
  final int coinsEarned;
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
