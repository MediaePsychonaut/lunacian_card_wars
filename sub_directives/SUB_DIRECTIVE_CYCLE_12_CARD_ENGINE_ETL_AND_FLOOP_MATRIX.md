# SUB-DIRECTIVA DE EJECUCIÓN: ETL DEL MOTOR DE CARTAS, ESQUEMAS NORMALIZADOS Y MATRIZ DE FLOOPS (CICLO 12)
**ID:** `SUB_DIR_LCW_CARD_ENGINE_ETL_NORMALIZED_SCHEMAS_FLOOP_MATRIX_CYCLE_12`  
**Directiva Primaria:** `MASTER ARCHITECTURAL DIRECTIVE: LUNACIAN CARD WARS (CYCLE 12)`  
**Sistema:** `lunacian_card_wars`  
**Autor:** `director` (Technical PM & Context Orchestrator)  
**Destinatarios:** `data_agent`, `qa_agent`  
**Contexto de Ejecución:** Ciclo 12 — Pipeline ETL Automatizado, Asignación de Floops, Conservación de Stats, 12 Combinaciones Secretas y Contrato de Escala Dinámica  
**Invariantes de Stack:** Python 3.9 (ETL), Dart 3.x / Flutter Web (Domain Engine & Verification), Clean Architecture, Salidas CSV Deterministas  

---

### 1. Descomposición Modular y Asignación de Roles

#### Módulo 1: Pipeline ETL y Generación de Datasets Normalizados (`data_agent`)
- **Archivos Objetivo:**
  - Script ETL: `scripts/compile_card_master_datasets.py`
  - Datasets Generados en `assets/data/generated/`:
    1. `assets/data/generated/axie_part_floops_matrix.csv`
    2. `assets/data/generated/structures_master.csv`
    3. `assets/data/generated/spells_master.csv`
- **Responsabilidades Específicas:**
  1. Ingestar datos de referencia:
     - `assets/data/axie_part_stats_and_floops.csv` (204 partes corporales)
     - `assets/data/mouth_tail_permutation_floops.csv` (288 permutaciones genéticas)
     - `assets/data/adventrue_time_cards.csv` (192 criaturas, 30 edificios, 49 hechizos)
  2. Generar `axie_part_floops_matrix.csv`:
     - 60 filas de partes anatómicas: 24 Bocas (`mouth`) y 36 Colas (`tail`) distribuidas en las 6 clases puras (`beast`, `aqua`, `plant`, `reptile`, `bug`, `bird`).
     - 12 filas de Combinaciones Secretas (`secret_combo`):
       * 6 Sinergias Puras (Beast, Aqua, Plant, Reptile, Bug, Bird).
       * 6 Sinergias Híbridas (2 Melee Beast $\times$ Bug; 2 Control Plant $\times$ Reptile; 2 Tempo Aqua $\times$ Bird).
     - Total exacto: **72 filas de datos + 1 cabecera = 73 líneas**.
     - Esquema estricto de 18 columnas:
       `part_id,part_type,class,part_name,floop_id,floop_name,activation_mana_cost,atk_bias_shift,def_bias_shift,effect_type,base_value,scaling_formula,conditional_rule,target_scope,is_secret,secret_combo_req,archetype_tag,card_art_asset_id`
     - **Ley de Conservación de Stats (AC-2):** $\Delta \text{ATK} + \Delta \text{DEF} = 0$ verificado en las 72 filas.
     - **Integridad Referencial (Primitive 3):** Para filas secretas (`is_secret == 1`), `secret_combo_req` tiene el formato `part_id_mouth+part_id_tail`, donde ambos IDs existen exactamente en la columna `part_id` del mismo archivo. Para partes estándar, `secret_combo_req` es `NONE`.
     - Fórmulas de escala dinámica parametrizadas: `BASE + (AXIE_MANA - 1) * Delta` o `NONE`.
     - Reglas condicionales: `TARGET_MANA <= AXIE_MANA` o `NONE`.
  3. Generar `structures_master.csv`:
     - Compilar a partir de los 30 edificios de `adventrue_time_cards.csv`.
     - Esquema estricto de 12 columnas:
       `structure_id,name,landscape,mana_cost,base_hp,passive_effect_type,effect_value,scaling_formula,activation_trigger,target_scope,lore_description,card_art_asset_id`
     - Mapeo de landscapes: `corn_fields`, `blue_plains`, `nice_lands`, `sandy_lands`, `useless_swamp`, `rainbow`.
  4. Generar `spells_master.csv`:
     - Compilar a partir de los 49 hechizos de `adventrue_time_cards.csv`.
     - Esquema estricto de 12 columnas:
       `spell_id,name,landscape_affinity,mana_cost,spell_type,effect_type,base_value,scaling_rule,target_scope,turn_duration,lore_description,card_art_asset_id`
     - Mapeo de landscape affinities: `corn_fields`, `blue_plains`, `nice_lands`, `sandy_lands`, `useless_swamp`, `universal`.

