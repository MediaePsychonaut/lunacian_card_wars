// ===============================================================================
// [MODULE_NAME]: deck_entity.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Models a player deck composed of 20 to 25 combat cards, exactly 4 landscape tiles, validation rules, and persistence serialization.
// [DEPENDENCIES]: combat/combat_card.dart, combat/combat_enums.dart, axie_card_entity.dart, combat/building_card_entity.dart, combat/spell_card_entity.dart, combat/equatable.dart
// [ARCHITECTURE]: Pure Domain Entity Pattern
// ===============================================================================

import 'axie_card_entity.dart';
import 'combat/building_card_entity.dart';
import 'combat/combat_card.dart';
import 'combat/combat_enums.dart';
import 'combat/equatable.dart';
import 'combat/spell_card_entity.dart';

class DeckEntity extends Equatable {
  final String id;
  final String name;
  final List<CombatCard> cards;
  final List<BoardClassAffinity> landscapes;
  final bool isPreset;
  final AxieElementalClass? pureClass;

  const DeckEntity({
    required this.id,
    required this.name,
    required this.cards,
    required this.landscapes,
    this.isPreset = false,
    this.pureClass,
  });

  /// Distinct classes of Axies present in the deck
  Set<BoardClassAffinity> get axieClassesInDeck {
    final affinities = <BoardClassAffinity>{};
    for (final c in cards) {
      if (c is AxieCardEntity) {
        affinities.add(c.classAffinity);
      }
    }
    return affinities;
  }

  /// Verifies that all 4 landscapes match at least one Axie class in the deck
  bool get hasValidLandscapes {
    if (landscapes.length != 4) return false;
    final validClasses = axieClassesInDeck;
    if (validClasses.isEmpty) return true;
    return landscapes.every((l) => validClasses.contains(l));
  }

  /// Verifies that no single Floop ability appears more than 2 times
  bool get areFloopsLegal {
    final floopCounts = <String, int>{};
    for (final c in cards) {
      if (c is AxieCardEntity && c.floop != null) {
        final key = c.floop!.name.toLowerCase();
        floopCounts[key] = (floopCounts[key] ?? 0) + 1;
        if (floopCounts[key]! > 2) {
          return false;
        }
      }
    }
    return true;
  }

  /// Full tournament / match legal check (20-25 cards, 4 tiles, valid classes, <=2 floops)
  bool get isReady =>
      cards.length >= 20 &&
      cards.length <= 25 &&
      landscapes.length == 4 &&
      hasValidLandscapes &&
      areFloopsLegal;

  DeckEntity copyWith({
    String? id,
    String? name,
    List<CombatCard>? cards,
    List<BoardClassAffinity>? landscapes,
    bool? isPreset,
    AxieElementalClass? pureClass,
  }) {
    return DeckEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      cards: cards ?? this.cards,
      landscapes: landscapes ?? this.landscapes,
      isPreset: isPreset ?? this.isPreset,
      pureClass: pureClass ?? this.pureClass,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isPreset': isPreset,
      'pureClass': pureClass?.name,
      'landscapes': landscapes.map((l) => l.name).toList(),
      'cards': cards.map((c) => _serializeCard(c)).toList(),
    };
  }

  factory DeckEntity.fromJson(Map<String, dynamic> json) {
    final rawLandscapes = (json['landscapes'] as List<dynamic>?) ?? [];
    final landscapes = rawLandscapes.map((e) {
      return BoardClassAffinity.values.firstWhere(
        (a) => a.name.toLowerCase() == e.toString().toLowerCase(),
        orElse: () => BoardClassAffinity.beast,
      );
    }).toList();

    final rawCards = (json['cards'] as List<dynamic>?) ?? [];
    final cards = rawCards.map((c) => _deserializeCard(c as Map<String, dynamic>)).toList();

    final pureClassStr = json['pureClass'] as String?;
    final pureClass = pureClassStr != null
        ? AxieElementalClass.values.firstWhere(
            (c) => c.name.toLowerCase() == pureClassStr.toLowerCase(),
            orElse: () => AxieElementalClass.beast,
          )
        : null;

    return DeckEntity(
      id: json['id'] as String? ?? 'deck_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Custom Deck',
      isPreset: json['isPreset'] as bool? ?? false,
      pureClass: pureClass,
      landscapes: landscapes,
      cards: cards,
    );
  }

  static Map<String, dynamic> _serializeCard(CombatCard card) {
    if (card is AxieCardEntity) {
      return {'cardType': 'axie', 'data': card.toJson()};
    } else if (card is BuildingCardEntity) {
      return {'cardType': 'building', 'data': card.toJson()};
    } else if (card is SpellCardEntity) {
      return {'cardType': 'spell', 'data': card.toJson()};
    }
    return {'cardType': 'unknown', 'id': card.id, 'name': card.name, 'manaCost': card.manaCost};
  }

  static CombatCard _deserializeCard(Map<String, dynamic> json) {
    final type = json['cardType'] as String?;
    final data = (json['data'] as Map<String, dynamic>?) ?? json;
    if (type == 'axie') {
      return AxieCardEntity.fromJson(data);
    } else if (type == 'building') {
      return BuildingCardEntity.fromJson(data);
    } else if (type == 'spell') {
      return SpellCardEntity.fromJson(data);
    }
    return AxieCardEntity.fromJson(data);
  }

  @override
  List<Object?> get props => [id, name, cards, landscapes, isPreset, pureClass];
}
