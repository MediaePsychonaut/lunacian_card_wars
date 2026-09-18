// ===============================================================================
// [MODULE_NAME]: combat_enums.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Enums for combat system
// [DEPENDENCIES]: None
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

enum PlayerId { p1, p2 }

enum TurnPhase {
  turnZeroTilePlacement,
  turnZeroMulligan,
  roundStart,
  p1Turn,
  p2Turn,
  p1ReactiveWindow,
  clashPhase,
  roundEnd,
  gameOver
}

enum BoardClassAffinity {
  beast,
  aquatic,
  plant,
  bird,
  bug,
  reptile,
  neutral
}
