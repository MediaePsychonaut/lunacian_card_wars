---
type: sub_directive
id: SUB_DIRECTIVE_CYCLE_10_MAIN_HUB_AND_ATMOSPHERE
cycle: 10
version: 1.0
status: dispatched
target_agent: ui_agent
author: der_tab (Director / Meta-Orchestrator)
created_at: 2026-09-16T21:52:00-06:00
system: lunacian_card_wars
tags:
  - navigation
  - atmosphere
  - ui_architecture
---

# SUB-DIRECTIVE: Cycle 10 — Main Hub Navigation & Atmospheric Tabletop Stage

## 0. Codebase Snapshot (Pre-Execution State)

The following files exist and MUST NOT have their domain logic altered:

| File | Role | Mutate? |
|:---|:---|:---|
| `lib/main.dart` | Entry point; currently points to `AxieImporterDashboard` | **YES** — Reroute to `RootView` |
| `lib/src/domain/entities/axie_card_entity.dart` | Pure domain entity; mana formulas, pip logic | **NO** — Frozen |
| `lib/src/data/datasources/axie_marketplace_remote_datasource.dart` | Remote GraphQL data source | **NO** — Frozen |
| `lib/src/data/datasources/axie_graphql_queries.dart` | GraphQL query strings | **NO** — Frozen |
| `lib/src/presentation/controllers/axie_importer_controller.dart` | Riverpod `AsyncNotifierProvider` for Axie collection | **NO** — Provider stays intact; add only the new nav provider alongside |
| `lib/src/presentation/views/axie_importer_dashboard.dart` | Current monolithic dashboard | **REPLACED** — Content migrated to `axie_vault_view.dart`; file becomes a thin alias or is deleted |
| `lib/src/presentation/views/widgets/axie_card_standee.dart` | Card standee widget | **NO** — Preserved as-is |
| `test/axie_importer_test.dart` | Existing 13-test suite, all passing | **NO** — Must remain 100% green |

---

## 1. Problem Statement

The application currently boots directly into `AxieImporterDashboard`, a raw data-import screen with no game identity or navigation shell. This cycle decouples the experience into a proper game loop: a living Main Menu Hub as the canonical entry point, routing to functional spaces (Axie Vault, Deckbuilder, Arena, Settings), all unified under a dynamic atmospheric backdrop rendered with native CanvasKit `CustomPainter`. No third-party animation libraries. No video loops.

---

## 2. Acceptance Criteria

| ID | Criterion | Binary Gate |
|:---|:---|:---|
| AC-01 | `appNavigationProvider` (Riverpod `Notifier<AppScreenState>`) exists with enum `{ mainMenu, play, deckbuilder, axieVault, settings }` | PASS / FAIL |
| AC-02 | `AtmosphericBattlefieldBackdrop` runs at 60 FPS: dark radial vignette (`#181D26` → `#0A0C10`), ascending mana mote particle system (cyan `#00E5FF` + amber `#FFB812`), floating logo oscillation | PASS / FAIL |
| AC-03 | `TactileMenuButton` has hover scale + glow transitions; four buttons present: PLAY BATTLE (gold), DECKBUILDER (cyan), AXIE VAULT (emerald), SETTINGS (amethyst) | PASS / FAIL |
| AC-04 | `AxieVaultView` hosts all importer functionality; persistent "← Return to Main Menu" bar present; navigating back does NOT reset `axieImporterProvider` state | PASS / FAIL |
| AC-05 | `ArenaView`, `DeckbuilderView`, `SettingsView` scaffolds exist with return buttons | PASS / FAIL |
| AC-06 | `dart analyze --fatal-infos` → 0 issues; `flutter test` → 100% pass (all 13 existing + new navigation tests) | PASS / FAIL |

---

## 3. Constraint Architecture

### 3.1. Stack Invariants
- **Flutter 3.47+ / Dart 3.13+** — use `.withValues(alpha: ...)` everywhere; `.withOpacity()` is **FORBIDDEN**.
- **Riverpod only** — no Navigator 1.0 `push/pop`. Navigation is pure state mutation via `appNavigationProvider`.
- **Clean Architecture** — Presentation layer ONLY. Zero domain mutations.
- **CanvasKit renderer** — Particle system MUST pre-allocate `Paint` objects outside the render loop (`paint()` method). Creating `Paint()` inside `paint()` is a **hard performance violation**.
- **AST Header compliance** — Every file written or modified must open with the 6-field AST block.

### 3.2. File Mutation Budget

**CREATE (8 new files):**
```
lib/src/presentation/controllers/app_navigation_controller.dart
lib/src/presentation/views/root_view.dart
lib/src/presentation/views/main_menu_view.dart
lib/src/presentation/views/axie_vault_view.dart
lib/src/presentation/views/arena_view.dart
lib/src/presentation/views/deckbuilder_view.dart
lib/src/presentation/views/settings_view.dart
lib/src/presentation/views/widgets/atmospheric_battlefield_backdrop.dart
lib/src/presentation/views/widgets/tactile_menu_button.dart
test/navigation_test.dart
```

