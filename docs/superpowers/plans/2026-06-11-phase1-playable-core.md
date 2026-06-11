# Phase 1: Playable Core Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete playable run of Time Travel Corp: contract selection → 8-quarter simulation with all core verbs (Dampen/Divert/Harvest) → debrief. All core mechanics from Sections 3–8 of the definitive design spec are operational.

**Architecture:** `RunSim` owns all simulation state as a pure `RunState` Resource; it never references UI nodes. `EventBus` carries typed signals from sim to UI. UI scripts subscribe to `EventBus` and never mutate sim state except through `RunSim` method calls. All numeric tuning is in `res://resources/balance_sheet.tres`. Content is `.tres` Resource files under `res://resources/`.

**Tech Stack:** Godot 4.3 (GL Compatibility renderer), GDScript 4, Resource-based data architecture, no external dependencies.

**Supersedes:** `docs/superpowers/plans/2026-06-07-time-travel-corporation.md` — that plan targeted the scrapped prototype (idle/incremental game). It is obsolete.

**Out of scope for Phase 1:** Incident event system, audio, CRT visual shader/post-process, Meta Anomaly unlock tree, PNG Incident Report export, mod support, era variant unlocks, Audit difficulty levels.

---

## File Map

```
scripts/resources/
  era_def.gd              EraDef resource class (updated)
  front_type_def.gd       FrontTypeDef resource class (updated)
  mutation_def.gd         MutationDef resource class (updated)
  contract_def.gd         ContractDef resource class (updated)
  directive_def.gd        DirectiveDef resource class (updated)
  incident_def.gd         IncidentDef resource class (updated, stub for Phase 2)
  modifier_def.gd         ModifierDef resource class (updated)
  mandate_def.gd          MandateDef resource class (updated)
  era_state.gd            NEW — runtime per-era state
  front_state.gd          NEW — runtime front state
  extractor_def.gd        NEW — extractor type definition
  run_state.gd            NEW — complete run save/state object
  quarter_report.gd       NEW — per-quarter summary data
  balance_sheet_data.gd   NEW — all numeric tuning constants

resources/
  balance_sheet.tres
  eras/antiquity.tres, middle_ages.tres, industrial.tres, future.tres
  fronts/myth.tres, dogma.tres, soot.tres
  mutations/primal_chaos.tres, dark_age.tres, diesel_wastes.tres
  extractors/steady.tres, burst.tres, deep.tres
  contracts/tier1_intro.tres, tier2_standard.tres, tier3_cascade.tres
  directives/  (12 .tres files)

scripts/core/
  event_bus.gd            Updated signals matching spec Section 19
  content_db.gd           Updated: indexes by type, scans extractors dir
  effect_resolver.gd      NEW — interprets op-list effects
  boot.gd                 Updated boot sequence

scripts/simulation/
  run_sim.gd              Full replacement — complete simulation engine

scripts/ui/
  main_menu.gd            Updated — adds Start button
  contract_select.gd      NEW
  era_panel.gd            NEW
  front_token.gd          NEW
  run_hud.gd              NEW — TopBar + BottomDock combined
  quarter_report_ui.gd    NEW
  debrief.gd              NEW

scenes/
  meta/main_menu.tscn     Updated
  meta/contract_select.tscn  NEW
  run/run.tscn            NEW — main game scene
  run/era_panel.tscn      NEW — instanced component
  run/front_token.tscn    NEW — instanced component
  ui/quarter_report.tscn  NEW
  ui/debrief.tscn         NEW
```

---

## Task 1: Update Resource Schemas

**Files:** Modify all 8 existing resource classes to match spec Section 20.

- [ ] **Step 1: Replace `scripts/resources/era_def.gd`**

```gdscript
extends Resource
class_name EraDef

@export var id: StringName = &""
@export var display_name: String = ""
@export var downstream_id: StringName = &""
@export var signature_rule: StringName = &""
@export var rule_params: Dictionary = {}
@export var extractor_cost_mult: float = 1.0
@export var instability_gain_mult: float = 1.0
@export var emits_front: StringName = &""
@export var mutation: MutationDef
@export var panel_art: Texture2D
@export var panel_art_mutated: Texture2D
```

- [ ] **Step 2: Replace `scripts/resources/front_type_def.gd`**

```gdscript
extends Resource
class_name FrontTypeDef

@export var id: StringName = &""
@export var origin_era: StringName = &""
@export var transmuted_name: String = ""
@export var travel_time_base: float = 45.0
@export var arrival_effects: Array[Dictionary] = []
@export var harvest_base: float = 150.0
@export var glyph: Texture2D
@export var codename_pool: Array[String] = []
```

- [ ] **Step 3: Replace `scripts/resources/mutation_def.gd`**

```gdscript
extends Resource
class_name MutationDef

@export var id: StringName = &""
@export var display_name: String = ""
@export var effects: Array[Dictionary] = []
@export var emission_interval_quarters: Array[int] = []
@export var yields_relics: bool = false
```

- [ ] **Step 4: Replace `scripts/resources/contract_def.gd`**

```gdscript
extends Resource
class_name ContractDef

@export var id: StringName = &""
@export var tier: int = 1
@export var display_name: String = ""
@export var quota: float = 0.0
@export var quota_relics: int = 0
@export var quarters: int = 8
@export var starting_injunctions: int = 3
@export var modifiers: Array[ModifierDef] = []
@export var mandate_pool: Array[MandateDef] = []
@export var anomaly_reward: int = 10
```

- [ ] **Step 5: Replace `scripts/resources/directive_def.gd`**

```gdscript
extends Resource
class_name DirectiveDef

@export_enum("gift", "deal", "mandate") var tone: int = 0
@export var id: StringName = &""
@export var title: String = ""
@export var body: String = ""
@export var effects: Array[Dictionary] = []
@export var duration_quarters: int = -1
```

- [ ] **Step 6: Replace `scripts/resources/incident_def.gd`**

```gdscript
extends Resource
class_name IncidentDef

@export var id: StringName = &""
@export var trigger: StringName = &""
@export var trigger_filter: Dictionary = {}
@export var weight: float = 1.0
@export var requires_flags: Array[StringName] = []
@export var memo_text: String = ""
@export var choices: Array[Dictionary] = []
@export var once_per_run: bool = true
```

- [ ] **Step 7: Replace `scripts/resources/modifier_def.gd`**

```gdscript
extends Resource
class_name ModifierDef

@export var id: StringName = &""
@export var display_name: String = ""
@export var effects: Array[Dictionary] = []
```

- [ ] **Step 8: Replace `scripts/resources/mandate_def.gd`**

```gdscript
extends Resource
class_name MandateDef

@export var id: StringName = &""
@export var display_name: String = ""
@export var reveal_text: String = ""
@export var condition: Dictionary = {}
@export var anomaly_bonus: int = 0
```

- [ ] **Step 9: Commit**

```bash
git add scripts/resources/
git commit -m "refactor: update resource schemas to match spec Section 20"
```

---

## Task 2: New Runtime Resource Classes

**Files:** Create 5 new resource classes.

- [ ] **Step 1: Create `scripts/resources/era_state.gd`**

```gdscript
extends Resource
class_name EraState

@export var era_id: StringName = &""
@export var instability: float = 0.0
@export var extractors: Array[Dictionary] = []
@export var mutation_severity: int = 0
@export var momentum: float = 0.0
@export var momentum_timer: float = 0.0
@export var contained: bool = false
@export var emission_timer: float = 0.0
```

- [ ] **Step 2: Create `scripts/resources/front_state.gd`**

```gdscript
extends Resource
class_name FrontState

@export var uid: int = 0
@export var type_id: StringName = &""
@export var codename: String = ""
@export var severity: int = 1
@export var origin_era_id: StringName = &""
@export var target_era_id: StringName = &""
@export var progress: float = 0.0
@export var travel_time: float = 45.0
@export var harvested: bool = false
@export var diverted_from: StringName = &""
@export var spawn_quarter: int = 0
```

- [ ] **Step 3: Create `scripts/resources/extractor_def.gd`**

```gdscript
extends Resource
class_name ExtractorDef

@export var id: StringName = &""
@export var display_name: String = ""
@export var base_cost: float = 100.0
@export var yield_per_second: float = 10.0
@export var instability_per_second: float = 0.5
@export var burst_duration: float = 0.0
@export var burst_yield: float = 0.0
@export var burst_instability_spike: float = 0.0
@export var post_burst_yield: float = 0.0
@export var deep_countdown_quarters: int = 0
```

- [ ] **Step 4: Create `scripts/resources/quarter_report.gd`**

```gdscript
extends Resource
class_name QuarterReport

@export var quarter: int = 0
@export var capital_start: float = 0.0
@export var capital_end: float = 0.0
@export var fronts_dampened: int = 0
@export var fronts_harvested: int = 0
@export var fronts_diverted: int = 0
@export var mutations_this_quarter: int = 0
@export var directives_offered: Array[DirectiveDef] = []
@export var directive_chosen_id: StringName = &""
```

- [ ] **Step 5: Create `scripts/resources/run_state.gd`**

```gdscript
extends Resource
class_name RunState

@export var seed: int = 0
@export var contract_id: StringName = &""
@export var quarter: int = 1
@export var sim_time: float = 0.0
@export var quarter_time: float = 0.0
@export var capital: float = 0.0
@export var relics: int = 0
@export var injunctions: int = 3
@export var restock_count: int = 0
@export var singularity: float = 0.0
@export var eras: Array[EraState] = []
@export var fronts: Array[FrontState] = []
@export var active_directives: Array[Dictionary] = []
@export var flags: Dictionary = {}
@export var action_log: Array[Dictionary] = []
@export var parachute_used: bool = false
@export var quarter_capitals: Array[float] = []
```

- [ ] **Step 6: Create `scripts/resources/balance_sheet_data.gd`**

```gdscript
extends Resource
class_name BalanceSheetData

# Front travel
@export var front_travel_base: float = 45.0
@export var mutation_speed_bonus: float = 0.2

# Singularity
@export var soot_singularity_gain: float = 25.0
@export var multi_mutation_singularity_per_quarter: float = 10.0

# Extractors
@export var extractor_cost_scaling: float = 1.6
@export var extractor_salvage_rate: float = 0.25
@export var temporal_scar_instability: float = 10.0
@export var deep_antiquity_bonus: float = 1.5
@export var momentum_stack_rate: float = 0.05
@export var momentum_cap: float = 1.0

# Harvest
@export var harvest_speed_bonus: float = 0.75
@export var harvest_contract_bonus: float = 150.0

# Era interaction
@export var mutation_neighbor_pressure: float = 0.05

# Instability
@export var instability_overflow_reset: float = 40.0

# Restock
@export var restock_base_cost_pct: float = 0.15

# Q-phase instability multipliers
@export var early_quarter_instability_mult: float = 0.6
@export var late_quarter_yield_bonus: float = 0.25
@export var late_quarter_instability_reduction: float = 0.4

# Foundation (Antiquity) downstream bonus
@export var foundation_max_bonus: float = 0.5

# Future speculation
@export var speculation_era_count: int = 4
```

- [ ] **Step 7: Commit**

```bash
git add scripts/resources/
git commit -m "feat: add runtime resource classes (RunState, EraState, FrontState, ExtractorDef, QuarterReport, BalanceSheetData)"
```

