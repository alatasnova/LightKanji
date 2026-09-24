import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/settings/settings_controller.dart';
import '../../data/kana_catalog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _query = TextEditingController();
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _match(List<String> keys) {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return keys.any((k) => k.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).maybePop();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Настройки'),
            centerTitle: true,
          ),
          body: ListenableBuilder(
            listenable: Listenable.merge([widget.controller, _query]),
            builder: (context, _) {
              final s = widget.controller.settings;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: SearchBar(
                          controller: _query,
                          hintText: 'Поиск по настройкам',
                          leading: const Icon(Icons.search),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 700),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (_match([
                                      'jlpt',
                                      'кандзи',
                                      'уровень',
                                      'n5',
                                      'n1'
                                    ]))
                                      _Category(
                                        title: 'Уровни кандзи',
                                        child: Wrap(
                                          spacing: 8,
                                          children: [
                                            for (final pair in const [
                                              (5, 'N5'),
                                              (4, 'N4'),
                                              (3, 'N3'),
                                              (2, 'N2'),
                                              (1, 'N1'),
                                            ])
                                              FilterChip(
                                                label: Text(pair.$2),
                                                selected: s.jlptLevels
                                                    .contains(pair.$1),
                                                onSelected: (sel) {
                                                  widget.controller.update((x) {
                                                    if (sel) {
                                                      x.jlptLevels.add(pair.$1);
                                                    } else if (x
                                                            .jlptLevels.length >
                                                        1) {
                                                      x.jlptLevels
                                                          .remove(pair.$1);
                                                    }
                                                  });
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    if (_match([
                                      'кана',
                                      'хирагана',
                                      'катакана',
                                      'ряд'
                                    ]))
                                      _Category(
                                        title: 'Кана',
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SwitchListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: const Text('Хирагана'),
                                              value: s.includeHiragana,
                                              onChanged: (v) => widget
                                                  .controller
                                                  .update((x) =>
                                                      x.includeHiragana = v),
                                            ),
                                            SwitchListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: const Text('Катакана'),
                                              value: s.includeKatakana,
                                              onChanged: (v) => widget
                                                  .controller
                                                  .update((x) =>
                                                      x.includeKatakana = v),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                for (final row
                                                    in KanaCatalog.rows)
                                                  FilterChip(
                                                    label: Text(row.title),
                                                    selected: s.kanaRows
                                                        .contains(row.id),
                                                    onSelected: (sel) {
                                                      widget.controller
                                                          .update((x) {
                                                        if (sel) {
                                                          x.kanaRows
                                                              .add(row.id);
                                                        } else if (x.kanaRows
                                                                .length >
                                                            1) {
                                                          x.kanaRows
                                                              .remove(row.id);
                                                        }
                                                      });
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (_match([
                                      'вес',
                                      'вероятност',
                                      'штраф',
                                      'ошибк',
                                      'weighted',
                                    ]))
                                      _Category(
                                        title: 'Взвешенный выбор',
                                        child: Column(
                                          children: [
                                            _SliderTile(
                                              label: 'Штраф за ошибку',
                                              value: s.weighted.penalty,
                                              min: 2,
                                              max: 16,
                                              divisions: 28,
                                              onChanged: (v) =>
                                                  widget.controller.update(
                                                (x) => x.weighted = x.weighted
                                                    .copyWith(penalty: v),
                                              ),
                                            ),
                                            _SliderTile(
                                              label:
                                                  'Затухание после верного ответа',
                                              value: s.weighted.decay,
                                              min: 0.5,
                                              max: 0.95,
                                              divisions: 45,
                                              onChanged: (v) =>
                                                  widget.controller.update(
                                                (x) => x.weighted = x.weighted
                                                    .copyWith(decay: v),
                                              ),
                                            ),
                                            _SliderTile(
                                              label:
                                                  'Множитель подсказки (Enter)',
                                              value:
                                                  s.weighted.revealMultiplier,
                                              min: 1,
                                              max: 5,
                                              divisions: 8,
                                              onChanged: (v) =>
                                                  widget.controller.update(
                                                (x) => x.weighted = x.weighted
                                                    .copyWith(
                                                        revealMultiplier: v),
                                              ),
                                            ),
                                            FilledButton.tonal(
                                              onPressed: () => widget.controller
                                                  .resetWeights(),
                                              child:
                                                  const Text('Сбросить веса'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (_match([
                                      'значение',
                                      'подсказка',
                                      'слово',
                                      'полезность',
                                      'черты',
                                      'частота',
                                    ]))
                                      _Category(
                                        title: 'Тренажёр кандзи',
                                        child: Column(
                                          children: [
                                            SwitchListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: const Text(
                                                  'Показывать значение слова'),
                                              value: s.kanjiShowMeaning,
                                              onChanged: (v) => widget
                                                  .controller
                                                  .update((x) =>
                                                      x.kanjiShowMeaning = v),
                                            ),
                                            _SliderTile(
                                              label: 'Вес количества черт',
                                              value:
                                                  s.kanjiUtility.strokeWeight,
                                              min: 0,
                                              max: 3,
                                              divisions: 12,
                                              onChanged: (v) =>
                                                  widget.controller.update(
                                                (x) => x.kanjiUtility = x
                                                    .kanjiUtility
                                                    .copyWith(strokeWeight: v),
                                              ),
                                            ),
                                            _SliderTile(
                                              label: 'Вес частоты',
                                              value: s
                                                  .kanjiUtility.frequencyWeight,
                                              min: 0,
                                              max: 3,
                                              divisions: 12,
                                              onChanged: (v) =>
                                                  widget.controller.update(
                                                (x) => x.kanjiUtility =
                                                    x.kanjiUtility.copyWith(
                                                        frequencyWeight: v),
                                              ),
                                            ),
                                            _SliderTile(
                                              label: 'Вес знаний',
                                              value: s
                                                  .kanjiUtility.knowledgeWeight,
                                              min: 0,
                                              max: 3,
                                              divisions: 12,
                                              onChanged: (v) =>
                                                  widget.controller.update(
                                                (x) => x.kanjiUtility =
                                                    x.kanjiUtility.copyWith(
                                                        knowledgeWeight: v),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    Text(
                                        [
                                          if (_info != null)
                                            '${_info!.appName} ${_info!.version}+${_info!.buildNumber}',
                                          'Авторы: alatasnova, blinkiew',
                                        ].join(' · '),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withValues(alpha: 0.55),
                                            )),
                                    SizedBox(height: 16),
                                  ],
                                )),
                          )
                        ]),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Category extends StatelessWidget {
  const _Category({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label  ${value.toStringAsFixed(2)}'),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
