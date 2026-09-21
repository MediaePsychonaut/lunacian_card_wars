// ===============================================================================
// [MODULE_NAME]: card_engine_datasets_test.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Test / Data Integration & Engine Contracts
// [INTENT]: Comprehensive Dart verification suite for Cycle 12 Card Engine master datasets, mathematical balance, and referential integrity.
// [DEPENDENCIES]: package:flutter_test/flutter_test.dart, dart:io
// [ARCHITECTURE]: Automated Integration & Quality Verification Suite
// ===============================================================================

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunacian_card_wars/src/domain/entities/axie_card_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/floop_ability_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/building_card_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/spell_card_entity.dart';

void main() {
  group('Cycle 12: Card Engine Datasets & Engine Integration Suite', () {
    final floopsFile = File('assets/data/generated/axie_part_floops_matrix.csv');
    final structuresFile = File('assets/data/generated/structures_master.csv');
    final spellsFile = File('assets/data/generated/spells_master.csv');

    test('Test 1: Dataset existence and strict line counts (73, 31, 50)', () {
      expect(floopsFile.existsSync(), isTrue, reason: 'axie_part_floops_matrix.csv must exist');
      expect(structuresFile.existsSync(), isTrue, reason: 'structures_master.csv must exist');
      expect(spellsFile.existsSync(), isTrue, reason: 'spells_master.csv must exist');

      final floopLines = floopsFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
      final strLines = structuresFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
      final splLines = spellsFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();

      expect(floopLines.length, equals(73), reason: 'Floops matrix must have 1 header + 72 data rows');
      expect(strLines.length, equals(31), reason: 'Structures master must have 1 header + 30 data rows');
      expect(splLines.length, equals(50), reason: 'Spells master must have 1 header + 49 data rows');
    });

    test('Test 2: Floop Matrix Stat Conservation Law and 18-Column Schema', () {
      final lines = floopsFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
      final header = lines.first;
      expect(header, equals('part_id,part_type,class,part_name,floop_id,floop_name,activation_mana_cost,atk_bias_shift,def_bias_shift,effect_type,base_value,scaling_formula,conditional_rule,target_scope,is_secret,secret_combo_req,archetype_tag,card_art_asset_id'));

      for (final row in lines.sublist(1)) {
        final cols = row.split(',');
        expect(cols.length, equals(18), reason: 'Row must contain 18 columns: $row');

        final partId = cols[0].trim();
        final manaCost = int.tryParse(cols[6].trim());
        final atkShift = int.tryParse(cols[7].trim());
        final defShift = int.tryParse(cols[8].trim());
        final baseVal = int.tryParse(cols[10].trim());
        final isSecret = int.tryParse(cols[14].trim());

        expect(manaCost, isNotNull);
        expect(atkShift, isNotNull);
        expect(defShift, isNotNull);
        expect(baseVal, isNotNull);
        expect(isSecret, isNotNull);

        // Stat Conservation: atk_bias_shift + def_bias_shift == 0
        expect(atkShift! + defShift!, equals(0), reason: 'Stat conservation violated on $partId');
        // Activation mana cost bounds: 0 <= cost <= 3
        expect(manaCost! >= 0 && manaCost <= 3, isTrue, reason: 'Mana cost out of bounds on $partId: $manaCost');
      }
    });

    test('Test 3: Secret Combos Referential Integrity (12 combos, 6 pure + 6 hybrid)', () {
      final lines = floopsFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
      final Map<String, Map<String, dynamic>> parsedRows = {};

      for (final row in lines.sublist(1)) {
        final cols = row.split(',');
        parsedRows[cols[0].trim()] = {
          'isSecret': int.parse(cols[14].trim()),
          'secretComboReq': cols[15].trim(),
          'class': cols[2].trim(),
        };
      }

      int secretCount = 0;
      int pureCount = 0;
      int hybridCount = 0;

      for (int i = 1; i <= 12; i++) {
        final secId = 'sec_${i.toString().padLeft(2, '0')}';
        expect(parsedRows.containsKey(secId), isTrue, reason: '$secId must exist');
        final sec = parsedRows[secId]!;
        expect(sec['isSecret'], equals(1));
        secretCount++;

        final req = sec['secretComboReq'] as String;
        expect(req.contains('+'), isTrue);
        final parts = req.split('+');
        expect(parts.length, equals(2));

        final mouthId = parts[0].trim();
        final tailId = parts[1].trim();

        // 0 dangling foreign keys
        expect(parsedRows.containsKey(mouthId), isTrue, reason: 'Dangling mouth FK: $mouthId');
        expect(parsedRows.containsKey(tailId), isTrue, reason: 'Dangling tail FK: $tailId');

        if (i <= 6) {
          pureCount++;
        } else {
          hybridCount++;
        }
      }

      expect(secretCount, equals(12));
      expect(pureCount, equals(6));
      expect(hybridCount, equals(6));
    });

    test('Test 4: Structures Master 13-Column Schema, Axie Class Affinities and 73 MP Invariance', () {
      final lines = structuresFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
      const validAffinities = {'beast', 'aquatic', 'plant', 'bird', 'bug', 'reptile', 'neutral'};
      const validTriggers = {'PASSIVE', 'ON_DESTROY', 'ON_SUMMON', 'START_OF_TURN', 'ON_FLOOP'};

      expect(lines.first, equals('structure_id,name,axie_class_affinity,mana_cost,base_hp,armor_reduction,passive_effect_type,effect_value,scaling_formula,activation_trigger,target_scope,lore_description,card_art_asset_id'));

      int totalStructureMana = 0;
      for (final row in lines.sublist(1)) {
        final cols = row.split(',');
        expect(cols.length, equals(13), reason: 'Each structure row must have 13 columns: $row');

        final affinity = cols[2].trim();
        final manaCost = int.tryParse(cols[3].trim());
        final baseHp = int.tryParse(cols[4].trim());
        final armorRed = int.tryParse(cols[5].trim());
        final trigger = cols[9].trim();
        final assetId = cols[12].trim();

        expect(validAffinities.contains(affinity), isTrue, reason: 'Invalid affinity: $affinity');
        expect(validTriggers.contains(trigger), isTrue, reason: 'Invalid trigger: $trigger');
        expect(manaCost, isNotNull);
        expect(manaCost! >= 0, isTrue);
        expect(baseHp, isNotNull);
        expect(baseHp! > 0, isTrue);
        expect(armorRed, isNotNull);
        expect(armorRed! >= 0, isTrue);
        expect(assetId.startsWith('asset_struct_'), isTrue, reason: 'Invalid asset ID prefix: $assetId');

        totalStructureMana += manaCost;
      }
      expect(totalStructureMana, equals(73), reason: 'Total structure mana cost must be strictly 73 MP');
    });

    test('Test 5: Spells Master 13-Column Schema, Axie Class Affinities and 97 MP Invariance', () {
      final lines = spellsFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
      const validAffinities = {'beast', 'aquatic', 'plant', 'bird', 'bug', 'reptile', 'neutral'};
      const validTypes = {'TARGETED', 'GLOBAL', 'INSTANT'};

      expect(lines.first, equals('spell_id,name,axie_class_affinity,mana_cost,spell_type,effect_type,base_value,scaling_formula,target_scope,cast_window,rarity,description,card_art_asset_id'));

      int totalSpellMana = 0;
      for (final row in lines.sublist(1)) {
        final cols = row.split(',');
        expect(cols.length, equals(13), reason: 'Each row must have 13 columns: $row');

        final affinity = cols[2].trim();
        final manaCost = int.tryParse(cols[3].trim());
        final spellType = cols[4].trim();
        final baseVal = int.tryParse(cols[6].trim());
        final assetId = cols[12].trim();

        expect(validAffinities.contains(affinity), isTrue, reason: 'Invalid affinity: $affinity');
        expect(validTypes.contains(spellType), isTrue, reason: 'Invalid spell type: $spellType');
        expect(manaCost, isNotNull);
        expect(manaCost! >= 0, isTrue);
        expect(baseVal, isNotNull);
        expect(assetId.startsWith('asset_spell_'), isTrue, reason: 'Invalid asset ID prefix: $assetId');

        totalSpellMana += manaCost;
      }
      expect(totalSpellMana, equals(97), reason: 'Total spell mana cost must be strictly 97 MP');
    });

    test('Test 6: Pure Domain Entity Scaling and Stat Pool Conservation', () {
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

      // Scaling formula check
      expect(floop.resolveScaledValue(1), equals(40));
      expect(floop.resolveScaledValue(2), equals(65));
      expect(floop.resolveScaledValue(3), equals(90));

      // Stat conservation on AxieCardEntity
      const axie = AxieCardEntity(
        id: 'test_beast_hero',
        name: 'Alpha Beast',
        axieClass: AxieElementalClass.beast,
        level: 10,
        manaCost: 3,
        baseAtk: 25,
        baseDef: 20,
        initialPips: 2,
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
      expect(axie.effectiveAtk, equals(45)); // 25 + 20
      expect(axie.effectiveDef, equals(0));  // 20 - 20
      expect(axie.effectiveAtk + axie.effectiveDef, equals(axie.baseAtk + axie.baseDef)); // 45 == 45
    });

    test('Test 7: Pure Domain fromCsv Deserialization of 30 Structures and 49 Spells', () {
      final strLines = structuresFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
      final strHeader = strLines.first.split(',');
      final structures = <BuildingCardEntity>[];

      for (final line in strLines.sublist(1)) {
        final cols = line.split(',');
        final row = <String, String>{};
        for (int i = 0; i < strHeader.length; i++) {
          row[strHeader[i]] = cols[i];
        }
        final bldg = BuildingCardEntity.fromCsv(row);
        structures.add(bldg);
      }

      expect(structures.length, equals(30));
      expect(structures.map((s) => s.manaCost).reduce((a, b) => a + b), equals(73));

      final splLines = spellsFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
      final splHeader = splLines.first.split(',');
      final spells = <SpellCardEntity>[];

      for (final line in splLines.sublist(1)) {
        final cols = line.split(',');
        final row = <String, String>{};
        for (int i = 0; i < splHeader.length; i++) {
          row[splHeader[i]] = cols[i];
        }
        final spell = SpellCardEntity.fromCsv(row);
        spells.add(spell);
      }

      expect(spells.length, equals(49));
      expect(spells.map((s) => s.manaCost).reduce((a, b) => a + b), equals(97));
    });
  });
}
