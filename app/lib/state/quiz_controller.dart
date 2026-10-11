import 'package:flutter/foundation.dart';

import '../domain/attempt.dart';
import '../domain/question.dart';
import '../domain/quiz_engine.dart';

/// Drives a quiz session for the UI, wrapping the [QuizEngine] and notifying
/// state changes.
class QuizController extends ChangeNotifier {
  final QuizEngine _engine;

  QuizController({
    required String theme,
    required List<String> subtopics,
    required List<Question> shuffledQuestions,
  }) : _engine = QuizEngine(
          theme: theme,
          subtopics: subtopics,
          questions: shuffledQuestions,
        );

  int get currentIndex => _engine.currentIndex;
  int get total => _engine.total;
  QuestionState get current => _engine.current;
  bool get isLast => _engine.isLast;
  bool get canFinish => _engine.canFinish;

  bool get hasSelection => current.selectedId != null;
  bool get answered => current.answered;

  void select(String optionId) {
    _engine.select(optionId);
    notifyListeners();
  }

  bool answer() {
    final ok = _engine.answer();
    if (ok) notifyListeners();
    return ok;
  }

  bool next() {
    final ok = _engine.next();
    if (ok) notifyListeners();
    return ok;
  }

  Attempt finish() {
    return _engine.finish(
      id: 'attempt-${DateTime.now().microsecondsSinceEpoch}',
      date: DateTime.now(),
    );
  }
}
