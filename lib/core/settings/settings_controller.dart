import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../weighted/weighted_picker.dart';
import '../../data/kana_catalog.dart';
import '../../dictionary/kanji_utility.dart';

class AppSettings {
  AppSettings({
    WeightedParams? weighted,
    Set<int>? jlptLevels,
    Set<String>? kanaRows,
    this.includeHiragana = true,
    this.includeKatakana = false,
    this.kanaImmediateAdvance = true,
    this.kanjiImmediateAdvance = true,
    this.kanjiShowMeaning = false,
    this.kanjiUtilityPercent = 100,
    KanjiUtilityParams? kanjiUtility,
  })  : weighted = weighted ?? const WeightedParams(),
        jlptLevels = jlptLevels ?? {5, 4},
        kanaRows = kanaRows ?? {'a', 'ka', 'sa', 'ta', 'na'},
        kanjiUtility = kanjiUtility ?? const KanjiUtilityParams();

  WeightedParams weighted;
  Set<int> jlptLevels;
  Set<String> kanaRows;
  bool includeHiragana;
  bool includeKatakana;
  bool kanaImmediateAdvance;
  bool kanjiImmediateAdvance;
  bool kanjiShowMeaning;
  double kanjiUtilityPercent;
  KanjiUtilityParams kanjiUtility;

  AppSettings copy() {
    return AppSettings(
      weighted: weighted,
      jlptLevels: {...jlptLevels},
      kanaRows: {...kanaRows},
      includeHiragana: includeHiragana,
      includeKatakana: includeKatakana,
      kanaImmediateAdvance: kanaImmediateAdvance,
      kanjiImmediateAdvance: kanjiImmediateAdvance,
      kanjiShowMeaning: kanjiShowMeaning,
      kanjiUtilityPercent: kanjiUtilityPercent,
      kanjiUtility: kanjiUtility,
    );
  }

  Map<String, dynamic> toJson() => {
        'weighted': weighted.toJson(),
        'jlptLevels': jlptLevels.toList()..sort(),
        'kanaRows': kanaRows.toList()..sort(),
        'includeHiragana': includeHiragana,
        'includeKatakana': includeKatakana,
        'kanaImmediateAdvance': kanaImmediateAdvance,
        'kanjiImmediateAdvance': kanjiImmediateAdvance,
        'kanjiShowMeaning': kanjiShowMeaning,
        'kanjiUtilityPercent': kanjiUtilityPercent,
        'kanjiUtility': {
          'strokeWeight': kanjiUtility.strokeWeight,
          'frequencyWeight': kanjiUtility.frequencyWeight,
          'knowledgeWeight': kanjiUtility.knowledgeWeight,
        },
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      weighted: WeightedParams.fromJson(
        json['weighted'] as Map<String, dynamic>?,
      ),
      jlptLevels: {
        for (final v in json['jlptLevels'] as List? ?? const [5, 4])
          (v as num).toInt(),
      },
      kanaRows: {
        for (final v in json['kanaRows'] as List? ?? const ['a', 'ka', 'sa', 'ta', 'na'])
          v.toString(),
      },
      includeHiragana: json['includeHiragana'] as bool? ?? true,
      includeKatakana: json['includeKatakana'] as bool? ?? false,
      kanaImmediateAdvance: json['kanaImmediateAdvance'] as bool? ?? true,
      kanjiImmediateAdvance: json['kanjiImmediateAdvance'] as bool? ?? true,
      kanjiShowMeaning: json['kanjiShowMeaning'] as bool? ?? false,
      kanjiUtilityPercent:
          ((json['kanjiUtilityPercent'] as num?)?.toDouble() ?? 100)
              .clamp(1, 100),
      kanjiUtility: _utilityFromJson(json['kanjiUtility']),
    );
  }
}

KanjiUtilityParams _utilityFromJson(dynamic value) {
  if (value is! Map) return const KanjiUtilityParams();
  return KanjiUtilityParams(
    strokeWeight: (value['strokeWeight'] as num?)?.toDouble() ?? 1,
    frequencyWeight: (value['frequencyWeight'] as num?)?.toDouble() ?? 1,
    knowledgeWeight: (value['knowledgeWeight'] as num?)?.toDouble() ?? 1,
  );
}

class SettingsController extends ChangeNotifier {
  SettingsController();

  static const _settingsKey = 'lightkanji.settings.v1';
  static const _kanaWeightsKey = 'lightkanji.weights.kana.v1';
  static const _kanjiWeightsKey = 'lightkanji.weights.kanji.v1';
  static const _kanjiKnowledgeKey = 'lightkanji.knowledge.kanji.v1';

  SharedPreferences? _prefs;
  AppSettings settings = AppSettings();
  late WeightedPicker kanaPicker = WeightedPicker(params: settings.weighted);
  late WeightedPicker kanjiPicker = WeightedPicker(params: settings.weighted);
  Map<String, double> kanjiKnowledge = {};

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_settingsKey);
    if (raw != null) {
      try {
        settings = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        settings = AppSettings();
      }
    }
    kanaPicker = WeightedPicker(
      params: settings.weighted,
      weights: WeightedPicker.decodeWeights(_prefs!.getString(_kanaWeightsKey)),
    );
    kanjiPicker = WeightedPicker(
      params: settings.weighted,
      weights: WeightedPicker.decodeWeights(_prefs!.getString(_kanjiWeightsKey)),
    );
    final knowledge = _prefs!.getString(_kanjiKnowledgeKey);
    if (knowledge != null) {
      kanjiKnowledge = WeightedPicker.decodeWeights(knowledge);
    }
    notifyListeners();
  }

  Future<void> _persistSettings() async {
    await _prefs?.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> persistKanaWeights() async {
    await _prefs?.setString(_kanaWeightsKey, kanaPicker.encodeWeights());
  }

  Future<void> persistKanjiWeights() async {
    await _prefs?.setString(_kanjiWeightsKey, kanjiPicker.encodeWeights());
  }

  Future<void> persistKanjiKnowledge() async {
    await _prefs?.setString(
      _kanjiKnowledgeKey,
      jsonEncode(kanjiKnowledge),
    );
  }

  Future<void> recordKanjiKnowledge(
    Iterable<String> characters, {
    required bool correct,
    double multiplier = 1,
  }) async {
    for (final character in characters.toSet()) {
      final current = kanjiKnowledge[character] ?? settings.weighted.baseline;
      final next = correct
          ? current * settings.weighted.decay
          : current *
              pow(settings.weighted.penalty, multiplier).toDouble();
      kanjiKnowledge[character] =
          next.clamp(settings.weighted.minWeight, settings.weighted.maxWeight);
    }
    await persistKanjiKnowledge();
    notifyListeners();
  }

  Future<void> update(void Function(AppSettings s) fn) async {
    fn(settings);
    kanaPicker.params = settings.weighted;
    kanjiPicker.params = settings.weighted;
    await _persistSettings();
    notifyListeners();
  }

  Future<void> resetWeights({bool kana = true, bool kanji = true}) async {
    if (kana) {
      kanaPicker.reset();
      await persistKanaWeights();
    }
    if (kanji) {
      kanjiPicker.reset();
      await persistKanjiWeights();
    }
    notifyListeners();
  }

  List<KanaGlyph> enabledKana() {
    return KanaCatalog.glyphs(
      rowIds: settings.kanaRows,
      hiragana: settings.includeHiragana,
      katakana: settings.includeKatakana,
    );
  }
}
