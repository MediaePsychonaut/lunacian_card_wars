// ===============================================================================
// [MODULE_NAME]: axie_stat_calibrator_test.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Test / Domain / Services
// [INTENT]: Exhaustive 9,072-permutation audit and lethality test suite for AxieStatCalibrator and dynamic entity scaling.
// [DEPENDENCIES]: package:flutter_test/flutter_test.dart, lib/src/domain/entities/axie_card_entity.dart, lib/src/domain/services/axie_stat_calibrator.dart, lib/src/domain/services/axie_card_factory.dart
// [ARCHITECTURE]: Pure Domain Unit Test Suite
// ===============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:lunacian_card_wars/src/domain/entities/axie_card_entity.dart';
import 'package:lunacian_card_wars/src/domain/services/axie_card_factory.dart';
import 'package:lunacian_card_wars/src/domain/services/axie_stat_calibrator.dart';

void main() {
  group('AxieStatCalibrator Unit & Exhaustive Permutation Audit', () {
    const pureClasses = [
      AxieElementalClass.bird,
      AxieElementalClass.beast,
      AxieElementalClass.aquatic,
      AxieElementalClass.bug,
      AxieElementalClass.reptile,
      AxieElementalClass.plant,
    ];

    test('9,072 exhaustive permutations: invariant conservation, clamping, and zero exceptions in < 50ms', () {
      int count = 0;
      final failures = <String>[];
      final stopwatch = Stopwatch()..start();

      for (final body in pureClasses) {
        for (final horn in pureClasses) {
          for (final back in pureClasses) {
            for (int mana = 1; mana <= 7; mana++) {
              for (int evolved = 0; evolved <= 5; evolved++) {
                count++;
                final stats = AxieStatCalibrator.calibrate(
                  manaCost: mana,
                  bodyClass: body,
                  hornClass: horn,
                  backClass: back,
                  numEvolvedParts: evolved,
                );

                // 1. Total Stat Conservation Invariant
                if (stats.atk + stats.def != stats.bstTotal) {
                  failures.add('Conservation failed for $body/$horn/$back M$mana E$evolved: ${stats.atk} + ${stats.def} != ${stats.bstTotal}');
                }

                // 2. BST Base + Delta Invariant
                final expectedBst = (9 * mana) + ((evolved * mana) ~/ 6);
                if (stats.bstTotal != expectedBst) {
                  failures.add('BST mismatch for M$mana E$evolved: got ${stats.bstTotal}, expected $expectedBst');
                }

                // 3. Clamping Bounds
                if (stats.ratioR < 0.25 || stats.ratioR > 0.75) {
                  failures.add('Ratio out of bounds: ${stats.ratioR}');
                }

                // 4. Positive Non-Zero Stats
                if (stats.atk < 1 || stats.def < 1) {
                  failures.add('Non-positive stats: ATK=${stats.atk}, DEF=${stats.def}');
                }
              }
            }
          }
        }
      }

      stopwatch.stop();
      expect(failures, isEmpty);
      expect(count, equals(9072));
      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: '9,072 calibrations took ${stopwatch.elapsedMilliseconds}ms, exceeding 50ms benchmark');
    });

    test('Lethality & Pacing Verification (No OHKO at Hero HP 25)', () {
      // At Cost 1: max ATK <= 8 << 12
      for (final body in pureClasses) {
        for (final horn in pureClasses) {
          for (final back in pureClasses) {
            for (int evolved = 0; evolved <= 6; evolved++) {
              final stats = AxieStatCalibrator.calibrate(
                manaCost: 1,
                bodyClass: body,
                hornClass: horn,
                backClass: back,
                numEvolvedParts: evolved,
              );
              expect(stats.atk, lessThanOrEqualTo(8),
                  reason: 'Cost 1 ATK exceeded 8: ${stats.atk}');
            }
          }
        }
      }

      // At Cost 2 Unevolved: max ATK <= 14 << 25
      for (final body in pureClasses) {
        for (final horn in pureClasses) {
          for (final back in pureClasses) {
            final stats = AxieStatCalibrator.calibrate(
              manaCost: 2,
              bodyClass: body,
              hornClass: horn,
              backClass: back,
              numEvolvedParts: 0,
            );
            expect(stats.atk, lessThanOrEqualTo(14),
                reason: 'Cost 2 Unevolved ATK exceeded 14: ${stats.atk}');
          }
        }
      }
    });

    test('Canonical Starter Proportional Calibrations (9 x C BST)', () {
      final buba = AxieCardFactory.bubaStarter();
      expect(buba.manaCost, equals(3));
      expect(buba.baseAtk, equals(16));
      expect(buba.baseDef, equals(11));
      expect(buba.baseAtk + buba.baseDef, equals(27));

      final olek = AxieCardFactory.olekStarter();
      expect(olek.manaCost, equals(3));
      expect(olek.baseAtk, equals(9));
      expect(olek.baseDef, equals(18));
      expect(olek.baseAtk + olek.baseDef, equals(27));

      final puffy = AxieCardFactory.puffyStarter();
      expect(puffy.manaCost, equals(3));
      expect(puffy.baseAtk, equals(14));
      expect(puffy.baseDef, equals(13));
      expect(puffy.baseAtk + puffy.baseDef, equals(27));

      final owl = AxieCardFactory.littleOwl();
      expect(owl.manaCost, equals(2));
      expect(owl.baseAtk, equals(12));
      expect(owl.baseDef, equals(6));
      expect(owl.baseAtk + owl.baseDef, equals(18));

      final bug = AxieCardFactory.pockyBug();
      expect(bug.manaCost, equals(2));
      expect(bug.baseAtk, equals(8));
      expect(bug.baseDef, equals(10));
      expect(bug.baseAtk + bug.baseDef, equals(18));

      final tri = AxieCardFactory.triSpikes();
      expect(tri.manaCost, equals(3));
      expect(tri.baseAtk, equals(9));
      expect(tri.baseDef, equals(18));
      expect(tri.baseAtk + tri.baseDef, equals(27));
    });

    test('Dynamic Mana Recalculation for Deckbuilder (recalculateForManaCost)', () {
      final buba = AxieCardFactory.bubaStarter();

      // Recalculate to Cost 1
      final bubaC1 = buba.recalculateForManaCost(1);
      expect(bubaC1.manaCost, equals(1));
      expect(bubaC1.baseAtk + bubaC1.baseDef, equals(9));

      // Recalculate to Cost 5 with 3 evolved parts
      final bubaC5E3 = buba.recalculateForManaCost(5, numEvolvedParts: 3);
      expect(bubaC5E3.manaCost, equals(5));
      expect(bubaC5E3.numEvolvedParts, equals(3));
      // BST: (9 * 5) + ((3 * 5) ~/ 6) = 45 + 2 = 47
      expect(bubaC5E3.baseAtk + bubaC5E3.baseDef, equals(47));

      // Recalculate to Cost 7 with 6 evolved parts
      final bubaC7E6 = buba.recalculateForManaCost(7, numEvolvedParts: 6);
      expect(bubaC7E6.manaCost, equals(7));
      expect(bubaC7E6.numEvolvedParts, equals(6));
      // BST: (9 * 7) + ((6 * 7) ~/ 6) = 63 + 7 = 70
      expect(bubaC7E6.baseAtk + bubaC7E6.baseDef, equals(70));
    });

    test('AxieCardEntity.fromGraphQL deserializes and calibrates correctly', () {
      final graphQLData = {
        'id': '12345',
        'name': 'Test Bird',
        'class': 'bird',
        'axpInfo': {'level': 22}, // calculatedMana = (22 ~/ 10) + 1 = 3
        'parts': [
          {'type': 'horn', 'name': 'Kestrel', 'class': 'bird', 'stage': 2},
          {'type': 'back', 'name': 'Cupid', 'class': 'bird', 'stage': 1},
          {'type': 'mouth', 'name': 'Peace Maker', 'class': 'bird', 'stage': 1},
          {'type': 'tail', 'name': 'Post Fight', 'class': 'bird', 'stage': 1},
        ],
        'stats': {
          'hp': 30,
          'speed': 61,
          'skill': 35,
          'morale': 38,
        },
      };

      final card = AxieCardEntity.fromGraphQL(graphQLData);
      expect(card.id, equals('12345'));
      expect(card.axieClass, equals(AxieElementalClass.bird));
      expect(card.manaCost, equals(3));
      expect(card.numEvolvedParts, equals(1)); // 1 part with stage >= 2
      expect(card.hornClass, equals(AxieElementalClass.bird));
      expect(card.backClass, equals(AxieElementalClass.bird));
      // BST: (9 * 3) + ((1 * 3) ~/ 6) = 27 + 0 = 27
      expect(card.baseAtk + card.baseDef, equals(27));
      expect(card.baseAtk, greaterThan(card.baseDef)); // Bird is offensive
    });
  });
}
