import 'question.dart';

/// Result of trying to assemble a quiz from filters.
///
/// Explicitly handles the insufficient-quantity case (see requirements,
/// section 14): the app must not silently start a quiz with a different
/// quantity than requested.
class QuizSelection {
  /// Available questions matching the filters (theme/subtopics).
  final List<Question> available;

  /// Quantity of questions requested by the user.
  final int requested;

  const QuizSelection({
    required this.available,
    required this.requested,
  });

  int get availableCount => available.length;

  bool get hasAny => available.isNotEmpty;

  /// There are fewer available questions than requested.
  bool get insufficient => availableCount < requested;

  /// Effective quantity to be used (never greater than what is available).
  int get effectiveCount =>
      availableCount < requested ? availableCount : requested;

  /// User-facing message (pt-BR) when the quantity is insufficient.
  String? get insufficiencyMessage {
    if (!insufficient) return null;
    if (availableCount == 0) {
      return 'Não há questões disponíveis para os filtros selecionados.';
    }
    return 'Há apenas $availableCount questão(ões) disponível(is), '
        'mas você solicitou $requested.';
  }
}
