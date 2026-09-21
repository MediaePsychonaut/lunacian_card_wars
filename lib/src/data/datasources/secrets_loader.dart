// ===============================================================================
// [MODULE_NAME]: secrets_loader.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Data / Security
// [INTENT]: Universal export switcher for cross-platform secure secrets resolution.
// [DEPENDENCIES]: secrets_loader_stub.dart, secrets_loader_io.dart
// [ARCHITECTURE]: Conditional Compilation Pattern
// ===============================================================================

export 'secrets_loader_stub.dart'
    if (dart.library.io) 'secrets_loader_io.dart';