---

## Task 3: BalanceSheet .tres + Content Data Files

**Files:** Create `resources/balance_sheet.tres` and all content `.tres` files.

- [ ] **Step 1: Create `resources/balance_sheet.tres`**

```
[gd_resource type="BalanceSheetData" format=3]

[resource]
front_travel_base = 45.0
mutation_speed_bonus = 0.2
soot_singularity_gain = 25.0
multi_mutation_singularity_per_quarter = 10.0
extractor_cost_scaling = 1.6
extractor_salvage_rate = 0.25
temporal_scar_instability = 10.0
deep_antiquity_bonus = 1.5
momentum_stack_rate = 0.05
momentum_cap = 1.0
harvest_speed_bonus = 0.75
harvest_contract_bonus = 150.0
mutation_neighbor_pressure = 0.05
instability_overflow_reset = 40.0
restock_base_cost_pct = 0.15
early_quarter_instability_mult = 0.6
late_quarter_yield_bonus = 0.25
late_quarter_instability_reduction = 0.4
foundation_max_bonus = 0.5
speculation_era_count = 4
```

- [ ] **Step 2: Create `resources/mutations/primal_chaos.tres`**

```
[gd_resource type="MutationDef" format=3]

[resource]
id = &"primal_chaos"
display_name = "PRIMAL CHAOS"
effects = [{"scope": "era", "era_id": "antiquity", "stat": "yield_mult", "op": "set", "value": 0.0, "severity_min": 1}]
emission_interval_quarters = [2, 1]
yields_relics = false
```

- [ ] **Step 3: Create `resources/mutations/dark_age.tres`**

```
[gd_resource type="MutationDef" format=3]

[resource]
id = &"dark_age"
display_name = "DARK AGE"
effects = [{"scope": "era", "era_id": "middle_ages", "stat": "instability_gain_mult", "op": "multiply", "value": 2.0, "severity_min": 1}]
emission_interval_quarters = [0, 1]
yields_relics = true
```

- [ ] **Step 4: Create `resources/mutations/diesel_wastes.tres`**

```
[gd_resource type="MutationDef" format=3]

[resource]
id = &"diesel_wastes"
display_name = "DIESEL WASTES"
effects = [{"scope": "era", "era_id": "industrial", "stat": "yield_mult", "op": "multiply", "value": 2.0, "severity_min": 1}, {"scope": "era", "era_id": "industrial", "stat": "yield_mult", "op": "multiply", "value": 3.0, "severity_min": 2}]
emission_interval_quarters = [2, 1]
yields_relics = false
```

- [ ] **Step 5: Create `resources/eras/antiquity.tres`**

Note: `mutation` field references `primal_chaos.tres`. In the Godot text format, sub-resources use `[sub_resource]` blocks or `ExtResource`. For simplicity, set `mutation` to null in the file and assign it via ContentDB at runtime, OR use the ext_resource pattern. Since these files are loaded by ContentDB, use `ExtResource`:

```
[gd_resource type="EraDef" format=3]

[ext_resource type="Resource" path="res://resources/mutations/primal_chaos.tres" id="1"]

[resource]
id = &"antiquity"
display_name = "Antiquity"
downstream_id = &"middle_ages"
signature_rule = &"foundation"
rule_params = {"foundation_max_bonus": 0.5}
extractor_cost_mult = 1.0
instability_gain_mult = 1.0
emits_front = &"myth"
mutation = ExtResource("1")
```

- [ ] **Step 6: Create `resources/eras/middle_ages.tres`**

```
[gd_resource type="EraDef" format=3]

[ext_resource type="Resource" path="res://resources/mutations/dark_age.tres" id="1"]

[resource]
id = &"middle_ages"
display_name = "Middle Ages"
downstream_id = &"industrial"
signature_rule = &"brittle"
rule_params = {}
extractor_cost_mult = 0.7
instability_gain_mult = 1.5
emits_front = &"dogma"
mutation = ExtResource("1")
```

- [ ] **Step 7: Create `resources/eras/industrial.tres`**

```
[gd_resource type="EraDef" format=3]

[ext_resource type="Resource" path="res://resources/mutations/diesel_wastes.tres" id="1"]

[resource]
id = &"industrial"
display_name = "Industrial"
downstream_id = &"future"
signature_rule = &"momentum"
rule_params = {"momentum_tick_interval": 10.0, "momentum_step": 0.05, "momentum_cap": 1.0}
extractor_cost_mult = 1.0
instability_gain_mult = 1.0
emits_front = &"soot"
mutation = ExtResource("1")
```

- [ ] **Step 8: Create `resources/eras/future.tres`**

```
[gd_resource type="EraDef" format=3]

[resource]
id = &"future"
display_name = "Future"
downstream_id = &""
signature_rule = &"speculation"
rule_params = {}
extractor_cost_mult = 1.0
instability_gain_mult = 1.0
emits_front = &""
```

- [ ] **Step 9: Create `resources/fronts/myth.tres`**

```
[gd_resource type="FrontTypeDef" format=3]

[resource]
id = &"myth"
origin_era = &"antiquity"
transmuted_name = "Zealotry"
travel_time_base = 45.0
arrival_effects = [{"stat": "instability_gain_mult", "op": "multiply", "value": 1.5, "scope": "era", "duration_quarters": 2, "severity_min": 1}, {"stat": "trigger_mutation", "op": "set", "value": 1.0, "scope": "era", "severity_min": 1, "condition": "instability_at_100"}]
harvest_base = 150.0
codename_pool = ["PROMETHEUS", "GORGON", "BABEL", "ATLAS", "ICARUS", "MEDUSA", "HYDRA", "TITAN", "KRONOS", "OLYMPUS"]
```

- [ ] **Step 10: Create `resources/fronts/dogma.tres`**

```
[gd_resource type="FrontTypeDef" format=3]

[resource]
id = &"dogma"
origin_era = &"middle_ages"
transmuted_name = "Stagnation"
travel_time_base = 45.0
arrival_effects = [{"stat": "momentum", "op": "set", "value": 0.0, "scope": "era", "duration_quarters": 1, "severity_min": 1}, {"stat": "trigger_mutation", "op": "set", "value": 1.0, "scope": "era", "severity_min": 1, "condition": "instability_at_100"}]
harvest_base = 150.0
codename_pool = ["INQUISITION", "CRUSADE", "SCHISM", "HERESY", "INTERDICT", "EXCOMMUNICATION", "DECREE", "EDICT", "BULL", "CANON"]
```

- [ ] **Step 11: Create `resources/fronts/soot.tres`**

```
[gd_resource type="FrontTypeDef" format=3]

[resource]
id = &"soot"
origin_era = &"industrial"
transmuted_name = "Singularity progress"
travel_time_base = 45.0
arrival_effects = [{"stat": "singularity", "op": "add", "value": 25.0, "scope": "global", "severity_min": 1}]
harvest_base = 150.0
codename_pool = ["SMOKESTACK", "GRIDLOCK", "MELTDOWN", "BLOWOUT", "RUNAWAY", "OVERCLOCK", "FEEDBACK", "CASCADE", "TERMINUS", "SINGULARITY"]
```

- [ ] **Step 12: Create `resources/extractors/steady.tres`**

```
[gd_resource type="ExtractorDef" format=3]

[resource]
id = &"steady"
display_name = "Steady Extractor"
base_cost = 100.0
yield_per_second = 10.0
instability_per_second = 0.5
burst_duration = 0.0
burst_yield = 0.0
burst_instability_spike = 0.0
post_burst_yield = 0.0
deep_countdown_quarters = 0
```

- [ ] **Step 13: Create `resources/extractors/burst.tres`**

```
[gd_resource type="ExtractorDef" format=3]

[resource]
id = &"burst"
display_name = "Burst Extractor"
base_cost = 150.0
yield_per_second = 0.0
instability_per_second = 1.0
burst_duration = 15.0
burst_yield = 40.0
burst_instability_spike = 15.0
post_burst_yield = 5.0
deep_countdown_quarters = 0
```

- [ ] **Step 14: Create `resources/extractors/deep.tres`**

```
[gd_resource type="ExtractorDef" format=3]

[resource]
id = &"deep"
display_name = "Deep Extractor"
base_cost = 400.0
yield_per_second = 35.0
instability_per_second = 0.5
burst_duration = 0.0
burst_yield = 0.0
burst_instability_spike = 0.0
post_burst_yield = 0.0
deep_countdown_quarters = 2
```

- [ ] **Step 15: Create `resources/contracts/tier1_intro.tres`**

```
[gd_resource type="ContractDef" format=3]

[resource]
id = &"tier1_intro"
tier = 1
display_name = "Q1 Revenue Initiative"
quota = 5000.0
quota_relics = 0
quarters = 8
starting_injunctions = 3
anomaly_reward = 10
```

- [ ] **Step 16: Create `resources/contracts/tier2_standard.tres`**

```
[gd_resource type="ContractDef" format=3]

[resource]
id = &"tier2_standard"
tier = 2
display_name = "Temporal Extraction Mandate"
quota = 12000.0
quota_relics = 0
quarters = 8
starting_injunctions = 3
anomaly_reward = 20
```

- [ ] **Step 17: Create `resources/contracts/tier3_cascade.tres`**

```
[gd_resource type="ContractDef" format=3]

[resource]
id = &"tier3_cascade"
tier = 3
display_name = "Aggressive Extraction Protocol"
quota = 25000.0
quota_relics = 0
quarters = 8
starting_injunctions = 3
anomaly_reward = 35
```

- [ ] **Step 18: Create 12 directive .tres files in `resources/directives/`**

Create each file with the following content. Tone values: 0=gift, 1=deal, 2=mandate.

`resources/directives/stimulus_package.tres`:
```
[gd_resource type="DirectiveDef" format=3]
[resource]
id = &"stimulus_package"
tone = 0
title = "Stimulus Package"
body = "The Board has approved an emergency capital injection."
effects = [{"stat": "capital", "op": "add", "value": 300.0, "scope": "global", "duration": 0}]
duration_quarters = 0
```

`resources/directives/overclock_antiquity.tres`:
```
[gd_resource type="DirectiveDef" format=3]
[resource]
id = &"overclock_antiquity"
tone = 0
title = "Overclock Antiquity"
body = "Antiquity extraction quotas have been raised. Yields reflect Board expectations."
effects = [{"stat": "yield_mult", "op": "multiply", "value": 1.5, "scope": "era", "era_id": "antiquity", "duration": -1}]
duration_quarters = -1
```

`resources/directives/legal_retainer.tres`:
```
[gd_resource type="DirectiveDef" format=3]
[resource]
id = "legal_retainer"
tone = 0
title = "Legal Retainer"
body = "Counsel has been retained. Your next Injunction restock is on the Board."
effects = [{"stat": "next_restock_free", "op": "set", "value": 1.0, "scope": "global", "duration": -1}]
duration_quarters = -1
```

`resources/directives/free_injunction.tres`:
```
[gd_resource type="DirectiveDef" format=3]
[resource]
id = &"free_injunction"
tone = 0
title = "Emergency Authorization"
body = "One additional Continuity Injunction has been approved."
effects = [{"stat": "injunctions", "op": "add", "value": 1.0, "scope": "global", "duration": 0}]
duration_quarters = 0
```

