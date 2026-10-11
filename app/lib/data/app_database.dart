import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Local database of QUIZtion (SQLite via drift).
///
/// Code generation (`app_database.g.dart`) is produced with:
///   dart run build_runner build --delete-conflicting-outputs
@DriftDatabase(
  tables: [
    Themes,
    Subtopics,
    Questions,
    AnswerOptions,
    Attempts,
    AttemptAnswers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'quiztion'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // Ensure referential integrity (ON DELETE CASCADE works).
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
