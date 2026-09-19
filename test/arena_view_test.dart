// ===============================================================================
// [MODULE_NAME]: arena_view_test.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Testing / Presentation
// [INTENT]: Test the ArenaView FSM Telemetry Inspector rendering, 4-lane matrix, side-by-side dual cockpits, 20-card tactical decks, building telemetry, and zero RenderFlex overflow.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:flutter_riverpod/flutter_riverpod.dart, package:lunacian_card_wars/src/presentation/views/arena_view.dart, package:lunacian_card_wars/src/presentation/controllers/combat_engine_controller.dart
// [ARCHITECTURE]: Widget Tests
// ===============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lunacian_card_wars/src/presentation/views/arena_view.dart';

class _DummyHttpOverrides extends HttpOverrides {}

void main() {
  setUpAll(() {
    HttpOverrides.global = _DummyHttpOverrides();
  });

  testWidgets('ArenaView renders FSM Telemetry Inspector with 4-lane matrix and side-by-side dual cockpits on 1920x1080', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Provide default desktop layout size
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ArenaView()),
        ),
      ),
    );

    await tester.pump();

    // 1. Verify Header & Status Badges
    expect(find.text('Return to Main Menu'), findsOneWidget);
    expect(find.text('Round: 1'), findsOneWidget);
    expect(find.text('Phase: turnZeroTilePlacement'), findsOneWidget);
    expect(find.text('Active: P1'), findsOneWidget);
    expect(find.text('Initiative: P1'), findsOneWidget);

    // 2. Verify Canonical 25 HP Hero indicators
    expect(find.textContaining('Hero HP: 25/25'), findsNWidgets(2));

    // 3. Verify Initial 20-Card Tactical Deck counts (0 in hand, 20 in deck during tile placement)
    expect(find.textContaining('Deck: 20/20'), findsNWidgets(2));

    // 4. Verify 4-Lane Board Matrix Telemetry (Dual-Tile Topology + Buildings)
    expect(find.textContaining('4-LANE BOARD MATRIX TELEMETRY (8-LANDSCAPE DUAL-TILE TOPOLOGY)'), findsOneWidget);

    // Dual tile badges per lane (initial state: EMPTY for both P1 and P2 across 4 lanes)
    expect(find.textContaining('[P1: EMPTY]'), findsNWidgets(4));
    expect(find.textContaining('[P2: EMPTY]'), findsNWidgets(4));

    // Clash Dividers
    expect(find.textContaining('LANE 0'), findsWidgets);
    expect(find.textContaining('LANE 1'), findsWidgets);
    expect(find.textContaining('LANE 2'), findsWidgets);
    expect(find.textContaining('LANE 3'), findsWidgets);

    // Unit slots: 8 empty slots (4 P1 + 4 P2)
    expect(find.text('Unit: EMPTY'), findsNWidgets(8));

    // Building slots: 8 NONE slots (4 P1 + 4 P2)
    expect(find.text('Building: NONE'), findsNWidgets(8));

    // 5. Verify Side-by-Side Dual Cockpits
    expect(find.textContaining('=== PLAYER 1 TESTING COCKPIT ==='), findsOneWidget);
    expect(find.textContaining('=== PLAYER 2 TESTING COCKPIT ==='), findsOneWidget);

    // Global step controls
    expect(find.text('Advance Phase'), findsOneWidget);
    expect(find.text('Pass Turn'), findsOneWidget);
    expect(find.text('Reset Battle'), findsOneWidget);

    // Turn Zero Tile Placement Views in both cockpits
    expect(find.textContaining('Turn Zero: 8-Landscape Tile Placement (P1)'), findsOneWidget);
    expect(find.textContaining('Turn Zero: 8-Landscape Tile Placement (P2)'), findsOneWidget);
    expect(find.textContaining('Advance / Auto-Place Remaining Tiles'), findsWidgets);

    // 6. Test interaction: Auto-Place Remaining Tiles & Transition to Mulligan
    await tester.tap(find.textContaining('Advance / Auto-Place Remaining Tiles').first);
    await tester.pump();

    // Now all 8 tiles are placed, 4 cards drawn each, and phase is turnZeroMulligan
    expect(find.text('Phase: turnZeroMulligan'), findsOneWidget);
    expect(find.textContaining('Deck: 16/20'), findsNWidgets(2));

    // Verify dual tile badges are now populated
    expect(find.textContaining('[P1: BEAST]'), findsOneWidget);
    expect(find.textContaining('[P1: AQUATIC]'), findsOneWidget);
    expect(find.textContaining('[P1: PLANT]'), findsOneWidget);
    expect(find.textContaining('[P1: BUG]'), findsOneWidget);

    // Verify Mulligan controls appear
    expect(find.textContaining('Keep Hand / Pass Mulligan'), findsWidgets);

    // 7. Advance through Mulligan to Round 1
    await tester.tap(find.text('Advance Phase'));
    await tester.pump();

    // Now in Round 1: Priority inversion gives opening initiative to P2!
    expect(find.text('Phase: p2Turn'), findsOneWidget);
    expect(find.text('Active: P2'), findsOneWidget);
    expect(find.text('Initiative: P2'), findsOneWidget);
    expect(find.textContaining('Mana: 1/1'), findsWidgets);

    // Verify Active Combat Controls appear in both cockpits
    expect(find.textContaining('Select Card to Deploy (P1 Hand):'), findsOneWidget);
    expect(find.textContaining('Select Card to Deploy (P2 Hand):'), findsOneWidget);
    expect(find.textContaining('Deploy Selected to Lane 0'), findsWidgets);

    // 8. Verify Monospace Telemetry Event Stream
    expect(find.textContaining('FSM STATE TELEMETRY & EVENT STREAM'), findsOneWidget);

    // Check no RenderFlex overflow exception was thrown
    expect(tester.binding.takeException(), isNull);
  });

  testWidgets('ArenaView renders without RenderFlex overflow on 800x600 compact viewport', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ArenaView()),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Return to Main Menu'), findsOneWidget);
    expect(find.textContaining('Hero HP: 25/25'), findsNWidgets(2));
    expect(find.textContaining('4-LANE BOARD MATRIX TELEMETRY'), findsOneWidget);
    expect(find.textContaining('SYMMETRICAL DUAL-PLAYER CONSOLE'), findsOneWidget);
    expect(find.textContaining('=== PLAYER 1 TESTING COCKPIT ==='), findsOneWidget);
    expect(find.textContaining('=== PLAYER 2 TESTING COCKPIT ==='), findsOneWidget);

    expect(tester.binding.takeException(), isNull);
  });
}
