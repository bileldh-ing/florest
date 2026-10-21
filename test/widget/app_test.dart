import 'package:florest/features/bag/bag_sheet.dart';
import 'package:florest/features/detail/detail_screen.dart';
import 'package:florest/features/home/home_screen.dart';
import 'package:florest/features/search/search_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('home shows the header, tab counts and first plants',
      (tester) async {
    await pumpFlorest(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('florest'), findsOneWidget);
    expect(find.text('16'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Aloe Vera'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping Outdoor switches the list', (tester) async {
    await pumpFlorest(tester);
    await tester.tap(find.text('Outdoor'));
    await settleFrames(tester, frames: 60);
    expect(find.text('Pontiatus Evo'), findsNothing); // indoor plant
    expect(find.text('Aloe Vera'), findsOneWidget);
  });

  testWidgets('+ adds to the bag, bumps the badge and offers undo',
      (tester) async {
    await pumpFlorest(tester);
    await tester.tap(find.bySemanticsLabel('Add Aloe Vera to bag').first);
    await settleFrames(tester, frames: 80);
    expect(find.bySemanticsLabel('Bag, 1 items'), findsOneWidget);
    expect(find.text('Aloe Vera added to bag'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settleFrames(tester, frames: 30);
    expect(find.bySemanticsLabel('Bag, 0 items'), findsOneWidget);
    await settleFrames(tester, frames: 200); // let the snackbar time out
  });

  testWidgets('card opens detail and Back returns home', (tester) async {
    await pumpFlorest(tester);
    await tester.tap(find.text('Pontiatus Evo'));
    await settleFrames(tester);
    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.textContaining('green rose'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await settleFrames(tester);
    expect(find.byType(DetailScreen), findsNothing);
  });

  testWidgets('detail rail selects another plant', (tester) async {
    await pumpFlorest(tester);
    await tester.tap(find.text('Aloe Vera'));
    await settleFrames(tester);
    await tester.tap(find.bySemanticsLabel('Boxwood Ball').last);
    await settleFrames(tester);
    expect(find.text('Boxwood Ball'), findsWidgets);
    expect(find.textContaining('evergreen sphere'), findsOneWidget);
  });

  testWidgets('bag sheet: stepper, total and swipe to remove', (tester) async {
    await pumpFlorest(tester);
    await tester.tap(find.bySemanticsLabel('Add Aloe Vera to bag').first);
    await settleFrames(tester, frames: 80);
    await tester.tap(find.bySemanticsLabel('Bag, 1 items'));
    await settleFrames(tester, frames: 40);
    expect(find.byType(BagSheet), findsOneWidget);
    expect(find.text(r'$18'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Add one Aloe Vera'));
    await settleFrames(tester, frames: 40);
    expect(find.bySemanticsLabel(r'Checkout, total $36'), findsOneWidget);

    await tester.drag(find.text('Aloe Vera').last, const Offset(-400, 0));
    await settleFrames(tester, frames: 60);
    expect(find.text('Your bag is empty'), findsOneWidget);
  });

  testWidgets('search filters and opens the picked plant', (tester) async {
    await pumpFlorest(tester);
    await tester.tap(find.bySemanticsLabel('Search plants'));
    await settleFrames(tester, frames: 40);
    expect(find.byType(PlantSearchSheet), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'lavender');
    await tester.pump();
    final inSheet = find.byType(PlantSearchSheet);
    expect(
      find.descendant(of: inSheet, matching: find.text('Lavender Dome')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: inSheet, matching: find.text('Aloe Vera')),
      findsNothing,
    );

    await tester.tap(
      find.descendant(of: inSheet, matching: find.text('Lavender Dome')),
    );
    await settleFrames(tester);
    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.textContaining('purple spikes'), findsOneWidget);
  });

  testWidgets('long press opens the care sheet', (tester) async {
    await pumpFlorest(tester);
    await tester.longPress(find.text('Aloe Vera'));
    await settleFrames(tester, frames: 40);
    expect(find.text('Every 3 weeks'), findsOneWidget);
    expect(find.text('Full sun'), findsOneWidget);
  });

  testWidgets('reduced motion still renders and navigates', (tester) async {
    await pumpFlorest(tester, reduceMotion: true);
    expect(find.text('Aloe Vera'), findsOneWidget);
    await tester.tap(find.text('Aloe Vera'));
    await settleFrames(tester);
    expect(find.byType(DetailScreen), findsOneWidget);
  });

  testWidgets('meets tap-target and labelling guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpFlorest(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('works on a small phone without overflow', (tester) async {
    await pumpFlorest(tester, size: const Size(360, 690));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Aloe Vera'));
    await settleFrames(tester);
    expect(tester.takeException(), isNull);
  });
}
