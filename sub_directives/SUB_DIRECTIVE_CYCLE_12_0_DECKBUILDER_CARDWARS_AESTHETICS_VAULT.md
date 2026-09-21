# SUB-DIRECTIVA DE EJECUCIÓN: CONCRECIÓN DEL DECK BUILDER, ANATOMÍA VISUAL CARD WARS Y PERSISTENCIA DE BÓVEDA (CICLO 12.0)
**ID:** `SUB_DIR_LCW_DECKBUILDER_CARDWARS_AESTHETICS_VAULT_CYCLE_12`  
**Directiva Primaria:** `DIR_LCW_DECKBUILDER_CARDWARS_AESTHETICS_VAULT_CYCLE_12`  
**Sistema:** `lunacian_card_wars`  
**Autor:** `director` (Technical PM & Context Orchestrator)  
**Destinatarios:** `data_agent`, `ui_agent`, `qa_agent`  
**Supervisión:** `der_tab` (Data Science Engineer & Solutions Architect)  
**Contexto de Ejecución:** Ciclo 12.0 — Persistencia Soberana de Axies en Bóveda Local (SharedPreferences / LocalStorage), Widget Generativo CardWarsCardView (Aspect Ratio 5:7, Biselado, Gemas de Maná, Badges ATK/DEF) y Conexión Reactiva al Deck Builder Unificado  
**Invariantes de Stack:** Flutter Web (CanvasKit / WASM), Dart 3.x, Riverpod 2.6+, SharedPreferences, Clean Architecture (Domain Purity)  

---

### 1. Descomposición Modular y Asignación de Roles

#### Módulo 1: Repositorio de Persistencia en Bóveda y Serialización de Entidades (`data_agent`)
- **Archivos Objetivo:**
  - `lib/src/domain/entities/axie_card_entity.dart`
  - `lib/src/domain/entities/combat/floop_ability_entity.dart`
  - `lib/src/data/repositories/axie_vault_repository.dart`
  - `lib/main.dart`
- **Responsabilidades Específicas:**
  1. **Serialización y Soporte de Dominio (`axie_card_entity.dart`, `floop_ability_entity.dart`)**:
     - Preservar encabezado AST formal de 6 campos.
     - Añadir `Map<String, dynamic> toJson()` y `factory AxieCardEntity.fromJson(Map<String, dynamic> json)`.
     - Exponer getter canónico `BoardClassAffinity get classAffinity => affinity;` en `AxieCardEntity` para compatibilidad universal.
     - Añadir serialización `toJson()` / `fromJson()` en `FloopAbilityEntity` si es requerido por el almacenamiento.
     - Cero dependencias de Flutter UI en la capa de dominio.
  2. **Repositorio de Bóveda Local (`axie_vault_repository.dart`)**:
     - Implementar la interfaz `IAxieVaultRepository` y la clase concreta `AxieVaultRepository`:
       * Clave de persistencia: `lcw_saved_axies_vault_v1`.
       * Métodos:
         - `Future<List<AxieCardEntity>> getSavedAxies();`
         - `Future<bool> saveAxie(AxieCardEntity axie);` (prevención de colisiones por ID duplicado).
         - `Future<bool> removeAxie(String axieId);`
         - `Future<bool> isAxieSaved(String axieId);`
     - Manejo de excepciones robusto ante datos corruptos (retornando lista vacía en error).
     - Preservar encabezado AST formal de 6 campos.
  3. **Inicialización en Main (`lib/main.dart`)**:
     - Asegurar que `WidgetsFlutterBinding.ensureInitialized()` se ejecute y provea la instancia inicial de `SharedPreferences` al `ProviderScope` mediante `sharedPreferencesProvider` (o fallback dinámico).
  4. Documentar y emitir reporte en `logs/CYCLE_12_0_MODULE_1_DATA_AGENT_EXECUTION_REPORT.md`.

#### Módulo 2: Anatomía Visual Card Wars, Controladores y Vistas (`ui_agent`)
- **Archivos Objetivo:**
  - `lib/src/presentation/widgets/card_wars_card_view.dart`
  - `lib/src/presentation/controllers/axie_vault_controller.dart`
  - `lib/src/presentation/controllers/deck_builder_controller.dart`
  - `lib/src/presentation/views/axie_vault_view.dart` (o `axie_importer_dashboard.dart`)
  - `lib/src/presentation/views/deckbuilder_view.dart`
