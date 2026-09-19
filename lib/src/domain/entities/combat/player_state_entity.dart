// ===============================================================================
// [MODULE_NAME]: player_state_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Represents the state of a player during combat with 7-card hand capacity and mixed unit, building, and spell cards
// [DEPENDENCIES]: axie_card_entity.dart, building_card_entity.dart, spell_card_entity.dart, combat_card.dart, board_unit_entity.dart, combat_enums.dart
// [ARCHITECTURE]: Immutable Domain Entity Pattern
// ===============================================================================

import '../axie_card_entity.dart';
import 'building_card_entity.dart';
import 'spell_card_entity.dart';
import 'combat_card.dart';
import 'board_unit_entity.dart';
import 'combat_enums.dart';

class PlayerStateEntity {
  static const int maxHandCapacity = 7;

  final PlayerId id;
  final int heroHp;
  final int maxHp;
  final int currentMana;
  final int maxMana;
  final List<CombatCard> hand;
  final List<CombatCard> deck;
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

  List<AxieCardEntity> get unitHand => hand.whereType<AxieCardEntity>().toList();
  List<BuildingCardEntity> get buildingHand => hand.whereType<BuildingCardEntity>().toList();
  List<SpellCardEntity> get spellHand => hand.whereType<SpellCardEntity>().toList();

  PlayerStateEntity copyWith({
    PlayerId? id,
    int? heroHp,
    int? maxHp,
    int? currentMana,
    int? maxMana,
    List<CombatCard>? hand,
    List<CombatCard>? deck,
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
