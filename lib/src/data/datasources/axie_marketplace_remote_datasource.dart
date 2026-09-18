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

    final response = await client.post(
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
    );

    if (response.statusCode != 200) {
      debugPrint('[SkyMavis Wallet Error]: HTTP ${response.statusCode} -> ${response.body}');
      throw AxieNetworkException('Failed to resolve wallet: HTTP ${response.statusCode}', response.statusCode);
    }

    final data = jsonDecode(response.body);
    if (data['errors'] != null) {
      debugPrint('[SkyMavis Wallet GraphQL Errors]: ${data['errors']}');
      throw AxieNetworkException('GraphQL Error: ${data['errors']}');
    }

    final results = data['data']?['axies']?['results'] as List<dynamic>? ?? [];
    final castedResults = results.cast<Map<String, dynamic>>();

    // Telemetry: Log raw metadata for every fetched wallet Axie
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

    // Concurrent single-entity resolution avoiding invalid criteria queries
    final futures = sanitizedIds.map((id) => _fetchSingleAxie(id));
    final results = await Future.wait(futures);

    return results.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>?> _fetchSingleAxie(String axieId) async {
    final response = await client.post(
      Uri.parse(_endpoint),
      headers: _headers,
      body: jsonEncode({
        'query': AxieGraphQLQueries.getAxieDetail,
        'variables': {'axieId': axieId},
      }),
    );

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
}

class OfflineFallbackDataSource implements IAxieRemoteDataSource {
  @override
  Future<List<Map<String, dynamic>>> fetchAxiesByWallet(String walletAddress) async {
    return _fetchFromSnapshot();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAxiesRawByIds(List<String> ids) async {
    return _fetchFromSnapshot();
  }

  Future<List<Map<String, dynamic>>> _fetchFromSnapshot() async {
    final jsonString = await rootBundle.loadString('assets/data/initial_axies_snapshot.json');
    final data = jsonDecode(jsonString) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }
}
