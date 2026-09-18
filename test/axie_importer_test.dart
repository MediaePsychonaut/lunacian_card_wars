import 'package:flutter_test/flutter_test.dart';
import 'package:lunacian_card_wars/src/domain/entities/axie_card_entity.dart';
import 'package:lunacian_card_wars/src/presentation/controllers/axie_importer_controller.dart';
import 'package:lunacian_card_wars/src/data/datasources/axie_marketplace_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockFailingDataSource implements IAxieRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchAxiesByWallet(String walletAddress) async {
    throw AxieNetworkException('Failed to resolve wallet: HTTP 400', 400);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAxiesRawByIds(List<String> ids) async {
    throw AxieNetworkException('Batch query failed: HTTP 400', 400);
  }
}

class MockSuccessfulDataSource implements IAxieRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchAxiesByWallet(String walletAddress) async {
    return [
      {
        'id': '100',
        'name': 'Axie #100',
        'class': 'Beast',
        'level': 25,
        'image': 'https://assets.axieinfinity.com/axies/100/axie/axie-full-transparent.png',
        'parts': [],
        'stats': {'hp': 40, 'speed': 40, 'skill': 40, 'morale': 40}
      }
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAxiesRawByIds(List<String> ids) async {
    return ids.map((id) => {
      'id': id,
      'name': 'Axie #$id',
      'class': 'Plant',
      'level': 25,
      'image': 'https://assets.axieinfinity.com/axies/$id/axie/axie-full-transparent.png',
      'parts': [],
      'stats': {'hp': 50, 'speed': 30, 'skill': 30, 'morale': 30}
    }).toList();
  }
}

void main() {
  group('AxieCardEntity.fromGraphQL mana formula', () {
    test('Mana calculation based on level', () {
      expect(AxieCardEntity.fromGraphQL({'level': 1}).manaCost, 1);
      expect(AxieCardEntity.fromGraphQL({'level': 9}).manaCost, 1);
      expect(AxieCardEntity.fromGraphQL({'level': 10}).manaCost, 2);
      expect(AxieCardEntity.fromGraphQL({'level': 25}).manaCost, 3);
      expect(AxieCardEntity.fromGraphQL({'level': 60}).manaCost, 7);
      expect(AxieCardEntity.fromGraphQL({'level': 70}).manaCost, 7);
    });

    test('Derives level from axpInfo.level and maps mana cost', () {
      final l35 = AxieCardEntity.fromGraphQL({
        'id': '11659521',
        'axpInfo': {'level': 35},
      });
      expect(l35.level, 35);
      expect(l35.manaCost, 4);

      final l1 = AxieCardEntity.fromGraphQL({
        'id': '11659521',
        'axpInfo': {'level': 1},
      });
      expect(l1.level, 1);
      expect(l1.manaCost, 1);
    });

    test('Defaults to level 1 (mana cost 1) when level and axpInfo are omitted', () {
      final entity = AxieCardEntity.fromGraphQL({'id': '123'});
      expect(entity.level, 1);
      expect(entity.manaCost, 1);
    });
  });

  group('AxieCardEntity.fromGraphQL pip mapping', () {
    test('Initial pips based on class', () {
      expect(AxieCardEntity.fromGraphQL({'class': 'Beast'}).initialPips, 1);
      expect(AxieCardEntity.fromGraphQL({'class': 'Bug'}).initialPips, 1);
      expect(AxieCardEntity.fromGraphQL({'class': 'Plant'}).initialPips, 0);
      expect(AxieCardEntity.fromGraphQL({'class': 'Aquatic'}).initialPips, 0);
    });
  });

  group('AxieCardEntity.fromGraphQL image resolution', () {
    test('Extracts direct root image when provided', () {
      final entity = AxieCardEntity.fromGraphQL({
        'id': '11659521',
        'image': 'https://custom.image/axie.png',
      });
      expect(entity.spriteUrl, 'https://custom.image/axie.png');
      expect(entity.imageUrl, 'https://custom.image/axie.png');
    });

    test('Falls back to axie-full-transparent.png when image is empty or null', () {
      final entity = AxieCardEntity.fromGraphQL({
        'id': '11659521',
        'image': '',
      });
      expect(
        entity.spriteUrl,
        'https://assets.axieinfinity.com/axies/11659521/axie/axie-full-transparent.png',
      );
    });

    test('Constructs wsrv.nl proxy URL from resolved sprite', () {
      final entity = AxieCardEntity.fromGraphQL({
        'id': '100',
        'image': 'https://assets.axieinfinity.com/axies/100/axie/axie-full-transparent.png',
      });
      expect(
        entity.proxySpriteUrl,
        'https://wsrv.nl/?url=https%3A%2F%2Fassets.axieinfinity.com%2Faxies%2F100%2Faxie%2Faxie-full-transparent.png',
      );
    });
  });

  group('Wallet normalization & empty input guard', () {
    test('Wallet normalization logic', () {
      final ronin = 'ronin:abc123';
      final normalized = ronin.startsWith('ronin:') ? '0x${ronin.substring(6)}' : ronin;
      expect(normalized, '0xabc123');
    });

    test('Empty input returns early without state change', () async {
      final container = ProviderContainer();
      final notifier = container.read(axieImporterProvider.notifier);

      await notifier.processImportInput('');

      final state = container.read(axieImporterProvider);
      expect(state, isA<AsyncData>());
      expect(state.value, isEmpty);
    });

    test('Single-trip wallet import successfully resolves Axies', () async {
      final container = ProviderContainer(
        overrides: [
          axieRemoteDataSourceProvider.overrideWithValue(MockSuccessfulDataSource()),
        ],
      );

      final notifier = container.read(axieImporterProvider.notifier);
      await notifier.processImportInput('0xA167c6272b6AcaB3DB14104cb66dd422CCBE2baE');

      final state = container.read(axieImporterProvider);
      expect(state, isA<AsyncData<List<AxieCardEntity>>>());
      expect(state.value!.length, 1);
      expect(state.value!.first.id, '100');
      expect(state.value!.first.axieClass, AxieElementalClass.beast);
    });

    test('Error propagation transitions state to AsyncError on failure', () async {
      final container = ProviderContainer(
        overrides: [
          axieRemoteDataSourceProvider.overrideWithValue(MockFailingDataSource()),
        ],
      );

      final notifier = container.read(axieImporterProvider.notifier);
      await notifier.processImportInput('1234');

      final state = container.read(axieImporterProvider);
      expect(state, isA<AsyncError>());
      expect(state.error, isA<AxieNetworkException>());
    });
  });
}
