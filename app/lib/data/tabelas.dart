import 'package:drift/drift.dart';

/// Temas de estudo (ex.: Java, Biologia, História).
@DataClassName('TemaRow')
class Temas extends Table {
  TextColumn get id => text()();
  TextColumn get nome => text()();
  DateTimeColumn get criadoEm => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Subtópicos pertencentes a um tema (ex.: Collections, Genética).
@DataClassName('SubtopicoRow')
class Subtopicos extends Table {
  TextColumn get id => text()();
  TextColumn get temaId => text().references(Temas, #id)();
  TextColumn get nome => text()();
  DateTimeColumn get criadoEm => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Questões de múltipla escolha.
///
/// Os campos [versaoPrompt] e [metadadosGeracao] são preenchidos quando a
/// questão é gerada por IA (Etapa 3); permanecem nulos para questões de
/// exemplo criadas localmente. O campo [tipoConteudo] distingue texto/código.
@DataClassName('QuestaoRow')
class Questoes extends Table {
  TextColumn get id => text()();
  // Referência lógica ao subtópico (slug). Mantida como coluna simples, sem
  // FK forçada, para desacoplar a questão do cadastro prévio do subtópico no
  // MVP; os campos `tema`/`subtopico` abaixo são a fonte para filtros/exibição.
  TextColumn get subtopicoId => text()();
  // Desnormalizados para facilitar filtros e preservar o rótulo exibido.
  TextColumn get tema => text()();
  TextColumn get subtopico => text()();
  TextColumn get enunciado => text()();
  TextColumn get tipoConteudo => text().withDefault(const Constant('texto'))();
  TextColumn get dificuldade => text()();
  TextColumn get tags => text().withDefault(const Constant(''))();
  DateTimeColumn get criadaEm => dateTime()();
  TextColumn get versaoPrompt => text().nullable()();
  TextColumn get metadadosGeracao => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Alternativas de uma questão. Cada alternativa mantém, de forma estável, seu
/// texto, explicação individual, flag de correta e ordem canônica.
@DataClassName('AlternativaRow')
class Alternativas extends Table {
  TextColumn get id => text()();
  TextColumn get questaoId =>
      text().references(Questoes, #id, onDelete: KeyAction.cascade)();
  TextColumn get texto => text()();
  TextColumn get explicacao => text()();
  BoolColumn get correta => boolean()();
  TextColumn get tipoConteudo => text().withDefault(const Constant('texto'))();
  IntColumn get ordem => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tentativas de quiz concluídas (histórico — populado a partir da Etapa 2).
@DataClassName('TentativaRow')
class Tentativas extends Table {
  TextColumn get id => text()();
  DateTimeColumn get data => dateTime()();
  TextColumn get tema => text()();
  // Lista de subtópicos serializada (JSON) — simples para o MVP.
  TextColumn get subtopicos => text()();
  IntColumn get total => integer()();
  IntColumn get acertos => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Respostas individuais de cada tentativa, com os dados necessários para
/// reconstruir o resultado (seção 15 dos requisitos).
@DataClassName('RespostaTentativaRow')
class RespostasTentativa extends Table {
  TextColumn get id => text()();
  TextColumn get tentativaId =>
      text().references(Tentativas, #id, onDelete: KeyAction.cascade)();
  TextColumn get questaoId => text()();
  TextColumn get idAlternativaEscolhida => text()();

  @override
  Set<Column> get primaryKey => {id};
}
