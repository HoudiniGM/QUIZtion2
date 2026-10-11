import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/banco.dart';
import 'data/repositorio_questoes.dart';
import 'state/app_state.dart';
import 'ui/router.dart';

void main() {
  final banco = Banco();
  final repositorio = RepositorioQuestoes(banco);
  runApp(QuiztionApp(repositorio: repositorio));
}

class QuiztionApp extends StatelessWidget {
  final RepositorioQuestoes repositorio;

  const QuiztionApp({super.key, required this.repositorio});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(repositorio)..inicializar(),
      child: _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final _router = criarRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QUIZtion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      routerConfig: _router,
    );
  }
}
