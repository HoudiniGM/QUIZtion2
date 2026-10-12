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
