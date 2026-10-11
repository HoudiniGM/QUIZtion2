import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/alternativa.dart';
import '../../domain/questao.dart';
import '../../state/quiz_controller.dart';
import '../widgets/conteudo_view.dart';

/// Tela do quiz: uma questão por vez, confirmação com "Responder" (definitiva),
/// feedback de correto/incorreto e explicação de cada alternativa
/// (requisitos, seções 4.5 e 14).
class QuizTela extends StatelessWidget {
  final String tema;
  final List<String> subtopicos;
  final List<Questao> questoes;

  const QuizTela({
    super.key,
    required this.tema,
    required this.subtopicos,
    required this.questoes,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizController(
        tema: tema,
        subtopicos: subtopicos,
        questoesEmbaralhadas: questoes,
      ),
      child: const _QuizView(),
    );
  }
}

class _QuizView extends StatelessWidget {
  const _QuizView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<QuizController>();
    final estado = ctrl.atual;
    final questao = estado.questao;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final sair = await _confirmarSair(context);
        if (sair == true && context.mounted) context.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Questão ${ctrl.indiceAtual + 1} de ${ctrl.total}'),
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: (ctrl.indiceAtual + 1) / ctrl.total,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '${questao.tema} • ${questao.subtopico} • '
                    '${questao.dificuldade.rotulo}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 12),
                  ConteudoView(
                    texto: questao.enunciado,
                    tipo: questao.tipoConteudo,
                    estiloTexto: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  ...questao.alternativas.map(
                    (a) => _AlternativaCard(
                      alternativa: a,
                      selecionada: estado.idSelecionado == a.id,
                      respondida: ctrl.respondida,
                      idCorreta: questao.alternativaCorreta.id,
                      onTap: ctrl.respondida
                          ? null
                          : () => ctrl.selecionar(a.id),
                    ),
                  ),
                  if (ctrl.respondida) ...[
                    const SizedBox(height: 16),
                    _FeedbackResposta(acertou: estado.acertou),
                  ],
                ],
              ),
            ),
            _BarraInferior(ctrl: ctrl),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmarSair(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do quiz'),
        content: const Text(
          'Se sair agora, o progresso deste quiz será perdido. Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar quiz'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _AlternativaCard extends StatelessWidget {
  final Alternativa alternativa;
  final bool selecionada;
  final bool respondida;
  final String idCorreta;
  final VoidCallback? onTap;

  const _AlternativaCard({
    required this.alternativa,
    required this.selecionada,
    required this.respondida,
    required this.idCorreta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ehCorreta = alternativa.id == idCorreta;

    Color? cor;
    if (respondida) {
      if (ehCorreta) {
        cor = Colors.green.withValues(alpha: 0.15);
      } else if (selecionada) {
        cor = Colors.red.withValues(alpha: 0.15);
      }
    } else if (selecionada) {
      cor = theme.colorScheme.primaryContainer;
    }

    return Card(
      color: cor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    respondida
                        ? (ehCorreta
                            ? Icons.check_circle
                            : (selecionada
                                ? Icons.cancel
                                : Icons.radio_button_unchecked))
                        : (selecionada
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked),
                    color: respondida
                        ? (ehCorreta
                            ? Colors.green
                            : (selecionada ? Colors.red : null))
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ConteudoView(
                      texto: alternativa.texto,
                      tipo: alternativa.tipoConteudo,
                    ),
                  ),
                ],
              ),
              if (respondida) ...[
                const SizedBox(height: 8),
                Text(
                  alternativa.explicacao,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackResposta extends StatelessWidget {
  final bool acertou;

  const _FeedbackResposta({required this.acertou});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (acertou ? Colors.green : Colors.red).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(acertou ? Icons.check_circle : Icons.cancel,
              color: acertou ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Text(
            acertou ? 'Resposta correta!' : 'Resposta incorreta.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  final QuizController ctrl;

  const _BarraInferior({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: !ctrl.respondida
            ? FilledButton(
                onPressed: ctrl.temSelecao ? () => ctrl.responder() : null,
                child: const Text('Responder'),
              )
            : (ctrl.ehUltima
                ? FilledButton.icon(
                    icon: const Icon(Icons.flag),
                    label: const Text('Finalizar'),
                    onPressed: () => _finalizar(context),
                  )
                : FilledButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Próxima questão'),
                    onPressed: () => ctrl.proxima(),
                  )),
      ),
    );
  }

  void _finalizar(BuildContext context) {
    final tentativa = ctrl.finalizar();
    context.pushReplacement('/resultados', extra: tentativa);
  }
}
