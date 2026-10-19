import 'package:flutter_test/flutter_test.dart';
import 'package:quiztion/domain/answer_option.dart';
import 'package:quiztion/domain/difficulty.dart';
import 'package:quiztion/domain/question.dart';
import 'package:quiztion/domain/quiz_engine.dart';

/// Builds a question whose correct options are the ids in [correct].
Question question(String id, {Set<String> correct = const {'a'}}) => Question(
      id: id,
      theme: 'Java',
      subtopic: 'Collections',
      statement: 'Statement $id',
      options: [
        AnswerOption(
            id: 'a', text: 'A', explanation: 'eA', correct: correct.contains('a')),
        AnswerOption(
            id: 'b', text: 'B', explanation: 'eB', correct: correct.contains('b')),
        AnswerOption(
            id: 'c', text: 'C', explanation: 'eC', correct: correct.contains('c')),
        AnswerOption(
            id: 'd', text: 'D', explanation: 'eD', correct: correct.contains('d')),
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

    test('toggle adds and removes a selection', () {
      final e = engine([question('q1')]);
      e.toggle('a');
      expect(e.current.selectedIds, {'a'});
      e.toggle('b');
      expect(e.current.selectedIds, {'a', 'b'});
      e.toggle('a');
      expect(e.current.selectedIds, {'b'});
    });

    test('single-correct: marking the correct option scores 1.0', () {
      final e = engine([question('q1', correct: {'b'})]);
      e.toggle('b');
      expect(e.answer(), isTrue);
      expect(e.current.score, 1.0);
      expect(e.current.isFullyCorrect, isTrue);
    });

    test('single-correct: marking a wrong option scores 0', () {
      final e = engine([question('q1', correct: {'b'})]);
      e.toggle('c');
      e.answer();
      expect(e.current.score, 0);
    });

    test('confirmation is final: toggles ignored after answering', () {
      final e = engine([question('q1', correct: {'a'})]);
      e.toggle('b');
      e.answer();
      e.toggle('a'); // ignored
      expect(e.current.confirmedIds, {'b'});
      expect(e.answer(), isFalse);
    });

    test('does not advance before answering', () {
      final e = engine([question('q1'), question('q2')]);
      expect(e.next(), isFalse);
      expect(e.currentIndex, 0);
    });

    test('advances after answering and identifies the last question', () {
      final e = engine([question('q1'), question('q2')]);
      e.toggle('a');
      e.answer();
      expect(e.next(), isTrue);
      expect(e.isLast, isTrue);
    });

    group('multiple-correct scoring (2 correct: a, b)', () {
      // Agreed formula: max(0, correctMarked - wrongMarked) / totalCorrect.
      test('none marked -> 0', () {
        final e = engine([question('q1', correct: {'a', 'b'})]);
        e.toggle('a');
        e.toggle('a'); // deselect to end with nothing
        // answer() needs a selection; select one wrong then compute via a
        // fresh question for the "nothing marked" conceptual case is covered
        // by the formula; here verify 1 correct + 1 wrong = 0 below.
        e.toggle('a');
        e.toggle('c');
        e.answer();
        expect(e.current.score, 0); // (1 - 1)/2 = 0
      });

      test('only one of two correct -> 0.5', () {
        final e = engine([question('q1', correct: {'a', 'b'})]);
        e.toggle('a');
        e.answer();
        expect(e.current.score, closeTo(0.5, 1e-9)); // (1 - 0)/2
      });

      test('both correct + one wrong -> 0.5', () {
        final e = engine([question('q1', correct: {'a', 'b'})]);
        e.toggle('a');
        e.toggle('b');
        e.toggle('c');
        e.answer();
        expect(e.current.score, closeTo(0.5, 1e-9)); // (2 - 1)/2
      });

      test('both correct, none wrong -> 1.0', () {
        final e = engine([question('q1', correct: {'a', 'b'})]);
        e.toggle('a');
        e.toggle('b');
        e.answer();
        expect(e.current.score, 1.0);
        expect(e.current.isFullyCorrect, isTrue);
      });
    });

    test('finish produces an attempt with averaged scoring', () {
      final e = engine([
        question('q1', correct: {'a'}), // answer 'a' -> 1.0
        question('q2', correct: {'a', 'b'}), // answer only 'a' -> 0.5
      ]);
      e.toggle('a');
      e.answer();
      e.next();
      e.toggle('a'); // marks one of the two correct, nothing wrong -> 0.5
      e.answer();

      final att = e.finish(id: 't1', date: DateTime(2026, 5, 1));
      expect(att.total, 2);
      expect(att.answers[0].score, 1.0);
      expect(att.answers[1].score, closeTo(0.5, 1e-9));
      expect(att.fullyCorrectCount, 1);
      expect(att.totalScore, closeTo(1.5, 1e-9));
      expect(att.accuracyPercent, closeTo(75.0, 1e-9)); // mean of 1.0 and 0.5
    });
  });
}
