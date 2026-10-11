import 'package:flutter/foundation.dart';

import '../data/question_repository.dart';
import '../data/sample_data.dart';
import '../domain/difficulty.dart';
import '../domain/question.dart';

/// Global application state (Stage 1): themes/subtopics and question bank.
///
/// Keeps the data loaded from SQLite and exposes operations used by screens.
class AppState extends ChangeNotifier {
  final QuestionRepository _repo;
  final DataSeeder _seeder;

  AppState(this._repo) : _seeder = DataSeeder(_repo);

  bool _loading = true;
  bool get loading => _loading;

  List<ThemeWithSubtopics> _themes = [];
  List<ThemeWithSubtopics> get themes => _themes;

  List<Question> _questions = [];
  List<Question> get questions => _questions;

  int get totalQuestions => _questions.length;

  /// Initializes: runs the seed (if needed) and loads the data.
  Future<void> initialize() async {
    _loading = true;
    notifyListeners();
    await _seeder.seedIfNeeded();
    await reload();
  }

  Future<void> reload() async {
    _themes = await _repo.listThemesWithSubtopics();
    _questions = await _repo.listQuestions();
    _loading = false;
    notifyListeners();
  }

  /// Filtered questions (used by the question bank screen).
  List<Question> filter({
    String? theme,
    List<String>? subtopics,
    Difficulty? difficulty,
  }) {
    return _questions.where((q) {
      if (theme != null && q.theme != theme) return false;
      if (subtopics != null &&
          subtopics.isNotEmpty &&
          !subtopics.contains(q.subtopic)) {
        return false;
      }
      if (difficulty != null && q.difficulty != difficulty) return false;
      return true;
    }).toList();
  }

  Future<void> deleteQuestion(String id) async {
    await _repo.deleteQuestion(id);
    await reload();
  }

  /// Subtopic names of a theme, or empty if the theme does not exist.
  List<String> subtopicsOfTheme(String theme) {
    final t = _themes.where((t) => t.name == theme);
    if (t.isEmpty) return const [];
    return t.first.subtopics.map((s) => s.name).toList();
  }
}
