// ===============================================================================
// [MODULE_NAME]: combat_card.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Abstract common interface for combat deck playable cards (units and buildings)
// [DEPENDENCIES]: None
// [ARCHITECTURE]: Pure Domain Entity Pattern
// ===============================================================================

abstract class CombatCard {
  String get id;
  String get name;
  int get manaCost;
}
