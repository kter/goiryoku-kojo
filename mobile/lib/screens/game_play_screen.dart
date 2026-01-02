import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'game_result_screen.dart';

/// Timer-based game play screen
class GamePlayScreen extends ConsumerStatefulWidget {
  final GameType gameType;
  final Word word;
  final int timeLimit;

  const GamePlayScreen({
    super.key,
    required this.gameType,
    required this.word,
    required this.timeLimit,
  });

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen> {
  late int _remainingSeconds;
  Timer? _timer;
  final TextEditingController _inputController = TextEditingController();
  final List<String> _answers = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeLimit;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _submitAnswers();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inputController.dispose();
    super.dispose();
  }

  void _addAnswer() {
    final text = _inputController.text.trim();
    if (text.isNotEmpty && !_answers.contains(text)) {
      setState(() {
        _answers.add(text);
        _inputController.clear();
      });
    }
  }

  void _removeAnswer(int index) {
    setState(() {
      _answers.removeAt(index);
    });
  }

  Future<void> _submitAnswers() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    _timer?.cancel();

    // Get current locale
    final locale = Localizations.localeOf(context).languageCode;
    final displayWord = widget.word.getDisplayWord(locale);

    // Get scoring service and score the answers
    final scoringService = ref.read(scoringServiceProvider);
    final result = await scoringService.scoreAnswers(
      word: displayWord,
      answers: _answers,
      gameType: widget.gameType,
      locale: locale,
    );

    // Create and save the game score
    final gameScore = GameScore(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      gameType: widget.gameType,
      word: displayWord,
      answers: _answers,
      score: result.score,
      feedback: result.feedback,
      timeLimit: widget.timeLimit,
      playedAt: DateTime.now(),
    );

    await ref.read(scoreNotifierProvider.notifier).addScore(gameScore);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameResultScreen(gameScore: gameScore),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = _remainingSeconds / widget.timeLimit;
    final isUrgent = _remainingSeconds <= 10;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameType == GameType.wordReplacement
            ? l10n.wordReplacement
            : l10n.rhyming),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timer
              Card(
                color: isUrgent
                    ? Theme.of(context).colorScheme.errorContainer
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '$_remainingSeconds',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isUrgent
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUrgent
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Word display
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Builder(
                    builder: (context) {
                      final locale = Localizations.localeOf(context).languageCode;
                      final displayWord = widget.word.getDisplayWord(locale);
                      return Column(
                        children: [
                          Text(
                            l10n.todaysWord,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            displayWord,
                            style:
                                Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Input field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: l10n.enterYourAnswers,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addAnswer,
                        ),
                      ),
                      onSubmitted: (_) => _addAnswer(),
                      enabled: !_isSubmitting,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Answers list
              Expanded(
                child: Card(
                  child: _answers.isEmpty
                      ? Center(
                          child: Text(
                            l10n.enterYourAnswers,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.start,
                            children: _answers.asMap().entries.map((entry) {
                              return Chip(
                                label: Text(entry.value),
                                onDeleted: _isSubmitting
                                    ? null
                                    : () => _removeAnswer(entry.key),
                                deleteIcon: const Icon(Icons.close, size: 18),
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Submit button
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitAnswers,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(l10n.submit),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
