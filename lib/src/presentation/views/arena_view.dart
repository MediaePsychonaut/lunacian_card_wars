// ===============================================================================
// [MODULE_NAME]: arena_view.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views
// [INTENT]: 2.5D Arena Diorama Battle Mode with living tavern game board aesthetic, 4-lane FSM telemetry inspector, visible mulligan hand selection, 7-card hand ceiling, canonical Axie floops, hand fan dock, and tactical spells.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, ../controllers/app_navigation_controller.dart, ../controllers/combat_engine_controller.dart, widgets/atmospheric_battlefield_backdrop.dart, ../../domain/entities/combat/combat_enums.dart, ../../domain/entities/combat/board_lane_entity.dart, ../../domain/entities/combat/board_unit_entity.dart, ../../domain/entities/combat/board_building_entity.dart, ../../domain/entities/combat/building_card_entity.dart, ../../domain/entities/combat/spell_card_entity.dart, ../../domain/entities/combat/floop_ability_entity.dart, ../../domain/entities/combat/combat_card.dart, ../../domain/entities/axie_card_entity.dart, ../../domain/entities/combat/game_state.dart, ../../domain/entities/combat/player_state_entity.dart
// [ARCHITECTURE]: ConsumerWidget
// ===============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/app_navigation_controller.dart';
import '../controllers/combat_engine_controller.dart';
import 'widgets/atmospheric_battlefield_backdrop.dart';
import '../../domain/entities/combat/combat_enums.dart';
import '../../domain/entities/combat/board_lane_entity.dart';
import '../../domain/entities/combat/board_unit_entity.dart';
import '../../domain/entities/combat/board_building_entity.dart';
import '../../domain/entities/combat/building_card_entity.dart';
import '../../domain/entities/combat/spell_card_entity.dart';
import '../../domain/entities/axie_card_entity.dart';
import '../../domain/entities/combat/game_state.dart';
import '../../domain/entities/combat/player_state_entity.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/services/pure_deck_catalog.dart';
import '../../data/repositories/player_decks_repository.dart';

class ArenaView extends ConsumerWidget {
  const ArenaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(combatEngineProvider);
    final controller = ref.read(combatEngineProvider.notifier);

    return AtmosphericBattlefieldBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header & Status Bar
              _buildHeader(context, ref, gameState),
              // Scrollable Body Inspector
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (gameState.winner != null) ...[
                        _buildWinnerBanner(gameState.winner!),
                        const SizedBox(height: 10),
                      ],
                      // Pre-Battle Matchup & Deck Selector Bar
                      _buildMatchupDeckSelectorBar(context, ref, controller),
                      const SizedBox(height: 12),
                      // 4-Lane Board Matrix Telemetry Table (Dual-Tile Topology + Tactical Buildings)
                      _buildBoardMatrix(gameState, controller),
                      const SizedBox(height: 12),
                      // Global Controls Bar
                      _buildGlobalControls(context, ref, gameState, controller),
                      const SizedBox(height: 12),
                      // Symmetrical Side-by-Side Dual-Player Cockpit
                      _buildDualCockpitContainer(context, gameState, controller),
                      const SizedBox(height: 12),
                      // Live Action Log / Event Stream Telemetry
                      _buildTelemetryLogConsole(gameState),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, GameState gameState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.arrow_back, color: Colors.amberAccent, size: 18),
            label: const Text(
              'Return to Main Menu',
              style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            onPressed: () => ref.read(appNavigationProvider.notifier).returnToMainMenu(),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'Round: ${gameState.roundNumber}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: Text(
                      'Phase: ${gameState.phase.name}',
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purpleAccent),
                    ),
                    child: Text(
                      'Active: ${gameState.activePlayer.name.toUpperCase()}',
                      style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.tealAccent),
                    ),
                    child: Text(
                      'Initiative: ${gameState.initiativePlayer.name.toUpperCase()}',
                      style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerBanner(PlayerId winner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amberAccent, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 24),
          const SizedBox(width: 8),
          Text(
            '🏆 WINNER: ${winner.name.toUpperCase()} 🏆',
            style: const TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchupDeckSelectorBar(
    BuildContext context,
    WidgetRef ref,
    CombatEngineController controller,
  ) {
    final p1Deck = controller.activeP1Deck ?? PureDeckCatalog.beastPureDeck();
    final p2Deck = controller.activeP2Deck ?? PureDeckCatalog.plantPureDeck();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1810).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB400).withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 750;

          final p1Badge = _buildDeckMatchupSummary(
            playerLabel: 'PLAYER 1 (YOU)',
            deck: p1Deck,
            accentColor: Colors.cyanAccent,
          );

          final p2Badge = _buildDeckMatchupSummary(
            playerLabel: 'PLAYER 2 (OPPONENT)',
            deck: p2Deck,
            accentColor: Colors.deepOrangeAccent,
          );

          final actionBtn = ElevatedButton.icon(
            icon: const Icon(Icons.style, size: 16, color: Colors.amberAccent),
            label: const Text(
              'CHOOSE DECKS / NEW MATCH',
              style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A1E00),
              side: const BorderSide(color: Color(0xFFFFB400), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _showDeckSelectionModal(context, ref, controller),
          );

          if (isCompact) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: p1Badge),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('⚔️', style: TextStyle(fontSize: 16)),
                    ),
                    Expanded(child: p2Badge),
                  ],
                ),
                const SizedBox(height: 8),
                actionBtn,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: p1Badge),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '⚔️ MATCHUP ⚔️',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    actionBtn,
                  ],
                ),
              ),
              Expanded(child: p2Badge),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeckMatchupSummary({
    required String playerLabel,
    required DeckEntity deck,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                playerLabel,
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 1.0),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${deck.cards.length} Cards',
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            deck.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 3,
            runSpacing: 2,
            children: deck.landscapes.map((affinity) {
              final color = _affinityColor(affinity);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: color.withValues(alpha: 0.6)),
                ),
                child: Text(
                  affinity.name.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showDeckSelectionModal(
    BuildContext context,
    WidgetRef ref,
    CombatEngineController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _DeckSelectionDialog(controller: controller),
    );
  }

  Widget _buildBoardMatrix(GameState gameState, CombatEngineController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 2.5D Arena Diorama ──────────────────────────────────────────────
        Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0008)
            ..rotateX(-0.22),
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3D1A00),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B5E00), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // P2 Units Row (opponent, top of board)
                _buildBoardRow(gameState, PlayerId.p2, gameState.lanes),
                // Lane Divider with Medallions
                _buildLaneDivider(),
                // P1 Units Row (player, bottom of board)
                _buildBoardRow(gameState, PlayerId.p1, gameState.lanes),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Legacy Telemetry Table (required by existing tests) ─────────────
        _buildLaneTelemetryTable(gameState),
      ],
    );
  }

  /// 2.5D diorama row for one player's units across 4 lanes.
  Widget _buildBoardRow(
    GameState gameState,
    PlayerId playerId,
    List<BoardLaneEntity> lanes,
  ) {
    final laneColors = [
      const Color(0xFFFFB800), // Beast
      const Color(0xFF00B4D8), // Aquatic
      const Color(0xFF48BB78), // Plant
      const Color(0xFFFF69B4), // Bird
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lanes.length, (i) {
        final lane = lanes[i];
        final slot = playerId == PlayerId.p1 ? lane.p1Slot : lane.p2Slot;
        final hasTile = slot.tileAffinity != null;
        final laneColor = hasTile ? _affinityColor(slot.tileAffinity!) : laneColors[i % laneColors.length];

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            constraints: const BoxConstraints(minHeight: 110),
            decoration: BoxDecoration(
              color: laneColor.withValues(alpha: hasTile ? 0.16 : 0.06),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasTile
                    ? laneColor.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.15),
                width: hasTile ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Elemental Affinity Badge (AC-04)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: hasTile ? laneColor.withValues(alpha: 0.3) : Colors.white10,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    hasTile
                        ? '${slot.tileAffinity!.name.toUpperCase()} TILE'
                        : 'NO TILE',
                    style: TextStyle(
                      color: hasTile ? laneColor : Colors.white38,
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStandee(slot.occupant, laneColor, slot.hasFloopedThisRound),
                if (slot.building != null) ...[
                  const SizedBox(height: 2),
                  Icon(
                    Icons.castle,
                    color: laneColor.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  Text(
                    slot.building!.name,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 7,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Pop-up standee for a unit in a lane cell.
  Widget _buildStandee(
    BoardUnitEntity? unit,
    Color laneColor,
    bool hasFlooped,
  ) {
    if (unit == null) {
      // Empty slot: dashed border circle
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: laneColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            '·',
            style: TextStyle(
              color: laneColor.withValues(alpha: 0.4),
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    final standeeWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: laneColor.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              unit.spriteUrl,
              height: 48,
              width: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, e, s) =>
                  Icon(Icons.smart_toy, color: laneColor, size: 40),

            ),
          ),
        ),
        const SizedBox(height: 2),
        // ATK / DEF micro-badges
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '${unit.currentAtk}',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '${unit.currentDef}',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        // Pip dots
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(unit.maxPips, (p) {
            final filled = p < unit.currentPips;
            return Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? laneColor.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.2),
              ),
            );
          }),
        ),
      ],
    );

    if (hasFlooped) {
      return Transform.rotate(
        angle: 0.61,
        child: standeeWidget,
      );
    }
    return standeeWidget;
  }

  /// Horizontal divider row with class medallions between the two player rows.
  Widget _buildLaneDivider() {
    final medallions = [
      (Icons.pets, const Color(0xFFFFB800)),
      (Icons.water_drop, const Color(0xFF00B4D8)),
      (Icons.eco, const Color(0xFF48BB78)),
      (Icons.air, const Color(0xFFFF69B4)),
    ];

    return SizedBox(
      height: 36,
      child: Row(
        children: List.generate(medallions.length, (i) {
          final (icon, color) = medallions[i];
          return Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Center divider line
                Container(
                  height: 1,
                  color: const Color(0xFF8B5E00).withValues(alpha: 0.5),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (i > 0)
                      const Text(
                        '⚔',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 4),
                    if (i < medallions.length - 1)
                      const Text(
                        '⚔',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Legacy telemetry table — preserved intact so existing tests keep passing.
  Widget _buildLaneTelemetryTable(GameState gameState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.grid_4x4, color: Colors.cyanAccent, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '4-LANE BOARD MATRIX TELEMETRY (8-LANDSCAPE DUAL-TILE TOPOLOGY)',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: gameState.lanes.map((lane) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    children: [
                      // Top: P2 Tile Badge
                      _buildTileBadge(PlayerId.p2, lane.p2Slot.tileAffinity),
                      // P2 Slot Details
                      _buildSlotTelemetry(lane.p2Slot, 'P2 SLOT', Colors.deepOrangeAccent),
                      // Middle: Clash Divider
                      _buildClashDivider(lane.laneIndex),
                      // Bottom: P1 Tile Badge
                      _buildTileBadge(PlayerId.p1, lane.p1Slot.tileAffinity),
                      // P1 Slot Details
                      _buildSlotTelemetry(lane.p1Slot, 'P1 SLOT', Colors.cyanAccent),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTileBadge(PlayerId player, BoardClassAffinity? affinity) {
    final color = _affinityColor(affinity);
    final prefix = player == PlayerId.p1 ? 'P1' : 'P2';
    final label = '[$prefix: ${affinity?.name.toUpperCase() ?? 'EMPTY'}]';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.landscape, size: 11, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _affinityColor(BoardClassAffinity? affinity) {
    switch (affinity) {
      case BoardClassAffinity.beast:
        return const Color(0xFFFFB812);
      case BoardClassAffinity.aquatic:
        return const Color(0xFF00E5FF);
      case BoardClassAffinity.plant:
        return const Color(0xFF4CAF50);
      case BoardClassAffinity.bug:
        return const Color(0xFFE91E63);
      case BoardClassAffinity.bird:
        return const Color(0xFF9C27B0);
      case BoardClassAffinity.reptile:
        return const Color(0xFFFF5722);
      case BoardClassAffinity.neutral:
        return const Color(0xFF9E9E9E);
      case null:
        return Colors.grey.shade700;
    }
  }

  Widget _buildSlotTelemetry(LaneSlot slot, String ownerLabel, Color color) {
    final BoardUnitEntity? occupant = slot.occupant;
    final BoardBuildingEntity? building = slot.building;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ownerLabel,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          if (occupant == null)
            const Text(
              'Unit: EMPTY',
              style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
            )
          else ...[
            Text(
              occupant.name,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'ATK: ${occupant.currentAtk} | DEF: ${occupant.currentDef}/${occupant.maxDef}',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Pips: ${occupant.currentPips}/${occupant.maxPips}',
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
            if (occupant.floop != null)
              Text(
                'Floop: ${occupant.floop!.name} (${occupant.floop!.manaCost}M) [${slot.hasFloopedThisRound ? "USED" : "READY"}]',
                style: TextStyle(
                  color: slot.hasFloopedThisRound ? Colors.orangeAccent : Colors.purpleAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
          const SizedBox(height: 4),
          if (building == null)
            const Text(
              'Building: NONE',
              style: TextStyle(color: Colors.white30, fontSize: 10),
            )
          else
            Text(
              '🏛️ ${building.name} (HP: ${building.currentHp}/${building.maxHp}, Arm: ${building.armorReduction} | NEUTRAL) [${building.effectType?.name.toUpperCase() ?? "NONE"}: +${building.effectValue}]',
              style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildClashDivider(int laneIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          '⚔️ LANE $laneIndex ⚔️',
          style: const TextStyle(
            color: Colors.amberAccent,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildGlobalControls(
    BuildContext context,
    WidgetRef ref,
    GameState gameState,
    CombatEngineController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.terminal, color: Colors.amberAccent, size: 16),
              SizedBox(width: 6),
              Text(
                'SYMMETRICAL DUAL-PLAYER CONSOLE',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.style, size: 13, color: Colors.amberAccent),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A2A0A),
                  foregroundColor: Colors.amberAccent,
                  side: const BorderSide(color: Color(0xFFFFB400), width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => _showDeckSelectionModal(context, ref, controller),
                label: const Text('Choose Decks', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => controller.advancePhase(),
                child: const Text('Advance Phase', style: TextStyle(fontSize: 11)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => controller.passPhase(),
                child: const Text('Pass Turn', style: TextStyle(fontSize: 11)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: () => controller.resetBattle(),
                child: const Text('Reset Battle', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDualCockpitContainer(
    BuildContext context,
    GameState gameState,
    CombatEngineController controller,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final p1Cockpit = _buildPlayerCockpit(
          gameState: gameState,
          controller: controller,
          player: gameState.p1,
          title: '=== PLAYER 1 TESTING COCKPIT ===',
          accentColor: Colors.cyanAccent,
          isP1: true,
        );

        final p2Cockpit = _buildPlayerCockpit(
          gameState: gameState,
          controller: controller,
          player: gameState.p2,
          title: '=== PLAYER 2 TESTING COCKPIT ===',
          accentColor: Colors.deepOrangeAccent,
          isP1: false,
        );

        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: p1Cockpit),
              const SizedBox(width: 12),
              Expanded(child: p2Cockpit),
            ],
          );
        } else {
          return Column(
            children: [
              p1Cockpit,
              const SizedBox(height: 12),
              p2Cockpit,
            ],
          );
        }
      },
    );
  }

  Widget _buildPlayerCockpit({
    required GameState gameState,
    required CombatEngineController controller,
    required PlayerStateEntity player,
    required String title,
    required Color accentColor,
    required bool isP1,
  }) {
    final heroHpRatio = (player.heroHp / player.maxHp).clamp(0.0, 1.0);
    final isTargetActive = gameState.activePlayer == player.id;


    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTargetActive ? accentColor : accentColor.withValues(alpha: 0.3),
          width: isTargetActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cockpit Header & Player Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isP1 ? Icons.person : Icons.smart_toy, color: accentColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              if (isTargetActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: accentColor),
                  ),
                  child: Text(
                    'ACTIVE TURN',
                    style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Vitals: Hero HP & Mana
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hero HP: ${player.heroHp}/25',
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        Text(
                          '${(heroHpRatio * 100).toInt()}%',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: heroHpRatio,
                        backgroundColor: Colors.red.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(
                          player.heroHp > 15
                              ? const Color(0xFF48BB78)
                              : player.heroHp > 7
                                  ? const Color(0xFFFFB812)
                                  : const Color(0xFFE53935),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mana: ${player.currentMana}/${player.maxMana}',
                      style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    // Mana orbs — up to 10 individual dots
                    Wrap(
                      spacing: 3,
                      runSpacing: 3,
                      children: List.generate(
                        player.maxMana.clamp(0, 10),
                        (i) {
                          final filled = i < player.currentMana;
                          return Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled
                                  ? const Color(0xFF805AD5)
                                  : Colors.white24,
                              boxShadow: filled
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF805AD5).withValues(alpha: 0.6),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),


          // Hand Gauge, Deck, Graveyard, and Mulligan Badges
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Hand: ${player.hand.length}/7 (Max: 7)',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                'Deck: ${player.deck.length}/20',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                'Graveyard: ${player.graveyard.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: player.hasCompletedMulligan
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: player.hasCompletedMulligan ? Colors.greenAccent : Colors.amberAccent,
                  ),
                ),
                child: Text(
                  player.hasCompletedMulligan ? 'Mulligan: DONE' : 'Mulligan: PENDING',
                  style: TextStyle(
                    color: player.hasCompletedMulligan ? Colors.greenAccent : Colors.amberAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 16),

          // Hand Fan Dock — visual card back display
          _buildHandFanDock(player, accentColor),
          const SizedBox(height: 8),

          // Dynamic Cockpit Actions based on TurnPhase
          if (gameState.phase == TurnPhase.turnZeroTilePlacement)
            _buildTilePlacementControls(gameState, controller, player.id, player)
          else if (gameState.phase == TurnPhase.turnZeroMulligan)
            _buildMulliganControls(gameState, controller, player.id, player)
          else
            _buildActiveCombatControls(gameState, controller, player.id, player, accentColor),
        ],
      ),
    );
  }

  /// Visual hand fan dock: shows mini card backs for cards in hand.
  Widget _buildHandFanDock(PlayerStateEntity playerState, Color accent) {
    const int maxVisible = 7;
    final handCount = playerState.hand.length;
    final displayCount = handCount.clamp(0, maxVisible);
    final overflow = handCount - maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hand (${playerState.hand.length}/7):',
          style: TextStyle(
            color: accent.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(displayCount, (i) {
              return Container(
                width: 28,
                height: 40,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2035),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accent, width: 1),
                ),
                child: Center(
                  child: Icon(
                    Icons.diamond,
                    color: accent.withValues(alpha: 0.5),
                    size: 14,
                  ),
                ),
              );
            }),
            if (overflow > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '+$overflow more',
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (handCount == 0)
              Text(
                'Empty hand',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ],
    );
  }



  Widget _buildTilePlacementControls(
    GameState gameState,
    CombatEngineController controller,
    PlayerId player,
    PlayerStateEntity playerState,
  ) {
    final placedAffinities = gameState.lanes
        .map((l) => l.getSlot(player).tileAffinity)
        .whereType<BoardClassAffinity>()
        .toList();
    final unplacedAffinities = List<BoardClassAffinity>.from(playerState.landscapeDeck);
    for (final p in placedAffinities) {
      unplacedAffinities.remove(p);
    }

    final isPlayerTurn = gameState.activePlayer == player;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Turn Zero: 8-Landscape Tile Placement (${player.name.toUpperCase()})',
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Landscapes: ${playerState.landscapeDeck.map((a) => a.name.toUpperCase()).join(', ')}',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 6),
        if (unplacedAffinities.isEmpty)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.greenAccent),
            ),
            child: Text(
              'All 4 landscape tiles placed for ${player.name.toUpperCase()}.',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPlayerTurn ? 'Select a landscape to place in a vacant lane:' : 'Awaiting turn for tile placement...',
                style: TextStyle(
                  color: isPlayerTurn ? Colors.amberAccent : Colors.white38,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: unplacedAffinities.toSet().map((affinity) {
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _affinityColor(affinity).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _affinityColor(affinity).withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          affinity.name.toUpperCase(),
                          style: TextStyle(color: _affinityColor(affinity), fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                        const SizedBox(width: 6),
                        ...List.generate(4, (laneIdx) {
                          final slotEmpty = gameState.lanes[laneIdx].getSlot(player).tileAffinity == null;
                          final canPlace = slotEmpty && isPlayerTurn;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canPlace ? Colors.blueGrey.shade700 : Colors.black26,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                minimumSize: const Size(26, 22),
                              ),
                              onPressed: canPlace
                                  ? () => controller.placeTile(player, laneIdx, affinity)
                                  : null,
                              child: Text('L$laneIdx', style: const TextStyle(fontSize: 9)),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.auto_mode, size: 13),
          label: const Text('Advance / Auto-Place Remaining Tiles', style: TextStyle(fontSize: 10)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amberAccent,
            side: const BorderSide(color: Colors.amberAccent),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          onPressed: () => controller.advancePhase(),
        ),
      ],
    );
  }

  Widget _buildMulliganControls(
    GameState gameState,
    CombatEngineController controller,
    PlayerId player,
    PlayerStateEntity playerState,
  ) {
    final isMulliganPending = !playerState.hasCompletedMulligan;
    final isActive = gameState.activePlayer == player;
    final selectionSet = player == PlayerId.p1 ? controller.p1MulliganSelection : controller.p2MulliganSelection;
    final selectedCount = selectionSet.length;

    if (!isMulliganPending) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mulligan: CONFIRMED. Waiting for opponent...',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Turn Zero: Opening Hand Mulligan (${player.name.toUpperCase()})',
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Hand: ${playerState.hand.length}/7 Cards | Status: PENDING | Select cards to discard & redraw:',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 6),
        // 4-Card Opening Hand Display with selection toggles
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: playerState.hand.map((card) {
            final isSelected = selectionSet.contains(card.id);
            String cardLabel;
            Color cardColor;
            if (card is AxieCardEntity) {
              cardLabel = '🐾 [${card.id}] ${card.name} (Cost:${card.manaCost} | A:${card.atk} D:${card.def} | ${card.affinity.name.toUpperCase()})';
              cardColor = _affinityColor(card.affinity);
            } else if (card is BuildingCardEntity) {
              cardLabel = '🏛️ [${card.id}] ${card.name} (Cost:${card.manaCost} | HP:${card.maxHp} Arm:${card.armorReduction} | NEUTRAL)';
              cardColor = Colors.tealAccent;
            } else if (card is SpellCardEntity) {
              cardLabel = '✨ [${card.id}] ${card.name} (Cost:${card.manaCost} | NEUTRAL | ${card.targetType.name} | ${card.effectType.name}:${card.effectValue})';
              cardColor = Colors.purpleAccent;
            } else {
              cardLabel = '[${card.id}] ${card.name} (Cost:${card.manaCost})';
              cardColor = Colors.amberAccent;
            }

            return InkWell(
              onTap: isActive ? () => controller.toggleMulliganCard(player, card.id) : null,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.red.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? Colors.redAccent : cardColor.withValues(alpha: 0.4),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 14,
                      color: isSelected ? Colors.redAccent : Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cardLabel,
                      style: TextStyle(
                        color: isSelected ? Colors.redAccent : Colors.white,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        decoration: isSelected ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.swap_horiz, size: 14),
              style: ElevatedButton.styleFrom(
                backgroundColor: (isMulliganPending && isActive && selectedCount > 0)
                    ? Colors.amber.shade800
                    : Colors.black26,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: (isMulliganPending && isActive && selectedCount > 0)
                  ? () => controller.confirmMulligan(player)
                  : null,
              label: Text(
                'Mulligan Selected ($selectedCount)',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.check, size: 14),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.greenAccent,
                side: BorderSide(
                  color: (isMulliganPending && isActive)
                      ? Colors.greenAccent
                      : Colors.white24,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: (isMulliganPending && isActive)
                  ? () => controller.keepEntireHand(player)
                  : null,
              label: const Text(
                'Keep Entire Hand',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveCombatControls(
    GameState gameState,
    CombatEngineController controller,
    PlayerId player,
    PlayerStateEntity playerState,
    Color accentColor,
  ) {
    final selectedCardId = controller.selectedCardFor(player);
    final selectedLane = controller.selectedLaneFor(player);
    final validation = controller.canDeploySelected(player);
    final isCardSelected = selectedCardId != null;
    final selectedCard = playerState.hand.where((c) => c.id == selectedCardId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Picker
        Row(
          children: [
            const Icon(Icons.style, size: 14, color: Colors.cyanAccent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Select Card to Deploy (${player.name.toUpperCase()} Hand: ${playerState.hand.length}/7):',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (playerState.hand.isEmpty)
          const Text('Hand is empty.', style: TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic))
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: playerState.hand.map((card) {
              final isSelected = selectedCardId == card.id;
              if (card is AxieCardEntity) {
                final color = _affinityColor(card.affinity);
                return ChoiceChip(
                  label: Text(
                    '🐾 [${card.id}] ${card.name} | ${card.affinity.name.toUpperCase()} (Cost: ${card.manaCost} | A:${card.atk} D:${card.def})',
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'monospace',
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: color,
                  backgroundColor: Colors.black45,
                  onSelected: (_) => controller.selectCardFor(player, card.id),
                );
              } else if (card is BuildingCardEntity) {
                return ChoiceChip(
                  label: Text(
                    '🏛️ [${card.id}] ${card.name} (Cost: ${card.manaCost} | HP:${card.maxHp} Arm:${card.armorReduction} | NEUTRAL | ${card.effectType.name.toUpperCase()}:+${card.effectValue})',
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.tealAccent,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'monospace',
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.tealAccent,
                  backgroundColor: Colors.black45,
                  onSelected: (_) => controller.selectCardFor(player, card.id),
                );
              } else if (card is SpellCardEntity) {
                return ChoiceChip(
                  label: Text(
                    '✨ [${card.id}] ${card.name} (Cost: ${card.manaCost} | NEUTRAL | ${card.effectType.name.toUpperCase()}: ${card.effectValue})',
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.purpleAccent,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'monospace',
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.purpleAccent,
                  backgroundColor: Colors.black45,
                  onSelected: (_) => controller.selectCardFor(player, card.id),
                );
              } else {
                return ChoiceChip(
                  label: Text(
                    '[${card.id}] ${card.name} (Cost: ${card.manaCost})',
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.amberAccent,
                  backgroundColor: Colors.black45,
                  onSelected: (_) => controller.selectCardFor(player, card.id),
                );
              }
            }).toList(),
          ),
        const SizedBox(height: 8),

        // Lane Picker
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.alt_route, size: 14, color: Colors.cyanAccent),
                const SizedBox(width: 4),
                Text(
                  'Target Lane: Lane $selectedLane',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(4, (i) {
                final isSelected = selectedLane == i;
                final slot = gameState.lanes[i].getSlot(player);
                return ChoiceChip(
                  label: Text('Lane $i (${slot.tileAffinity?.name.toUpperCase() ?? "NO TILE"})'),
                  selected: isSelected,
                  selectedColor: Colors.amberAccent.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.amberAccent : Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => controller.selectLaneFor(player, i),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Summon / Cast Button & Feedback
        Row(
          children: [
            ElevatedButton.icon(
              icon: Icon(
                selectedCard is SpellCardEntity ? Icons.auto_fix_high : Icons.upload,
                size: 13,
              ),
              label: Text(
                selectedCard is SpellCardEntity
                    ? 'Cast ${selectedCard.name} to Lane $selectedLane'
                    : 'Deploy Selected to Lane $selectedLane',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: validation.canDeploy
                    ? (selectedCard is SpellCardEntity ? Colors.purple.shade700 : Colors.teal.shade700)
                    : Colors.black38,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: validation.canDeploy ? () => controller.deploySelectedCard(player) : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                validation.reason,
                style: TextStyle(
                  color: validation.canDeploy ? Colors.greenAccent : (isCardSelected ? Colors.redAccent : Colors.white38),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Floop & Turn Pass Controls
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on, size: 14, color: Colors.purpleAccent),
                const SizedBox(width: 4),
                Text(
                  'Floop (${player.name.toUpperCase()}):',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(4, (i) {
                final slot = gameState.lanes[i].getSlot(player);
                final unit = slot.occupant;
                final floop = unit?.floop;
                final hasFlooped = slot.hasFloopedThisRound;
                final canFloop = (gameState.phase == TurnPhase.p1Turn || gameState.phase == TurnPhase.p2Turn) &&
                    gameState.activePlayer == player &&
                    unit != null &&
                    floop != null &&
                    !hasFlooped &&
                    playerState.currentMana >= floop.manaCost;

                String floopText;
                if (hasFlooped) {
                  floopText = 'L$i: USED';
                } else if (floop != null) {
                  floopText = 'Floop L$i: ${floop.name} (${floop.manaCost}M)';
                } else {
                  floopText = 'Floop L$i';
                }

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canFloop ? Colors.purple.shade700 : Colors.black26,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    minimumSize: const Size(30, 24),
                  ),
                  onPressed: canFloop ? () => controller.triggerFloop(player, i) : null,
                  child: Text(floopText, style: const TextStyle(fontSize: 9)),
                );
              }),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gameState.activePlayer == player ? Colors.indigo.shade700 : Colors.black26,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                minimumSize: const Size(50, 24),
              ),
              onPressed: gameState.activePlayer == player ? () => controller.passTurn(player) : null,
              child: Text('Pass Turn (${player.name.toUpperCase()})', style: const TextStyle(fontSize: 9)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelemetryLogConsole(GameState gameState) {
    final logs = gameState.logs.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.data_object, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'FSM STATE TELEMETRY & EVENT STREAM',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Text(
                '${gameState.logs.length} Events',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 140,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF080C10),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: logs.isEmpty
                ? const Center(
                    child: Text('No telemetry logs recorded.', style: TextStyle(color: Colors.white30, fontSize: 11)),
                  )
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          '#${gameState.logs.length - index} $log',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pre-Battle Symmetrical Deck Selection Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _DeckSelectionDialog extends ConsumerStatefulWidget {
  final CombatEngineController controller;

  const _DeckSelectionDialog({required this.controller});

  @override
  ConsumerState<_DeckSelectionDialog> createState() => _DeckSelectionDialogState();
}

class _DeckSelectionDialogState extends ConsumerState<_DeckSelectionDialog> {
  late DeckEntity _selectedP1Deck;
  late DeckEntity _selectedP2Deck;

  @override
  void initState() {
    super.initState();
    _selectedP1Deck = widget.controller.activeP1Deck ?? PureDeckCatalog.beastPureDeck();
    _selectedP2Deck = widget.controller.activeP2Deck ?? PureDeckCatalog.plantPureDeck();
  }

  Color _affinityColor(BoardClassAffinity affinity) {
    switch (affinity) {
      case BoardClassAffinity.beast:
        return const Color(0xFFFFB812);
      case BoardClassAffinity.aquatic:
        return const Color(0xFF00E5FF);
      case BoardClassAffinity.plant:
        return const Color(0xFF4CAF50);
      case BoardClassAffinity.bug:
        return const Color(0xFFE91E63);
      case BoardClassAffinity.bird:
        return const Color(0xFF9C27B0);
      case BoardClassAffinity.reptile:
        return const Color(0xFFFF5722);
      case BoardClassAffinity.neutral:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableDecks = ref.watch(availableDecksProvider);

    return Dialog(
      backgroundColor: const Color(0xFF23120B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFFB400), width: 2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.style, color: Colors.amberAccent, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚔️ PRE-BATTLE DECK SELECTION',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Choose tactical decks for Player 1 and Player 2 before starting the FSM.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF8B5E00), height: 1),
            const SizedBox(height: 12),

            // Symmetrical Deck Columns
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;
                  final p1Column = _buildDeckColumn(
                    title: 'PLAYER 1 (YOU)',
                    subtitle: 'Active: ${_selectedP1Deck.name}',
                    accentColor: Colors.cyanAccent,
                    selectedDeck: _selectedP1Deck,
                    availableDecks: availableDecks,
                    onSelect: (deck) => setState(() => _selectedP1Deck = deck),
                  );
                  final p2Column = _buildDeckColumn(
                    title: 'PLAYER 2 (OPPONENT)',
                    subtitle: 'Active: ${_selectedP2Deck.name}',
                    accentColor: Colors.deepOrangeAccent,
                    selectedDeck: _selectedP2Deck,
                    availableDecks: availableDecks,
                    onSelect: (deck) => setState(() => _selectedP2Deck = deck),
                  );

                  if (isNarrow) {
                    return DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(
                            indicatorColor: Colors.amberAccent,
                            tabs: [
                              Tab(text: 'Player 1 Deck'),
                              Tab(text: 'Player 2 Deck'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [p1Column, p2Column],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: p1Column),
                      const VerticalDivider(color: Color(0xFF8B5E00), width: 24),
                      Expanded(child: p2Column),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 14),
            const Divider(color: Color(0xFF8B5E00), height: 1),
            const SizedBox(height: 14),

            // Footer / Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                  label: const Text(
                    'INITIALIZE BATTLE WITH SELECTED DECKS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFFFB400), width: 1.5),
                    ),
                    elevation: 6,
                  ),
                  onPressed: () {
                    widget.controller.startBattleWithDecks(
                      p1Deck: _selectedP1Deck,
                      p2Deck: _selectedP2Deck,
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1E3A2F),
                        content: Text(
                          'Battle reloaded: ${_selectedP1Deck.name} vs ${_selectedP2Deck.name}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckColumn({
    required String title,
    required String subtitle,
    required Color accentColor,
    required DeckEntity selectedDeck,
    required List<DeckEntity> availableDecks,
    required ValueChanged<DeckEntity> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: availableDecks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final deck = availableDecks[index];
              final isChosen = deck.id == selectedDeck.id;

              return InkWell(
                onTap: () => onSelect(deck),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isChosen
                        ? accentColor.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isChosen ? accentColor : Colors.white.withValues(alpha: 0.12),
                      width: isChosen ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isChosen ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isChosen ? accentColor : Colors.white38,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              deck.name,
                              style: TextStyle(
                                color: isChosen ? Colors.white : Colors.white70,
                                fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: deck.isPreset
                                  ? Colors.amber.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: deck.isPreset ? Colors.amberAccent : Colors.greenAccent,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              deck.isPreset ? 'PURE PRESET' : 'CUSTOM',
                              style: TextStyle(
                                color: deck.isPreset ? Colors.amberAccent : Colors.greenAccent,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Tiles: ',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9),
                          ),
                          Wrap(
                            spacing: 3,
                            children: deck.landscapes.map((affinity) {
                              final color = _affinityColor(affinity);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
                                ),
                                child: Text(
                                  affinity.name.toUpperCase(),
                                  style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.bold),
                                ),
                              );
                            }).toList(),
                          ),
                          const Spacer(),
                          Text(
                            '${deck.cards.length}/20 Cards',
                            style: TextStyle(
                              color: deck.cards.length == 20 ? Colors.greenAccent : Colors.orangeAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
