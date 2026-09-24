import 'dart:convert';
import 'dart:math';

/// Weighted probabilistic picker for any string keys (kana, kanji, words).
///
/// One error jumps the item's weight in proportion to the active pool size;
/// correct answers decay it toward the seen-item baseline.
class WeightedPicker {
  WeightedPicker({
    required this.params,
    Map<String, double>? weights,
    Random? random,
  })  : _weights = Map<String, double>.from(weights ?? const {}),
        _random = random ?? Random();

  WeightedParams params;
  final Map<String, double> _weights;
  final Random _random;
  String? _lastKey;
  int _lastPoolSize = 1;

  Map<String, double> get weights => Map.unmodifiable(_weights);

  double weightOf(String key) {
    final w = _weights[key] ?? params.baseline;
    return w.clamp(params.minWeight, params.maxWeight);
  }

  String pick(
    List<String> items, {
    Map<String, double> priorities = const {},
  }) {
    if (items.isEmpty) {
      throw StateError('Cannot pick from an empty list');
    }
    final pool = items.length == 1
        ? items
        : items.where((k) => k != _lastKey).toList(growable: false);
    final chosenPool = pool.isEmpty ? items : pool;
    _lastPoolSize = chosenPool.length;

    var total = 0.0;
    final ws = <double>[];
    for (final key in chosenPool) {
      final w = weightOf(key) * (priorities[key] ?? 1).clamp(0.01, 100.0);
      ws.add(w);
      total += w;
    }
    var ticket = _random.nextDouble() * total;
    for (var i = 0; i < chosenPool.length; i++) {
      ticket -= ws[i];
      if (ticket <= 0) {
        return _remember(chosenPool[i]);
      }
    }
    return _remember(chosenPool.last);
  }

  void recordCorrect(String key) {
    final current = weightOf(key);
    final next =
        params.seenBaseline + (current - params.seenBaseline) * params.decay;
    _set(key, next);
  }

  void recordError(
    String key, {
    double multiplier = 1,
    int? poolSize,
  }) {
    final current = weightOf(key);
    final sizeScale = max(1, poolSize ?? _lastPoolSize);
    final next = current *
        pow(params.penalty, multiplier).toDouble() *
        sizeScale;
    _set(key, next);
  }

  void reset([Iterable<String>? keys]) {
    if (keys == null) {
      _weights.clear();
      return;
    }
    for (final key in keys) {
      _weights.remove(key);
    }
  }

  void _set(String key, double value) {
    _weights[key] = value.clamp(params.minWeight, params.maxWeight);
  }

  String _remember(String key) {
    _lastKey = key;
    if (!_weights.containsKey(key)) {
      _set(key, params.seenBaseline);
    }
    return key;
  }

  String encodeWeights() => jsonEncode(_weights);

  static Map<String, double> decodeWeights(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return decoded.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
  }
}

class WeightedParams {
  const WeightedParams({
    this.baseline = 1,
    this.seenBaseline = 1.25,
    this.penalty = 8,
    this.decay = 0.82,
    this.minWeight = 0.001,
    this.maxWeight = 2000,
    this.revealMultiplier = 3,
  });

  /// Starting weight for unseen items.
  final double baseline;

  /// Weight of an item after it has been answered at least once.
  final double seenBaseline;

  /// Multiplier applied on a normal error. One miss should dominate sampling.
  final double penalty;

  /// After each correct answer:
  /// `seenBaseline + (weight - seenBaseline) * decay`.
  final double decay;

  final double minWeight;
  final double maxWeight;

  /// Extra exponent used when the user reveals the answer (Enter).
  final double revealMultiplier;

  WeightedParams copyWith({
    double? baseline,
    double? seenBaseline,
    double? penalty,
    double? decay,
    double? minWeight,
    double? maxWeight,
    double? revealMultiplier,
  }) {
    return WeightedParams(
      baseline: baseline ?? this.baseline,
      seenBaseline: seenBaseline ?? this.seenBaseline,
      penalty: penalty ?? this.penalty,
      decay: decay ?? this.decay,
      minWeight: minWeight ?? this.minWeight,
      maxWeight: maxWeight ?? this.maxWeight,
      revealMultiplier: revealMultiplier ?? this.revealMultiplier,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseline': baseline,
        'seenBaseline': seenBaseline,
        'penalty': penalty,
        'decay': decay,
        'minWeight': minWeight,
        'maxWeight': maxWeight,
        'revealMultiplier': revealMultiplier,
      };

  factory WeightedParams.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WeightedParams();
    return WeightedParams(
      baseline: (json['baseline'] as num?)?.toDouble() ?? 1,
      seenBaseline: (json['seenBaseline'] as num?)?.toDouble() ?? 1.25,
      penalty: (json['penalty'] as num?)?.toDouble() ?? 8,
      decay: (json['decay'] as num?)?.toDouble() ?? 0.82,
      minWeight: (json['minWeight'] as num?)?.toDouble() ?? 0.001,
      maxWeight: (json['maxWeight'] as num?)?.toDouble() ?? 2000,
      revealMultiplier: (json['revealMultiplier'] as num?)?.toDouble() ?? 3,
    );
  }
}
