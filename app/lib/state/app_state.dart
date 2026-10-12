import 'package:flutter/material.dart';

import '../data/question_repository.dart';
import '../data/sample_data.dart';
import '../data/settings_repository.dart';
import '../domain/difficulty.dart';
import '../domain/question.dart';

/// Global application state: themes/subtopics, question bank and settings.
///
/// Keeps the data loaded from SQLite and exposes operations used by screens.
class AppState extends ChangeNotifier {
  final QuestionRepository _repo;
  final SettingsRepository _settings;
  final DataSeeder _seeder;

  AppState(this._repo, this._settings) : _seeder = DataSeeder(_repo);

  SettingsRepository get settings => _settings;

  ThemeMode get themeMode => _settings.themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settings.setThemeMode(mode);
    notifyListeners();
  }

  bool _loading = true;
  bool get loading => _loading;

  List<ThemeWithSubtopics> _themes = [];
  List<ThemeWithSubtopics> get themes => _themes;

  List<Question> _questions = [];
  List<Question> get questions => _questions;

  int get totalQuestions => _questions.length;

  int get totalThemes => _themes.length;

  int get totalSubtopics =>
      _themes.fold(0, (sum, t) => sum + t.subtopics.length);

  /// Count of questions per difficulty, for the home summary.
  Map<Difficulty, int> get questionsByDifficulty {
    final map = {for (final d in Difficulty.values) d: 0};
    for (final q in _questions) {
      map[q.difficulty] = (map[q.difficulty] ?? 0) + 1;
    }
    return map;
  }

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

  /// Persists newly generated questions and refreshes the loaded data.
  Future<void> saveGeneratedQuestions(List<Question> questions) async {
    for (final q in questions) {
      await _repo.insertQuestion(q);
    }
    await reload();
  }

  /// Short statement summaries of existing questions for a theme/subtopic,
  /// used to help the backend avoid duplicates. Capped to a small number.
  List<String> existingSummaries({
    required String theme,
    required String subtopic,
    int max = 20,
  }) {
    return _questions
        .where((q) => q.theme == theme && q.subtopic == subtopic)
        .map((q) => q.statement)
        .take(max)
        .toList();
  }

  /// Subtopic names of a theme, or empty if the theme does not exist.
  List<String> subtopicsOfTheme(String theme) {
    final t = _themes.where((t) => t.name == theme);
    if (t.isEmpty) return const [];
    return t.first.subtopics.map((s) => s.name).toList();
  }

  /// Creates a theme (if a theme with the same name does not already exist)
  /// and returns its name. Reloads the data.
  Future<String> createTheme(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('O nome do tema não pode ser vazio.');
    }
    final existing = _themes.where(
      (t) => t.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (existing.isNotEmpty) return existing.first.name;

    await _repo.insertTheme(
      id: _slug(trimmed),
      name: trimmed,
      createdAt: DateTime.now(),
    );
    await reload();
    return trimmed;
  }

  /// Creates a subtopic under a theme (idempotent by name) and returns its
  /// name. Reloads the data.
  Future<String> createSubtopic({
    required String theme,
    required String name,
  }) async {
    final trimmedSub = name.trim();
    if (trimmedSub.isEmpty) {
      throw ArgumentError('O nome do subtópico não pode ser vazio.');
    }
    if (subtopicsOfTheme(theme)
        .any((s) => s.toLowerCase() == trimmedSub.toLowerCase())) {
      return trimmedSub;
    }
    await _repo.insertSubtopic(
      id: '${_slug(theme)}__${_slug(trimmedSub)}',
      themeId: _slug(theme),
      name: trimmedSub,
      createdAt: DateTime.now(),
    );
    await reload();
    return trimmedSub;
  }

  static String _slug(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-|-$)'), '');
}
