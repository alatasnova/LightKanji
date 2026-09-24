import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models.dart';

/// Read-only adapter for the Kanjium SQLite database.
class KanjiumDataset {
  static const assetPath = 'assets/dictionaries/kanjidb.sqlite';

  Database? _database;

  bool get isLoaded => _database != null;

  Future<void> load({AssetBundle? bundle}) async {
    if (isLoaded) return;
    final byteData = await (bundle ?? rootBundle).load(assetPath);
    final tempDirectory = await Directory.systemTemp.createTemp('lightkanji-');
    final tempFile = File('${tempDirectory.path}/kanjidb.sqlite');
    try {
      await tempFile.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
        flush: true,
      );
      final source = sqlite3.open(
        tempFile.path,
        mode: OpenMode.readOnly,
      );
      try {
        _database = sqlite3.copyIntoMemory(source);
      } finally {
        source.dispose();
      }
    } finally {
      await tempFile.delete();
      await tempDirectory.delete();
    }
  }

  KanjiumEntry? byCharacter(String character) {
    final db = _requireDatabase();
    final rows = db.select(
      '''
      SELECT k.kanji, k.radical, k.strokes, k.idc, e.elements,
             e.extra_elements, e.kanji_parts, e.part_of, k.meaning,
             k.frequency, k.jlpt, k.grade
      FROM kanjidict k
      LEFT JOIN elements e ON e.kanji = k.kanji
      WHERE k.kanji = ?
      LIMIT 1
      ''',
      [character],
    );
    return rows.isEmpty ? null : _entryFromRow(rows.first);
  }

  List<KanjiumEntry> search(String query, {int limit = 50}) {
    final db = _requireDatabase();
    final normalized = query.trim();
    if (normalized.isEmpty) return const [];
    final rows = db.select(
      '''
      SELECT k.kanji, k.radical, k.strokes, k.idc, e.elements,
             e.extra_elements, e.kanji_parts, e.part_of, k.meaning,
             k.frequency, k.jlpt, k.grade
      FROM kanjidict k
      LEFT JOIN elements e ON e.kanji = k.kanji
      WHERE k.kanji LIKE ? OR k.meaning LIKE ?
      ORDER BY frequency IS NULL, frequency
      LIMIT ?
      ''',
      [normalized, '%$normalized%', limit],
    );
    return rows.map(_entryFromRow).toList(growable: false);
  }

  List<KanjiumEntry> allEntries({int limit = 500}) {
    final db = _requireDatabase();
    final rows = db.select(
      '''
      SELECT k.kanji, k.radical, k.strokes, k.idc, e.elements,
             e.extra_elements, e.kanji_parts, e.part_of, k.meaning,
             k.frequency, k.jlpt, k.grade
      FROM kanjidict k
      LEFT JOIN elements e ON e.kanji = k.kanji
      ORDER BY k.frequency IS NULL, k.frequency
      LIMIT ?
      ''',
      [limit],
    );
    return rows.map(_entryFromRow).toList(growable: false);
  }

  List<KanjiumRadical> radicalsFor(String character) {
    final entry = byCharacter(character);
    if (entry == null) return const [];
    final db = _requireDatabase();
    final symbols = <String>{entry.radical, ...entry.kanjiParts};
    final rows = db.select(
      '''
      SELECT radical, radvar, number, strokes, names, meaning, notes
      FROM radicals
      WHERE radical IN (${List.filled(symbols.length, '?').join(',')})
      UNION
      SELECT radical, radvar, number, strokes, names, meaning, notes
      FROM radvars
      WHERE radvar IN (${List.filled(symbols.length, '?').join(',')})
      ''',
      [...symbols, ...symbols],
    );
    return rows.map(_radicalFromRow).toList(growable: false);
  }

  List<KanjiumEntry> lookalikesFor(String character) {
    final db = _requireDatabase();
    final rows = db.select(
      'SELECT similar FROM lookalikes WHERE kanji = ? LIMIT 1',
      [character],
    );
    if (rows.isEmpty) return const [];
    final similar = _splitList(rows.first['similar']);
    return [
      for (final item in similar)
        if (byCharacter(item) case final entry?) entry,
    ];
  }

  Database _requireDatabase() {
    final database = _database;
    if (database == null) {
      throw StateError('KanjiumDataset.load() must be called first');
    }
    return database;
  }

  KanjiumEntry _entryFromRow(Row row) {
    return KanjiumEntry(
      character: row['kanji'] as String,
      radical: row['radical'] as String,
      strokes: row['strokes'] as int,
      idc: row['idc'] as String,
      elements: row['elements'] as String? ?? '',
      extraElements: row['extra_elements'] as String?,
      kanjiParts: _splitList(row['kanji_parts']),
      partOf: _splitList(row['part_of']),
      meaning: row['meaning'] as String,
      frequency: row['frequency'] as int?,
      jlpt: row['jlpt'] as String?,
      grade: row['grade'] as String?,
    );
  }

  KanjiumRadical _radicalFromRow(Row row) {
    return KanjiumRadical(
      character: row['radical'] as String,
      variant: row['radvar'] as String?,
      number: row['number'] as int,
      strokes: row['strokes'] as int,
      names: row['names'] as String,
      meaning: row['meaning'] as String,
      notes: row['notes'] as String?,
    );
  }
}

List<String> _splitList(Object? value) {
  final text = value as String?;
  if (text == null || text.trim().isEmpty) return const [];
  return text
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
}
