import 'question.dart';

/// Record of a single answer given during a quiz.
///
/// Stores the answered question (with its options in the order they were
/// shown) and the ids of the options the user marked. A question may have one
/// or more correct options (multiple-answer), so the chosen set may contain
/// more than one id. Preserves the information needed to rebuild the result
/// later, regardless of any shuffling (see requirements, section 15).
class QuizAnswer {
  final Question question;

  /// Ids of the options marked by the user (one or more).
  final Set<String> chosenOptionIds;

  const QuizAnswer({
    required this.question,
    required this.chosenOptionIds,
  });

  /// Ids of the correct options of the question (one or more).
  Set<String> get correctOptionIds => question.correctOptionIds;

  /// Score for this question, from 0.0 to 1.0, using the agreed formula:
  ///
  ///   score = max(0, correctMarked - wrongMarked) / totalCorrect
  ///
  /// - Marking a wrong option subtracts (one cancels one correct).
  /// - Failing to mark a correct option simply does not add (no extra penalty).
  double get score {
    final correct = correctOptionIds;
    if (correct.isEmpty) return 0;
    final correctMarked =
        chosenOptionIds.where((id) => correct.contains(id)).length;
    final wrongMarked =
        chosenOptionIds.where((id) => !correct.contains(id)).length;
    final raw = (correctMarked - wrongMarked) / correct.length;
    return raw < 0 ? 0 : raw;
  }

  /// Convenience: whether the question was answered perfectly (score == 1.0).
  bool get isFullyCorrect => score >= 1.0;
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

  /// Number of questions answered perfectly (score == 1.0).
  int get fullyCorrectCount => answers.where((a) => a.isFullyCorrect).length;

  /// Questions not answered perfectly.
  int get notFullyCorrectCount => total - fullyCorrectCount;

  /// Sum of per-question scores (each 0.0–1.0).
  double get totalScore =>
      answers.fold(0.0, (sum, a) => sum + a.score);

  /// Overall accuracy percentage (0–100): the mean of per-question scores.
  /// With single-correct questions this reduces to the usual correct ratio.
  double get accuracyPercent {
    if (total == 0) return 0;
    return (totalScore / total) * 100;
  }
}
