import 'package:flutter/material.dart';

/// A small, curated library of icons for themes. Icons are from Material
/// (bundled with Flutter, no assets to download). Each entry has a stable
/// [id] (persisted in the database) and a pt-BR [label] for the picker.
class ThemeIconOption {
  final String id;
  final IconData icon;
  final String label;

  const ThemeIconOption(this.id, this.icon, this.label);
}

abstract class ThemeIcons {
  /// Default icon when a theme has none set.
  static const IconData fallback = Icons.category_outlined;

  static const List<ThemeIconOption> all = [
    ThemeIconOption('code', Icons.code, 'Programação'),
    ThemeIconOption('terminal', Icons.terminal, 'Terminal'),
    ThemeIconOption('database', Icons.storage, 'Banco de dados'),
    ThemeIconOption('web', Icons.public, 'Web'),
    ThemeIconOption('devices', Icons.devices, 'Dispositivos'),
    ThemeIconOption('security', Icons.security, 'Segurança'),
    ThemeIconOption('cloud', Icons.cloud, 'Nuvem'),
    ThemeIconOption('math', Icons.functions, 'Matemática'),
    ThemeIconOption('calculate', Icons.calculate, 'Cálculo'),
    ThemeIconOption('physics', Icons.science, 'Ciências'),
    ThemeIconOption('biology', Icons.biotech, 'Biologia'),
    ThemeIconOption('chemistry', Icons.bubble_chart, 'Química'),
    ThemeIconOption('history', Icons.account_balance, 'História'),
    ThemeIconOption('geography', Icons.travel_explore, 'Geografia'),
    ThemeIconOption('language', Icons.translate, 'Idiomas'),
    ThemeIconOption('literature', Icons.menu_book, 'Literatura'),
    ThemeIconOption('art', Icons.palette, 'Artes'),
    ThemeIconOption('music', Icons.music_note, 'Música'),
    ThemeIconOption('health', Icons.favorite, 'Saúde'),
    ThemeIconOption('economy', Icons.attach_money, 'Economia'),
    ThemeIconOption('law', Icons.gavel, 'Direito'),
    ThemeIconOption('engineering', Icons.engineering, 'Engenharia'),
    ThemeIconOption('sports', Icons.sports_soccer, 'Esportes'),
    ThemeIconOption('general', Icons.lightbulb, 'Geral'),
  ];

  /// Returns the IconData for a stored id, or the fallback.
  static IconData byId(String? id) {
    if (id == null) return fallback;
    for (final o in all) {
      if (o.id == id) return o.icon;
    }
    return fallback;
  }
}
