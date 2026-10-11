import 'alternativa.dart';
import 'dificuldade.dart';
import 'tipo_conteudo.dart';

/// Uma questão de múltipla escolha.
///
/// Invariantes do MVP (ver requisitos, seções 9, 11 e 12):
/// - exatamente 4 alternativas;
/// - exatamente 1 alternativa correta;
/// - cada alternativa possui explicação individual.
///
/// A validação forte dessas regras é feita por [validar]; o construtor em si
/// não impede a criação de instâncias inválidas (por exemplo, dados vindos de
/// uma geração ainda não validada), mas elas nunca devem ser persistidas.
class Questao {
  final String id;
  final String tema;
  final String subtopico;
  final String enunciado;
  final TipoConteudo tipoConteudo;
  final List<Alternativa> alternativas;
  final Dificuldade dificuldade;
  final List<String> tags;
  final DateTime criadaEm;

  /// Versão do prompt-base usado na geração (quando aplicável).
  final String? versaoPrompt;

  const Questao({
    required this.id,
    required this.tema,
    required this.subtopico,
    required this.enunciado,
    required this.alternativas,
    required this.dificuldade,
    required this.criadaEm,
    this.tipoConteudo = TipoConteudo.texto,
    this.tags = const [],
    this.versaoPrompt,
  });

  /// Alternativa correta da questão.
  ///
  /// Pressupõe uma questão válida (exatamente uma correta). Lança [StateError]
  /// se não houver exatamente uma alternativa correta.
  Alternativa get alternativaCorreta =>
      alternativas.singleWhere((a) => a.correta);

  Questao copyWith({
    String? id,
    String? tema,
    String? subtopico,
    String? enunciado,
    TipoConteudo? tipoConteudo,
    List<Alternativa>? alternativas,
    Dificuldade? dificuldade,
    List<String>? tags,
    DateTime? criadaEm,
    String? versaoPrompt,
  }) {
    return Questao(
      id: id ?? this.id,
      tema: tema ?? this.tema,
      subtopico: subtopico ?? this.subtopico,
      enunciado: enunciado ?? this.enunciado,
      tipoConteudo: tipoConteudo ?? this.tipoConteudo,
      alternativas: alternativas ?? this.alternativas,
      dificuldade: dificuldade ?? this.dificuldade,
      tags: tags ?? this.tags,
      criadaEm: criadaEm ?? this.criadaEm,
      versaoPrompt: versaoPrompt ?? this.versaoPrompt,
    );
  }

  @override
  String toString() =>
      'Questao(id: $id, tema: $tema, subtopico: $subtopico, '
      'dificuldade: ${dificuldade.id})';
}
