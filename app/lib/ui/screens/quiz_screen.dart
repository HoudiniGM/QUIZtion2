import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/answer_option.dart';
import '../../domain/content_type.dart';
import '../../domain/question.dart';
import '../../state/quiz_controller.dart';
import '../widgets/content_view.dart';

/// Quiz screen: one question at a time, confirmation with "Responder" (final),
/// correct/incorrect feedback and the explanation of each option
/// (requirements, sections 4.5 and 14).
class QuizScreen extends StatelessWidget {
  final String theme;
  final List<String> subtopics;
  final List<Question> questions;

  const QuizScreen({
    super.key,
    required this.theme,
    required this.subtopics,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizController(
        theme: theme,
        subtopics: subtopics,
        shuffledQuestions: questions,
      ),
      child: const _QuizView(),
    );
  }
}

class _QuizView extends StatelessWidget {
  const _QuizView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<QuizController>();
    final state = ctrl.current;
    final question = state.question;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmLeave(context);
        if (leave == true && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Questão ${ctrl.currentIndex + 1} de ${ctrl.total}'),
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: (ctrl.currentIndex + 1) / ctrl.total,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '${question.theme} • ${question.subtopic} • '
                    '${question.difficulty.label}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.statement,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (question.hasCode) ...[
                    const SizedBox(height: 12),
                    ContentView(
                      text: question.codeSnippet!,
                      type: ContentType.code,
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (question.isMultipleAnswer)
                    Text(
                      'Marque todas as alternativas corretas.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  const SizedBox(height: 8),
                  ...question.options.map(
                    (o) => _OptionCard(
                      option: o,
                      selected: state.selectedIds.contains(o.id),
                      answered: ctrl.answered,
                      isCorrect: question.correctOptionIds.contains(o.id),
                      multiple: question.isMultipleAnswer,
                      onTap: ctrl.answered ? null : () => ctrl.toggle(o.id),
                    ),
                  ),
                  if (ctrl.answered) ...[
                    const SizedBox(height: 16),
                    _AnswerFeedback(score: state.score),
                  ],
                ],
              ),
            ),
            _BottomBar(ctrl: ctrl),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmLeave(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do quiz'),
        content: const Text(
          'Se sair agora, o progresso deste quiz será perdido. Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar quiz'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final AnswerOption option;
  final bool selected;
  final bool answered;
  final bool isCorrect;
  final bool multiple;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.option,
    required this.selected,
    required this.answered,
    required this.isCorrect,
    required this.multiple,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? color;
    if (answered) {
      if (isCorrect) {
        color = Colors.green.withValues(alpha: 0.15);
      } else if (selected) {
        color = Colors.red.withValues(alpha: 0.15);
      }
    } else if (selected) {
      color = theme.colorScheme.primaryContainer;
    }

    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconFor(), color: _iconColor()),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ContentView(
                      text: option.text,
                      type: option.contentType,
                    ),
                  ),
                ],
              ),
              if (answered) ...[
                const SizedBox(height: 8),
                Text(option.explanation, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor() {
    if (answered) {
      if (isCorrect) return Icons.check_circle;
      if (selected) return Icons.cancel;
      return multiple
          ? Icons.check_box_outline_blank
          : Icons.radio_button_unchecked;
    }
    // Not answered yet: checkbox for multiple-answer, radio otherwise.
    if (multiple) {
      return selected ? Icons.check_box : Icons.check_box_outline_blank;
    }
    return selected ? Icons.radio_button_checked : Icons.radio_button_unchecked;
  }

  Color? _iconColor() {
    if (!answered) return null;
    if (isCorrect) return Colors.green;
    if (selected) return Colors.red;
    return null;
  }
}

class _AnswerFeedback extends StatelessWidget {
  /// Per-question score, 0.0–1.0.
  final double score;

  const _AnswerFeedback({required this.score});

  @override
  Widget build(BuildContext context) {
    final percent = (score * 100).round();
    final (color, icon, label) = score >= 1.0
        ? (Colors.green, Icons.check_circle, 'Resposta correta!')
        : score <= 0
            ? (Colors.red, Icons.cancel, 'Resposta incorreta.')
            : (Colors.orange, Icons.info, 'Parcialmente correta — $percent%.');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final QuizController ctrl;

  const _BottomBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: !ctrl.answered
            ? FilledButton(
                onPressed: ctrl.hasSelection ? () => ctrl.answer() : null,
                child: const Text('Responder'),
              )
            : (ctrl.isLast
                ? FilledButton.icon(
                    icon: const Icon(Icons.flag),
                    label: const Text('Finalizar'),
                    onPressed: () => _finish(context),
                  )
                : FilledButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Próxima questão'),
                    onPressed: () => ctrl.next(),
                  )),
      ),
    );
  }

  void _finish(BuildContext context) {
    final attempt = ctrl.finish();
    context.pushReplacement('/results', extra: attempt);
  }
}
