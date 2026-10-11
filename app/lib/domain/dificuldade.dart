/// Níveis de dificuldade de uma questão.
///
/// A dificuldade reflete o raciocínio necessário para resolver a questão, e não
/// o tamanho do enunciado ou a raridade do conteúdo (ver requisitos, seção 8).
enum Dificuldade {
  basico,
  intermediario,
  avancado;

  /// Rótulo legível em pt-BR para exibição na interface.
  String get rotulo {
    switch (this) {
      case Dificuldade.basico:
        return 'Básico';
      case Dificuldade.intermediario:
        return 'Intermediário';
      case Dificuldade.avancado:
        return 'Avançado';
    }
  }

  /// Converte um identificador persistido/da API para o enum.
  ///
  /// Lança [ArgumentError] se o valor não corresponder a um nível válido.
  static Dificuldade fromId(String id) {
    switch (id) {
      case 'basico':
        return Dificuldade.basico;
      case 'intermediario':
        return Dificuldade.intermediario;
      case 'avancado':
        return Dificuldade.avancado;
      default:
        throw ArgumentError('Dificuldade inválida: "$id"');
    }
  }

  /// Identificador estável para persistência (nunca localizado).
  String get id => name;

  /// Retorna o enum correspondente ou `null` se o valor for inválido.
  static Dificuldade? tryFromId(String? id) {
    if (id == null) return null;
    try {
      return fromId(id);
    } on ArgumentError {
      return null;
    }
  }
}
