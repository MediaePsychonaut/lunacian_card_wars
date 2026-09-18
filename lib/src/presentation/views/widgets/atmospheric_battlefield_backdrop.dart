// ===============================================================================
// [MODULE_NAME]: atmospheric_battlefield_backdrop.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views / Widgets
// [INTENT]: Renders an atmospheric animated particle background for the game menus.
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
  State<AtmosphericBattlefieldBackdrop> createState() => _AtmosphericBattlefieldBackdropState();
}

class _AtmosphericBattlefieldBackdropState extends State<AtmosphericBattlefieldBackdrop> with SingleTickerProviderStateMixin {
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
          painter: _VignettePainter(),
        ),
        CustomPaint(
          painter: _ParticlePainter(animation: _controller),
        ),
        widget.child,
      ],
    );
  }
}

class _VignettePainter extends CustomPainter {
  final Paint _paint = Paint();
  Size _lastSize = Size.zero;

  _VignettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Regenerate shader only when canvas size changes — zero per-frame allocation.
    if (size != _lastSize) {
      _lastSize = size;
      _paint.shader = const RadialGradient(
        colors: [Color(0xFF181D26), Color(0xFF0A0C10)],
        center: Alignment.center,
        radius: 0.8,
      ).createShader(rect);
    }
    canvas.drawRect(rect, _paint);
  }

  @override
  bool shouldRepaint(covariant _VignettePainter oldDelegate) => false;
}

class _Mote {
  final double x;
  final double y;
  final double radius;
  final Color baseColor;
  final double speed;
  final double alphaPhase;
  final bool isCyan;

  _Mote({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseColor,
    required this.speed,
    required this.alphaPhase,
    required this.isCyan,
  });
}

class _ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Mote> _motes = [];
  final Paint _cyanPaint;
  final Paint _amberPaint;

  _ParticlePainter({required this.animation})
      : _cyanPaint = Paint()..style = PaintingStyle.fill,
        _amberPaint = Paint()..style = PaintingStyle.fill,
        super(repaint: animation) {
    final random = math.Random(42); // fixed seed for consistency
    final cyanColor = const Color(0xFF00E5FF);
    final amberColor = const Color(0xFFFFB812);
    for (int i = 0; i < 40; i++) {
      final isCyan = i % 2 == 0;
      _motes.add(_Mote(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: 1.5 + random.nextDouble() * 2.0,
        baseColor: isCyan ? cyanColor : amberColor,
        speed: 0.04 + random.nextDouble() * 0.08,
        alphaPhase: random.nextDouble() * 2 * math.pi,
        isCyan: isCyan,
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    for (final mote in _motes) {
      final currentY = (mote.y - t * mote.speed) % 1.0;
      final computedAlpha = (0.4 + 0.4 * math.sin(t * 2 * math.pi + mote.alphaPhase)).clamp(0.1, 0.8);
      
      final paint = mote.isCyan ? _cyanPaint : _amberPaint;
      paint.color = mote.baseColor.withValues(alpha: computedAlpha);
      
      canvas.drawCircle(
        Offset(mote.x * size.width, currentY * size.height),
        mote.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
