import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

/// Tela inicial: acesso às principais funcionalidades e um resumo simples do
/// progresso quando houver dados (requisitos, seção 4.1).
class InicioTela extends StatelessWidget {
  const InicioTela({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('QUIZtion')),
      body: state.carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ResumoCard(
                  totalQuestoes: state.totalQuestoes,
                  totalTemas: state.temas.length,
                ),
                const SizedBox(height: 24),
                _BotaoFuncao(
                  icone: Icons.quiz_outlined,
                  titulo: 'Novo quiz',
                  descricao: 'Responder questões já salvas.',
                  onTap: () => context.push('/novo-quiz'),
                ),
                _BotaoFuncao(
                  icone: Icons.inventory_2_outlined,
                  titulo: 'Banco de questões',
                  descricao: 'Consultar, filtrar e excluir questões.',
                  onTap: () => context.push('/banco'),
                ),
                _BotaoFuncao(
                  icone: Icons.auto_awesome_outlined,
                  titulo: 'Gerar questões',
                  descricao: 'Em breve (Etapa 3): geração por IA.',
                  habilitado: false,
                  onTap: () {},
                ),
                _BotaoFuncao(
                  icone: Icons.history,
                  titulo: 'Histórico',
                  descricao: 'Em breve (Etapa 2): tentativas anteriores.',
                  habilitado: false,
                  onTap: () {},
                ),
              ],
            ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final int totalQuestoes;
  final int totalTemas;

  const _ResumoCard({required this.totalQuestoes, required this.totalTemas});

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
            if (totalQuestoes == 0)
              const Text(
                'Ainda não há dados suficientes. Comece respondendo um quiz '
                'com as questões de exemplo.',
              )
            else
              Row(
                children: [
                  _Metrica(valor: '$totalQuestoes', rotulo: 'Questões'),
                  const SizedBox(width: 24),
                  _Metrica(valor: '$totalTemas', rotulo: 'Temas'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  final String valor;
  final String rotulo;

  const _Metrica({required this.valor, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(valor, style: theme.textTheme.headlineMedium),
        Text(rotulo, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _BotaoFuncao extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback onTap;
  final bool habilitado;

  const _BotaoFuncao({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.onTap,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icone),
        title: Text(titulo),
        subtitle: Text(descricao),
        trailing: habilitado
            ? const Icon(Icons.chevron_right)
            : const Icon(Icons.lock_clock, size: 18),
        enabled: habilitado,
        onTap: habilitado ? onTap : null,
      ),
    );
  }
}