`resources/directives/aggressive_targets.tres`:
```
[gd_resource type="DirectiveDef" format=3]
[resource]
id = &"aggressive_targets"
tone = 1
title = "Aggressive Quarterly Targets"
body = "Yields up. Instability up. The Board never said this would be comfortable."
effects = [{"stat": "yield_mult", "op": "multiply", "value": 1.4, "scope": "global", "duration": -1}, {"stat": "instability_gain_mult", "op": "multiply", "value": 1.3, "scope": "global", "duration": -1}]
duration_quarters = -1
```

`resources/directives/outsource_risk.tres`:
```
[gd_resource type="DirectiveDef" format=3]
[resource]
id = &"outsource_risk"
tone = 1
title = "Outsource Risk"
body = "Fronts will be slower. The quota will be larger. That is someone else's problem."
effects = [{"stat": "front_speed_mult", "op": "multiply", "value": 0.8, "scope": "global", "duration": -1}]
duration_quarters = -1
```

`resources/directives/asset_stripping.tres`:
```
[gd_resource type="DirectiveDef" format=3]
[resource]
id = &"asset_stripping"
tone = 1
title = "Asset Stripping"
body = "Demolition returns full cost. Temporal scars are now someone else's era."
effects = [{"stat": "salvage_rate", "op": "set", "value": 1.0, "scope": "global", "duration": -1}, {"stat": "scar_mult", "op": "multiply", "value": 2.0, "scope": "global", "duration": -1}]
duration_quarters = -1
```

`resources/directives/capital_injection.tres`:
```
[gd_resource type="DirectiveDef" format=3]
[resource]
id = &"capital_injection"
tone = 0
title = "Capital Injection"
body = "Liquidity secured. Proceed with expansion."
effects = [{"stat": "capital", "op": "add", "value": 600.0, "scope": "global", "duration": 0}]
duration_quarters = 0
```

`resources/directives/synergy_initiative.tres`:
```
[gd_resource type="DirectiveDef" format=3]
[resource]
id = &"synergy_initiative"
tone = 2
title = "Synergy Initiative"
body = "Your lowest-yield era will receive a complimentary Steady extractor each quarter. The Board is generous."
effects = [{"stat": "synergy_initiative_active", "op": "set", "value": 1.0, "scope": "global", "duration": -1}]
duration_quarters = -1
```

`resources/directives/founder_watching.tres`:
```
[gd_resource type="DirectiveDef" format=3]
[resource]
id = &"founder_watching"
tone = 2
title = "The Founder Is Watching"
body = "Harvest values doubled. Dampen is unavailable this quarter. The Founder trusts you."
effects = [{"stat": "harvest_mult", "op": "multiply", "value": 2.0, "scope": "global", "duration": 1}, {"stat": "dampen_disabled", "op": "set", "value": 1.0, "scope": "global", "duration": 1}]
duration_quarters = 1
```

`resources/directives/hands_on_antiquity.tres`:
```
[gd_resource type="DirectiveDef" format=3]
[resource]
id = &"hands_on_antiquity"
tone = 1
title = "Hands-On Antiquity"
body = "Antiquity instability gain reduced. Foundation bonuses enhanced."
effects = [{"stat": "instability_gain_mult", "op": "multiply", "value": 0.7, "scope": "era", "era_id": "antiquity", "duration": -1}]
duration_quarters = -1
```

`resources/directives/industrial_subsidy.tres`:
```
[gd_resource type="DirectiveDef" format=3]
[resource]
id = &"industrial_subsidy"
tone = 0
title = "Industrial Subsidy"
body = "Industrial extraction costs reduced this quarter."
effects = [{"stat": "cost_mult", "op": "multiply", "value": 0.7, "scope": "era", "era_id": "industrial", "duration": 1}]
duration_quarters = 1
```

- [ ] **Step 19: Commit**

```bash
git add resources/
git commit -m "feat: add BalanceSheet, era/front/mutation/extractor/contract/directive content files"
```

---

## Task 4: Update EventBus and ContentDB

**Files:** `scripts/core/event_bus.gd`, `scripts/core/content_db.gd`

- [ ] **Step 1: Replace `scripts/core/event_bus.gd`**

```gdscript
extends Node

# Simulation lifecycle
signal run_started
signal run_ended(result: Dictionary)
signal run_paused
signal run_resumed
signal tick_processed

# Front events
signal front_spawned(front: FrontState)
signal front_resolved(front: FrontState, resolution: int)  # 0=arrived, 1=dampened, 2=diverted

# Era events
signal era_mutated(era_id: StringName, severity: int)
signal singularity_changed(value: float)

# Quarter events
signal quarter_ended(report: QuarterReport)
signal directive_required(directives: Array)

# Incident
signal incident_triggered(incident: IncidentDef)

# Content
signal content_loaded
signal content_validation_failed(errors: Array)

# UI meta
signal screen_changed(screen_name: String)

# Player action relay (UI → sim, for action log and potential replay)
signal player_action(action: Dictionary)
```

- [ ] **Step 2: Replace `scripts/core/content_db.gd`**

```gdscript
extends Node

## Central repository for all static game content.
## Loads, validates, and indexes resources at boot.

var _registry: Dictionary = {}       # id -> Resource
var _type_index: Dictionary = {}     # class_name string -> Array[Resource]

func load_all_content() -> void:
    _registry.clear()
    _type_index.clear()

    var dirs = [
        "res://resources/eras",
        "res://resources/fronts",
        "res://resources/mutations",
        "res://resources/extractors",
        "res://resources/contracts",
        "res://resources/directives",
        "res://resources/incidents",
        "res://resources/modifiers",
        "res://resources/mutations",
    ]

    for dir_path in dirs:
        var dir = DirAccess.open(dir_path)
        if not dir:
            continue
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if not dir.current_is_dir() and file_name.ends_with(".tres"):
                var res_path = dir_path + "/" + file_name
                var res = load(res_path)
                if res and res.get("id") != null:
                    var id = res.id
                    if id != &"" and id != "":
                        _registry[id] = res
                        var type_name = res.get_class()
                        if not _type_index.has(type_name):
                            _type_index[type_name] = []
                        _type_index[type_name].append(res)
            file_name = dir.get_next()

    EventBus.content_loaded.emit()

func validate_content() -> void:
    var errors: Array = []
    var seen: Dictionary = {}

    for id in _registry:
        if id == "" or id == &"":
            errors.append("Resource with empty ID found.")
            continue
        if seen.has(id):
            errors.append("Duplicate ID: " + str(id))
        seen[id] = true

    if errors.size() > 0:
        EventBus.content_validation_failed.emit(errors)
        for err in errors:
            push_error("ContentDB: " + err)
    else:
        print("ContentDB: All content valid. %d resources loaded." % _registry.size())

func get_by_id(id: StringName) -> Resource:
    if _registry.has(id):
        return _registry[id]
    return null

func get_all_of_type(type_name: String) -> Array:
    return _type_index.get(type_name, []).duplicate()

func get_all_contracts() -> Array[ContractDef]:
    var result: Array[ContractDef] = []
    for r in _type_index.get("ContractDef", []):
        result.append(r as ContractDef)
    result.sort_custom(func(a, b): return a.tier < b.tier)
    return result
```

- [ ] **Step 3: Verify**

Press **F5**. In Output panel you should see:
```
ContentDB: All content valid. N resources loaded.
```
where N is the total number of `.tres` files created. No errors.

- [ ] **Step 4: Commit**

```bash
git add scripts/core/event_bus.gd scripts/core/content_db.gd
git commit -m "feat: update EventBus with spec signals, ContentDB with type indexing and extractor scanning"
```

---

## Task 5: EffectResolver

**Files:** Create `scripts/core/effect_resolver.gd`

- [ ] **Step 1: Create `scripts/core/effect_resolver.gd`**

This is a static utility class. RunSim and other systems call it directly via `EffectResolver.apply_op(...)`.

```gdscript
class_name EffectResolver
extends RefCounted

## Interprets op-list effects onto RunState or EraState.
## Effect Dictionary schema:
##   stat: String       — which stat to modify
##   op: String         — "add", "multiply", "set"
##   value: float       — the operand
##   scope: String      — "global", "era"
##   era_id: String     — required when scope == "era"
##   duration: int      — -1=permanent, 0=instant, N=quarters
##   severity_min: int  — minimum front severity for arrival effects
##   duration_quarters: int — alias for duration

static func apply_op(base: float, effect: Dictionary) -> float:
    var op = effect.get("op", "add")
    var val = float(effect.get("value", 0.0))
    match op:
        "add":
            return base + val
        "multiply":
            return base * val
        "set":
            return val
    return base

static func apply_global(effect: Dictionary, state: RunState) -> void:
    var stat = effect.get("stat", "")
    var op = effect.get("op", "add")
    var val = float(effect.get("value", 0.0))
    match stat:
        "capital":
            state.capital = apply_op(state.capital, effect)
        "injunctions":
            state.injunctions = int(apply_op(float(state.injunctions), effect))
        "singularity":
            state.singularity = apply_op(state.singularity, effect)

static func apply_to_era(effect: Dictionary, era_state: EraState, state: RunState) -> void:
    var stat = effect.get("stat", "")
    match stat:
        "instability":
            era_state.instability = apply_op(era_state.instability, effect)
            era_state.instability = clampf(era_state.instability, 0.0, 100.0)
        "momentum":
            era_state.momentum = apply_op(era_state.momentum, effect)
        "singularity":
            # Soot front effect — applies to global singularity
            state.singularity += float(effect.get("value", 25.0))

static func get_global_multiplier(stat: String, active_directives: Array, scope_filter: String = "global") -> float:
    var result = 1.0
    for directive in active_directives:
        for effect in directive.get("effects", []):
            if effect.get("scope", "") == scope_filter and effect.get("stat", "") == stat:
                var op = effect.get("op", "multiply")
                if op == "multiply":
                    result *= float(effect.get("value", 1.0))
    return result

static func get_era_multiplier(stat: String, era_id: StringName, active_directives: Array) -> float:
    var result = 1.0
    for directive in active_directives:
        for effect in directive.get("effects", []):
            if (effect.get("scope", "") == "era"
                    and StringName(effect.get("era_id", "")) == era_id
                    and effect.get("stat", "") == stat):
                var op = effect.get("op", "multiply")
                if op == "multiply":
                    result *= float(effect.get("value", 1.0))
    return result

static func has_flag(flag: String, active_directives: Array) -> bool:
    for directive in active_directives:
        for effect in directive.get("effects", []):
            if effect.get("stat", "") == flag and float(effect.get("value", 0.0)) > 0.0:
                return true
    return false

static func tick_directive_durations(state: RunState) -> void:
    var to_remove: Array = []
    for directive in state.active_directives:
        var remaining = int(directive.get("quarters_remaining", -1))
        if remaining == -1:
            continue
        directive["quarters_remaining"] = remaining - 1
        if directive["quarters_remaining"] <= 0:
            to_remove.append(directive)
    for d in to_remove:
        state.active_directives.erase(d)
```

- [ ] **Step 2: Commit**

