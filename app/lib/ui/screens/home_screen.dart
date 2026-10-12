import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

/// Home screen: access to the main features and a simple progress summary when
/// there is data (requirements, section 4.1).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('QUIZtion')),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryCard(
                  totalQuestions: state.totalQuestions,
                  totalThemes: state.themes.length,
                ),
                const SizedBox(height: 24),
                _FeatureButton(
                  icon: Icons.quiz_outlined,
                  title: 'Novo quiz',
                  description: 'Responder questões já salvas.',
                  onTap: () => context.push('/new-quiz'),
                ),
                _FeatureButton(
                  icon: Icons.inventory_2_outlined,
                  title: 'Banco de questões',
                  description: 'Consultar, filtrar e excluir questões.',
                  onTap: () => context.push('/bank'),
                ),
                _FeatureButton(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Gerar questões',
                  description: 'Gerar novas questões por IA (requer internet).',
                  onTap: () => context.push('/generate'),
                ),
                _FeatureButton(
                  icon: Icons.settings_outlined,
                  title: 'Configurações',
                  description: 'Endereço do backend e informações.',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalQuestions;
  final int totalThemes;

  const _SummaryCard({required this.totalQuestions, required this.totalThemes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seu progresso', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (totalQuestions == 0)
              const Text(
                'Ainda não há dados suficientes. Comece respondendo um quiz '
                'com as questões de exemplo.',
              )
            else
              Row(
                children: [
                  _Metric(value: '$totalQuestions', label: 'Questões'),
                  const SizedBox(width: 24),
                  _Metric(value: '$totalThemes', label: 'Temas'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;

  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.headlineMedium),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool enabled;

  const _FeatureButton({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: enabled
            ? const Icon(Icons.chevron_right)
            : const Icon(Icons.lock_clock, size: 18),
        enabled: enabled,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
