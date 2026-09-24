class KanaGlyph {
  const KanaGlyph({
    required this.character,
    required this.romaji,
    required this.rowId,
    required this.script,
  });

  final String character;
  final String romaji;
  final String rowId;
  final KanaScript script;
}

enum KanaScript { hiragana, katakana }

class KanaRow {
  const KanaRow({
    required this.id,
    required this.title,
    required this.group,
  });

  final String id;
  final String title;
  final String group;
}

class KanaCatalog {
  static const rows = <KanaRow>[
    KanaRow(id: 'a', title: 'あ行', group: 'годзюон'),
    KanaRow(id: 'ka', title: 'か行', group: 'годзюон'),
    KanaRow(id: 'sa', title: 'さ行', group: 'годзюон'),
    KanaRow(id: 'ta', title: 'た行', group: 'годзюон'),
    KanaRow(id: 'na', title: 'な行', group: 'годзюон'),
    KanaRow(id: 'ha', title: 'は行', group: 'годзюон'),
    KanaRow(id: 'ma', title: 'ま行', group: 'годзюон'),
    KanaRow(id: 'ya', title: 'や行', group: 'годзюон'),
    KanaRow(id: 'ra', title: 'ら行', group: 'годзюон'),
    KanaRow(id: 'wa', title: 'わ行', group: 'годзюон'),
    KanaRow(id: 'n', title: 'ん', group: 'годзюон'),
    KanaRow(id: 'ga', title: 'が行', group: 'дакутэн'),
    KanaRow(id: 'za', title: 'ざ行', group: 'дакутэн'),
    KanaRow(id: 'da', title: 'だ行', group: 'дакутэн'),
    KanaRow(id: 'ba', title: 'ば行', group: 'дакутэн'),
    KanaRow(id: 'pa', title: 'ぱ行', group: 'хандакутэн'),
    KanaRow(id: 'kya', title: 'きゃ', group: 'ёон'),
    KanaRow(id: 'sha', title: 'しゃ', group: 'ёон'),
    KanaRow(id: 'cha', title: 'ちゃ', group: 'ёон'),
    KanaRow(id: 'nya', title: 'にゃ', group: 'ёон'),
    KanaRow(id: 'hya', title: 'ひゃ', group: 'ёон'),
    KanaRow(id: 'mya', title: 'みゃ', group: 'ёон'),
    KanaRow(id: 'rya', title: 'りゃ', group: 'ёон'),
    KanaRow(id: 'gya', title: 'ぎゃ', group: 'ёон'),
    KanaRow(id: 'ja', title: 'じゃ', group: 'ёон'),
    KanaRow(id: 'bya', title: 'びゃ', group: 'ёон'),
    KanaRow(id: 'pya', title: 'ぴゃ', group: 'ёон'),
  ];

