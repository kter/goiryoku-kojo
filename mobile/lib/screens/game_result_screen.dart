import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import 'home_screen.dart';

/// Screen to display game results and AI feedback
class GameResultScreen extends ConsumerWidget {
  final GameScore gameScore;

  const GameResultScreen({
    super.key,
    required this.gameScore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scoreColor = _getScoreColor(context, gameScore.score);

    return Scaffold(
      appBar: AppBar(
        title: Text(gameScore.gameType == GameType.wordReplacement
            ? l10n.wordReplacement
            : l10n.rhyming),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score display
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Text(
                        l10n.score,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scoreColor,
                            width: 8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${gameScore.score}',
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getScoreMessage(gameScore.score),
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Word info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.todaysWord,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gameScore.word,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Answers submitted
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '入力した回答',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (gameScore.answers.isEmpty)
                        Text(
                          '回答なし',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: gameScore.answers
                              .map((answer) => Chip(label: Text(answer)))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // AI Feedback
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.feedback,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        gameScore.feedback,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home),
                      label: Text(l10n.backToMenu),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(BuildContext context, int score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 50) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.error;
    }
  }

  String _getScoreMessage(int score) {
    if (score >= 90) {
      return '素晴らしい！語彙力の達人です！🎉';
    } else if (score >= 80) {
      return '素晴らしい成績です！👏';
    } else if (score >= 60) {
      return 'よく頑張りました！💪';
    } else if (score >= 40) {
      return 'もう少し練習しましょう！📚';
    } else {
      return '次はもっと頑張りましょう！🌟';
    }
  }
}
