/// Hepburn romaji ↔ kana. Accepts loose input (si/shi, tu/tsu, n'/nn).
class KanaRomaji {
  KanaRomaji._();

  static const _kataToHiraOffset = 0x3041 - 0x30A1;

  static String toHiragana(String input) {
    final buf = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x30A1 && rune <= 0x30F6) {
        buf.writeCharCode(rune + _kataToHiraOffset);
      } else {
        buf.writeCharCode(rune);
      }
    }
    return buf.toString();
  }

  static String normalizeKana(String input) {
    return toHiragana(input)
        .replaceAll('ー', '')
        .replaceAll('・', '')
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .replaceAll('　', '');
  }

  static String romajiToHiragana(String romaji) {
    final s = romaji.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
    final out = StringBuffer();
    var i = 0;
    while (i < s.length) {
      if (s[i] == '\'') {
        i++;
        continue;
      }
      // doubled consonant (sokuon), but not 'n'
      if (i + 1 < s.length &&
          s[i] == s[i + 1] &&
          _isConsonant(s[i]) &&
          s[i] != 'n') {
        out.write('っ');
        i++;
        continue;
      }
      var matched = false;
      for (var len = 4; len >= 1; len--) {
        if (i + len > s.length) continue;
        final slice = s.substring(i, i + len);
        final kana = _table[slice];
        if (kana != null) {
          out.write(kana);
          i += len;
          matched = true;
          break;
        }
      }
      if (!matched) {
        // skip unknown char so "n5" etc. don't lock the matcher
        i++;
      }
    }
    return out.toString();
  }

  static String kanaToRomaji(String kana) {
    final hira = normalizeKana(kana);
    final out = StringBuffer();
    var i = 0;
    while (i < hira.length) {
      if (hira[i] == 'っ' && i + 1 < hira.length) {
        final next = _longestRomaji(hira, i + 1);
        if (next != null && next.$1.isNotEmpty) {
          out.write(next.$1[0]);
          i++;
          continue;
        }
      }
      final hit = _longestRomaji(hira, i);
      if (hit == null) {
        i++;
        continue;
      }
      out.write(hit.$1);
      i += hit.$2;
    }
    return out.toString();
  }

  static (String, int)? _longestRomaji(String hira, int i) {
    for (var len = 2; len >= 1; len--) {
      if (i + len > hira.length) continue;
      final slice = hira.substring(i, i + len);
      final r = _kanaToRomaji[slice];
      if (r != null) return (r, len);
    }
    return null;
  }

  static bool _isConsonant(String c) =>
      'bcdfghjklmpqrstvwxyz'.contains(c);

  /// Returns true if [input] (romaji or kana) matches any accepted kana reading.
  static bool matches(String input, Iterable<String> acceptedKana) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    final asKana = normalizeKana(trimmed);
    final fromRomaji = romajiToHiragana(trimmed);
    for (final raw in acceptedKana) {
      final target = normalizeKana(raw);
      if (target.isEmpty) continue;
      if (asKana == target) return true;
      if (fromRomaji == target) return true;
      if (kanaToRomaji(target) == trimmed.toLowerCase().replaceAll(' ', '')) {
        return true;
      }
    }
    return false;
  }
}

