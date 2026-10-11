import 'package:flutter/foundation.dart';

import '../data/dados_exemplo.dart';
import '../data/repositorio_questoes.dart';
import '../domain/dificuldade.dart';
import '../domain/questao.dart';

/// Estado global da aplicação (Etapa 1): temas/subtópicos e banco de questões.
///
/// Mantém os dados carregados do SQLite e expõe operações usadas pelas telas.
class AppState extends ChangeNotifier {
  final RepositorioQuestoes _repo;
  final SemeadorDados _semeador;

  AppState(this._repo) : _semeador = SemeadorDados(_repo);

  bool _carregando = true;
  bool get carregando => _carregando;

  List<TemaComSubtopicos> _temas = [];
  List<TemaComSubtopicos> get temas => _temas;

  List<Questao> _questoes = [];
  List<Questao> get questoes => _questoes;

  int get totalQuestoes => _questoes.length;

  /// Inicializa: executa o seed (se necessário) e carrega os dados.
  Future<void> inicializar() async {
    _carregando = true;
    notifyListeners();
    await _semeador.semearSeNecessario();
    await recarregar();
  }

  Future<void> recarregar() async {
    _temas = await _repo.listarTemasComSubtopicos();
    _questoes = await _repo.listarQuestoes();
    _carregando = false;
    notifyListeners();
  }

  /// Questões filtradas (usado pelo Banco de questões).
  List<Questao> filtrar({
    String? tema,
    List<String>? subtopicos,
    Dificuldade? dificuldade,
  }) {
    return _questoes.where((q) {
      if (tema != null && q.tema != tema) return false;
      if (subtopicos != null &&
          subtopicos.isNotEmpty &&
          !subtopicos.contains(q.subtopico)) {
        return false;
      }
      if (dificuldade != null && q.dificuldade != dificuldade) return false;
      return true;
    }).toList();
  }

  Future<void> excluirQuestao(String id) async {
    await _repo.excluirQuestao(id);
    await recarregar();
  }

  /// Subtópicos de um tema (nomes), ou vazio se o tema não existir.
  List<String> subtopicosDoTema(String tema) {
    final t = _temas.where((t) => t.nome == tema);
    if (t.isEmpty) return const [];
    return t.first.subtopicos.map((s) => s.nome).toList();
  }
}
