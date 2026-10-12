import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/difficulty.dart';
import '../../state/app_state.dart';
import '../widgets/brand_logo.dart';

/// Home screen: branding header, a quick action and a simple progress summary
/// (requirements, section 4.1). Primary navigation is the bottom navbar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: BrandLogoHorizontal(
          height: 40,
          fallbackColor: theme.colorScheme.onSurface,
        ),
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Hero(theme: theme),
                const SizedBox(height: 16),
                _StatsCard(state: state),
                const SizedBox(height: 16),
                _DifficultyBreakdown(state: state),
              ],
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  final ThemeData theme;
  const _Hero({required this.theme});

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estude com quizzes gerados por IA',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Organize por tema e tópico, gere questões e teste seu '
            'conhecimento.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: scheme.primary,
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar um quiz'),
            onPressed: () => context.go('/new-quiz'),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final AppState state;
  const _StatsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seu acervo', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                  icon: Icons.help_outline,
                  value: '${state.totalQuestions}',
                  label: 'Questões',
                ),
                _Stat(
                  icon: Icons.category_outlined,
                  value: '${state.totalThemes}',
                  label: 'Temas',
                ),
                _Stat(
                  icon: Icons.account_tree_outlined,
                  value: '${state.totalSubtopics}',
                  label: 'Tópicos',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.headlineSmall),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _DifficultyBreakdown extends StatelessWidget {
  final AppState state;
  const _DifficultyBreakdown({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = state.questionsByDifficulty;
    final total = state.totalQuestions;

    if (total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Você ainda não tem questões. Gere algumas pela aba "Gerar" ou crie '
            'um tema para começar.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por dificuldade', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final d in Difficulty.values)
              _DifficultyBar(
                label: d.label,
                count: counts[d] ?? 0,
                total: total,
                color: _colorFor(d, theme),
              ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(Difficulty d, ThemeData theme) {
    switch (d) {
      case Difficulty.basic:
        return theme.colorScheme.secondary;
      case Difficulty.intermediate:
        return theme.colorScheme.primary;
      case Difficulty.advanced:
        return Colors.deepOrange;
    }
  }
}

class _DifficultyBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _DifficultyBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text('$count', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
