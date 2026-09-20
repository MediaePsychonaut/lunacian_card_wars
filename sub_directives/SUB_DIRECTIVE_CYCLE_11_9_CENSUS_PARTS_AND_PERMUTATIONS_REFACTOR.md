# SUB-DIRECTIVA DE EJECUCIÓN: CENSO ANATÓMICO Y MATRIZ DE PERMUTACIONES (REFACTOR)
**ID:** `SUB_DIR_LCW_CENSUS_PARTS_AND_PERMUTATIONS_REFACTOR_CYCLE_11_9`  
**Directiva Primaria:** `DIR_LCW_CENSUS_PARTS_AND_PERMUTATIONS_REFACTOR_CYCLE_11_9`  
**Sistema:** `lunacian_card_wars`  
**Autor:** `director` (Technical PM & Context Orchestrator)  
**Destinatarios:** `data_agent`, `qa_agent`  
**Contexto de Ejecución:** Ciclo 11.9 — Refactor del Censo On-Chain, Resolución Dinámica de Slugs y Matriz de Permutaciones con Tipología/Clase  
**Invariantes de Stack:** Dart 3.x (CLI Scripting), HTTP, Sky Mavis Marketplace GraphQL API, Clean Architecture, Salida CSV Determinista  

---

### 1. Descomposición Modular y Asignación de Roles

#### Módulo 1: Refactor del Censo On-Chain y Generador de Permutaciones (`data_agent`)
- **Archivo Objetivo:** `tool/census/fetch_axie_census.dart`
- **Responsabilidad:**
  1. Definir la estructura `PartDefinition` con soporte para `candidateSlugs: List<String>`.
  2. Implementar `resolvePartCount(PartDefinition def, http.Client client, String apiKey)` con mecanismo fallback y detección automática de slugs válidos.
  3. Registrar los 204 ítems del catálogo anatómico, incorporando la lista de candidatos verificada para subsanar los 20 slugs problemáticos identificados en la exploración on-chain:
     - Plant Horn `Bamboo` -> `['horn-bamboo-shoot', 'horn-bamboo']`
     - Bug Horn `Vall Ein` -> `['horn-lagging', 'horn-mystic-rush', 'horn-vall-ein']`
     - Bug Horn `Caterpillar` -> `['horn-caterpillars', 'horn-dente', 'horn-pupa', 'horn-caterpillar']`
     - Beast Tail `Shiba` -> `['tail-shiba', 'tail-shiva']`
     - Bug Tail `Twin Needle` -> `['tail-twin-tail', 'tail-twin-needles', 'tail-twinneedle', 'tail-twin-needle']`
     - Beast Eyes `Calico` -> `['eyes-calico', 'eyes-calico-zee']`
     - Beast Eyes `Zeal` -> `['eyes-zeal', 'eyes-chubby', 'eyes-zeek']`
     - Aquatic Eyes `Telescope` -> `['eyes-telescope', 'eyes-telescopes']`
     - Aquatic Eyes `Gero / Clear` -> `['eyes-clear', 'eyes-gero', 'eyes-blosson']`
     - Plant Eyes `Confused / Papi` -> `['eyes-confused', 'eyes-papi', 'eyes-mistletoe']`
     - Bug Eyes `Bookworm / Neo` -> `['eyes-neo', 'eyes-bookworm', 'eyes-geisha']`
     - Bug Eyes `Nerdy` -> `['eyes-nerdy', 'eyes-kotaro', 'eyes-dente']`
     - Reptile Eyes `Kabuki / Tricky` -> `['eyes-tricky', 'eyes-kabuki', 'eyes-crimson-tooth']`
     - Reptile Eyes `Topaz / Scar` -> `['eyes-topaz', 'eyes-scar', 'eyes-scarlet-frog']`
     - Aquatic Ears `Sea Bream / Seaslug` -> `['ears-seaslug', 'ears-sea-bream', 'ears-seabream']`
     - Plant Ears `Rosa / Hollow` -> `['ears-hollow', 'ears-rosa', 'ears-serious']`
     - Plant Ears `Leaf` -> `['ears-lotus', 'ears-leafy', 'ears-leaf', 'ears-leaves']`
     - Bug Ears `Caterpillar` -> `['ears-earwing', 'ears-leaf-bug', 'ears-caterpillar', 'ears-caterpillars']`
     - Reptile Ears `Small Frill / Swirl / Friezard` -> `['ears-friezard', 'ears-small-frill', 'ears-swirl', 'ears-frizzy']`
     - Reptile Ears `Side Bar` -> `['ears-sidebarb', 'ears-side-bar', 'ears-sidebar']`
  4. Recolectar dinámicamente los slugs resueltos de boca y cola para alimentar la generación de las 288 permutaciones, garantizando que combinaciones como `mouth-nut-cracker__tail-shiba` y `mouth-pincer__tail-shiba` consulten slugs válidos (`> 0`).
  5. Extender la generación de permutaciones para incorporar metadatos de tipología y clase:
     - 144 filas `Pure` (24 Beast, 24 Aquatic, 24 Plant, 24 Bird, 24 Bug, 24 Reptile).
     - 48 filas `Mix` / `Mech` (24 Bug Mouth x Beast Tail + 24 Beast Mouth x Bug Tail).
     - 48 filas `Mix` / `Dusk` (24 Reptile Mouth x Aquatic Tail + 24 Aquatic Mouth x Reptile Tail).
     - 48 filas `Mix` / `Dawn` (24 Plant Mouth x Bird Tail + 24 Bird Mouth x Plant Tail).
  6. Escribir `assets/data/axie_part_stats_and_floops.csv` (exactamente 205 líneas, 1 header + 204 partes).
  7. Escribir `assets/data/mouth_tail_permutation_floops.csv` (exactamente 289 líneas, cabecera `permutation_mouth_tail,Axie_amount,Permutation_Type,Permutation_class`).
  8. Ejecutar `dart run tool/census/fetch_axie_census.dart` y documentar métricas en `logs/CYCLE_11_9_MODULE_1_DATA_AGENT_EXECUTION_REPORT.md`.

