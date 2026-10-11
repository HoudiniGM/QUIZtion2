import 'questao.dart';

/// Resultado da tentativa de montar um quiz a partir de filtros.
///
/// Trata explicitamente o caso de quantidade insuficiente de questões
/// (ver requisitos, seção 14): o app não deve iniciar silenciosamente um quiz
/// com uma quantidade diferente da solicitada.
class SelecaoQuiz {
  /// Questões disponíveis que atendem aos filtros (tema/subtópicos).
  final List<Questao> disponiveis;

  /// Quantidade de questões solicitada pelo usuário.
  final int solicitadas;

  const SelecaoQuiz({
    required this.disponiveis,
    required this.solicitadas,
  });

  int get quantidadeDisponivel => disponiveis.length;

  bool get temAlguma => disponiveis.isNotEmpty;

  /// Há menos questões disponíveis do que o solicitado.
  bool get insuficiente => quantidadeDisponivel < solicitadas;

  /// Quantidade efetiva que seria usada (nunca maior que o disponível).
  int get quantidadeEfetiva =>
      quantidadeDisponivel < solicitadas ? quantidadeDisponivel : solicitadas;

  /// Mensagem informativa quando a quantidade é insuficiente.
  String? get mensagemInsuficiencia {
    if (!insuficiente) return null;
    if (quantidadeDisponivel == 0) {
      return 'Não há questões disponíveis para os filtros selecionados.';
    }
    return 'Há apenas $quantidadeDisponivel questão(ões) disponível(is), '
        'mas você solicitou $solicitadas.';
  }
}
