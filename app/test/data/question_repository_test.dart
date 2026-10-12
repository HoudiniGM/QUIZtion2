import 'package:flutter_test/flutter_test.dart';
import 'package:quiztion/data/app_database.dart';
import 'package:quiztion/data/question_repository.dart';
import 'package:quiztion/domain/answer_option.dart';
import 'package:quiztion/domain/difficulty.dart';
import 'package:quiztion/domain/question.dart';

import '../support/test_database.dart';

// Persistence tests using an in-memory SQLite database (no file, no AI).
//
// Prerequisite: run `dart run build_runner build` to generate
// app_database.g.dart.

Question exampleQuestion(String id, {String theme = 'Java Core'}) => Question(
      id: id,
      theme: theme,
      subtopic: 'Collections',
      statement: 'Statement $id',
      difficulty: Difficulty.basic,
      createdAt: DateTime(2026, 1, 1),
      options: const [
        AnswerOption(id: 'a', text: 'A', explanation: 'eA', correct: true),
        AnswerOption(id: 'b', text: 'B', explanation: 'eB', correct: false),
        AnswerOption(id: 'c', text: 'C', explanation: 'eC', correct: false),
        AnswerOption(id: 'd', text: 'D', explanation: 'eD', correct: false),
      ],
    );

void main() {
  late AppDatabase db;
  late QuestionRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = QuestionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('QuestionRepository', () {
    test('creates and reads themes and subtopics', () async {
      await repo.insertTheme(
          id: 'java-core', name: 'Java Core', createdAt: DateTime(2026));
      await repo.insertSubtopic(
        id: 'java-core__collections',
        themeId: 'java-core',
        name: 'Collections',
        createdAt: DateTime(2026),
      );

      final themes = await repo.listThemesWithSubtopics();
      expect(themes.length, 1);
      expect(themes.first.name, 'Java Core');
      expect(themes.first.subtopics.single.name, 'Collections');
    });

    test('saves a valid question and reads it back with its options', () async {
      await repo.insertQuestion(exampleQuestion('q1'));

      final questions = await repo.listQuestions();
      expect(questions.length, 1);
      final q = questions.first;
      expect(q.id, 'q1');
      expect(q.options.length, 4);
      expect(q.options.where((o) => o.correct).length, 1);
      expect(q.correctOption.id, 'a');
      // Option<->explanation association preserved.
      expect(q.correctOption.explanation, 'eA');
    });

    test('inserting the same question twice does not duplicate (idempotent)',
        () async {
      await repo.insertQuestion(exampleQuestion('q1'));
      await repo.insertQuestion(exampleQuestion('q1'));
      expect(await repo.countQuestions(), 1);
      final q = (await repo.listQuestions()).single;
      expect(q.options.length, 4);
    });

    test('filters questions by theme and difficulty', () async {
      await repo.insertQuestion(exampleQuestion('q1', theme: 'Java Core'));
      await repo.insertQuestion(exampleQuestion('q2', theme: 'Bancos de Dados'));

      final onlyJava = await repo.listQuestions(theme: 'Java Core');
      expect(onlyJava.map((q) => q.id), ['q1']);

      final basics = await repo.listQuestions(difficulty: Difficulty.basic);
      expect(basics.length, 2);

      final advanced =
          await repo.listQuestions(difficulty: Difficulty.advanced);
      expect(advanced, isEmpty);
    });

    test('deleting a question also removes its options (cascade)', () async {
      await repo.insertQuestion(exampleQuestion('q1'));
      await repo.deleteQuestion('q1');
      expect(await repo.countQuestions(), 0);

      // No orphan options should remain.
      final options = await db.select(db.answerOptions).get();
      expect(options, isEmpty);
    });

    test(
        'multiple questions reusing option ids a/b/c/d each keep their 4 options',
        () async {
      // Regression test: option ids are only unique within a question. With a
      // single-column primary key on options, insertOrIgnore dropped the
      // options of every question after the first (because ids collided),
      // leaving those questions with no answers.
      await repo.insertQuestion(exampleQuestion('q1'));
      await repo.insertQuestion(exampleQuestion('q2'));
      await repo.insertQuestion(exampleQuestion('q3'));

      final questions = await repo.listQuestions();
      expect(questions.length, 3);
      for (final q in questions) {
        expect(q.options.length, 4, reason: '${q.id} must keep all 4 options');
        expect(q.options.where((o) => o.correct).length, 1);
      }
      final total = await db.select(db.answerOptions).get();
      expect(total.length, 12); // 3 questions x 4 options
    });
  });
}
