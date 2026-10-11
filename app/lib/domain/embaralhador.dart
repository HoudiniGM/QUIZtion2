import 'dart:math';

import 'alternativa.dart';
import 'questao.dart';

/// Embaralha questões e alternativas preservando a associação entre
/// alternativa, resposta correta e explicação (ver requisitos, seções 5 e 15).
///
/// O embaralhamento opera sobre as próprias [Alternativa], que carregam o
/// identificador, o texto, a explicação e a flag `correta` juntos. Como a
/// unidade movida é a alternativa inteira, a associação é preservada por
/// construção: nenhuma dessas partes é reatribuída de forma independente.
class Embaralhador {
  final Random _random;

  /// Permite injetar um [Random] com semente fixa para testes determinísticos.
  Embaralhador([Random? random]) : _random = random ?? Random();

  /// Retorna uma nova lista com as questões em ordem aleatória.
  /// Não modifica a lista original.
  List<Questao> embaralharQuestoes(List<Questao> questoes) {
    final copia = List<Questao>.of(questoes);
    copia.shuffle(_random);
    return copia;
  }

  /// Retorna uma nova lista de alternativas em ordem aleatória.
  /// Cada alternativa é mantida intacta (id, texto, explicação, correta).
  List<Alternativa> embaralharAlternativas(List<Alternativa> alternativas) {
    final copia = List<Alternativa>.of(alternativas);
    copia.shuffle(_random);
    return copia;
  }

  /// Retorna uma cópia da questão com as alternativas embaralhadas.
  Questao embaralharQuestao(Questao questao) {
    return questao.copyWith(
      alternativas: embaralharAlternativas(questao.alternativas),
    );
  }

  /// Prepara um quiz completo: embaralha a ordem das questões e, dentro de
  /// cada questão, a ordem das alternativas.
  List<Questao> prepararQuiz(List<Questao> questoes) {
    return embaralharQuestoes(questoes)
        .map((q) => embaralharQuestao(q))
        .toList();
  }
}
