import 'dart:convert';

import 'package:flutter/services.dart';

import '../models.dart';

/// JLPT vocabulary dataset containing whole words and their actual readings.
class PronounceVocabDataset {
  static const assetPath = 'assets/dictionaries/pronounce_vocab.json';

  final List<WordPronunciation> _entries = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load({AssetBundle? bundle}) async {
    if (_loaded) return;
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in decoded.entries) {
      final values = entry.value as List? ?? const [];
      for (final value in values) {
        final map = value as Map<String, dynamic>;
        final reading = map['reading'] as String?;
        final level = (map['level'] as num?)?.toInt();
        if (reading == null || reading.isEmpty || level == null) continue;
        _entries.add(
          WordPronunciation(
            word: entry.key,
            reading: reading,
            level: level,
          ),
        );
      }
    }
    _loaded = true;
  }

  List<WordPronunciation> byLevels(Iterable<int> levels) {
    final wanted = levels.toSet();
    return _entries
        .where(
          (entry) =>
              wanted.contains(entry.level) && entry.containsKanji,
        )
        .toList(growable: false);
  }

  Set<int> levelsFor(String word, String reading) {
    return _entries
        .where((entry) => entry.word == word && entry.reading == reading)
        .map((entry) => entry.level)
        .toSet();
  }
}
