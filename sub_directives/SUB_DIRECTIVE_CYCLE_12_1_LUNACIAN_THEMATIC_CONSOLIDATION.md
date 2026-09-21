# SUB-DIRECTIVA DE EJECUCIÓN: MIGRACIÓN TEMÁTICA Y CONSOLIDACIÓN A LUNACIA (CICLO 12.1)
**ID:** `SUB_DIR_LCW_LUNACIAN_THEMATIC_CONSOLIDATION_CYCLE_12_1`  
**Directiva Primaria:** `DIR_LCW_LUNACIAN_THEMATIC_CONSOLIDATION_CYCLE_12_1`  
**Sistema:** `lunacian_card_wars`  
**Autor:** `director` (Technical PM & Context Orchestrator)  
**Destinatarios:** `data_agent`, `ui_agent`, `qa_agent`  
**Supervisión:** `der_tab` (Data Science Engineer & Solutions Architect)  
**Contexto de Ejecución:** Ciclo 12.1 — Erradicación Absoluta de IP Heredada, Sustitución de Landscapes por Axie Class Affinities, Consolidación de Land Items y Runas/Charms de Origins, y Mapeo de Identificadores de Arte Local  
**Invariantes de Stack:** Flutter Web (CanvasKit), Dart 3.x, Clean Architecture (Domain Purity), Esquema GraphQL Sky Mavis, CSV Determinista  

---

### 1. Descomposición Modular y Asignación de Roles

#### Módulo 1: Pipeline GraphQL, Datasets Normalizados y Entidades de Dominio (`data_agent`)
- **Archivos Objetivo:**
  - `tool/extraction/fetch_land_items.dart`
  - `assets/data/generated/structures_master.csv`
  - `assets/data/generated/spells_master.csv`
  - `scripts/compile_card_master_datasets.py`
  - `lib/src/domain/entities/combat/building_card_entity.dart`
  - `lib/src/domain/entities/combat/spell_card_entity.dart`
  - `lib/src/domain/services/axie_card_factory.dart`
- **Responsabilidades Específicas:**
  1. **Script de Soporte GraphQL (`tool/extraction/fetch_land_items.dart`)**:
     - Implementar la consulta oficial de Land Items contra `https://api-gateway.skymavis.com/graphql/axie-marketplace` con cabeceras `Content-Type: application/json` y `X-API-Key: Platform.environment['SKY_MAVIS_API_KEY']`.
     - Preservar encabezado AST de 6 campos.
  2. **Catálogo Maestro de Estructuras (`assets/data/generated/structures_master.csv`)**:
     - 30 registros de datos + 1 fila de encabezado = exactamente **31 líneas**.
     - Eliminar `landscape` y sustituir por `axie_class_affinity` (`beast`, `aquatic`, `plant`, `bird`, `bug`, `reptile`, `neutral`).
     - Renombrar las 30 estructuras basándose en Land Items oficiales y monumentos de Lunacia (e.g. `Chimera Monument`, `Sunken Obelisk`, `Forest Shrine`, `Outpost of Vigor`, `Crimson Barricade`, etc.).
     - Erradicar cualquier término de IP previa (*Adventure Time, Card Wars, Jake, Finn, Corn Fields, Blue Plains, Useless Swamp, Nice Lands, Sandy Lands, Floop* en descripciones de estructuras).
     - Conservar matemáticamente todos los valores mecánicos:
       * Sumatoria total de `mana_cost` = **73 MP**.
       * Exactos `base_hp`, `armor_reduction`, `passive_effect_type`, `effect_value`, `scaling_formula`, `activation_trigger`, `target_scope`.
     - Identificador `card_art_asset_id` con formato formal `asset_struct_<slug>`.
     - Encabezado:
       `structure_id,name,axie_class_affinity,mana_cost,base_hp,armor_reduction,passive_effect_type,effect_value,scaling_formula,activation_trigger,target_scope,lore_description,card_art_asset_id`
  3. **Catálogo Maestro de Hechizos (`assets/data/generated/spells_master.csv`)**:
     - 49 registros de datos + 1 fila de encabezado = exactamente **50 líneas**.
     - Eliminar `landscape_affinity` y sustituir por `axie_class_affinity` (`beast`, `aquatic`, `plant`, `bird`, `bug`, `reptile`, `neutral`).
     - Renombrar los 49 hechizos basándose en Runas, Amuletos (Charms) y habilidades arcanas de Axie Origins (e.g. `Tidal Surge`, `Cerebral Bloodstorm`, `Yggdrasil Blessing`, `Pure Water`, `Feather Strike`, etc.).
     - Erradicar cualquier término de IP previa.
     - Conservar matemáticamente todos los valores mecánicos:
       * Sumatoria total de `mana_cost` = **97 MP**.
       * Exactos `effect_type`, `base_value`, `scaling_formula`, `target_scope`, `cast_window`, `rarity`.
     - Identificador `card_art_asset_id` con formato formal `asset_spell_<slug>`.
     - Encabezado:
       `spell_id,name,axie_class_affinity,mana_cost,spell_type,effect_type,base_value,scaling_formula,target_scope,cast_window,rarity,description,card_art_asset_id`
  4. **Entidades Inmutables de Dominio en Dart**:
     - Actualizar `BuildingCardEntity` y `SpellCardEntity` con los constructores y deserializadores `fromCsv` canónicos (sin dependencias de Flutter UI, importando únicamente `combat_card.dart` y `combat_enums.dart`).
     - Actualizar `AxieCardFactory` para que los 4 edificios tácticos y 4 hechizos tácticos iniciales usen las entidades y nombres canónicos de Lunacia.
     - Verificar `dart analyze --fatal-infos`.
  5. Documentar y emitir reporte de ejecución en `logs/CYCLE_12_1_MODULE_1_DATA_AGENT_EXECUTION_REPORT.md`.

