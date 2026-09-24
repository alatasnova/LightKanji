import 'package:flutter/material.dart';

import '../../core/settings/settings_controller.dart';
import '../../data/kana_catalog.dart';
import 'trainer_scaffold.dart';

class KanaTrainerPage extends StatefulWidget {
  const KanaTrainerPage({super.key, required this.settings});

  final SettingsController settings;

  @override
  State<KanaTrainerPage> createState() => _KanaTrainerPageState();
}

class _KanaTrainerPageState extends State<KanaTrainerPage> {
  KanaGlyph? _current;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettings);
    _pickNext();
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettings);
    super.dispose();
  }

  void _onSettings() {
    final pool = widget.settings.enabledKana();
    if (_current == null ||
        pool.every((g) => g.character != _current!.character)) {
      _pickNext();
    } else {
      setState(() {});
    }
  }

  void _pickNext() {
    final pool = widget.settings.enabledKana();
    if (pool.isEmpty) {
      setState(() => _current = null);
      return;
    }
    final key = widget.settings.kanaPicker.pick(
      pool.map((g) => g.character).toList(),
    );
    setState(() {
      _current = pool.firstWhere((g) => g.character == key);
    });
  }

  Future<void> _correct() async {
    final cur = _current;
    if (cur == null) return;
    widget.settings.kanaPicker.recordCorrect(cur.character);
    await widget.settings.persistKanaWeights();
    if (widget.settings.settings.kanaImmediateAdvance) {
      _pickNext();
    }
  }

  Future<void> _error({required bool reveal}) async {
    final cur = _current;
    if (cur == null) return;
    widget.settings.kanaPicker.recordError(
      cur.character,
      multiplier: reveal
          ? widget.settings.settings.weighted.revealMultiplier
          : 1,
    );
    await widget.settings.persistKanaWeights();
  }

  @override
  Widget build(BuildContext context) {
    final cur = _current;
    return TrainerScaffold(
      prompt: cur?.character,
      accepted: cur == null ? const [] : [cur.character],
      emptyMessage:
          'Выберите ряды каны и хирагану или катакану в настройках.',
      onCorrect: _correct,
      onError: () => _error(reveal: false),
      onReveal: () => _error(reveal: true),
      settingsBuilder: (ctx) => _KanaSheet(settings: widget.settings),
    );
  }
}

class _KanaSheet extends StatelessWidget {
  const _KanaSheet({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final s = settings.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Тренажёр каны', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Хирагана'),
              value: s.includeHiragana,
              onChanged: (v) => settings.update((x) => x.includeHiragana = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Катакана'),
              value: s.includeKatakana,
              onChanged: (v) => settings.update((x) => x.includeKatakana = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Сразу следующее после верного ответа'),
              value: s.kanaImmediateAdvance,
              onChanged: (v) =>
                  settings.update((x) => x.kanaImmediateAdvance = v),
            ),
            const SizedBox(height: 8),
            Text('Ряды', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final row in KanaCatalog.rows)
                  FilterChip(
                    label: Text(row.title),
                    selected: s.kanaRows.contains(row.id),
                    onSelected: (sel) {
                      settings.update((x) {
                        if (sel) {
                          x.kanaRows.add(row.id);
                        } else if (x.kanaRows.length > 1) {
                          x.kanaRows.remove(row.id);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
