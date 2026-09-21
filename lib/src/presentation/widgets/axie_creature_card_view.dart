// ===============================================================================
// [MODULE_NAME]: axie_creature_card_view.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Widgets
// [INTENT]: Declarative 5:7 physical creature card view with beveled elemental borders, mana gems, parchment Floop boxes, and ATK/DEF badges.
// [DEPENDENCIES]: package:flutter/material.dart, ../../domain/entities/axie_card_entity.dart, ../../domain/entities/combat/combat_enums.dart
// [ARCHITECTURE]: Stateless Presentation Component
// ===============================================================================

import 'dart:math';

import 'package:flutter/material.dart';
import '../../domain/entities/axie_card_entity.dart';
import '../../domain/entities/combat/combat_enums.dart';

class CardWarsCardView extends StatelessWidget {
  final AxieCardEntity axie;
  final bool isInDeck;
  final VoidCallback? onTap;
  final int? customManaCost;
  final int? customAtk;
  final int? customDef;

  const CardWarsCardView({
    super.key,
    required this.axie,
    this.isInDeck = false,
    this.onTap,
    this.customManaCost,
    this.customAtk,
    this.customDef,
  });

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

  @override
  Widget build(BuildContext context) {
    final classColor = _getClassColor(axie.classAffinity);
    final mana = customManaCost ?? axie.manaCost;
    final attack = max(0, customAtk ?? axie.atk);
    final defense = max(0, customDef ?? axie.def);
    final floop = axie.floop;

    return AspectRatio(
      aspectRatio: 5 / 7,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF1E222D),
            border: Border.all(color: classColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: classColor.withValues(alpha: 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main Card Layout
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar: Mana Gem & Card Name
                    Row(
                      children: [
                        // Mana Gem
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E88E5),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E88E5).withValues(alpha: 0.8),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$mana',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 2),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Card Name
                        Expanded(
                          child: Text(
                            axie.name.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Central Art Window
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: classColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          axie.spriteUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackArt(classColor);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Class Tag Ribbon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: classColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${axie.classAffinity.name.toUpperCase()} CREATURE',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Floop Text Box (Parchment Aesthetic)
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4ECE1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF8D6E63), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade900,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    'FLOOP ${floop?.manaCost ?? 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    floop?.name ?? 'Basic Strike',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Expanded(
                              child: Text(
                                floop?.description ?? 'Standard creature ability.',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 10,
                                  height: 1.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Bottom Bar: ATK & DEF Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ATK Badge (Orange)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6D00),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flash_on, color: Colors.white, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                '$attack',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // DEF Badge (Blue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0091EA),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield, color: Colors.white, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                '$defense',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // IN DECK Overlay Dimmer
              if (isInDeck)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade900,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amberAccent, width: 1.5),
                        ),
                        child: const Text(
                          'IN DECK',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackArt(Color classColor) {
    return Container(
      color: Colors.black38,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, color: classColor.withValues(alpha: 0.8), size: 36),
            const SizedBox(height: 4),
            Text(
              'AXIE #${axie.id}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
