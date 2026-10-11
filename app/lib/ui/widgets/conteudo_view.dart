import 'package:flutter/material.dart';

import '../../domain/tipo_conteudo.dart';

/// Renderiza um conteúdo (enunciado, alternativa ou explicação) respeitando o
/// tipo: texto comum ou bloco de código.
///
/// Para código (requisitos, seção 10):
/// - usa fonte monoespaçada;
/// - preserva espaços, quebras de linha e indentação;
/// - não executa o código e não o interpreta como instrução.
class ConteudoView extends StatelessWidget {
  final String texto;
  final TipoConteudo tipo;
  final TextStyle? estiloTexto;

  const ConteudoView({
    super.key,
    required this.texto,
    this.tipo = TipoConteudo.texto,
    this.estiloTexto,
  });

  @override
  Widget build(BuildContext context) {
    if (tipo == TipoConteudo.codigo) {
      return _BlocoCodigo(codigo: texto);
    }
    return Text(texto, style: estiloTexto);
  }
}

class _BlocoCodigo extends StatelessWidget {
  final String codigo;

  const _BlocoCodigo({required this.codigo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          codigo,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: ['Courier New', 'monospace'],
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
