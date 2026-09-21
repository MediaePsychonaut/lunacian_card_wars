// ===============================================================================
// [MODULE_NAME]: vault_fallback_and_csv_catalog_test.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Test / Data & Ingestion
// [INTENT]: Unit tests verifying resilient vault offline fallback on HTTP 401, CSV catalog parsing for Spells and Structures, and deck builder rules.
// [DEPENDENCIES]: package:flutter_test/flutter_test.dart, http/testing.dart, lib/src/data/datasources/axie_marketplace_remote_datasource.dart, lib/src/data/repositories/card_catalog_repository.dart, lib/src/presentation/controllers/deck_builder_controller.dart
// [ARCHITECTURE]: Data and Integration Verification Test Suite
// ===============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lunacian_card_wars/src/data/datasources/axie_marketplace_remote_datasource.dart';
import 'package:lunacian_card_wars/src/data/repositories/card_catalog_repository.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/combat_enums.dart';
import 'package:lunacian_card_wars/src/presentation/controllers/deck_builder_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cycle 15: Resilient Vault Fallback & CSV Ingestion Suite', () {
    test('AC-01: HTTP 401/403 triggers offline fallback resolving local snapshot', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"message": "No API key found in request"}',
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final dataSource = AxieMarketplaceRemoteDataSource(client: mockClient);
      expect(dataSource.isOfflineFallbackActive, isFalse);

      final result = await dataSource.fetchAxiesByWallet('0xA167c6272b6AcaB3DB14104cb66dd422CCBE2baE');

      expect(dataSource.isOfflineFallbackActive, isTrue);
      expect(result.isNotEmpty, isTrue);
      expect(result.length, greaterThanOrEqualTo(3));
      expect(result.first['name'], isNotNull);
    });

    test('AC-01: Network timeout/exception triggers offline fallback without crashing', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network connection refused');
      });

      final dataSource = AxieMarketplaceRemoteDataSource(client: mockClient);
      final result = await dataSource.fetchAxiesByWallet('ronin:123456');

      expect(dataSource.isOfflineFallbackActive, isTrue);
      expect(result.isNotEmpty, isTrue);
    });

    test('AC-03: CardCatalogRepository parses structures_master.csv correctly', () async {
      final repo = CardCatalogRepository();
      final structures = await repo.loadStructures();

      expect(structures.length, equals(30));
      for (final s in structures) {
        expect(s.id.isNotEmpty, isTrue);
        expect(s.name.isNotEmpty, isTrue);
        expect(s.manaCost, greaterThanOrEqualTo(0));
        expect(s.maxHp, greaterThan(0));
        expect(s.axieClassAffinity, equals(BoardClassAffinity.neutral));
      }
    });

    test('AC-03: CardCatalogRepository parses spells_master.csv correctly', () async {
      final repo = CardCatalogRepository();
      final spells = await repo.loadSpells();

      expect(spells.length, equals(49));
      for (final sp in spells) {
        expect(sp.id.isNotEmpty, isTrue);
        expect(sp.name.isNotEmpty, isTrue);
        expect(sp.manaCost, greaterThanOrEqualTo(0));
        expect(sp.axieClassAffinity, equals(BoardClassAffinity.neutral));
      }
    });

    test('AC-03: DeckBuilderController allows adding structures and spells with max 2 copies limit', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(deckBuilderProvider.notifier);
      final repo = CardCatalogRepository();
      final structures = await repo.loadStructures();
      final spells = await repo.loadSpells();

      final firstStruct = structures.first;
      final firstSpell = spells.first;

      // Add structure
      final addedStruct1 = controller.addBuildingToDeck(firstStruct);
      expect(addedStruct1, isTrue);
      expect(controller.getCardCountInDeck(firstStruct.id), equals(1));

      // Add second copy of structure
      final addedStruct2 = controller.addBuildingToDeck(firstStruct);
      expect(addedStruct2, isTrue);
      expect(controller.getCardCountInDeck(firstStruct.id), equals(2));

      // Third copy must fail
      final addedStruct3 = controller.addBuildingToDeck(firstStruct);
      expect(addedStruct3, isFalse);
      expect(controller.lastErrorMessage, contains('Maximum 2 copies'));

      // Add spell
      final addedSpell1 = controller.addSpellToDeck(firstSpell);
      expect(addedSpell1, isTrue);
      expect(controller.getCardCountInDeck(firstSpell.id), equals(1));

      // Add second copy of spell
      final addedSpell2 = controller.addSpellToDeck(firstSpell);
      expect(addedSpell2, isTrue);
      expect(controller.getCardCountInDeck(firstSpell.id), equals(2));

      // Third copy must fail
      final addedSpell3 = controller.addSpellToDeck(firstSpell);
      expect(addedSpell3, isFalse);
      expect(controller.lastErrorMessage, contains('Maximum 2 copies'));

      expect(container.read(deckBuilderProvider).length, equals(4));
    });
  });
}
