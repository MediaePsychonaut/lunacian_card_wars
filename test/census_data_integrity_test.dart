// ===============================================================================
// [MODULE_NAME]: census_data_integrity_test.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Test / Data Integrity
// [INTENT]: Automated integrity verification suite for Axie Infinity on-chain GraphQL census datasets (204 body parts and 288 mouth-tail genetic permutations).
// [DEPENDENCIES]: package:flutter_test/flutter_test.dart, dart:io
// [ARCHITECTURE]: Data Integrity Verification Suite
// ===============================================================================

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Axie Demographic Census Datasets Integrity (Cycle 11.9)', () {
    final partStatsFile = File('assets/data/axie_part_stats_and_floops.csv');
    final permStatsFile = File('assets/data/mouth_tail_permutation_floops.csv');

    test('Test 1: Primary dataset exists and contains exactly 205 lines (1 header + 204 parts)', () {
      expect(partStatsFile.existsSync(), isTrue, reason: 'assets/data/axie_part_stats_and_floops.csv must exist');

      final lines = partStatsFile
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty)
          .toList();

      expect(lines.length, equals(205), reason: 'Must contain exactly 1 header + 204 data rows');
      expect(lines.first, equals('Part_Name,Slot,Class,GraphQL_ID,Axie_Amount'));
    });

    test('Test 2: Primary dataset slot and class distribution matches canonical 204 parts', () {
      final lines = partStatsFile
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty)
          .toList();

      final dataRows = lines.sublist(1);
      final Map<String, int> slotCounts = {};
      final Map<String, Set<String>> slotClasses = {};

      for (final row in dataRows) {
        final cols = row.split(',');
        expect(cols.length, equals(5), reason: 'Each row must have 5 columns: Part_Name,Slot,Class,GraphQL_ID,Axie_Amount');

        final slot = cols[1].trim();
        final axieClass = cols[2].trim();
        final slug = cols[3].trim();
        final amount = int.tryParse(cols[4].trim());

        expect(amount, isNotNull, reason: 'Axie_Amount must be a valid integer: $row');
        expect(amount! >= 0, isTrue, reason: 'Axie_Amount must be non-negative: $amount');
        expect(slug.isNotEmpty, isTrue, reason: 'GraphQL_ID must not be empty');

        slotCounts[slot] = (slotCounts[slot] ?? 0) + 1;
        slotClasses.putIfAbsent(slot, () => <String>{}).add(axieClass);
      }

      // 36 Horns, 36 Backs, 36 Tails, 24 Mouths, 36 Eyes, 36 Ears
      expect(slotCounts['Horn'], equals(36));
      expect(slotCounts['Back'], equals(36));
      expect(slotCounts['Tail'], equals(36));
      expect(slotCounts['Mouth'], equals(24));
      expect(slotCounts['Eyes'], equals(36));
      expect(slotCounts['Ears'], equals(36));

      // All 6 classes represented in all 6 slots
      const expectedClasses = {'Beast', 'Aquatic', 'Plant', 'Bird', 'Bug', 'Reptile'};
      for (final slot in ['Horn', 'Back', 'Tail', 'Mouth', 'Eyes', 'Ears']) {
        expect(slotClasses[slot], equals(expectedClasses), reason: 'Slot $slot must contain all 6 classes');
      }
    });

    test('Test 3: Secondary dataset exists and contains exactly 289 lines (1 header + 288 permutations)', () {
      expect(permStatsFile.existsSync(), isTrue, reason: 'assets/data/mouth_tail_permutation_floops.csv must exist');

      final lines = permStatsFile
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty)
          .toList();

      expect(lines.length, equals(289), reason: 'Must contain exactly 1 header + 288 data rows');
      expect(lines.first, equals('permutation_mouth_tail,Axie_amount'));
    });

    test('Test 4: Permutation dataset format and numeric integrity', () {
      final lines = permStatsFile
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty)
          .toList();

      final dataRows = lines.sublist(1);
      final Set<String> uniqueKeys = {};

      for (final row in dataRows) {
        final cols = row.split(',');
        expect(cols.length, equals(2), reason: 'Each row must have 2 columns: permutation_mouth_tail,Axie_amount');

        final key = cols[0].trim();
        final amount = int.tryParse(cols[1].trim());

        expect(key.contains('__'), isTrue, reason: 'Permutation key must contain separator __: $key');
        expect(key.startsWith('mouth-'), isTrue, reason: 'Key must start with mouth slug: $key');
        expect(key.contains('__tail-'), isTrue, reason: 'Key must contain tail slug: $key');

        expect(amount, isNotNull, reason: 'Axie_amount must be a valid integer: $row');
        expect(amount! >= 0, isTrue, reason: 'Axie_amount must be non-negative: $amount');

        uniqueKeys.add(key);
      }

      expect(uniqueKeys.length, equals(288), reason: 'All 288 permutations must be unique');
    });

    test('Test 5: Demographic density sanity check for hyper-common parts (>1,000,000 minted)', () {
      final lines = partStatsFile
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty)
          .toList();

      final Map<String, int> countsBySlug = {};
      for (final row in lines.sublist(1)) {
        final cols = row.split(',');
        countsBySlug[cols[3].trim()] = int.parse(cols[4].trim());
      }

      // Check hyper-common parts on the Ronin network
      expect(countsBySlug['mouth-serious']! > 1000000, isTrue, reason: 'mouth-serious should exceed 1M axies');
      expect(countsBySlug['tail-carrot']! > 1000000, isTrue, reason: 'tail-carrot should exceed 1M axies');
      expect(countsBySlug['mouth-nut-cracker']! > 1000000, isTrue, reason: 'mouth-nut-cracker should exceed 1M axies');
      expect(countsBySlug['tail-nimo']! > 1000000, isTrue, reason: 'tail-nimo should exceed 1M axies');
    });
  });
}