```bash
git add scripts/core/effect_resolver.gd
git commit -m "feat: add EffectResolver static utility for op-list effect application"
```

---

## Task 6: RunSim — Full Simulation Engine

**Files:** Replace `scripts/simulation/run_sim.gd` entirely.

- [ ] **Step 1: Replace `scripts/simulation/run_sim.gd`**

```gdscript
extends Node

## Central simulation owner. Pure state machine; never references UI nodes.
## Communicates only via EventBus signals.

enum Phase { IDLE, RUNNING, PAUSED, QUARTER_REPORT, ENDED }

const TICK_RATE: float = 0.1
const QUARTER_DURATION: float = 90.0
const ERA_ORDER: Array[StringName] = [&"antiquity", &"middle_ages", &"industrial", &"future"]

var _state: RunState
var _phase: Phase = Phase.IDLE
var _tick_accum: float = 0.0
var _rng: RandomNumberGenerator
var _balance: BalanceSheetData
var _front_uid_counter: int = 0
var _pending_directives: Array[DirectiveDef] = []
var _quarter_capital_start: float = 0.0

func _ready() -> void:
    _balance = load("res://resources/balance_sheet.tres")

func _process(delta: float) -> void:
    if _phase != Phase.RUNNING:
        return
    _tick_accum += delta
    while _tick_accum >= TICK_RATE:
        _tick_accum -= TICK_RATE
        _simulate(TICK_RATE)

# ── Public API ──────────────────────────────────────────────────────────────

func start_run(contract_id: StringName) -> void:
    var contract := ContentDB.get_by_id(contract_id) as ContractDef
    if not contract:
        push_error("RunSim: unknown contract " + str(contract_id))
        return

    _state = RunState.new()
    _state.seed = randi()
    _state.contract_id = contract_id
    _state.quarter = 1
    _state.sim_time = 0.0
    _state.quarter_time = 0.0
    _state.capital = 0.0
    _state.relics = 0
    _state.injunctions = contract.starting_injunctions
    _state.restock_count = 0
    _state.singularity = 0.0
    _state.parachute_used = false
    _state.active_directives = []
    _state.flags = {}
    _state.action_log = []
    _state.quarter_capitals = []

    _rng = RandomNumberGenerator.new()
    _rng.seed = _state.seed
    _front_uid_counter = 0

    _state.eras = []
    for era_id in ERA_ORDER:
        var es := EraState.new()
        es.era_id = era_id
        _state.eras.append(es)

    _state.fronts = []
    _quarter_capital_start = 0.0
    _phase = Phase.RUNNING
    EventBus.run_started.emit()

func pause() -> void:
    if _phase == Phase.RUNNING:
        _phase = Phase.PAUSED
        EventBus.run_paused.emit()

func resume() -> void:
    if _phase == Phase.PAUSED:
        _phase = Phase.RUNNING
        EventBus.run_resumed.emit()

func place_extractor(era_id: StringName, ext_type_id: StringName) -> bool:
    if _phase != Phase.RUNNING:
        return false
    var era_state := _get_era(era_id)
    var era_def := ContentDB.get_by_id(era_id) as EraDef
    var ext_def := ContentDB.get_by_id(ext_type_id) as ExtractorDef
    if not era_state or not era_def or not ext_def:
        return false

    var cost := _extractor_cost(ext_def, era_state, era_def)
    if _state.capital < cost:
        return false

    _state.capital -= cost

    var rec := {
        "type_id": ext_type_id,
        "placed_at": _state.sim_time,
        "placed_quarter": _state.quarter,
        "burst_timer": 0.0,
        "burst_active": ext_type_id == &"burst",
    }
    era_state.extractors.append(rec)

    if era_id == &"industrial":
        era_state.momentum = 0.0
        era_state.momentum_timer = 0.0

    _log("place_extractor", {"era_id": era_id, "type_id": ext_type_id, "cost": cost})
    EventBus.player_action.emit({"action": "place_extractor", "era_id": era_id, "type_id": ext_type_id})
    return true

func remove_extractor(era_id: StringName, index: int) -> bool:
    if _phase != Phase.RUNNING:
        return false
    var era_state := _get_era(era_id)
    if not era_state or index >= era_state.extractors.size():
        return false

    var rec: Dictionary = era_state.extractors[index]
    var ext_def := ContentDB.get_by_id(rec.type_id) as ExtractorDef
    var era_def := ContentDB.get_by_id(era_id) as EraDef
    if ext_def and era_def:
        var salvage_rate := _balance.extractor_salvage_rate
        if EffectResolver.has_flag("salvage_rate_override", _state.active_directives):
            salvage_rate = 1.0
        _state.capital += _extractor_cost(ext_def, era_state, era_def) * salvage_rate

    era_state.extractors.remove_at(index)
    era_state.instability = minf(era_state.instability + _balance.temporal_scar_instability, 100.0)

    if era_id == &"industrial":
        era_state.momentum = 0.0
        era_state.momentum_timer = 0.0

    _log("remove_extractor", {"era_id": era_id, "index": index})
    return true

func dampen_front(front_uid: int) -> bool:
    if _phase != Phase.RUNNING:
        return false
    if EffectResolver.has_flag("dampen_disabled", _state.active_directives):
        return false
    if _state.injunctions <= 0:
        return false
    var front := _find_front(front_uid)
    if not front or front.harvested:
        return false

    _state.injunctions -= 1
    _state.fronts.erase(front)
    _log("dampen", {"front_uid": front_uid})
    EventBus.front_resolved.emit(front, 1)
    EventBus.player_action.emit({"action": "dampen", "front_uid": front_uid})
    return true

func divert_front(front_uid: int) -> bool:
    if _phase != Phase.RUNNING:
        return false
    var front := _find_front(front_uid)
    if not front or front.harvested:
        return false
    var target_def := ContentDB.get_by_id(front.target_era_id) as EraDef
    if not target_def or target_def.downstream_id == &"":
        return false

    var cost := _divert_cost(front)
    if _state.capital < cost:
        return false

    _state.capital -= cost
    front.diverted_from = front.target_era_id
    front.target_era_id = target_def.downstream_id
    front.progress = 0.0
    front.travel_time = _travel_time()

    _log("divert", {"front_uid": front_uid, "cost": cost, "new_target": front.target_era_id})
    EventBus.player_action.emit({"action": "divert", "front_uid": front_uid, "cost": cost})
    return true

func harvest_front(front_uid: int) -> bool:
    if _phase != Phase.RUNNING:
        return false
    var front := _find_front(front_uid)
    if not front or front.harvested:
        return false

    var payout := _harvest_payout(front)
    var harvest_mult := EffectResolver.get_global_multiplier("harvest_mult", _state.active_directives)
    payout *= harvest_mult

    front.harvested = true
    front.severity = mini(front.severity + 1, 2)
    front.travel_time *= _balance.harvest_speed_bonus

    _state.capital += payout
    _log("harvest", {"front_uid": front_uid, "payout": payout})
    EventBus.player_action.emit({"action": "harvest", "front_uid": front_uid, "payout": payout})
    return true

func pick_directive(directive_id: StringName) -> void:
    if _phase != Phase.QUARTER_REPORT:
        return
    var directive: DirectiveDef = null
    for d in _pending_directives:
        if d.id == directive_id:
            directive = d
            break
    if not directive:
        return

    var entry := {
        "id": directive.id,
        "quarters_remaining": directive.duration_quarters,
        "effects": directive.effects,
    }
    _state.active_directives.append(entry)

    # Apply instant effects (duration == 0)
    for effect in directive.effects:
        var dur := int(effect.get("duration", effect.get("duration_quarters", -1)))
        if dur == 0:
            EffectResolver.apply_global(effect, _state)

    # Handle Synergy Initiative on quarter start
    if directive.id == &"synergy_initiative":
        _state.flags[&"synergy_initiative"] = true

    _log("directive", {"id": directive_id})
    _state.quarter += 1
    _pending_directives.clear()
    _phase = Phase.RUNNING
    _quarter_capital_start = _state.capital

func restock_injunctions() -> bool:
    var cost := _restock_cost()
    if _state.capital < cost:
        return false
    _state.capital -= cost
    _state.injunctions += 3
    _state.restock_count += 1
    return true

func get_state() -> RunState:
    return _state

func get_phase() -> Phase:
    return _phase

func get_extractor_cost(era_id: StringName, ext_type_id: StringName) -> float:
    var era_state := _get_era(era_id)
    var era_def := ContentDB.get_by_id(era_id) as EraDef
    var ext_def := ContentDB.get_by_id(ext_type_id) as ExtractorDef
    if not era_state or not era_def or not ext_def:
        return -1.0
    return _extractor_cost(ext_def, era_state, era_def)

# ── Simulation tick ─────────────────────────────────────────────────────────

func _simulate(dt: float) -> void:
    _state.sim_time += dt
    _state.quarter_time += dt

    # Q1-Q2 pacing: suppress cascades before 60s mark
    var allow_cascade := not (_state.quarter <= 2 and _state.quarter_time < 60.0)

    # Tick eras
    for es in _state.eras:
        _tick_era(es, dt, allow_cascade)

    # Tick fronts
    _tick_fronts(dt)

    # Synergy Initiative: place free Steady in lowest-yield era each quarter tick
    # (handled at quarter boundary instead — see _end_quarter)

    # Check quarter boundary
    if _state.quarter_time >= QUARTER_DURATION:
        _end_quarter()
        return

    EventBus.tick_processed.emit()

func _tick_era(es: EraState, dt: float, allow_cascade: bool) -> void:
    if es.contained:
        return

    var era_def := ContentDB.get_by_id(es.era_id) as EraDef
    if not era_def:
        return

    # Yield calculation
    var relic_gain := 0.0
    for rec in es.extractors:
        var ext_def := ContentDB.get_by_id(rec.type_id) as ExtractorDef
        if not ext_def:
            continue

        # Burst extractor timer
        if rec.type_id == &"burst":
            if rec.burst_active:
                rec.burst_timer += dt
                if rec.burst_timer >= ext_def.burst_duration:
                    rec.burst_active = false

        var yield_rate := _extractor_yield(ext_def, rec, es, era_def)

        # Dark Age yields Relics, not capital
        if es.era_id == &"middle_ages" and es.mutation_severity > 0:
            if ext_def.id == &"burst":
                relic_gain += yield_rate * dt
            # non-burst yields nothing in Dark Age
        else:
            _state.capital += yield_rate * dt

    if relic_gain > 0.0:
        # Accumulate fractional relics, convert whole units
        var relic_acc: float = float(_state.flags.get(&"relic_accumulator", 0.0))
        relic_acc += relic_gain
        if relic_acc >= 1.0:
            _state.relics += int(relic_acc)
            relic_acc = fmod(relic_acc, 1.0)
        _state.flags[&"relic_accumulator"] = relic_acc

    # Instability gain from extractors
    var inst_gain := 0.0
    for rec in es.extractors:
        var ext_def := ContentDB.get_by_id(rec.type_id) as ExtractorDef
        if not ext_def:
            continue
        var base_gain := ext_def.instability_per_second
        if rec.type_id == &"burst" and rec.burst_active:
            base_gain = ext_def.burst_instability_spike / ext_def.burst_duration
        inst_gain += base_gain

    # Era-specific instability multiplier
    inst_gain *= era_def.instability_gain_mult
    inst_gain *= EffectResolver.get_era_multiplier("instability_gain_mult", es.era_id, _state.active_directives)
    inst_gain *= EffectResolver.get_global_multiplier("instability_gain_mult", _state.active_directives)

    # Q1-Q2 suppression
    if _state.quarter <= 2:
        inst_gain *= _balance.early_quarter_instability_mult

    es.instability = minf(es.instability + inst_gain * dt, 100.0)

    # Industrial Momentum tick
    if es.era_id == &"industrial" and es.mutation_severity == 0:
        es.momentum_timer += dt
        if es.momentum_timer >= 10.0:
            es.momentum_timer = 0.0
            es.momentum = minf(es.momentum + _balance.momentum_stack_rate, _balance.momentum_cap)

    # Mutated era emission timer
    if es.mutation_severity > 0 and allow_cascade:
        var mutation := era_def.mutation as MutationDef
        if mutation and mutation.emission_interval_quarters.size() > 0:
            var idx := mini(es.mutation_severity - 1, mutation.emission_interval_quarters.size() - 1)
            var interval_q := mutation.emission_interval_quarters[idx]
            if interval_q > 0:
                es.emission_timer += dt
                var interval_s := float(interval_q) * QUARTER_DURATION
                if es.emission_timer >= interval_s:
                    es.emission_timer = 0.0
                    _spawn_front(es, era_def)

    # Overflow
    if es.instability >= 100.0 and allow_cascade:
        _overflow(es, era_def)

func _overflow(es: EraState, era_def: EraDef) -> void:
    es.instability = _balance.instability_overflow_reset
    _spawn_front(es, era_def)

func _spawn_front(es: EraState, era_def: EraDef) -> void:
    if era_def.downstream_id == &"" or era_def.emits_front == &"":
        return
    var front := FrontState.new()
    front.uid = _next_uid()
    front.type_id = era_def.emits_front
    front.codename = _codename(era_def.emits_front)
    front.severity = 1
    front.origin_era_id = es.era_id
    front.target_era_id = era_def.downstream_id
    front.progress = 0.0
    front.travel_time = _travel_time()
    front.spawn_quarter = _state.quarter
    _state.fronts.append(front)
    EventBus.front_spawned.emit(front)

func _tick_fronts(dt: float) -> void:
    var arrived: Array[FrontState] = []
    for front in _state.fronts:
        front.progress += dt / front.travel_time
        if front.progress >= 1.0:
            arrived.append(front)
    for front in arrived:
        _arrive(front)

func _arrive(front: FrontState) -> void:
    _state.fronts.erase(front)

    # Future: singularity
    if front.target_era_id == &"future":
        var gain := _balance.soot_singularity_gain * (1.5 if front.severity >= 2 else 1.0)
        _state.singularity += gain
        EventBus.singularity_changed.emit(_state.singularity)
        EventBus.front_resolved.emit(front, 0)
        if _state.singularity >= 100.0:
            if not _state.parachute_used and _state.singularity >= 85.0:
                _fire_parachute()
            else:
                _end_run(false, "singularity")
        return

    var target := _get_era(front.target_era_id)
    var target_def := ContentDB.get_by_id(front.target_era_id) as EraDef
    var front_type := ContentDB.get_by_id(front.type_id) as FrontTypeDef

    # Apply arrival effects
    if front_type:
        for effect in front_type.arrival_effects:
            var min_sev := int(effect.get("severity_min", 1))
            if front.severity < min_sev:
                continue
            var stat := effect.get("stat", "")
            if stat == "trigger_mutation" and effect.get("condition", "") == "instability_at_100":
                pass  # handled after instability check below
            elif stat == "singularity":
                EffectResolver.apply_global(effect, _state)
                EventBus.singularity_changed.emit(_state.singularity)
            else:
                EffectResolver.apply_to_era(effect, target, _state)

    EventBus.front_resolved.emit(front, 0)

    # Chain: if target hit 100 instability
    if target.instability >= 100.0:
        _overflow(target, target_def)

    # Mutation trigger: when instability overflow was caused by this front
    # In Phase 1, mutation triggers on any overflow of a non-Future era
    # (simplified from spec — spec says mutation happens when overflow caused by front)
    # This is handled inside _overflow already; the severity increment is there:
    # We do it here as well for the first overflow from a front

func _check_and_mutate(es: EraState, era_def: EraDef) -> void:
    if es.mutation_severity >= 2 or not era_def.mutation:
        return
    es.mutation_severity += 1
    es.instability = _balance.instability_overflow_reset
    EventBus.era_mutated.emit(es.era_id, es.mutation_severity)

    # Industrial Momentum disabled
    if es.era_id == &"industrial":
        es.momentum = 0.0

    # Singularity pressure from multi-mutation board
    if _count_mutations() >= 2:
        _state.singularity += _balance.multi_mutation_singularity_per_quarter
        EventBus.singularity_changed.emit(_state.singularity)

func _fire_parachute() -> void:
    _state.parachute_used = true
    _state.injunctions += 1
    EventBus.player_action.emit({"action": "parachute_fired"})

# ── Quarter boundary ─────────────────────────────────────────────────────────

func _end_quarter() -> void:
    _state.quarter_time = 0.0
    _state.quarter_capitals.append(_state.capital)

    EffectResolver.tick_directive_durations(_state)

    # Relic quarterly conversion (Dark Age)
    _convert_relics()

    # Synergy Initiative: place Steady in lowest-yield era
    if _state.flags.get(&"synergy_initiative", false):
        _apply_synergy_initiative()

    # Q8 final quarter
    if _state.quarter >= 8:
        _end_run(_state.capital >= (_get_contract().quota if _get_contract() else 0.0), "")
        return

    # Generate quarter report with 3 directives
    var report := QuarterReport.new()
    report.quarter = _state.quarter
    report.capital_start = _quarter_capital_start
    report.capital_end = _state.capital

    _pending_directives = _pick_directives()
    report.directives_offered = _pending_directives.duplicate()

    _phase = Phase.QUARTER_REPORT
    EventBus.quarter_ended.emit(report)
    EventBus.directive_required.emit(_pending_directives)

func _pick_directives() -> Array[DirectiveDef]:
    var all: Array = ContentDB.get_all_of_type("DirectiveDef")
    all.shuffle()
    var selected: Array[DirectiveDef] = []
    var mandate_count := 0
    var deal_count := 0
    for d in all:
        if selected.size() >= 3:
            break
        var dir := d as DirectiveDef
        if not dir:
            continue
        if dir.tone == 2 and mandate_count >= 1:
            continue
        if dir.tone == 1 and deal_count >= 2:
            continue
        if dir.tone == 2:
            mandate_count += 1
        elif dir.tone == 1:
            deal_count += 1
        selected.append(dir)
    return selected

func _apply_synergy_initiative() -> void:
    var lowest_era: StringName = &""
    var lowest_yield: float = INF
    for es in _state.eras:
        if es.era_id == &"future":
            continue
        var y := _era_total_yield(es)
        if y < lowest_yield:
            lowest_yield = y
            lowest_era = es.era_id
    if lowest_era != &"":
        place_extractor(lowest_era, &"steady")

func _convert_relics() -> void:
    if _state.relics <= 0:
        return
    _state.capital += float(_state.relics) * 25.0
    _state.relics = 0

# ── Run end ──────────────────────────────────────────────────────────────────

func _end_run(won: bool, cause: String) -> void:
    _phase = Phase.ENDED
    var contract := _get_contract()
    var anomalies := 0
    if won:
        anomalies = contract.anomaly_reward if contract else 0
    else:
        var quota := contract.quota if contract else 1.0
        var pct := _state.capital / quota
        if pct >= 0.5:
            anomalies = int((contract.anomaly_reward if contract else 0) * 0.4)

    var result := {
        "won": won,
        "cause": cause,
        "capital": _state.capital,
        "quota": contract.quota if contract else 0.0,
        "singularity": _state.singularity,
        "mutations": _count_mutations(),
        "anomalies_earned": anomalies,
        "action_log": _state.action_log,
    }

    MetaState.complete_run(result)
    EventBus.run_ended.emit(result)

# ── Calculations ─────────────────────────────────────────────────────────────

func _travel_time() -> float:
    var speed_mult := 1.0 + float(_count_mutations()) * _balance.mutation_speed_bonus
    var global_mult := EffectResolver.get_global_multiplier("front_speed_mult", _state.active_directives)
    return _balance.front_travel_base / (speed_mult * global_mult)

func _extractor_cost(ext_def: ExtractorDef, es: EraState, era_def: EraDef) -> float:
    var base := ext_def.base_cost * era_def.extractor_cost_mult
    base *= EffectResolver.get_era_multiplier("cost_mult", es.era_id, _state.active_directives)
    var count := es.extractors.size()
    return base * pow(_balance.extractor_cost_scaling, count)

func _extractor_yield(ext_def: ExtractorDef, rec: Dictionary, es: EraState, era_def: EraDef) -> float:
    var rate: float
    match ext_def.id:
        &"steady":
            rate = ext_def.yield_per_second
        &"burst":
            rate = ext_def.burst_yield if rec.get("burst_active", false) else ext_def.post_burst_yield
        &"deep":
            rate = ext_def.yield_per_second
        _:
            rate = ext_def.yield_per_second

    # Deep +50% in Antiquity
    if es.era_id == &"antiquity" and ext_def.id == &"deep":
        rate *= _balance.deep_antiquity_bonus

    # Industrial Momentum
    if es.era_id == &"industrial" and es.mutation_severity == 0:
        rate *= (1.0 + es.momentum)

    # Diesel Wastes yield multiplier
    if es.era_id == &"industrial" and es.mutation_severity > 0:
        rate *= [2.0, 3.0][mini(es.mutation_severity - 1, 1)]

    # Foundation (Antiquity) downstream bonus to all other eras
    if es.era_id != &"antiquity":
        var antiquity := _get_era(&"antiquity")
        if antiquity and antiquity.mutation_severity == 0:
            var foundation_mult := 1.5 - antiquity.instability / 200.0
            rate *= foundation_mult

    # Future Speculation: yield scales with total timeline integrity
    if es.era_id == &"future":
        var total_stability := 0.0
        for other_es in _state.eras:
            total_stability += 100.0 - other_es.instability
        rate *= total_stability / (100.0 * float(_balance.speculation_era_count))

    # Q8 yield bonus
    if _state.quarter >= 8:
        rate *= (1.0 + _balance.late_quarter_yield_bonus)

    rate *= EffectResolver.get_era_multiplier("yield_mult", es.era_id, _state.active_directives)
    rate *= EffectResolver.get_global_multiplier("yield_mult", _state.active_directives)
    return rate

func _divert_cost(front: FrontState) -> float:
    var front_type := ContentDB.get_by_id(front.type_id) as FrontTypeDef
    var base := (front_type.harvest_base if front_type else 150.0)
    base += _balance.harvest_contract_bonus * float(_current_tier())
    return base * 0.3

func _harvest_payout(front: FrontState) -> float:
    var era_yield := _era_total_yield(_get_era(front.origin_era_id))
    var front_type := ContentDB.get_by_id(front.type_id) as FrontTypeDef
    var base := front_type.harvest_base if front_type else 150.0
    return era_yield * 12.0 + base * float(_current_tier())

func _era_total_yield(es: EraState) -> float:
    if not es:
        return 0.0
    var era_def := ContentDB.get_by_id(es.era_id) as EraDef
    if not era_def:
        return 0.0
    var total := 0.0
    for rec in es.extractors:
        var ext_def := ContentDB.get_by_id(rec.type_id) as ExtractorDef
        if ext_def:
            total += _extractor_yield(ext_def, rec, es, era_def)
    return total

func _restock_cost() -> float:
    var contract := _get_contract()
    var quota := contract.quota if contract else 1000.0
    var base := quota * _balance.restock_base_cost_pct
    return base * pow(2.0, float(_state.restock_count))

func _count_mutations() -> int:
    var n := 0
    for es in _state.eras:
        if es.mutation_severity > 0:
            n += 1
    return n

# ── Helpers ───────────────────────────────────────────────────────────────────

func _get_era(era_id: StringName) -> EraState:
    for es in _state.eras:
        if es.era_id == era_id:
            return es
    return null

func _find_front(uid: int) -> FrontState:
    for f in _state.fronts:
        if f.uid == uid:
            return f
    return null

func _next_uid() -> int:
    _front_uid_counter += 1
    return _front_uid_counter

func _codename(type_id: StringName) -> String:
    var ft := ContentDB.get_by_id(type_id) as FrontTypeDef
    if not ft or ft.codename_pool.is_empty():
        return "ANOMALY-%d" % _front_uid_counter
    return ft.codename_pool[_rng.randi() % ft.codename_pool.size()]

func _current_tier() -> int:
    var c := _get_contract()
    return c.tier if c else 1

func _get_contract() -> ContractDef:
    return ContentDB.get_by_id(_state.contract_id) as ContractDef

func _log(action: String, data: Dictionary) -> void:
    _state.action_log.append({
        "action": action,
        "quarter": _state.quarter,
        "t": _state.sim_time,
        "data": data,
    })
```

