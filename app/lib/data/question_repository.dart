import 'package:drift/drift.dart';

import '../domain/answer_option.dart';
import '../domain/content_type.dart';
import '../domain/difficulty.dart';
import '../domain/question.dart';
import 'app_database.dart';

/// A theme with its subtopics, for the UI.
class ThemeWithSubtopics {
  final String id;
  final String name;
  final List<SubtopicInfo> subtopics;

  const ThemeWithSubtopics({
    required this.id,
    required this.name,
    required this.subtopics,
  });
}

class SubtopicInfo {
  final String id;
  final String themeId;
  final String name;

  const SubtopicInfo({
    required this.id,
    required this.themeId,
    required this.name,
  });
}

/// Access to themes, subtopics and questions in the local database.
class QuestionRepository {
  final AppDatabase _db;

  QuestionRepository(this._db);

  // ---------------------------------------------------------------------------
  // Themes and subtopics
  // ---------------------------------------------------------------------------

  Future<List<ThemeWithSubtopics>> listThemesWithSubtopics() async {
    final themes = await _db.select(_db.themes).get();
    final subs = await _db.select(_db.subtopics).get();
    themes.sort((a, b) => a.name.compareTo(b.name));
    return themes.map((t) {
      final mine = subs.where((s) => s.themeId == t.id).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return ThemeWithSubtopics(
        id: t.id,
        name: t.name,
        subtopics: mine
            .map((s) =>
                SubtopicInfo(id: s.id, themeId: s.themeId, name: s.name))
            .toList(),
      );
    }).toList();
  }

  Future<void> insertTheme(
      {required String id, required String name, required DateTime createdAt}) {
    return _db.into(_db.themes).insert(
          ThemesCompanion.insert(id: id, name: name, createdAt: createdAt),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<void> insertSubtopic({
    required String id,
    required String themeId,
    required String name,
    required DateTime createdAt,
  }) {
    return _db.into(_db.subtopics).insert(
          SubtopicsCompanion.insert(
            id: id,
            themeId: themeId,
            name: name,
            createdAt: createdAt,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  // ---------------------------------------------------------------------------
  // Questions
  // ---------------------------------------------------------------------------

  Future<int> countQuestions() async {
    final expr = countAll();
    final q = _db.selectOnly(_db.questions)..addColumns([expr]);
    final row = await q.getSingle();
    return row.read(expr) ?? 0;
  }

  /// Lists questions, optionally filtered by theme, subtopics and difficulty.
  Future<List<Question>> listQuestions({
    String? theme,
    List<String>? subtopics,
    Difficulty? difficulty,
  }) async {
    final query = _db.select(_db.questions);
    if (theme != null) {
      query.where((t) => t.theme.equals(theme));
    }
    if (subtopics != null && subtopics.isNotEmpty) {
      query.where((t) => t.subtopic.isIn(subtopics));
    }
    if (difficulty != null) {
      query.where((t) => t.difficulty.equals(difficulty.id));
    }
    final questionRows = await query.get();
    if (questionRows.isEmpty) return [];

    final ids = questionRows.map((q) => q.id).toList();
    final optionRows = await (_db.select(_db.answerOptions)
          ..where((o) => o.questionId.isIn(ids)))
        .get();

    final byQuestion = <String, List<AnswerOptionRow>>{};
    for (final o in optionRows) {
      byQuestion.putIfAbsent(o.questionId, () => []).add(o);
    }

    return questionRows
        .map((q) => _buildQuestion(q, byQuestion[q.id] ?? []))
        .toList();
  }

  Future<void> deleteQuestion(String id) async {
    // Delete options and question in a transaction. This does not rely on
    // SQLite's ON DELETE CASCADE being active (which depends on the
    // `foreign_keys` pragma being ON for the connection); the schema still
    // declares the cascade as a safety net.
    await _db.transaction(() async {
      await (_db.delete(_db.answerOptions)
            ..where((o) => o.questionId.equals(id)))
          .go();
      await (_db.delete(_db.questions)..where((q) => q.id.equals(id))).go();
    });
  }

  /// Inserts a question with its options atomically (transaction), using
  /// insert-or-ignore to avoid accidental duplication on repeated operations.
  Future<void> insertQuestion(Question question) async {
    await _db.transaction(() async {
      await _db.into(_db.questions).insert(
            QuestionsCompanion.insert(
              id: question.id,
              subtopicId: _subtopicSlug(question.theme, question.subtopic),
              theme: question.theme,
              subtopic: question.subtopic,
              statement: question.statement,
              difficulty: question.difficulty.id,
              createdAt: question.createdAt,
              codeSnippet: Value(question.codeSnippet),
              contentType: Value(question.contentType.id),
              tags: Value(question.tags.join(',')),
              promptVersion: Value(question.promptVersion),
            ),
            mode: InsertMode.insertOrIgnore,
          );
      for (var i = 0; i < question.options.length; i++) {
        final o = question.options[i];
        await _db.into(_db.answerOptions).insert(
              AnswerOptionsCompanion.insert(
                id: o.id,
                questionId: question.id,
                optionText: o.text,
                explanation: o.explanation,
                correct: o.correct,
                position: i,
                contentType: Value(o.contentType.id),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  Question _buildQuestion(QuestionRow q, List<AnswerOptionRow> options) {
    options.sort((a, b) => a.position.compareTo(b.position));
    return Question(
      id: q.id,
      theme: q.theme,
      subtopic: q.subtopic,
      statement: q.statement,
      codeSnippet: q.codeSnippet,
      contentType: ContentType.fromIdOrDefault(q.contentType),
      difficulty: Difficulty.fromId(q.difficulty),
      tags: q.tags.isEmpty ? const [] : q.tags.split(','),
      createdAt: q.createdAt,
      promptVersion: q.promptVersion,
      options: options
          .map((o) => AnswerOption(
                id: o.id,
                text: o.optionText,
                explanation: o.explanation,
                correct: o.correct,
                contentType: ContentType.fromIdOrDefault(o.contentType),
              ))
          .toList(),
    );
  }

  static String _subtopicSlug(String theme, String subtopic) =>
      '${_slug(theme)}__${_slug(subtopic)}';

  static String _slug(String s) => s
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'(^-|-$)'), '');
}
