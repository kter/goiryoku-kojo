import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'game_setup_screen.dart';
import 'score_history_screen.dart';

/// Home screen with game selection
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final todaysWord = ref.watch(todaysWordProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScoreHistoryScreen(),
                ),
              );
            },
            tooltip: l10n.scoreHistory,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Today's word card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        l10n.todaysWord,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      todaysWord.when(
                        data: (word) {
                          if (word == null) {
                            return Text(
                              'お題を取得中...',
                              style: Theme.of(context).textTheme.headlineMedium,
                            );
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                              if (word.meaning.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  word.meaning,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Column(
                          children: [
                            Text(
                              l10n.error,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                ref.invalidate(todaysWordProvider);
                              },
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Game selection title
              Text(
                l10n.selectGame,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Game cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 1,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: [
                    _GameCard(
                      gameType: GameType.wordReplacement,
                      title: l10n.wordReplacement,
                      description: l10n.wordReplacementDescription,
                      icon: Icons.swap_horiz,
                      color: Colors.blue,
                      onTap: () => _navigateToGameSetup(
                          context, GameType.wordReplacement),
                    ),
                    _GameCard(
                      gameType: GameType.rhyming,
                      title: l10n.rhyming,
                      description: l10n.rhymingDescription,
                      icon: Icons.music_note,
                      color: Colors.purple,
                      onTap: () =>
                          _navigateToGameSetup(context, GameType.rhyming),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGameSetup(BuildContext context, GameType gameType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameSetupScreen(gameType: gameType),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameType gameType;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.gameType,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
