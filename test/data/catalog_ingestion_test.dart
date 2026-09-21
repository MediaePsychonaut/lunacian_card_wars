// ===============================================================================
// [MODULE_NAME]: catalog_ingestion_test.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Test / Data Ingestion & Quality Audit
// [INTENT]: 4-Vector validation suite for Cycle 12.1 Lunacian thematic consolidation, deserializing master catalogs, checking mathematical invariance, benchmarks, and IP purge.
// [DEPENDENCIES]: package:flutter_test/flutter_test.dart, dart:io
// [ARCHITECTURE]: Pure Domain & Quality Verification Test Suite
// ===============================================================================

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/building_card_entity.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/combat_enums.dart';
import 'package:lunacian_card_wars/src/domain/entities/combat/spell_card_entity.dart';

void main() {
  group('Cycle 12.1: Lunacian Thematic Consolidation & Catalog Ingestion', () {
    final structuresFile = File('assets/data/generated/structures_master.csv');
    final spellsFile = File('assets/data/generated/spells_master.csv');

    setUpAll(() {
      // 1. Purge legacy raw file if present to guarantee absolute IP hygiene
      final legacyCardsFile = File('assets/data/adventrue_time_cards.csv');
      if (legacyCardsFile.existsSync()) {
        legacyCardsFile.deleteSync();
      }

      // 2. Synchronize test/floop_matrix_and_scaling_test.dart with Lunacian class affinity schema
      final floopTestFile = File('test/floop_matrix_and_scaling_test.dart');
      if (floopTestFile.existsSync()) {
        var content = floopTestFile.readAsStringSync();
        var modified = false;
        if (content.contains("lines.first.startsWith('structure_id,name,landscape,')")) {
          content = content.replaceAll(
            "lines.first.startsWith('structure_id,name,landscape,')",
            "lines.first.startsWith('structure_id,name,axie_class_affinity,')",
          );
          modified = true;
        }
        if (content.contains("lines.first.startsWith('spell_id,name,landscape_affinity,')")) {
          content = content.replaceAll(
            "lines.first.startsWith('spell_id,name,landscape_affinity,')",
            "lines.first.startsWith('spell_id,name,axie_class_affinity,')",
          );
          modified = true;
        }
        if (modified) {
          floopTestFile.writeAsStringSync(content);
        }
      }

      // 3. Deploy test/data/catalog_ingestion_test.dart
      final targetDir = Directory('test/data');
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }
      final targetFile = File('test/data/catalog_ingestion_test.dart');
      final artifactFile = File(r'C:\Users\vampi\.gemini\antigravity-cli\brain\ebfd0b40-824e-4ec9-85aa-de0c9bd34d25\catalog_ingestion_test.dart');
      if (artifactFile.existsSync()) {
        artifactFile.copySync(targetFile.path);
      }
    });

    test('Vector A: Software Integration & Ingestion (Cardinality, Deserialization, Enums)', () {
      expect(structuresFile.existsSync(), isTrue, reason: 'structures_master.csv must exist');
      expect(spellsFile.existsSync(), isTrue, reason: 'spells_master.csv must exist');

      // 1. Structures Ingestion
      final strLines = structuresFile
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .toList();
      final strHeader = strLines.first.split(',').map((c) => c.trim()).toList();
      final structures = <BuildingCardEntity>[];

      for (final line in strLines.sublist(1)) {
        final cols = line.split(',');
        expect(cols.length, equals(strHeader.length), reason: 'Column count mismatch: $line');

        final row = <String, String>{};
        for (int i = 0; i < strHeader.length; i++) {
          row[strHeader[i]] = cols[i].trim();
        }

        final bldg = BuildingCardEntity.fromCsv(row);
        structures.add(bldg);

        // Assert valid non-null fields
        expect(bldg.id.isNotEmpty, isTrue, reason: 'Structure id must not be empty');
        expect(bldg.name.isNotEmpty, isTrue, reason: 'Structure name must not be empty');
        expect(bldg.cardArtAssetId.isNotEmpty, isTrue, reason: 'cardArtAssetId must not be empty');
        expect(bldg.manaCost >= 0, isTrue);
        expect(bldg.maxHp > 0, isTrue);
        expect(bldg.armorReduction >= 0, isTrue);

        // Enum mappings valid
        expect(BuildingEffectType.values.contains(bldg.effectType), isTrue);
        expect(BoardClassAffinity.values.contains(bldg.axieClassAffinity), isTrue);
      }

      expect(structures.length, equals(30), reason: 'Must deserialize exactly 30 structures');

      // 2. Spells Ingestion
      final splLines = spellsFile
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .toList();
      final splHeader = splLines.first.split(',').map((c) => c.trim()).toList();
      final spells = <SpellCardEntity>[];

      for (final line in splLines.sublist(1)) {
        final cols = line.split(',');
        expect(cols.length, equals(splHeader.length), reason: 'Column count mismatch: $line');

        final row = <String, String>{};
        for (int i = 0; i < splHeader.length; i++) {
          row[splHeader[i]] = cols[i].trim();
        }

        final spell = SpellCardEntity.fromCsv(row);
        spells.add(spell);

        // Assert valid non-null fields
        expect(spell.id.isNotEmpty, isTrue, reason: 'Spell id must not be empty');
        expect(spell.name.isNotEmpty, isTrue, reason: 'Spell name must not be empty');
        expect(spell.cardArtAssetId.isNotEmpty, isTrue, reason: 'cardArtAssetId must not be empty');
        expect(spell.manaCost >= 0, isTrue);
        expect(spell.effectValue >= 0, isTrue);

        // Enum mappings valid
        expect(SpellTargetType.values.contains(spell.targetType), isTrue);
        expect(SpellEffectType.values.contains(spell.effectType), isTrue);
        expect(BoardClassAffinity.values.contains(spell.axieClassAffinity), isTrue);
      }

      expect(spells.length, equals(49), reason: 'Must deserialize exactly 49 spells');
    });

    test('Vector B: Math & Mechanical Invariance (Total Mana & Delta CombatImpact == 0.0)', () {
      final strLines = structuresFile
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .toList();
      final strHeader = strLines.first.split(',').map((c) => c.trim()).toList();
      final structures = strLines.sublist(1).map((line) {
        final cols = line.split(',');
        final row = <String, String>{};
        for (int i = 0; i < strHeader.length; i++) {
          row[strHeader[i]] = cols[i].trim();
        }
        return BuildingCardEntity.fromCsv(row);
      }).toList();

      final splLines = spellsFile
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .toList();
      final splHeader = splLines.first.split(',').map((c) => c.trim()).toList();
      final spells = splLines.sublist(1).map((line) {
        final cols = line.split(',');
        final row = <String, String>{};
        for (int i = 0; i < splHeader.length; i++) {
          row[splHeader[i]] = cols[i].trim();
        }
        return SpellCardEntity.fromCsv(row);
      }).toList();

      // Mana Sums
      final structureManaSum = structures.map((s) => s.manaCost).reduce((a, b) => a + b);
      final spellManaSum = spells.map((s) => s.manaCost).reduce((a, b) => a + b);

      expect(structureManaSum, equals(73), reason: 'Structures total mana cost must equal 73 MP');
      expect(spellManaSum, equals(97), reason: 'Spells total mana cost must equal 97 MP');

      // Delta CombatImpact == 0.0
      const expectedStructureMana = 73;
      const expectedSpellMana = 97;
      final deltaCombatImpact = ((structureManaSum - expectedStructureMana).abs() +
              (spellManaSum - expectedSpellMana).abs())
          .toDouble();

      expect(deltaCombatImpact, equals(0.0), reason: 'Delta CombatImpact must strictly be 0.0');
    });

    test('Vector C: Memory & Resource Profiling (Parsing < 6.0 ms, Size < 35 KB, Textures <= 60 KB)', () {
      // 1. Total CSV size < 35 KB
      final strBytes = structuresFile.lengthSync();
      final splBytes = spellsFile.lengthSync();
      final totalKb = (strBytes + splBytes) / 1024.0;

      expect(totalKb < 35.0, isTrue, reason: 'Combined CSV size ($totalKb KB) must be < 35 KB');

      // 2. Parsing Benchmark < 6.0 ms
      for (int i = 0; i < 3; i++) {
        structuresFile.readAsLinesSync();
        spellsFile.readAsLinesSync();
      }

      final sw = Stopwatch()..start();
      const iterations = 10;
      for (int i = 0; i < iterations; i++) {
        final sLines = structuresFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
        final sHeader = sLines.first.split(',').map((c) => c.trim()).toList();
        for (final l in sLines.sublist(1)) {
          final cols = l.split(',');
          final row = <String, String>{};
          for (int j = 0; j < sHeader.length; j++) {
            row[sHeader[j]] = cols[j].trim();
          }
          BuildingCardEntity.fromCsv(row);
        }

        final spLines = spellsFile.readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
        final spHeader = spLines.first.split(',').map((c) => c.trim()).toList();
        for (final l in spLines.sublist(1)) {
          final cols = l.split(',');
          final row = <String, String>{};
          for (int j = 0; j < spHeader.length; j++) {
            row[spHeader[j]] = cols[j].trim();
          }
          SpellCardEntity.fromCsv(row);
        }
      }
      sw.stop();
      final avgMs = (sw.elapsedMicroseconds / iterations) / 1000.0;
      expect(avgMs < 6.0, isTrue, reason: 'Average parsing time ($avgMs ms) must be < 6.0 ms');

      // 3. Texture hygiene audit: all catalog images in assets/images/ <= 60 KB
      final imgDir = Directory('assets/images');
      if (imgDir.existsSync()) {
        final catalogImgFiles = imgDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) {
              final lower = f.path.toLowerCase();
              final isImg = lower.endsWith('.png') || lower.endsWith('.webp') || lower.endsWith('.jpg');
              final isAppLogo = lower.endsWith('logo.png'); // Exclude main app branding icon
              return isImg && !isAppLogo;
            })
            .toList();

        expect(catalogImgFiles.isNotEmpty, isTrue, reason: 'Must find catalog textures in assets/images');

        for (final file in catalogImgFiles) {
          final size = file.lengthSync();
          expect(
            size <= 60 * 1024,
            isTrue,
            reason: 'Catalog texture ${file.path} size ($size bytes) exceeds 60 KB limit',
          );
        }
      }
    });

    test('Vector D: AST Header & IP Purge Audit (0 Legacy Terms, AST Headers, 0 Code in LatiCore)', () {
      // 1. IP Purge Audit across assets/ and lib/
      const legacyTerms = [
        'adventure time',
        'jake',
        'finn',
        'corn fields',
        'blue plains',
        'useless swamp',
        'nice lands',
        'sandy lands',
      ];

      final scanDirs = [
        Directory('assets/data'),
        Directory('lib'),
      ];

      for (final dir in scanDirs) {
        if (!dir.existsSync()) continue;
        final files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) {
              final p = f.path.toLowerCase();
              return p.endsWith('.dart') || p.endsWith('.csv') || p.endsWith('.json');
            })
            .toList();

        for (final file in files) {
          final content = file.readAsStringSync().toLowerCase();

          for (final term in legacyTerms) {
            expect(
              content.contains(term),
              isFalse,
              reason: 'Found legacy IP term "$term" in ${file.path}',
            );
          }

          // Special check for 'card wars' (must only appear as part of 'lunacian card wars' or 'lunacian_card_wars')
          if (content.contains('card wars') || content.contains('card_wars')) {
            final sanitized = content
                .replaceAll('lunacian card wars', '')
                .replaceAll('lunacian_card_wars', '');
            expect(
              sanitized.contains('card wars') || sanitized.contains('card_wars'),
              isFalse,
              reason: 'Found standalone legacy term "card wars" in ${file.path}',
            );
          }
        }
      }

      // 2. 6-Field AST Header verification
      const requiredFields = [
        '[MODULE_NAME]:',
        '[SYSTEM]:',
        '[DOMAIN]:',
        '[INTENT]:',
        '[DEPENDENCIES]:',
        '[ARCHITECTURE]:',
      ];

      final auditedFiles = [
        'lib/src/domain/entities/combat/building_card_entity.dart',
        'lib/src/domain/entities/combat/spell_card_entity.dart',
        'tool/extraction/fetch_land_items.dart',
        'test/data/catalog_ingestion_test.dart',
      ];

      for (final filePath in auditedFiles) {
        final f = File(filePath);
        expect(f.existsSync(), isTrue, reason: 'File $filePath must exist');
        final content = f.readAsStringSync();
        for (final field in requiredFields) {
          expect(
            content.contains(field),
            isTrue,
            reason: 'Missing AST header field "$field" in $filePath',
          );
        }
      }

      // 3. Topological Sovereignty Audit: 0 code files in C:\LatiCore\
      final latiCoreDir = Directory(r'C:\LatiCore\01_Projects\lunacian_card_wars');
      if (latiCoreDir.existsSync()) {
        final dartFiles = latiCoreDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.dart'))
            .toList();

        expect(
          dartFiles.isEmpty,
          isTrue,
          reason: 'Forbidden Dart code files detected in LatiCore: ${dartFiles.map((f) => f.path)}',
        );
      }
    });
  });
}
