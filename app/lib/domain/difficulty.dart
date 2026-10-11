/// Difficulty levels of a question.
///
/// Difficulty reflects the reasoning required to answer the question, not the
/// length of the statement or the rarity of the content (see requirements,
/// section 8).
enum Difficulty {
  basic,
  intermediate,
  advanced;

  /// Human-readable pt-BR label shown in the UI.
  String get label {
    switch (this) {
      case Difficulty.basic:
        return 'Básico';
      case Difficulty.intermediate:
        return 'Intermediário';
      case Difficulty.advanced:
        return 'Avançado';
    }
  }

  /// Stable identifier used for persistence and API (never localized).
  String get id => name;

  /// Parses a persisted/API identifier into the enum.
  ///
  /// Throws [ArgumentError] if the value is not a valid level.
  static Difficulty fromId(String id) {
    switch (id) {
      case 'basic':
        return Difficulty.basic;
      case 'intermediate':
        return Difficulty.intermediate;
      case 'advanced':
        return Difficulty.advanced;
      default:
        throw ArgumentError('Invalid difficulty: "$id"');
    }
  }

  /// Returns the matching enum, or `null` if the value is invalid.
  static Difficulty? tryFromId(String? id) {
    if (id == null) return null;
    try {
      return fromId(id);
    } on ArgumentError {
      return null;
    }
  }
}
