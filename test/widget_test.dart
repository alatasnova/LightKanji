import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_kanji/ui/trainers/trainer_scaffold.dart';

void main() {
  testWidgets('trainer shows glyph and romaji field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainerScaffold(
            prompt: 'あ',
            accepted: const ['あ'],
            onCorrect: () {},
            onError: () {},
            onReveal: () {},
            settingsBuilder: (_) => const Text('sheet'),
          ),
        ),
      ),
    );

    expect(find.text('あ'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
