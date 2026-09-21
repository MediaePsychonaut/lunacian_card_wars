// ===============================================================================
// [MODULE_NAME]: deckbuilder_view.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views
// [INTENT]: Interactive Lunacian deckbuilder with Axies calibration, universal Structures and Spells catalog tabs, and active deck persistence.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, ../controllers/app_navigation_controller.dart, ../controllers/deck_builder_controller.dart, ../widgets/axie_creature_card_view.dart, ../../data/repositories/card_catalog_repository.dart, ../../domain/entities/axie_card_entity.dart, ../../domain/entities/combat/combat_card.dart, ../../domain/entities/combat/building_card_entity.dart, ../../domain/entities/combat/spell_card_entity.dart, widgets/atmospheric_battlefield_backdrop.dart
// [ARCHITECTURE]: Riverpod ConsumerStatefulWidget
// ===============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/app_navigation_controller.dart';
import '../controllers/deck_builder_controller.dart';
import '../widgets/axie_creature_card_view.dart';
import '../../data/repositories/card_catalog_repository.dart';
import '../../data/repositories/floop_catalog_repository.dart';
import '../../data/repositories/player_decks_repository.dart';
import '../../domain/entities/axie_card_entity.dart';
import '../../domain/entities/combat/combat_card.dart';
import '../../domain/entities/combat/combat_enums.dart';
import '../../domain/entities/combat/building_card_entity.dart';
import '../../domain/entities/combat/spell_card_entity.dart';
import '../../domain/services/pure_deck_catalog.dart';
import '../controllers/combat_engine_controller.dart';
import 'widgets/atmospheric_battlefield_backdrop.dart';

class DeckbuilderView extends ConsumerStatefulWidget {
  const DeckbuilderView({super.key});

  @override
  ConsumerState<DeckbuilderView> createState() => _DeckbuilderViewState();
}

class _DeckbuilderViewState extends ConsumerState<DeckbuilderView> {
  int _selectedTab = 0; // 0: Axies, 1: Structures, 2: Spells

