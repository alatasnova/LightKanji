import 'dart:convert';

import 'package:flutter/services.dart';

import '../models.dart';

/// Standalone JMdict dataset.
///
/// Runtime file is a compact per-kanji index compiled from `jmdict.json`
/// / jmdict-simplified `words` (same entry schema: kanji/kana/sense).
/// Real pronunciations, glosses and usage examples come from here.
class JmdictDataset {
  JmdictDataset();

  static const indexAssetPath = 'assets/dictionaries/jmdict_kanji_index.json';
  static const metaAssetPath = 'assets/dictionaries/jmdict_meta.json';

  final Map<String, _JmdictKanjiRecord> _byCharacter = {};
  Map<String, dynamic> meta = const {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load({AssetBundle? bundle}) async {
    if (_loaded) return;
    final b = bundle ?? rootBundle;
    final raw = await b.loadString(indexAssetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in decoded.entries) {
      final map = entry.value as Map<String, dynamic>;
      final readings = [
        for (final item in (map['readings'] as List? ?? const []))
          RealReading.fromJson(item as Map<String, dynamic>),
      ];
      final examples = [
        for (final item in (map['examples'] as List? ?? const []))
          UsageExample.fromJson(item as Map<String, dynamic>),
      ];
      _byCharacter[entry.key] = _JmdictKanjiRecord(
        readings: readings,
        examples: examples,
      );
    }
    try {
      meta = jsonDecode(await b.loadString(metaAssetPath)) as Map<String, dynamic>;
    } catch (_) {
      meta = const {};
    }
    _loaded = true;
  }

  List<RealReading> readingsFor(String character) =>
      _byCharacter[character]?.readings ?? const [];

  List<UsageExample> examplesFor(String character) =>
      _byCharacter[character]?.examples ?? const [];

  List<String> glossesForWord(String word, String kana) {
    final glosses = <String>{};
    for (final record in _byCharacter.values) {
      for (final reading in record.readings) {
        if (reading.word == word && reading.kana == kana) {
          glosses.addAll(reading.gloss);
        }
      }
      for (final example in record.examples) {
        if (example.word == word && example.kana == kana) {
          glosses.addAll(example.gloss);
        }
      }
    }
    return glosses.toList(growable: false);
  }

  bool isCommonReading(String word, String kana) {
    return _byCharacter.values.any(
      (record) => record.readings.any(
        (reading) =>
            reading.word == word &&
            reading.kana == kana &&
            reading.common,
      ),
    );
  }

  List<String> searchByReading(String kanaOrFragment) {
    final q = kanaOrFragment.trim();
    if (q.isEmpty) return const [];
    final hits = <String>[];
    for (final entry in _byCharacter.entries) {
      final match = entry.value.readings.any((r) => r.kana.contains(q));
      if (match) hits.add(entry.key);
    }
    return hits;
  }
}

class _JmdictKanjiRecord {
  const _JmdictKanjiRecord({
    required this.readings,
    required this.examples,
  });

  final List<RealReading> readings;
  final List<UsageExample> examples;
}
