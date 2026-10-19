import 'answer_option.dart';
import 'content_type.dart';
import 'difficulty.dart';

/// A multiple-choice question.
///
/// MVP invariants (see requirements, sections 9, 11 and 12):
/// - exactly 4 options;
/// - at least 1 correct option (one or more — multiple-answer questions);
/// - each option has an individual explanation.
///
/// Strong enforcement of these rules is done by the validator; the constructor
/// itself does not prevent creating invalid instances (e.g. data from an
/// unvalidated generation), but such instances must never be persisted.
class Question {
  final String id;
  final String theme;
  final String subtopic;

  /// The question statement in natural language (always plain text).
  final String statement;

  /// Optional code snippet shown as a monospaced code block below the
  /// statement. When null, the question has no code. Keeping it separate from
  /// [statement] prevents the natural-language text from being rendered as
  /// code (see requirements, section 10).
  final String? codeSnippet;

  /// Content type of the statement. Kept for extensibility; the statement is
  /// expected to be plain text — code goes in [codeSnippet].
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
    this.codeSnippet,
    this.contentType = ContentType.text,
    this.tags = const [],
    this.promptVersion,
  });

  /// Whether the question has a code snippet to display.
  bool get hasCode => codeSnippet != null && codeSnippet!.trim().isNotEmpty;

  /// All correct options of the question (one or more).
  List<AnswerOption> get correctOptions =>
      options.where((o) => o.correct).toList();

  /// Ids of all correct options.
  Set<String> get correctOptionIds =>
      options.where((o) => o.correct).map((o) => o.id).toSet();

  /// Whether the question has more than one correct option.
  bool get isMultipleAnswer => correctOptions.length > 1;

  Question copyWith({
    String? id,
    String? theme,
    String? subtopic,
    String? statement,
    String? codeSnippet,
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
      codeSnippet: codeSnippet ?? this.codeSnippet,
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
