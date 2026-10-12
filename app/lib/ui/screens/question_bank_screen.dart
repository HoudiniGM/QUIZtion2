import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/content_type.dart';
import '../../domain/question.dart';
import '../../state/app_state.dart';
import '../theme_icons.dart';
import '../widgets/brand_logo.dart';
import '../widgets/content_view.dart';
import '../widgets/icon_picker.dart';

/// Question bank as a collapsible tree (requirements, section 4.3):
///   Theme → (expand) Topics → (expand) Questions (collapsed).
///
/// Only one node can be open per level: expanding one collapses any other at
/// the same level (and resets the deeper selections).
class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  String? _openTheme;
  String? _openTopic;
  String? _openQuestionId;

  void _toggleTheme(String name) => setState(() {
        if (_openTheme == name) {
          _openTheme = null;
        } else {
          _openTheme = name;
        }
        _openTopic = null;
        _openQuestionId = null;
      });

  void _toggleTopic(String name) => setState(() {
        _openTopic = _openTopic == name ? null : name;
        _openQuestionId = null;
      });

  void _toggleQuestion(String id) => setState(() {
        _openQuestionId = _openQuestionId == id ? null : id;
      });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const BrandedAppBarTitle('Banco de questões')),
      body: state.themes.isEmpty
          ? const _EmptyBank()
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final theme in state.themes)
                  _ThemeTile(
                    themeName: theme.name,
                    state: state,
                    expanded: _openTheme == theme.name,
                    onToggle: () => _toggleTheme(theme.name),
                    openTopic: _openTopic,
                    onToggleTopic: _toggleTopic,
                    openQuestionId: _openQuestionId,
                    onToggleQuestion: _toggleQuestion,
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
          'Nenhum tema ainda. Crie um tema e gere questões para começar.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Level 1: theme.
class _ThemeTile extends StatelessWidget {
  final String themeName;
  final AppState state;
  final bool expanded;
  final VoidCallback onToggle;
  final String? openTopic;
  final ValueChanged<String> onToggleTopic;
  final String? openQuestionId;
  final ValueChanged<String> onToggleQuestion;

  const _ThemeTile({
    required this.themeName,
    required this.state,
    required this.expanded,
    required this.onToggle,
    required this.openTopic,
    required this.onToggleTopic,
    required this.openQuestionId,
    required this.onToggleQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtopics = state.subtopicsOfTheme(themeName);
    final questionCount = state.filter(theme: themeName).length;
    final iconId = state.iconOfTheme(themeName);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          ListTile(
            leading:
                Icon(ThemeIcons.byId(iconId), color: theme.colorScheme.primary),
            title: Text(
              themeName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('$questionCount questão(ões)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopupMenuButton<String>(
                  onSelected: (v) => _onThemeMenu(context, v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'icon', child: Text('Alterar ícone')),
                    PopupMenuItem(value: 'delete', child: Text('Excluir tema')),
                  ],
                ),
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
            onTap: onToggle,
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: subtopics.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Nenhum tópico neste tema.'),
                      ),
                    )
                  : Column(
                      children: [
                        for (final sub in subtopics)
                          _SubtopicTile(
                            themeName: themeName,
                            subtopicName: sub,
                            state: state,
                            expanded: openTopic == sub,
                            onToggle: () => onToggleTopic(sub),
                            openQuestionId: openQuestionId,
                            onToggleQuestion: onToggleQuestion,
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Future<void> _onThemeMenu(BuildContext context, String action) async {
    if (action == 'icon') {
      final iconId = await showThemeIconPicker(
        context,
        currentIconId: state.iconOfTheme(themeName),
      );
      if (iconId != null) {
        await state.updateThemeIcon(themeName: themeName, icon: iconId);
      }
      return;
    }
    if (action == 'delete') {
      final ok = await _confirm(
        context,
        title: 'Excluir tema',
        message: 'Excluir o tema "$themeName" remove todos os seus tópicos e '
            'questões. Esta ação não pode ser desfeita.',
      );
      if (ok == true) {
        await state.deleteTheme(themeName);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tema "$themeName" excluído.')),
          );
        }
      }
    }
  }
}

Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
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
}

/// Level 2: topic.
class _SubtopicTile extends StatelessWidget {
  final String themeName;
  final String subtopicName;
  final AppState state;
  final bool expanded;
  final VoidCallback onToggle;
  final String? openQuestionId;
  final ValueChanged<String> onToggleQuestion;

  const _SubtopicTile({
    required this.themeName,
    required this.subtopicName,
    required this.state,
    required this.expanded,
    required this.onToggle,
    required this.openQuestionId,
    required this.onToggleQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questions =
        state.filter(theme: themeName, subtopics: [subtopicName]);

    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.account_tree_outlined,
            size: 20,
            color: theme.colorScheme.secondary,
          ),
          title: Text(subtopicName),
          subtitle: Text('${questions.length} questão(ões)'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<String>(
                onSelected: (v) => _onTopicMenu(context, v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Excluir tópico')),
                ],
              ),
              Icon(expanded ? Icons.expand_less : Icons.expand_more),
            ],
          ),
          onTap: onToggle,
        ),
        if (expanded)
          if (questions.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nenhuma questão neste tópico.'),
              ),
            )
          else
            Column(
              children: [
                for (final q in questions)
                  _QuestionTile(
                    question: q,
                    expanded: openQuestionId == q.id,
                    onToggle: () => onToggleQuestion(q.id),
                  ),
              ],
            ),
      ],
    );
  }

  Future<void> _onTopicMenu(BuildContext context, String action) async {
    if (action == 'delete') {
      final ok = await _confirm(
        context,
        title: 'Excluir tópico',
        message: 'Excluir o tópico "$subtopicName" remove todas as suas '
            'questões. Esta ação não pode ser desfeita.',
      );
      if (ok == true) {
        await state.deleteSubtopic(
          themeName: themeName,
          subtopicName: subtopicName,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tópico "$subtopicName" excluído.')),
          );
        }
      }
    }
  }
}

/// Level 3: a single question.
class _QuestionTile extends StatelessWidget {
  final Question question;
  final bool expanded;
  final VoidCallback onToggle;

  const _QuestionTile({
    required this.question,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: _DifficultyDot(question: question),
          title: Text(
            question.statement,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          subtitle:
              Text(question.difficulty.label, style: theme.textTheme.bodySmall),
          trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          onTap: onToggle,
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question.statement),
                if (question.hasCode) ...[
                  const SizedBox(height: 8),
                  ContentView(
                      text: question.codeSnippet!, type: ContentType.code),
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
                                ContentView(
                                    text: o.text, type: o.contentType),
                                const SizedBox(height: 2),
                                Text(o.explanation,
                                    style: theme.textTheme.bodySmall),
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
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: 'Excluir questão',
      message: 'Tem certeza que deseja excluir esta questão? '
          'Esta ação não pode ser desfeita.',
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

class _DifficultyDot extends StatelessWidget {
  final Question question;
  const _DifficultyDot({required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (question.difficulty.id) {
      'basic' => theme.colorScheme.secondary,
      'intermediate' => theme.colorScheme.primary,
      _ => Colors.deepOrange,
    };
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