  static const _pairs = <(String, String, String, String)>[
    ('a', 'あ', 'ア', 'a'),
    ('a', 'い', 'イ', 'i'),
    ('a', 'う', 'ウ', 'u'),
    ('a', 'え', 'エ', 'e'),
    ('a', 'お', 'オ', 'o'),
    ('ka', 'か', 'カ', 'ka'),
    ('ka', 'き', 'キ', 'ki'),
    ('ka', 'く', 'ク', 'ku'),
    ('ka', 'け', 'ケ', 'ke'),
    ('ka', 'こ', 'コ', 'ko'),
    ('sa', 'さ', 'サ', 'sa'),
    ('sa', 'し', 'シ', 'shi'),
    ('sa', 'す', 'ス', 'su'),
    ('sa', 'せ', 'セ', 'se'),
    ('sa', 'そ', 'ソ', 'so'),
    ('ta', 'た', 'タ', 'ta'),
    ('ta', 'ち', 'チ', 'chi'),
    ('ta', 'つ', 'ツ', 'tsu'),
    ('ta', 'て', 'テ', 'te'),
    ('ta', 'と', 'ト', 'to'),
    ('na', 'な', 'ナ', 'na'),
    ('na', 'に', 'ニ', 'ni'),
    ('na', 'ぬ', 'ヌ', 'nu'),
    ('na', 'ね', 'ネ', 'ne'),
    ('na', 'の', 'ノ', 'no'),
    ('ha', 'は', 'ハ', 'ha'),
    ('ha', 'ひ', 'ヒ', 'hi'),
    ('ha', 'ふ', 'フ', 'fu'),
    ('ha', 'へ', 'ヘ', 'he'),
    ('ha', 'ほ', 'ホ', 'ho'),
    ('ma', 'ま', 'マ', 'ma'),
    ('ma', 'み', 'ミ', 'mi'),
    ('ma', 'む', 'ム', 'mu'),
    ('ma', 'め', 'メ', 'me'),
    ('ma', 'も', 'モ', 'mo'),
    ('ya', 'や', 'ヤ', 'ya'),
    ('ya', 'ゆ', 'ユ', 'yu'),
    ('ya', 'よ', 'ヨ', 'yo'),
    ('ra', 'ら', 'ラ', 'ra'),
    ('ra', 'り', 'リ', 'ri'),
    ('ra', 'る', 'ル', 'ru'),
    ('ra', 'れ', 'レ', 're'),
    ('ra', 'ろ', 'ロ', 'ro'),
    ('wa', 'わ', 'ワ', 'wa'),
    ('wa', 'を', 'ヲ', 'wo'),
    ('n', 'ん', 'ン', 'n'),
    ('ga', 'が', 'ガ', 'ga'),
    ('ga', 'ぎ', 'ギ', 'gi'),
    ('ga', 'ぐ', 'グ', 'gu'),
    ('ga', 'げ', 'ゲ', 'ge'),
    ('ga', 'ご', 'ゴ', 'go'),
    ('za', 'ざ', 'ザ', 'za'),
    ('za', 'じ', 'ジ', 'ji'),
    ('za', 'ず', 'ズ', 'zu'),
    ('za', 'ぜ', 'ゼ', 'ze'),
    ('za', 'ぞ', 'ゾ', 'zo'),
    ('da', 'だ', 'ダ', 'da'),
    ('da', 'ぢ', 'ヂ', 'di'),
    ('da', 'づ', 'ヅ', 'du'),
    ('da', 'で', 'デ', 'de'),
    ('da', 'ど', 'ド', 'do'),
    ('ba', 'ば', 'バ', 'ba'),
    ('ba', 'び', 'ビ', 'bi'),
    ('ba', 'ぶ', 'ブ', 'bu'),
    ('ba', 'べ', 'ベ', 'be'),
    ('ba', 'ぼ', 'ボ', 'bo'),
    ('pa', 'ぱ', 'パ', 'pa'),
    ('pa', 'ぴ', 'ピ', 'pi'),
    ('pa', 'ぷ', 'プ', 'pu'),
    ('pa', 'ぺ', 'ペ', 'pe'),
    ('pa', 'ぽ', 'ポ', 'po'),
    ('kya', 'きゃ', 'キャ', 'kya'),
    ('kya', 'きゅ', 'キュ', 'kyu'),
    ('kya', 'きょ', 'キョ', 'kyo'),
    ('sha', 'しゃ', 'シャ', 'sha'),
    ('sha', 'しゅ', 'シュ', 'shu'),
    ('sha', 'しょ', 'ショ', 'sho'),
    ('cha', 'ちゃ', 'チャ', 'cha'),
    ('cha', 'ちゅ', 'チュ', 'chu'),
    ('cha', 'ちょ', 'チョ', 'cho'),
    ('nya', 'にゃ', 'ニャ', 'nya'),
    ('nya', 'にゅ', 'ニュ', 'nyu'),
    ('nya', 'にょ', 'ニョ', 'nyo'),
    ('hya', 'ひゃ', 'ヒャ', 'hya'),
    ('hya', 'ひゅ', 'ヒュ', 'hyu'),
    ('hya', 'ひょ', 'ヒョ', 'hyo'),
    ('mya', 'みゃ', 'ミャ', 'mya'),
    ('mya', 'みゅ', 'ミュ', 'myu'),
    ('mya', 'みょ', 'ミョ', 'myo'),
    ('rya', 'りゃ', 'リャ', 'rya'),
    ('rya', 'りゅ', 'リュ', 'ryu'),
    ('rya', 'りょ', 'リョ', 'ryo'),
    ('gya', 'ぎゃ', 'ギャ', 'gya'),
    ('gya', 'ぎゅ', 'ギュ', 'gyu'),
    ('gya', 'ぎょ', 'ギョ', 'gyo'),
    ('ja', 'じゃ', 'ジャ', 'ja'),
    ('ja', 'じゅ', 'ジュ', 'ju'),
    ('ja', 'じょ', 'ジョ', 'jo'),
    ('bya', 'びゃ', 'ビャ', 'bya'),
    ('bya', 'びゅ', 'ビュ', 'byu'),
    ('bya', 'びょ', 'ビョ', 'byo'),
    ('pya', 'ぴゃ', 'ピャ', 'pya'),
    ('pya', 'ぴゅ', 'ピュ', 'pyu'),
    ('pya', 'ぴょ', 'ピョ', 'pyo'),
  ];

  static List<KanaGlyph> glyphs({
    required Set<String> rowIds,
    required bool hiragana,
    required bool katakana,
  }) {
    final out = <KanaGlyph>[];
    for (final row in _pairs) {
      if (!rowIds.contains(row.$1)) continue;
      if (hiragana) {
        out.add(KanaGlyph(
          character: row.$2,
          romaji: row.$4,
          rowId: row.$1,
          script: KanaScript.hiragana,
        ));
      }
      if (katakana) {
        out.add(KanaGlyph(
          character: row.$3,
          romaji: row.$4,
          rowId: row.$1,
          script: KanaScript.katakana,
        ));
      }
    }
    return out;
  }
}
