// ===============================================================================
// [MODULE_NAME]: floop_matrix_and_scaling_test.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Test / Domain Verification
// [INTENT]: Unit tests verifying FloopAbilityEntity dynamic scaling formula, stat modulation biases, secret floops, and generated master datasets integrity for Cycle 12.
// [DEPENDENCIES]: package:flutter_test/flutter_test.dart, dart:io
// [ARCHITECTURE]: Pure Domain Verification Test Suite
// ===============================================================================

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunacian_card_wars/src/domain/entities/axie_card_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/floop_ability_entity.dart';

void main() {
  group('Cycle 12: FloopAbilityEntity & Dynamic Scaling Tests', () {
    test('resolveScaledValue returns base value when scalingFormula is NONE', () {
      const floop = FloopAbilityEntity(
        id: 'test_floop_none',
        name: 'Fixed Floop',
        manaCost: 1,
        description: 'Fixed effect',
        targetRequirement: FloopTargetType.laneEnemyUnit,
        effectType: FloopEffectType.directDamage,
        effectValue: 20,
        scalingFormula: 'NONE',
      );

      expect(floop.resolveScaledValue(1), equals(20));
      expect(floop.resolveScaledValue(2), equals(20));
      expect(floop.resolveScaledValue(5), equals(20));
    });

    test('resolveScaledValue calculates V_base + Delta * (AxieMana - 1) accurately', () {
      const floop = FloopAbilityEntity(
        id: 'sec_01',
        name: 'Savage Rampage',
        manaCost: 2,
        description: 'Savage Rampage',
        targetRequirement: FloopTargetType.laneEnemyUnit,
        effectType: FloopEffectType.directDamage,
        effectValue: 40,
        scalingFormula: 'BASE + (AXIE_MANA - 1) * 25',
        atkMod: 20,
        defMod: -20,
        isSecret: true,
      );

      // Mana cost 1 -> 40 + 25 * 0 = 40
      expect(floop.resolveScaledValue(1), equals(40));
      // Mana cost 2 -> 40 + 25 * 1 = 65
      expect(floop.resolveScaledValue(2), equals(65));
      // Mana cost 3 -> 40 + 25 * 2 = 90
      expect(floop.resolveScaledValue(3), equals(90));
      // Mana cost 5 -> 40 + 25 * 4 = 140
      expect(floop.resolveScaledValue(5), equals(140));
    });
  });

  group('Cycle 12: AxieCardEntity Stat Conservation Law', () {
    test('effectiveAtk and effectiveDef reflect Floop stat biases while preserving total pool', () {
      const floop = FloopAbilityEntity(
        id: 'flp_bias_test',
        name: 'Bias Test',
        manaCost: 1,
        description: 'Shift test',
        targetRequirement: FloopTargetType.self,
        effectType: FloopEffectType.buffAtk,
        effectValue: 10,
        atkMod: 15,
        defMod: -15,
      );

      const axie = AxieCardEntity(
        id: 'axie_test',
        name: 'Test Beast',
        axieClass: AxieElementalClass.beast,
        level: 10,
        manaCost: 2,
        baseAtk: 20,
        baseDef: 20,
        initialPips: 1,
        maxPips: 3,
        mouthPartName: 'Nutcracker',
        tailPartName: 'Cottontail',
        selectedFloop: FloopSource.secret,
        spriteUrl: '',
        proxySpriteUrl: '',
        rawGenes: {},
        floop: floop,
      );

      expect(axie.selectedFloop, equals(FloopSource.secret));
      expect(axie.effectiveAtk, equals(35));
      expect(axie.effectiveDef, equals(5));
      expect(axie.atk, equals(35));
      expect(axie.def, equals(5));

      // Stat Conservation: baseAtk + baseDef == effectiveAtk + effectiveDef
      expect(axie.effectiveAtk + axie.effectiveDef, equals(axie.baseAtk + axie.baseDef));
    });
  });

  group('Cycle 12: Master Datasets Integrity Tests', () {
    final floopsFile = File('assets/data/generated/axie_part_floops_matrix.csv');
    final structuresFile = File('assets/data/generated/structures_master.csv');
    final spellsFile = File('assets/data/generated/spells_master.csv');

    test('axie_part_floops_matrix.csv has exactly 73 lines and satisfies Stat Conservation', () {
      expect(floopsFile.existsSync(), isTrue);
      final lines = floopsFile
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .toList();

      expect(lines.length, equals(73), reason: 'Must contain 1 header + 72 data rows');
      expect(lines.first.startsWith('part_id,part_type,class,'), isTrue);

      final Map<String, Map<String, dynamic>> parsedRows = {};

      for (final row in lines.sublist(1)) {
        final cols = row.split(',');
        expect(cols.length, equals(18), reason: 'Row must have 18 columns: $row');

        final partId = cols[0].trim();
        final atkShift = int.parse(cols[7].trim());
        final defShift = int.parse(cols[8].trim());
        final isSecret = int.parse(cols[14].trim());
        final secretComboReq = cols[15].trim();

        // Stat Conservation Law: atk_bias_shift + def_bias_shift == 0
        expect(atkShift + defShift, equals(0), reason: 'Stat conservation failed on $partId: $row');

        parsedRows[partId] = {
          'isSecret': isSecret,
          'secretComboReq': secretComboReq,
        };
      }

      // Check all 12 secret combos have valid foreign keys
      for (int i = 1; i <= 12; i++) {
        final secId = 'sec_${i.toString().padLeft(2, '0')}';
        expect(parsedRows.containsKey(secId), isTrue, reason: '$secId must exist');
        final sec = parsedRows[secId]!;
        expect(sec['isSecret'], equals(1));

        final req = sec['secretComboReq'] as String;
        expect(req.contains('+'), isTrue);
        final parts = req.split('+');
        expect(parsedRows.containsKey(parts[0]), isTrue, reason: 'Dangling mouth FK: ${parts[0]}');
        expect(parsedRows.containsKey(parts[1]), isTrue, reason: 'Dangling tail FK: ${parts[1]}');
      }
    });

    test('structures_master.csv has exactly 31 lines', () {
      expect(structuresFile.existsSync(), isTrue);
      final lines = structuresFile
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .toList();

      expect(lines.length, equals(31), reason: 'Must contain 1 header + 30 data rows');
      expect(lines.first.startsWith('structure_id,name,landscape,'), isTrue);
    });

    test('spells_master.csv has exactly 50 lines', () {
      expect(spellsFile.existsSync(), isTrue);
      final lines = spellsFile
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .toList();

      expect(lines.length, equals(50), reason: 'Must contain 1 header + 49 data rows');
      expect(lines.first.startsWith('spell_id,name,landscape_affinity,'), isTrue);
    });
  });
}
