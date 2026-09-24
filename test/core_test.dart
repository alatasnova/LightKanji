import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_kanji/core/romaji/kana_romaji.dart';
import 'package:light_kanji/core/settings/settings_controller.dart';
import 'package:light_kanji/core/weighted/weighted_picker.dart';

void main() {
  test('persists the kanji utility study range', () {
    final settings = AppSettings()..kanjiUtilityPercent = 20;
    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.kanjiUtilityPercent, 20);
  });

  group('KanaRomaji', () {
    test('round-trips common mora', () {
      expect(KanaRomaji.romajiToHiragana('shi'), 'し');
      expect(KanaRomaji.romajiToHiragana('tsu'), 'つ');
      expect(KanaRomaji.romajiToHiragana('kyo'), 'きょ');
      expect(KanaRomaji.romajiToHiragana('nana'), 'なな');
      expect(KanaRomaji.romajiToHiragana('taberu'), 'たべる');
    });

    test('matches romaji against kana readings', () {
      expect(KanaRomaji.matches('shichi', ['しち']), isTrue);
      expect(KanaRomaji.matches('シチ', ['しち']), isTrue);
      expect(KanaRomaji.matches('wrong', ['しち']), isFalse);
    });
  });

  group('WeightedPicker', () {
    test('error then many corrects decays toward baseline', () {
      final picker = WeightedPicker(
        params: const WeightedParams(penalty: 8, decay: 0.82, baseline: 1),
        random: Random(1),
      );
      picker.recordError('あ');
      expect(picker.weightOf('あ'), greaterThan(7));
      for (var i = 0; i < 16; i++) {
        picker.recordCorrect('あ');
      }
      expect(picker.weightOf('あ'), lessThan(2));
    });

    test('reveal uses extra multiplier', () {
      final picker = WeightedPicker(
        params: const WeightedParams(penalty: 2, revealMultiplier: 3),
      );
      picker.recordError('x', multiplier: picker.params.revealMultiplier);
      expect(picker.weightOf('x'), closeTo(8, 0.01));
    });

    test('seen items stay more likely than unseen items', () {
      final picker = WeightedPicker(
        params: const WeightedParams(seenBaseline: 2),
      );
      picker.recordCorrect('seen');
      expect(picker.weightOf('seen'), greaterThan(picker.weightOf('new')));
    });

    test('error scales with the current pool size', () {
      final picker = WeightedPicker(
        params: const WeightedParams(penalty: 2),
      );
      picker.pick(List<String>.generate(20, (i) => 'item$i'));
      picker.recordError('item0');
      expect(picker.weightOf('item0'), closeTo(40, 0.01));
    });
  });
}
