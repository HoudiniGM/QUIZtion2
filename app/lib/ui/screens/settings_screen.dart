import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../widgets/brand_logo.dart';

/// Settings screen (requirements, section 4.8).
///
/// Lets the user configure the backend URL and shows useful info about the
/// connection. It NEVER shows the Gemini API key (which lives only on the
/// backend and is never sent to the app).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppState>().settings;
    _urlController = TextEditingController(text: settings.backendUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const BrandedAppBarTitle('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Aparência', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('Claro'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Escuro'),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('Sistema'),
              ),
            ],
            selected: {appState.themeMode},
            onSelectionChanged: (set) => appState.setThemeMode(set.first),
          ),
          const Divider(height: 32),
          Text('Backend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Endereço do servidor responsável por gerar questões. É necessário '
            'apenas para gerar novas questões; responder quizzes com questões '
            'já salvas funciona offline.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL do backend',
              hintText: 'http://192.168.0.10:3000',
              helperText:
                  'Para um backend local, use "http://" (não "https://").',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Salvar'),
            onPressed: () async {
              await appState.setBackendUrl(_urlController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Endereço salvo.')),
                );
                setState(() {});
              }
            },
          ),
          const Divider(height: 32),
          const _PromptEditor(),
          const Divider(height: 32),
          Text('Informações', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Backend configurado',
            value: appState.settings.hasBackendUrl ? 'Sim' : 'Não',
          ),
          _InfoRow(
            label: 'Questões salvas',
            value: '${appState.totalQuestions}',
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'A chave da API de IA fica exclusivamente no backend e nunca é '
                'exibida ou armazenada neste aplicativo.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Editor for the AI prompt template (advanced / testing).
///
/// Lets the user view, edit and test the full prompt sent to the AI. The
/// response FORMAT (JSON) is always enforced by the backend, regardless of the
/// template — so only the instructions can be changed here.
class _PromptEditor extends StatefulWidget {
  const _PromptEditor();

  @override
  State<_PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends State<_PromptEditor> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final appState = context.read<AppState>();
    // If the user already has a custom prompt, show it. Otherwise try to load
    // the backend default to pre-fill (best-effort; may fail if offline).
    final custom = appState.customPrompt;
    if (custom != null) {
      _controller.text = custom;
      setState(() => _initialized = true);
      return;
    }
    await _loadDefault(silent: true);
    setState(() => _initialized = true);
  }

  Future<void> _loadDefault({bool silent = false}) async {
    final appState = context.read<AppState>();
    setState(() => _loading = true);
    try {
      final template = await appState.fetchDefaultPrompt();
      _controller.text = template;
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível carregar o prompt padrão.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Prompt da IA',
                  style: theme.textTheme.titleMedium),
            ),
            if (appState.hasCustomPrompt)
              const Chip(
                label: Text('Personalizado'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Edite o prompt enviado à IA para gerar questões. O formato de '
          'resposta (JSON) é sempre garantido pelo sistema — você controla '
          'apenas as instruções.',
        ),
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Variáveis disponíveis (substituídas ao gerar):',
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                const Text('• {{theme}} — o tema escolhido'),
                const Text('• {{subtopic}} — o tópico escolhido'),
                const Text('• {{difficulty}} — a dificuldade'),
                const Text('• {{quantity}} — a quantidade de questões'),
                const Text('• {{material}} — material complementar (se houver)'),
                const Text('• {{existing}} — resumo de questões já existentes'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 12,
          minLines: 6,
          enabled: _initialized && !_loading,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: InputDecoration(
            hintText: _loading ? 'Carregando...' : 'Prompt enviado à IA',
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Salvar prompt'),
              onPressed: _loading
                  ? null
                  : () async {
                      await appState.setCustomPrompt(_controller.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Prompt salvo.')),
                        );
                      }
                    },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Restaurar padrão'),
              onPressed: _loading
                  ? null
                  : () async {
                      await appState.clearCustomPrompt();
                      await _loadDefault();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Prompt padrão restaurado.'),
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ],
    );
  }
}