#### Módulo 2: Suite de Verificación Automatizada y Auditoría 4-Vector (`qa_agent`)
- **Archivo Objetivo:** `test/census_data_integrity_test.dart`
- **Responsabilidad:**
  1. Actualizar la suite de pruebas unitarias para validar el esquema ampliado de 4 columnas en `mouth_tail_permutation_floops.csv`.
  2. Implementar aserciones deterministas:
     - 205 líneas en `axie_part_stats_and_floops.csv` (0 nulos, valores numéricos no negativos).
     - 289 líneas en `mouth_tail_permutation_floops.csv` (1 cabecera + 288 permutaciones).
     - Validación de tipos: exactamente 144 `Pure` y 144 `Mix`.
     - Validación de clases: 24 para cada clase pura (Beast, Aquatic, Plant, Bird, Bug, Reptile) y 48 para cada clase híbrida (Mech, Dusk, Dawn).
     - Verificación estricta de subsanación de agujeros: `mouth-nut-cracker__tail-shiba` y `mouth-pincer__tail-shiba` deben ser estrictamente `> 0`.
  3. Ejecutar `flutter test test/census_data_integrity_test.dart` y la suite global `flutter test`.
  4. Ejecutar análisis estático `dart analyze --fatal-infos`.
  5. Ejecutar la evaluación de 4 vectores y emitir `logs/CYCLE_11_9_FINAL_AUDIT_PROMOTION_VERDICT.md` con veredicto `QA_VERDICT: [PROMOTION GRANTED]`.

---

### 2. Invariantes Arquitecturales y Topológicas
- **Soberanía Topológica:** Cero archivos `.dart` o binarios en `C:\LatiCore\`. Todo código reside en `C:\NeuroField\active_projects\lunacian_card_wars\`.
- **Espejado Semántico:** Documentos Markdown (sub-directivas y logs) se sincronizan en `C:\LatiCore\01_Projects\lunacian_card_wars\`.
- **Seguridad de Secretos:** Nunca registrar o commitear `SKY_MAVIS_API_KEY`.
- **Encabezados AST:** Mantener estrictamente el bloque de comentario AST de 6 campos en inglés al inicio de cada archivo Dart modificado.
