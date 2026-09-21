# SUB-DIRECTIVA DE EJECUCIÓN: UNIFICACIÓN UNIVERSAL RAINBOW Y CALIBRACIÓN ANATÓMICA (CICLO 12.2)
**ID:** `SUB_DIR_LCW_RAINBOW_UNIFICATION_AND_ANATOMICAL_CALIBRATION_CYCLE_12_2`  
**Directiva Primaria:** `DIR_LCW_RAINBOW_UNIFICATION_AND_ANATOMICAL_CALIBRATION_CYCLE_12_2`  
**Sistema:** `lunacian_card_wars`  
**Autor:** `director` (Technical PM & Context Orchestrator)  
**Destinatarios:** `data_agent`, `ui_agent`, `qa_agent`  
**Supervisión:** `der_tab` (Data Science Engineer & Solutions Architect)  
**Contexto de Ejecución:** Ciclo 12.2 — Unificación Universal Rainbow (Neutral) de Estructuras y Hechizos, Desacoplamiento Total de Terreno en Soporte, y Motor Determinista de Calibración Anatómica de Axies ($9 \times C$)  
**Invariantes de Stack:** Flutter Web (CanvasKit), Dart 3.x, Clean Architecture (Domain Purity), Esquema GraphQL Sky Mavis, CSV Determinista  

---

### 1. Descomposición Modular y Asignación de Roles

#### Módulo 1: Normalización Universal Rainbow y Motor de Calibración Anatómica (`data_agent`)
- **Archivos Objetivo:**
  - `scripts/compile_card_master_datasets.py`
  - `assets/data/generated/structures_master.csv`
  - `assets/data/generated/spells_master.csv`
  - `lib/src/domain/services/axie_stat_calibrator.dart`
  - `lib/src/domain/entities/axie_card_entity.dart`
  - `lib/src/domain/services/axie_card_factory.dart`
- **Responsabilidades Específicas:**
  1. **Unificación Rainbow en Datasets (`scripts/compile_card_master_datasets.py`)**:
     - En `compile_structures_master()`: fijar `axie_class_affinity = "neutral"` en el 100% de las 30 estructuras.
     - En `compile_spells_master()`: fijar `axie_class_affinity = "neutral"` en el 100% de los 49 hechizos.
     - Preservar estrictamente los nombres, lore, mecánicas y los IDs de arte (`asset_struct_<slug>`, `asset_spell_<slug>`).
     - Preservar la invariancia matemática:
       * $\sum_{i=1}^{30} \text{mana\_cost}(\text{Structures}) \equiv 73\text{ MP}$.
       * $\sum_{i=1}^{49} \text{mana\_cost}(\text{Spells}) \equiv 97\text{ MP}$.
     - Ejecutar `python scripts/compile_card_master_datasets.py` para regenerar los CSV maestros en `assets/data/generated/`.
  2. **Servicio Determinista de Calibración (`lib/src/domain/services/axie_stat_calibrator.dart`)**:
     - Servicio puro de dominio sin estado y sin dependencias de Flutter UI.
     - Encabezado AST de 6 campos obligatorio.
     - Implementar `CalibratedAxieStats`:
       * `final int bstTotal;`
       * `final int atk;`
       * `final int def;`
       * `final double ratioR;`
       * Aserción `atk + def == bstTotal`.
     - Implementar `AxieStatCalibrator.calibrate(...)`:
       * **Presupuesto Proporcional BST**:
         $\text{BST}_{\text{base}}(C) = 9 \times C$ para $C \in [1, 7]$.
         $\Delta_{\text{evolved}} = \lfloor (N_{\text{evolved}} \times C) / 6 \rfloor$ ($N_{\text{evolved}} \in [0, 6]$).
         $\text{BST}_{\text{total}} = \text{BST}_{\text{base}}(C) + \Delta_{\text{evolved}}$.
       * **Ratios Base por Clase Corporal**:
         * Bird: 0.60
         * Beast: 0.56
         * Aquatic: 0.48
         * Bug: 0.44
         * Reptile: 0.36
         * Plant: 0.30
         * Neutral / Mech / Dusk / Dawn / Unknown: 0.45
       * **Sesgo Anatómico Continuo por Afinidad de Parte**:
         * Bird / Beast: +0.04
         * Aquatic: +0.02
         * Bug / Neutral / Mech / Dusk / Dawn: 0.00
         * Reptile: -0.02
         * Plant: -0.04
       * **Fórmula de Calibración**:
         `rawR = classRatio + hornBias - backBias + floopBias + statVariance`
         Donde:
         * `floopBias = isMouthFloop ? 0.04 : -0.04`
         * `statVariance = ((speed + skill) - (hp + morale)) / 600.0`
         * Clampear $R \in [0.25, 0.75]$.
         * $\text{ATK} = \text{round}(\text{BST}_{\text{total}} \times R)$.
         * $\text{DEF} = \text{BST}_{\text{total}} - \text{ATK}$.
         * Invariante estricto: $\text{ATK} + \text{DEF} \equiv \text{BST}_{\text{total}}$.
  3. **Integración con `AxieCardEntity` y `AxieCardFactory`**:
     - Actualizar `AxieCardEntity.fromGraphQL` para delegar el cálculo de `baseAtk` y `baseDef` a `AxieStatCalibrator`.
     - Extraer clases de cuerno (horn), espalda (back) y estadísticas (`stats: hp, speed, skill, morale`) del JSON de GraphQL si están presentes.
     - Añadir método de escalado dinámico `recalculateForManaCost(int newManaCost)` para soporte del Deckbuilder.
     - Actualizar las cartas canónicas en `AxieCardFactory` para que sus estadísticas respeten el balance proporcional BST ($9 \times C$).
  4. **Desacoplamiento de Despliegue de Soporte**:
     - Validar que `canPlayBuilding` y el lanzamiento de hechizos en `combat_engine.dart` verifiquen exclusivamente maná y espacio, con 0 dependencias de afinidad de terreno en la casilla.
  5. Documentar y emitir reporte en `logs/CYCLE_12_2_MODULE_1_DATA_AGENT_EXECUTION_REPORT.md`.

