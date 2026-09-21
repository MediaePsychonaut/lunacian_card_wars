// ===============================================================================
// [MODULE_NAME]: axie_stat_calibrator.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Services
// [INTENT]: Deterministic proportional 9 x C Base Stat Total (BST) calibrator with anatomical class and part bias shifts.
// [DEPENDENCIES]: ../entities/axie_card_entity.dart
// [ARCHITECTURE]: Pure Domain Stateless Service Pattern
// ===============================================================================

import '../entities/axie_card_entity.dart';

/// Immutable container holding calibrated Axie statistics.
/// Strictly enforces the total stat conservation law: [atk] + [def] == [bstTotal].
class CalibratedAxieStats {
  final int bstTotal;
  final int atk;
  final int def;
  final double ratioR;

  const CalibratedAxieStats({
    required this.bstTotal,
    required this.atk,
    required this.def,
    required this.ratioR,
  }) : assert(
          atk >= 0,
          'ATK cannot be less than 0: $atk',
        ),
       assert(
          def >= 0,
          'DEF cannot be less than 0: $def',
        ),
       assert(
          atk + def == bstTotal,
          'Total stat conservation invariant violated: atk ($atk) + def ($def) != bstTotal ($bstTotal)',
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalibratedAxieStats &&
          runtimeType == other.runtimeType &&
          bstTotal == other.bstTotal &&
          atk == other.atk &&
          def == other.def &&
          (ratioR - other.ratioR).abs() < 1e-9;

  @override
  int get hashCode => Object.hash(bstTotal, atk, def, ratioR);

  @override
  String toString() =>
      'CalibratedAxieStats(BST: $bstTotal, ATK: $atk, DEF: $def, R: ${ratioR.toStringAsFixed(4)})';
}

/// Pure deterministic service responsible for calculating Axie ATK and DEF
/// from on-chain mana cost (C in [1, 7]), evolved parts (N in [0, 6]),
/// body elemental class, horn/back anatomical affinities, floop orientation, and base stats.
class AxieStatCalibrator {
  const AxieStatCalibrator._();

  static const double rMin = 0.25;
  static const double rMax = 0.75;

  /// Returns the base ATK/DEF ratio for a given body class.
  static double getBaseClassRatio(AxieElementalClass axieClass) {
    return switch (axieClass) {
      AxieElementalClass.bird => 0.60,
      AxieElementalClass.beast => 0.56,
      AxieElementalClass.aquatic => 0.48,
      AxieElementalClass.bug => 0.44,
      AxieElementalClass.reptile => 0.36,
      AxieElementalClass.plant => 0.30,
      _ => 0.45,
    };
  }

  /// Returns the anatomical part bias for a given part class affinity.
  static double getPartBias(AxieElementalClass? partClass) {
    if (partClass == null) return 0.0;
    return switch (partClass) {
      AxieElementalClass.bird || AxieElementalClass.beast => 0.04,
      AxieElementalClass.aquatic => 0.02,
      AxieElementalClass.bug => 0.00,
      AxieElementalClass.reptile => -0.02,
      AxieElementalClass.plant => -0.04,
      _ => 0.00,
    };
  }

  /// Resolves an [AxieElementalClass] enum from a string representation.
  static AxieElementalClass parseClass(String? className) {
    if (className == null) return AxieElementalClass.unknown;
    return switch (className.toLowerCase().trim()) {
      'beast' => AxieElementalClass.beast,
      'aquatic' || 'aqua' => AxieElementalClass.aquatic,
      'plant' => AxieElementalClass.plant,
      'bird' => AxieElementalClass.bird,
      'bug' => AxieElementalClass.bug,
      'reptile' => AxieElementalClass.reptile,
      'mech' => AxieElementalClass.mech,
      'dusk' => AxieElementalClass.dusk,
      'dawn' => AxieElementalClass.dawn,
      _ => AxieElementalClass.unknown,
    };
  }

  /// Calibrates ATK and DEF for an Axie according to the Cycle 12.2 specification:
  ///
  /// 1. BST Base: 9 * C, where C in [1, 7]
  /// 2. Delta Evolved: floor((numEvolvedParts * C) / 6), where numEvolvedParts in [0, 6]
  /// 3. BST Total = BST Base + Delta Evolved
  /// 4. rawR = classRatio + hornBias - backBias + floopBias + statVariance
  ///    - floopBias = isMouthFloop ? +0.04 : -0.04
  ///    - statVariance = ((speed + skill) - (hp + morale)) / 600.0
  /// 5. Clamped R in [0.25, 0.75]
  /// 6. ATK = round(BST Total * R)
  /// 7. DEF = BST Total - ATK
  ///
  /// Strictly guarantees ATK + DEF == BST Total.
  static CalibratedAxieStats calibrate({
    required int manaCost,
    required AxieElementalClass bodyClass,
    AxieElementalClass? hornClass,
    AxieElementalClass? backClass,
    int numEvolvedParts = 0,
    bool isMouthFloop = true,
    int hp = 0,
    int speed = 0,
    int skill = 0,
    int morale = 0,
  }) {
    final c = manaCost.clamp(1, 7);
    final nEvolved = numEvolvedParts.clamp(0, 6);
    final bstBase = 9 * c;
    final deltaEvolved = (nEvolved * c) ~/ 6;
    final bstTotal = bstBase + deltaEvolved;

    final classRatio = getBaseClassRatio(bodyClass);
    final hornBias = getPartBias(hornClass);
    final backBias = getPartBias(backClass);
    final floopBias = isMouthFloop ? 0.04 : -0.04;
    final statVariance = ((speed + skill) - (hp + morale)) / 600.0;

    final rawR = classRatio + hornBias - backBias + floopBias + statVariance;
    final ratioR = rawR.clamp(rMin, rMax);

    final rawAtk = (bstTotal * ratioR).round();
    final atk = rawAtk.clamp(0, bstTotal);
    final def = (bstTotal - atk).clamp(0, bstTotal);

    return CalibratedAxieStats(
      bstTotal: bstTotal,
      atk: atk,
      def: def,
      ratioR: ratioR,
    );
  }
}