**MODIFY (1 file):**
```
lib/main.dart  — Change home: AxieImporterDashboard() → home: RootView()
                 Update [DEPENDENCIES] and [INTENT] in AST header.
```

**RETIRE (1 file):**
```
lib/src/presentation/views/axie_importer_dashboard.dart
  — All UI code migrated to axie_vault_view.dart.
  — File must be DELETED (not left as dead import bait).
```

### 3.3. Provider State Invariant
`axieImporterProvider` is an `AsyncNotifierProvider` with `keepAlive` behavior (it is never autodisposed). Navigation must NOT wrap Axie Vault in any scoping widget that would invalidate the provider. `RootView` must watch `appNavigationProvider` and switch between pre-built widget branches — NOT `Navigator.push/pop`.

---

## 4. Decomposition — Ordered Execution Nodes

> Execute strictly in sequence. Each node depends on the previous.

### Node 1 — Navigation Controller
**File:** `lib/src/presentation/controllers/app_navigation_controller.dart`

```dart
// AST Header required.
enum AppScreenState { mainMenu, play, deckbuilder, axieVault, settings }

class AppNavigationController extends Notifier<AppScreenState> {
  @override
  AppScreenState build() => AppScreenState.mainMenu;

  void navigateTo(AppScreenState screen) => state = screen;
  void returnToMainMenu() => state = AppScreenState.mainMenu;
}

final appNavigationProvider = NotifierProvider<AppNavigationController, AppScreenState>(
  AppNavigationController.new,
);
```

### Node 2 — Atmospheric Backdrop Widget
**File:** `lib/src/presentation/views/widgets/atmospheric_battlefield_backdrop.dart`

- `StatefulWidget` with `SingleTickerProviderStateMixin`.
- `AnimationController` ticking continuously (repeat, duration: `Duration(seconds: 8)`).
- Constructor takes `Widget child`.
- `Stack` layout:
  1. **Bottom layer:** `CustomPaint` with `_VignettePainter` — draws `RadialGradient` from `Color(0xFF181D26)` center to `Color(0xFF0A0C10)` edge filling the canvas.
  2. **Middle layer:** `CustomPaint` with `_ParticlePainter(animation: _controller)` — particle system (details below).
  3. **Top layer:** `child` (the menu content).
- **`_ParticlePainter` specification:**
  - Initialize a fixed list of 40 `_Mote` objects in `_ParticlePainter` constructor (NOT in `paint()`).
  - Each `_Mote` has: `x` (0.0–1.0 normalized), `y` (0.0–1.0 seed offset), `radius` (1.5–3.5), `color` (alternate cyan `Color(0xFF00E5FF)` / amber `Color(0xFFFFB812)`), `speed` (0.04–0.12), `alphaPhase` (random 0–2π).
  - Pre-allocate two `Paint` objects: `_cyanPaint` and `_amberPaint` in the constructor. Set `style = PaintingStyle.fill`.
  - In `paint()`: compute `t = animation.value`. For each mote: `currentY = (mote.y - t * mote.speed) % 1.0`. Alpha: `(0.4 + 0.4 * sin(t * 2π + mote.alphaPhase)).clamp(0.1, 0.8)`. Update paint alpha with `.withValues(alpha: computedAlpha)`. Draw `canvas.drawCircle(...)`.
  - `shouldRepaint` returns `true` always (driven by animation).

### Node 3 — Tactile Menu Button Widget
**File:** `lib/src/presentation/views/widgets/tactile_menu_button.dart`

- `StatefulWidget` tracking `bool _hovered`.
- Constructor params: `String label`, `IconData icon`, `Color glowColor`, `VoidCallback onPressed`.
- `MouseRegion` wrapping an `AnimatedContainer` that transitions:
  - Width: `340` (idle) → `360` (hovered).
  - `BoxDecoration.boxShadow` glow radius: `6` → `18` using `glowColor.withValues(alpha: 0.6)`.
  - Duration: `200ms`.
- Inner `ElevatedButton` with `Row(icon + label)`.
- Do NOT use `Transform.scale` (causes jitter on web); use `AnimatedContainer` width change only.

### Node 4 — Main Menu View
**File:** `lib/src/presentation/views/main_menu_view.dart`

- `ConsumerWidget`.
- Returns `AtmosphericBattlefieldBackdrop(child: ...)`.
- Child is a centered `Column` with:
  1. **Logo block:** `AnimatedBuilder` on `_controller` (passed down or use a separate `SingleTickerProviderStateMixin` in a child `StatefulWidget`). Logo oscillates: `Transform.translate(offset: Offset(0, 6 * sin(animation.value * 2 * pi)))`. Wrap in `Image.asset('assets/images/logo.png', height: 140)` with error fallback. Below logo: subtitle text `'VIBEATHON EDITION'` in amber/gold, letter-spaced.
  2. `SizedBox(height: 40)`.
  3. Four `TactileMenuButton` instances:
     - `PLAY BATTLE` → `glowColor: Color(0xFFFFB812)` → `navigateTo(AppScreenState.play)`.
     - `DECKBUILDER` → `glowColor: Color(0xFF00E5FF)` → `navigateTo(AppScreenState.deckbuilder)`.
     - `AXIE VAULT` → `glowColor: Color(0xFF6CC000)` → `navigateTo(AppScreenState.axieVault)`.
     - `SETTINGS` → `glowColor: Color(0xFFA045E6)` → `navigateTo(AppScreenState.settings)`.

