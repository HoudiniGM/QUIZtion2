import 'package:go_router/go_router.dart';

import '../domain/questao.dart';
import '../domain/tentativa.dart';
import 'telas/banco_tela.dart';
import 'telas/inicio_tela.dart';
import 'telas/novo_quiz_tela.dart';
import 'telas/quiz_tela.dart';
import 'telas/resultados_tela.dart';

/// Configuração de rotas do aplicativo.
GoRouter criarRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const InicioTela(),
      ),
      GoRoute(
        path: '/banco',
        builder: (_, __) => const BancoTela(),
      ),
      GoRoute(
        path: '/novo-quiz',
        builder: (_, __) => const NovoQuizTela(),
      ),
      GoRoute(
        path: '/quiz',
        builder: (_, state) {
          final args = state.extra as Map<String, dynamic>;
          return QuizTela(
            tema: args['tema'] as String,
            subtopicos: (args['subtopicos'] as List).cast<String>(),
            questoes: (args['questoes'] as List).cast<Questao>(),
          );
        },
      ),
      GoRoute(
        path: '/resultados',
        builder: (_, state) =>
            ResultadosTela(tentativa: state.extra as Tentativa),
      ),
    ],
  );
}