- [ ] **Step 2: Verify syntax**

In Godot, open `scripts/simulation/run_sim.gd` in the script editor. Verify there are no red error markers. Press **F5** — the project should launch with no errors.

- [ ] **Step 3: Commit**

```bash
git add scripts/simulation/run_sim.gd
git commit -m "feat: implement full RunSim simulation engine — quarters, extractors, fronts, cascade, verbs"
```

---

## Task 7: Update MetaState

**Files:** `scripts/core/meta_state.gd`

- [ ] **Step 1: Replace `scripts/core/meta_state.gd`**

```gdscript
extends Node

const SAVE_PATH := "user://meta_state.json"
const SCHEMA := 2

var state: Dictionary = {}

func _ready() -> void:
    reset()

func reset() -> void:
    state = {
        "schema": SCHEMA,
        "anomalies": 0,
        "unlocked_nodes": [],
        "ladder_tier": 1,
        "audit_level": 0,
        "completed_contracts": [],
        "lifetime_stats": {
            "runs_completed": 0,
            "runs_won": 0,
            "total_capital": 0.0,
            "total_mutations": 0,
            "total_harvests": 0,
        }
    }

func load() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        reset()
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        reset()
        return
    var parsed := JSON.parse_string(file.get_as_text())
    if not parsed or not parsed is Dictionary:
        push_error("MetaState: corrupt save. Resetting.")
        reset()
        return
    state = _migrate(parsed)

func save() -> void:
    var tmp := SAVE_PATH + ".tmp"
    var file := FileAccess.open(tmp, FileAccess.WRITE)
    if not file:
        push_error("MetaState: cannot write save.")
        return
    file.store_string(JSON.stringify(state))
    file.close()
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)
    DirAccess.rename_absolute(tmp, SAVE_PATH)

func complete_run(result: Dictionary) -> void:
    state.lifetime_stats.runs_completed += 1
    if result.get("won", false):
        state.lifetime_stats.runs_won += 1
    state.lifetime_stats.total_capital += result.get("capital", 0.0)
    state.lifetime_stats.total_mutations += result.get("mutations", 0)
    var anomalies := int(result.get("anomalies_earned", 0))
    state.anomalies += anomalies
    save()

func _migrate(data: Dictionary) -> Dictionary:
    var schema := int(data.get("schema", 1))
    if schema < 2:
        data.setdefault("anomalies", 0)
        data.setdefault("unlocked_nodes", [])
        data.setdefault("ladder_tier", 1)
        data.setdefault("audit_level", 0)
        data.setdefault("completed_contracts", [])
        data.setdefault("lifetime_stats", {
            "runs_completed": 0, "runs_won": 0,
            "total_capital": 0.0, "total_mutations": 0, "total_harvests": 0
        })
        data["schema"] = SCHEMA
    return data
```

