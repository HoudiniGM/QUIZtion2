import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_database.dart';
import 'data/question_repository.dart';
import 'data/settings_repository.dart';
import 'state/app_state.dart';
import 'ui/app_router.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final repository = QuestionRepository(database);
  final settings = await SettingsRepository.create();
  runApp(QuiztionApp(repository: repository, settings: settings));
}

class QuiztionApp extends StatelessWidget {
  final QuestionRepository repository;
  final SettingsRepository settings;

  const QuiztionApp({
    super.key,
    required this.repository,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(repository, settings)..initialize(),
      child: _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QUIZtion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
