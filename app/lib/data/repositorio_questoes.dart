import 'package:drift/drift.dart';

import '../domain/alternativa.dart';
import '../domain/dificuldade.dart';
import '../domain/questao.dart';
import '../domain/tipo_conteudo.dart';
import 'banco.dart';
import 'tabelas.dart';

/// Representa um tema com seus subtópicos, para a interface.
class TemaComSubtopicos {
  final String id;
  final String nome;
  final List<SubtopicoInfo> subtopicos;

  const TemaComSubtopicos({
    required this.id,
    required this.nome,
    required this.subtopicos,
  });
}

class SubtopicoInfo {
  final String id;
  final String temaId;
  final String nome;

  const SubtopicoInfo({
    required this.id,
    required this.temaId,
    required this.nome,
  });
}

/// Acesso a temas, subtópicos e questões no banco local.
class RepositorioQuestoes {
  final Banco _db;

  RepositorioQuestoes(this._db);

  // ---------------------------------------------------------------------------
  // Temas e subtópicos
  // ---------------------------------------------------------------------------

  Future<List<TemaComSubtopicos>> listarTemasComSubtopicos() async {
    final temas = await _db.select(_db.temas).get();
    final subs = await _db.select(_db.subtopicos).get();
    temas.sort((a, b) => a.nome.compareTo(b.nome));
    return temas.map((t) {
      final meus = subs.where((s) => s.temaId == t.id).toList()
        ..sort((a, b) => a.nome.compareTo(b.nome));
      return TemaComSubtopicos(
        id: t.id,
        nome: t.nome,
        subtopicos: meus
            .map((s) =>
                SubtopicoInfo(id: s.id, temaId: s.temaId, nome: s.nome))
            .toList(),
      );
    }).toList();
  }

  Future<void> inserirTema(
      {required String id, required String nome, required DateTime criadoEm}) {
    return _db.into(_db.temas).insert(
          TemasCompanion.insert(id: id, nome: nome, criadoEm: criadoEm),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> inserirSubtopico({
    required String id,
    required String temaId,
    required String nome,
    required DateTime criadoEm,
  }) {
    return _db.into(_db.subtopicos).insert(
          SubtopicosCompanion.insert(
            id: id,
            temaId: temaId,
            nome: nome,
            criadoEm: criadoEm,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  // ---------------------------------------------------------------------------
  // Questões
  // ---------------------------------------------------------------------------

  Future<int> contarQuestoes() async {
    final expr = countAll();
    final q = _db.selectOnly(_db.questoes)..addColumns([expr]);
    final row = await q.getSingle();
    return row.read(expr) ?? 0;
  }

  /// Lista questões, opcionalmente filtradas por tema, subtópicos e dificuldade.
  Future<List<Questao>> listarQuestoes({
    String? tema,
    List<String>? subtopicos,
    Dificuldade? dificuldade,
  }) async {
    final query = _db.select(_db.questoes);
    if (tema != null) {
      query.where((t) => t.tema.equals(tema));
    }
    if (subtopicos != null && subtopicos.isNotEmpty) {
      query.where((t) => t.subtopico.isIn(subtopicos));
    }
    if (dificuldade != null) {
      query.where((t) => t.dificuldade.equals(dificuldade.id));
    }
    final linhasQuestoes = await query.get();
    if (linhasQuestoes.isEmpty) return [];

    final ids = linhasQuestoes.map((q) => q.id).toList();
    final linhasAlt = await (_db.select(_db.alternativas)
          ..where((a) => a.questaoId.isIn(ids)))
        .get();

    final porQuestao = <String, List<AlternativaRow>>{};
    for (final a in linhasAlt) {
      porQuestao.putIfAbsent(a.questaoId, () => []).add(a);
    }

    return linhasQuestoes
        .map((q) => _montarQuestao(q, porQuestao[q.id] ?? []))
        .toList();
  }

  Future<void> excluirQuestao(String id) async {
    await (_db.delete(_db.questoes)..where((q) => q.id.equals(id))).go();
  }

  /// Insere uma questão com suas alternativas de forma atômica (transação),
  /// usando insert-or-ignore para evitar duplicação acidental em repetições.
  Future<void> inserirQuestao(Questao questao) async {
    await _db.transaction(() async {
      await _db.into(_db.questoes).insert(
            QuestoesCompanion.insert(
              id: questao.id,
              subtopicoId: _subtopicoSlug(questao.tema, questao.subtopico),
              tema: questao.tema,
              subtopico: questao.subtopico,
              enunciado: questao.enunciado,
              dificuldade: questao.dificuldade.id,
              criadaEm: questao.criadaEm,
              tipoConteudo: Value(questao.tipoConteudo.id),
              tags: Value(questao.tags.join(',')),
              versaoPrompt: Value(questao.versaoPrompt),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      for (var i = 0; i < questao.alternativas.length; i++) {
        final a = questao.alternativas[i];
        await _db.into(_db.alternativas).insert(
              AlternativasCompanion.insert(
                id: a.id,
                questaoId: questao.id,
                texto: a.texto,
                explicacao: a.explicacao,
                correta: a.correta,
                ordem: i,
                tipoConteudo: Value(a.tipoConteudo.id),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  Questao _montarQuestao(QuestaoRow q, List<AlternativaRow> alts) {
    alts.sort((a, b) => a.ordem.compareTo(b.ordem));
    return Questao(
      id: q.id,
      tema: q.tema,
      subtopico: q.subtopico,
      enunciado: q.enunciado,
      tipoConteudo: TipoConteudo.fromIdOrDefault(q.tipoConteudo),
      dificuldade: Dificuldade.fromId(q.dificuldade),
      tags: q.tags.isEmpty ? const [] : q.tags.split(','),
      criadaEm: q.criadaEm,
      versaoPrompt: q.versaoPrompt,
      alternativas: alts
          .map((a) => Alternativa(
                id: a.id,
                texto: a.texto,
                explicacao: a.explicacao,
                correta: a.correta,
                tipoConteudo: TipoConteudo.fromIdOrDefault(a.tipoConteudo),
              ))
          .toList(),
    );
  }

  static String _subtopicoSlug(String tema, String subtopico) =>
      '${_slug(tema)}__${_slug(subtopico)}';

  static String _slug(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-|-$)'), '');
}
