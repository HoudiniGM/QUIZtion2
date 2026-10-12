import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Local database of QUIZtion (SQLite via drift).
///
/// Code generation (`app_database.g.dart`) is produced with:
///   dart run build_runner build --delete-conflicting-outputs
///
/// Note: this file must stay web-compatible, so it must NOT import
/// `package:drift/native.dart` (which pulls in `dart:ffi`, unavailable on the
/// web). The in-memory database used by tests lives under `test/` instead.
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
      : super(executor ??
            driftDatabase(
              name: 'quiztion',
              // Required for the web build: these files must be present in
              // app/web/ (sqlite3.wasm and drift_worker.js). They are ignored
              // on native platforms, where sqlite3_flutter_libs is used.
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // v2: the answer_options primary key changed from {id} to
          // {questionId, id}. In v1, option ids collided across questions and
          // insertOrIgnore dropped options of all but the first question,
          // leaving questions without answers. There is no user-authored data
          // in this stage (only seeded example questions), so the safe,
          // simplest fix is to drop and recreate all tables; the app re-seeds
          // on next launch.
          for (final table in allTables) {
            await m.deleteTable(table.actualTableName);
          }
          await m.createAll();
        },
        beforeOpen: (details) async {
          // Ensure referential integrity (ON DELETE CASCADE works) on the
          // production connection. On devices this runs once per open.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
