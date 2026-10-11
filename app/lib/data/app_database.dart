import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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

  /// In-memory database for tests.
  ///
  /// Enables `foreign_keys` directly on the raw connection via [setup], which
  /// is the reliable place to do it: SQLite resets `foreign_keys` to OFF on
  /// every connection, and the PRAGMA is a no-op inside a transaction, so
  /// setting it here guarantees ON DELETE CASCADE works in tests.
  AppDatabase.memory()
      : super(NativeDatabase.memory(
          setup: (rawDb) {
            rawDb.execute('PRAGMA foreign_keys = ON');
          },
        ));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // Ensure referential integrity (ON DELETE CASCADE works) on the
          // production connection. On devices this runs once per open.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
