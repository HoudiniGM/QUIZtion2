import 'answer_option.dart';
import 'content_type.dart';
import 'difficulty.dart';

/// A multiple-choice question.
///
/// MVP invariants (see requirements, sections 9, 11 and 12):
/// - exactly 4 options;
/// - exactly 1 correct option;
/// - each option has an individual explanation.
///
/// Strong enforcement of these rules is done by the validator; the constructor
/// itself does not prevent creating invalid instances (e.g. data from an
/// unvalidated generation), but such instances must never be persisted.
class Question {
  final String id;
  final String theme;
  final String subtopic;
  final String statement;
  final ContentType contentType;
  final List<AnswerOption> options;
  final Difficulty difficulty;
  final List<String> tags;
  final DateTime createdAt;

  /// Version of the base prompt used in generation (when applicable).
  final String? promptVersion;

  const Question({
    required this.id,
    required this.theme,
    required this.subtopic,
    required this.statement,
    required this.options,
    required this.difficulty,
    required this.createdAt,
    this.contentType = ContentType.text,
    this.tags = const [],
    this.promptVersion,
  });

  /// The correct option of the question.
  ///
  /// Assumes a valid question (exactly one correct). Throws [StateError] if
  /// there is not exactly one correct option.
  AnswerOption get correctOption => options.singleWhere((o) => o.correct);

  Question copyWith({
    String? id,
    String? theme,
    String? subtopic,
    String? statement,
    ContentType? contentType,
    List<AnswerOption>? options,
    Difficulty? difficulty,
    List<String>? tags,
    DateTime? createdAt,
    String? promptVersion,
  }) {
    return Question(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      subtopic: subtopic ?? this.subtopic,
      statement: statement ?? this.statement,
      contentType: contentType ?? this.contentType,
      options: options ?? this.options,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      promptVersion: promptVersion ?? this.promptVersion,
    );
  }

  @override
  String toString() =>
      'Question(id: $id, theme: $theme, subtopic: $subtopic, '
      'difficulty: ${difficulty.id})';
}
