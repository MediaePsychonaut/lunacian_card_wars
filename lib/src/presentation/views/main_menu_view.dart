// ===============================================================================
// [MODULE_NAME]: main_menu_view.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views
// [INTENT]: Full tavern main-menu immersion — logo, 2.5D diorama board, lane
//           medallions, creature zones, Buba standee overlay, and carved-wood
//           navigation dock. Implements AC-01 of Cycle 14.
// [DEPENDENCIES]: package:flutter/material.dart, package:flutter_riverpod/flutter_riverpod.dart,
//                 dart:math, widgets/atmospheric_battlefield_backdrop.dart,
//                 ../controllers/app_navigation_controller.dart
// [ARCHITECTURE]: ConsumerWidget (Riverpod) with nested StatefulWidget animations
// ===============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/app_navigation_controller.dart';
import 'widgets/atmospheric_battlefield_backdrop.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Lane descriptor — one entry per elemental lane on the diorama board
// ─────────────────────────────────────────────────────────────────────────────
class _LaneInfo {
  final String label;
  final Color color;
  final IconData medallionIcon;
  final IconData zoneIcon;
  final String assetPath;

  const _LaneInfo({
    required this.label,
    required this.color,
    required this.medallionIcon,
    required this.zoneIcon,
    required this.assetPath,
  });
}

