import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

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
      appBar: AppBar(title: const Text('Configurações')),
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
              await appState.settings.setBackendUrl(_urlController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Endereço salvo.')),
                );
                setState(() {});
              }
            },
          ),
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
