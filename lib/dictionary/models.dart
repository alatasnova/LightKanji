class JlptKanji {
  const JlptKanji({
    required this.character,
    required this.jlpt,
    required this.strokeCount,
    required this.meanings,
    required this.onReadings,
    required this.kunReadings,
    required this.nameReadings,
    this.grade,
    this.heisigEn,
    this.freqMainichiShinbun,
    this.unicode,
  });

  final String character;
  final int jlpt;
  final int strokeCount;
  final List<String> meanings;
  final List<String> onReadings;
  final List<String> kunReadings;
  final List<String> nameReadings;
  final int? grade;
  final String? heisigEn;
  final int? freqMainichiShinbun;
  final String? unicode;

  factory JlptKanji.fromJson(String character, Map<String, dynamic> json) {
    return JlptKanji(
      character: (json['kanji'] as String?) ?? character,
      jlpt: json['jlpt'] as int,
      strokeCount: json['stroke_count'] as int? ?? 0,
      meanings: _stringList(json['meanings']),
      onReadings: _stringList(json['on_readings']),
      kunReadings: _stringList(json['kun_readings']),
      nameReadings: _stringList(json['name_readings']),
      grade: json['grade'] as int?,
      heisigEn: json['heisig_en'] as String?,
      freqMainichiShinbun: json['freq_mainichi_shinbun'] as int?,
      unicode: json['unicode'] as String?,
    );
  }
}

class RealReading {
  const RealReading({
    required this.kana,
    required this.word,
    required this.gloss,
    required this.common,
    this.jlptLevels = const {},
  });

  final String kana;
  final String word;
  final List<String> gloss;
  final bool common;
  final Set<int> jlptLevels;

  factory RealReading.fromJson(Map<String, dynamic> json) {
    return RealReading(
      kana: json['kana'] as String,
      word: json['word'] as String,
      gloss: _stringList(json['gloss']),
      common: json['common'] as bool? ?? false,
    );
  }

  RealReading withJlptLevels(Set<int> levels) {
    return RealReading(
      kana: kana,
      word: word,
      gloss: gloss,
      common: common,
      jlptLevels: levels,
    );
  }
}

class WordPronunciation {
  const WordPronunciation({
    required this.word,
    required this.reading,
    required this.level,
  });

  final String word;
  final String reading;
  final int level;

  String get key => '$word|$reading|$level';

  bool get containsKanji => word.runes.any(
        (rune) =>
            (rune >= 0x3400 && rune <= 0x4dbf) ||
            (rune >= 0x4e00 && rune <= 0x9fff) ||
            (rune >= 0xf900 && rune <= 0xfaff),
      );

  int get kanjiCount => word.runes.where(
        (rune) =>
            (rune >= 0x3400 && rune <= 0x4dbf) ||
            (rune >= 0x4e00 && rune <= 0x9fff) ||
            (rune >= 0xf900 && rune <= 0xfaff),
      ).length;
}

class UsageExample {
  const UsageExample({
    required this.word,
    required this.kana,
    required this.gloss,
    required this.common,
  });

  final String word;
  final String kana;
  final List<String> gloss;
  final bool common;

  factory UsageExample.fromJson(Map<String, dynamic> json) {
    return UsageExample(
      word: json['word'] as String,
      kana: json['kana'] as String,
      gloss: _stringList(json['gloss']),
      common: json['common'] as bool? ?? false,
    );
  }
}

class KanjiEntry {
  const KanjiEntry({
    required this.character,
    this.jlpt,
    this.jlptMeta,
    required this.realReadings,
    required this.examples,
  });

  final String character;
  final int? jlpt;
  final JlptKanji? jlptMeta;
  final List<RealReading> realReadings;
  final List<UsageExample> examples;

  List<String> get acceptedKana =>
      realReadings.map((r) => r.kana).toList(growable: false);
}

class KanjiumEntry {
  const KanjiumEntry({
    required this.character,
    required this.radical,
    required this.strokes,
    required this.idc,
    required this.elements,
    required this.extraElements,
    required this.kanjiParts,
    required this.partOf,
    required this.meaning,
    this.frequency,
    this.jlpt,
    this.grade,
  });

  final String character;
  final String radical;
  final int strokes;
  final String idc;
  final String elements;
  final String? extraElements;
  final List<String> kanjiParts;
  final List<String> partOf;
  final String meaning;
  final int? frequency;
  final String? jlpt;
  final String? grade;

  bool get isComponentKanji => kanjiParts.any(
        (part) => part.runes.any(
          (rune) =>
              (rune >= 0x3400 && rune <= 0x4dbf) ||
              (rune >= 0x4e00 && rune <= 0x9fff) ||
              (rune >= 0xf900 && rune <= 0xfaff),
        ),
      );
}

class KanjiumRadical {
  const KanjiumRadical({
    required this.character,
    required this.variant,
    required this.number,
    required this.strokes,
    required this.names,
    required this.meaning,
    required this.notes,
  });

  final String character;
  final String? variant;
  final int number;
  final int strokes;
  final String names;
  final String meaning;
  final String? notes;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => e.toString()).toList(growable: false);
}
