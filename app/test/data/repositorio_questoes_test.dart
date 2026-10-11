import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiztion/data/banco.dart';
import 'package:quiztion/data/repositorio_questoes.dart';
import 'package:quiztion/domain/alternativa.dart';
import 'package:quiztion/domain/dificuldade.dart';
import 'package:quiztion/domain/questao.dart';

// Testes de persistência usando SQLite em memória (sem arquivo e sem IA).
//
// Pré-requisito: `dart run build_runner build` para gerar banco.g.dart.

Questao questaoExemplo(String id, {String tema = 'Java Core'}) => Questao(
      id: id,
      tema: tema,
      subtopico: 'Collections',
      enunciado: 'Enunciado $id',
      dificuldade: Dificuldade.basico,
      criadaEm: DateTime(2026, 1, 1),
      alternativas: const [
        Alternativa(id: 'a', texto: 'A', explicacao: 'eA', correta: true),
        Alternativa(id: 'b', texto: 'B', explicacao: 'eB', correta: false),
        Alternativa(id: 'c', texto: 'C', explicacao: 'eC', correta: false),
        Alternativa(id: 'd', texto: 'D', explicacao: 'eD', correta: false),
      ],
    );

void main() {
  late Banco db;
  late RepositorioQuestoes repo;

  setUp(() {
    db = Banco(NativeDatabase.memory());
    repo = RepositorioQuestoes(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RepositorioQuestoes', () {
    test('cria e lê temas e subtópicos', () async {
      await repo.inserirTema(
          id: 'java-core', nome: 'Java Core', criadoEm: DateTime(2026));
      await repo.inserirSubtopico(
        id: 'java-core__collections',
        temaId: 'java-core',
        nome: 'Collections',
        criadoEm: DateTime(2026),
      );

      final temas = await repo.listarTemasComSubtopicos();
      expect(temas.length, 1);
      expect(temas.first.nome, 'Java Core');
      expect(temas.first.subtopicos.single.nome, 'Collections');
    });

    test('salva uma questão válida e a recupera com as alternativas', () async {
      await repo.inserirQuestao(questaoExemplo('q1'));

      final questoes = await repo.listarQuestoes();
      expect(questoes.length, 1);
      final q = questoes.first;
      expect(q.id, 'q1');
      expect(q.alternativas.length, 4);
      expect(q.alternativas.where((a) => a.correta).length, 1);
      expect(q.alternativaCorreta.id, 'a');
      // Associação alternativa↔explicação preservada.
      expect(q.alternativaCorreta.explicacao, 'eA');
    });

    test('inserir a mesma questão duas vezes não duplica (idempotente)',
        () async {
      await repo.inserirQuestao(questaoExemplo('q1'));
      await repo.inserirQuestao(questaoExemplo('q1'));
      expect(await repo.contarQuestoes(), 1);
      final q = (await repo.listarQuestoes()).single;
      expect(q.alternativas.length, 4);
    });

    test('filtra questões por tema e dificuldade', () async {
      await repo.inserirQuestao(questaoExemplo('q1', tema: 'Java Core'));
      await repo.inserirQuestao(questaoExemplo('q2', tema: 'Bancos de Dados'));

      final soJava = await repo.listarQuestoes(tema: 'Java Core');
      expect(soJava.map((q) => q.id), ['q1']);

      final basicas =
          await repo.listarQuestoes(dificuldade: Dificuldade.basico);
      expect(basicas.length, 2);

      final avancadas =
          await repo.listarQuestoes(dificuldade: Dificuldade.avancado);
      expect(avancadas, isEmpty);
    });

    test('excluir questão remove também suas alternativas (cascade)',
        () async {
      await repo.inserirQuestao(questaoExemplo('q1'));
      await repo.excluirQuestao('q1');
      expect(await repo.contarQuestoes(), 0);

      // Nenhuma alternativa órfã deve restar.
      final alts = await db.select(db.alternativas).get();
      expect(alts, isEmpty);
    });
  });
}
