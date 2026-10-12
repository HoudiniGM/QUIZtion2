import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quiztion/data/generation_api.dart';
import 'package:quiztion/domain/difficulty.dart';

Map<String, dynamic> sampleSavedQuestion(String id) => {
      'id': id,
      'theme': 'Java Core',
      'subtopic': 'Collections',
      'statement': 'Enunciado $id',
      'codeSnippet': null,
      'difficulty': 'basic',
      'promptVersion': 'v1',
      'options': [
        {'id': 'a', 'text': 'A', 'explanation': 'eA', 'correct': true},
        {'id': 'b', 'text': 'B', 'explanation': 'eB', 'correct': false},
        {'id': 'c', 'text': 'C', 'explanation': 'eC', 'correct': false},
        {'id': 'd', 'text': 'D', 'explanation': 'eD', 'correct': false},
      ],
    };

GenerationApi apiReturning(http.Response Function(http.Request) handler) {
  return GenerationApi(
    baseUrl: 'http://localhost:3000',
    client: MockClient((req) async => handler(req)),
  );
}

void main() {
  group('GenerationApi.generate', () {
    test('parses a successful full generation', () async {
      final api = apiReturning((_) => http.Response(
            jsonEncode({
              'saved': [sampleSavedQuestion('q1'), sampleSavedQuestion('q2')],
              'savedCount': 2,
              'failedCount': 0,
              'requested': 2,
              'promptVersion': 'v1',
            }),
            200,
            headers: {'content-type': 'application/json'},
          ));

      final result = await api.generate(
        theme: 'Java Core',
        subtopic: 'Collections',
        difficulty: Difficulty.basic,
        quantity: 2,
      );

      expect(result.questions, hasLength(2));
      expect(result.savedCount, 2);
      expect(result.failedCount, 0);
      expect(result.isPartial, isFalse);
      final q = result.questions.first;
      expect(q.options, hasLength(4));
      expect(q.options.where((o) => o.correct), hasLength(1));
      expect(q.difficulty, Difficulty.basic);
    });

    test('flags a partial generation', () async {
      final api = apiReturning((_) => http.Response(
            jsonEncode({
              'saved': [sampleSavedQuestion('q1')],
              'savedCount': 1,
              'failedCount': 2,
              'requested': 3,
            }),
            200,
            headers: {'content-type': 'application/json'},
          ));

      final result = await api.generate(
        theme: 'Java Core',
        subtopic: 'Collections',
        difficulty: Difficulty.basic,
        quantity: 3,
      );

      expect(result.isPartial, isTrue);
      expect(result.savedCount, 1);
      expect(result.failedCount, 2);
    });

    test('throws with backend messages on 400', () async {
      final api = apiReturning((_) => http.Response(
            jsonEncode({
              'error': 'validation_error',
              'messages': ['O tema é obrigatório.'],
            }),
            400,
            headers: {'content-type': 'application/json'},
          ));

      expect(
        () => api.generate(
          theme: '',
          subtopic: 'x',
          difficulty: Difficulty.basic,
          quantity: 1,
        ),
        throwsA(isA<GenerationException>()),
      );
    });

    test('throws a friendly message on 5xx', () async {
      final api = apiReturning((_) => http.Response(
            jsonEncode({'error': 'generation_failed'}),
            502,
            headers: {'content-type': 'application/json'},
          ));

      expect(
        () => api.generate(
          theme: 'x',
          subtopic: 'y',
          difficulty: Difficulty.basic,
          quantity: 1,
        ),
        throwsA(isA<GenerationException>()),
      );
    });

    test('throws when the response body is not valid JSON', () async {
      final api = apiReturning((_) => http.Response('<html>oops</html>', 200));

      expect(
        () => api.generate(
          theme: 'x',
          subtopic: 'y',
          difficulty: Difficulty.basic,
          quantity: 1,
        ),
        throwsA(isA<GenerationException>()),
      );
    });
  });
}
