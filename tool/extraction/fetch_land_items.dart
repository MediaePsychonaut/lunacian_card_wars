// ===============================================================================
// [MODULE_NAME]: fetch_land_items.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Tool / Extraction
// [INTENT]: Pure Dart CLI extraction script querying Sky Mavis GraphQL API for official Lunacian Land Items to catalog monuments, shrines, and outposts.
// [DEPENDENCIES]: dart:io, dart:convert, package:http/http.dart
// [ARCHITECTURE]: Standalone CLI Data Extraction Script
// ===============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Resolves the Sky Mavis API key from environment variables or local secrets file.
String resolveApiKey() {
  final envKey = Platform.environment['SKY_MAVIS_API_KEY'];
  if (envKey != null && envKey.isNotEmpty) {
    return envKey;
  }

  final candidates = [
    File('secrets.env'),
    File('../secrets.env'),
    File('C:/NeuroField/active_projects/lunacian_card_wars/secrets.env'),
  ];

  for (final file in candidates) {
    if (file.existsSync()) {
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('SKY_MAVIS_API_KEY=')) {
          final key = trimmed.substring('SKY_MAVIS_API_KEY='.length).trim();
          if (key.isNotEmpty) return key;
        }
      }
    }
  }

  return '';
}

/// Sky Mavis GraphQL client for Land Items querying.
class LunaciaLandClient {
  static const String endpoint =
      'https://api-gateway.skymavis.com/graphql/axie-marketplace';

  final String apiKey;
  final http.Client _client = http.Client();

  LunaciaLandClient({required this.apiKey});

  static const String landItemsQuery = r'''
query GetLandItems($from: Int, $size: Int) {
  items(itemTypes: [LandItem], from: $from, size: $size) {
    total
    results {
      tokenId
      itemId
      itemType
      name
      rarity
      figureURL
    }
  }
}
''';

  Future<Map<String, dynamic>?> fetchLandItems({int from = 0, int size = 50}) async {
    final body = jsonEncode({
      'query': landItemsQuery,
      'variables': {
        'from': from,
        'size': size,
      },
    });

    final headers = {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey,
    };

    try {
      final response = await _client.post(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['data']?['items'] as Map<String, dynamic>?;
      } else {
        stderr.writeln('HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      stderr.writeln('Network error fetching land items: $e');
      return null;
    }
  }

  void close() {
    _client.close();
  }
}

Future<void> main(List<String> args) async {
  stdout.writeln('====================================================');
  stdout.writeln('Lunacia Land Items GraphQL Extractor');
  stdout.writeln('Sky Mavis Marketplace API — Cycle 12.1');
  stdout.writeln('====================================================');

  final apiKey = resolveApiKey();
  if (apiKey.isEmpty) {
    stdout.writeln('NOTICE: SKY_MAVIS_API_KEY is not configured in environment or secrets.env.');
    stdout.writeln('Operating in dry-run/mock inspection mode.');
    stdout.writeln('====================================================');
    return;
  }

  stdout.writeln('API Key authenticated.');
  final client = LunaciaLandClient(apiKey: apiKey);

  try {
    stdout.writeln('Querying Land Items from Sky Mavis GraphQL API...');
    final data = await client.fetchLandItems(from: 0, size: 50);

    if (data != null) {
      final total = data['total'] ?? 0;
      final results = data['results'] as List<dynamic>? ?? [];
      stdout.writeln('Discovered $total Land Items on-chain (Fetched: ${results.length}).');

      final outDir = Directory('assets/data/generated');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }

      final outFile = File('assets/data/generated/land_items_raw.json');
      outFile.writeAsStringSync(jsonEncode(data));
      stdout.writeln('Successfully stored raw items to ${outFile.path}');
    } else {
      stderr.writeln('Unable to extract land items payload.');
    }
  } finally {
    client.close();
  }

  stdout.writeln('====================================================');
  stdout.writeln('EXTRACTION COMPLETE');
  stdout.writeln('====================================================');
}
