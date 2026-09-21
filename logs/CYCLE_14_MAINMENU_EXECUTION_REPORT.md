# Cycle 14 AC-01 — Main Menu Immersion Execution Report

**Date:** 2026-09-21  
**Cycle:** 14  
**Acceptance Criterion:** AC-01 — Full Tavern Main Menu Immersion  
**Engineer:** Antigravity (AI Coding Agent)

---

## VERDICT: [COMPLETE]

---

## Files Modified

| File | Action | Issues |
|------|--------|--------|
| `lib/src/presentation/views/main_menu_view.dart` | Full rewrite | 0 |
| `lib/src/presentation/views/widgets/atmospheric_battlefield_backdrop.dart` | Full upgrade | 0 |

---

## Static Analysis

```
dart analyze lib/src/presentation/views/main_menu_view.dart \
             lib/src/presentation/views/widgets/atmospheric_battlefield_backdrop.dart

Analyzing main_menu_view.dart, atmospheric_battlefield_backdrop.dart...
No issues found!
```

> Note: `dart analyze --fatal-infos` on the whole project surfaces 3 pre-existing issues in `arena_view.dart` (1 `unused_local_variable` warning, 2 `unnecessary_underscores` infos) that are unrelated to this cycle's changes.

---

## Test Suite

```
flutter test --reporter=compact
00:05 +64: All tests passed!
```

**Result:** 64 / 64 tests passed — zero regressions.

---

## Implementation Summary

### `main_menu_view.dart` (Full Rewrite)

- **`MainMenuView`** — `ConsumerWidget`, wraps everything in `AtmosphericBattlefieldBackdrop` then a `Stack` containing a `Column` + Buba overlay.

- **`_LogoSection`** — `StatefulWidget` with `AnimationController(4s, repeat+reverse)`. Oscillation via `Transform.translate(Offset(0, 7 * sin(t * 2pi)))`. Loads `assets/images/logo.jfif` at height 120. Error fallback: golden bold Text. Subtitle: `'AXIE VIBEATHON 2026'` in `#FFB812`, letterSpacing 3.0, size 14.

- **`_DioramaBoard`** — `Transform` with `Matrix4..setEntry(3,2,0.001)..rotateX(-0.25)` for 2.5D perspective tilt. Container: `#6B3A1F` warm brown, 12px radius, `#FFB400` border width 3. Top row: 4 `_LaneMedallion` widgets (52x52 circles). Bottom: `Expanded` row of 4 `_LaneZone` widgets.

- **`_LaneMedallion`** — 52x52 circle with lane color, glow BoxShadow, white Icon size 24.

- **`_LaneZone`** — `Expanded` container with lane color at alpha 0.15, `Image.asset` of class PNG with `colorBlendMode: BlendMode.srcIn` (white silhouette effect), errorBuilder falls back to icon.

- **`_BubaStandee`** — `Positioned(right: 20, bottom: 100)`, `Transform.rotate(angle: 0.05)`, loads beast.png at height 140. Error fallback: `Icon(Icons.smart_toy, size: 80, color: Color(0xFF4FC3F7))`.

- **`_BottomDock`** — `Container(height: 88)`, `#5C2E00`, top border `#FFB400` width 2, upward amber glow BoxShadow. Row: DECK, VAULT (WoodButtons), BATTLE! (BattleButton), SETTINGS (WoodButton).

- **`_WoodButton`** — `StatefulWidget`, `MouseRegion` hover detection, `AnimatedScale(1.07)` on hover, `80x70` container `#3D1A00`, border switches to glowColor on hover.

- **`_BattleButton`** — `StatefulWidget` with `AnimationController(1.5s, repeat+reverse)`. Pill shape `borderRadius 28`, gradient `#E53935->#B71C1C`. Amber BoxShadow pulsing at `pulseValue * 0.7` alpha. Text `'BATTLE!'` size 20, bold, white, letterSpacing 2.0.

### `atmospheric_battlefield_backdrop.dart` (Upgrade)

- Background gradient: Radial `#2C1810 -> #0F0806` (warm dark brown to near-black, replaces cold blue-black).
- Particles: 40 motes, 50/50 amber `#FFB812` / warm gold `#FFD700` — cyan removed entirely.
- Alpha range: 0.2-0.6 (subtler tavern ambiance, previously 0.1-0.8).
- Fixed seed `Random(42)` — deterministic layout preserved.
- `shouldRepaint` returns `true` for continuous animation.
- Renamed painter classes (`_TavernVignettePainter`, `_TavernParticlePainter`) to reflect theme identity.

---

## Constraint Checklist

| Constraint | Status |
|---|---|
| 0 `.withOpacity()` calls | PASS — all opacity via `.withValues(alpha: ...)` |
| 6-field AST header in both files | PASS |
| 0 RenderFlex overflows — `Expanded`/`Flexible` used throughout | PASS |
| 0 legacy IP terms | PASS |
| Navigation via `appNavigationProvider.notifier.navigateTo(AppScreenState.x)` | PASS |
| Logo fallback to golden bold Text (not Icon) | PASS |
| `_BattleButton` navigates to `AppScreenState.play` | PASS |
| 64 tests passing | PASS |
