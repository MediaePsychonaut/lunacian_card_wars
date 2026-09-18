// Baseline smoke test for the Lunacian Card Wars CanvasKit entry point.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunacian_card_wars/main.dart';

void main() {
  testWidgets('Baseline smoke test — app renders without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LunacianCardWarsApp()));
    expect(find.byType(LunacianCardWarsApp), findsOneWidget);
  });
}
