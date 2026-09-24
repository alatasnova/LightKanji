import 'dart:math';

import 'models.dart';

const _maxKnowledgeUtilityBoost = 1.75;

double kanjiKnowledgeSuppression(
  double weight, {
  double start = 0.5,
  double minimum = 0.01,
}) {
  final normalized = weight.clamp(minimum, start);
  if (normalized >= start) return 1;
  final logarithmic =
      log(1 + normalized / minimum) / log(1 + start / minimum);
  return pow(logarithmic, 2).toDouble().clamp(0.01, 1.0);
}

class KanjiUtilityParams {
  const KanjiUtilityParams({
    this.strokeWeight = 1,
    this.frequencyWeight = 1,
    this.knowledgeWeight = 1,
    this.knownBaseline = 1,
  });

  final double strokeWeight;
  final double frequencyWeight;
  final double knowledgeWeight;
  final double knownBaseline;

  KanjiUtilityParams copyWith({
    double? strokeWeight,
    double? frequencyWeight,
    double? knowledgeWeight,
    double? knownBaseline,
  }) {
    return KanjiUtilityParams(
      strokeWeight: strokeWeight ?? this.strokeWeight,
      frequencyWeight: frequencyWeight ?? this.frequencyWeight,
      knowledgeWeight: knowledgeWeight ?? this.knowledgeWeight,
      knownBaseline: knownBaseline ?? this.knownBaseline,
    );
  }
}

class KanjiUtilityScore {
  const KanjiUtilityScore({
    required this.entry,
    required this.simplicity,
    required this.frequencyScore,
    required this.utility,
    required this.knowledgeWeight,
    required this.knownComponents,
  });

  final KanjiumEntry entry;
  final double simplicity;
  final double frequencyScore;
  final double utility;
  final double knowledgeWeight;
  final List<String> knownComponents;
}

class KanjiUtilityScorer {
  const KanjiUtilityScorer({this.params = const KanjiUtilityParams()});

  final KanjiUtilityParams params;

  KanjiUtilityScore score(
    KanjiumEntry entry, {
    Map<String, double> knownWeights = const {},
  }) {
    final componentKeys = {
      entry.radical,
      ...entry.kanjiParts,
    }..removeWhere((part) => part.isEmpty);
    final knownComponents = componentKeys
        .where(knownWeights.containsKey)
        .toList(growable: false);
    final weights = [
      if (knownWeights[entry.character] case final weight?) weight,
      for (final component in knownComponents) knownWeights[component]!,
    ];
    final weight = weights.isEmpty
        ? params.knownBaseline
        : exp(
            weights.map((value) => log(max(value, 0.01))).reduce(
                  (a, b) => a + b,
                ) /
                weights.length,
          );
    final knowledgeFactor = (params.knownBaseline / max(weight, 0.01))
        .clamp(1.0, _maxKnowledgeUtilityBoost);
    final strokeFactor = 1 / (1 + entry.strokes / 5);
    final frequencyFactor = entry.frequency == null
        ? 0.6
        : 0.6 + 0.4 / (1 + log(max(entry.frequency!, 1)));
    final simplicity = pow(strokeFactor, params.strokeWeight).toDouble() *
        pow(
          knowledgeFactor,
          params.knowledgeWeight.clamp(0.0, 1.0),
        ).toDouble();
    final utility = simplicity *
        pow(frequencyFactor, params.frequencyWeight).toDouble();
    return KanjiUtilityScore(
      entry: entry,
      simplicity: simplicity,
      frequencyScore: frequencyFactor,
      utility: utility,
      knowledgeWeight: weight,
      knownComponents: knownComponents,
    );
  }

  double scoreSequence(
    Iterable<KanjiumEntry> entries, {
    Map<String, double> knownWeights = const {},
  }) {
    final scores = [
      for (final entry in entries) score(entry, knownWeights: knownWeights),
    ];
    if (scores.isEmpty) return 1;
    return scores
            .map((item) => item.utility)
            .reduce((a, b) => a + b) /
        scores.length;
  }

  List<KanjiUtilityScore> rank(
    Iterable<KanjiumEntry> entries, {
    Map<String, double> knownWeights = const {},
  }) {
    final scores = [
      for (final entry in entries) score(entry, knownWeights: knownWeights),
    ];
    scores.sort((a, b) => b.utility.compareTo(a.utility));
    return scores;
  }
}
