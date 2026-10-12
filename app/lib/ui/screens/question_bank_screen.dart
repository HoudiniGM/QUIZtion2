import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/content_type.dart';
import '../../domain/difficulty.dart';
import '../../domain/question.dart';
import '../../state/app_state.dart';
import '../widgets/content_view.dart';

/// Question bank: list, filter and view/delete saved questions
/// (requirements, section 4.3).
class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  String? _theme;
  String? _subtopic;
  Difficulty? _difficulty;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final themes = state.themes.map((t) => t.name).toList();
    final subtopics =
        _theme == null ? <String>[] : state.subtopicsOfTheme(_theme!);

    final questions = state.filter(
      theme: _theme,
      subtopics: _subtopic == null ? null : [_subtopic!],
      difficulty: _difficulty,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Banco de questões')),
      body: Column(
        children: [
          _Filters(
            themes: themes,
            subtopics: subtopics,
            theme: _theme,
            subtopic: _subtopic,
            difficulty: _difficulty,
            onTheme: (v) => setState(() {
              _theme = v;
              _subtopic = null;
            }),
            onSubtopic: (v) => setState(() => _subtopic = v),
            onDifficulty: (v) => setState(() => _difficulty = v),
            onClear: () => setState(() {
              _theme = null;
              _subtopic = null;
              _difficulty = null;
            }),
          ),
          const Divider(height: 1),
          Expanded(
            child: questions.isEmpty
                ? const _EmptyBank()
                : ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (_, i) => _QuestionTile(question: questions[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBank extends StatelessWidget {
  const _EmptyBank();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Nenhuma questão encontrada para os filtros selecionados.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final List<String> themes;
  final List<String> subtopics;
  final String? theme;
  final String? subtopic;
  final Difficulty? difficulty;
  final ValueChanged<String?> onTheme;
  final ValueChanged<String?> onSubtopic;
  final ValueChanged<Difficulty?> onDifficulty;
  final VoidCallback onClear;

  const _Filters({
    required this.themes,
    required this.subtopics,
    required this.theme,
    required this.subtopic,
    required this.difficulty,
    required this.onTheme,
    required this.onSubtopic,
    required this.onDifficulty,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: theme,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tema',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...themes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
            ],
            onChanged: onTheme,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: subtopic,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Subtópico',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...subtopics
                  .map((s) => DropdownMenuItem(value: s, child: Text(s))),
            ],
            onChanged: theme == null ? null : onSubtopic,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Difficulty>(
                  initialValue: difficulty,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Dificuldade',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ...Difficulty.values.map((d) =>
                        DropdownMenuItem(value: d, child: Text(d.label))),
                  ],
                  onChanged: onDifficulty,
                ),
              ),
              IconButton(
                tooltip: 'Limpar filtros',
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionTile extends StatelessWidget {
  final Question question;

  const _QuestionTile({required this.question});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(
          question.statement,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${question.theme} • ${question.subtopic} • '
          '${question.difficulty.label}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(question.statement),
          ),
          if (question.hasCode) ...[
            const SizedBox(height: 8),
            ContentView(
              text: question.codeSnippet!,
              type: ContentType.code,
            ),
          ],
          const SizedBox(height: 12),
          ...question.options.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      o.correct
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: o.correct ? Colors.green : null,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ContentView(text: o.text, type: o.contentType),
                          const SizedBox(height: 2),
                          Text(
                            o.explanation,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir'),
              onPressed: () => _confirmDelete(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir questão'),
        content: const Text(
          'Tem certeza que deseja excluir esta questão? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AppState>().deleteQuestion(question.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Questão excluída.')),
        );
      }
    }
  }
}
