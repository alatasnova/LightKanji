import 'package:flutter_test/flutter_test.dart';
import 'package:light_kanji/dictionary/datasets/kanjium_dataset.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads Kanjium structure and component relations', () async {
    final dataset = KanjiumDataset();
    await dataset.load();

    final entry = dataset.byCharacter('明');
    expect(entry, isNotNull);
    expect(entry!.strokes, greaterThan(0));
    expect(entry.kanjiParts, isNotEmpty);

    final radicals = dataset.radicalsFor('明');
    expect(radicals, isNotEmpty);

    final lookalikes = dataset.lookalikesFor('会');
    expect(lookalikes, isNotEmpty);
  });
}
