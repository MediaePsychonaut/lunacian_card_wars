// ===============================================================================
// [MODULE_NAME]: secrets_loader_io.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Data / Security
// [INTENT]: Native IO resolution of Sky Mavis API key from local environment or uncommitted secrets.env.
// [DEPENDENCIES]: dart:io
// [ARCHITECTURE]: Conditional Compilation Pattern
// ===============================================================================

import 'dart:io';

String? loadLocalSecretsFile() {
  try {
    final envKey = Platform.environment['SKY_MAVIS_API_KEY'];
    if (envKey != null && envKey.trim().isNotEmpty) {
      return envKey.trim();
    }

    final candidates = [
      File('secrets.env'),
      File('assets/data/secrets.env'),
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
  } catch (_) {}
  return null;
}
