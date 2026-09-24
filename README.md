# LightKanji

LightKanji is a focused kanji study app built with Flutter and Material 3.
It targets Android, Linux, Windows and web.

## Current features

- Kana trainer with configurable scripts and kana rows.
- Weighted selection that prioritizes items with recent mistakes.
- Kanji reading trainer using real JMdict word readings rather than only
  abstract on/kun readings.
- Whole-word kanji trainer powered by `pronounce_vocab.json`, which assigns a
  JLPT level to each word and reading variant.
- Local dictionary search by kanji, word, reading, translation and examples,
  with JLPT filters.
- Automatic local persistence for trainer options and per-item weights.
- Responsive navigation rail on wide screens and navigation bar on phones.

## Dictionary architecture

Each dataset is loaded by its own module:

- `kanji_jlpt_only.json` supplies JLPT metadata and raw readings.
- `jmdict_kanji_index.json` supplies real word readings, meanings and examples.
- `pronounce_vocab.json` supplies whole vocabulary items with per-reading JLPT
  levels. The kanji trainer uses this dataset directly.
- `kanjidb.sqlite` is the local Kanjium database. It supplies kanji frequency,
  stroke counts, structural components, radicals and lookalikes.

`KanjiDatabase` is the single facade consumed by trainers and the dictionary
screen. This keeps dataset-specific parsing out of the UI and allows another
dataset to be added without changing trainer code. The dictionary enriches
JMdict readings with matching levels from `pronounce_vocab.json` using the
exact word and reading pair.

## Kanjium structural database

The Kanjium SQLite database is bundled as
`assets/dictionaries/kanjidb.sqlite` and is loaded by
[`KanjiumDataset`](./lib/dictionary/datasets/kanjium_dataset.dart). The
database is read-only at runtime and currently exposes:

- `byCharacter()` — frequency, strokes, JLPT metadata, meanings and structure;
- `radicalsFor()` — radical and radical-variant metadata for a kanji;
- `lookalikesFor()` — visually similar kanji from Kanjium;
- `search()` — bounded search by character or meaning.

The same operations are available through [`KanjiDatabase`](./lib/dictionary/kanji_database.dart)
so UI and recommendation code do not depend on SQLite details. The adapter
intentionally does not calculate a learning score yet; it only provides the
structured data needed for that future layer.

## Kanji utility settings

The kanji trainer settings expose sliders for the utility model's stroke,
frequency and knowledge coefficients. The model ranks Kanjium entries using
stroke-based simplicity, usage frequency and the user's existing per-kanji
weight. Frequency uses a saturating curve, so very common entries do not
overpower the learning state. Knowledge suppression is applied separately
with a stronger bounded multiplier, while error weights from the weighted
picker can still bring a missed item back into rotation. The scorer is isolated in
[`kanji_utility.dart`](./lib/dictionary/kanji_utility.dart), so the formula
can be calibrated without changing the database adapter or UI.

The database is sourced from
[mifunetoshiro/kanjium](https://github.com/mifunetoshiro/kanjium), as described
by its repository license and acknowledgements.

## Running

Install the Flutter SDK, then run:

```sh
flutter pub get
flutter test
flutter run
```

### Web

Build the browser application with:

```sh
flutter build web
```

To run a local development host reachable from other devices on the network:

```sh
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

The application is then available at `http://localhost:8080` and at the
machine's LAN address on port `8080`. The web build uses the JSON-backed
dictionaries. Kanjium's native SQLite adapter is disabled on web because it
requires `dart:io`; its web adapter is kept as a safe no-op until a browser
SQLite implementation is added.
