import 'package:florest/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer c;
  BagNotifier bag() => c.read(bagProvider.notifier);

  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  test('starts empty', () {
    expect(c.read(bagCountProvider), 0);
    expect(c.read(bagLinesProvider), isEmpty);
    expect(c.read(bagTotalCentsProvider), 0);
  });

  test('groups lines by plant in first-added order', () {
    bag()
      ..add('aloe_vera')
      ..add('boxwood_ball')
      ..add('aloe_vera');
    final lines = c.read(bagLinesProvider);
    expect(lines.map((l) => (l.plant.id, l.quantity)), [
      ('aloe_vera', 2),
      ('boxwood_ball', 1),
    ]);
    expect(c.read(bagCountProvider), 3);
    expect(c.read(bagTotalCentsProvider), 1800 * 2 + 5600);
  });

  test('undo removes only the latest copy', () {
    bag()
      ..add('aloe_vera')
      ..add('aloe_vera')
      ..undoAdd('aloe_vera');
    expect(c.read(bagCountProvider), 1);
    bag().undoAdd('not-in-bag');
    expect(c.read(bagCountProvider), 1);
  });

  test('removeAll and clear', () {
    bag()
      ..add('aloe_vera')
      ..add('aloe_vera')
      ..add('fern_nest')
      ..removeAll('aloe_vera');
    expect(c.read(bagProvider), ['fern_nest']);
    bag().clear();
    expect(c.read(bagCountProvider), 0);
  });

  test('unknown ids are ignored in lines', () {
    bag().add('ghost');
    expect(c.read(bagLinesProvider), isEmpty);
    expect(c.read(bagTotalCentsProvider), 0);
  });
}
