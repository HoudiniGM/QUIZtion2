import 'questao.dart';

/// Resultado da validação de uma questão.
class ResultadoValidacao {
  final bool valida;
  final List<String> erros;

  const ResultadoValidacao._(this.valida, this.erros);

  const ResultadoValidacao.ok() : this._(true, const []);
  const ResultadoValidacao.falha(List<String> erros) : this._(false, erros);

  /// Primeiro erro encontrado, útil para mensagens curtas.
  String? get primeiroErro => erros.isEmpty ? null : erros.first;
}

/// Validação estrutural de uma questão, aplicada antes de qualquer salvamento.
///
/// Espelha, no app, as regras mínimas da seção 12 dos requisitos. Na Etapa 3,
/// o backend fará uma validação equivalente (e mais rica) antes de devolver as
/// questões; esta validação local é a última barreira antes de persistir.
class ValidacaoQuestao {
  const ValidacaoQuestao._();

  static ResultadoValidacao validar(Questao q) {
    final erros = <String>[];

    if (q.tema.trim().isEmpty) {
      erros.add('O tema é obrigatório.');
    }
    if (q.subtopico.trim().isEmpty) {
      erros.add('O subtópico é obrigatório.');
    }
    if (q.enunciado.trim().isEmpty) {
      erros.add('O enunciado não pode ser vazio.');
    }

    if (q.alternativas.length != 4) {
      erros.add(
        'A questão deve ter exatamente 4 alternativas '
        '(encontradas: ${q.alternativas.length}).',
      );
    }

    final corretas = q.alternativas.where((a) => a.correta).length;
    if (corretas != 1) {
      erros.add(
        'A questão deve ter exatamente 1 alternativa correta '
        '(encontradas: $corretas).',
      );
    }

    for (final a in q.alternativas) {
      if (a.texto.trim().isEmpty) {
        erros.add('Toda alternativa deve ter texto.');
        break;
      }
    }
    for (final a in q.alternativas) {
      if (a.explicacao.trim().isEmpty) {
        erros.add('Toda alternativa deve ter uma explicação individual.');
        break;
      }
    }

    // Alternativas duplicadas ou praticamente idênticas (normalização simples).
    final textosNormalizados =
        q.alternativas.map((a) => _normalizar(a.texto)).toList();
    final distintos = textosNormalizados.toSet();
    if (distintos.length != textosNormalizados.length) {
      erros.add('Há alternativas duplicadas ou praticamente idênticas.');
    }

    // Identificadores de alternativa devem ser únicos (associação estável).
    final ids = q.alternativas.map((a) => a.id).toList();
    if (ids.toSet().length != ids.length) {
      erros.add('Os identificadores das alternativas devem ser únicos.');
    }

    return erros.isEmpty
        ? const ResultadoValidacao.ok()
        : ResultadoValidacao.falha(erros);
  }

  static bool ehValida(Questao q) => validar(q).valida;

  static String _normalizar(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
