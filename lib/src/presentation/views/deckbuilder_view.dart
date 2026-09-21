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
import '../../domain/entities/axie_card_entity.dart';
import '../../domain/entities/combat/combat_card.dart';
import '../../domain/entities/combat/building_card_entity.dart';
import '../../domain/entities/combat/spell_card_entity.dart';
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

  @override
  Widget build(BuildContext context) {
    final availableAxies = ref.watch(fullAvailableAxiesProvider);
    final activeDeck = ref.watch(deckBuilderProvider);
    final deckController = ref.watch(deckBuilderProvider.notifier);
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
                    const SizedBox(width: 12),
                    const Text(
                      'LUNACIAN DECK BUILDER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
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
                    OutlinedButton.icon(
                      icon: const Icon(Icons.flash_on, size: 13, color: Colors.cyanAccent),
                      label: const Text('Preset', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.cyanAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      onPressed: () => deckController.loadCanonicalPreset(),
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
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
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
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    // Dynamic calibrated preview
    final previewAxie = widget.axie.copyWith(
      selectedFloop: _selectedFloop,
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
                        const SizedBox(height: 10),

                        // Stats Summary
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
                                style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ATK: ${previewAxie.atk}  |  DEF: ${previewAxie.def}',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
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
                        content: Text('Added ${widget.axie.name} (${_selectedMana}M) to deck!'),
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
                        duration: const Duration(seconds: 2),
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
