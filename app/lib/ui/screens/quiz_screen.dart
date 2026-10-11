import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/answer_option.dart';
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
                  ContentView(
                    text: question.statement,
                    type: question.contentType,
                    textStyle: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  ...question.options.map(
                    (o) => _OptionCard(
                      option: o,
                      selected: state.selectedId == o.id,
                      answered: ctrl.answered,
                      correctId: question.correctOption.id,
                      onTap: ctrl.answered ? null : () => ctrl.select(o.id),
                    ),
                  ),
                  if (ctrl.answered) ...[
                    const SizedBox(height: 16),
                    _AnswerFeedback(correct: state.isCorrect),
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
  final String correctId;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.option,
    required this.selected,
    required this.answered,
    required this.correctId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = option.id == correctId;

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
                  Icon(
                    answered
                        ? (isCorrect
                            ? Icons.check_circle
                            : (selected
                                ? Icons.cancel
                                : Icons.radio_button_unchecked))
                        : (selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked),
                    color: answered
                        ? (isCorrect
                            ? Colors.green
                            : (selected ? Colors.red : null))
                        : null,
                  ),
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
                Text(
                  option.explanation,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerFeedback extends StatelessWidget {
  final bool correct;

  const _AnswerFeedback({required this.correct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (correct ? Colors.green : Colors.red).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(correct ? Icons.check_circle : Icons.cancel,
              color: correct ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Text(
            correct ? 'Resposta correta!' : 'Resposta incorreta.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
