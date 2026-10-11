import 'package:drift/native.dart';
import 'package:quiztion/data/app_database.dart';

/// Builds an in-memory [AppDatabase] for tests.
///
/// Lives under `test/` (not `lib/`) because `package:drift/native.dart` pulls
/// in `dart:ffi`, which is unavailable on the web and would break the web
/// build if imported from production code.
///
/// Enables `foreign_keys` directly on the raw connection via [setup] — the
/// reliable place to do it, since SQLite resets `foreign_keys` to OFF on every
/// connection and ignores the PRAGMA inside a transaction.
AppDatabase createTestDatabase() {
  return AppDatabase(
    NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON');
      },
    ),
  );
}
