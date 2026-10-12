import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/quiz_selection.dart';
import '../../domain/shuffler.dart';
import '../../state/app_state.dart';
import '../widgets/brand_logo.dart';

/// New quiz: choose a theme, one or more subtopics (or all) and the number of
/// questions, with insufficient-quantity handling (requirements, 4.4 and 14).
class NewQuizScreen extends StatefulWidget {
  const NewQuizScreen({super.key});

  @override
  State<NewQuizScreen> createState() => _NewQuizScreenState();
}

class _NewQuizScreenState extends State<NewQuizScreen> {
  String? _theme;
  final Set<String> _selectedSubtopics = {};
  int _quantity = 5;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final themes = state.themes.map((t) => t.name).toList();

    // Guard against a theme deleted elsewhere.
    if (_theme != null && !themes.contains(_theme)) {
      _theme = null;
      _selectedSubtopics.clear();
    }
    final subtopics =
        _theme == null ? <String>[] : state.subtopicsOfTheme(_theme!);
    // Drop any selected topics that no longer exist.
    _selectedSubtopics.removeWhere((s) => !subtopics.contains(s));

    return Scaffold(
      appBar: AppBar(title: const BrandedAppBarTitle('Novo quiz')),
      body: Column(
        children: [
          // Fixed: theme selector + "Tópicos" header.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _theme,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tema',
                    border: OutlineInputBorder(),
                  ),
                  items: themes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _theme = v;
                    _selectedSubtopics.clear();
                  }),
                ),
                if (_theme != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tópicos', style: theme.textTheme.titleMedium),
                      TextButton(
                        onPressed: () => setState(() {
                          if (_selectedSubtopics.length == subtopics.length) {
                            _selectedSubtopics.clear();
                          } else {
                            _selectedSubtopics
                              ..clear()
                              ..addAll(subtopics);
                          }
                        }),
                        child: Text(
                          _selectedSubtopics.length == subtopics.length
                              ? 'Limpar'
                              : 'Selecionar todos',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Scrollable: only the topics list.
          Expanded(
            child: _theme == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Selecione um tema para ver os tópicos.'),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: subtopics
                        .map((s) => CheckboxListTile(
                              value: _selectedSubtopics.contains(s),
                              title: Text(s),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selectedSubtopics.add(s);
                                } else {
                                  _selectedSubtopics.remove(s);
                                }
                              }),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
      // Fixed footer: quantity (just above) + the start button.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quantidade de questões: $_quantity',
                  style: theme.textTheme.titleMedium),
              Slider(
                value: _quantity.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                label: '$_quantity',
                onChanged: (v) => setState(() => _quantity = v.round()),
              ),
              const SizedBox(height: 4),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar quiz'),
                onPressed: (_theme == null || _selectedSubtopics.isEmpty)
                    ? null
                    : () => _start(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    final state = context.read<AppState>();
    final available = state.filter(
      theme: _theme,
      subtopics: _selectedSubtopics.toList(),
    );
    final selection =
        QuizSelection(available: available, requested: _quantity);

    if (!selection.hasAny) {
      _showNotice(
        context,
        selection.insufficiencyMessage!,
        canStart: false,
      );
      return;
    }

    if (selection.insufficient) {
      final start = await _showNotice(
        context,
        '${selection.insufficiencyMessage!}\n\n'
        'Deseja iniciar o quiz com as ${selection.effectiveCount} questão(ões) '
        'disponível(is)?',
        canStart: true,
      );
      if (start != true) return;
    }

    // Shuffle and take the effective quantity.
    final shuffler = Shuffler();
    final prepared = shuffler
        .prepareQuiz(selection.available)
        .take(selection.effectiveCount)
        .toList();

    if (!context.mounted) return;
    context.push('/quiz', extra: {
      'theme': _theme,
      'subtopics': _selectedSubtopics.toList(),
      'questions': prepared,
    });
  }

  Future<bool?> _showNotice(
    BuildContext context,
    String message, {
    required bool canStart,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Questões disponíveis'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          if (canStart)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Iniciar assim mesmo'),
            ),
        ],
      ),
    );
  }
}
