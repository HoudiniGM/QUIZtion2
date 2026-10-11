/// Distinguishes the content type of a statement/explanation.
///
/// The MVP supports plain text and code blocks (monospaced font, preserving
/// indentation). Images/diagrams are out of scope for the MVP, but the model
/// is extensible to support them later (see requirements, sections 10 and 11).
enum ContentType {
  text,
  code;

  String get id => name;

  static ContentType fromId(String id) {
    switch (id) {
      case 'text':
        return ContentType.text;
      case 'code':
        return ContentType.code;
      default:
        throw ArgumentError('Invalid content type: "$id"');
    }
  }

  static ContentType fromIdOrDefault(String? id) {
    if (id == null) return ContentType.text;
    try {
      return fromId(id);
    } on ArgumentError {
      return ContentType.text;
    }
  }
}