> **Important:** `MainMenuView` must NOT own the `AnimationController` for the backdrop particles — that is internal to `AtmosphericBattlefieldBackdrop`. The logo animation uses its own internal `AnimationController` with `repeat(reverse: true)`, duration `Duration(seconds: 3)`.

### Node 5 — Axie Vault View
**File:** `lib/src/presentation/views/axie_vault_view.dart`

- `ConsumerStatefulWidget` — transplant ALL logic from `axie_importer_dashboard.dart`.
- Wrap in `AtmosphericBattlefieldBackdrop(child: Scaffold(backgroundColor: Colors.transparent, body: ...))`.
- Top bar: `Row` containing `TextButton.icon(icon: Icons.arrow_back, label: 'Return to Menu', onPressed: () => ref.read(appNavigationProvider.notifier).returnToMainMenu())`. Styled in amber. No `AppBar`.
- Below top bar: the existing `TextField` / `ElevatedButton` import row, then the `GridView.builder` with `AxieCardStandee` cards.
- Uses `ref.watch(axieImporterProvider)` exactly as the old dashboard did.
- **Critical:** Do NOT `invalidate` or `refresh` the provider on init or dispose.

### Node 6 — Scaffold Placeholder Views (×3)
**Files:** `arena_view.dart`, `deckbuilder_view.dart`, `settings_view.dart`

Each follows the same template:
```
AtmosphericBattlefieldBackdrop(
  child: Scaffold(
    backgroundColor: Colors.transparent,
    body: Column([
      _buildTopBar(ref, title),   // Back button row
      Expanded(Center(Text('COMING SOON', style: ...))),
    ]),
  ),
)
```

### Node 7 — Root View Switcher
**File:** `lib/src/presentation/views/root_view.dart`

```dart
class RootView extends ConsumerWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(appNavigationProvider);
    return switch (screen) {
      AppScreenState.mainMenu    => const MainMenuView(),
      AppScreenState.play        => const ArenaView(),
      AppScreenState.deckbuilder => const DeckbuilderView(),
      AppScreenState.axieVault   => const AxieVaultView(),
      AppScreenState.settings    => const SettingsView(),
    };
  }
}
```

### Node 8 — main.dart Update
- Change `home: const AxieImporterDashboard()` → `home: const RootView()`.
- Update import: remove `axie_importer_dashboard.dart`, add `src/presentation/views/root_view.dart`.
- Update AST `[DEPENDENCIES]` and `[INTENT]` fields accordingly.

### Node 9 — Delete Retired File
- Delete `lib/src/presentation/views/axie_importer_dashboard.dart`.
- Verify no remaining imports reference this file (`grep` across lib/).

### Node 10 — Test Suite: `test/navigation_test.dart`
Write unit tests covering:
1. **Initial state:** `appNavigationProvider` initializes to `AppScreenState.mainMenu`.
2. **Transition to each screen:** `navigateTo(AppScreenState.axieVault)` → state equals `axieVault`.
3. **Return to menu:** from any state, `returnToMainMenu()` → `mainMenu`.
4. **Data persistence invariant:** After `axieImporterProvider` is loaded with mock data, transitioning away and back via `appNavigationProvider` leaves `axieImporterProvider.value` intact.

---

## 5. Eval Harness

### Vector A — Software
```bash
flutter test                     # All tests green (existing 13 + new navigation tests)
dart analyze --fatal-infos       # 0 issues
```

### Vector B — Mathematical (N/A this cycle)
No formula changes in this cycle. Domain entity is frozen. Marked N/A.

### Vector C — Performance Budget
- `AtmosphericBattlefieldBackdrop` `_ParticlePainter`: ZERO `Paint()` calls inside `paint()`. Pre-allocation mandatory.
- No synchronous I/O in build methods.
- Logo animation uses `repeat(reverse: true)` — no manual frame callbacks.

### Vector D — AST & Architectural Integrity
- Every new/modified `.dart` file must open with the 6-field AST header block.
- Zero domain imports in presentation layer beyond `axie_card_entity.dart` (already established).
- `axie_importer_dashboard.dart` must be physically deleted; no dead file residue.
- `RootView` must use `switch` expression (Dart 3+), not if/else chains.

---

## 6. Output Artifacts Required

Upon completion, the UI Agent MUST produce:
1. All source files listed in §3.2 written to their specified paths.
2. Clean `dart analyze --fatal-infos` output (0 issues).
3. Clean `flutter test` output (all tests passing).
4. Report filed to: `C:\LatiCore\01_Projects\lunacian_card_wars\logs\CYCLE_10_MODULE_2_UI_AGENT_EXECUTION_REPORT.md`
```
