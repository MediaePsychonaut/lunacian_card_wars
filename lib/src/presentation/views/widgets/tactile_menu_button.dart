// ===============================================================================
// [MODULE_NAME]: tactile_menu_button.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Presentation / Views / Widgets
// [INTENT]: Interactive menu button with hover scale and glow effect.
// [DEPENDENCIES]: package:flutter/material.dart
// [ARCHITECTURE]: StatefulWidget
// ===============================================================================

import 'package:flutter/material.dart';

class TactileMenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color glowColor;
  final VoidCallback onPressed;

  const TactileMenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.glowColor,
    required this.onPressed,
  });

  @override
  State<TactileMenuButton> createState() => _TactileMenuButtonState();
}

class _TactileMenuButtonState extends State<TactileMenuButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _hovered ? 360 : 340,
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: _hovered ? 0.6 : 0.0),
                blurRadius: _hovered ? 18 : 6,
                spreadRadius: 2,
              )
            ],
            border: Border.all(
              color: _hovered ? widget.glowColor : Colors.white24,
              width: 2,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: _hovered ? widget.glowColor : Colors.white70),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: _hovered ? Colors.white : Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
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
