import 'package:flutter/services.dart';

import 'datasets/jlpt_dataset.dart';
import 'datasets/jmdict_dataset.dart';
import 'datasets/kanjium_dataset.dart';
import 'datasets/pronounce_vocab_dataset.dart';
import 'models.dart';

/// Unified dictionary facade consumed by trainers and search.
class KanjiDatabase {
  KanjiDatabase({
    JlptKanjiDataset? jlpt,
    JmdictDataset? jmdict,
    PronounceVocabDataset? pronounceVocab,
    KanjiumDataset? kanjium,
  })  : jlpt = jlpt ?? JlptKanjiDataset(),
        jmdict = jmdict ?? JmdictDataset(),
        pronounceVocab = pronounceVocab ?? PronounceVocabDataset(),
        kanjium = kanjium ?? KanjiumDataset();

  final JlptKanjiDataset jlpt;
  final JmdictDataset jmdict;
  final PronounceVocabDataset pronounceVocab;
  final KanjiumDataset kanjium;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load({AssetBundle? bundle}) async {
    if (_loaded) return;
    await Future.wait([
      jlpt.load(bundle: bundle),
      jmdict.load(bundle: bundle),
      pronounceVocab.load(bundle: bundle),
      kanjium.load(bundle: bundle),
    ]);
    _loaded = true;
  }

  /// Kanji metadata in the given JLPT levels (N5=5 … N1=1).
  List<KanjiEntry> byJlptLevels(Iterable<int> levels) {
    final out = <KanjiEntry>[];
    for (final meta in jlpt.byJlptLevels(levels)) {
      final readings = _readingsWithLevels(meta.character);
      if (readings.isEmpty) continue;
      out.add(
        KanjiEntry(
          character: meta.character,
          jlpt: meta.jlpt,
          jlptMeta: meta,
          realReadings: readings,
          examples: jmdict.examplesFor(meta.character),
        ),
      );
    }
    return out;
  }

  List<WordPronunciation> pronunciationsByLevels(Iterable<int> levels) {
    return pronounceVocab.byLevels(levels).where(_isSuitableForTrainer).toList(
          growable: false,
        );
  }

  KanjiumEntry? kanjiumByCharacter(String character) =>
      kanjium.byCharacter(character);

  List<KanjiumRadical> radicalsFor(String character) =>
      kanjium.radicalsFor(character);

  List<KanjiumEntry> lookalikesFor(String character) =>
      kanjium.lookalikesFor(character);

  List<String> meaningFor(WordPronunciation pronunciation) {
    return jmdict.glossesForWord(
      pronunciation.word,
      pronunciation.reading,
    );
  }

  bool _isSuitableForTrainer(WordPronunciation pronunciation) {
    final maxKanji = switch (pronunciation.level) {
      5 => 2,
      4 => 3,
      3 => 4,
      _ => null,
    };
    if (maxKanji != null && pronunciation.kanjiCount > maxKanji) {
      return false;
    }
    if ((pronunciation.level == 5 || pronunciation.level == 4) &&
        !jmdict.isCommonReading(
          pronunciation.word,
          pronunciation.reading,
        )) {
      return false;
    }
    return true;
  }

  /// Searches the unified dictionary by character, word, reading or gloss.
  ///
  /// An empty query returns all entries from [jlptLevels]. This keeps the
  /// method useful for both a dictionary screen and autocomplete fields.
  List<KanjiEntry> search({
    String query = '',
    Iterable<int>? jlptLevels,
  }) {
    final entries = byJlptLevels(jlptLevels ?? jlpt.availableLevels);
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return entries;

    return entries.where((entry) {
      if (entry.character.toLowerCase().contains(normalized)) return true;
      return entry.realReadings.any(
        (reading) =>
            reading.kana.toLowerCase().contains(normalized) ||
            reading.word.toLowerCase().contains(normalized) ||
            reading.gloss.any(
              (gloss) => gloss.toLowerCase().contains(normalized),
            ),
      ) ||
          entry.examples.any(
            (example) =>
                example.word.toLowerCase().contains(normalized) ||
                example.kana.toLowerCase().contains(normalized) ||
                example.gloss.any(
                  (gloss) => gloss.toLowerCase().contains(normalized),
                ),
          );
    }).toList(growable: false);
  }

  KanjiEntry? byCharacter(String character) {
    final readings = _readingsWithLevels(character);
    final meta = jlpt.byCharacter(character);
    if (readings.isEmpty && meta == null) return null;
    return KanjiEntry(
      character: character,
      jlpt: meta?.jlpt,
      jlptMeta: meta,
      realReadings: readings,
      examples: jmdict.examplesFor(character),
    );
  }

  List<KanjiEntry> searchByReading(String query) {
    return [
      for (final ch in jmdict.searchByReading(query))
        if (byCharacter(ch) != null) byCharacter(ch)!,
    ];
  }

  List<RealReading> _readingsWithLevels(String character) {
    return [
      for (final reading in jmdict.readingsFor(character))
        reading.withJlptLevels(
          pronounceVocab.levelsFor(reading.word, reading.kana),
        ),
    ];
  }
}