const _table = <String, String>{
  'a': 'あ',
  'i': 'い',
  'u': 'う',
  'e': 'え',
  'o': 'お',
  'ka': 'か',
  'ki': 'き',
  'ku': 'く',
  'ke': 'け',
  'ko': 'こ',
  'sa': 'さ',
  'si': 'し',
  'shi': 'し',
  'su': 'す',
  'se': 'せ',
  'so': 'そ',
  'ta': 'た',
  'ti': 'ち',
  'chi': 'ち',
  'tu': 'つ',
  'tsu': 'つ',
  'te': 'て',
  'to': 'と',
  'na': 'な',
  'ni': 'に',
  'nu': 'ぬ',
  'ne': 'ね',
  'no': 'の',
  'ha': 'は',
  'hi': 'ひ',
  'hu': 'ふ',
  'fu': 'ふ',
  'he': 'へ',
  'ho': 'ほ',
  'ma': 'ま',
  'mi': 'み',
  'mu': 'む',
  'me': 'め',
  'mo': 'も',
  'ya': 'や',
  'yu': 'ゆ',
  'yo': 'よ',
  'ra': 'ら',
  'ri': 'り',
  'ru': 'る',
  're': 'れ',
  'ro': 'ろ',
  'wa': 'わ',
  'wi': 'ゐ',
  'we': 'ゑ',
  'wo': 'を',
  'n': 'ん',
  'nn': 'ん',
  'n\'': 'ん',
  'ga': 'が',
  'gi': 'ぎ',
  'gu': 'ぐ',
  'ge': 'げ',
  'go': 'ご',
  'za': 'ざ',
  'zi': 'じ',
  'ji': 'じ',
  'zu': 'ず',
  'ze': 'ぜ',
  'zo': 'ぞ',
  'da': 'だ',
  'di': 'ぢ',
  'du': 'づ',
  'de': 'で',
  'do': 'ど',
  'ba': 'ば',
  'bi': 'び',
  'bu': 'ぶ',
  'be': 'べ',
  'bo': 'ぼ',
  'pa': 'ぱ',
  'pi': 'ぴ',
  'pu': 'ぷ',
  'pe': 'ぺ',
  'po': 'ぽ',
  'kya': 'きゃ',
  'kyu': 'きゅ',
  'kyo': 'きょ',
  'sha': 'しゃ',
  'shu': 'しゅ',
  'sho': 'しょ',
  'sya': 'しゃ',
  'syu': 'しゅ',
  'syo': 'しょ',
  'cha': 'ちゃ',
  'chu': 'ちゅ',
  'cho': 'ちょ',
  'tya': 'ちゃ',
  'tyu': 'ちゅ',
  'tyo': 'ちょ',
  'nya': 'にゃ',
  'nyu': 'にゅ',
  'nyo': 'にょ',
  'hya': 'ひゃ',
  'hyu': 'ひゅ',
  'hyo': 'ひょ',
  'mya': 'みゃ',
  'myu': 'みゅ',
  'myo': 'みょ',
  'rya': 'りゃ',
  'ryu': 'りゅ',
  'ryo': 'りょ',
  'gya': 'ぎゃ',
  'gyu': 'ぎゅ',
  'gyo': 'ぎょ',
  'ja': 'じゃ',
  'ju': 'じゅ',
  'jo': 'じょ',
  'jya': 'じゃ',
  'jyu': 'じゅ',
  'jyo': 'じょ',
  'bya': 'びゃ',
  'byu': 'びゅ',
  'byo': 'びょ',
  'pya': 'ぴゃ',
  'pyu': 'ぴゅ',
  'pyo': 'ぴょ',
  'vu': 'ゔ',
  'fa': 'ふぁ',
  'fi': 'ふぃ',
  'fe': 'ふぇ',
  'fo': 'ふぉ',
};

final _kanaToRomaji = () {
  const preferred = {
    'し': 'shi',
    'ち': 'chi',
    'つ': 'tsu',
    'ふ': 'fu',
    'じ': 'ji',
    'しゃ': 'sha',
    'しゅ': 'shu',
    'しょ': 'sho',
    'ちゃ': 'cha',
    'ちゅ': 'chu',
    'ちょ': 'cho',
    'じゃ': 'ja',
    'じゅ': 'ju',
    'じょ': 'jo',
    'ん': 'n',
  };
  final map = <String, String>{};
  for (final e in _table.entries) {
    map.putIfAbsent(e.value, () => e.key);
  }
  map.addAll(preferred);
  map['っ'] = 't';
  return map;
}();
