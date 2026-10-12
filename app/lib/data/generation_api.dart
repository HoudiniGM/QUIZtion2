import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/answer_option.dart';
import '../domain/difficulty.dart';
import '../domain/question.dart';

/// Outcome of a generation request against the backend.
class GenerationResult {
  /// Questions returned by the backend (already validated server-side).
  final List<Question> questions;

  /// How many questions the user requested.
  final int requested;

  /// How many valid questions were produced/saved by the backend.
  final int savedCount;

  /// How many failed validation on the backend.
  final int failedCount;

  const GenerationResult({
    required this.questions,
    required this.requested,
    required this.savedCount,
    required this.failedCount,
  });

  /// True when fewer questions were produced than requested.
  bool get isPartial => savedCount < requested;
}

/// Error raised when generation fails, with a user-facing (pt-BR) message.
class GenerationException implements Exception {
  final String message;
  const GenerationException(this.message);

  @override
  String toString() => message;
}

/// HTTP client for the backend's generation endpoint.
///
/// The base URL is configurable (so the app can point to a local server during
/// development or to the deployed backend). The Gemini key is NEVER handled
/// here — it lives only on the backend.
class GenerationApi {
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  GenerationApi({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  /// Requests the backend to generate questions.
  ///
  /// Throws [GenerationException] with a clear message on any failure
  /// (no connection, backend down, timeout, invalid response, etc.).
  Future<GenerationResult> generate({
    required String theme,
    required String subtopic,
    required Difficulty difficulty,
    required int quantity,
    String material = '',
    List<String> existingSummaries = const [],
  }) async {
    final uri = Uri.parse('${_normalizedBase()}/generate');
    final body = jsonEncode({
      'theme': theme,
      'subtopic': subtopic,
      'difficulty': difficulty.id,
      'quantity': quantity,
      'material': material,
      'existingSummaries': existingSummaries,
    });

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const GenerationException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } catch (_) {
      throw const GenerationException(
        'Não foi possível conectar ao servidor. Verifique sua conexão e o '
        'endereço do backend nas Configurações. Dica: para um backend local, '
        'use "http://" (e não "https://").',
      );
    }

    return _parseResponse(response, theme, subtopic);
  }

  GenerationResult _parseResponse(
    http.Response response,
    String theme,
    String subtopic,
  ) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const GenerationException(
        'O servidor retornou uma resposta inválida.',
      );
    }

    if (response.statusCode == 400) {
      final messages = (json['messages'] as List?)?.cast<String>() ?? const [];
      throw GenerationException(
        messages.isNotEmpty
            ? messages.join('\n')
            : 'Dados inválidos para a geração.',
      );
    }

    if (response.statusCode != 200) {
      final messages = (json['messages'] as List?)?.cast<String>() ?? const [];
      throw GenerationException(
        messages.isNotEmpty
            ? messages.join('\n')
            : 'Não foi possível gerar as questões agora. Tente novamente.',
      );
    }

    final rawList = (json['saved'] as List?) ?? const [];
    final questions = rawList
        .map((e) => _questionFromJson(
              e as Map<String, dynamic>,
              theme: theme,
              subtopic: subtopic,
            ))
        .toList();

    return GenerationResult(
      questions: questions,
      requested: (json['requested'] as num?)?.toInt() ?? questions.length,
      savedCount: (json['savedCount'] as num?)?.toInt() ?? questions.length,
      failedCount: (json['failedCount'] as num?)?.toInt() ?? 0,
    );
  }

  Question _questionFromJson(
    Map<String, dynamic> json, {
    required String theme,
    required String subtopic,
  }) {
    final options = ((json['options'] as List?) ?? const [])
        .map((o) => o as Map<String, dynamic>)
        .map((o) => AnswerOption(
              id: o['id'] as String,
              text: o['text'] as String,
              explanation: o['explanation'] as String,
              correct: o['correct'] == true,
            ))
        .toList();

    final codeSnippet = json['codeSnippet'] as String?;

    return Question(
      id: json['id'] as String,
      theme: (json['theme'] as String?) ?? theme,
      subtopic: (json['subtopic'] as String?) ?? subtopic,
      statement: json['statement'] as String,
      codeSnippet:
          (codeSnippet != null && codeSnippet.trim().isNotEmpty)
              ? codeSnippet
              : null,
      difficulty: Difficulty.fromId(json['difficulty'] as String),
      createdAt: DateTime.now(),
      promptVersion: json['promptVersion'] as String?,
      options: options,
    );
  }

  String _normalizedBase() {
    final b = baseUrl.trim();
    return b.endsWith('/') ? b.substring(0, b.length - 1) : b;
  }

  void close() => _client.close();
}