#### Módulo 2: Migración, Optimización y Estandarización de Assets Gráficos (`ui_agent`)
- **Archivos Objetivo:**
  - `assets/images/classes/`
  - `assets/images/spells/runes/`
  - `assets/images/spells/tactics/`
  - `assets/images/spells/effects/`
  - `assets/images/structures/`
  - `pubspec.yaml`
- **Responsabilidades Específicas:**
  1. Migrar y optimizar recursos visuales desde `C:\NeuroField\active_projects\lunacian_resources\`:
     - `Class Icons` -> `assets/images/classes/` (PNGs de las 7 afinidades: beast, aquatic, plant, bird, bug, reptile, neutral).
     - `Artifacts` -> `assets/images/spells/runes/` (Runas de clase).
     - `Card Art` -> `assets/images/spells/tactics/` (Ilustraciones de cartas tácticas).
     - `StatusIcons` -> `assets/images/spells/effects/` (Efectos de estado de Origins).
     - `Textures/Vfx` / Fondos -> `assets/images/structures/` (Monumentos y estructuras).
  2. Optimizar imágenes a resolución máxima de $256 \times 256$ px en PNG/WebP con peso $< 60$ KB por textura.
  3. Declarar las subcarpetas de assets en `pubspec.yaml`.
  4. Documentar y emitir reporte de ejecución en `logs/CYCLE_12_1_MODULE_2_UI_AGENT_EXECUTION_REPORT.md`.

#### Módulo 3: Suite de Verificación 4-Vector y Auditoría de Purga IP (`qa_agent`)
- **Archivos Objetivo:**
  - `test/data/catalog_ingestion_test.dart`
  - `logs/CYCLE_12_1_FINAL_AUDIT_PROMOTION_VERDICT.md`
- **Responsabilidades Específicas:**
  1. **Vector A (Software Integration & Ingestion)**:
     - Crear `test/data/catalog_ingestion_test.dart` deserializando `structures_master.csv` y `spells_master.csv` vía `BuildingCardEntity.fromCsv` y `SpellCardEntity.fromCsv`.
     - Aserción estricta de cardinalidad: `structures.length == 30` y `spells.length == 49`.
     - Validar que no existan `FormatException` o nulos.
     - `flutter test` pasa al 100%.
     - `dart analyze --fatal-infos` certifica 0 issues.
  2. **Vector B (Math & Mechanical Invariance)**:
     - $\sum \text{ManaCost}(\text{Structures}) == 73$ MP.
     - $\sum \text{ManaCost}(\text{Spells}) == 97$ MP.
     - Delta de impacto de combate: $\Delta \text{CombatImpact} = 0.0$.
  3. **Vector C (Memory & Resource Profiling)**:
     - Peso combinado de los 2 CSVs $< 35$ KB.
     - Tiempo de parsing $< 6.0$ ms.
     - Texturas $< 60$ KB en VRAM.
  4. **Vector D (AST Header & IP Purge Audit)**:
     - Auditoría estricta de texto: escanear `assets/` y `lib/` comprobando que las menciones de la IP anterior (*Adventure Time, Card Wars, Jake, Finn, Corn Fields, Blue Plains, Useless Swamp, Nice Lands, Sandy Lands*) sean exactamente 0.
     - 6 campos AST obligatorios en todos los archivos `.dart` creados/modificados.
     - Cero código en `C:\LatiCore\`.
  5. Emitir `logs/CYCLE_12_1_FINAL_AUDIT_PROMOTION_VERDICT.md` con veredicto `QA_VERDICT: [PROMOTION GRANTED]`.

---

### 2. Invariantes de Seguridad y Topología
- **Soberanía Topológica:** Cero código o scripts en `C:\LatiCore\`. Todo código reside en `C:\NeuroField\active_projects\lunacian_card_wars\`.
- **Espejado Semántico:** Documentación Markdown (sub-directivas y logs) sincronizada en `C:\LatiCore\01_Projects\lunacian_card_wars\`.
- **Higiene de Secretos:** Nunca versionar API Keys en el repositorio.
