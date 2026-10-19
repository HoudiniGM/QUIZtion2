import 'question.dart';

/// Result of validating a question.
class ValidationResult {
  final bool valid;

  /// User-facing error messages (pt-BR), empty when valid.
  final List<String> errors;

  const ValidationResult._(this.valid, this.errors);

  const ValidationResult.ok() : this._(true, const []);
  const ValidationResult.failure(List<String> errors) : this._(false, errors);

  /// First error found, useful for short messages.
  String? get firstError => errors.isEmpty ? null : errors.first;
}

/// Structural validation of a question, applied before any save.
///
/// Mirrors, on the app side, the minimum rules of requirements section 12. In
/// Stage 3 the backend performs an equivalent (richer) validation before
/// returning questions; this local validation is the last barrier before
/// persisting.
class QuestionValidation {
  const QuestionValidation._();

  static ValidationResult validate(Question q) {
    final errors = <String>[];

    if (q.theme.trim().isEmpty) {
      errors.add('O tema é obrigatório.');
    }
    if (q.subtopic.trim().isEmpty) {
      errors.add('O subtópico é obrigatório.');
    }
    if (q.statement.trim().isEmpty) {
      errors.add('O enunciado não pode ser vazio.');
    }

    if (q.options.length != 4) {
      errors.add(
        'A questão deve ter exatamente 4 alternativas '
        '(encontradas: ${q.options.length}).',
      );
    }

    final correctCount = q.options.where((o) => o.correct).length;
    if (correctCount < 1) {
      errors.add('A questão deve ter pelo menos 1 alternativa correta.');
    } else if (correctCount == q.options.length) {
      // All options correct is not a meaningful question.
      errors.add('A questão não pode ter todas as alternativas corretas.');
    }

    for (final o in q.options) {
      if (o.text.trim().isEmpty) {
        errors.add('Toda alternativa deve ter texto.');
        break;
      }
    }
    for (final o in q.options) {
      if (o.explanation.trim().isEmpty) {
        errors.add('Toda alternativa deve ter uma explicação individual.');
        break;
      }
    }

    // Duplicate or nearly identical options (simple normalization).
    final normalizedTexts = q.options.map((o) => _normalize(o.text)).toList();
    if (normalizedTexts.toSet().length != normalizedTexts.length) {
      errors.add('Há alternativas duplicadas ou praticamente idênticas.');
    }

    // Option identifiers must be unique (stable association).
    final ids = q.options.map((o) => o.id).toList();
    if (ids.toSet().length != ids.length) {
      errors.add('Os identificadores das alternativas devem ser únicos.');
    }

    return errors.isEmpty
        ? const ValidationResult.ok()
        : ValidationResult.failure(errors);
  }

  static bool isValid(Question q) => validate(q).valid;

  static String _normalize(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
