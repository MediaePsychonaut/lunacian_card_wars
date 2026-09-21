// ===============================================================================
// [MODULE_NAME]: axie_importer_controller.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / State Management
// [INTENT]: Orchestrates single and wallet Axie ingestion.
// [DEPENDENCIES]: flutter_riverpod, axie_marketplace_remote_datasource.dart, axie_card_entity.dart
// [ARCHITECTURE]: Riverpod State Controller Pattern
// ===============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/axie_marketplace_remote_datasource.dart';
import '../../domain/entities/axie_card_entity.dart';

final axieRemoteDataSourceProvider = Provider<IAxieRemoteDataSource>((ref) {
  return AxieMarketplaceRemoteDataSource(client: http.Client());
});

final axieImporterProvider = AsyncNotifierProvider<AxieImporterController, List<AxieCardEntity>>(() {
  return AxieImporterController();
});

class AxieImporterController extends AsyncNotifier<List<AxieCardEntity>> {
  late final IAxieRemoteDataSource _dataSource;

  @override
  Future<List<AxieCardEntity>> build() async {
    _dataSource = ref.read(axieRemoteDataSourceProvider);
    return [];
  }

  Future<List<AxieCardEntity>> importAxies(List<String> ids) async {
    state = const AsyncValue.loading();
    try {
      final rawResults = await _dataSource.fetchAxiesRawByIds(ids);
      final axies = rawResults.map((json) => AxieCardEntity.fromGraphQL(json)).toList();
      state = AsyncValue.data(axies);
      return axies;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      rethrow;
    }
  }

  Future<List<AxieCardEntity>> importAxiesFromWallet(String wallet) async {
    state = const AsyncValue.loading();
    try {
      final rawResults = await _dataSource.fetchAxiesByWallet(wallet);
      final axies = rawResults.map((json) => AxieCardEntity.fromGraphQL(json)).toList();
      state = AsyncValue.data(axies);
      return axies;
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
      rethrow;
    }
  }

  Future<void> processImportInput(String rawInput) async {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) return;

    try {
      if (trimmed.startsWith('ronin:') || trimmed.startsWith('0x')) {
        await importAxiesFromWallet(trimmed);
      } else {
        final ids = trimmed.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        await importAxies(ids);
      }
    } catch (_) {
      // Error state is already captured in state = AsyncValue.error(err, stack)
    }
  }

  bool get isOfflineFallback {
    final ds = _dataSource;
    if (ds is AxieMarketplaceRemoteDataSource) {
      return ds.isOfflineFallbackActive;
    }
    if (ds is OfflineFallbackDataSource) {
      return true;
    }
    return false;
  }
}
