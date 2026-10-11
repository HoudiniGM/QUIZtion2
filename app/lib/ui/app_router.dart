import 'package:go_router/go_router.dart';

import '../domain/attempt.dart';
import '../domain/question.dart';
import 'screens/home_screen.dart';
import 'screens/new_quiz_screen.dart';
import 'screens/question_bank_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/results_screen.dart';

/// Application route configuration.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/bank',
        builder: (_, __) => const QuestionBankScreen(),
      ),
      GoRoute(
        path: '/new-quiz',
        builder: (_, __) => const NewQuizScreen(),
      ),
      GoRoute(
        path: '/quiz',
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
        builder: (_, state) => ResultsScreen(attempt: state.extra as Attempt),
      ),
    ],
  );
}
