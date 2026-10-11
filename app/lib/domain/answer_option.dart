import 'content_type.dart';

/// A single answer option of a multiple-choice question.
///
/// Each option keeps, inseparably:
/// - a stable identifier ([id]);
/// - the displayed text;
/// - an individual explanation;
/// - whether it is the correct answer.
///
/// This association must be preserved even when the order of the options is
/// shuffled (see requirements, sections 5, 9 and 15).
class AnswerOption {
  /// Stable option identifier. Does not change when shuffled.
  final String id;

  /// Option text.
  final String text;

  /// Individual explanation: why it is correct or incorrect.
  final String explanation;

  /// Whether this is the (single) correct option of the question.
  final bool correct;

  /// Content type of the option text (text or code).
  final ContentType contentType;

  const AnswerOption({
    required this.id,
    required this.text,
    required this.explanation,
    required this.correct,
    this.contentType = ContentType.text,
  });

  AnswerOption copyWith({
    String? id,
    String? text,
    String? explanation,
    bool? correct,
    ContentType? contentType,
  }) {
    return AnswerOption(
      id: id ?? this.id,
      text: text ?? this.text,
      explanation: explanation ?? this.explanation,
      correct: correct ?? this.correct,
      contentType: contentType ?? this.contentType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnswerOption &&
          other.id == id &&
          other.text == text &&
          other.explanation == explanation &&
          other.correct == correct &&
          other.contentType == contentType;

  @override
  int get hashCode => Object.hash(id, text, explanation, correct, contentType);

  @override
  String toString() => 'AnswerOption(id: $id, correct: $correct, text: "$text")';
}
