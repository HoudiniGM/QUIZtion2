import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiztion/domain/alternativa.dart';
import 'package:quiztion/domain/dificuldade.dart';
import 'package:quiztion/domain/embaralhador.dart';
import 'package:quiztion/domain/questao.dart';

Alternativa alt(String id, {bool correta = false}) => Alternativa(
      id: id,
      texto: 'Texto $id',
      explicacao: 'Explicação $id',
      correta: correta,
    );

Questao questao(String id) => Questao(
      id: id,
      tema: 'Java',
      subtopico: 'Collections',
      enunciado: 'Enunciado $id',
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
  group('Embaralhador', () {
    test('embaralhar alternativas preserva o conjunto e as associações', () {
      final embaralhador = Embaralhador(Random(42));
      final original = questao('q1').alternativas;
      final embaralhada = embaralhador.embaralharAlternativas(original);

      // Mesma quantidade e mesmo conjunto de elementos (nada perdido/criado).
      expect(embaralhada.length, original.length);
      expect(embaralhada.toSet(), original.toSet());

      // A associação id↔texto↔explicação↔correta é preservada por elemento.
      for (final a in original) {
        final correspondente =
            embaralhada.firstWhere((x) => x.id == a.id);
        expect(correspondente.texto, a.texto);
        expect(correspondente.explicacao, a.explicacao);
        expect(correspondente.correta, a.correta);
      }

      // Continua havendo exatamente uma correta.
      expect(embaralhada.where((a) => a.correta).length, 1);
    });

    test('não modifica a lista original de alternativas', () {
      final embaralhador = Embaralhador(Random(1));
      final original = questao('q1').alternativas;
      final idsAntes = original.map((a) => a.id).toList();
      embaralhador.embaralharAlternativas(original);
      expect(original.map((a) => a.id).toList(), idsAntes);
    });

    test('prepararQuiz mantém todas as questões e suas corretas', () {
      final embaralhador = Embaralhador(Random(7));
      final questoes = [questao('q1'), questao('q2'), questao('q3')];
      final preparadas = embaralhador.prepararQuiz(questoes);

      expect(preparadas.length, 3);
      expect(
        preparadas.map((q) => q.id).toSet(),
        {'q1', 'q2', 'q3'},
      );
      for (final q in preparadas) {
        expect(q.alternativas.length, 4);
        expect(q.alternativas.where((a) => a.correta).length, 1);
        // A alternativa correta continua acessível e coerente.
        expect(q.alternativaCorreta.correta, isTrue);
      }
    });

    test('com semente fixa, o embaralhamento é determinístico', () {
      final a = Embaralhador(Random(123))
          .embaralharAlternativas(questao('q1').alternativas)
          .map((x) => x.id)
          .toList();
      final b = Embaralhador(Random(123))
          .embaralharAlternativas(questao('q1').alternativas)
          .map((x) => x.id)
          .toList();
      expect(a, b);
    });
  });
}
