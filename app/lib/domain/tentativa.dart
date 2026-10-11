import 'questao.dart';

/// Registro de uma única resposta dada durante um quiz.
///
/// Guarda a questão respondida (com as alternativas na ordem em que foram
/// exibidas), o id da alternativa escolhida pelo usuário e o id da correta.
/// Preserva a informação necessária para reconstruir o resultado depois,
/// independentemente de qualquer embaralhamento (ver requisitos, seção 15).
class RespostaQuiz {
  final Questao questao;

  /// Id da alternativa escolhida pelo usuário.
  final String idAlternativaEscolhida;

  const RespostaQuiz({
    required this.questao,
    required this.idAlternativaEscolhida,
  });

  /// Id da alternativa correta da questão.
  String get idAlternativaCorreta => questao.alternativaCorreta.id;

  /// Se a resposta do usuário está correta.
  bool get acertou => idAlternativaEscolhida == idAlternativaCorreta;
}

/// Uma tentativa de quiz concluída: o conjunto de respostas e os metadados
/// necessários para o histórico (ver requisitos, seções 14 e 15).
class Tentativa {
  final String id;
  final DateTime data;
  final String tema;
  final List<String> subtopicos;
  final List<RespostaQuiz> respostas;

  const Tentativa({
    required this.id,
    required this.data,
    required this.tema,
    required this.subtopicos,
    required this.respostas,
  });

  int get total => respostas.length;

  int get acertos => respostas.where((r) => r.acertou).length;

  int get erros => total - acertos;

  /// Percentual de acerto (0–100). Retorna 0 quando não há respostas.
  double get percentualAcerto {
    if (total == 0) return 0;
    return (acertos / total) * 100;
  }
}
