import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiztion/domain/answer_option.dart';
import 'package:quiztion/domain/difficulty.dart';
import 'package:quiztion/domain/question.dart';
import 'package:quiztion/domain/shuffler.dart';

AnswerOption opt(String id, {bool correct = false}) => AnswerOption(
      id: id,
      text: 'Text $id',
      explanation: 'Explanation $id',
      correct: correct,
    );

Question question(String id) => Question(
      id: id,
      theme: 'Java',
      subtopic: 'Collections',
      statement: 'Statement $id',
      options: [
        opt('a', correct: true),
        opt('b'),
        opt('c'),
        opt('d'),
      ],
      difficulty: Difficulty.basic,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('Shuffler', () {
    test('shuffling options preserves the set and the associations', () {
      final shuffler = Shuffler(Random(42));
      final original = question('q1').options;
      final shuffled = shuffler.shuffleOptions(original);

      // Same count and same element set (nothing lost/created).
      expect(shuffled.length, original.length);
      expect(shuffled.toSet(), original.toSet());

      // The id<->text<->explanation<->correct association is preserved.
      for (final o in original) {
        final match = shuffled.firstWhere((x) => x.id == o.id);
        expect(match.text, o.text);
        expect(match.explanation, o.explanation);
        expect(match.correct, o.correct);
      }

      // There is still exactly one correct option.
      expect(shuffled.where((o) => o.correct).length, 1);
    });

    test('does not modify the original options list', () {
      final shuffler = Shuffler(Random(1));
      final original = question('q1').options;
      final idsBefore = original.map((o) => o.id).toList();
      shuffler.shuffleOptions(original);
      expect(original.map((o) => o.id).toList(), idsBefore);
    });

    test('prepareQuiz keeps all questions and their correct options', () {
      final shuffler = Shuffler(Random(7));
      final questions = [question('q1'), question('q2'), question('q3')];
      final prepared = shuffler.prepareQuiz(questions);

      expect(prepared.length, 3);
      expect(prepared.map((q) => q.id).toSet(), {'q1', 'q2', 'q3'});
      for (final q in prepared) {
        expect(q.options.length, 4);
        expect(q.options.where((o) => o.correct).length, 1);
        expect(q.correctOptions.single.correct, isTrue);
      }
    });

    test('with a fixed seed, shuffling is deterministic', () {
      final a = Shuffler(Random(123))
          .shuffleOptions(question('q1').options)
          .map((x) => x.id)
          .toList();
      final b = Shuffler(Random(123))
          .shuffleOptions(question('q1').options)
          .map((x) => x.id)
          .toList();
      expect(a, b);
    });
  });
}
