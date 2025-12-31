import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'game_play_screen.dart';

/// Screen for setting up game options before playing
class GameSetupScreen extends ConsumerStatefulWidget {
  final GameType gameType;

  const GameSetupScreen({
    super.key,
    required this.gameType,
  });

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  int _selectedTimeLimit = 30;
  final List<int> _timeLimitOptions = [30, 60, 90];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todaysWord = ref.watch(todaysWordProvider);

    final gameTitle = widget.gameType == GameType.wordReplacement
        ? l10n.wordReplacement
        : l10n.rhyming;

    return Scaffold(
      appBar: AppBar(
        title: Text(gameTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Today's word display
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        l10n.todaysWord,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(height: 16),
                      todaysWord.when(
                        data: (word) {
                          if (word == null) {
                            return const Text('---');
                          }
                          return Column(
                            children: [
                              Text(
                                word.word,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (word.reading.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  word.reading,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => Text(l10n.error),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Time limit selection
              Text(
                l10n.timeLimit,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _timeLimitOptions.map((seconds) {
                  final isSelected = _selectedTimeLimit == seconds;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(l10n.seconds(seconds)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedTimeLimit = seconds;
                            });
                          }
                        },
                        showCheckmark: false,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              // Start button
              FilledButton.icon(
                onPressed: todaysWord.hasValue && todaysWord.value != null
                    ? () => _startGame(context, todaysWord.value!)
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.startGame),
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

  void _startGame(BuildContext context, Word word) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GamePlayScreen(
          gameType: widget.gameType,
          word: word,
          timeLimit: _selectedTimeLimit,
        ),
      ),
    );
  }
}
