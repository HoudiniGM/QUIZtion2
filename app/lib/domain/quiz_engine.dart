import 'attempt.dart';
import 'question.dart';

/// State of a single question within a quiz session.
///
/// Supports one or more selected options (multiple-answer questions): the user
/// toggles options on/off before confirming.
class QuestionState {
  final Question question;

  /// Ids of the selected options (not yet confirmed).
  final Set<String> selectedIds;

  /// Ids of the confirmed (final) options, or null if not answered yet.
  final Set<String>? confirmedIds;

  QuestionState({
    required this.question,
    Set<String>? selectedIds,
    this.confirmedIds,
  }) : selectedIds = selectedIds ?? <String>{};

  bool get answered => confirmedIds != null;

  bool get hasSelection => selectedIds.isNotEmpty;

  /// Score (0.0–1.0) for this question once answered; 0 before answering.
  double get score {
    if (!answered) return 0;
    return QuizAnswer(question: question, chosenOptionIds: confirmedIds!).score;
  }

  /// Whether answered perfectly.
  bool get isFullyCorrect => answered && score >= 1.0;

  QuestionState copyWith({
    Set<String>? selectedIds,
    Set<String>? confirmedIds,
  }) {
    return QuestionState(
      question: question,
      selectedIds: selectedIds ?? this.selectedIds,
      confirmedIds: confirmedIds ?? this.confirmedIds,
    );
  }
}

/// Engine of a quiz session.
///
/// Rules (see requirements, section 14):
/// - one question at a time;
/// - select one OR MORE options before "Responder";
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

  /// Toggles an option on the current question (adds if absent, removes if
  /// present). Ignored if the question is already answered.
  void toggle(String optionId) {
    if (current.answered) return;
    final next = Set<String>.of(current.selectedIds);
    if (next.contains(optionId)) {
      next.remove(optionId);
    } else {
      next.add(optionId);
    }
    _states[_currentIndex] = current.copyWith(selectedIds: next);
  }

  /// Confirms ("Responder") the selected options on the current question.
  ///
  /// Returns `true` if confirmation happened. Returns `false` if nothing was
  /// selected or if the question was already answered. Confirmation is final.
  bool answer() {
    if (current.answered) return false;
    if (current.selectedIds.isEmpty) return false;
    _states[_currentIndex] =
        current.copyWith(confirmedIds: Set<String>.of(current.selectedIds));
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
              chosenOptionIds: s.confirmedIds!,
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
