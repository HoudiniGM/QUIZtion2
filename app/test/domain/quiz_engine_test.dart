import 'package:flutter_test/flutter_test.dart';
import 'package:quiztion/domain/answer_option.dart';
import 'package:quiztion/domain/difficulty.dart';
import 'package:quiztion/domain/question.dart';
import 'package:quiztion/domain/quiz_engine.dart';

Question question(String id, {String correct = 'a'}) => Question(
      id: id,
      theme: 'Java',
      subtopic: 'Collections',
      statement: 'Statement $id',
      options: [
        AnswerOption(
            id: 'a', text: 'A', explanation: 'eA', correct: correct == 'a'),
        AnswerOption(
            id: 'b', text: 'B', explanation: 'eB', correct: correct == 'b'),
        AnswerOption(
            id: 'c', text: 'C', explanation: 'eC', correct: correct == 'c'),
        AnswerOption(
            id: 'd', text: 'D', explanation: 'eD', correct: correct == 'd'),
      ],
      difficulty: Difficulty.basic,
      createdAt: DateTime(2026, 1, 1),
    );

QuizEngine engine(List<Question> qs) => QuizEngine(
      theme: 'Java',
      subtopics: const ['Collections'],
      questions: qs,
    );

void main() {
  group('QuizEngine', () {
    test('starts on the first question, without selection nor confirmation',
        () {
      final e = engine([question('q1'), question('q2')]);
      expect(e.currentIndex, 0);
      expect(e.total, 2);
      expect(e.isFirst, isTrue);
      expect(e.isLast, isFalse);
      expect(e.current.answered, isFalse);
    });

    test('does not allow answering without a selection', () {
      final e = engine([question('q1')]);
      expect(e.answer(), isFalse);
      expect(e.current.answered, isFalse);
    });

    test('confirms the answer and marks correctness properly', () {
      final e = engine([question('q1', correct: 'b')]);
      e.select('b');
      expect(e.answer(), isTrue);
      expect(e.current.answered, isTrue);
      expect(e.current.isCorrect, isTrue);
    });

    test('marks wrong when the chosen option is not the correct one', () {
      final e = engine([question('q1', correct: 'b')]);
      e.select('c');
      e.answer();
      expect(e.current.isCorrect, isFalse);
    });

    test('confirmation is final: new selection is ignored after answering',
        () {
      final e = engine([question('q1', correct: 'a')]);
      e.select('b');
      e.answer();
      e.select('a'); // attempt to change after confirming
      expect(e.current.confirmedId, 'b');
      expect(e.current.isCorrect, isFalse);
      expect(e.answer(), isFalse);
    });

    test('does not advance before answering the current question', () {
      final e = engine([question('q1'), question('q2')]);
      expect(e.next(), isFalse);
      expect(e.currentIndex, 0);
    });

    test('advances after answering and identifies the last question', () {
      final e = engine([question('q1'), question('q2')]);
      e.select('a');
      e.answer();
      expect(e.next(), isTrue);
      expect(e.currentIndex, 1);
      expect(e.isLast, isTrue);
      e.select('a');
      e.answer();
      expect(e.next(), isFalse);
    });

    test('can only finish when all questions have been answered', () {
      final e = engine([question('q1'), question('q2')]);
      e.select('a');
      e.answer();
      expect(e.canFinish, isFalse);
      expect(
        () => e.finish(id: 't1', date: DateTime(2026)),
        throwsStateError,
      );
      e.next();
      e.select('a');
      e.answer();
      expect(e.canFinish, isTrue);
    });

    test('finish produces an attempt with correct answers and performance', () {
      final e = engine([
        question('q1', correct: 'a'),
        question('q2', correct: 'b'),
        question('q3', correct: 'c'),
      ]);
      e.select('a'); // q1: correct
      e.answer();
      e.next();
      e.select('a'); // q2: wrong
      e.answer();
      e.next();
      e.select('c'); // q3: correct
      e.answer();

      final a = e.finish(id: 't1', date: DateTime(2026, 5, 1));
      expect(a.total, 3);
      expect(a.correctCount, 2);
      expect(a.wrongCount, 1);
      expect(a.accuracyPercent, closeTo(66.666, 0.01));
      expect(a.answers.length, 3);
      expect(a.answers[0].isCorrect, isTrue);
      expect(a.answers[1].isCorrect, isFalse);
      expect(a.answers[2].isCorrect, isTrue);
      expect(a.answers[1].chosenOptionId, 'a');
      expect(a.answers[1].correctOptionId, 'b');
    });
  });
}
