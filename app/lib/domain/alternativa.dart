import 'tipo_conteudo.dart';

/// Uma alternativa de uma questão de múltipla escolha.
///
/// Cada alternativa mantém, de forma inseparável:
/// - um identificador estável ([id]);
/// - o texto exibido;
/// - a explicação individual;
/// - se é ou não a resposta correta.
///
/// Essa associação deve ser preservada mesmo quando a ordem das alternativas
/// for embaralhada (ver requisitos, seções 5, 9 e 15).
class Alternativa {
  /// Identificador estável da alternativa. Não muda com o embaralhamento.
  final String id;

  /// Texto da alternativa.
  final String texto;

  /// Explicação individual: por que está correta ou incorreta.
  final String explicacao;

  /// Indica se esta é a (única) alternativa correta da questão.
  final bool correta;

  /// Tipo de conteúdo do texto da alternativa (texto ou código).
  final TipoConteudo tipoConteudo;

  const Alternativa({
    required this.id,
    required this.texto,
    required this.explicacao,
    required this.correta,
    this.tipoConteudo = TipoConteudo.texto,
  });

  Alternativa copyWith({
    String? id,
    String? texto,
    String? explicacao,
    bool? correta,
    TipoConteudo? tipoConteudo,
  }) {
    return Alternativa(
      id: id ?? this.id,
      texto: texto ?? this.texto,
      explicacao: explicacao ?? this.explicacao,
      correta: correta ?? this.correta,
      tipoConteudo: tipoConteudo ?? this.tipoConteudo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alternativa &&
          other.id == id &&
          other.texto == texto &&
          other.explicacao == explicacao &&
          other.correta == correta &&
          other.tipoConteudo == tipoConteudo;

  @override
  int get hashCode =>
      Object.hash(id, texto, explicacao, correta, tipoConteudo);

  @override
  String toString() =>
      'Alternativa(id: $id, correta: $correta, texto: "$texto")';
}