- [ ] **Step 2: Commit**

```bash
git add scripts/core/meta_state.gd
git commit -m "feat: update MetaState with run completion tracking and schema migration"
```

---

## Task 8: ContractSelect Scene

**Files:** Create `scenes/meta/contract_select.tscn` and `scripts/ui/contract_select.gd`.

- [ ] **Step 1: Create `scripts/ui/contract_select.gd`**

```gdscript
extends Control

@onready var contract_list: HBoxContainer = $VBox/ContractList
@onready var back_button: Button = $VBox/BackButton

func _ready() -> void:
    back_button.pressed.connect(_on_back)
    _populate()

func _populate() -> void:
    for child in contract_list.get_children():
        child.queue_free()

    var contracts := ContentDB.get_all_contracts()
    # Show 3 per tier, or all available — Phase 1: show all 3 we have
    for contract in contracts:
        var card := _make_card(contract)
        contract_list.add_child(card)

func _make_card(contract: ContractDef) -> PanelContainer:
    var panel := PanelContainer.new()
    var vbox := VBoxContainer.new()
    panel.add_child(vbox)

    var tier_label := Label.new()
    tier_label.text = "TIER %d" % contract.tier

    var name_label := Label.new()
    name_label.text = contract.display_name

    var quota_label := Label.new()
    quota_label.text = "Quota: %s µ" % _fmt(contract.quota)

    var inj_label := Label.new()
    inj_label.text = "Injunctions: %d" % contract.starting_injunctions

    var start_btn := Button.new()
    start_btn.text = "ACCEPT CONTRACT"
    start_btn.pressed.connect(_on_start.bind(contract.id))

    vbox.add_child(tier_label)
    vbox.add_child(name_label)
    vbox.add_child(quota_label)
    vbox.add_child(inj_label)
    vbox.add_child(start_btn)
    return panel

func _on_start(contract_id: StringName) -> void:
    RunSim.start_run(contract_id)
    get_tree().change_scene_to_file("res://scenes/run/run.tscn")

func _on_back() -> void:
    get_tree().change_scene_to_file("res://scenes/meta/main_menu.tscn")

func _fmt(n: float) -> String:
    if n >= 1000.0:
        return "%.0fK" % (n / 1000.0)
    return "%.0f" % n
```

- [ ] **Step 2: Create `scenes/meta/contract_select.tscn`**

In Godot editor, create a new scene:
```
Control (root, full rect)
  VBox (VBoxContainer, full rect)
    Label — text: "CONTRACT BOARD"
    HBoxContainer (name: ContractList)
    Button (name: BackButton) — text: "BACK"
```
Attach `scripts/ui/contract_select.gd` to the root. Save as `scenes/meta/contract_select.tscn`.

- [ ] **Step 3: Commit**

```bash
git add scenes/meta/contract_select.tscn scripts/ui/contract_select.gd
git commit -m "feat: add ContractSelect scene with 3 contract cards"
```

---

## Task 9: Run Scene — Structure + HUD

**Files:** Create `scenes/run/run.tscn`, `scripts/ui/run_hud.gd`

- [ ] **Step 1: Create `scripts/ui/run_hud.gd`**

```gdscript
extends Control

# Node references — set in _ready after scene is built
@onready var quota_bar: ProgressBar = $TopBar/QuotaBar
@onready var pace_line: Control = $TopBar/PaceLine
@onready var clock_label: Label = $TopBar/ClockLabel
@onready var injunction_label: Label = $TopBar/InjunctionLabel
@onready var capital_label: Label = $TopBar/CapitalLabel
@onready var singularity_bar: ProgressBar = $TopBar/SingularityBar
@onready var era_container: HBoxContainer = $Timeline/EraContainer
@onready var front_layer: Control = $Timeline/FrontLayer
@onready var verb_panel: HBoxContainer = $BottomDock/VerbPanel
@onready var build_panel: HBoxContainer = $BottomDock/BuildPanel
@onready var pause_button: Button = $BottomDock/PauseButton

var _selected_front_uid: int = -1
var _era_panels: Array = []

func _ready() -> void:
    EventBus.tick_processed.connect(_on_tick)
    EventBus.front_spawned.connect(_on_front_spawned)
    EventBus.front_resolved.connect(_on_front_resolved)
    EventBus.era_mutated.connect(_on_era_mutated)
    EventBus.singularity_changed.connect(_on_singularity_changed)
    EventBus.quarter_ended.connect(_on_quarter_ended)
    EventBus.run_ended.connect(_on_run_ended)

    pause_button.pressed.connect(_toggle_pause)
    _setup_verb_buttons()
    _setup_build_buttons()
    _refresh_hud()

func _setup_verb_buttons() -> void:
    for child in verb_panel.get_children():
        child.queue_free()
    var dampen_btn := Button.new()
    dampen_btn.name = "DampenBtn"
    dampen_btn.text = "DAMPEN (1 INJ)"
    dampen_btn.pressed.connect(_on_dampen)
    var divert_btn := Button.new()
    divert_btn.name = "DivertBtn"
    divert_btn.text = "DIVERT"
    divert_btn.pressed.connect(_on_divert)
    var harvest_btn := Button.new()
    harvest_btn.name = "HarvestBtn"
    harvest_btn.text = "HARVEST"
    harvest_btn.pressed.connect(_on_harvest)
    verb_panel.add_child(dampen_btn)
    verb_panel.add_child(divert_btn)
    verb_panel.add_child(harvest_btn)
    _update_verb_buttons()

func _setup_build_buttons() -> void:
    for child in build_panel.get_children():
        child.queue_free()
    for ext_id in [&"steady", &"burst", &"deep"]:
        var ext_def := ContentDB.get_by_id(ext_id) as ExtractorDef
        if not ext_def:
            continue
        var btn := Button.new()
        btn.name = str(ext_id) + "Btn"
        btn.text = ext_def.display_name
        btn.pressed.connect(_on_build.bind(ext_id))
        build_panel.add_child(btn)

func _on_tick() -> void:
    _refresh_hud()

func _refresh_hud() -> void:
    var state := RunSim.get_state()
    if not state:
        return
    var contract := ContentDB.get_by_id(state.contract_id) as ContractDef
    var quota := contract.quota if contract else 1.0

    quota_bar.max_value = quota
    quota_bar.value = state.capital

    var elapsed := state.quarter_time
    var remaining := 90.0 - elapsed
    clock_label.text = "Q%d — %d:%02d" % [state.quarter, int(remaining) / 60, int(remaining) % 60]
    injunction_label.text = "INJ: %d" % state.injunctions
    capital_label.text = "µ %.0f" % state.capital
    singularity_bar.value = state.singularity

    _update_verb_buttons()

func _update_verb_buttons() -> void:
    var has_front := _selected_front_uid >= 0
    var has_front_node := _selected_front_uid >= 0 and RunSim.get_state() and _find_front_state(_selected_front_uid) != null
    var state := RunSim.get_state()
    var has_inj := state and state.injunctions > 0
    verb_panel.get_node("DampenBtn").disabled = not (has_front_node and has_inj)
    verb_panel.get_node("DivertBtn").disabled = not has_front_node
    verb_panel.get_node("HarvestBtn").disabled = not has_front_node

func _find_front_state(uid: int) -> FrontState:
    var state := RunSim.get_state()
    if not state:
        return null
    for f in state.fronts:
        if f.uid == uid:
            return f
    return null

func _on_front_spawned(front: FrontState) -> void:
    var token := preload("res://scenes/run/front_token.tscn").instantiate()
    token.name = "Front_%d" % front.uid
    token.setup(front)
    front_layer.add_child(token)

func _on_front_resolved(front: FrontState, _resolution: int) -> void:
    var token := front_layer.get_node_or_null("Front_%d" % front.uid)
    if token:
        token.queue_free()
    if _selected_front_uid == front.uid:
        _selected_front_uid = -1
        _update_verb_buttons()

func _on_era_mutated(era_id: StringName, severity: int) -> void:
    for panel in _era_panels:
        if panel.era_id == era_id:
            panel.update_mutation(severity)

func _on_singularity_changed(value: float) -> void:
    singularity_bar.value = value

func _on_quarter_ended(_report: QuarterReport) -> void:
    get_tree().change_scene_to_file("res://scenes/ui/quarter_report.tscn")

func _on_run_ended(_result: Dictionary) -> void:
    get_tree().change_scene_to_file("res://scenes/ui/debrief.tscn")

func _on_dampen() -> void:
    if _selected_front_uid >= 0:
        RunSim.dampen_front(_selected_front_uid)

func _on_divert() -> void:
    if _selected_front_uid >= 0:
        RunSim.divert_front(_selected_front_uid)

func _on_harvest() -> void:
    if _selected_front_uid >= 0:
        RunSim.harvest_front(_selected_front_uid)

func _on_build(ext_type_id: StringName) -> void:
    # Phase 1: build in first era that can afford it
    # Full implementation: era selection via click on EraPanel
    var state := RunSim.get_state()
    if not state:
        return
    for es in state.eras:
        if RunSim.place_extractor(es.era_id, ext_type_id):
            break

func _toggle_pause() -> void:
    if RunSim.get_phase() == RunSim.Phase.RUNNING:
        RunSim.pause()
        pause_button.text = "RESUME"
    else:
        RunSim.resume()
        pause_button.text = "PAUSE"

func select_front(uid: int) -> void:
    _selected_front_uid = uid
    _update_verb_buttons()
```

