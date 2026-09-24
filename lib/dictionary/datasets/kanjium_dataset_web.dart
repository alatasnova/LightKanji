import '../models.dart';
import 'package:flutter/services.dart';

/// Web-compatible Kanjium adapter.
///
/// The native SQLite adapter requires `dart:io`. Web builds keep the facade
/// available and continue using the JSON-backed dictionaries; structural
/// Kanjium data is unavailable until a web database adapter is added.
class KanjiumDataset {
  static const assetPath = 'assets/dictionaries/kanjidb.sqlite';

  bool get isLoaded => true;

  Future<void> load({AssetBundle? bundle}) async {}

  KanjiumEntry? byCharacter(String character) => null;

  List<KanjiumEntry> search(String query, {int limit = 50}) => const [];

  List<KanjiumEntry> allEntries({int limit = 500}) => const [];

  List<KanjiumRadical> radicalsFor(String character) => const [];

  List<KanjiumEntry> lookalikesFor(String character) => const [];
}
