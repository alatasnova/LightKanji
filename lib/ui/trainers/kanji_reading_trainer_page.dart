import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/settings/settings_controller.dart';
import '../../dictionary/kanji_database.dart';
import '../../dictionary/kanji_utility.dart';
import '../../dictionary/models.dart';
import 'trainer_scaffold.dart';

class KanjiReadingTrainerPage extends StatefulWidget {
  const KanjiReadingTrainerPage({
    super.key,
    required this.settings,
    required this.database,
  });

  final SettingsController settings;
  final KanjiDatabase database;

  @override
  State<KanjiReadingTrainerPage> createState() =>
      _KanjiReadingTrainerPageState();
}

class _KanjiReadingTrainerPageState extends State<KanjiReadingTrainerPage> {
  WordPronunciation? _current;
  List<WordPronunciation> _pool = const [];
  bool _suppressPoolPick = false;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_rebuildPool);
    _rebuildPool();
  }

  @override
  void dispose() {
    widget.settings.removeListener(_rebuildPool);
    super.dispose();
  }

  void _rebuildPool() {
    _pool = widget.database
        .pronunciationsByLevels(widget.settings.settings.jlptLevels);
    if (!_suppressPoolPick &&
        (_current == null ||
        _pool.every((e) => e.key != _current!.key) ||
        !_eligibleKeys().contains(_current!.key))) {
      _pickNext();
    } else {
      setState(() {});
    }
  }

  void _pickNext() {
    if (_pool.isEmpty) {
      setState(() => _current = null);
      return;
    }
    final scorer = KanjiUtilityScorer(
      params: widget.settings.settings.kanjiUtility,
    );
    final priorities = <String, double>{};
    final utilityScores = <String, double>{};
    for (final pronunciation in _pool) {
      final entries = [
        for (final rune in pronunciation.word.runes)
          if (widget.database.kanjiumByCharacter(String.fromCharCode(rune))
              case final entry?)
            entry,
      ];
      final utility = scorer.scoreSequence(
        entries,
        knownWeights: widget.settings.kanjiKnowledge,
      );
      final familiarity = entries.isEmpty
          ? 1.0
          : pow(
              entries
                  .map(
                    (entry) => kanjiKnowledgeSuppression(
                      widget.settings.kanjiKnowledge[entry.character] ?? 1.0,
                    ),
                  )
                  .fold<double>(1, (product, value) => product * value),
              1.5 / entries.length,
            ).toDouble();
      final selectionUtility = utility * familiarity;
      priorities[pronunciation.key] = selectionUtility;
      utilityScores[pronunciation.key] = selectionUtility;
    }
    final rankedKeys = _pool
        .map((entry) => entry.key)
        .toList()
      ..sort(
        (a, b) => (utilityScores[b] ?? 0).compareTo(utilityScores[a] ?? 0),
      );
    final keepCount = max(
      1,
      (rankedKeys.length *
              widget.settings.settings.kanjiUtilityPercent /
              100)
          .ceil(),
    );
    final eligibleKeys = rankedKeys.take(keepCount).toSet();
    final key = widget.settings.kanjiPicker.pick(
      eligibleKeys.toList(growable: false),
      priorities: priorities,
    );
    setState(() {
      _current = _pool.firstWhere((e) => e.key == key);
    });
  }

  Set<String> _eligibleKeys() {
    if (_pool.isEmpty) return const {};
    final scorer = KanjiUtilityScorer(
      params: widget.settings.settings.kanjiUtility,
    );
    final scores = <String, double>{};
    for (final pronunciation in _pool) {
      final entries = [
        for (final rune in pronunciation.word.runes)
          if (widget.database.kanjiumByCharacter(String.fromCharCode(rune))
              case final entry?)
            entry,
      ];
      final utility = scorer.scoreSequence(
        entries,
        knownWeights: widget.settings.kanjiKnowledge,
      );
      final familiarity = entries.isEmpty
          ? 1.0
          : pow(
              entries
                  .map(
                    (entry) => kanjiKnowledgeSuppression(
                      widget.settings.kanjiKnowledge[entry.character] ?? 1.0,
                    ),
                  )
                  .fold<double>(1, (product, value) => product * value),
              1.5 / entries.length,
            ).toDouble();
      scores[pronunciation.key] = utility * familiarity;
    }
    final ranked = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    final count = max(
      1,
      (ranked.length * widget.settings.settings.kanjiUtilityPercent / 100)
          .ceil(),
    );
    return ranked.take(count).toSet();
  }

  Future<void> _correct() async {
    final cur = _current;
    if (cur == null) return;
    widget.settings.kanjiPicker.recordCorrect(cur.key);
    _suppressPoolPick = true;
    try {
      await widget.settings.recordKanjiKnowledge(
        _kanjiCharacters(cur.word),
        correct: true,
      );
    } finally {
      _suppressPoolPick = false;
    }
    await widget.settings.persistKanjiWeights();
    if (widget.settings.settings.kanjiImmediateAdvance) {
      _pickNext();
    }
  }

  Future<void> _error({required bool reveal}) async {
    final cur = _current;
    if (cur == null) return;
    widget.settings.kanjiPicker.recordError(
      cur.key,
      multiplier: reveal
          ? widget.settings.settings.weighted.revealMultiplier
          : 1,
    );
    _suppressPoolPick = true;
    try {
      await widget.settings.recordKanjiKnowledge(
        _kanjiCharacters(cur.word),
        correct: false,
        multiplier: reveal
            ? widget.settings.settings.weighted.revealMultiplier
            : 1,
      );
    } finally {
      _suppressPoolPick = false;
    }
    await widget.settings.persistKanjiWeights();
  }

  Iterable<String> _kanjiCharacters(String word) sync* {
    for (final rune in word.runes) {
      final character = String.fromCharCode(rune);
      if (widget.database.kanjiumByCharacter(character) != null) {
        yield character;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = _current;
    final accepted = cur == null
        ? const <String>[]
        : _pool
            .where((entry) =>
                entry.word == cur.word && entry.level == cur.level)
            .map((entry) => entry.reading)
            .toSet()
            .toList(growable: false);
    final meaning = cur == null || !widget.settings.settings.kanjiShowMeaning
        ? null
        : widget.database.meaningFor(cur).join('; ');
    return TrainerScaffold(
      prompt: cur?.word,
      accepted: accepted,
      subtitle: meaning == null || meaning.isEmpty ? null : meaning,
      emptyMessage:
          'Нет слов с реальными чтениями для выбранных уровней JLPT.',
      onCorrect: _correct,
      onError: () => _error(reveal: false),
      onReveal: () => _error(reveal: true),
      settingsBuilder: (_) => _KanjiSheet(settings: widget.settings),
    );
  }
}

class _KanjiSheet extends StatelessWidget {
  const _KanjiSheet({required this.settings});

  final SettingsController settings;

  static const levels = [
    (5, 'N5'),
    (4, 'N4'),
    (3, 'N3'),
    (2, 'N2'),
    (1, 'N1'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final s = settings.settings;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Чтение кандзи',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Введите реальное чтение из словаря (не абстрактные он/кун).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final level in levels)
                  FilterChip(
                    label: Text(level.$2),
                    selected: s.jlptLevels.contains(level.$1),
                    onSelected: (sel) {
                      settings.update((x) {
                        if (sel) {
                          x.jlptLevels.add(level.$1);
                        } else if (x.jlptLevels.length > 1) {
                          x.jlptLevels.remove(level.$1);
                        }
                      });
                    },
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Сразу следующее после верного ответа'),
              value: s.kanjiImmediateAdvance,
              onChanged: (v) =>
                  settings.update((x) => x.kanjiImmediateAdvance = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Диапазон полезности: ${s.kanjiUtilityPercent.round()}%',
              ),
              subtitle: Slider(
                value: s.kanjiUtilityPercent,
                min: 1,
                max: 100,
                divisions: 99,
                onChanged: (v) => settings.update(
                  (x) => x.kanjiUtilityPercent = v.roundToDouble(),
                ),
              ),
            ),
            Text(
              'Изучать верхние ${s.kanjiUtilityPercent.round()}% слов '
              'по текущей полезности.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Показывать значение слова'),
              value: s.kanjiShowMeaning,
              onChanged: (v) =>
                  settings.update((x) => x.kanjiShowMeaning = v),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
