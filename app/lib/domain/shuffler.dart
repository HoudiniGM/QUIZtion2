import 'dart:math';

import 'answer_option.dart';
import 'question.dart';

/// Shuffles questions and answer options while preserving the association
/// between option, correct answer and explanation (see requirements,
/// sections 5 and 15).
///
/// Shuffling operates on the [AnswerOption] objects themselves, which carry
/// the identifier, text, explanation and `correct` flag together. Because the
/// moved unit is the whole option, the association is preserved by
/// construction: none of these parts is reassigned independently.
class Shuffler {
  final Random _random;

  /// Allows injecting a seeded [Random] for deterministic tests.
  Shuffler([Random? random]) : _random = random ?? Random();

  /// Returns a new list with the questions in random order.
  /// Does not modify the original list.
  List<Question> shuffleQuestions(List<Question> questions) {
    final copy = List<Question>.of(questions);
    copy.shuffle(_random);
    return copy;
  }

  /// Returns a new list of options in random order.
  /// Each option is kept intact (id, text, explanation, correct).
  List<AnswerOption> shuffleOptions(List<AnswerOption> options) {
    final copy = List<AnswerOption>.of(options);
    copy.shuffle(_random);
    return copy;
  }

  /// Returns a copy of the question with its options shuffled.
  Question shuffleQuestion(Question question) {
    return question.copyWith(options: shuffleOptions(question.options));
  }

  /// Prepares a full quiz: shuffles the order of the questions and, within
  /// each question, the order of the options.
  List<Question> prepareQuiz(List<Question> questions) {
    return shuffleQuestions(questions).map(shuffleQuestion).toList();
  }
}
