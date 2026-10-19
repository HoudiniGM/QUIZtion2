import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/attempt.dart';
import '../../domain/content_type.dart';
import '../widgets/content_view.dart';

/// Quiz results: totals, accuracy percentage and the detailed list of
/// questions with the chosen option, the correct one and the explanations
/// (requirements, sections 4.6 and 15).
///
/// Questions start collapsed and only one can be expanded at a time. The
/// "Voltar" action is fixed at the bottom.
class ResultsScreen extends StatefulWidget {
  final Attempt attempt;

  const ResultsScreen({super.key, required this.attempt});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attempt = widget.attempt;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${attempt.accuracyPercent.toStringAsFixed(0)}%',
                    style: theme.textTheme.displaySmall,
                  ),
                  Text('de acerto', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Metric(value: '${attempt.total}', label: 'Respondidas'),
                      _Metric(
                        value: '${attempt.fullyCorrectCount}',
                        label: 'Totalmente certas',
                        color: Colors.green,
                      ),
                      _Metric(
                        value: '${attempt.notFullyCorrectCount}',
                        label: 'Demais',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Revisão das questões', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...attempt.answers.asMap().entries.map(
                (e) => _AnswerCard(
                  index: e.key + 1,
                  answer: e.value,
                  expanded: _expandedIndex == e.key,
                  onToggle: () => setState(() {
                    _expandedIndex = _expandedIndex == e.key ? null : e.key;
                  }),
                ),
              ),
        ],
      ),
      // Fixed "Voltar" button (no need to scroll to the end).
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.home),
            label: const Text('Voltar ao início'),
            onPressed: () => context.go('/'),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;

  const _Metric({required this.value, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.headlineSmall?.copyWith(color: color)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final int index;
  final QuizAnswer answer;
  final bool expanded;
  final VoidCallback onToggle;

  const _AnswerCard({
    required this.index,
    required this.answer,
    required this.expanded,
    required this.onToggle,
  });

  IconData _headerIcon() {
    if (answer.isFullyCorrect) return Icons.check_circle;
    if (answer.score <= 0) return Icons.cancel;
    return Icons.info; // partial
  }

  Color _headerColor() {
    if (answer.isFullyCorrect) return Colors.green;
    if (answer.score <= 0) return Colors.red;
    return Colors.orange; // partial
  }

  @override
  Widget build(BuildContext context) {
    final q = answer.question;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collapsed header: tap to expand/collapse.
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(_headerIcon(), color: _headerColor(), size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Questão $index',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (answer.question.isMultipleAnswer && !answer.isFullyCorrect)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${(answer.score * 100).round()}%',
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
            if (!expanded) ...[
              const SizedBox(height: 4),
              Text(
                q.statement,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (expanded) ...[
              const SizedBox(height: 8),
              Text(q.statement),
              if (q.hasCode) ...[
              const SizedBox(height: 8),
              ContentView(text: q.codeSnippet!, type: ContentType.code),
            ],
            const SizedBox(height: 12),
            ...q.options.map((o) {
              final isChosen = answer.chosenOptionIds.contains(o.id);
              final isCorrect = answer.correctOptionIds.contains(o.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isCorrect
                      ? Colors.green.withValues(alpha: 0.12)
                      : (isChosen
                          ? Colors.red.withValues(alpha: 0.12)
                          : null),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCorrect)
                          const Icon(Icons.check,
                              size: 16, color: Colors.green)
                        else if (isChosen)
                          const Icon(Icons.close, size: 16, color: Colors.red)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child:
                              ContentView(text: o.text, type: o.contentType),
                        ),
                        if (isChosen)
                          Text('  (sua resposta)',
                              style: theme.textTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Text(o.explanation,
                          style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              );
            }),
            ],
          ],
        ),
      ),
    );
  }
}
