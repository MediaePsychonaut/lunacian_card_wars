// ===============================================================================
// [MODULE_NAME]: arena_view.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views
// [INTENT]: Renders the developer-grade FSM State Graph & Telemetry Inspector with 8-landscape dual-tile matrix and symmetrical dual-player console.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, ../controllers/app_navigation_controller.dart, ../controllers/combat_engine_controller.dart, widgets/atmospheric_battlefield_backdrop.dart, ../../domain/entities/combat/combat_enums.dart, ../../domain/entities/combat/board_lane_entity.dart, ../../domain/entities/combat/board_unit_entity.dart, ../../domain/entities/combat/board_building_entity.dart, ../../domain/entities/combat/game_state.dart, ../../domain/entities/combat/player_state_entity.dart
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
import '../../domain/entities/combat/game_state.dart';
import '../../domain/entities/combat/player_state_entity.dart';

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
                      // Symmetric P2 (Opponent) Telemetry Panel
                      _buildPlayerPanel(
                        context: context,
                        player: gameState.p2,
                        title: 'Player 2 (Opponent)',
                        accentColor: Colors.deepOrangeAccent,
                        isP1: false,
                      ),
                      const SizedBox(height: 10),
                      // 4-Lane Board Matrix Telemetry Table (Dual-Tile Topology)
                      _buildBoardMatrix(gameState, controller),
                      const SizedBox(height: 10),
                      // Symmetric P1 (Player) Telemetry Panel
                      _buildPlayerPanel(
                        context: context,
                        player: gameState.p1,
                        title: 'Player 1 (Active User)',
                        accentColor: Colors.cyanAccent,
                        isP1: true,
                      ),
                      const SizedBox(height: 10),
                      // Symmetrical Dual-Player Interactive Telemetry Console
                      _buildSymmetricalConsole(gameState, controller),
                      const SizedBox(height: 10),
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

  Widget _buildPlayerPanel({
    required BuildContext context,
    required PlayerStateEntity player,
    required String title,
    required Color accentColor,
    required bool isP1,
  }) {
    final heroHpRatio = (player.heroHp / player.maxHp).clamp(0.0, 1.0);
    final manaRatio = player.maxMana > 0 ? (player.currentMana / player.maxMana).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isP1 ? Icons.person : Icons.smart_toy, color: accentColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: player.hasCompletedMulligan
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: player.hasCompletedMulligan ? Colors.greenAccent : Colors.amberAccent,
                      ),
                    ),
                    child: Text(
                      player.hasCompletedMulligan ? 'Mulligan: DONE' : 'Mulligan: PENDING',
                      style: TextStyle(
                        color: player.hasCompletedMulligan ? Colors.greenAccent : Colors.amberAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Deck: ${player.deck.length}/15',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    'Graveyard: ${player.graveyard.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
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
                        valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mana: ${player.currentMana}/${player.maxMana}',
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          player.maxMana > 0 ? '${(manaRatio * 100).toInt()}%' : '0%',
                          style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: manaRatio,
                        backgroundColor: Colors.blue.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(Colors.lightBlueAccent),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hand (${player.hand.length} cards):',
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (player.hand.isEmpty)
            const Text(
              'Hand is empty',
              style: TextStyle(color: Colors.white30, fontSize: 10, fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: player.hand.map((card) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    '[${card.id}] ${card.name} | ${card.affinity.name.toUpperCase()} (Cost: ${card.manaCost} | ATK: ${card.atk} / DEF: ${card.def})',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBoardMatrix(GameState gameState, CombatEngineController controller) {
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
          Row(
            children: [
              const Icon(Icons.grid_4x4, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '4-LANE BOARD MATRIX TELEMETRY (8-LANDSCAPE DUAL-TILE TOPOLOGY)',
                  style: const TextStyle(
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
            Text(
              'Flooped: ${occupant.hasFlooped ? "YES" : "NO"}',
              style: TextStyle(
                color: occupant.hasFlooped ? Colors.orangeAccent : Colors.white70,
                fontSize: 10,
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
              'Building: ${building.name} [HP:${building.currentHp}/${building.maxHp}|Arm:${building.armorReduction}]',
              style: const TextStyle(color: Colors.tealAccent, fontSize: 10),
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

  Widget _buildSymmetricalConsole(GameState gameState, CombatEngineController controller) {
    final selectedPlayer = controller.selectedPlayer;
    final playerState = gameState.players[selectedPlayer]!;
    final isP1 = selectedPlayer == PlayerId.p1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Console Header & Global Controls
          Wrap(
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onPressed: () => controller.advancePhase(),
                    child: const Text('Advance Phase', style: TextStyle(fontSize: 10)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onPressed: () => controller.passPhase(),
                    child: const Text('Pass Turn', style: TextStyle(fontSize: 10)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    onPressed: () => controller.resetBattle(),
                    child: const Text('Reset Battle', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Player Scope Selector (Toggle P1 / P2)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text('Console Target: ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
              ChoiceChip(
                label: Text('Player 1 (P1)${gameState.activePlayer == PlayerId.p1 ? " *" : ""}'),
                selected: isP1,
                selectedColor: Colors.cyanAccent.withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  color: isP1 ? Colors.cyanAccent : Colors.white60,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                onSelected: (_) => controller.selectPlayer(PlayerId.p1),
              ),
              ChoiceChip(
                label: Text('Player 2 (P2)${gameState.activePlayer == PlayerId.p2 ? " *" : ""}'),
                selected: !isP1,
                selectedColor: Colors.deepOrangeAccent.withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  color: !isP1 ? Colors.deepOrangeAccent : Colors.white60,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                onSelected: (_) => controller.selectPlayer(PlayerId.p2),
              ),
              Text(
                'Active Engine Player: ${gameState.activePlayer.name.toUpperCase()}',
                style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 16),

          // Dynamic Console Body based on FSM TurnPhase
          if (gameState.phase == TurnPhase.turnZeroTilePlacement)
            _buildTilePlacementControls(gameState, controller, selectedPlayer, playerState)
          else if (gameState.phase == TurnPhase.turnZeroMulligan)
            _buildMulliganControls(gameState, controller, selectedPlayer, playerState)
          else
            _buildActiveCombatControls(gameState, controller, selectedPlayer, playerState),
        ],
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Turn Zero: 8-Landscape Tile Placement (${player.name.toUpperCase()})',
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Available Landscapes in Deck: ${playerState.landscapeDeck.map((a) => a.name.toUpperCase()).join(', ')}',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 6),
        if (unplacedAffinities.isEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.greenAccent),
            ),
            child: Text(
              'All 4 landscape tiles placed for ${player.name.toUpperCase()}. Awaiting other player or advance.',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select an unplaced landscape to position in a vacant lane:', style: TextStyle(color: Colors.amberAccent, fontSize: 10)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: unplacedAffinities.toSet().map((affinity) {
                  return Container(
                    padding: const EdgeInsets.all(6),
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
                          style: TextStyle(color: _affinityColor(affinity), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        ...List.generate(4, (laneIdx) {
                          final slotEmpty = gameState.lanes[laneIdx].getSlot(player).tileAffinity == null;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: slotEmpty ? Colors.blueGrey.shade700 : Colors.black26,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                minimumSize: const Size(28, 24),
                              ),
                              onPressed: slotEmpty && (gameState.activePlayer == player)
                                  ? () => controller.placeTile(player, laneIdx, affinity)
                                  : null,
                              child: Text('L$laneIdx', style: const TextStyle(fontSize: 10)),
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
          icon: const Icon(Icons.auto_mode, size: 14),
          label: const Text('Advance / Auto-Place Remaining Tiles', style: TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.amberAccent,
            side: const BorderSide(color: Colors.amberAccent),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Turn Zero: Opening Hand Mulligan (${player.name.toUpperCase()})',
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Hand: ${playerState.hand.length} Cards | Status: ${isMulliganPending ? "PENDING" : "COMPLETE"}',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amberAccent,
                side: BorderSide(color: isMulliganPending && isActive ? Colors.amberAccent : Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: isMulliganPending && isActive && playerState.hand.isNotEmpty
                  ? () => controller.mulliganCards(player, [playerState.hand.first.id])
                  : null,
              child: Text('Mulligan ${player.name.toUpperCase()} (Swap First Card)', style: const TextStyle(fontSize: 11)),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.greenAccent,
                side: BorderSide(color: isMulliganPending && isActive ? Colors.greenAccent : Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: isMulliganPending && isActive ? () => controller.passPhase() : null,
              child: const Text('Keep Hand / Pass Mulligan', style: TextStyle(fontSize: 11)),
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
  ) {
    final validation = controller.canDeploySelected();
    final isCardSelected = controller.selectedCardId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Picker
        Row(
          children: [
            const Icon(Icons.style, size: 14, color: Colors.cyanAccent),
            const SizedBox(width: 6),
            Text(
              'Select Card to Deploy (${player.name.toUpperCase()} Hand):',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (playerState.hand.isEmpty)
          const Text('Hand is empty.', style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic))
        else
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: playerState.hand.map((card) {
              final isSelected = controller.selectedCardId == card.id;
              final color = _affinityColor(card.affinity);
              return ChoiceChip(
                label: Text(
                  '[${card.id}] ${card.name} | ${card.affinity.name.toUpperCase()} (Cost: ${card.manaCost} | A:${card.atk} D:${card.def})',
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
                onSelected: (_) => controller.selectCard(card.id),
              );
            }).toList(),
          ),
        const SizedBox(height: 10),

        // Lane Picker
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.alt_route, size: 14, color: Colors.cyanAccent),
                const SizedBox(width: 6),
                Text(
                  'Target Lane: Lane ${controller.selectedLane}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: List.generate(4, (i) {
                final isSelected = controller.selectedLane == i;
                final slot = gameState.lanes[i].getSlot(player);
                return ChoiceChip(
                  label: Text('Lane $i (${slot.tileAffinity?.name.toUpperCase() ?? "NO TILE"})'),
                  selected: isSelected,
                  selectedColor: Colors.amberAccent.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.amberAccent : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => controller.selectLane(i),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Summon Button & Feedback
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload, size: 14),
              label: Text('Deploy Selected to Lane ${controller.selectedLane}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: validation.canDeploy ? Colors.teal.shade700 : Colors.black38,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: validation.canDeploy ? () => controller.deploySelectedCard() : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                validation.reason,
                style: TextStyle(
                  color: validation.canDeploy ? Colors.greenAccent : (isCardSelected ? Colors.redAccent : Colors.white38),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Dual-player Floop Controls
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on, size: 14, color: Colors.purpleAccent),
                const SizedBox(width: 6),
                Text(
                  'Floop Activation (${player.name.toUpperCase()} Occupants):',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: List.generate(4, (i) {
                final unit = gameState.lanes[i].getSlot(player).occupant;
                final canFloop = (gameState.phase == TurnPhase.p1Turn || gameState.phase == TurnPhase.p2Turn) &&
                    gameState.activePlayer == player &&
                    unit != null &&
                    !unit.hasFlooped;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canFloop ? Colors.purple.shade700 : Colors.black26,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: canFloop ? () => controller.triggerFloop(player, i) : null,
                  child: Text('Floop ${player.name.toUpperCase()} L$i', style: const TextStyle(fontSize: 10)),
                );
              }),
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
