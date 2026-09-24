import 'dart:convert';

import 'package:flutter/services.dart';

import '../models.dart';

/// Standalone dataset for [kanji_jlpt_only.json].
///
/// Used for JLPT level, grade, stroke count and raw on/kun lists.
/// Meanings and real word readings must come from JMdict.
class JlptKanjiDataset {
  JlptKanjiDataset();

  static const assetPath = 'assets/dictionaries/kanji_jlpt_only.json';

  final Map<String, JlptKanji> _byCharacter = {};
  final Map<int, List<JlptKanji>> _byLevel = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load({AssetBundle? bundle}) async {
    if (_loaded) return;
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in decoded.entries) {
      final map = entry.value as Map<String, dynamic>;
      final kanji = JlptKanji.fromJson(entry.key, map);
      _byCharacter[kanji.character] = kanji;
      _byLevel.putIfAbsent(kanji.jlpt, () => []).add(kanji);
    }
    _loaded = true;
  }

  JlptKanji? byCharacter(String character) => _byCharacter[character];

  List<JlptKanji> byJlptLevels(Iterable<int> levels) {
    final wanted = levels.toSet();
    final out = <JlptKanji>[];
    for (final level in wanted) {
      out.addAll(_byLevel[level] ?? const []);
    }
    return out;
  }

  List<int> get availableLevels => _byLevel.keys.toList()..sort();
}
