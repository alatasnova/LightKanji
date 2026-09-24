import 'package:flutter/material.dart';

import 'core/settings/settings_controller.dart';
import 'dictionary/kanji_database.dart';
import 'ui/app_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsController();
  final database = KanjiDatabase();
  await Future.wait([
    settings.load(),
    database.load(),
  ]);
  runApp(LightKanjiApp(settings: settings, database: database));
}

class LightKanjiApp extends StatelessWidget {
  const LightKanjiApp({
    super.key,
    required this.settings,
    required this.database,
  });

  final SettingsController settings;
  final KanjiDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LightKanji',
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      home: AppShell(settings: settings, database: database),
    );
  }
}
