// ===============================================================================
// [MODULE_NAME]: deckbuilder_view.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views
// [INTENT]: Deckbuilder view supporting Axie creature, universal neutral structure, and tactical spell roster inspection.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart, ../controllers/app_navigation_controller.dart, widgets/atmospheric_battlefield_backdrop.dart
// [ARCHITECTURE]: ConsumerWidget
// ===============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/app_navigation_controller.dart';
import 'widgets/atmospheric_battlefield_backdrop.dart';

class DeckbuilderView extends ConsumerWidget {
  const DeckbuilderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AtmosphericBattlefieldBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back, color: Colors.amber),
                      label: const Text('Return to Menu', style: TextStyle(color: Colors.amber)),
                      onPressed: () => ref.read(appNavigationProvider.notifier).returnToMainMenu(),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'DECKBUILDER & ROSTER INSPECTOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'UNIVERSAL RAINBOW (NEUTRAL) AFFILIATION POLICY',
                            style: TextStyle(
                              color: Colors.amberAccent.shade100,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Under Cycle 12.2 Unification, all 30 Structures and 49 Spells possess universal Neutral / Rainbow affinity. Support cards are completely decoupled from landscape or creature elements, permitting deployment to any lane and integration into any deck archetype without artificial elemental restrictions.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: '🐾 AXIE CREATURE CARDS (CLASS AFFILIATED)',
                  subtitle: r'Calculated via deterministic 9 × C proportional BST calibration (9 × Cost + Δ_evolved).',
                  color: Colors.blueAccent,
                  chips: const [
                    'Buba (Beast / Cost 3 / BST 27: 15 ATK | 12 DEF)',
                    'Olek (Plant / Cost 3 / BST 27: 8 ATK | 19 DEF)',
                    'Puffy (Aquatic / Cost 3 / BST 27: 13 ATK | 14 DEF)',
                    'Little Owl (Bird / Cost 2 / BST 18: 11 ATK | 7 DEF)',
                    'Pocky Bug (Bug / Cost 2 / BST 18: 8 ATK | 10 DEF)',
                    'Tri Spikes (Reptile / Cost 3 / BST 27: 10 ATK | 17 DEF)',
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: '🏛️ TACTICAL STRUCTURES (UNIVERSAL NEUTRAL / RAINBOW — 30 CARDS)',
                  subtitle: 'Deployable to ANY lane without landscape tile affinity constraints. Sum = 73 MP.',
                  color: Colors.tealAccent,
                  chips: const [
                    'Astral Citadel (Cost 3 | 20 HP | 2 Arm | NEUTRAL)',
                    'Spike Spire (Cost 3 | 15 HP | 1 Arm | NEUTRAL)',
                    'Verdant Greenhouse (Cost 2 | 18 HP | 1 Arm | NEUTRAL)',
                    'Coral Sanctuary (Cost 1 | 12 HP | 0 Arm | NEUTRAL)',
                    'Abyssal Grotto (Cost 2 | 15 HP | 1 Arm | NEUTRAL)',
                    'Beast Den Stronghold (Cost 3 | 20 HP | 2 Arm | NEUTRAL)',
                    'Forest Shrine (Cost 3 | 24 HP | 2 Arm | NEUTRAL)',
                    'Outpost of Vigor (Cost 2 | 15 HP | 1 Arm | NEUTRAL)',
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: '✨ TACTICAL SPELLS (UNIVERSAL NEUTRAL / RAINBOW — 49 CARDS)',
                  subtitle: 'Castable with universal applicability across all lane units and heroes. Sum = 97 MP.',
                  color: Colors.purpleAccent,
                  chips: const [
                    'Tidal Surge (Cost 4 | NEUTRAL | Destroy Allied & Opposing Unit)',
                    'Pure Water (Cost 1 | NEUTRAL | Sacrifice Allied Unit to Draw 1)',
                    'Black Void Pendant (Cost 3 | NEUTRAL | Reduce DEF of All Units 50%)',
                    'Bloodlust Transfusion (Cost 2 | NEUTRAL | Deal 5 Dmg to Hero & Heal 5 HP)',
                    'Atias Quickening (Cost 1 | NEUTRAL | Cards Cost 1 Less Energy This Round)',
                    'Yggdrasil Blessing (Cost 2 | NEUTRAL | Draw 3 Cards from Deck)',
                    'Cerebral Bloodstorm (Cost 4 | NEUTRAL | Deal Dmg Equal to Enemy ATK)',
                    'Seed of Atia (Cost 1 | NEUTRAL | Gain 1 Energy per Allied Unit)',
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Color color,
    required List<String> chips,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
