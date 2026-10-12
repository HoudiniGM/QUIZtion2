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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Schema history (stage 1 has only seeded example data, no
          // user-authored content, so each upgrade safely drops and recreates
          // all tables; the app re-seeds on next launch):
          //   v2: answer_options primary key changed to {questionId, id}
          //       (option ids collided across questions in v1).
          //   v3: questions gained a nullable code_snippet column so the
          //       statement text is no longer rendered as a code block.
          //   v4: removed the attempts/attempt_answers tables (quiz attempt
          //       history is out of scope).
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
