// ===============================================================================
// [MODULE_NAME]: axie_marketplace_remote_datasource.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Data / Remote Data Sources
// [INTENT]: Remote data source with full raw metadata debug logging.
// [DEPENDENCIES]: http, dart:convert, flutter/foundation.dart, flutter/services.dart
// [ARCHITECTURE]: Remote DataSource Pattern
// ===============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'axie_graphql_queries.dart';

class AxieNetworkException implements Exception {
  final String message;
  final int? statusCode;
  AxieNetworkException(this.message, [this.statusCode]);
  @override
  String toString() => 'AxieNetworkException: $message (HTTP $statusCode)';
}

abstract class IAxieRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchAxiesRawByIds(List<String> ids);
  Future<List<Map<String, dynamic>>> fetchAxiesByWallet(String walletAddress);
}

class AxieMarketplaceRemoteDataSource implements IAxieRemoteDataSource {
  final http.Client client;
  static const String _endpoint = 'https://api-gateway.skymavis.com/graphql/axie-marketplace';
  static const String _apiKey = String.fromEnvironment('SKY_MAVIS_API_KEY', defaultValue: '');
  static const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

  bool isOfflineFallbackActive = false;

  AxieMarketplaceRemoteDataSource({required this.client});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'User-Agent': 'LunacianCardWars/1.0',
    if (_apiKey.isNotEmpty) 'X-API-Key': _apiKey,
  };

  @override
  Future<List<Map<String, dynamic>>> fetchAxiesByWallet(String walletAddress) async {
    final sanitizedWallet = walletAddress.trim().toLowerCase();
    final normalizedWallet = sanitizedWallet.startsWith('ronin:')
        ? '0x${sanitizedWallet.substring(6)}'
        : sanitizedWallet;

    http.Response response;
    try {
      response = await client.post(
        Uri.parse(_endpoint),
        headers: _headers,
        body: jsonEncode({
          'query': AxieGraphQLQueries.getAxiesByOwner,
          'variables': {
            'owner': normalizedWallet,
            'from': 0,
            'size': 100,
          },
        }),
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[SkyMavis Wallet Offline Fallback]: Network exception ($e). Loading local Lunacian squad.');
      isOfflineFallbackActive = true;
      return _fetchFromSnapshot();
    }

    if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode >= 500) {
      debugPrint('[SkyMavis Wallet Offline Fallback]: HTTP ${response.statusCode} (API key required/server error). Transparently loading local Lunacian squad.');
      isOfflineFallbackActive = true;
      return _fetchFromSnapshot();
    }

    if (response.statusCode != 200) {
      debugPrint('[SkyMavis Wallet Error]: HTTP ${response.statusCode} -> ${response.body}');
      throw AxieNetworkException('Failed to resolve wallet: HTTP ${response.statusCode}', response.statusCode);
    }

    final data = jsonDecode(response.body);
    if (data['errors'] != null) {
      debugPrint('[SkyMavis Wallet GraphQL Errors]: ${data['errors']}');
      isOfflineFallbackActive = true;
      return _fetchFromSnapshot();
    }

    final results = data['data']?['axies']?['results'] as List<dynamic>? ?? [];
    final castedResults = results.cast<Map<String, dynamic>>();

    if (castedResults.isEmpty) {
      debugPrint('[SkyMavis Wallet Empty]: No on-chain Axies found in wallet. Providing local Lunacian squad.');
      isOfflineFallbackActive = true;
      return _fetchFromSnapshot();
    }

    isOfflineFallbackActive = false;
    for (final axieJson in castedResults) {
      debugPrint('==================== AXIE RAW METADATA [ID: ${axieJson['id']}] ====================');
      debugPrint(_prettyEncoder.convert(axieJson));
      debugPrint('===================================================================================');
    }

    return castedResults;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAxiesRawByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final sanitizedIds = ids.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    try {
      final futures = sanitizedIds.map((id) => _fetchSingleAxie(id));
      final results = await Future.wait(futures);
      final valid = results.whereType<Map<String, dynamic>>().toList();
      if (valid.isNotEmpty) {
        return valid;
      }
    } catch (e) {
      debugPrint('[SkyMavis Batch Ids Offline Fallback]: Error ($e). Loading local Lunacian squad.');
    }

    isOfflineFallbackActive = true;
    return _fetchFromSnapshot();
  }

  Future<Map<String, dynamic>?> _fetchSingleAxie(String axieId) async {
    http.Response response;
    try {
      response = await client.post(
        Uri.parse(_endpoint),
        headers: _headers,
        body: jsonEncode({
          'query': AxieGraphQLQueries.getAxieDetail,
          'variables': {'axieId': axieId},
        }),
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[SkyMavis Single Axie Offline Fallback $axieId]: $e');
      isOfflineFallbackActive = true;
      final snapshot = await _fetchFromSnapshot();
      return snapshot.firstWhere(
        (a) => a['id']?.toString() == axieId,
        orElse: () => snapshot.first,
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode >= 500) {
      debugPrint('[SkyMavis Single Axie Offline Fallback $axieId]: HTTP ${response.statusCode}');
      isOfflineFallbackActive = true;
      final snapshot = await _fetchFromSnapshot();
      return snapshot.firstWhere(
        (a) => a['id']?.toString() == axieId,
        orElse: () => snapshot.first,
      );
    }

    if (response.statusCode != 200) {
      debugPrint('[SkyMavis Single Axie Error $axieId]: HTTP ${response.statusCode} -> ${response.body}');
      throw AxieNetworkException('Single query failed: HTTP ${response.statusCode}', response.statusCode);
    }

    final data = jsonDecode(response.body);
    if (data['errors'] != null) {
      debugPrint('[SkyMavis Single Axie GraphQL Error $axieId]: ${data['errors']}');
      throw AxieNetworkException('GraphQL Error: ${data['errors']}');
    }

    final axieData = data['data']?['axie'] as Map<String, dynamic>?;
    if (axieData != null) {
      debugPrint('==================== AXIE RAW METADATA [ID: $axieId] ====================');
      debugPrint(_prettyEncoder.convert(axieData));
      debugPrint('=========================================================================');
    }

    return axieData;
  }

  static Future<List<Map<String, dynamic>>> loadSnapshotData() => _fetchFromSnapshot();

  static Future<List<Map<String, dynamic>>> _fetchFromSnapshot() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/initial_axies_snapshot.json');
      final data = jsonDecode(jsonString) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return _bundledStaticSnapshot;
    }
  }

  static const List<Map<String, dynamic>> _bundledStaticSnapshot = [
    {
      "id": "1",
      "name": "Buba",
      "class": "Plant",
      "level": 25,
      "genes": "0x000000000000000000000000000000000000000000000000000000000000000000",
      "axpInfo": {"level": 25},
      "image": "",
      "parts": [
        {"id": "horn-caterpillars", "name": "Caterpillars", "class": "Bug", "type": "Horn"},
        {"id": "back-leafy", "name": "Leafy", "class": "Plant", "type": "Back"},
        {"id": "mouth-tiny-turtle", "name": "Tiny Turtle", "class": "Reptile", "type": "Mouth"},
        {"id": "tail-shrimp", "name": "Shrimp", "class": "Aquatic", "type": "Tail"},
        {"id": "eyes-confused", "name": "Confused", "class": "Plant", "type": "Eyes"},
        {"id": "ears-lotus", "name": "Lotus", "class": "Plant", "type": "Ears"}
      ],
      "stats": {"hp": 61, "speed": 35, "skill": 31, "morale": 43}
    },
    {
      "id": "2",
      "name": "Olek",
      "class": "Beast",
      "level": 25,
      "genes": "0x000000000000000000000000000000000000000000000000000000000000000001",
      "axpInfo": {"level": 25},
      "image": "",
      "parts": [
        {"id": "horn-serious", "name": "Serious", "class": "Beast", "type": "Horn"},
        {"id": "back-jaguar", "name": "Jaguar", "class": "Beast", "type": "Back"},
        {"id": "mouth-goda", "name": "Goda", "class": "Beast", "type": "Mouth"},
        {"id": "tail-rice", "name": "Rice", "class": "Beast", "type": "Tail"},
        {"id": "eyes-chubby", "name": "Chubby", "class": "Beast", "type": "Eyes"},
        {"id": "ears-sakura", "name": "Sakura", "class": "Beast", "type": "Ears"}
      ],
      "stats": {"hp": 43, "speed": 61, "skill": 43, "morale": 83}
    },
    {
      "id": "3",
      "name": "Puffy",
      "class": "Aquatic",
      "level": 25,
      "genes": "0x000000000000000000000000000000000000000000000000000000000000000002",
      "axpInfo": {"level": 25},
      "image": "",
      "parts": [
        {"id": "horn-anemone", "name": "Anemone", "class": "Aquatic", "type": "Horn"},
        {"id": "back-blue-moon", "name": "Blue Moon", "class": "Aquatic", "type": "Back"},
        {"id": "mouth-piranha", "name": "Piranha", "class": "Aquatic", "type": "Mouth"},
        {"id": "tail-nimo", "name": "Nimo", "class": "Aquatic", "type": "Tail"},
        {"id": "eyes-spit-kiss", "name": "Spit Kiss", "class": "Aquatic", "type": "Eyes"},
        {"id": "ears-seaside-porcinus", "name": "Seaside Porcinus", "class": "Aquatic", "type": "Ears"}
      ],
      "stats": {"hp": 43, "speed": 67, "skill": 61, "morale": 29}
    }
  ];
}

class OfflineFallbackDataSource implements IAxieRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchAxiesByWallet(String walletAddress) async {
    return AxieMarketplaceRemoteDataSource._fetchFromSnapshot();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAxiesRawByIds(List<String> ids) async {
    return AxieMarketplaceRemoteDataSource._fetchFromSnapshot();
  }
}
