// ===============================================================================
// [MODULE_NAME]: axie_vault_repository.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Data / Repositories
// [INTENT]: Local storage persistence for imported Axie creatures using SharedPreferences.
// [DEPENDENCIES]: shared_preferences, dart:convert, axie_card_entity
// [ARCHITECTURE]: Clean Architecture Repository Pattern
// ===============================================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/axie_card_entity.dart';

abstract class IAxieVaultRepository {
  Future<List<AxieCardEntity>> getSavedAxies();
  Future<bool> saveAxie(AxieCardEntity axie);
  Future<bool> removeAxie(String axieId);
  Future<bool> isAxieSaved(String axieId);
}

class AxieVaultRepository implements IAxieVaultRepository {
  static const String vaultStorageKey = 'lcw_saved_axies_vault_v1';

  final SharedPreferences prefs;

  AxieVaultRepository({required this.prefs});

  @override
  Future<List<AxieCardEntity>> getSavedAxies() async {
    try {
      final stringList = prefs.getStringList(vaultStorageKey);
      if (stringList != null && stringList.isNotEmpty) {
        final axies = <AxieCardEntity>[];
        for (final rawJson in stringList) {
          try {
            final map = jsonDecode(rawJson) as Map<String, dynamic>;
            axies.add(AxieCardEntity.fromJson(map));
          } catch (_) {
            // Skip corrupt individual items without crashing entire vault
          }
        }
        return axies;
      }

      final rawString = prefs.getString(vaultStorageKey);
      if (rawString != null && rawString.trim().isNotEmpty) {
        final decoded = jsonDecode(rawString);
        if (decoded is List) {
          final axies = <AxieCardEntity>[];
          for (final item in decoded) {
            try {
              if (item is Map<String, dynamic>) {
                axies.add(AxieCardEntity.fromJson(item));
              } else if (item is Map) {
                axies.add(AxieCardEntity.fromJson(Map<String, dynamic>.from(item)));
              }
            } catch (_) {}
          }
          return axies;
        }
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> saveAxie(AxieCardEntity axie) async {
    try {
      final currentAxies = await getSavedAxies();
      if (currentAxies.any((a) => a.id == axie.id)) {
        return true;
      }
      currentAxies.add(axie);

      final encodedList = currentAxies.map((a) => jsonEncode(a.toJson())).toList();
      return await prefs.setStringList(vaultStorageKey, encodedList);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> removeAxie(String axieId) async {
    try {
      final currentAxies = await getSavedAxies();
      final initialLength = currentAxies.length;
      currentAxies.removeWhere((a) => a.id == axieId);
      if (currentAxies.length == initialLength) {
        return true;
      }

      final encodedList = currentAxies.map((a) => jsonEncode(a.toJson())).toList();
      return await prefs.setStringList(vaultStorageKey, encodedList);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isAxieSaved(String axieId) async {
    try {
      final currentAxies = await getSavedAxies();
      return currentAxies.any((a) => a.id == axieId);
    } catch (_) {
      return false;
    }
  }
}
