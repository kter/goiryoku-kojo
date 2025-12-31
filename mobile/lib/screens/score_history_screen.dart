import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/providers.dart';

/// Screen to display score history with charts
class ScoreHistoryScreen extends ConsumerWidget {
  const ScoreHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scores = ref.watch(scoreNotifierProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.scoreHistory),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.wordReplacement),
              Tab(text: l10n.rhyming),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ScoreHistoryTab(
              gameType: GameType.wordReplacement,
              scores: scores
                  .where((s) => s.gameType == GameType.wordReplacement)
                  .toList(),
            ),
            _ScoreHistoryTab(
              gameType: GameType.rhyming,
              scores:
                  scores.where((s) => s.gameType == GameType.rhyming).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreHistoryTab extends StatelessWidget {
  final GameType gameType;
  final List<GameScore> scores;

  const _ScoreHistoryTab({
    required this.gameType,
    required this.scores,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (scores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noScoresYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    // Sort scores by date (oldest first for chart)
    final sortedScores = List<GameScore>.from(scores)
      ..sort((a, b) => a.playedAt.compareTo(b.playedAt));

    // Take last 10 scores for chart
    final chartScores = sortedScores.length > 10
        ? sortedScores.sublist(sortedScores.length - 10)
        : sortedScores;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Statistics card
          _StatisticsCard(scores: scores),
          const SizedBox(height: 24),
          // Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'スコア推移',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _ScoreLineChart(scores: chartScores),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Recent scores list
          Text(
            '最近のスコア',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...scores.take(10).map((score) => _ScoreListItem(score: score)),
        ],
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final List<GameScore> scores;

  const _StatisticsCard({required this.scores});

  @override
  Widget build(BuildContext context) {
    final avgScore = scores.isEmpty
        ? 0.0
        : scores.map((s) => s.score).reduce((a, b) => a + b) / scores.length;
    final highScore =
        scores.isEmpty ? 0 : scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
    final totalGames = scores.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'プレイ回数',
              value: '$totalGames',
              icon: Icons.games,
            ),
            _StatItem(
              label: '平均スコア',
              value: avgScore.toStringAsFixed(1),
              icon: Icons.trending_up,
            ),
            _StatItem(
              label: '最高スコア',
              value: '$highScore',
              icon: Icons.emoji_events,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ScoreLineChart extends StatelessWidget {
  final List<GameScore> scores;

  const _ScoreLineChart({required this.scores});

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return const Center(child: Text('データなし'));
    }

    final spots = scores.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.score.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreListItem extends StatelessWidget {
  final GameScore score;

  const _ScoreListItem({required this.score});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${score.playedAt.month}/${score.playedAt.day} ${score.playedAt.hour}:${score.playedAt.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getScoreColor(score.score).withValues(alpha: 0.2),
          child: Text(
            '${score.score}',
            style: TextStyle(
              color: _getScoreColor(score.score),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(score.word),
        subtitle: Text('$dateStr • ${score.timeLimit}秒'),
        trailing: Chip(
          label: Text('${score.answers.length}語'),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
