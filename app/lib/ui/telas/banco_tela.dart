import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/dificuldade.dart';
import '../../domain/questao.dart';
import '../../state/app_state.dart';
import '../widgets/conteudo_view.dart';

/// Banco de questões: listar, filtrar e consultar/excluir questões salvas
/// (requisitos, seção 4.3).
class BancoTela extends StatefulWidget {
  const BancoTela({super.key});

  @override
  State<BancoTela> createState() => _BancoTelaState();
}

class _BancoTelaState extends State<BancoTela> {
  String? _tema;
  String? _subtopico;
  Dificuldade? _dificuldade;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final temas = state.temas.map((t) => t.nome).toList();
    final subtopicos =
        _tema == null ? <String>[] : state.subtopicosDoTema(_tema!);

    final questoes = state.filtrar(
      tema: _tema,
      subtopicos: _subtopico == null ? null : [_subtopico!],
      dificuldade: _dificuldade,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Banco de questões')),
      body: Column(
        children: [
          _Filtros(
            temas: temas,
            subtopicos: subtopicos,
            tema: _tema,
            subtopico: _subtopico,
            dificuldade: _dificuldade,
            onTema: (v) => setState(() {
              _tema = v;
              _subtopico = null;
            }),
            onSubtopico: (v) => setState(() => _subtopico = v),
            onDificuldade: (v) => setState(() => _dificuldade = v),
            onLimpar: () => setState(() {
              _tema = null;
              _subtopico = null;
              _dificuldade = null;
            }),
          ),
          const Divider(height: 1),
          Expanded(
            child: questoes.isEmpty
                ? const _VazioBanco()
                : ListView.builder(
                    itemCount: questoes.length,
                    itemBuilder: (_, i) => _QuestaoTile(questao: questoes[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _VazioBanco extends StatelessWidget {
  const _VazioBanco();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Nenhuma questão encontrada para os filtros selecionados.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  final List<String> temas;
  final List<String> subtopicos;
  final String? tema;
  final String? subtopico;
  final Dificuldade? dificuldade;
  final ValueChanged<String?> onTema;
  final ValueChanged<String?> onSubtopico;
  final ValueChanged<Dificuldade?> onDificuldade;
  final VoidCallback onLimpar;

  const _Filtros({
    required this.temas,
    required this.subtopicos,
    required this.tema,
    required this.subtopico,
    required this.dificuldade,
    required this.onTema,
    required this.onSubtopico,
    required this.onDificuldade,
    required this.onLimpar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: tema,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Tema',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...temas.map((t) => DropdownMenuItem(value: t, child: Text(t))),
            ],
            onChanged: onTema,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: subtopico,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Subtópico',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...subtopicos
                  .map((s) => DropdownMenuItem(value: s, child: Text(s))),
            ],
            onChanged: tema == null ? null : onSubtopico,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Dificuldade>(
                  initialValue: dificuldade,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Dificuldade',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ...Dificuldade.values.map((d) =>
                        DropdownMenuItem(value: d, child: Text(d.rotulo))),
                  ],
                  onChanged: onDificuldade,
                ),
              ),
              IconButton(
                tooltip: 'Limpar filtros',
                onPressed: onLimpar,
                icon: const Icon(Icons.filter_alt_off),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestaoTile extends StatelessWidget {
  final Questao questao;

  const _QuestaoTile({required this.questao});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(
          questao.enunciado,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${questao.tema} • ${questao.subtopico} • '
          '${questao.dificuldade.rotulo}',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: ConteudoView(
              texto: questao.enunciado,
              tipo: questao.tipoConteudo,
            ),
          ),
          const SizedBox(height: 12),
          ...questao.alternativas.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      a.correta
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: a.correta ? Colors.green : null,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ConteudoView(
                              texto: a.texto, tipo: a.tipoConteudo),
                          const SizedBox(height: 2),
                          Text(
                            a.explicacao,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir'),
              onPressed: () => _confirmarExclusao(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir questão'),
        content: const Text(
          'Tem certeza que deseja excluir esta questão? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true && context.mounted) {
      await context.read<AppState>().excluirQuestao(questao.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Questão excluída.')),
        );
      }
    }
  }
}
