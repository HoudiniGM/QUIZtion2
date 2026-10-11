import 'package:flutter_test/flutter_test.dart';
import 'package:quiztion/domain/alternativa.dart';
import 'package:quiztion/domain/dificuldade.dart';
import 'package:quiztion/domain/motor_quiz.dart';
import 'package:quiztion/domain/questao.dart';

Questao questao(String id, {String correta = 'a'}) => Questao(
      id: id,
      tema: 'Java',
      subtopico: 'Collections',
      enunciado: 'Enunciado $id',
      alternativas: [
        Alternativa(
            id: 'a', texto: 'A', explicacao: 'eA', correta: correta == 'a'),
        Alternativa(
            id: 'b', texto: 'B', explicacao: 'eB', correta: correta == 'b'),
        Alternativa(
            id: 'c', texto: 'C', explicacao: 'eC', correta: correta == 'c'),
        Alternativa(
            id: 'd', texto: 'D', explicacao: 'eD', correta: correta == 'd'),
      ],
      dificuldade: Dificuldade.basico,
      criadaEm: DateTime(2026, 1, 1),
    );

MotorQuiz motor(List<Questao> qs) => MotorQuiz(
      tema: 'Java',
      subtopicos: const ['Collections'],
      questoes: qs,
    );

void main() {
  group('MotorQuiz', () {
    test('começa na primeira questão, sem seleção nem confirmação', () {
      final m = motor([questao('q1'), questao('q2')]);
      expect(m.indiceAtual, 0);
      expect(m.total, 2);
      expect(m.ehPrimeira, isTrue);
      expect(m.ehUltima, isFalse);
      expect(m.atual.respondida, isFalse);
    });

    test('não permite responder sem seleção', () {
      final m = motor([questao('q1')]);
      expect(m.responder(), isFalse);
      expect(m.atual.respondida, isFalse);
    });

    test('confirma a resposta e marca acerto corretamente', () {
      final m = motor([questao('q1', correta: 'b')]);
      m.selecionar('b');
      expect(m.responder(), isTrue);
      expect(m.atual.respondida, isTrue);
      expect(m.atual.acertou, isTrue);
    });

    test('marca erro quando a alternativa escolhida não é a correta', () {
      final m = motor([questao('q1', correta: 'b')]);
      m.selecionar('c');
      m.responder();
      expect(m.atual.acertou, isFalse);
    });

    test('confirmação é definitiva: nova seleção é ignorada após responder',
        () {
      final m = motor([questao('q1', correta: 'a')]);
      m.selecionar('b');
      m.responder();
      m.selecionar('a'); // tentativa de mudar após confirmar
      expect(m.atual.idConfirmado, 'b');
      expect(m.atual.acertou, isFalse);
      // Responder de novo não altera nada.
      expect(m.responder(), isFalse);
    });

    test('não avança antes de responder a questão atual', () {
      final m = motor([questao('q1'), questao('q2')]);
      expect(m.proxima(), isFalse);
      expect(m.indiceAtual, 0);
    });

    test('avança após responder e identifica a última questão', () {
      final m = motor([questao('q1'), questao('q2')]);
      m.selecionar('a');
      m.responder();
      expect(m.proxima(), isTrue);
      expect(m.indiceAtual, 1);
      expect(m.ehUltima, isTrue);
      // Não há próxima depois da última.
      m.selecionar('a');
      m.responder();
      expect(m.proxima(), isFalse);
    });

    test('só pode finalizar quando todas as questões foram respondidas', () {
      final m = motor([questao('q1'), questao('q2')]);
      m.selecionar('a');
      m.responder();
      expect(m.podeFinalizar, isFalse);
      expect(
        () => m.finalizar(id: 't1', data: DateTime(2026)),
        throwsStateError,
      );
      m.proxima();
      m.selecionar('a');
      m.responder();
      expect(m.podeFinalizar, isTrue);
    });

    test('finalizar produz tentativa com respostas e desempenho corretos', () {
      final m = motor([
        questao('q1', correta: 'a'),
        questao('q2', correta: 'b'),
        questao('q3', correta: 'c'),
      ]);
      // q1: acerta
      m.selecionar('a');
      m.responder();
      m.proxima();
      // q2: erra
      m.selecionar('a');
      m.responder();
      m.proxima();
      // q3: acerta
      m.selecionar('c');
      m.responder();

      final t = m.finalizar(id: 't1', data: DateTime(2026, 5, 1));
      expect(t.total, 3);
      expect(t.acertos, 2);
      expect(t.erros, 1);
      expect(t.percentualAcerto, closeTo(66.666, 0.01));
      expect(t.respostas.length, 3);
      expect(t.respostas[0].acertou, isTrue);
      expect(t.respostas[1].acertou, isFalse);
      expect(t.respostas[2].acertou, isTrue);
      // Resposta preserva alternativa escolhida e correta.
      expect(t.respostas[1].idAlternativaEscolhida, 'a');
      expect(t.respostas[1].idAlternativaCorreta, 'b');
    });
  });
}
