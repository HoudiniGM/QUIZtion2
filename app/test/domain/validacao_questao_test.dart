import 'package:flutter_test/flutter_test.dart';
import 'package:quiztion/domain/alternativa.dart';
import 'package:quiztion/domain/dificuldade.dart';
import 'package:quiztion/domain/questao.dart';
import 'package:quiztion/domain/validacao_questao.dart';

Alternativa alt(String id, {bool correta = false, String? texto}) => Alternativa(
      id: id,
      texto: texto ?? 'Texto $id',
      explicacao: 'Explicação $id',
      correta: correta,
    );

Questao questaoValida() => Questao(
      id: 'q1',
      tema: 'Java',
      subtopico: 'Collections',
      enunciado: 'Qual implementação de List mantém a ordem de inserção?',
      alternativas: [
        alt('a', correta: true),
        alt('b'),
        alt('c'),
        alt('d'),
      ],
      dificuldade: Dificuldade.basico,
      criadaEm: DateTime(2026, 1, 1),
    );

void main() {
  group('ValidacaoQuestao', () {
    test('aceita uma questão bem formada', () {
      final r = ValidacaoQuestao.validar(questaoValida());
      expect(r.valida, isTrue);
      expect(r.erros, isEmpty);
    });

    test('rejeita questão com número incorreto de alternativas', () {
      final q = questaoValida().copyWith(
        alternativas: [alt('a', correta: true), alt('b'), alt('c')],
      );
      final r = ValidacaoQuestao.validar(q);
      expect(r.valida, isFalse);
      expect(r.erros.any((e) => e.contains('4 alternativas')), isTrue);
    });

    test('rejeita questão sem exatamente uma resposta correta (zero)', () {
      final q = questaoValida().copyWith(
        alternativas: [alt('a'), alt('b'), alt('c'), alt('d')],
      );
      final r = ValidacaoQuestao.validar(q);
      expect(r.valida, isFalse);
      expect(r.erros.any((e) => e.contains('1 alternativa correta')), isTrue);
    });

    test('rejeita questão com mais de uma resposta correta', () {
      final q = questaoValida().copyWith(
        alternativas: [
          alt('a', correta: true),
          alt('b', correta: true),
          alt('c'),
          alt('d'),
        ],
      );
      final r = ValidacaoQuestao.validar(q);
      expect(r.valida, isFalse);
      expect(r.erros.any((e) => e.contains('1 alternativa correta')), isTrue);
    });

    test('rejeita questão sem explicação em alguma alternativa', () {
      final q = questaoValida().copyWith(
        alternativas: [
          const Alternativa(
              id: 'a', texto: 'A', explicacao: '', correta: true),
          alt('b'),
          alt('c'),
          alt('d'),
        ],
      );
      final r = ValidacaoQuestao.validar(q);
      expect(r.valida, isFalse);
      expect(r.erros.any((e) => e.contains('explicação')), isTrue);
    });

    test('rejeita enunciado vazio', () {
      final q = questaoValida().copyWith(enunciado: '   ');
      expect(ValidacaoQuestao.ehValida(q), isFalse);
    });

    test('rejeita tema ou subtópico ausente', () {
      expect(ValidacaoQuestao.ehValida(questaoValida().copyWith(tema: '')),
          isFalse);
      expect(
          ValidacaoQuestao.ehValida(questaoValida().copyWith(subtopico: ' ')),
          isFalse);
    });

    test('rejeita alternativas praticamente idênticas', () {
      final q = questaoValida().copyWith(
        alternativas: [
          alt('a', correta: true, texto: 'ArrayList'),
          alt('b', texto: '  arraylist '),
          alt('c'),
          alt('d'),
        ],
      );
      final r = ValidacaoQuestao.validar(q);
      expect(r.valida, isFalse);
      expect(r.erros.any((e) => e.contains('duplicadas')), isTrue);
    });

    test('rejeita identificadores de alternativa duplicados', () {
      final q = questaoValida().copyWith(
        alternativas: [
          alt('a', correta: true),
          alt('a', texto: 'outro'),
          alt('c'),
          alt('d'),
        ],
      );
      final r = ValidacaoQuestao.validar(q);
      expect(r.valida, isFalse);
      expect(r.erros.any((e) => e.contains('identificadores')), isTrue);
    });
  });
}