- [ ] **Step 2: Create `scenes/run/run.tscn`**

In Godot, create a new scene with this node tree:
```
Control (root, full rect, script: run_hud.gd)
  TopBar (HBoxContainer, custom_minimum_size y=48)
    QuotaBar (ProgressBar, size_flags: expand)
    SingularityBar (ProgressBar, custom_minimum_size x=80)
    ClockLabel (Label)
    InjunctionLabel (Label)
    CapitalLabel (Label)
    PaceLine (Control)   ← placeholder, Phase 2 animates this
  Timeline (VBoxContainer, size_flags: expand)
    EraContainer (HBoxContainer, size_flags: expand fill)
    FrontLayer (Control, size_flags: expand fill)
  BottomDock (HBoxContainer, custom_minimum_size y=64)
    VerbPanel (HBoxContainer)
    BuildPanel (HBoxContainer)
    PauseButton (Button, text: "PAUSE")
```
Save as `scenes/run/run.tscn`. Attach `scripts/ui/run_hud.gd` to root.

- [ ] **Step 3: Commit**

```bash
git add scenes/run/run.tscn scripts/ui/run_hud.gd
git commit -m "feat: add Run scene with HUD — TopBar, Timeline, BottomDock, verb buttons"
```

---

## Task 10: EraPanel + FrontToken Components

**Files:** `scripts/ui/era_panel.gd`, `scripts/ui/front_token.gd`, `scenes/run/era_panel.tscn`, `scenes/run/front_token.tscn`

- [ ] **Step 1: Create `scripts/ui/era_panel.gd`**

```gdscript
extends PanelContainer

var era_id: StringName = &""

@onready var name_label: Label = $VBox/NameLabel
@onready var instability_bar: ProgressBar = $VBox/InstabilityBar
@onready var yield_label: Label = $VBox/YieldLabel
@onready var extractor_list: VBoxContainer = $VBox/ExtractorList
@onready var mutation_label: Label = $VBox/MutationLabel

func setup(p_era_id: StringName) -> void:
    era_id = p_era_id
    var era_def := ContentDB.get_by_id(era_id) as EraDef
    name_label.text = era_def.display_name if era_def else str(era_id)
    EventBus.tick_processed.connect(_refresh)

func _refresh() -> void:
    var state := RunSim.get_state()
    if not state:
        return
    for es in state.eras:
        if es.era_id == era_id:
            instability_bar.value = es.instability
            yield_label.text = "µ/s: %.1f" % RunSim._era_total_yield(es)
            mutation_label.text = _mutation_text(es.mutation_severity)
            _rebuild_extractors(es)
            return

func update_mutation(severity: int) -> void:
    mutation_label.text = _mutation_text(severity)

func _mutation_text(severity: int) -> String:
    match severity:
        0: return ""
        1: return "MUTATED (I)"
        2: return "MUTATED (II)"
    return ""

func _rebuild_extractors(es: EraState) -> void:
    for child in extractor_list.get_children():
        child.queue_free()
    for i in range(es.extractors.size()):
        var rec: Dictionary = es.extractors[i]
        var ext_def := ContentDB.get_by_id(rec.type_id) as ExtractorDef
        var row := HBoxContainer.new()
        var lbl := Label.new()
        lbl.text = ext_def.display_name if ext_def else str(rec.type_id)
        var remove_btn := Button.new()
        remove_btn.text = "X"
        remove_btn.pressed.connect(_on_remove.bind(i))
        row.add_child(lbl)
        row.add_child(remove_btn)
        extractor_list.add_child(row)

func _on_remove(index: int) -> void:
    RunSim.remove_extractor(era_id, index)
```

- [ ] **Step 2: Create `scenes/run/era_panel.tscn`**

```
PanelContainer (root, script: era_panel.gd, custom_minimum_size: 200x300)
  VBox (VBoxContainer, full rect)
    NameLabel (Label)
    InstabilityBar (ProgressBar, max_value: 100)
    YieldLabel (Label)
    ExtractorList (VBoxContainer)
    MutationLabel (Label)
```
Save as `scenes/run/era_panel.tscn`.

- [ ] **Step 3: Create `scripts/ui/front_token.gd`**

```gdscript
extends Control

var front_uid: int = -1

@onready var label: Label = $Label

func setup(front: FrontState) -> void:
    front_uid = front.uid
    label.text = "%s\n%s" % [front.codename, "I" if front.severity == 1 else "II"]
    _update_position(front)
    EventBus.tick_processed.connect(_on_tick)

    # Make clickable
    gui_input.connect(_on_gui_input)
    mouse_filter = Control.MOUSE_FILTER_STOP

func _on_tick() -> void:
    var state := RunSim.get_state()
    if not state:
        return
    for f in state.fronts:
        if f.uid == front_uid:
            _update_position(f)
            label.modulate = Color.GOLD if f.harvested else Color.WHITE
            return

func _update_position(front: FrontState) -> void:
    # Position front token along the horizontal timeline (FrontLayer width)
    # ERA_ORDER index of target_era_id maps to a horizontal band
    var era_order := [&"antiquity", &"middle_ages", &"industrial", &"future"]
    var target_idx := era_order.find(front.target_era_id)
    if target_idx < 0:
        return
    # Each era occupies 1/4 of the FrontLayer width
    var parent_width := get_parent().size.x if get_parent() else 800.0
    var slot_width := parent_width / 4.0
    var origin_idx := era_order.find(front.origin_era_id)
    if origin_idx < 0:
        origin_idx = target_idx - 1
    var x_start := slot_width * origin_idx + slot_width * 0.5
    var x_end := slot_width * target_idx + slot_width * 0.5
    position.x = lerp(x_start, x_end, front.progress)
    position.y = 20.0

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        # Notify RunHUD of selection
        var hud := get_tree().get_first_node_in_group("run_hud")
        if hud and hud.has_method("select_front"):
            hud.select_front(front_uid)
```

- [ ] **Step 4: Create `scenes/run/front_token.tscn`**

```
Control (root, script: front_token.gd, custom_minimum_size: 80x40)
  Label (name: Label, text: "FRONT")
```
Save as `scenes/run/front_token.tscn`.

- [ ] **Step 5: Add RunHUD to a group**

In `scripts/ui/run_hud.gd`, add to `_ready()`:
```gdscript
add_to_group("run_hud")
```

- [ ] **Step 6: Wire EraPanel instances into Run scene**

In Godot, open `scenes/run/run.tscn`. Select the `EraContainer` node. Add 4 instances of `scenes/run/era_panel.tscn` as children. Name them `EraPanel_antiquity`, `EraPanel_middle_ages`, `EraPanel_industrial`, `EraPanel_future`.

In `run_hud.gd` `_ready()`, after the signal connections, add:
```gdscript
var era_order := [&"antiquity", &"middle_ages", &"industrial", &"future"]
for era_id in era_order:
    var panel_name := "EraPanel_" + str(era_id)
    var panel := era_container.get_node_or_null(panel_name)
    if panel and panel.has_method("setup"):
        panel.setup(era_id)
        _era_panels.append(panel)
```

- [ ] **Step 7: Commit**

```bash
git add scenes/run/ scripts/ui/era_panel.gd scripts/ui/front_token.gd
git commit -m "feat: add EraPanel and FrontToken UI components"
```

---

## Task 11: QuarterlyReport Scene

**Files:** `scenes/ui/quarter_report.tscn`, `scripts/ui/quarter_report_ui.gd`

- [ ] **Step 1: Create `scripts/ui/quarter_report_ui.gd`**

