import 'package:flutter/foundation.dart';

import '../domain/motor_quiz.dart';
import '../domain/questao.dart';
import '../domain/tentativa.dart';

/// Controla uma sessão de quiz para a UI, encapsulando o [MotorQuiz] e
/// notificando mudanças de estado.
class QuizController extends ChangeNotifier {
  final MotorQuiz _motor;

  QuizController({
    required String tema,
    required List<String> subtopicos,
    required List<Questao> questoesEmbaralhadas,
  }) : _motor = MotorQuiz(
          tema: tema,
          subtopicos: subtopicos,
          questoes: questoesEmbaralhadas,
        );

  int get indiceAtual => _motor.indiceAtual;
  int get total => _motor.total;
  EstadoQuestao get atual => _motor.atual;
  bool get ehUltima => _motor.ehUltima;
  bool get podeFinalizar => _motor.podeFinalizar;

  bool get temSelecao => atual.idSelecionado != null;
  bool get respondida => atual.respondida;

  void selecionar(String idAlternativa) {
    _motor.selecionar(idAlternativa);
    notifyListeners();
  }

  bool responder() {
    final ok = _motor.responder();
    if (ok) notifyListeners();
    return ok;
  }

  bool proxima() {
    final ok = _motor.proxima();
    if (ok) notifyListeners();
    return ok;
  }

  Tentativa finalizar() {
    return _motor.finalizar(
      id: 'tentativa-${DateTime.now().microsecondsSinceEpoch}',
      data: DateTime.now(),
    );
  }
}