#### Módulo 2: Telemetría de Soporte Rainbow y Ajuste de Deckbuilder (`ui_agent`)
- **Archivos Objetivo:**
  - `lib/src/presentation/views/deckbuilder_view.dart`
  - `lib/src/presentation/views/arena_view.dart`
- **Responsabilidades Específicas:**
  1. Asegurar que las cartas de soporte (Estructuras y Hechizos) se muestren con el badge/indicador universal "Neutral / Rainbow" en lugar de estar atadas a un elemento específico.
  2. Verificar que no existan restricciones visuales ni de interacción para desplegar edificios en cualquier carril.
  3. Documentar y emitir reporte en `logs/CYCLE_12_2_MODULE_2_UI_AGENT_EXECUTION_REPORT.md`.

#### Módulo 3: Suite de Verificación 4-Vector y Auditoría de Permutaciones (`qa_agent`)
- **Archivos Objetivo:**
  - `test/data/catalog_ingestion_test.dart`
  - `test/domain/axie_stat_calibrator_test.dart`
  - `logs/CYCLE_12_2_FINAL_AUDIT_PROMOTION_VERDICT.md`
- **Responsabilidades Específicas:**
  1. **Vector A (Software Integration & Ingestion)**:
     - Actualizar `test/data/catalog_ingestion_test.dart`:
       * Aserción estricta de que el 100% de las 30 estructuras tienen `axieClassAffinity == BoardClassAffinity.neutral`.
       * Aserción estricta de que el 100% de los 49 hechizos tienen `axieClassAffinity == BoardClassAffinity.neutral`.
     - Crear `test/domain/axie_stat_calibrator_test.dart`:
       * Aserción exhaustiva sobre **9,072 permutaciones** ($6 \text{ body} \times 6 \text{ horn} \times 6 \text{ back} \times 7 \text{ mana} \times 6 \text{ evolved}$):
         - 0 excepciones.
         - Invariante estricto: $\text{ATK} + \text{DEF} \equiv \text{BST}_{\text{total}}$.
         - Clampeo estricto: $0.25 \le R \le 0.75$.
         - $\text{ATK} \ge 1$, $\text{DEF} \ge 1$.
       * Verificación de letalidad:
         - A Coste 1, $\text{ATK} \le 8 \ll 12$.
         - A Coste 2 sin evolución, $\text{ATK} \le 14$ (o verificar que el pacing inicial no permite OHKO de un héroe de 25 HP).
  2. **Vector B (Math & Invariance)**:
     - Suma de maná de estructuras = 73 MP.
     - Suma de maná de hechizos = 97 MP.
     - Conservación total de estadísticas en cada llamada del calibrador.
  3. **Vector C (Resource & Execution Profiling)**:
     - Tiempo de calibración de 9,072 permutaciones $< 50$ ms.
     - `pytest tests/test_card_datasets.py` al 100% pass.
     - `flutter test` al 100% pass.
  4. **Vector D (AST Header & Topology Audit)**:
     - Encabezado AST de 6 campos en todos los archivos `.dart` creados o modificados.
     - Cero código en `C:\LatiCore\`.
  5. Emitir `logs/CYCLE_12_2_FINAL_AUDIT_PROMOTION_VERDICT.md` con veredicto `QA_VERDICT: [PROMOTION GRANTED]`.

---

### 2. Invariantes de Seguridad y Topología
- **Soberanía Topológica:** Cero código o scripts en `C:\LatiCore\`. Todo código reside en `C:\NeuroField\active_projects\lunacian_card_wars\`.
- **Espejado Semántico:** Documentación Markdown (sub-directivas y logs) sincronizada en `C:\LatiCore\01_Projects\lunacian_card_wars\`.
- **Higiene de Secretos:** Nunca versionar API Keys en el repositorio.
