// ===============================================================================
// [MODULE_NAME]: card_catalog_repository.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Data / Repositories
// [INTENT]: Ingestion repository parsing master CSV catalogs for Structures and Spells with neutral Rainbow affinity.
// [DEPENDENCIES]: package:flutter/services.dart, dart:io, package:flutter_riverpod/flutter_riverpod.dart, ../../domain/entities/combat/building_card_entity.dart, ../../domain/entities/combat/spell_card_entity.dart
// [ARCHITECTURE]: Clean Architecture Repository Pattern
// ===============================================================================

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/combat/building_card_entity.dart';
import '../../domain/entities/combat/spell_card_entity.dart';

abstract class ICardCatalogRepository {
  Future<List<BuildingCardEntity>> loadStructures();
  Future<List<SpellCardEntity>> loadSpells();
}

class CardCatalogRepository implements ICardCatalogRepository {
  static const String structuresCsvPath = 'assets/data/generated/structures_master.csv';
  static const String spellsCsvPath = 'assets/data/generated/spells_master.csv';

  List<BuildingCardEntity>? _cachedStructures;
  List<SpellCardEntity>? _cachedSpells;

  @override
  Future<List<BuildingCardEntity>> loadStructures() async {
    if (_cachedStructures != null && _cachedStructures!.isNotEmpty) {
      return _cachedStructures!;
    }

    final csvContent = await _loadAssetOrFile(structuresCsvPath);
    final lines = csvContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    final structures = <BuildingCardEntity>[];

    for (final line in lines.sublist(1)) {
      final cols = _parseCsvLine(line);
      if (cols.length != headers.length) continue;

      final row = <String, String>{};
      for (int i = 0; i < headers.length; i++) {
        row[headers[i]] = cols[i].trim();
      }

      structures.add(BuildingCardEntity.fromCsv(row));
    }

    _cachedStructures = structures;
    return structures;
  }

  @override
  Future<List<SpellCardEntity>> loadSpells() async {
    if (_cachedSpells != null && _cachedSpells!.isNotEmpty) {
      return _cachedSpells!;
    }

    final csvContent = await _loadAssetOrFile(spellsCsvPath);
    final lines = csvContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return [];

    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    final spells = <SpellCardEntity>[];

    for (final line in lines.sublist(1)) {
      final cols = _parseCsvLine(line);
      if (cols.length != headers.length) continue;

      final row = <String, String>{};
      for (int i = 0; i < headers.length; i++) {
        row[headers[i]] = cols[i].trim();
      }

      spells.add(SpellCardEntity.fromCsv(row));
    }

    _cachedSpells = spells;
    return spells;
  }

  Future<String> _loadAssetOrFile(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          return file.readAsStringSync();
        }
      } catch (_) {}
      return '';
    }
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }
}

final cardCatalogRepositoryProvider = Provider<ICardCatalogRepository>((ref) {
  return CardCatalogRepository();
});

final structuresCatalogProvider = FutureProvider<List<BuildingCardEntity>>((ref) async {
  final repo = ref.watch(cardCatalogRepositoryProvider);
  return await repo.loadStructures();
});

final spellsCatalogProvider = FutureProvider<List<SpellCardEntity>>((ref) async {
  final repo = ref.watch(cardCatalogRepositoryProvider);
  return await repo.loadSpells();
});