  void _openConfigModal(BuildContext context, AxieCardEntity axie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AxieConfigSheet(axie: axie),
    );
  }

  void _openDeckSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _DeckSelectorModal(),
    );
  }

  void _promptSaveDeck(BuildContext context) {
    final controller = ref.read(deckBuilderProvider.notifier);
    final textCtrl = TextEditingController(text: controller.currentDeckName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161922),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.amberAccent, width: 1.5),
        ),
        title: const Text('SAVE DECK TO VAULT', style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a name for your deck:', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: textCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black45,
                hintText: 'e.g. My Beast Striker',
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.black),
            onPressed: () async {
              final name = textCtrl.text.trim();
              Navigator.of(ctx).pop();
              final success = await controller.saveActiveDeck(name.isNotEmpty ? name : 'Custom Deck');
              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deck "${controller.currentDeckName}" saved to Vault!'),
                    backgroundColor: Colors.teal.shade800,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'BATTLE NOW',
                      textColor: Colors.amberAccent,
                      onPressed: () {
                        final savedDeck = ref.read(availableDecksProvider).firstWhere(
                          (d) => d.id == controller.currentDeckId,
                          orElse: () => PureDeckCatalog.beastPureDeck(),
                        );
                        ref.read(combatEngineProvider.notifier).startBattleWithDecks(
                          p1Deck: savedDeck,
                          p2Deck: PureDeckCatalog.plantPureDeck(),
                        );
                        ref.read(appNavigationProvider.notifier).navigateTo(AppScreenState.play);
                      },
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(controller.lastErrorMessage ?? 'Could not save deck.'),
                    backgroundColor: Colors.red.shade800,
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openTileSelectorModal(BuildContext context, int slotIndex, Set<BoardClassAffinity> allowedClasses) {
    if (allowedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add Axie creatures to your deck first to unlock their class landscape tiles.'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TileSelectorModal(
        slotIndex: slotIndex,
        allowedClasses: allowedClasses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableAxies = ref.watch(fullAvailableAxiesProvider);
    final activeDeck = ref.watch(deckBuilderProvider);
    final deckController = ref.watch(deckBuilderProvider.notifier);
    final activeLandscapes = ref.watch(deckBuilderLandscapesProvider);
    final allowedTileClasses = deckController.axieClassesInDeck;
    final structuresAsync = ref.watch(structuresCatalogProvider);
    final spellsAsync = ref.watch(spellsCatalogProvider);

    final structuresList = structuresAsync.valueOrNull ?? [];
    final spellsList = spellsAsync.valueOrNull ?? [];

    return AtmosphericBattlefieldBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Navigation & Deck Counter Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back, color: Colors.amber),
                      label: const Text('Return to Menu', style: TextStyle(color: Colors.amber)),
                      onPressed: () => ref.read(appNavigationProvider.notifier).returnToMainMenu(),
                    ),
                    const SizedBox(width: 8),
                    // Deck Selector / Current Deck Button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.folder_special, size: 14, color: Colors.amberAccent),
                      label: Text(
                        deckController.currentDeckName.toUpperCase(),
                        style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.amberAccent, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      onPressed: () => _openDeckSelectorModal(context),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: activeDeck.length >= 20 ? Colors.green.shade800 : Colors.amber.shade900,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: activeDeck.length >= 20 ? Colors.greenAccent : Colors.amberAccent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Deck: ${activeDeck.length} / 25 (${activeDeck.length < 20 ? "Min 20" : "Ready"})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save, size: 13, color: Colors.black),
                      label: const Text('Save Deck', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      onPressed: activeDeck.length < 20 ? null : () => _promptSaveDeck(context),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<AxieElementalClass>(
                      icon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.cyanAccent),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on, size: 13, color: Colors.cyanAccent),
                            SizedBox(width: 4),
                            Text('Presets', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      color: const Color(0xFF161922),
                      onSelected: (cls) => deckController.loadCanonicalPureDeck(cls),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: AxieElementalClass.beast,
                          child: Text('Pure Beast (Hay Aggro)', style: TextStyle(color: Color(0xFFFF9800), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const PopupMenuItem(
                          value: AxieElementalClass.aquatic,
                          child: Text('Pure Aquatic (Blue Tempo)', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const PopupMenuItem(
                          value: AxieElementalClass.plant,
                          child: Text('Pure Plant (Green Sustain)', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const PopupMenuItem(
                          value: AxieElementalClass.bird,
                          child: Text('Pure Bird (Sky Backdoor)', style: TextStyle(color: Color(0xFFE91E63), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const PopupMenuItem(
                          value: AxieElementalClass.bug,
                          child: Text('Pure Bug (Swamp Disruption)', style: TextStyle(color: Color(0xFFF44336), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const PopupMenuItem(
                          value: AxieElementalClass.reptile,
                          child: Text('Pure Reptile (Sand Attrition)', style: TextStyle(color: Color(0xFF9C27B0), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_sweep, size: 13, color: Colors.redAccent),
                      label: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      onPressed: activeDeck.isEmpty ? null : () => deckController.clearDeck(),
                    ),
                  ],
                ),
              ),

              // 2. Active Deck Tray
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.view_carousel, color: Colors.amberAccent, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'ACTIVE DECK TRAY (${activeDeck.length} Cards)',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const Spacer(),
                        if (activeDeck.length < 20)
                          Text(
                            'Add ${20 - activeDeck.length} more card${20 - activeDeck.length == 1 ? "" : "s"} to deploy',
                            style: const TextStyle(color: Colors.white54, fontSize: 9),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 76,
                      child: activeDeck.isEmpty
                          ? Center(
                              child: Text(
                                'No cards in deck yet. Tap an Axie, Structure, or Spell below to configure and add.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: activeDeck.length,
                              separatorBuilder: (context, _) => const SizedBox(width: 6),
                              itemBuilder: (context, index) {
                                final card = activeDeck[index];
                                return _buildDeckCardChip(card, () {
                                  ref.read(deckBuilderProvider.notifier).removeCardFromDeck(card.id);
                                });
                              },
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // 2.5 Landscape Tiles Bar (4 Baldosas Required)
              _buildLandscapeTilesBar(activeLandscapes, allowedTileClasses, deckController),

              const SizedBox(height: 6),

              // 3. Catalog Tab Switcher (Axies, Structures, Spells)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildCatalogTab(
                      index: 0,
                      label: 'AXIES (${availableAxies.length})',
                      icon: Icons.pets,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildCatalogTab(
                      index: 1,
                      label: 'STRUCTURES (${structuresList.length})',
                      icon: Icons.castle,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildCatalogTab(
                      index: 2,
                      label: 'SPELLS (${spellsList.length})',
                      icon: Icons.auto_fix_high,
                      color: const Color(0xFFE040FB),
                    ),
                    const Spacer(),
                    Text(
                      _selectedTab == 0
                          ? '• Tap to Calibrate & Add'
                          : '• Tap card to Add to Deck',
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ),

              // 4. Catalog Grid Content
              Expanded(
                child: _buildSelectedTabContent(
                  availableAxies: availableAxies,
                  structuresAsync: structuresAsync,
                  spellsAsync: spellsAsync,
                  deckController: deckController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogTab({
    required int index,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : Colors.white24,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? color : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent({
    required List<AxieCardEntity> availableAxies,
    required AsyncValue<List<BuildingCardEntity>> structuresAsync,
    required AsyncValue<List<SpellCardEntity>> spellsAsync,
    required DeckBuilderController deckController,
  }) {
    switch (_selectedTab) {
      case 0:
        // Axies Grid
        if (availableAxies.isEmpty) {
          return Center(
            child: Text(
              'No Axies available. Check your Vault or Starters.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            childAspectRatio: 5 / 7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: availableAxies.length,
          itemBuilder: (context, index) {
            final axie = availableAxies[index];
            final isInDeck = deckController.isCardInDeck(axie.id);

            return CardWarsCardView(
              axie: axie,
              isInDeck: isInDeck,
              onTap: () => _openConfigModal(context, axie),
            );
          },
        );

      case 1:
        // Structures Grid
        return structuresAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
          error: (err, _) => Center(child: Text('Error loading structures: $err', style: const TextStyle(color: Colors.redAccent))),
          data: (structures) {
            if (structures.isEmpty) {
              return const Center(child: Text('No structures found in catalog.', style: TextStyle(color: Colors.white70)));
            }
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 5 / 7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: structures.length,
              itemBuilder: (context, index) {
                final struct = structures[index];
                final countInDeck = deckController.getCardCountInDeck(struct.id);
                return _buildStructureCard(struct, countInDeck, () {
                  final added = deckController.addBuildingToDeck(struct);
                  if (added) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added "${struct.name}" to deck!'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: Colors.teal.shade800,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(deckController.lastErrorMessage ?? 'Cannot add structure.'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.red.shade800,
                      ),
                    );
                  }
                });
              },
            );
          },
        );

      case 2:
      default:
        // Spells Grid
        return spellsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFE040FB))),
          error: (err, _) => Center(child: Text('Error loading spells: $err', style: const TextStyle(color: Colors.redAccent))),
          data: (spells) {
            if (spells.isEmpty) {
              return const Center(child: Text('No spells found in catalog.', style: TextStyle(color: Colors.white70)));
            }
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                childAspectRatio: 5 / 7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: spells.length,
              itemBuilder: (context, index) {
                final spell = spells[index];
                final countInDeck = deckController.getCardCountInDeck(spell.id);
                return _buildSpellCard(spell, countInDeck, () {
                  final added = deckController.addSpellToDeck(spell);
                  if (added) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added "${spell.name}" to deck!'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: Colors.teal.shade800,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(deckController.lastErrorMessage ?? 'Cannot add spell.'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.red.shade800,
                      ),
                    );
                  }
                });
              },
            );
          },
        );
    }
  }

  Widget _buildStructureCard(BuildingCardEntity card, int countInDeck, VoidCallback onAdd) {
    const classColor = Color(0xFF00BCD4); // Cyan for Structure
    final isMax = countInDeck >= 2;

    return AspectRatio(
      aspectRatio: 5 / 7,
      child: GestureDetector(
        onTap: isMax ? null : onAdd,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF1A222D),
            border: Border.all(color: classColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: classColor.withValues(alpha: 0.25),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Mana Gem & Name
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF805AD5),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${card.manaCost}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      card.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (countInDeck > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'x$countInDeck',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),

              // Art Window
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: classColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.castle, size: 36, color: classColor),
                        const SizedBox(height: 2),
                        Text(
                          'STRUCTURE',
                          style: TextStyle(
                            color: classColor.withValues(alpha: 0.8),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Type Tag Ribbon
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: classColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'RAINBOW STRUCTURE',
                    style: TextStyle(color: Colors.black, fontSize: 7.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Parchment Effect Box
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4ECE1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF8D6E63), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.rawEffectType.replaceAll('_', ' '),
                        style: const TextStyle(color: Colors.black87, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 1),
                      Expanded(
                        child: Text(
                          card.loreDescription.isNotEmpty ? card.loreDescription : 'Tactical lane reinforcement.',
                          style: const TextStyle(color: Colors.black87, fontSize: 7.5, height: 1.1),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Bottom Badges: HP & Armor
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF388E3C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'HP: ${card.maxHp}',
                      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ARM: ${card.armorReduction}',
                      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpellCard(SpellCardEntity card, int countInDeck, VoidCallback onAdd) {
    const classColor = Color(0xFFE040FB); // Magenta/Purple for Spell
    final isMax = countInDeck >= 2;

    return AspectRatio(
      aspectRatio: 5 / 7,
      child: GestureDetector(
        onTap: isMax ? null : onAdd,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF251A2D),
            border: Border.all(color: classColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: classColor.withValues(alpha: 0.25),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Mana Gem & Name
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF805AD5),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${card.manaCost}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      card.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (countInDeck > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade900,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'x$countInDeck',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),

              // Art Window
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: classColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_fix_high, size: 36, color: classColor),
                        const SizedBox(height: 2),
                        Text(
                          'TACTICAL SPELL',
                          style: TextStyle(
                            color: classColor.withValues(alpha: 0.8),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Type Tag Ribbon
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: classColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    'RAINBOW ${card.spellType}',
                    style: const TextStyle(color: Colors.black, fontSize: 7.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Parchment Effect Box
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4ECE1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF8D6E63), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.rawEffectType.replaceAll('_', ' '),
                        style: const TextStyle(color: Colors.black87, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 1),
                      Expanded(
                        child: Text(
                          card.description.isNotEmpty ? card.description : 'Instant magical resolution.',
                          style: const TextStyle(color: Colors.black87, fontSize: 7.5, height: 1.1),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Bottom Badges: Scope & Value
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'VAL: ${card.effectValue}',
                      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      card.targetScope.replaceAll('_', ' '),
                      style: const TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeckCardChip(CombatCard card, VoidCallback onRemove) {
    int mana = card.manaCost;
    int attack = 0;
    int defense = 0;
    String name = card.name;
    String badgeLeft = '';
    String badgeRight = '';
    Color borderColor = Colors.tealAccent.withValues(alpha: 0.5);

    if (card is AxieCardEntity) {
      attack = card.atk;
      defense = card.def;
      badgeLeft = '⚔ $attack';
      badgeRight = '🛡 $defense';
    } else if (card is BuildingCardEntity) {
      badgeLeft = 'HP ${card.maxHp}';
      badgeRight = 'ARM ${card.armorReduction}';
      borderColor = Colors.cyanAccent.withValues(alpha: 0.5);
    } else if (card is SpellCardEntity) {
      badgeLeft = 'SPELL';
      badgeRight = 'VAL ${card.effectValue}';
      borderColor = const Color(0xFFE040FB).withValues(alpha: 0.5);
    }

    return Container(
      width: 120,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF222736),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF805AD5),
                ),
                child: Center(
                  child: Text(
                    '$mana',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.redAccent),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: card is AxieCardEntity
                      ? const Color(0xFFFF6D00)
                      : (card is BuildingCardEntity ? const Color(0xFF388E3C) : const Color(0xFF6A1B9A)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  badgeLeft,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: card is AxieCardEntity
                      ? const Color(0xFF0091EA)
                      : (card is BuildingCardEntity ? const Color(0xFF1976D2) : const Color(0xFFE65100)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  badgeRight,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeTilesBar(
    List<BoardClassAffinity> activeLandscapes,
    Set<BoardClassAffinity> allowedClasses,
    DeckBuilderController deckController,
  ) {
    final isValid = activeLandscapes.length == 4 &&
        (allowedClasses.isEmpty || activeLandscapes.every((l) => allowedClasses.contains(l)));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.greenAccent.withValues(alpha: 0.6) : Colors.amber.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers, color: Colors.amberAccent, size: 14),
              const SizedBox(width: 6),
              const Text(
                'LANDSCAPE TILES (4 BALDOSAS)',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isValid ? Colors.green.shade900 : Colors.amber.shade900,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isValid ? '4 TILES VALID' : 'SELECT 4 TILES',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (allowedClasses.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.auto_awesome, size: 12, color: Colors.cyanAccent),
                  label: const Text('Auto-Fill', style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                  onPressed: () => ref.read(deckBuilderLandscapesProvider.notifier).autoFill(allowedClasses),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(4, (index) {
              final affinity = index < activeLandscapes.length
                  ? activeLandscapes[index]
                  : (allowedClasses.isNotEmpty ? allowedClasses.first : BoardClassAffinity.beast);
              final isClassAllowed = allowedClasses.isEmpty || allowedClasses.contains(affinity);
              final color = _getClassColor(affinity);

              return Expanded(
                child: GestureDetector(
                  onTap: () => _openTileSelectorModal(context, index, allowedClasses),
                  child: Container(
                    margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isClassAllowed ? color : Colors.redAccent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getClassIcon(affinity), size: 12, color: color),
                            const SizedBox(width: 4),
                            Text(
                              affinity.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Slot ${index + 1} • Tap to pick',
                          style: TextStyle(
                            color: isClassAllowed ? Colors.white54 : Colors.redAccent,
                            fontSize: 7.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getClassColor(BoardClassAffinity affinity) {
    switch (affinity) {
      case BoardClassAffinity.beast:
        return const Color(0xFFFF9800);
      case BoardClassAffinity.aquatic:
        return const Color(0xFF00BCD4);
      case BoardClassAffinity.plant:
        return const Color(0xFF4CAF50);
      case BoardClassAffinity.bird:
        return const Color(0xFFE91E63);
      case BoardClassAffinity.bug:
        return const Color(0xFFF44336);
      case BoardClassAffinity.reptile:
        return const Color(0xFF9C27B0);
      case BoardClassAffinity.neutral:
        return const Color(0xFF78909C);
    }
  }

  IconData _getClassIcon(BoardClassAffinity affinity) {
    switch (affinity) {
      case BoardClassAffinity.beast:
        return Icons.pets;
      case BoardClassAffinity.aquatic:
        return Icons.water_drop;
      case BoardClassAffinity.plant:
        return Icons.eco;
      case BoardClassAffinity.bird:
        return Icons.air;
      case BoardClassAffinity.bug:
        return Icons.bug_report;
      case BoardClassAffinity.reptile:
        return Icons.shield;
      case BoardClassAffinity.neutral:
        return Icons.circle;
    }
  }
}

class _AxieConfigSheet extends ConsumerStatefulWidget {
  final AxieCardEntity axie;

  const _AxieConfigSheet({required this.axie});

  @override
  ConsumerState<_AxieConfigSheet> createState() => _AxieConfigSheetState();
}

class _AxieConfigSheetState extends ConsumerState<_AxieConfigSheet> {
  late int _selectedMana;
  late FloopSource _selectedFloop;
  late int _maxAllowedMana;

  @override
  void initState() {
    super.initState();
    // Formula: C in [1, min(7, floor(L/10) + 1)]
    _maxAllowedMana = min(7, max(1, (widget.axie.level ~/ 10) + 1));
    _selectedMana = min(widget.axie.manaCost, _maxAllowedMana);
    _selectedFloop = widget.axie.selectedFloop;
  }

  @override
  Widget build(BuildContext context) {
    final floopRepo = ref.watch(floopCatalogRepositoryProvider);
    final selectedPartName = _selectedFloop == FloopSource.mouth ? widget.axie.mouthPartName : widget.axie.tailPartName;
    final selectedPartType = _selectedFloop == FloopSource.mouth ? 'mouth' : 'tail';
    final floop = floopRepo.getFloopForPart(
      partName: selectedPartName,
      partType: selectedPartType,
      axieClass: widget.axie.axieClass,
    );

    // Dynamic calibrated preview with authentic Floop
    final previewAxie = widget.axie.copyWith(
      selectedFloop: _selectedFloop,
      floop: floop,
    ).recalculateForManaCost(_selectedMana);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CALIBRATE ${widget.axie.name.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Calibration Controls & Card Preview Side-by-Side or Stack
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Card Preview
                  SizedBox(
                    width: 140,
                    child: CardWarsCardView(
                      axie: previewAxie,
                      customManaCost: _selectedMana,
                      customAtk: previewAxie.atk,
                      customDef: previewAxie.def,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Controls
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mana Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Mana Cost (C):',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$_selectedMana Mana',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _selectedMana.toDouble(),
                          min: 1.0,
                          max: _maxAllowedMana.toDouble(),
                          divisions: max(1, _maxAllowedMana - 1),
                          label: '$_selectedMana',
                          activeColor: const Color(0xFF1E88E5),
                          inactiveColor: Colors.white24,
                          onChanged: (val) {
                            setState(() {
                              _selectedMana = val.round();
                            });
                          },
                        ),
                        Text(
                          'Level ${widget.axie.level} cap: max $_maxAllowedMana Mana (min(7, ⌊L/10⌋ + 1))',
                          style: const TextStyle(color: Colors.white54, fontSize: 9),
                        ),
                        const SizedBox(height: 12),

                        // Floop Ability Selection (Mouth vs Tail)
                        const Text(
                          'Floop Source:',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: Text(
                                  'Mouth (${widget.axie.mouthPartName})',
                                  style: TextStyle(
                                    color: _selectedFloop == FloopSource.mouth ? Colors.black : Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: _selectedFloop == FloopSource.mouth,
                                selectedColor: Colors.amberAccent,
                                backgroundColor: Colors.white10,
                                onSelected: (_) {
                                  setState(() => _selectedFloop = FloopSource.mouth);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: Text(
                                  'Tail (${widget.axie.tailPartName})',
                                  style: TextStyle(
                                    color: _selectedFloop == FloopSource.tail ? Colors.black : Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: _selectedFloop == FloopSource.tail,
                                selectedColor: Colors.amberAccent,
                                backgroundColor: Colors.white10,
                                onSelected: (_) {
                                  setState(() => _selectedFloop = FloopSource.tail);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Authentic Floop Description Box
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF222736),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      floop.name.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.amberAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade900,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      'FLOOP ${floop.manaCost}',
                                      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                floop.description,
                                style: const TextStyle(color: Colors.white70, fontSize: 10, height: 1.2),
                              ),
                              if (floop.atkMod != 0 || floop.defMod != 0) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'Bias: ${floop.atkMod >= 0 ? '+' : ''}${floop.atkMod} ATK / ${floop.defMod >= 0 ? '+' : ''}${floop.defMod} DEF',
                                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 9),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Stats Summary (+2 pt font size increase: 12pt)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Proportional BST (9 × C): ${previewAxie.atk + previewAxie.def}',
                                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ATK: ${previewAxie.atk}  |  DEF: ${previewAxie.def}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Add to Deck Button
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('ADD TO ACTIVE DECK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final success = ref.read(deckBuilderProvider.notifier).addAxieToDeck(
                        widget.axie,
                        manaCost: _selectedMana,
                        floopSource: _selectedFloop,
                      );

                  if (success) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${widget.axie.name} (${_selectedMana}M) with [${floop.name}] to deck!'),
                        backgroundColor: Colors.teal.shade800,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else {
                    final err = ref.read(deckBuilderProvider.notifier).lastErrorMessage ?? 'Cannot add card.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: Colors.red.shade800,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckSelectorModal extends ConsumerWidget {
  const _DeckSelectorModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDecks = ref.watch(availableDecksProvider);
    final pureDecks = allDecks.where((d) => d.isPreset).toList();
    final customDecks = allDecks.where((d) => !d.isPreset).toList();
    final deckController = ref.read(deckBuilderProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'LUNACIAN DECK VAULT',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action: New Deck
              OutlinedButton.icon(
                icon: const Icon(Icons.add, color: Colors.amberAccent),
                label: const Text('Create New Empty Deck', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.amberAccent),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () {
                  deckController.clearDeck();
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 16),

              // Section: 6 Pure Decks
              const Text(
                '6 PURE ELEMENTAL DECKS (CANONICAL PRESETS)',
                style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...pureDecks.map((d) {
                return Card(
                  color: const Color(0xFF222736),
                  margin: const EdgeInsets.only(bottom: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.stars, color: Colors.amberAccent),
                    title: Text(d.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    subtitle: Text(
                      '${d.cards.length} Cards • 4 ${d.pureClass?.name.toUpperCase() ?? ""} Landscapes',
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow, size: 12),
                          label: const Text('Battle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB71C1C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onPressed: () {
                            final opponentDeck = d.id == 'deck_pure_plant'
                                ? PureDeckCatalog.beastPureDeck()
                                : PureDeckCatalog.plantPureDeck();
                            ref.read(combatEngineProvider.notifier).startBattleWithDecks(
                              p1Deck: d,
                              p2Deck: opponentDeck,
                            );
                            Navigator.of(context).pop();
                            ref.read(appNavigationProvider.notifier).navigateTo(AppScreenState.play);
                          },
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: () {
                            deckController.loadDeck(d);
                            Navigator.of(context).pop();
                          },
                          child: const Text('Load', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Section: Custom Decks (at least 10 slots supported)
              Text(
                'SAVED CUSTOM DECKS (${customDecks.length} / 10+ Slots)',
                style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (customDecks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('No custom decks saved yet. Build a deck and tap "Save Deck"!', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ),
                )
              else
                ...customDecks.map((d) {
                  return Card(
                    color: const Color(0xFF1E222D),
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.4)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.style, color: Colors.tealAccent),
                      title: Text(d.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      subtitle: Text(
                        '${d.cards.length} Cards • Landscapes: ${d.landscapes.map((l) => l.name.toUpperCase()).join(", ")}',
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow, size: 12),
                            label: const Text('Battle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB71C1C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onPressed: () {
                              final opponentDeck = d.id == 'deck_pure_plant'
                                  ? PureDeckCatalog.beastPureDeck()
                                  : PureDeckCatalog.plantPureDeck();
                              ref.read(combatEngineProvider.notifier).startBattleWithDecks(
                                p1Deck: d,
                                p2Deck: opponentDeck,
                              );
                              Navigator.of(context).pop();
                              ref.read(appNavigationProvider.notifier).navigateTo(AppScreenState.play);
                            },
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            onPressed: () {
                              deckController.loadDeck(d);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Load', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            onPressed: () async {
                              await ref.read(playerDecksRepositoryProvider).deleteCustomDeck(d.id);
                              ref.invalidate(availableDecksProvider);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileSelectorModal extends ConsumerWidget {
  final int slotIndex;
  final Set<BoardClassAffinity> allowedClasses;

  const _TileSelectorModal({
    required this.slotIndex,
    required this.allowedClasses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'SELECT TILE AFFINITY FOR SLOT ${slotIndex + 1}',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Per rule: Only elemental classes of Axies present in your deck may be selected.',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allowedClasses.map((cls) {
                return ActionChip(
                  avatar: Icon(_getClassIcon(cls), size: 14, color: Colors.black),
                  label: Text(
                    cls.name.toUpperCase(),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  backgroundColor: _getClassColor(cls),
                  onPressed: () {
                    ref.read(deckBuilderLandscapesProvider.notifier).setLandscapeAt(slotIndex, cls, allowedClasses);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getClassColor(BoardClassAffinity affinity) {
    switch (affinity) {
      case BoardClassAffinity.beast:
        return const Color(0xFFFF9800);
      case BoardClassAffinity.aquatic:
        return const Color(0xFF00BCD4);
      case BoardClassAffinity.plant:
        return const Color(0xFF4CAF50);
      case BoardClassAffinity.bird:
        return const Color(0xFFE91E63);
      case BoardClassAffinity.bug:
        return const Color(0xFFF44336);
      case BoardClassAffinity.reptile:
        return const Color(0xFF9C27B0);
      case BoardClassAffinity.neutral:
        return const Color(0xFF78909C);
    }
  }

  IconData _getClassIcon(BoardClassAffinity affinity) {
    switch (affinity) {
      case BoardClassAffinity.beast:
        return Icons.pets;
      case BoardClassAffinity.aquatic:
        return Icons.water_drop;
      case BoardClassAffinity.plant:
        return Icons.eco;
      case BoardClassAffinity.bird:
        return Icons.air;
      case BoardClassAffinity.bug:
        return Icons.bug_report;
      case BoardClassAffinity.reptile:
        return Icons.shield;
      case BoardClassAffinity.neutral:
        return Icons.circle;
    }
  }
}
