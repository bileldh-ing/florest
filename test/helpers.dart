import 'dart:io';

import 'package:florest/core/assets.dart';
import 'package:florest/data/plants_repo.dart';
import 'package:florest/features/detail/detail_screen.dart';
import 'package:florest/features/home/widgets/hero_header.dart';
import 'package:florest/features/home/widgets/plant_card.dart';
import 'package:florest/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// iPhone 14-ish logical size, the size the reference was drawn at.
const Size kPhone = Size(390, 844);

bool _fontsLoaded = false;

/// Loads the bundled Inter weights and Material Icons so text and icons render
/// as real glyphs (flutter_test uses the Ahem box font otherwise).
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  final inter = FontLoader('Inter');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    inter.addFont(rootBundle.load('assets/fonts/Inter-$w.ttf'));
  }
  await inter.load();

  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = root == null
      ? null
      : File(
          '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons != null && icons.existsSync()) {
    final bytes = await icons.readAsBytes();
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}

/// Pumps the whole app on a phone-sized surface with every plant image
/// decoded, so the first frame is the real one.
Future<void> pumpFlorest(
  WidgetTester tester, {
  bool reduceMotion = false,
  Size size = kPhone,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view
    ..physicalSize = size * 3
    ..devicePixelRatio = 3
    ..padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3)
    ..viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const ProviderScope(child: FlorestApp()));
  await warmImages(tester, width: size.width);
  await settleFrames(tester);
}

/// Advances ~1.5 s frame by frame, so timer-started entrance animations play
/// out (the idle spin never settles, so pumpAndSettle can't be used).
Future<void> settleFrames(WidgetTester tester, {int frames = 90}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Decodes every plant image at the sizes the screens ask for.
Future<void> warmImages(WidgetTester tester, {double width = 390}) async {
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    final w = width;
    final sizes = [
      PlantCard.imageSizeFor(w / 390),
      DetailScreen.bigPlantSizeFor(w),
      DetailScreen.thumbSizeFor(w),
      62 * w / 390, // bag rows
      56 * w / 390, // search results
      64 * w / 390, // care sheet
    ];
    for (final plant in PlantsRepo.all) {
      for (final size in sizes) {
        await precachePlant(context, plant.asset, size);
      }
    }
    await precachePlant(
        context, AppAssets.heroPlant, HeroHeader.plantSizeFor(w));
  });
  await tester.pump();
}
