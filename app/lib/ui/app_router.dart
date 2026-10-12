import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/attempt.dart';
import '../domain/question.dart';
import 'screens/generate_screen.dart';
import 'screens/home_screen.dart';
import 'screens/new_quiz_screen.dart';
import 'screens/question_bank_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/results_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_shell.dart';

/// Application route configuration.
///
/// The five primary destinations live inside a bottom navigation shell
/// (Início, Novo quiz, Gerar, Banco, Configurações). The Quiz and Results
/// screens are pushed on top (full screen, without the navbar).
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    navigatorKey: rootNavigatorKey,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/new-quiz',
                builder: (_, __) => const NewQuizScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/generate',
                builder: (_, __) => const GenerateScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bank',
                builder: (_, __) => const QuestionBankScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/quiz',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) {
          final args = state.extra as Map<String, dynamic>;
          return QuizScreen(
            theme: args['theme'] as String,
            subtopics: (args['subtopics'] as List).cast<String>(),
            questions: (args['questions'] as List).cast<Question>(),
          );
        },
      ),
      GoRoute(
        path: '/results',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) => ResultsScreen(attempt: state.extra as Attempt),
      ),
    ],
  );
}

/// Root navigator key, so full-screen routes (quiz/results) are pushed above
/// the bottom-navigation shell rather than inside a tab.
final rootNavigatorKey = GlobalKey<NavigatorState>();
