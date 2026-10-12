import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/generation_api.dart';
import '../../domain/difficulty.dart';
import '../../state/app_state.dart';
import '../../state/generation_controller.dart';
import '../widgets/brand_logo.dart';
import '../widgets/icon_picker.dart';
import '../widgets/selector_with_create.dart';

/// "Gerar questões" screen (requirements, sections 4.2 and 5).
///
/// Theme and subtopic are mandatory; the generate button stays disabled until
/// both are chosen. Shows loading / success / partial / error states.
class GenerateScreen extends StatelessWidget {
  const GenerateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => GenerationController(ctx.read<AppState>()),
      child: const _GenerateView(),
    );
  }
}

class _GenerateView extends StatefulWidget {
  const _GenerateView();

  @override
  State<_GenerateView> createState() => _GenerateViewState();
}

class _GenerateViewState extends State<_GenerateView> {
  String? _theme;
  String? _subtopic;
  Difficulty _difficulty = Difficulty.basic;
  int _quantity = 3;
  final _materialController = TextEditingController();

  @override
  void dispose() {
    _materialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final controller = context.watch<GenerationController>();
    final themes = appState.themes.map((t) => t.name).toList();

    // Guard against a selected theme/topic that was deleted elsewhere (e.g. in
    // the question bank). Without this, the dropdown would hold a value absent
    // from its items and throw (the "red screen" error).
    if (_theme != null && !themes.contains(_theme)) {
      _theme = null;
      _subtopic = null;
    }
    final subtopics =
        _theme == null ? <String>[] : appState.subtopicsOfTheme(_theme!);
    if (_subtopic != null && !subtopics.contains(_subtopic)) {
      _subtopic = null;
    }

    final canGenerate = _theme != null &&
        _subtopic != null &&
        !controller.isLoading;

    return Scaffold(
      appBar: AppBar(title: const BrandedAppBarTitle('Gerar questões')),
      body: AbsorbPointer(
        absorbing: controller.isLoading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!appState.settings.hasBackendUrl) const _BackendWarning(),
            _SuggestSection(
              controller: controller,
              onSuggested: _applySuggestion,
            ),
            const SizedBox(height: 12),
            SelectorWithCreate(
              label: 'Tema *',
              createLabel: 'Criar tema',
              options: themes,
              value: _theme,
              onSelected: (v) {
                controller.reset();
                setState(() {
                  _theme = v;
                  _subtopic = null;
                });
              },
              onCreate: (name) async {
                // Offer picking an icon for the new theme (floating dialog).
                final iconId = await showThemeIconPicker(context);
                final created =
                    await appState.createTheme(name, icon: iconId);
                setState(() {
                  _theme = created;
                  _subtopic = null;
                });
                return created;
              },
            ),
            const SizedBox(height: 12),
            SelectorWithCreate(
              label: 'Tópico *',
              createLabel: 'Criar tópico',
              options: subtopics,
              value: _subtopic,
              enabled: _theme != null,
              onSelected: (v) {
                controller.reset();
                setState(() => _subtopic = v);
              },
              onCreate: (name) async {
                final created = await appState.createSubtopic(
                  theme: _theme!,
                  name: name,
                );
                setState(() => _subtopic = created);
                return created;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Difficulty>(
              initialValue: _difficulty,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Dificuldade',
                border: OutlineInputBorder(),
              ),
              items: Difficulty.values
                  .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                  .toList(),
              onChanged: (v) {
                controller.reset();
                setState(() => _difficulty = v ?? Difficulty.basic);
              },
            ),
            const SizedBox(height: 16),
            Text('Quantidade de questões: $_quantity',
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _quantity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_quantity',
              onChanged: (v) {
                controller.reset();
                setState(() => _quantity = v.round());
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _materialController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Material complementar (opcional)',
                helperText:
                    'Apenas texto colado nesta versão. Serve de orientação; '
                    'a IA pode complementar com conhecimento do tema.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            _StatusBanner(controller: controller),
          ],
        ),
      ),
      // Fixed action button at the bottom (does not scroll with content).
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: controller.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              controller.isLoading ? 'Gerando...' : 'Gerar questões',
            ),
            onPressed: canGenerate ? () => _onGenerate(context) : null,
          ),
        ),
      ),
    );
  }

  Future<void> _onGenerate(BuildContext context) async {
    final controller = context.read<GenerationController>();
    await controller.generate(
      theme: _theme!,
      subtopic: _subtopic!,
      difficulty: _difficulty,
      quantity: _quantity,
      material: _materialController.text,
    );
  }

  /// Pre-fills the theme/topic from an AI suggestion. If the suggested
  /// theme/topic does not exist yet, it is created so it becomes selectable
  /// (the user still chooses difficulty/quantity and presses Gerar).
  Future<void> _applySuggestion(ThemeSuggestion s) async {
    final appState = context.read<AppState>();
    final theme = await appState.createTheme(s.theme);
    final topic = await appState.createSubtopic(theme: theme, name: s.topic);
    if (!mounted) return;
    setState(() {
      _theme = theme;
      _subtopic = topic;
    });
  }
}

class _BackendWarning extends StatelessWidget {
  const _BackendWarning();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O endereço do backend não está configurado. Configure-o antes '
              'de gerar questões.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Abrir Configurações'),
                onPressed: () => context.go('/settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final GenerationController controller;

  const _StatusBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.message == null) return const SizedBox.shrink();

    final (color, icon) = switch (controller.status) {
      GenerationStatus.success => (Colors.green, Icons.check_circle),
      GenerationStatus.partial => (Colors.orange, Icons.info),
      GenerationStatus.error => (Colors.red, Icons.error),
      _ => (Colors.blue, Icons.info),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(controller.message!)),
        ],
      ),
    );
  }
}

/// A collapsible helper: the user describes what they want to study and the AI
/// suggests a theme/topic, which pre-fills the form.
class _SuggestSection extends StatefulWidget {
  final GenerationController controller;
  final Future<void> Function(ThemeSuggestion) onSuggested;

  const _SuggestSection({required this.controller, required this.onSuggested});

  @override
  State<_SuggestSection> createState() => _SuggestSectionState();
}

class _SuggestSectionState extends State<_SuggestSection> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Não sabe o tema?'),
        subtitle: const Text('Descreva o que quer treinar e a IA sugere.'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ex.: quero treinar herança e polimorfismo',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: widget.controller.suggesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(
                widget.controller.suggesting ? 'Sugerindo...' : 'Sugerir',
              ),
              onPressed: widget.controller.suggesting
                  ? null
                  : () => _onSuggest(context),
            ),
          ),
          if (widget.controller.status == GenerationStatus.error &&
              widget.controller.message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.controller.message!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onSuggest(BuildContext context) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final suggestion = await widget.controller.suggest(text);
    if (suggestion != null) {
      await widget.onSuggested(suggestion);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sugestão: ${suggestion.theme} › ${suggestion.topic}',
            ),
          ),
        );
      }
    }
  }
}
