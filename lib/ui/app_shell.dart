import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings/settings_controller.dart';
import '../dictionary/kanji_database.dart';
import 'settings/settings_page.dart';
import 'dictionary/dictionary_page.dart';
import 'trainers/kana_trainer_page.dart';
import 'trainers/kanji_reading_trainer_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.settings,
    required this.database,
  });

  final SettingsController settings;
  final KanjiDatabase database;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = [
    _Dest('Кана', Icons.spa_outlined, Icons.spa),
    _Dest('Чтение', Icons.translate_outlined, Icons.translate),
    _Dest('Словарь', Icons.menu_book_outlined, Icons.menu_book),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 700;

    final pages = [
      KanaTrainerPage(settings: widget.settings),
      KanjiReadingTrainerPage(
        settings: widget.settings,
        database: widget.database,
      ),
      DictionaryPage(database: widget.database),
    ];

    final body = IndexedStack(index: _index, children: pages);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          final nav = Navigator.of(context);
          if (nav.canPop()) nav.pop();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: (i) => setState(() => _index = i),
                      labelType: width >= 1100
                          ? NavigationRailLabelType.all
                          : NavigationRailLabelType.selected,
                      leading: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        child: Icon(
                          Icons.auto_stories_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      destinations: [
                        for (final d in _destinations)
                          NavigationRailDestination(
                            icon: Icon(d.icon),
                            selectedIcon: Icon(d.selectedIcon),
                            label: Text(d.label),
                          ),
                      ],
                      trailing: Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: IconButton(
                              tooltip: 'Настройки',
                              onPressed: () => _openSettings(context),
                              icon: const Icon(Icons.settings_outlined),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                )
              : body,
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final d in _destinations)
                      NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: d.label,
                      ),
                  ],
                ),
          floatingActionButton: useRail
              ? null
              : FloatingActionButton.small(
                  tooltip: 'Настройки',
                  onPressed: () => _openSettings(context),
                  child: const Icon(Icons.settings_outlined),
                ),
        ),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(controller: widget.settings),
      ),
    );
  }
}

class _Dest {
  const _Dest(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
