import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/embaralhador.dart';
import '../../domain/selecao_quiz.dart';
import '../../state/app_state.dart';

/// Novo quiz: escolher tema, um ou mais subtópicos (ou todos) e a quantidade
/// de questões, com tratamento de quantidade insuficiente (requisitos, 4.4 e
/// 14).
class NovoQuizTela extends StatefulWidget {
  const NovoQuizTela({super.key});

  @override
  State<NovoQuizTela> createState() => _NovoQuizTelaState();
}

class _NovoQuizTelaState extends State<NovoQuizTela> {
  String? _tema;
  final Set<String> _subtopicosSelecionados = {};
  int _quantidade = 5;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final temas = state.temas.map((t) => t.nome).toList();
    final subtopicos =
        _tema == null ? <String>[] : state.subtopicosDoTema(_tema!);

    return Scaffold(
      appBar: AppBar(title: const Text('Novo quiz')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _tema,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tema',
              border: OutlineInputBorder(),
            ),
            items: temas
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() {
              _tema = v;
              _subtopicosSelecionados.clear();
            }),
          ),
          const SizedBox(height: 16),
          if (_tema != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtópicos',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => setState(() {
                    if (_subtopicosSelecionados.length == subtopicos.length) {
                      _subtopicosSelecionados.clear();
                    } else {
                      _subtopicosSelecionados
                        ..clear()
                        ..addAll(subtopicos);
                    }
                  }),
                  child: Text(
                    _subtopicosSelecionados.length == subtopicos.length
                        ? 'Limpar'
                        : 'Selecionar todos',
                  ),
                ),
              ],
            ),
            ...subtopicos.map((s) => CheckboxListTile(
                  value: _subtopicosSelecionados.contains(s),
                  title: Text(s),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _subtopicosSelecionados.add(s);
                    } else {
                      _subtopicosSelecionados.remove(s);
                    }
                  }),
                )),
            const SizedBox(height: 16),
            Text('Quantidade de questões: $_quantidade',
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _quantidade.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: '$_quantidade',
              onChanged: (v) => setState(() => _quantidade = v.round()),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar quiz'),
              onPressed: _subtopicosSelecionados.isEmpty
                  ? null
                  : () => _iniciar(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _iniciar(BuildContext context) async {
    final state = context.read<AppState>();
    final disponiveis = state.filtrar(
      tema: _tema,
      subtopicos: _subtopicosSelecionados.toList(),
    );
    final selecao =
        SelecaoQuiz(disponiveis: disponiveis, solicitadas: _quantidade);

    if (!selecao.temAlguma) {
      _mostrarAviso(
        context,
        selecao.mensagemInsuficiencia!,
        podeIniciar: false,
      );
      return;
    }

    if (selecao.insuficiente) {
      final iniciar = await _mostrarAviso(
        context,
        '${selecao.mensagemInsuficiencia!}\n\n'
        'Deseja iniciar o quiz com as ${selecao.quantidadeEfetiva} questão(ões) '
        'disponível(is)?',
        podeIniciar: true,
      );
      if (iniciar != true) return;
    }

    // Embaralha e seleciona a quantidade efetiva.
    final embaralhador = Embaralhador();
    final preparadas = embaralhador
        .prepararQuiz(selecao.disponiveis)
        .take(selecao.quantidadeEfetiva)
        .toList();

    if (!context.mounted) return;
    context.push('/quiz', extra: {
      'tema': _tema,
      'subtopicos': _subtopicosSelecionados.toList(),
      'questoes': preparadas,
    });
  }

  Future<bool?> _mostrarAviso(
    BuildContext context,
    String mensagem, {
    required bool podeIniciar,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Questões disponíveis'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          if (podeIniciar)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Iniciar assim mesmo'),
            ),
        ],
      ),
    );
  }
}
