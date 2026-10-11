import 'questao.dart';
import 'tentativa.dart';

/// Estado de uma única questão dentro de uma sessão de quiz.
class EstadoQuestao {
  final Questao questao;

  /// Id da alternativa selecionada (ainda não confirmada), ou null.
  final String? idSelecionado;

  /// Id da alternativa confirmada (definitiva), ou null se ainda não respondida.
  final String? idConfirmado;

  const EstadoQuestao({
    required this.questao,
    this.idSelecionado,
    this.idConfirmado,
  });

  bool get respondida => idConfirmado != null;

  bool get acertou =>
      respondida && idConfirmado == questao.alternativaCorreta.id;

  EstadoQuestao copyWith({
    String? idSelecionado,
    String? idConfirmado,
    bool limparSelecao = false,
  }) {
    return EstadoQuestao(
      questao: questao,
      idSelecionado:
          limparSelecao ? null : (idSelecionado ?? this.idSelecionado),
      idConfirmado: idConfirmado ?? this.idConfirmado,
    );
  }
}

/// Motor de uma sessão de quiz.
///
/// Regras (ver requisitos, seção 14):
/// - uma questão por vez;
/// - seleção de uma alternativa antes de "Responder";
/// - a confirmação ("Responder") é definitiva e não pode ser alterada;
/// - avanço para a próxima questão; "Finalizar" na última.
///
/// As questões recebidas já devem vir embaralhadas (questões e alternativas).
class MotorQuiz {
  final String tema;
  final List<String> subtopicos;
  final List<EstadoQuestao> _estados;
  int _indiceAtual = 0;

  MotorQuiz({
    required this.tema,
    required this.subtopicos,
    required List<Questao> questoes,
  })  : assert(questoes.isNotEmpty, 'O quiz precisa de ao menos uma questão.'),
        _estados =
            questoes.map((q) => EstadoQuestao(questao: q)).toList();

  int get indiceAtual => _indiceAtual;
  int get total => _estados.length;
  EstadoQuestao get atual => _estados[_indiceAtual];
  bool get ehUltima => _indiceAtual == total - 1;
  bool get ehPrimeira => _indiceAtual == 0;

  /// Seleciona (sem confirmar) uma alternativa na questão atual.
  /// Ignorado se a questão já foi respondida (confirmação é definitiva).
  void selecionar(String idAlternativa) {
    if (atual.respondida) return;
    _estados[_indiceAtual] =
        atual.copyWith(idSelecionado: idAlternativa);
  }

  /// Confirma ("Responder") a alternativa selecionada na questão atual.
  ///
  /// Retorna `true` se a confirmação ocorreu. Retorna `false` se não havia
  /// seleção ou se a questão já estava respondida. A confirmação é definitiva.
  bool responder() {
    if (atual.respondida) return false;
    final sel = atual.idSelecionado;
    if (sel == null) return false;
    _estados[_indiceAtual] = atual.copyWith(idConfirmado: sel);
    return true;
  }

  /// Avança para a próxima questão. Só é permitido após responder a atual.
  /// Retorna `true` se avançou.
  bool proxima() {
    if (!atual.respondida) return false;
    if (ehUltima) return false;
    _indiceAtual++;
    return true;
  }

  /// Indica se o quiz pode ser finalizado (todas as questões respondidas).
  bool get podeFinalizar => _estados.every((e) => e.respondida);

  /// Constrói a [Tentativa] com o resultado do quiz.
  ///
  /// Lança [StateError] se nem todas as questões foram respondidas.
  Tentativa finalizar({
    required String id,
    required DateTime data,
  }) {
    if (!podeFinalizar) {
      throw StateError(
        'Não é possível finalizar: há questões não respondidas.',
      );
    }
    final respostas = _estados
        .map((e) => RespostaQuiz(
              questao: e.questao,
              idAlternativaEscolhida: e.idConfirmado!,
            ))
        .toList();
    return Tentativa(
      id: id,
      data: data,
      tema: tema,
      subtopicos: subtopicos,
      respostas: respostas,
    );
  }
}