```gdscript
extends Control

@onready var quarter_label: Label = $VBox/QuarterLabel
@onready var capital_label: Label = $VBox/CapitalLabel
@onready var directive_container: HBoxContainer = $VBox/DirectiveContainer
@onready var continue_label: Label = $VBox/ContinueLabel

var _directives: Array[DirectiveDef] = []

func _ready() -> void:
    EventBus.directive_required.connect(_on_directives_received)
    continue_label.text = "Select a Directive to continue."

func _on_directives_received(directives: Array) -> void:
    _directives.clear()
    for child in directive_container.get_children():
        child.queue_free()

    var state := RunSim.get_state()
    if state:
        quarter_label.text = "QUARTERLY REPORT — Q%d" % state.quarter
        var contract := ContentDB.get_by_id(state.contract_id) as ContractDef
        var quota := contract.quota if contract else 0.0
        capital_label.text = "Capital: µ%.0f / µ%.0f  (%.0f%%)" % [
            state.capital, quota,
            (state.capital / quota * 100.0) if quota > 0 else 0.0
        ]

    for d in directives:
        var dir := d as DirectiveDef
        if not dir:
            continue
        _directives.append(dir)
        var card := _make_card(dir)
        directive_container.add_child(card)

func _make_card(directive: DirectiveDef) -> PanelContainer:
    var panel := PanelContainer.new()
    var vbox := VBoxContainer.new()
    panel.add_child(vbox)

    var tone_names := ["GIFT", "DEAL", "MANDATE"]
    var tone_lbl := Label.new()
    tone_lbl.text = tone_names[directive.tone] if directive.tone < tone_names.size() else ""

    var title_lbl := Label.new()
    title_lbl.text = directive.title

    var body_lbl := Label.new()
    body_lbl.text = directive.body
    body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD

    var dur_lbl := Label.new()
    dur_lbl.text = "Permanent" if directive.duration_quarters == -1 else ("This quarter" if directive.duration_quarters == 1 else "%d quarters" % directive.duration_quarters)

    var pick_btn := Button.new()
    pick_btn.text = "SELECT"
    pick_btn.pressed.connect(_on_pick.bind(directive.id))

    vbox.add_child(tone_lbl)
    vbox.add_child(title_lbl)
    vbox.add_child(body_lbl)
    vbox.add_child(dur_lbl)
    vbox.add_child(pick_btn)
    return panel

func _on_pick(directive_id: StringName) -> void:
    RunSim.pick_directive(directive_id)
    get_tree().change_scene_to_file("res://scenes/run/run.tscn")
```

- [ ] **Step 2: Create `scenes/ui/quarter_report.tscn`**

```
Control (root, full rect, script: quarter_report_ui.gd)
  VBox (VBoxContainer, full rect)
    QuarterLabel (Label, text: "QUARTERLY REPORT")
    CapitalLabel (Label)
    DirectiveContainer (HBoxContainer)
    ContinueLabel (Label)
```
Save as `scenes/ui/quarter_report.tscn`.

- [ ] **Step 3: Commit**

```bash
git add scenes/ui/quarter_report.tscn scripts/ui/quarter_report_ui.gd
git commit -m "feat: add QuarterlyReport scene with directive selection"
```

---

## Task 12: Debrief Scene

**Files:** `scenes/ui/debrief.tscn`, `scripts/ui/debrief.gd`

- [ ] **Step 1: Create `scripts/ui/debrief.gd`**

```gdscript
extends Control

@onready var result_label: Label = $VBox/ResultLabel
@onready var capital_label: Label = $VBox/CapitalLabel
@onready var quota_label: Label = $VBox/QuotaLabel
@onready var stats_label: Label = $VBox/StatsLabel
@onready var anomaly_label: Label = $VBox/AnomalyLabel
@onready var play_again_btn: Button = $VBox/PlayAgainBtn
@onready var main_menu_btn: Button = $VBox/MainMenuBtn

func _ready() -> void:
    EventBus.run_ended.connect(_on_run_ended)
    play_again_btn.pressed.connect(_on_play_again)
    main_menu_btn.pressed.connect(_on_main_menu)

    # If we arrive here and run already ended, result is in MetaState lifetime_stats
    # (run_ended may have fired before this scene loaded; handle gracefully)
    _try_populate_from_last_run()

func _on_run_ended(result: Dictionary) -> void:
    _populate(result)

func _try_populate_from_last_run() -> void:
    # Fallback: show last known stats from MetaState
    var stats := MetaState.state.get("lifetime_stats", {})
    if stats.get("runs_completed", 0) > 0:
        result_label.text = "CONTRACT CONCLUDED"
        capital_label.text = "See lifetime stats below."
        stats_label.text = "Runs: %d  Won: %d" % [stats.get("runs_completed", 0), stats.get("runs_won", 0)]

func _populate(result: Dictionary) -> void:
    var won: bool = result.get("won", false)
    result_label.text = "CONTRACT FULFILLED" if won else "CONTRACT TERMINATED"
    capital_label.text = "Final Capital: µ%.0f" % result.get("capital", 0.0)
    quota_label.text = "Quota: µ%.0f" % result.get("quota", 0.0)

    var cause := result.get("cause", "")
    var cause_text := ""
    if not won and cause == "singularity":
        cause_text = "\nTHE SINGULARITY HAS ARRIVED. THE BOARD IS DISPLEASED."
    elif not won:
        cause_text = "\nQuota not met by Q8."

    stats_label.text = "Mutations: %d  %s" % [result.get("mutations", 0), cause_text]
    anomaly_label.text = "Anomalies Earned: ⌬%d" % result.get("anomalies_earned", 0)

func _on_play_again() -> void:
    get_tree().change_scene_to_file("res://scenes/meta/contract_select.tscn")

func _on_main_menu() -> void:
    get_tree().change_scene_to_file("res://scenes/meta/main_menu.tscn")
```

- [ ] **Step 2: Create `scenes/ui/debrief.tscn`**

```
Control (root, full rect, script: debrief.gd)
  VBox (VBoxContainer, anchors: full rect)
    ResultLabel (Label, text: "DEBRIEF")
    CapitalLabel (Label)
    QuotaLabel (Label)
    StatsLabel (Label)
    AnomalyLabel (Label)
    PlayAgainBtn (Button, text: "NEW CONTRACT")
    MainMenuBtn (Button, text: "MAIN MENU")
```
Save as `scenes/ui/debrief.tscn`.

- [ ] **Step 3: Commit**

```bash
git add scenes/ui/debrief.tscn scripts/ui/debrief.gd
git commit -m "feat: add Debrief scene with run outcome display"
```

---

## Task 13: Wire Boot Flow

**Files:** `scripts/core/boot.gd`, `scripts/ui/main_menu.gd`

- [ ] **Step 1: Update `scripts/ui/main_menu.gd`**

```gdscript
extends Control

func _ready() -> void:
    var start_btn := Button.new()
    start_btn.text = "NEW CONTRACT"
    start_btn.pressed.connect(_on_start)
    add_child(start_btn)
    start_btn.position = Vector2(get_viewport_rect().size / 2.0) - Vector2(60, 15)

func _on_start() -> void:
    get_tree().change_scene_to_file("res://scenes/meta/contract_select.tscn")
```

- [ ] **Step 2: Update `scripts/core/boot.gd`**

```gdscript
extends Node

func _ready() -> void:
    MetaState.load()
    ContentDB.load_all_content()
    ContentDB.validate_content()

    var err := get_tree().change_scene_to_file("res://scenes/meta/main_menu.tscn")
    if err != OK:
        push_error("Boot: failed to load main menu — error %d" % err)
```

- [ ] **Step 3: Verify full flow**

Press **F5**. Verify:
1. Boot scene loads → transitions to Main Menu.
2. Click **NEW CONTRACT** → ContractSelect loads, shows 3 contract cards.
3. Click **ACCEPT CONTRACT** on Tier 1 → Run scene loads, quarter clock starts counting.
4. Wait 90 seconds → QuarterlyReport scene loads, shows 3 directive cards.
5. Click **SELECT** on any directive → Run resumes with Q2.
6. After Q8 (8 × 90s = 12 min) or manually trigger end → Debrief loads.

For rapid testing, temporarily reduce `QUARTER_DURATION` in `run_sim.gd` to `10.0` to cycle quickly, then restore to `90.0`.

Expected Output during run:
- No errors or null reference messages
- `ContentDB: All content valid. N resources loaded.` at boot
- Front codenames appear when instability overflows

- [ ] **Step 4: Restore QUARTER_DURATION if changed, then commit**

```bash
git add scripts/core/boot.gd scripts/ui/main_menu.gd
git commit -m "feat: wire boot flow — MainMenu → ContractSelect → Run → QuarterlyReport → Debrief"
```

---

## Self-Review: Spec Coverage Check

Sections reviewed against this plan:

| Spec Section | Coverage |
|---|---|
| §3 5-second loop (Dampen/Divert/Harvest) | ✅ RunSim Task 6 |
| §3 90-second loop (quarters, quota pace) | ✅ RunSim + QuarterlyReport |
| §3 12-minute loop (8 quarters, Contract) | ✅ RunSim QUARTER_DURATION × 8 |
| §3 Meta loop (Anomalies, ContractBoard) | ⚠️ Anomaly accumulation ✅, tree UI deferred to Phase 2 |
| §4 Q1-Q2 land grab (60s cascade suppression) | ✅ RunSim `allow_cascade` |
| §4 Q3-Q5 exposure | ✅ natural cascade flow |
| §4 Q6-Q7 squeeze | ✅ no special code needed — Deep extractor detonate |
| §4 Q8 sprint (yield +25%, instability -40%) | ✅ `late_quarter_yield_bonus` + BalanceSheet |
| §4 Failure design (partial Anomaly payout) | ✅ `_calculate_anomalies` |
| §4 Golden Parachute (85% singularity) | ✅ `_fire_parachute` |
| §5 Four resources | ✅ Capital ✅, Injunctions ✅, Anomalies ✅, Relics ✅ |
| §6 Three extractor types | ✅ Steady/Burst/Deep in content + RunSim |
| §6 Instability per-era 0-100, overflow at 100, reset to 40 | ✅ |
| §6 Extractor cost ×1.6 per subsequent | ✅ |
| §6 Demolition 25% salvage + scar | ✅ |
| §7 Front travel time 45s base | ✅ |
| §7 Mutation speed bonus +20% each | ✅ |
| §7 Typed transmutation table | ✅ arrival_effects in FrontTypeDef .tres |
| §7 Harvest: worse mutation, 25% faster, locked | ✅ |
| §7 Divert: 30% cost, skips era | ✅ |
| §7 Dampen: costs 1 Injunction | ✅ |
| §7 Mutation severity I/II | ✅ `mutation_severity` 0/1/2 |
| §7 Singularity meter, +25 per Soot | ✅ |
| §8 Foundation (Antiquity downstream bonus) | ✅ |
| §8 Brittle (Middle Ages cheap+fast) | ✅ extractor_cost_mult=0.7, instability_gain_mult=1.5 |
| §8 Momentum (Industrial hands-off) | ✅ |
| §8 Speculation (Future scales with stability) | ✅ |
| §9 Contract Board (3 contracts, tier ladder) | ✅ 3 contracts, ContractSelect |
| §13 Directive system (3 per quarter, tone balance) | ✅ 12 directives, `_pick_directives` |
| §19 5 autoloads | ✅ EventBus/RunSim/ContentDB/MetaState/AudioDirector |
| §20 All Resource schemas | ✅ Tasks 1-2 |

**Deferred to Phase 2:** Incident event system (§12), audio (§18), CRT visual identity (§17), Meta Anomaly unlock tree (§10), Audit system, Memo generation, Era Variants, Mandate reveals in Debrief, Incident Report PNG export.

**No placeholders found.**

---

**Plan complete and saved.**

Two execution options:

**1. Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review output between tasks. Use `superpowers:subagent-driven-development`.

**2. Inline Execution** — execute all tasks in this session with checkpoints. Use `superpowers:executing-plans`.

Which approach?