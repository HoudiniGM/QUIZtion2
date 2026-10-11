import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tabelas.dart';

part 'banco.g.dart';

/// Banco de dados local do QUIZtion (SQLite via drift).
///
/// A geração de código (`banco.g.dart`) é feita com:
///   dart run build_runner build --delete-conflicting-outputs
@DriftDatabase(
  tables: [
    Temas,
    Subtopicos,
    Questoes,
    Alternativas,
    Tentativas,
    RespostasTentativa,
  ],
)
class Banco extends _$Banco {
  Banco([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'quiztion'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // Garante integridade referencial (ON DELETE CASCADE funciona).
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
