// ===============================================================================
// [MODULE_NAME]: axie_vault_repository_test.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Test / Data / Repositories
// [INTENT]: Unit tests for AxieVaultRepository SharedPreferences persistence and entity JSON serialization.
// [DEPENDENCIES]: package:flutter_test/flutter_test.dart, package:shared_preferences/shared_preferences.dart, lib/src/data/repositories/axie_vault_repository.dart, lib/src/domain/entities/axie_card_entity.dart, lib/src/domain/entities/combat/floop_ability_entity.dart
// [ARCHITECTURE]: Pure Data & Domain Unit Test Suite
// ===============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lunacian_card_wars/src/data/repositories/axie_vault_repository.dart';
import 'package:lunacian_card_wars/src/domain/entities/axie_card_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/combat_enums.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/floop_ability_entity.dart';
import 'package:lunacian_card_wars/src/domain/services/axie_card_factory.dart';

void main() {
  group('AxieVaultRepository & Entity Serialization Tests', () {
    late SharedPreferences prefs;
    late AxieVaultRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = AxieVaultRepository(prefs: prefs);
    });

    test('FloopAbilityEntity toJson and fromJson round-trip fidelity', () {
      const floop = FloopAbilityEntity(
        id: 'test_floop_01',
        name: 'Thunder Claw',
        manaCost: 2,
        description: 'Deals 6 direct damage to opposing unit.',
        targetRequirement: FloopTargetType.laneEnemyUnit,
        effectType: FloopEffectType.directDamage,
        effectValue: 6,
        atkMod: 2,
        defMod: -2,
        scalingFormula: 'BASE + 3 * (C - 1)',
        conditionalRule: 'IF_NIGHT',
        isSecret: true,
      );

      final json = floop.toJson();
      final restored = FloopAbilityEntity.fromJson(json);

      expect(restored.id, equals(floop.id));
      expect(restored.name, equals(floop.name));
      expect(restored.manaCost, equals(floop.manaCost));
      expect(restored.description, equals(floop.description));
      expect(restored.targetRequirement, equals(floop.targetRequirement));
      expect(restored.effectType, equals(floop.effectType));
      expect(restored.effectValue, equals(floop.effectValue));
      expect(restored.atkMod, equals(floop.atkMod));
      expect(restored.defMod, equals(floop.defMod));
      expect(restored.scalingFormula, equals(floop.scalingFormula));
      expect(restored.conditionalRule, equals(floop.conditionalRule));
      expect(restored.isSecret, equals(floop.isSecret));
    });

    test('AxieCardEntity toJson and fromJson round-trip fidelity and classAffinity', () {
      final buba = AxieCardFactory.bubaStarter();
      expect(buba.classAffinity, equals(BoardClassAffinity.beast));
      expect(buba.classAffinity, equals(buba.affinity));

      final json = buba.toJson();
      expect(json['id'], equals(buba.id));
      expect(json['class'], equals('beast'));
      expect(json['baseAtk'], equals(buba.baseAtk));
      expect(json['baseDef'], equals(buba.baseDef));

      final restored = AxieCardEntity.fromJson(json);
      expect(restored.id, equals(buba.id));
      expect(restored.name, equals(buba.name));
      expect(restored.axieClass, equals(buba.axieClass));
      expect(restored.level, equals(buba.level));
      expect(restored.manaCost, equals(buba.manaCost));
      expect(restored.baseAtk, equals(buba.baseAtk));
      expect(restored.baseDef, equals(buba.baseDef));
      expect(restored.initialPips, equals(buba.initialPips));
      expect(restored.maxPips, equals(buba.maxPips));
      expect(restored.mouthPartName, equals(buba.mouthPartName));
      expect(restored.tailPartName, equals(buba.tailPartName));
      expect(restored.selectedFloop, equals(buba.selectedFloop));
      expect(restored.floop?.id, equals(buba.floop?.id));
      expect(restored.classAffinity, equals(BoardClassAffinity.beast));
    });

    test('AxieVaultRepository: initial state is empty', () async {
      final saved = await repository.getSavedAxies();
      expect(saved, isEmpty);
    });

    test('AxieVaultRepository: saves axie and verifies presence via isAxieSaved and getSavedAxies', () async {
      final buba = AxieCardFactory.bubaStarter(instanceId: 'axie_buba_vault_1');

      expect(await repository.isAxieSaved(buba.id), isFalse);

      final saveSuccess = await repository.saveAxie(buba);
      expect(saveSuccess, isTrue);

      expect(await repository.isAxieSaved(buba.id), isTrue);

      final savedList = await repository.getSavedAxies();
      expect(savedList.length, equals(1));
      expect(savedList.first.id, equals(buba.id));
      expect(savedList.first.name, equals('Buba'));
    });

    test('AxieVaultRepository: duplicate saves do not create duplicate entries', () async {
      final buba = AxieCardFactory.bubaStarter(instanceId: 'axie_buba_vault_1');

      await repository.saveAxie(buba);
      final secondSave = await repository.saveAxie(buba);
      expect(secondSave, isTrue);

      final savedList = await repository.getSavedAxies();
      expect(savedList.length, equals(1));
    });

    test('AxieVaultRepository: removes axie by id accurately', () async {
      final buba = AxieCardFactory.bubaStarter(instanceId: 'axie_buba_vault_1');
      final olek = AxieCardFactory.olekStarter(instanceId: 'axie_olek_vault_2');

      await repository.saveAxie(buba);
      await repository.saveAxie(olek);

      var list = await repository.getSavedAxies();
      expect(list.length, equals(2));

      final removeSuccess = await repository.removeAxie(buba.id);
      expect(removeSuccess, isTrue);

      list = await repository.getSavedAxies();
      expect(list.length, equals(1));
      expect(list.first.id, equals(olek.id));
      expect(await repository.isAxieSaved(buba.id), isFalse);
      expect(await repository.isAxieSaved(olek.id), isTrue);
    });

    test('AxieVaultRepository: corrupted JSON data recovers gracefully to empty list', () async {
      await prefs.setString(AxieVaultRepository.vaultStorageKey, '{not_a_valid_json_list}');
      final saved = await repository.getSavedAxies();
      expect(saved, isEmpty);
    });
  });
}
