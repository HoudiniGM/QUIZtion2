import 'question.dart';

/// Record of a single answer given during a quiz.
///
/// Stores the answered question (with its options in the order they were
/// shown), the id of the option chosen by the user and the id of the correct
/// one. Preserves the information needed to rebuild the result later,
/// regardless of any shuffling (see requirements, section 15).
class QuizAnswer {
  final Question question;

  /// Id of the option chosen by the user.
  final String chosenOptionId;

  const QuizAnswer({
    required this.question,
    required this.chosenOptionId,
  });

  /// Id of the correct option of the question.
  String get correctOptionId => question.correctOption.id;

  /// Whether the user's answer is correct.
  bool get isCorrect => chosenOptionId == correctOptionId;
}

/// The result of a completed quiz: the set of answers plus quiz metadata.
///
/// This is an in-memory value produced by [QuizEngine.finish] and consumed by
/// the results screen. It is NOT persisted — the app does not keep a history
/// of attempts (out of scope).
class Attempt {
  final String id;
  final DateTime date;
  final String theme;
  final List<String> subtopics;
  final List<QuizAnswer> answers;

  const Attempt({
    required this.id,
    required this.date,
    required this.theme,
    required this.subtopics,
    required this.answers,
  });

  int get total => answers.length;

  int get correctCount => answers.where((a) => a.isCorrect).length;

  int get wrongCount => total - correctCount;

  /// Accuracy percentage (0–100). Returns 0 when there are no answers.
  double get accuracyPercent {
    if (total == 0) return 0;
    return (correctCount / total) * 100;
  }
}
