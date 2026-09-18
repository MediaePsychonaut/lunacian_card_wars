// ===============================================================================
// [MODULE_NAME]: axie_card_standee.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Widgets
// [INTENT]: Standee rendering with primary -> proxy -> placeholder fallback cascade.
// [DEPENDENCIES]: flutter, axie_card_entity.dart
// [ARCHITECTURE]: Stateless Presentation Widget
// ===============================================================================

import 'package:flutter/material.dart';
import '../../../domain/entities/axie_card_entity.dart';

class AxieCardStandee extends StatelessWidget {
  final AxieCardEntity axie;
  const AxieCardStandee({super.key, required this.axie});

  Color _getClassColor(AxieElementalClass axieClass) {
    switch (axieClass) {
      case AxieElementalClass.beast: return const Color(0xFFFFB812);
      case AxieElementalClass.aquatic: return const Color(0xFF00B8CE);
      case AxieElementalClass.plant: return const Color(0xFF6CC000);
      case AxieElementalClass.bird: return const Color(0xFFFF8BBD);
      case AxieElementalClass.bug: return const Color(0xFFFF5341);
      case AxieElementalClass.reptile: return const Color(0xFFA045E6);
      case AxieElementalClass.mech: return const Color(0xFF769B9B);
      case AxieElementalClass.dusk: return const Color(0xFF129092);
      case AxieElementalClass.dawn: return const Color(0xFFBECEFF);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final classColor = _getClassColor(axie.axieClass);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E222D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: classColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cost: ${axie.manaCost}',
                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                axie.axieClass.name.toUpperCase(),
                style: TextStyle(color: classColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Image.network(
                axie.spriteUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorBuilder: (_, _, _) => Image.network(
                  axie.proxySpriteUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorBuilder: (_, _, _) => _buildFallbackVisual(classColor),
                ),
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                axie.maxPips,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Icon(
                    i < axie.initialPips ? Icons.circle : Icons.circle_outlined,
                    size: 10,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ATK: ${axie.baseAtk}',
                style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Text(
                'DEF: ${axie.baseDef}',
                style: const TextStyle(color: Color(0xFF51CF66), fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackVisual(Color classColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, size: 48, color: classColor.withValues(alpha: 0.6)),
        const SizedBox(height: 6),
        Text(
          axie.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
