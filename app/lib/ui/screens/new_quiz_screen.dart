import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/quiz_selection.dart';
import '../../domain/shuffler.dart';
import '../../state/app_state.dart';

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
    final themes = state.themes.map((t) => t.name).toList();
    final subtopics =
        _theme == null ? <String>[] : state.subtopicsOfTheme(_theme!);

    return Scaffold(
      appBar: AppBar(title: const Text('Novo quiz')),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          if (_theme != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtópicos',
                    style: Theme.of(context).textTheme.titleMedium),
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
            ...subtopics.map((s) => CheckboxListTile(
                  value: _selectedSubtopics.contains(s),
                  title: Text(s),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selectedSubtopics.add(s);
                    } else {
                      _selectedSubtopics.remove(s);
                    }
                  }),
                )),
            const SizedBox(height: 16),
            Text('Quantidade de questões: $_quantity',
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _quantity.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: '$_quantity',
              onChanged: (v) => setState(() => _quantity = v.round()),
            ),
          ],
        ],
      ),
      // Fixed action button at the bottom (does not scroll with content).
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar quiz'),
            onPressed: (_theme == null || _selectedSubtopics.isEmpty)
                ? null
                : () => _start(context),
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