const List<_LaneInfo> _lanes = [
  _LaneInfo(
    label: 'Beast',
    color: Color(0xFFFFB800),
    medallionIcon: Icons.pets,
    zoneIcon: Icons.pets,
    assetPath: 'assets/images/classes/beast.png',
  ),
  _LaneInfo(
    label: 'Aquatic',
    color: Color(0xFF00B4D8),
    medallionIcon: Icons.water_drop,
    zoneIcon: Icons.water_drop,
    assetPath: 'assets/images/classes/aquatic.png',
  ),
  _LaneInfo(
    label: 'Plant',
    color: Color(0xFF48BB78),
    medallionIcon: Icons.eco,
    zoneIcon: Icons.eco,
    assetPath: 'assets/images/classes/plant.png',
  ),
  _LaneInfo(
    label: 'Bird',
    color: Color(0xFFFF69B4),
    medallionIcon: Icons.air,
    zoneIcon: Icons.air,
    assetPath: 'assets/images/classes/bird.png',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MainMenuView — root ConsumerWidget
// ─────────────────────────────────────────────────────────────────────────────
class MainMenuView extends ConsumerWidget {
  const MainMenuView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AtmosphericBattlefieldBackdrop(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Main column layout ──────────────────────────────────────────
          Column(
            children: [
              // Logo + subtitle  (flex 2)
              Expanded(
                flex: 2,
                child: _LogoSection(),
              ),

              // Diorama board  (flex 5, capped at 900 px wide)
              Expanded(
                flex: 5,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const _DioramaBoard(),
                    ),
                  ),
                ),
              ),

              // Bottom navigation dock  (fixed 88 px)
              _BottomDock(ref: ref),
            ],
          ),

          // ── Buba rival standee overlay ──────────────────────────────────
          const _BubaStandee(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LogoSection — oscillating logo image + subtitle
// ─────────────────────────────────────────────────────────────────────────────
class _LogoSection extends StatefulWidget {
  @override
  State<_LogoSection> createState() => _LogoSectionState();
}

class _LogoSectionState extends State<_LogoSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Oscillating logo
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                0,
                7 * math.sin(_controller.value * 2 * math.pi),
              ),
              child: child,
            );
          },
          child: Image.asset(
            'assets/images/logo.jfif',
            height: 120,
            errorBuilder: (context, error, stackTrace) => const Text(
              'LUNACIAN CARD WARS',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        const Text(
          'AXIE VIBEATHON 2026',
          style: TextStyle(
            color: Color(0xFFFFB812),
            fontSize: 14,
            letterSpacing: 3.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DioramaBoard — the 2.5D perspective-tilted game board
// ─────────────────────────────────────────────────────────────────────────────
class _DioramaBoard extends StatelessWidget {
  const _DioramaBoard();

  @override
  Widget build(BuildContext context) {
    // 2.5D perspective tilt — rotateX pulls the top away, setEntry(3,2) adds
    // a slight perspective distortion so far edges compress.
    final Matrix4 tilt = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(-0.25);

    return Transform(
      transform: tilt,
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6B3A1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB400), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ── Medallion row across the front edge ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _lanes
                  .map((lane) => _LaneMedallion(lane: lane))
                  .toList(),
            ),

            const SizedBox(height: 8),

            // ── Four elemental zone tiles ─────────────────────────────────
            Expanded(
              child: Row(
                children: _lanes
                    .map((lane) => Expanded(child: _LaneZone(lane: lane)))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LaneMedallion — 52×52 circular badge for each lane class
// ─────────────────────────────────────────────────────────────────────────────
class _LaneMedallion extends StatelessWidget {
  final _LaneInfo lane;

  const _LaneMedallion({required this.lane});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lane.color,
        boxShadow: [
          BoxShadow(
            color: lane.color.withValues(alpha: 0.6),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          lane.medallionIcon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LaneZone — a single elemental lane area with creature badge
// ─────────────────────────────────────────────────────────────────────────────
class _LaneZone extends StatelessWidget {
  final _LaneInfo lane;

  const _LaneZone({required this.lane});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: lane.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: lane.color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Center(
        child: Image.asset(
          lane.assetPath,
          width: 40,
          height: 40,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (context, error, stackTrace) => Icon(
            lane.zoneIcon,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BubaStandee — Buba rival NPC overlay (right side, slight lean)
// ─────────────────────────────────────────────────────────────────────────────
class _BubaStandee extends StatelessWidget {
  const _BubaStandee();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 100,
      child: Transform.rotate(
        angle: 0.05,
        child: Image.asset(
          'assets/images/classes/beast.png',
          height: 140,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 80,
            height: 140,
            alignment: Alignment.center,
            child: const Icon(
              Icons.smart_toy,
              size: 80,
              color: Color(0xFF4FC3F7),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomDock — warm wooden navigation dock (fixed height 88)
// ─────────────────────────────────────────────────────────────────────────────
class _BottomDock extends StatelessWidget {
  final WidgetRef ref;

  const _BottomDock({required this.ref});

  void _nav(AppScreenState screen) =>
      ref.read(appNavigationProvider.notifier).navigateTo(screen);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: Color(0xFF5C2E00),
        border: Border(
          top: BorderSide(color: Color(0xFFFFB400), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66FFB400),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _WoodButton(
            icon: Icons.style,
            label: 'DECK',
            glowColor: const Color(0xFFFFB812),
            onTap: () => _nav(AppScreenState.deckbuilder),
          ),
          _WoodButton(
            icon: Icons.inventory_2,
            label: 'VAULT',
            glowColor: const Color(0xFF6CC000),
            onTap: () => _nav(AppScreenState.axieVault),
          ),
          _BattleButton(onTap: () => _nav(AppScreenState.play)),
          _WoodButton(
            icon: Icons.settings,
            label: 'SETTINGS',
            glowColor: const Color(0xFFA045E6),
            onTap: () => _nav(AppScreenState.settings),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _WoodButton — carved wooden nav button with hover scale
// ─────────────────────────────────────────────────────────────────────────────
class _WoodButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color glowColor;
  final VoidCallback onTap;

  const _WoodButton({
    required this.icon,
    required this.label,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<_WoodButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.07 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 80,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF3D1A00),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered ? widget.glowColor : const Color(0xFF8B5E00),
                width: 1.5,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.glowColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: 22, color: widget.glowColor),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BattleButton — pulsing red pill BATTLE! CTA button
// ─────────────────────────────────────────────────────────────────────────────
class _BattleButton extends StatefulWidget {
  final VoidCallback onTap;

  const _BattleButton({required this.onTap});

  @override
  State<_BattleButton> createState() => _BattleButtonState();
}

class _BattleButtonState extends State<_BattleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final pulseValue = _pulse.value; // 0.0 → 1.0 → 0.0
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 180,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB812)
                      .withValues(alpha: pulseValue * 0.7),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                  color: Color(0x66E53935),
                  blurRadius: 8,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'BATTLE!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
          ),
        );
      },
    );
  }
}
