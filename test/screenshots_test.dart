@Tags(['screenshots'])
library;

import 'package:florest/features/detail/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Renders the README screenshots. Regenerate with:
///   flutter test --tags screenshots --update-goldens
void main() {
  setUpAll(loadAppFonts);

  testWidgets('home', (tester) async {
    await pumpFlorest(tester);
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/home.png'));
  });

  testWidgets('detail', (tester) async {
    await pumpFlorest(tester);
    await tester.tap(find.text('Pontiatus Evo').first);
    await settleFrames(tester);
    await warmImages(tester);
    await settleFrames(tester, frames: 30);
    expect(find.byType(DetailScreen), findsOneWidget);
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/detail.png'));
  });

  testWidgets('bag', (tester) async {
    await pumpFlorest(tester);
    for (final name in ['Aloe Vera', 'Pontiatus Evo', 'Aloe Vera']) {
      await tester.tap(find.bySemanticsLabel('Add $name to bag').first);
      await settleFrames(tester);
    }
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Bag, \d+ items$')));
    await settleFrames(tester, frames: 60);
    await warmImages(tester);
    await settleFrames(tester, frames: 10);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/bag.png'),
    );
  });

  testWidgets('search', (tester) async {
    await pumpFlorest(tester);
    await tester.tap(find.bySemanticsLabel('Search plants'));
    await settleFrames(tester, frames: 40);
    await tester.enterText(find.byType(TextField), 'sun');
    await settleFrames(tester, frames: 10);
    await warmImages(tester);
    await settleFrames(tester, frames: 10);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/search.png'),
    );
  });
}
