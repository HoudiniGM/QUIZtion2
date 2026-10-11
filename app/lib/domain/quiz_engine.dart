import 'attempt.dart';
import 'question.dart';

/// State of a single question within a quiz session.
class QuestionState {
  final Question question;

  /// Id of the selected option (not yet confirmed), or null.
  final String? selectedId;

  /// Id of the confirmed (final) option, or null if not answered yet.
  final String? confirmedId;

  const QuestionState({
    required this.question,
    this.selectedId,
    this.confirmedId,
  });

  bool get answered => confirmedId != null;

  bool get isCorrect => answered && confirmedId == question.correctOption.id;

  QuestionState copyWith({
    String? selectedId,
    String? confirmedId,
    bool clearSelection = false,
  }) {
    return QuestionState(
      question: question,
      selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
      confirmedId: confirmedId ?? this.confirmedId,
    );
  }
}

/// Engine of a quiz session.
///
/// Rules (see requirements, section 14):
/// - one question at a time;
/// - select an option before "Responder";
/// - confirmation ("Responder") is final and cannot be changed;
/// - advance to the next question; "Finalizar" on the last one.
///
/// The provided questions must already be shuffled (questions and options).
class QuizEngine {
  final String theme;
  final List<String> subtopics;
  final List<QuestionState> _states;
  int _currentIndex = 0;

  QuizEngine({
    required this.theme,
    required this.subtopics,
    required List<Question> questions,
  })  : assert(questions.isNotEmpty, 'The quiz needs at least one question.'),
        _states =
            questions.map((q) => QuestionState(question: q)).toList();

  int get currentIndex => _currentIndex;
  int get total => _states.length;
  QuestionState get current => _states[_currentIndex];
  bool get isLast => _currentIndex == total - 1;
  bool get isFirst => _currentIndex == 0;

  /// Selects (without confirming) an option on the current question.
  /// Ignored if the question is already answered (confirmation is final).
  void select(String optionId) {
    if (current.answered) return;
    _states[_currentIndex] = current.copyWith(selectedId: optionId);
  }

  /// Confirms ("Responder") the selected option on the current question.
  ///
  /// Returns `true` if confirmation happened. Returns `false` if there was no
  /// selection or if the question was already answered. Confirmation is final.
  bool answer() {
    if (current.answered) return false;
    final sel = current.selectedId;
    if (sel == null) return false;
    _states[_currentIndex] = current.copyWith(confirmedId: sel);
    return true;
  }

  /// Advances to the next question. Only allowed after answering the current.
  /// Returns `true` if it advanced.
  bool next() {
    if (!current.answered) return false;
    if (isLast) return false;
    _currentIndex++;
    return true;
  }

  /// Whether the quiz can be finished (all questions answered).
  bool get canFinish => _states.every((s) => s.answered);

  /// Builds the [Attempt] with the quiz result.
  ///
  /// Throws [StateError] if not all questions were answered.
  Attempt finish({
    required String id,
    required DateTime date,
  }) {
    if (!canFinish) {
      throw StateError('Cannot finish: there are unanswered questions.');
    }
    final answers = _states
        .map((s) => QuizAnswer(
              question: s.question,
              chosenOptionId: s.confirmedId!,
            ))
        .toList();
    return Attempt(
      id: id,
      date: date,
      theme: theme,
      subtopics: subtopics,
      answers: answers,
    );
  }
}
