import 'package:flutter_test/flutter_test.dart';
import 'package:light_kanji/dictionary/kanji_utility.dart';
import 'package:light_kanji/dictionary/models.dart';

KanjiumEntry entry(
  String character, {
  required int strokes,
  int? frequency,
  List<String> kanjiParts = const [],
}) {
  return KanjiumEntry(
    character: character,
    radical: '',
    strokes: strokes,
    idc: '',
    elements: '',
    extraElements: null,
    kanjiParts: kanjiParts,
    partOf: const [],
    meaning: '',
    frequency: frequency,
  );
}

void main() {
  test('knowledge suppression becomes logarithmically stronger below threshold',
      () {
    expect(kanjiKnowledgeSuppression(0.8), 1);
    expect(
      kanjiKnowledgeSuppression(0.01),
      lessThan(kanjiKnowledgeSuppression(0.1)),
    );
    expect(kanjiKnowledgeSuppression(0.01), lessThan(0.1));
  });

  test('more frequent kanji has greater utility when other factors match', () {
    const scorer = KanjiUtilityScorer();
    final common = scorer.score(entry('日', strokes: 4, frequency: 10));
    final rare = scorer.score(entry('龘', strokes: 4, frequency: 10000));
    expect(common.utility, greaterThan(rare.utility));
  });

  test('frequency has a bounded influence on utility', () {
    const scorer = KanjiUtilityScorer(
      params: KanjiUtilityParams(frequencyWeight: 3),
    );
    final common = scorer.score(entry('日', strokes: 4, frequency: 1));
    final rare = scorer.score(entry('龘', strokes: 4, frequency: 1000000));

    expect(common.utility / rare.utility, lessThan(5));
  });

  test('known kanji is simpler than an unknown kanji', () {
    const scorer = KanjiUtilityScorer();
    final unknown = scorer.score(entry('日', strokes: 4, frequency: 10));
    final known = scorer.score(
      entry('日', strokes: 4, frequency: 10),
      knownWeights: const {'日': 0.25},
    );
    expect(known.simplicity, greaterThan(unknown.simplicity));
    expect(known.utility, greaterThan(unknown.utility));
  });

  test('incorrect knowledge cannot reduce utility', () {
    const scorer = KanjiUtilityScorer(
      params: KanjiUtilityParams(knowledgeWeight: 3),
    );
    final unknown = scorer.score(entry('日', strokes: 4, frequency: 10));
    final incorrect = scorer.score(
      entry('日', strokes: 4, frequency: 10),
      knownWeights: const {'日': 2000},
    );

    expect(incorrect.utility, greaterThanOrEqualTo(unknown.utility));
  });

  test('knowledge boost remains bounded at maximum settings', () {
    const scorer = KanjiUtilityScorer(
      params: KanjiUtilityParams(knowledgeWeight: 3),
    );
    final unknown = scorer.score(entry('日', strokes: 4, frequency: 10));
    final known = scorer.score(
      entry('日', strokes: 4, frequency: 10),
      knownWeights: const {'日': 0.01},
    );

    expect(known.utility / unknown.utility, closeTo(1.75, 0.0001));
  });

  test('more strokes reduce simplicity', () {
    const scorer = KanjiUtilityScorer();
    final simple = scorer.score(entry('一', strokes: 1, frequency: 10));
    final complex = scorer.score(entry('龍', strokes: 16, frequency: 10));
    expect(simple.simplicity, greaterThan(complex.simplicity));
  });

  test('known components make a compound kanji simpler', () {
    const scorer = KanjiUtilityScorer();
    final compound = entry(
      '大',
      strokes: 3,
      frequency: 10,
      kanjiParts: const ['一', '人'],
    );
    final unknown = scorer.score(compound);
    final known = scorer.score(
      compound,
      knownWeights: const {'一': 0.1, '人': 0.01},
    );
    expect(known.knownComponents, containsAll(['一', '人']));
    expect(known.knowledgeWeight, lessThan(unknown.knowledgeWeight));
    expect(known.simplicity, greaterThan(unknown.simplicity));
  });
}
