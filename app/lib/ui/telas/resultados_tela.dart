import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/tentativa.dart';
import '../widgets/conteudo_view.dart';

/// Resultados do quiz: totais, percentual de acerto e a lista detalhada de
/// questões com a alternativa escolhida, a correta e as explicações
/// (requisitos, seções 4.6 e 15).
class ResultadosTela extends StatelessWidget {
  final Tentativa tentativa;

  const ResultadosTela({super.key, required this.tentativa});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${tentativa.percentualAcerto.toStringAsFixed(0)}%',
                    style: theme.textTheme.displaySmall,
                  ),
                  Text('de acerto', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Metrica(
                          valor: '${tentativa.total}', rotulo: 'Respondidas'),
                      _Metrica(
                        valor: '${tentativa.acertos}',
                        rotulo: 'Corretas',
                        cor: Colors.green,
                      ),
                      _Metrica(
                        valor: '${tentativa.erros}',
                        rotulo: 'Incorretas',
                        cor: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Revisão das questões',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...tentativa.respostas.asMap().entries.map(
                (e) => _RespostaCard(indice: e.key + 1, resposta: e.value),
              ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.home),
            label: const Text('Voltar ao início'),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  final String valor;
  final String rotulo;
  final Color? cor;

  const _Metrica({required this.valor, required this.rotulo, this.cor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(valor,
            style: theme.textTheme.headlineSmall?.copyWith(color: cor)),
        Text(rotulo, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _RespostaCard extends StatelessWidget {
  final int indice;
  final RespostaQuiz resposta;

  const _RespostaCard({required this.indice, required this.resposta});

  @override
  Widget build(BuildContext context) {
    final q = resposta.questao;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  resposta.acertou ? Icons.check_circle : Icons.cancel,
                  color: resposta.acertou ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text('Questão $indice',
                    style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            ConteudoView(texto: q.enunciado, tipo: q.tipoConteudo),
            const SizedBox(height: 12),
            ...q.alternativas.map((a) {
              final ehEscolhida = a.id == resposta.idAlternativaEscolhida;
              final ehCorreta = a.id == resposta.idAlternativaCorreta;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: ehCorreta
                      ? Colors.green.withValues(alpha: 0.12)
                      : (ehEscolhida
                          ? Colors.red.withValues(alpha: 0.12)
                          : null),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ehCorreta)
                          const Icon(Icons.check,
                              size: 16, color: Colors.green)
                        else if (ehEscolhida)
                          const Icon(Icons.close,
                              size: 16, color: Colors.red)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ConteudoView(
                              texto: a.texto, tipo: a.tipoConteudo),
                        ),
                        if (ehEscolhida)
                          Text('  (sua resposta)',
                              style: theme.textTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Text(a.explicacao,
                          style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