- **Responsabilidades Específicas:**
  1. **Controlador de Bóveda (`axie_vault_controller.dart`)**:
     - `sharedPreferencesProvider` con soporte de inyección.
     - `axieVaultRepositoryProvider` que inyecta `SharedPreferences`.
     - `axieVaultProvider` como `AsyncNotifierProvider<AxieVaultController, List<AxieCardEntity>>`.
     - Métodos: `toggleSaveAxie(AxieCardEntity axie)`, `isSavedSync(String axieId)`.
  2. **Widget Generativo `CardWarsCardView` (`card_wars_card_view.dart`)**:
     - Relación de aspecto rígida:
       $$\text{Aspect Ratio} = \frac{\text{Width}}{\text{Height}} = \frac{5}{7} \approx 0.714$$
     - Marco exterior biselado según afinidad elemental `BoardClassAffinity` (`_getClassColor`).
     - Gema / hexágono de maná superior izquierdo con brillo y borde blanco.
     - Barra de título con nombre de carta en mayúsculas.
     - Ventana central de arte con cascada resiliente: `Image.network(axie.spriteUrl)` con fallback en `errorBuilder` a placeholder estilizado con icono elemental y `AXIE #${axie.id}`.
     - Cinta heráldica de clase: `${axie.classAffinity.name.toUpperCase()} CREATURE`.
     - Recuadro pergamino de Floop con badge de coste `FLOOP $floopCost`, título de Floop y descripción legible.
     - Insignia de Ataque (inferior izquierda, fondo naranja con icono de rayo `flash_on`).
     - Insignia de Defensa (inferior derecha, fondo azul con icono de escudo `shield`).
     - Overlay *"IN DECK"* atenuado cuando `isInDeck == true`.
     - Callback interactivo `onTap`.
     - Invariante visual: cero llamadas a `.withOpacity()`, uso estricto de `.withValues(alpha: ...)`.
  3. **Acción "SAVE TO VAULT" en el Importer (`axie_vault_view.dart` / dashboard)**:
     - En cada tarjeta de Axie importado, desplegar botón interactivo `SAVE TO VAULT` / `REMOVE`.
     - Conectar a `ref.read(axieVaultProvider.notifier).toggleSaveAxie(axie)` con SnackBar de retroalimentación.
  4. **Controlador y Vista del Deck Builder (`deck_builder_controller.dart`, `deckbuilder_view.dart`)**:
     - Proveedor `starterAxiesListProvider`: catálogo de starters inmutables (Buba, Olek, Puffy) desde `AxieCardFactory`.
     - Proveedor `fullAvailableAxiesProvider`: fusión reactiva y deduplicada por ID de Starters + Axies guardados en la bóveda.
     - `DeckBuilderController`:
       * Gestión del mazo activo (objetivo: 20 a 25 cartas).
       * Regla de máximo 2 copias con idéntico Floop.
       * Soporte de configuración de carta al agregar: selector de coste de maná ($1 \le C \le \min(7, \lfloor L/10 \rfloor + 1)$) y selección de Floop (Boca vs. Cola), recalculando estadísticas con `recalculateForManaCost`.
     - `DeckbuilderView`:
       * Grilla de cartas disponibles con `CardWarsCardView`.
       * Drawer / Modal de configuración de Axie (coste de maná y Floop).
       * Bandeja visual del mazo actual con contador, indicador de estado y botón de guardado/limpieza.
  5. Documentar y emitir reporte en `logs/CYCLE_12_0_MODULE_2_UI_AGENT_EXECUTION_REPORT.md`.

#### Módulo 3: Suite de Verificación 4-Vector y Auditoría de Promoción (`qa_agent`)
- **Archivos Objetivo:**
  - `test/deckbuilder_vault_persistence_test.dart`
  - `logs/CYCLE_12_0_FINAL_AUDIT_PROMOTION_VERDICT.md`
- **Responsabilidades Específicas:**
  1. **Vector A (Software Verification & Compilación Limpia)**:
     - Crear `test/deckbuilder_vault_persistence_test.dart`:
       * Prueba de guardado, persistencia, deduplicación y remoción en `AxieVaultRepository`.
       * Prueba de unificación reactiva en `fullAvailableAxiesProvider` (Starters + Bóveda sin duplicados).
       * Prueba de widget `CardWarsCardView` (aspect ratio 5:7, badges ATK/DEF, gema de maná, fallback de imagen, overlay "IN DECK").
       * Prueba de reglas del Deckbuilder: clamp de maná según nivel on-chain, selección de Floop, límite de 2 copias.
     - `flutter test` pasa al 100% en todas las suites.
     - `dart analyze --fatal-infos` finaliza con 0 errores, advertencias o sugerencias.
  2. **Vector B (Invarianza de Persistencia y Límites)**:
     - Serialización JSON determinista de `AxieCardEntity`.
     - Invariante de relación de aspecto visual $5:7$.
     - Preservación estricta de la regla de balance BST ($9 \times C$).
  3. **Vector C (Perfil de Recursos y Rendimiento Edge)**:
     - Tiempo de acceso y serialización en LocalStorage $< 10$ ms.
     - Cero fugas de red o excepciones no capturadas en fallback de imágenes.
     - Cero RenderFlex overflows en desktop y viewports móviles/compactos.
  4. **Vector D (Integridad AST y Soberanía Topológica)**:
     - Encabezado AST obligatorio de 6 campos en todos los nuevos archivos `.dart`.
     - Cero código en `C:\LatiCore\`.
  5. Emitir `logs/CYCLE_12_0_FINAL_AUDIT_PROMOTION_VERDICT.md` con veredicto `QA_VERDICT: [PROMOTION GRANTED]`.

---

### 2. Invariantes de Seguridad y Topología
- **Soberanía Topológica:** Cero código o scripts en `C:\LatiCore\`. Todo código reside en `C:\NeuroField\active_projects\lunacian_card_wars\`.
- **Espejado Semántico:** Documentación Markdown (sub-directivas y logs) sincronizada en `C:\LatiCore\01_Projects\lunacian_card_wars\`.
- **Higiene de Secretos:** Nunca versionar API Keys en el repositorio.
