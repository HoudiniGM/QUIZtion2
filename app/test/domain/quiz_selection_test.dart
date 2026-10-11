import 'package:flutter_test/flutter_test.dart';
import 'package:quiztion/domain/answer_option.dart';
import 'package:quiztion/domain/difficulty.dart';
import 'package:quiztion/domain/question.dart';
import 'package:quiztion/domain/quiz_selection.dart';

Question question(String id) => Question(
      id: id,
      theme: 'Java',
      subtopic: 'Collections',
      statement: 'Statement $id',
      options: const [
        AnswerOption(id: 'a', text: 'A', explanation: 'eA', correct: true),
        AnswerOption(id: 'b', text: 'B', explanation: 'eB', correct: false),
        AnswerOption(id: 'c', text: 'C', explanation: 'eC', correct: false),
        AnswerOption(id: 'd', text: 'D', explanation: 'eD', correct: false),
      ],
      difficulty: Difficulty.basic,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('QuizSelection', () {
    test('sufficient quantity is not flagged as insufficient', () {
      final s = QuizSelection(
        available: [question('q1'), question('q2'), question('q3')],
        requested: 2,
      );
      expect(s.insufficient, isFalse);
      expect(s.effectiveCount, 2);
      expect(s.insufficiencyMessage, isNull);
    });

    test('insufficient quantity is detected and reported', () {
      final s = QuizSelection(
        available: [question('q1'), question('q2')],
        requested: 5,
      );
      expect(s.insufficient, isTrue);
      expect(s.availableCount, 2);
      expect(s.effectiveCount, 2);
      expect(s.insufficiencyMessage, contains('apenas 2'));
    });

    test('no available questions yields an appropriate message', () {
      const s = QuizSelection(available: [], requested: 3);
      expect(s.hasAny, isFalse);
      expect(s.insufficient, isTrue);
      expect(s.insufficiencyMessage, contains('Não há questões'));
    });
  });
}
