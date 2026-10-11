import 'package:flutter_test/flutter_test.dart';
import 'package:quiztion/domain/alternativa.dart';
import 'package:quiztion/domain/dificuldade.dart';
import 'package:quiztion/domain/questao.dart';
import 'package:quiztion/domain/selecao_quiz.dart';

Questao questao(String id) => Questao(
      id: id,
      tema: 'Java',
      subtopico: 'Collections',
      enunciado: 'Enunciado $id',
      alternativas: [
        const Alternativa(id: 'a', texto: 'A', explicacao: 'eA', correta: true),
        const Alternativa(id: 'b', texto: 'B', explicacao: 'eB', correta: false),
        const Alternativa(id: 'c', texto: 'C', explicacao: 'eC', correta: false),
        const Alternativa(id: 'd', texto: 'D', explicacao: 'eD', correta: false),
      ],
      dificuldade: Dificuldade.basico,
      criadaEm: DateTime(2026, 1, 1),
    );

void main() {
  group('SelecaoQuiz', () {
    test('quantidade suficiente não é marcada como insuficiente', () {
      final s = SelecaoQuiz(
        disponiveis: [questao('q1'), questao('q2'), questao('q3')],
        solicitadas: 2,
      );
      expect(s.insuficiente, isFalse);
      expect(s.quantidadeEfetiva, 2);
      expect(s.mensagemInsuficiencia, isNull);
    });

    test('quantidade insuficiente é detectada e informada', () {
      final s = SelecaoQuiz(
        disponiveis: [questao('q1'), questao('q2')],
        solicitadas: 5,
      );
      expect(s.insuficiente, isTrue);
      expect(s.quantidadeDisponivel, 2);
      expect(s.quantidadeEfetiva, 2);
      expect(s.mensagemInsuficiencia, contains('apenas 2'));
    });

    test('nenhuma questão disponível gera mensagem apropriada', () {
      final s = SelecaoQuiz(disponiveis: const [], solicitadas: 3);
      expect(s.temAlguma, isFalse);
      expect(s.insuficiente, isTrue);
      expect(s.mensagemInsuficiencia, contains('Não há questões'));
    });
  });
}