#### Módulo 2: Contrato de Escala Dinámica y Modulación en el Motor Dart (`data_agent`)
- **Archivos Objetivo:**
  - `lib/src/domain/entities/combat/floop_ability_entity.dart`
  - `lib/src/domain/entities/axie_card_entity.dart`
  - `lib/src/domain/services/axie_card_factory.dart`
- **Responsabilidades Específicas:**
  1. Extender `FloopAbilityEntity` para admitir `atkMod`, `defMod`, `scalingFormula`, `conditionalRule`, `targetScope` (`FloopTargetScope`), e `isSecret`.
  2. Implementar método evaluador de escala en `FloopAbilityEntity`:
     `int resolveScaledValue(int axieManaCost)` aplicando $V_{\text{scaled}} = V_{\text{base}} + \Delta \cdot (C_{\text{Axie}} - 1)$.
  3. En `AxieCardEntity`, aplicar la modulación de estadísticas en construcción/copyWith:
     $$\text{ATK}_{\text{final}} = \text{baseAtk} + \Delta \text{ATK}_{\text{floop}}$$
     $$\text{DEF}_{\text{final}} = \text{baseDef} + \Delta \text{DEF}_{\text{floop}}$$
     Preservando la invariante $\Delta \text{ATK} + \Delta \text{DEF} = 0$.
  4. Permitir `FloopSource.secret` en `FloopSource` para equipar Floops secretos si la combinación de partes cumple los requisitos.
  5. Mantener los encabezados AST de 6 campos en inglés.

#### Módulo 3: Suite de Pruebas de Integración y Auditoría 4-Vector (`qa_agent`)
- **Archivos Objetivo:**
  - Suite de validación Python: `tests/test_card_datasets.py`
  - Suite de verificación Dart/Flutter: `test/card_engine_datasets_test.dart`
  - Reporte de Auditoría: `logs/CYCLE_12_FINAL_AUDIT_PROMOTION_VERDICT.md`
- **Responsabilidades Específicas:**
  1. Validar Vector A (Software Integration):
     - Ejecutar `pytest tests/test_card_datasets.py`.
     - Ejecutar `flutter test test/card_engine_datasets_test.dart` y `flutter test -j 1`.
     - Ejecutar `dart analyze --fatal-infos`.
  2. Validar Vector B (Mathematical Balance & Stat Conservation):
     - Verificar que $\Delta \text{ATK} + \Delta \text{DEF} == 0$ en el 100% de las filas de Floops.
     - Verificar que los costos de activación cumplan $0 \le C_{\text{Floop}} \le 3$.
     - Verificar la consistencia de las 12 combinaciones secretas.
  3. Validar Vector C (Memory & Performance):
     - Tiempo de parseo de datasets $< 15$ ms; tamaño total de archivos $< 500$ KB.
  4. Validar Vector D (AST & Schema Integrity):
     - Cero claves foráneas huérfanas en `secret_combo_req`.
     - Encabezados AST de 6 campos en todos los archivos Dart modificados.
     - Cero archivos de código en `C:\LatiCore\`.
  5. Emitir veredicto final: `QA_VERDICT: [PROMOTION GRANTED]`.

---

### 2. Invariantes de Seguridad y Topología
- **Soberanía Topológica:** Cero código o scripts en `C:\LatiCore\`. Todos los archivos residen en `C:\NeuroField\active_projects\lunacian_card_wars\`.
- **Espejado Semántico:** Documentación Markdown (sub-directivas y logs) se sincroniza en `C:\LatiCore\01_Projects\lunacian_card_wars\`.
- **Higiene de Secretos:** Nunca registrar ni versionar claves API en los repositorios.
