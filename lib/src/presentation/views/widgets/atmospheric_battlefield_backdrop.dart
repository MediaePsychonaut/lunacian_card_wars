// ===============================================================================
// [MODULE_NAME]: atmospheric_battlefield_backdrop.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views / Widgets
// [INTENT]: Renders a warm tavern-themed animated particle background for the main menu.
// [DEPENDENCIES]: package:flutter/material.dart, dart:math
// [ARCHITECTURE]: StatefulWidget with AnimationController and CustomPainter
// ===============================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;

class AtmosphericBattlefieldBackdrop extends StatefulWidget {
  final Widget child;

  const AtmosphericBattlefieldBackdrop({
    super.key,
    required this.child,
  });

  @override
  State<AtmosphericBattlefieldBackdrop> createState() =>
      _AtmosphericBattlefieldBackdropState();
}

class _AtmosphericBattlefieldBackdropState
    extends State<AtmosphericBattlefieldBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _TavernVignettePainter(),
        ),
        CustomPaint(
          painter: _TavernParticlePainter(animation: _controller),
        ),
        widget.child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Warm tavern radial background painter — dark oak browns, not cold blue-black
// ---------------------------------------------------------------------------
class _TavernVignettePainter extends CustomPainter {
  final Paint _paint = Paint();
  Size _lastSize = Size.zero;

  _TavernVignettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Regenerate shader only when canvas size changes — zero per-frame allocation.
    if (size != _lastSize) {
      _lastSize = size;
      _paint.shader = const RadialGradient(
        // Warm dark brown center (#2C1810) → near-black warm edge (#0F0806)
        colors: [Color(0xFF2C1810), Color(0xFF0F0806)],
        center: Alignment.center,
        radius: 0.85,
      ).createShader(rect);
    }
    canvas.drawRect(rect, _paint);
  }

  @override
  bool shouldRepaint(covariant _TavernVignettePainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Mote data — immutable value type for each ambient dust particle
// ---------------------------------------------------------------------------
class _Mote {
  final double x;
  final double y;
  final double radius;
  final Color baseColor;
  final double speed;
  final double alphaPhase;
  final bool isGold; // true → warm gold #FFD700, false → amber #FFB812

  const _Mote({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseColor,
    required this.speed,
    required this.alphaPhase,
    required this.isGold,
  });
}

// ---------------------------------------------------------------------------
// Tavern particle painter — 40 motes, 50/50 amber / warm gold, no cyan
// ---------------------------------------------------------------------------
class _TavernParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Mote> _motes = [];
  final Paint _goldPaint;
  final Paint _amberPaint;

  _TavernParticlePainter({required this.animation})
      : _goldPaint = Paint()..style = PaintingStyle.fill,
        _amberPaint = Paint()..style = PaintingStyle.fill,
        super(repaint: animation) {
    // Fixed seed for deterministic layout across hot reloads.
    final random = math.Random(42);
    const amberColor = Color(0xFFFFB812);
    const goldColor = Color(0xFFFFD700);
    for (int i = 0; i < 40; i++) {
      final isGold = i % 2 == 0; // 50/50 split
      _motes.add(_Mote(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: 1.2 + random.nextDouble() * 2.0,
        baseColor: isGold ? goldColor : amberColor,
        speed: 0.03 + random.nextDouble() * 0.07,
        alphaPhase: random.nextDouble() * 2 * math.pi,
        isGold: isGold,
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    for (final mote in _motes) {
      // Drift upward; wrap with modulo so motes loop seamlessly.
      final currentY = (mote.y - t * mote.speed) % 1.0;
      // Alpha subtler: 0.2–0.6 range for gentle tavern ambiance.
      final computedAlpha =
          (0.2 + 0.4 * math.sin(t * 2 * math.pi + mote.alphaPhase))
              .clamp(0.2, 0.6);

      final paint = mote.isGold ? _goldPaint : _amberPaint;
      paint.color = mote.baseColor.withValues(alpha: computedAlpha);

      canvas.drawCircle(
        Offset(mote.x * size.width, currentY * size.height),
        mote.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TavernParticlePainter oldDelegate) => true;
}
