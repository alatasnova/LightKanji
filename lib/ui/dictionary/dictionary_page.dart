import 'package:flutter/material.dart';

import '../../dictionary/kanji_database.dart';
import '../../dictionary/models.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key, required this.database});

  final KanjiDatabase database;

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final _query = TextEditingController();
  final _levels = <int>{1, 2, 3, 4, 5};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.database.search(
      query: _query.text,
      jlptLevels: _levels,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: SearchBar(
            controller: _query,
            leading: const Icon(Icons.search),
            hintText: 'Кандзи, чтение, слово или значение',
            onChanged: (_) => setState(() {}),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              for (final level in [5, 4, 3, 2, 1])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('N$level'),
                    selected: _levels.contains(level),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _levels.add(level);
                        } else if (_levels.length > 1) {
                          _levels.remove(level);
                        }
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text('Ничего не найдено'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: results.length,
                  itemBuilder: (context, index) =>
                      _EntryCard(entry: results[index]),
                ),
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final KanjiEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readings = entry.realReadings.take(6).toList(growable: false);
    final examples = entry.examples.take(3).toList(growable: false);
    return Card(
      child: ExpansionTile(
        leading: Text(
          entry.character,
          style: theme.textTheme.headlineMedium,
        ),
        title: Text(entry.jlpt == null ? 'JLPT —' : 'JLPT N${entry.jlpt}'),
        subtitle: Text(
          readings.isEmpty
              ? 'Нет реальных чтений'
              : readings.map((reading) => reading.kana).join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final reading in readings)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${reading.word} · ${reading.kana}'),
              subtitle: Text(reading.gloss.join('; ')),
              trailing: reading.jlptLevels.isEmpty
                  ? null
                  : Wrap(
                      spacing: 4,
                      children: [
                        for (final level in reading.jlptLevels.toList()..sort())
                          Chip(
                            label: Text('N$level'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
            ),
          if (examples.isNotEmpty) ...[
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Примеры', style: theme.textTheme.titleSmall),
            ),
            for (final example in examples)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${example.word} · ${example.kana}'),
                subtitle: Text(example.gloss.join('; ')),
              ),
          ],
        ],
      ),
    );
  }
}
