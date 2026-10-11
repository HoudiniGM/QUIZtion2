/// Distingue o tipo de conteúdo de um enunciado/explicação.
///
/// No MVP há suporte a texto e a blocos de código (fonte monoespaçada,
/// preservando indentação). Imagens/diagramas ficam fora do MVP, mas o modelo
/// é extensível para suportá-los no futuro (ver requisitos, seções 10 e 11).
enum TipoConteudo {
  texto,
  codigo;

  String get id => name;

  static TipoConteudo fromId(String id) {
    switch (id) {
      case 'texto':
        return TipoConteudo.texto;
      case 'codigo':
        return TipoConteudo.codigo;
      default:
        throw ArgumentError('Tipo de conteúdo inválido: "$id"');
    }
  }

  static TipoConteudo fromIdOrDefault(String? id) {
    if (id == null) return TipoConteudo.texto;
    try {
      return fromId(id);
    } on ArgumentError {
      return TipoConteudo.texto;
    }
  }
}
