import 'package:flutter/foundation.dart';

import '../data/generation_api.dart';
import '../domain/difficulty.dart';
import 'app_state.dart';

/// UI status of a generation request (requirements, sections 4.2 and 16).
enum GenerationStatus { idle, loading, success, partial, error }

/// Drives the "Gerar questões" screen: calls the backend, saves the valid
/// questions through [AppState], and exposes loading / success / partial /
/// error states. Prevents concurrent submissions.
class GenerationController extends ChangeNotifier {
  final AppState _appState;
  final GenerationApi Function(String baseUrl) _apiFactory;

  GenerationController(
    this._appState, {
    GenerationApi Function(String baseUrl)? apiFactory,
  }) : _apiFactory =
            apiFactory ?? ((baseUrl) => GenerationApi(baseUrl: baseUrl));

  GenerationStatus _status = GenerationStatus.idle;
  GenerationStatus get status => _status;

  bool get isLoading => _status == GenerationStatus.loading;

  String? _message;
  String? get message => _message;

  int _savedCount = 0;
  int get savedCount => _savedCount;

  int _failedCount = 0;
  int get failedCount => _failedCount;

  int _requested = 0;
  int get requested => _requested;

  /// Starts a generation. Ignored if one is already in progress (prevents
  /// accidental double submits).
  Future<void> generate({
    required String theme,
    required String subtopic,
    required Difficulty difficulty,
    required int quantity,
    String material = '',
  }) async {
    if (_status == GenerationStatus.loading) return;

    final baseUrl = _appState.settings.backendUrl;
    if (baseUrl.isEmpty) {
      _status = GenerationStatus.error;
      _message =
          'Configure o endereço do backend nas Configurações antes de gerar '
          'questões.';
      notifyListeners();
      return;
    }

    _status = GenerationStatus.loading;
    _message = null;
    _requested = quantity;
    notifyListeners();

    final api = _apiFactory(baseUrl);
    try {
      final result = await api.generate(
        theme: theme,
        subtopic: subtopic,
        difficulty: difficulty,
        quantity: quantity,
        material: material,
        existingSummaries: _appState.existingSummaries(
          theme: theme,
          subtopic: subtopic,
        ),
      );

      if (result.questions.isNotEmpty) {
        await _appState.saveGeneratedQuestions(result.questions);
      }

      _savedCount = result.savedCount;
      _failedCount = result.failedCount;
      _requested = result.requested;

      if (result.questions.isEmpty) {
        _status = GenerationStatus.error;
        _message =
            'Nenhuma questão válida foi gerada. Tente novamente ou ajuste os '
            'parâmetros.';
      } else if (result.isPartial) {
        _status = GenerationStatus.partial;
        _message =
            'Foram salvas ${result.savedCount} de ${result.requested} '
            'questões solicitadas.';
      } else {
        _status = GenerationStatus.success;
        _message = '${result.savedCount} questão(ões) gerada(s) e salva(s).';
      }
    } on GenerationException catch (e) {
      _status = GenerationStatus.error;
      _message = e.message;
    } catch (_) {
      _status = GenerationStatus.error;
      _message = 'Ocorreu um erro inesperado ao gerar as questões.';
    } finally {
      api.close();
      notifyListeners();
    }
  }

  void reset() {
    _status = GenerationStatus.idle;
    _message = null;
    _savedCount = 0;
    _failedCount = 0;
    _requested = 0;
    notifyListeners();
  }
}
