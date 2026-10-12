import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/difficulty.dart';
import '../../state/app_state.dart';
import '../../state/generation_controller.dart';
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
    final subtopics =
        _theme == null ? <String>[] : appState.subtopicsOfTheme(_theme!);

    final canGenerate = _theme != null &&
        _subtopic != null &&
        !controller.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Gerar questões')),
      body: AbsorbPointer(
        absorbing: controller.isLoading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!appState.settings.hasBackendUrl) const _BackendWarning(),
            SelectorWithCreate(
              label: 'Tema *',
              createLabel: 'Criar tema',
              options: themes,
              value: _theme,
              onSelected: (v) => setState(() {
                _theme = v;
                _subtopic = null;
              }),
              onCreate: (name) async {
                final created = await appState.createTheme(name);
                setState(() {
                  _theme = created;
                  _subtopic = null;
                });
                return created;
              },
            ),
            const SizedBox(height: 12),
            SelectorWithCreate(
              label: 'Subtópico *',
              createLabel: 'Criar subtópico',
              options: subtopics,
              value: _subtopic,
              enabled: _theme != null,
              onSelected: (v) => setState(() => _subtopic = v),
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
              onChanged: (v) =>
                  setState(() => _difficulty = v ?? Difficulty.basic),
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
              onChanged: (v) => setState(() => _quantity = v.round()),
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
