// ===============================================================================
// [MODULE_NAME]: player_state_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Represents the state of a player during combat
// [DEPENDENCIES]: axie_card_entity.dart, board_unit_entity.dart, combat_enums.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import '../axie_card_entity.dart';
import 'board_unit_entity.dart';
import 'combat_enums.dart';

class PlayerStateEntity {
  final PlayerId id;
  final int heroHp;
  final int maxHp;
  final int currentMana;
  final int maxMana;
  final List<AxieCardEntity> hand;
  final List<AxieCardEntity> deck;
  final List<BoardUnitEntity> graveyard;
  final bool canReact;
  final bool hasCompletedMulligan;
  final List<BoardClassAffinity> landscapeDeck;

  const PlayerStateEntity({
    required this.id,
    this.heroHp = 25,
    this.maxHp = 25,
    required this.currentMana,
    required this.maxMana,
    required this.hand,
    required this.deck,
    required this.graveyard,
    required this.canReact,
    this.hasCompletedMulligan = false,
    this.landscapeDeck = const [
      BoardClassAffinity.beast,
      BoardClassAffinity.aquatic,
      BoardClassAffinity.plant,
      BoardClassAffinity.bug,
    ],
  });

  PlayerStateEntity copyWith({
    PlayerId? id,
    int? heroHp,
    int? maxHp,
    int? currentMana,
    int? maxMana,
    List<AxieCardEntity>? hand,
    List<AxieCardEntity>? deck,
    List<BoardUnitEntity>? graveyard,
    bool? canReact,
    bool? hasCompletedMulligan,
    List<BoardClassAffinity>? landscapeDeck,
  }) {
    return PlayerStateEntity(
      id: id ?? this.id,
      heroHp: heroHp ?? this.heroHp,
      maxHp: maxHp ?? this.maxHp,
      currentMana: currentMana ?? this.currentMana,
      maxMana: maxMana ?? this.maxMana,
      hand: hand ?? this.hand,
      deck: deck ?? this.deck,
      graveyard: graveyard ?? this.graveyard,
      canReact: canReact ?? this.canReact,
      hasCompletedMulligan: hasCompletedMulligan ?? this.hasCompletedMulligan,
      landscapeDeck: landscapeDeck ?? this.landscapeDeck,
    );
  }
}
