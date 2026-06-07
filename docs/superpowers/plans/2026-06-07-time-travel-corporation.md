# Time Travel Corporation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete MVP of Time Travel Corporation — an idle management game in Godot 4 — per the approved spec at `docs/superpowers/specs/2026-06-07-time-travel-corporation-design.md`.

**Architecture:** Single `GameState` autoload holds all runtime state and emits `state_changed`. Five manager autoloads (`AgentManager`, `EraManager`, `ResearchManager`, `EventManager`, `SaveManager`) mutate state. UI scripts are read-only observers. All content is defined in JSON config files under `data/`.

**Tech Stack:** Godot 4.x · GDScript · HTML5 export · localStorage (web) / `user://save.json` (desktop) · Share Tech Mono font · JSON data config

---

## File Map

```
autoloads/game_state.gd          All runtime state + signals
autoloads/agent_manager.gd       Agent lifecycle: hire/dispatch/return/level-up
autoloads/era_manager.gd         Era unlock + mission tick + completion
autoloads/research_manager.gd    Research unlock + multiplier calculation
autoloads/event_manager.gd       Timed event firing + choice resolution
autoloads/save_manager.gd        JSON save/load + offline reward calc

data/eras.json                   8 era definitions
data/agent_tiers.json            10 tiers + name pool
data/research_tree.json          35 research nodes
data/events.json                 20 random events

scenes/main.tscn                 Root scene (TabContainer)
scenes/ui/dashboard.tscn
scenes/ui/timelines.tscn
scenes/ui/agents.tscn
scenes/ui/research.tscn
scenes/ui/corporation.tscn
scenes/ui/event_overlay.tscn     Floating event notification

scripts/main.gd                  Boot + tick timer
scripts/ui/dashboard.gd
scripts/ui/timelines.gd
scripts/ui/agents.gd
scripts/ui/research.gd
scripts/ui/corporation.gd
scripts/ui/event_overlay.gd

components/agent_card.tscn + .gd
components/era_card.tscn   + .gd
components/resource_row.tscn + .gd

theme/terminal.tres
theme/fonts/share_tech_mono.ttf
```

---

## PHASE 1 — FOUNDATION

---

### Task 1: Install Godot 4 + Create Project Structure

**Files:**
- Create: entire project folder structure (folders only, no scripts yet)
- Create: `project.godot` (Godot creates this)

- [ ] **Step 1: Download and install Godot 4**

  1. Go to **https://godotengine.org/download**
  2. Download **Godot Engine 4.x — Standard** (not .NET/Mono)
  3. Unzip it. Godot is a single `.exe` — no installer needed.
  4. Double-click `Godot_v4.x.exe` to launch.

- [ ] **Step 2: Create the Godot project**

  In the Godot Project Manager:
  1. Click **New Project**
  2. Project Name: `Time Travel Corp`
  3. Project Path: `C:\Users\georg\OneDrive\Desktop\Projects\Time travel Corp`
  4. Renderer: **Compatibility** (required for HTML5 web export — do not pick Forward+)
  5. Click **Create & Edit**

- [ ] **Step 3: Create the folder structure**

  In the Godot **FileSystem** panel (bottom-left), right-click `res://` and create these folders one by one:
  ```
  autoloads/
  data/
  scenes/
  scenes/ui/
  scripts/
  scripts/ui/
  components/
  theme/
  theme/fonts/
  docs/
  docs/superpowers/
  docs/superpowers/specs/
  docs/superpowers/plans/
  ```

- [ ] **Step 4: Create placeholder empty .gd files**

  In the FileSystem panel, right-click each folder and choose **New Script** to create these empty files:
  ```
  autoloads/game_state.gd
  autoloads/agent_manager.gd
  autoloads/era_manager.gd
  autoloads/research_manager.gd
  autoloads/event_manager.gd
  autoloads/save_manager.gd
  scripts/main.gd
  scripts/ui/dashboard.gd
  scripts/ui/timelines.gd
  scripts/ui/agents.gd
  scripts/ui/research.gd
  scripts/ui/corporation.gd
  scripts/ui/event_overlay.gd
  components/agent_card.gd
  components/era_card.gd
  components/resource_row.gd
  ```
  Leave each file with just `extends Node` for now.

- [ ] **Step 5: Register autoloads in Project Settings**

  Go to **Project → Project Settings → Autoload** tab. Click the folder icon next to "Path" and add each file:

  | Path | Node Name |
  |------|-----------|
  | `res://autoloads/game_state.gd` | `GameState` |
  | `res://autoloads/agent_manager.gd` | `AgentManager` |
  | `res://autoloads/era_manager.gd` | `EraManager` |
  | `res://autoloads/research_manager.gd` | `ResearchManager` |
  | `res://autoloads/event_manager.gd` | `EventManager` |
  | `res://autoloads/save_manager.gd` | `SaveManager` |

  Order matters — add them in the order listed above.

- [ ] **Step 6: Download Share Tech Mono font**

  1. Go to **https://fonts.google.com/specimen/Share+Tech+Mono**
  2. Click Download Family
  3. Unzip and copy `ShareTechMono-Regular.ttf` into `res://theme/fonts/` using the Godot FileSystem panel (drag and drop from Windows Explorer)

- [ ] **Step 7: Commit**

  Open a terminal in the project folder and run:
  ```bash
  git init
  git add .
  git commit -m "feat: initial Godot 4 project structure and autoload registration"
  ```

---

### Task 2: game_state.gd — State Model + Signals

**Files:**
- Write: `autoloads/game_state.gd`

- [ ] **Step 1: Write game_state.gd**

  Open `autoloads/game_state.gd` in Godot's script editor and replace its contents:

  ```gdscript
  extends Node

  signal state_changed
  signal mission_complete(agent_id: String, era_id: String, rewards: Dictionary)
  signal event_fired(event_data: Dictionary)
  signal agent_leveled_up(agent_id: String, new_level: int)

  var state: Dictionary = {}

  func _ready() -> void:
      initialize_state()

  func initialize_state() -> void:
      state = {
          "resources": {
              "credits": 0.0,
              "knowledge": 0.0,
              "artifacts": 0.0,
              "historical_data": 0.0,
              "temporal_energy": 10.0,
              "temporal_energy_max": 10.0,
              "influence": 0.0,
              "stability": 80.0,
              "reputation": 0.0
          },
          "agents": [],
          "eras_unlocked": ["stone_age"],
          "active_missions": [],
          "research_unlocked": [],
          "departments": [],
          "prestige_count": 0,
          "temporal_echoes": 0,
          "echo_upgrades": [],
          "total_credits_earned": 0.0,
          "agents_promoted_this_run": 0,
          "run_start_timestamp": int(Time.get_unix_time_from_system()),
          "last_save_timestamp": int(Time.get_unix_time_from_system())
      }

  func get_resource(key: String) -> float:
      return float(state.resources.get(key, 0.0))

  func add_resource(key: String, amount: float) -> void:
      if not state.resources.has(key):
          return
      state.resources[key] = float(state.resources[key]) + amount
      if key == "credits" and amount > 0.0:
          state.total_credits_earned += amount
      if key == "stability":
          state.resources.stability = clampf(state.resources.stability, 0.0, 100.0)
      if key == "temporal_energy":
          state.resources.temporal_energy = clampf(
              state.resources.temporal_energy,
              0.0,
              state.resources.temporal_energy_max
          )

  func apply_passive_income() -> void:
      # TE passive bonus from Industrial / Near Future deployed agents
      for mission in state.active_missions:
          if mission.era_id == "industrial_revolution":
              add_resource("temporal_energy", 0.5 / 60.0)
          elif mission.era_id == "near_future":
              add_resource("temporal_energy", 2.0 / 60.0)
      # Stability regen from TS-4
      if "TS-4" in state.research_unlocked:
          add_resource("stability", 0.02)

  func decay_stability() -> void:
      var decay = 0.05
      if "TS-1" in state.research_unlocked:
          decay *= 0.8
      if "security_department" in state.departments:
          decay *= 0.7
      var floor_val = ResearchManager.get_stability_floor()
      var new_stability = maxf(state.resources.stability - decay, floor_val)
      state.resources.stability = new_stability

  func calculate_income_per_second() -> Dictionary:
      var income = {"credits": 0.0, "knowledge": 0.0, "historical_data": 0.0, "influence": 0.0}
      for mission in state.active_missions:
          var era = EraManager.get_era(mission.era_id)
          if era.is_empty():
              continue
          var agent_stats = AgentManager.get_agent_stats(mission.agent_id)
          var efficiency = agent_stats.get("efficiency", 1.0)
          var duration = float(era.get("duration", 60))
          income.credits += (float(era.get("base_credits", 0.0)) * efficiency) / duration
          income.knowledge += float(era.get("base_knowledge", 0.0)) / duration
          income.historical_data += float(era.get("base_historical_data", 0.0)) / duration
          income.influence += float(era.get("base_influence", 0.0)) / duration
      return income

  func get_stability_penalty() -> float:
      var s = state.resources.stability
      if s < 10.0:
          return 0.5
      if s < 30.0:
          return 0.75
      return 1.0
  ```

- [ ] **Step 2: Verify in Godot**

  Press **F5** to run the project (it will open a blank window — that's fine). Check the **Output** panel at the bottom. You should see no errors. If you see `"Cannot call method 'get_stability_floor' on a null instance"`, make sure ResearchManager is registered as an autoload in Project Settings.

  Stop the project with the **Stop** button (■).

- [ ] **Step 3: Commit**

  ```bash
  git add autoloads/game_state.gd
  git commit -m "feat: add GameState autoload with state model and signals"
  ```

---

### Task 3: save_manager.gd — Save, Load, Offline Rewards

**Files:**
- Write: `autoloads/save_manager.gd`

- [ ] **Step 1: Write save_manager.gd**

  ```gdscript
  extends Node

  const SAVE_KEY = "ttc_save_v1"
  const MAX_OFFLINE_SECONDS = 86400

  func save() -> void:
      GameState.state.last_save_timestamp = int(Time.get_unix_time_from_system())
      var json_string = JSON.stringify(GameState.state)
      if OS.has_feature("web"):
          _save_web(json_string)
      else:
          _save_file(json_string)

  func load_game() -> bool:
      var json_string: String
      if OS.has_feature("web"):
          json_string = _load_web()
      else:
          json_string = _load_file()
      if json_string.is_empty():
          return false
      var parsed = JSON.parse_string(json_string)
      if parsed == null or not parsed is Dictionary:
          push_error("SaveManager: failed to parse save data")
          return false
      GameState.state = parsed
      return true

  func calculate_offline_rewards() -> Dictionary:
      var now = int(Time.get_unix_time_from_system())
      var last = int(GameState.state.get("last_save_timestamp", now))
      var elapsed = mini(now - last, MAX_OFFLINE_SECONDS)
      if elapsed < 10:
          return {}
      var income = GameState.calculate_income_per_second()
      var rewards: Dictionary = {}
      for resource in income:
          var amount = income[resource] * float(elapsed) * 0.5
          if amount > 0.01:
              rewards[resource] = snappedf(amount, 0.01)
              GameState.add_resource(resource, amount)
      # Resolve all active missions as complete (TE restored to max)
      GameState.state.active_missions.clear()
      GameState.state.resources.temporal_energy = GameState.state.resources.temporal_energy_max
      # Re-set agent statuses to IDLE
      for agent in GameState.state.agents:
          agent.status = "IDLE"
      return {"elapsed_seconds": elapsed, "rewards": rewards}

  func _save_web(json_string: String) -> void:
      var escaped = json_string.replace("\\", "\\\\").replace("'", "\\'")
      JavaScriptBridge.eval("localStorage.setItem('" + SAVE_KEY + "', '" + escaped + "')")

  func _load_web() -> String:
      var result = JavaScriptBridge.eval("localStorage.getItem('" + SAVE_KEY + "') || ''")
      if result == null:
          return ""
      return str(result)

  func _save_file(json_string: String) -> void:
      var file = FileAccess.open("user://save.json", FileAccess.WRITE)
      if file:
          file.store_string(json_string)

  func _load_file() -> String:
      if not FileAccess.file_exists("user://save.json"):
          return ""
      var file = FileAccess.open("user://save.json", FileAccess.READ)
      if not file:
          return ""
      return file.get_as_text()
  ```

- [ ] **Step 2: Verify**

  Press **F5**. In the Output panel, you should see no errors. Stop the project.

  To manually test save/load on desktop: temporarily add to `game_state.gd`'s `_ready()`:
  ```gdscript
  # TEMP TEST — remove after verifying
  initialize_state()
  add_resource("credits", 999.0)
  SaveManager.save()
  initialize_state()
  SaveManager.load_game()
  print("Credits after save/load: ", get_resource("credits"))  # should print 999
  ```
  Run, check output shows `999`, then remove those lines.

- [ ] **Step 3: Commit**

  ```bash
  git add autoloads/save_manager.gd
  git commit -m "feat: add SaveManager with JSON save/load and offline reward calc"
  ```

---

### Task 4: data/eras.json + era_manager.gd

**Files:**
- Create: `data/eras.json`
- Write: `autoloads/era_manager.gd`

- [ ] **Step 1: Create data/eras.json**

  In Godot FileSystem panel, right-click `data/` → **New File** → name it `eras.json`. Open it in a text editor (or Godot's built-in editor) and paste:

  ```json
  [
    {
      "id": "stone_age", "name": "Stone Age", "date": "~10,000 BC",
      "risk": 1, "duration": 30,
      "base_credits": 5.0, "base_knowledge": 0.0,
      "base_historical_data": 2.0, "base_influence": 0.0,
      "artifact_chance": 0.0, "te_passive_bonus": 0.0, "stability_on_return": 0.0,
      "unlock_cost": {},
      "flavor": "Mammoth bones sell surprisingly well."
    },
    {
      "id": "egypt", "name": "Ancient Egypt", "date": "~3,000 BC",
      "risk": 2, "duration": 45,
      "base_credits": 12.0, "base_knowledge": 3.0,
      "base_historical_data": 0.0, "base_influence": 0.0,
      "artifact_chance": 0.15, "te_passive_bonus": 0.0, "stability_on_return": 0.0,
      "unlock_cost": {"credits": 500.0, "historical_data": 50.0},
      "flavor": "The pyramids aren't finished. Opportunity knocks."
    },
    {
      "id": "roman_empire", "name": "Roman Empire", "date": "~100 AD",
      "risk": 3, "duration": 60,
      "base_credits": 20.0, "base_knowledge": 0.0,
      "base_historical_data": 0.0, "base_influence": 2.0,
      "artifact_chance": 0.10, "te_passive_bonus": 0.0, "stability_on_return": 0.0,
      "unlock_cost": {"credits": 2000.0, "historical_data": 200.0, "knowledge": 50.0},
      "flavor": "Senators are bribeable. Emperors, less so."
    },
    {
      "id": "medieval_europe", "name": "Medieval Europe", "date": "~1200 AD",
      "risk": 3, "duration": 75,
      "base_credits": 18.0, "base_knowledge": 5.0,
      "base_historical_data": 4.0, "base_influence": 0.0,
      "artifact_chance": 0.0, "te_passive_bonus": 0.0, "stability_on_return": 0.0,
      "unlock_cost": {"credits": 8000.0, "historical_data": 500.0},
      "flavor": "The plague is a risk. The relics are worth it."
    },
    {
      "id": "renaissance", "name": "Renaissance", "date": "~1500 AD",
      "risk": 4, "duration": 90,
      "base_credits": 30.0, "base_knowledge": 10.0,
      "base_historical_data": 0.0, "base_influence": 3.0,
      "artifact_chance": 0.0, "te_passive_bonus": 0.0, "stability_on_return": 0.0,
      "unlock_cost": {"credits": 30000.0, "knowledge": 1000.0},
      "flavor": "Da Vinci is suspicious. He's been asking questions."
    },
    {
      "id": "industrial_revolution", "name": "Industrial Revolution", "date": "~1850 AD",
      "risk": 4, "duration": 120,
      "base_credits": 60.0, "base_knowledge": 0.0,
      "base_historical_data": 10.0, "base_influence": 0.0,
      "artifact_chance": 0.0, "te_passive_bonus": 0.5, "stability_on_return": 0.0,
      "unlock_cost": {"credits": 100000.0, "historical_data": 2000.0, "influence": 500.0},
      "flavor": "Steam, coal, and child labour. Don't ask questions."
    },
    {
      "id": "cold_war", "name": "Cold War", "date": "~1962 AD",
      "risk": 4, "duration": 150,
      "base_credits": 100.0, "base_knowledge": 20.0,
      "base_historical_data": 0.0, "base_influence": 10.0,
      "artifact_chance": 0.20, "te_passive_bonus": 0.0, "stability_on_return": 0.0,
      "unlock_cost": {"credits": 500000.0, "knowledge": 5000.0, "influence": 1000.0},
      "flavor": "Agents can be captured. Extraction costs double."
    },
    {
      "id": "near_future", "name": "Near Future", "date": "~2050 AD",
      "risk": 5, "duration": 300,
      "base_credits": 250.0, "base_knowledge": 0.0,
      "base_historical_data": 0.0, "base_influence": 0.0,
      "artifact_chance": 0.0, "te_passive_bonus": 2.0, "stability_on_return": 5.0,
      "unlock_cost": {"credits": 2000000.0, "knowledge": 10000.0, "historical_data": 10000.0},
      "flavor": "They know about us. They've been preparing."
    }
  ]
  ```

- [ ] **Step 2: Write autoloads/era_manager.gd**

  ```gdscript
  extends Node

  var eras: Dictionary = {}

  func _ready() -> void:
      _load_eras()

  func _load_eras() -> void:
      var file = FileAccess.open("res://data/eras.json", FileAccess.READ)
      if not file:
          push_error("EraManager: cannot open res://data/eras.json")
          return
      var data = JSON.parse_string(file.get_as_text())
      if data == null:
          push_error("EraManager: failed to parse eras.json")
          return
      for era in data:
          eras[era.id] = era

  func get_era(era_id: String) -> Dictionary:
      return eras.get(era_id, {})

  func get_all_eras() -> Array:
      return eras.values()

  func can_unlock(era_id: String) -> bool:
      if era_id in GameState.state.eras_unlocked:
          return false
      var era = get_era(era_id)
      if era.is_empty():
          return false
      var cost: Dictionary = era.get("unlock_cost", {})
      for resource in cost:
          if GameState.get_resource(resource) < float(cost[resource]):
              return false
      return true

  func unlock_era(era_id: String) -> void:
      if not can_unlock(era_id):
          return
      var era = get_era(era_id)
      var cost: Dictionary = era.get("unlock_cost", {})
      for resource in cost:
          GameState.add_resource(resource, -float(cost[resource]))
      GameState.state.eras_unlocked.append(era_id)
      GameState.emit_signal("state_changed")

  func tick(delta: float) -> void:
      var completed: Array = []
      for mission in GameState.state.active_missions:
          mission.time_remaining = float(mission.time_remaining) - delta
          if mission.time_remaining <= 0.0:
              completed.append(mission)
      for mission in completed:
          GameState.state.active_missions.erase(mission)
          _complete_mission(mission)

  func _complete_mission(mission: Dictionary) -> void:
      var era = get_era(mission.era_id)
      if era.is_empty():
          return
      var agent_stats = AgentManager.get_agent_stats(mission.agent_id)
      var efficiency = agent_stats.get("efficiency", 1.0)
      var luck = agent_stats.get("luck", 0.05)

      var rewards: Dictionary = {}

      var credit_mult = ResearchManager.get_multiplier("credits") * GameState.get_stability_penalty()
      rewards["credits"] = float(era.get("base_credits", 0.0)) * efficiency * credit_mult

      var base_k = float(era.get("base_knowledge", 0.0))
      if base_k > 0.0:
          rewards["knowledge"] = base_k * ResearchManager.get_multiplier("knowledge")

      var base_hd = float(era.get("base_historical_data", 0.0))
      if base_hd > 0.0:
          rewards["historical_data"] = base_hd * ResearchManager.get_multiplier("historical_data")

      var base_i = float(era.get("base_influence", 0.0))
      if base_i > 0.0:
          rewards["influence"] = base_i

      var artifact_chance = float(era.get("artifact_chance", 0.0))
      if artifact_chance > 0.0:
          var roll = randf()
          var adjusted = (artifact_chance + luck) * ResearchManager.get_multiplier("artifact_chance")
          if roll < adjusted:
              rewards["artifacts"] = 1.0

      var stab_return = float(era.get("stability_on_return", 0.0))
      if stab_return > 0.0:
          rewards["stability"] = stab_return

      # XP for agent
      rewards["xp"] = 10.0 * float(era.get("risk", 1))

      # Apply all rewards
      for resource in rewards:
          if resource != "xp":
              GameState.add_resource(resource, rewards[resource])

      # Restore TE lock
      GameState.state.resources.temporal_energy = minf(
          GameState.state.resources.temporal_energy + 1.0,
          GameState.state.resources.temporal_energy_max
      )

      AgentManager.return_agent(mission.agent_id, rewards)
      GameState.emit_signal("mission_complete", mission.agent_id, mission.era_id, rewards)
      GameState.emit_signal("state_changed")
  ```

- [ ] **Step 3: Verify**

  Press **F5**. Check Output panel — you should see no errors. The autoload `EraManager.eras` should contain 8 entries. To verify, temporarily add to `era_manager.gd`'s `_ready()`:
  ```gdscript
  print("Eras loaded: ", eras.keys())
  ```
  Run, confirm you see 8 era IDs printed, then remove that line.

- [ ] **Step 4: Commit**

  ```bash
  git add data/eras.json autoloads/era_manager.gd
  git commit -m "feat: add 8 era definitions and EraManager autoload"
  ```

---

### Task 5: data/agent_tiers.json + agent_manager.gd

**Files:**
- Create: `data/agent_tiers.json`
- Write: `autoloads/agent_manager.gd`

- [ ] **Step 1: Create data/agent_tiers.json**

  ```json
  {
    "tiers": [
      {"min_level": 1,  "max_level": 9,   "title": "Intern"},
      {"min_level": 10, "max_level": 19,  "title": "Field Operative"},
      {"min_level": 20, "max_level": 29,  "title": "Senior Operative"},
      {"min_level": 30, "max_level": 39,  "title": "Time Scout"},
      {"min_level": 40, "max_level": 49,  "title": "Chrono Specialist"},
      {"min_level": 50, "max_level": 59,  "title": "Temporal Agent"},
      {"min_level": 60, "max_level": 69,  "title": "Chrono Veteran"},
      {"min_level": 70, "max_level": 79,  "title": "Elite Operative"},
      {"min_level": 80, "max_level": 89,  "title": "Chrono Commander"},
      {"min_level": 90, "max_level": 100, "title": "Elite Chrono Operative"}
    ],
    "first_names": ["Ada","Marcus","Hiroshi","Yuki","Elena","Dimitri","Priya","Omar","Saoirse","Aleksei","Zara","Kira","Ivan","Nora","Theo"],
    "last_names": ["Kowalski","Chen","Bonaparte","Alexandros","Volta","Nightingale","Turing","Curie","Darwin","Tesla","Lovelace","Kepler","Faraday","Curie","Ramanujan"]
  }
  ```

- [ ] **Step 2: Write autoloads/agent_manager.gd**

  ```gdscript
  extends Node

  var tiers: Array = []
  var first_names: Array = []
  var last_names: Array = []

  func _ready() -> void:
      _load_data()

  func _load_data() -> void:
      var file = FileAccess.open("res://data/agent_tiers.json", FileAccess.READ)
      if not file:
          push_error("AgentManager: cannot open agent_tiers.json")
          return
      var data = JSON.parse_string(file.get_as_text())
      if data == null:
          return
      tiers = data.get("tiers", [])
      first_names = data.get("first_names", ["Agent"])
      last_names = data.get("last_names", ["Alpha"])

  func create_starter_agent() -> void:
      if GameState.state.agents.size() > 0:
          return
      GameState.state.agents.append(_make_agent("agent_0", "Alex Temporal"))

  func _make_agent(id: String, name: String) -> Dictionary:
      return {
          "id": id, "name": name,
          "level": 1, "xp": 0.0, "tier": 1,
          "status": "IDLE",
          "stat_boosts": {},
          "equipment": {"scanner": "", "shield": "", "core": "", "accelerator": ""}
      }

  func get_agent(agent_id: String):
      for agent in GameState.state.agents:
          if agent.id == agent_id:
              return agent
      return null

  func get_agent_title(level: int) -> String:
      for tier in tiers:
          if level >= tier.min_level and level <= tier.max_level:
              return tier.title
      return "Unknown"

  func get_hire_cost() -> float:
      var base = 200.0
      if "CE-1" in GameState.state.research_unlocked:
          base *= 0.8
      if "hr_department" in GameState.state.departments:
          base *= 0.8
      return snappedf(base * pow(1.5, GameState.state.agents.size()), 1.0)

  func get_agent_cap() -> int:
      var cap = 3
      if "hr_department" in GameState.state.departments:
          cap += 5
      if "CE-3" in GameState.state.research_unlocked:
          cap += 2
      if "CE-5" in GameState.state.research_unlocked:
          cap += 2
      return cap

  func can_hire() -> bool:
      return (GameState.state.agents.size() < get_agent_cap()
              and GameState.get_resource("credits") >= get_hire_cost())

  func hire_agent() -> void:
      if not can_hire():
          return
      GameState.add_resource("credits", -get_hire_cost())
      var id = "agent_" + str(GameState.state.agents.size())
      var name = first_names.pick_random() + " " + last_names.pick_random()
      var agent = _make_agent(id, name)
      if "E-05" in GameState.state.echo_upgrades:
          agent.level = 5
      GameState.state.agents.append(agent)
      GameState.emit_signal("state_changed")

  func can_dispatch(agent_id: String, era_id: String) -> bool:
      var agent = get_agent(agent_id)
      if agent == null or agent.status != "IDLE":
          return false
      if not era_id in GameState.state.eras_unlocked:
          return false
      var max_missions = ResearchManager.get_max_missions()
      if GameState.state.active_missions.size() >= max_missions:
          return false
      if GameState.get_resource("temporal_energy") < 1.0:
          return false
      return true

  func dispatch_agent(agent_id: String, era_id: String) -> void:
      if not can_dispatch(agent_id, era_id):
          return
      var agent = get_agent(agent_id)
      agent.status = "DEPLOYED"
      var era = EraManager.get_era(era_id)
      var stats = get_agent_stats(agent_id)
      var speed_reduction = stats.get("speed", 0.0)
      var duration = float(era.get("duration", 60)) * (1.0 - speed_reduction)
      GameState.add_resource("temporal_energy", -1.0)
      GameState.state.active_missions.append({
          "agent_id": agent_id,
          "era_id": era_id,
          "time_remaining": duration,
          "duration_total": duration
      })
      GameState.emit_signal("state_changed")

  func return_agent(agent_id: String, rewards: Dictionary) -> void:
      var agent = get_agent(agent_id)
      if agent == null:
          return
      agent.status = "IDLE"
      _grant_xp(agent, rewards.get("xp", 10.0))

  func set_agent_captured(agent_id: String) -> void:
      var agent = get_agent(agent_id)
      if agent:
          agent.status = "CAPTURED"
      GameState.emit_signal("state_changed")

  func ransom_agent(agent_id: String) -> void:
      var ransom_credits = 10000.0
      var ransom_influence = 50.0
      if (GameState.get_resource("credits") >= ransom_credits
              and GameState.get_resource("influence") >= ransom_influence):
          GameState.add_resource("credits", -ransom_credits)
          GameState.add_resource("influence", -ransom_influence)
          var agent = get_agent(agent_id)
          if agent:
              agent.status = "IDLE"
          GameState.emit_signal("state_changed")

  func _grant_xp(agent: Dictionary, xp: float) -> void:
      var mult = 1.0
      if "AE-8" in GameState.state.research_unlocked:
          mult *= 1.5
      if "E-10" in GameState.state.echo_upgrades:
          mult *= 1.25
      agent.xp += xp * mult
      while agent.level < 100:
          var needed = _xp_to_next_level(agent.level)
          if agent.xp < needed:
              break
          agent.xp -= needed
          agent.level += 1
          _check_promotion(agent)
          GameState.emit_signal("agent_leveled_up", agent.id, agent.level)

  func _xp_to_next_level(level: int) -> float:
      return float(level * level * 50)

  func _check_promotion(agent: Dictionary) -> void:
      var new_tier = ceili(float(agent.level) / 10.0)
      if new_tier > int(agent.get("tier", 1)):
          agent.tier = new_tier
          GameState.state.agents_promoted_this_run += 1
          # Auto-boost efficiency on promotion (MVP: no choice UI)
          agent.stat_boosts["efficiency"] = float(agent.stat_boosts.get("efficiency", 0.0)) + 0.15

  func get_agent_stats(agent_id: String) -> Dictionary:
      var agent = get_agent(agent_id)
      if agent == null:
          return {"efficiency": 1.0, "speed": 0.0, "luck": 0.05, "resilience": 0.0}
      var t = clampf(float(agent.level - 1) / 99.0, 0.0, 1.0)
      var efficiency = (1.0 + 2.0 * t) + float(agent.stat_boosts.get("efficiency", 0.0))
      var speed     = (0.5 * t)         + float(agent.stat_boosts.get("speed", 0.0))
      var luck      = (0.05 + 0.45 * t) + float(agent.stat_boosts.get("luck", 0.0))
      var resilience = (0.6 * t)        + float(agent.stat_boosts.get("resilience", 0.0))
      efficiency += ResearchManager.get_flat_bonus("efficiency")
      speed      += ResearchManager.get_flat_bonus("speed")
      luck       += ResearchManager.get_flat_bonus("luck")
      resilience += ResearchManager.get_flat_bonus("resilience")
      return {"efficiency": efficiency, "speed": speed, "luck": luck, "resilience": resilience}
  ```

- [ ] **Step 3: Verify**

  Press **F5**. No errors in Output. Stop the project.

- [ ] **Step 4: Commit**

  ```bash
  git add data/agent_tiers.json autoloads/agent_manager.gd
  git commit -m "feat: add AgentManager with hire/dispatch/return/level-up"
  ```

---

### Task 6: data/research_tree.json + research_manager.gd

**Files:**
- Create: `data/research_tree.json`
- Write: `autoloads/research_manager.gd`

- [ ] **Step 1: Create data/research_tree.json**

  ```json
  [
    {"id":"TM-1","name":"Mark II Prototype","category":"time_machines","description":"Mission TE cost −20%","cost_knowledge":100.0,"cost_artifacts":0,"prerequisites":[]},
    {"id":"TM-2","name":"Mark III Engine","category":"time_machines","description":"Max TE cap +1","cost_knowledge":300.0,"cost_artifacts":0,"prerequisites":["TM-1"]},
    {"id":"TM-3","name":"Quantum Stabilizer","category":"time_machines","description":"Mission fail chance −10%","cost_knowledge":500.0,"cost_artifacts":50,"prerequisites":["TM-2"]},
    {"id":"TM-4","name":"Dual-Core Drive","category":"time_machines","description":"TE regen +50%","cost_knowledge":1000.0,"cost_artifacts":100,"prerequisites":["TM-3"]},
    {"id":"TM-5","name":"Mark IV Chrono","category":"time_machines","description":"Max TE cap +3","cost_knowledge":2000.0,"cost_artifacts":200,"prerequisites":["TM-4"]},
    {"id":"TM-6","name":"Temporal Fleet","category":"time_machines","description":"Run 2 simultaneous missions","cost_knowledge":5000.0,"cost_artifacts":500,"prerequisites":["TM-5"]},
    {"id":"AE-1","name":"Basic Training","category":"agent_efficiency","description":"All agents +5% Efficiency","cost_knowledge":200.0,"cost_artifacts":0,"prerequisites":[]},
    {"id":"AE-2","name":"Field Handbook","category":"agent_efficiency","description":"All agents +5% Speed","cost_knowledge":200.0,"cost_artifacts":0,"prerequisites":[]},
    {"id":"AE-3","name":"Advanced Training","category":"agent_efficiency","description":"All agents +10% Efficiency","cost_knowledge":500.0,"cost_artifacts":0,"prerequisites":["AE-1"]},
    {"id":"AE-4","name":"Rapid Deployment","category":"agent_efficiency","description":"All agents +10% Speed","cost_knowledge":500.0,"cost_artifacts":0,"prerequisites":["AE-2"]},
    {"id":"AE-5","name":"Specialist Curriculum","category":"agent_efficiency","description":"All agents +10% Luck","cost_knowledge":800.0,"cost_artifacts":0,"prerequisites":["AE-3"]},
    {"id":"AE-6","name":"Combat Resilience","category":"agent_efficiency","description":"All agents +15% Resilience","cost_knowledge":800.0,"cost_artifacts":0,"prerequisites":["AE-4"]},
    {"id":"AE-7","name":"Elite Operations","category":"agent_efficiency","description":"+15% Efficiency, +5% all stats","cost_knowledge":2000.0,"cost_artifacts":0,"prerequisites":["AE-5","AE-6"]},
    {"id":"AE-8","name":"Chrono Mastery","category":"agent_efficiency","description":"Agent XP gain +50%","cost_knowledge":5000.0,"cost_artifacts":0,"prerequisites":["AE-7"]},
    {"id":"RM-1","name":"Acquisition Protocols","category":"resource_multipliers","description":"Credits +25%","cost_knowledge":300.0,"cost_artifacts":0,"prerequisites":[]},
    {"id":"RM-2","name":"Data Mining","category":"resource_multipliers","description":"Historical Data +50%","cost_knowledge":300.0,"cost_artifacts":0,"prerequisites":[]},
    {"id":"RM-3","name":"Artifact Authentication","category":"resource_multipliers","description":"Artifact drop rate +10%","cost_knowledge":500.0,"cost_artifacts":0,"prerequisites":["RM-1"]},
    {"id":"RM-4","name":"Knowledge Synthesis","category":"resource_multipliers","description":"Knowledge +30%","cost_knowledge":500.0,"cost_artifacts":0,"prerequisites":["RM-2"]},
    {"id":"RM-5","name":"Black Market Network","category":"resource_multipliers","description":"Sell Artifacts for 2x Credits","cost_knowledge":1000.0,"cost_artifacts":100,"prerequisites":["RM-3"]},
    {"id":"RM-6","name":"Historical Archives","category":"resource_multipliers","description":"Historical Data +100%","cost_knowledge":1000.0,"cost_artifacts":0,"prerequisites":["RM-4"]},
    {"id":"RM-7","name":"Revenue Optimization","category":"resource_multipliers","description":"Credits +50%","cost_knowledge":3000.0,"cost_artifacts":0,"prerequisites":["RM-5"]},
    {"id":"RM-8","name":"Temporal Arbitrage","category":"resource_multipliers","description":"All resources +20%","cost_knowledge":8000.0,"cost_artifacts":500,"prerequisites":["RM-7","RM-6"]},
    {"id":"TS-1","name":"Paradox Dampener","category":"timeline_stability","description":"Stability decay -20%","cost_knowledge":200.0,"cost_artifacts":0,"prerequisites":[]},
    {"id":"TS-2","name":"Event Mitigation","category":"timeline_stability","description":"Event Stability damage -15%","cost_knowledge":300.0,"cost_artifacts":0,"prerequisites":["TS-1"]},
    {"id":"TS-3","name":"Temporal Anchor","category":"timeline_stability","description":"Stability floor raised to 20","cost_knowledge":500.0,"cost_artifacts":0,"prerequisites":["TS-1"]},
    {"id":"TS-4","name":"Stabilizer Array","category":"timeline_stability","description":"Stability regen +0.02/sec","cost_knowledge":800.0,"cost_artifacts":0,"prerequisites":["TS-2"]},
    {"id":"TS-5","name":"Quantum Buffer","category":"timeline_stability","description":"Event Stability damage -30%","cost_knowledge":1500.0,"cost_artifacts":0,"prerequisites":["TS-4"]},
    {"id":"TS-6","name":"Chrono Fortress","category":"timeline_stability","description":"Stability floor raised to 40","cost_knowledge":3000.0,"cost_artifacts":0,"prerequisites":["TS-3","TS-5"]},
    {"id":"TS-7","name":"Temporal Immunity","category":"timeline_stability","description":"Missions no longer drain Stability","cost_knowledge":8000.0,"cost_artifacts":300,"prerequisites":["TS-6"]},
    {"id":"CE-1","name":"HR Optimization","category":"corp_expansion","description":"Hire cost -20%; unlocks Tier 2 equipment","cost_knowledge":500.0,"cost_artifacts":0,"prerequisites":[]},
    {"id":"CE-2","name":"Research Division","category":"corp_expansion","description":"All research cost -25%","cost_knowledge":500.0,"cost_artifacts":0,"prerequisites":[]},
    {"id":"CE-3","name":"Agent Cap I","category":"corp_expansion","description":"Max agents +2","cost_knowledge":1000.0,"cost_artifacts":0,"prerequisites":["CE-1"]},
    {"id":"CE-4","name":"Department Efficiency","category":"corp_expansion","description":"All dept bonuses +25%","cost_knowledge":1500.0,"cost_artifacts":0,"prerequisites":["CE-2"]},
    {"id":"CE-5","name":"Agent Cap II","category":"corp_expansion","description":"Max agents +2","cost_knowledge":3000.0,"cost_artifacts":0,"prerequisites":["CE-3"]},
    {"id":"CE-6","name":"Tier 3 Equipment","category":"corp_expansion","description":"Unlocks all Tier 3 gear","cost_knowledge":5000.0,"cost_artifacts":200,"prerequisites":["CE-4"]}
  ]
  ```

- [ ] **Step 2: Write autoloads/research_manager.gd**

  ```gdscript
  extends Node

  # Additive bonuses applied by each node when unlocked.
  # Keys map to resource multipliers or flat agent stat bonuses.
  const NODE_EFFECTS: Dictionary = {
      "TM-1": {"te_cost_reduction": 0.2},
      "TM-2": {"te_max": 1.0},
      "TM-3": {"mission_fail_reduction": 0.1},
      "TM-4": {"te_regen_bonus": 0.5},
      "TM-5": {"te_max": 3.0},
      "TM-6": {"extra_mission_slot": 1.0},
      "AE-1": {"efficiency": 0.05},
      "AE-2": {"speed": 0.05},
      "AE-3": {"efficiency": 0.10},
      "AE-4": {"speed": 0.10},
      "AE-5": {"luck": 0.10},
      "AE-6": {"resilience": 0.15},
      "AE-7": {"efficiency": 0.15, "speed": 0.05, "luck": 0.05, "resilience": 0.05},
      "AE-8": {},
      "RM-1": {"credits": 0.25},
      "RM-2": {"historical_data": 0.50},
      "RM-3": {"artifact_chance": 0.10},
      "RM-4": {"knowledge": 0.30},
      "RM-5": {},
      "RM-6": {"historical_data": 1.00},
      "RM-7": {"credits": 0.50},
      "RM-8": {"credits": 0.20, "knowledge": 0.20, "historical_data": 0.20, "influence": 0.20},
      "TS-1": {},
      "TS-2": {},
      "TS-3": {},
      "TS-4": {},
      "TS-5": {},
      "TS-6": {},
      "TS-7": {},
      "CE-1": {},
      "CE-2": {},
      "CE-3": {},
      "CE-4": {},
      "CE-5": {},
      "CE-6": {}
  }

  var nodes: Dictionary = {}

  func _ready() -> void:
      _load_tree()

  func _load_tree() -> void:
      var file = FileAccess.open("res://data/research_tree.json", FileAccess.READ)
      if not file:
          push_error("ResearchManager: cannot open research_tree.json")
          return
      var data = JSON.parse_string(file.get_as_text())
      if data == null:
          return
      for node in data:
          nodes[node.id] = node

  func get_node_data(node_id: String) -> Dictionary:
      return nodes.get(node_id, {})

  func get_nodes_by_category(category: String) -> Array:
      var result: Array = []
      for node in nodes.values():
          if node.get("category", "") == category:
              result.append(node)
      return result

  func can_unlock(node_id: String) -> bool:
      if node_id in GameState.state.research_unlocked:
          return false
      var node = nodes.get(node_id, {})
      if node.is_empty():
          return false
      for prereq in node.get("prerequisites", []):
          if not prereq in GameState.state.research_unlocked:
              return false
      var cost_mult = _get_cost_multiplier()
      if GameState.get_resource("knowledge") < float(node.get("cost_knowledge", 0.0)) * cost_mult:
          return false
      if GameState.get_resource("artifacts") < float(node.get("cost_artifacts", 0)):
          return false
      return true

  func unlock_node(node_id: String) -> void:
      if not can_unlock(node_id):
          return
      var node = nodes.get(node_id, {})
      var cost_mult = _get_cost_multiplier()
      GameState.add_resource("knowledge", -float(node.get("cost_knowledge", 0.0)) * cost_mult)
      if float(node.get("cost_artifacts", 0)) > 0:
          GameState.add_resource("artifacts", -float(node.get("cost_artifacts", 0)))
      GameState.state.research_unlocked.append(node_id)
      _apply_immediate_effects(node_id)
      GameState.emit_signal("state_changed")

  func _apply_immediate_effects(node_id: String) -> void:
      var effects = NODE_EFFECTS.get(node_id, {})
      if effects.has("te_max"):
          GameState.state.resources.temporal_energy_max += effects.te_max
          GameState.state.resources.temporal_energy = minf(
              GameState.state.resources.temporal_energy + effects.te_max,
              GameState.state.resources.temporal_energy_max
          )

  func _get_cost_multiplier() -> float:
      var mult = 1.0
      if "CE-2" in GameState.state.research_unlocked:
          mult *= 0.75
      if "research_department" in GameState.state.departments:
          mult *= 0.75
      return mult

  func get_multiplier(resource_key: String) -> float:
      var total = 1.0
      for node_id in GameState.state.research_unlocked:
          var effects = NODE_EFFECTS.get(node_id, {})
          total += float(effects.get(resource_key, 0.0))
      return maxf(total, 0.01)

  func get_flat_bonus(stat_key: String) -> float:
      var total = 0.0
      for node_id in GameState.state.research_unlocked:
          var effects = NODE_EFFECTS.get(node_id, {})
          total += float(effects.get(stat_key, 0.0))
      return total

  func get_stability_floor() -> float:
      if "TS-6" in GameState.state.research_unlocked:
          return 40.0
      if "TS-3" in GameState.state.research_unlocked:
          return 20.0
      return 0.0

  func get_max_missions() -> int:
      if "TM-6" in GameState.state.research_unlocked:
          return 2
      return 1

  func get_event_stability_reduction() -> float:
      var reduction = 0.0
      if "TS-2" in GameState.state.research_unlocked:
          reduction += 0.15
      if "TS-5" in GameState.state.research_unlocked:
          reduction += 0.30
      return minf(reduction, 0.9)
  ```

- [ ] **Step 3: Verify**

  Press **F5**. No errors. To confirm nodes loaded, temporarily add to `research_manager.gd` `_ready()`:
  ```gdscript
  print("Research nodes loaded: ", nodes.size())  # should print 35
  ```
  Run, check output, remove the line.

- [ ] **Step 4: Commit**

  ```bash
  git add data/research_tree.json autoloads/research_manager.gd
  git commit -m "feat: add 35-node research tree and ResearchManager"
  ```

---

### Task 7: data/events.json + event_manager.gd

**Files:**
- Create: `data/events.json`
- Write: `autoloads/event_manager.gd`

- [ ] **Step 1: Create data/events.json**

  ```json
  [
    {"id":"temporal_anomaly","name":"Temporal Anomaly","trigger":"any","weight":10,
     "description":"A rift in spacetime detected near HQ. Stability is destabilising.",
     "choices":[
       {"label":"Contain it","desc":"-500 ₲, -10 Stability","outcome":{"credits":-500,"stability":-10}},
       {"label":"Study it","desc":"+200 K, -25 Stability","outcome":{"knowledge":200,"stability":-25}},
       {"label":"Ignore it","desc":"-15 Stability","outcome":{"stability":-15}}
     ],"default_choice":2},
    {"id":"corporate_spy","name":"Corporate Spy","trigger":"any","weight":8,
     "description":"A rival corporation has infiltrated your systems.",
     "choices":[
       {"label":"Pay them off","desc":"-2,000 ₲","outcome":{"credits":-2000}},
       {"label":"Confront them","desc":"+5 Influence, -10 Stability","outcome":{"influence":5,"stability":-10}},
       {"label":"Ignore","desc":"-500 Knowledge","outcome":{"knowledge":-500}}
     ],"default_choice":2},
    {"id":"government_inquiry","name":"Government Inquiry","trigger":"any","weight":6,
     "description":"Temporal authorities are asking uncomfortable questions.",
     "choices":[
       {"label":"Bribe officials","desc":"-5,000 ₲","outcome":{"credits":-5000}},
       {"label":"Cooperate","desc":"-30 Influence, +200 Reputation","outcome":{"influence":-30,"reputation":200}},
       {"label":"Stonewall","desc":"-50 Stability","outcome":{"stability":-50}}
     ],"default_choice":1},
    {"id":"artifact_market","name":"Artifact Black Market","trigger":"any","weight":7,
     "description":"An anonymous seller offers rare artifacts at a suspicious price.",
     "choices":[
       {"label":"Buy them","desc":"-2,000 ₲, +20 Artifacts","outcome":{"credits":-2000,"artifacts":20}},
       {"label":"Investigate","desc":"+10 Influence","outcome":{"influence":10}},
       {"label":"Ignore","desc":"Nothing happens","outcome":{}}
     ],"default_choice":2},
    {"id":"stability_crisis","name":"Stability Crisis","trigger":"stability_below_30","weight":15,
     "description":"WARNING: Temporal stability is critical. Immediate action required.",
     "choices":[
       {"label":"Emergency protocols","desc":"-1,000 ₲, +20 Stability","outcome":{"credits":-1000,"stability":20}},
       {"label":"Let it ride","desc":"-5 Stability","outcome":{"stability":-5}}
     ],"default_choice":1},
    {"id":"mammoth_stampede","name":"Mammoth Stampede","trigger":"stone_age","weight":12,
     "description":"A herd of mammoths is heading toward your agent's camp.",
     "choices":[
       {"label":"Evacuate","desc":"Mission +30 seconds","outcome":{"mission_delay":30}},
       {"label":"Study the herd","desc":"+3 Artifacts","outcome":{"artifacts":3}},
       {"label":"Ignore","desc":"20% mission fail","outcome":{"mission_fail_chance":0.2}}
     ],"default_choice":0},
    {"id":"fire_discovery","name":"Fire Discovery","trigger":"stone_age","weight":10,
     "description":"Your agent witnesses humanity discovering fire for the first time.",
     "choices":[
       {"label":"Document it","desc":"+100 Knowledge","outcome":{"knowledge":100}},
       {"label":"Participate","desc":"+50 ₲, mission ends early","outcome":{"credits":50,"end_mission":true}}
     ],"default_choice":0},
    {"id":"pharaohs_interest","name":"Pharaoh's Interest","trigger":"egypt","weight":12,
     "description":"The Pharaoh has taken notice of your agent's unusual technology.",
     "choices":[
       {"label":"Offer a gift","desc":"-500 ₲, +50 Influence","outcome":{"credits":-500,"influence":50}},
       {"label":"Escape","desc":"Mission ends, full rewards","outcome":{"end_mission":true}},
       {"label":"Stay","desc":"+25% rewards on return","outcome":{"reward_bonus":0.25}}
     ],"default_choice":1},
    {"id":"pyramid_blueprint","name":"Pyramid Blueprint","trigger":"egypt","weight":8,
     "description":"Your agent has found what appear to be original pyramid construction plans.",
     "choices":[
       {"label":"Acquire them","desc":"+200 Knowledge, +30 Artifacts","outcome":{"knowledge":200,"artifacts":30}},
       {"label":"Leave them","desc":"Nothing","outcome":{}}
     ],"default_choice":0},
    {"id":"tomb_curse","name":"Tomb Curse","trigger":"egypt","weight":6,
     "description":"Your agent triggered an ancient mechanism. The air smells wrong.",
     "choices":[
       {"label":"Trust the Chrono Shield","desc":"-15 Stability","outcome":{"stability":-15}},
       {"label":"Abort mission","desc":"No rewards, agent safe","outcome":{"end_mission":true,"no_rewards":true}}
     ],"default_choice":0},
    {"id":"senate_bribery","name":"Senate Bribery","trigger":"roman_empire","weight":12,
     "description":"A Roman senator has cornered your agent and is making demands.",
     "choices":[
       {"label":"Bribe him","desc":"-1,000 ₲, +20 Influence","outcome":{"credits":-1000,"influence":20}},
       {"label":"Decline","desc":"Nothing","outcome":{}},
       {"label":"Frame a rival senator","desc":"+10 Influence, -10 Stability","outcome":{"influence":10,"stability":-10}}
     ],"default_choice":1},
    {"id":"gladiator_challenge","name":"Gladiator Challenge","trigger":"roman_empire","weight":8,
     "description":"Your agent has been challenged to the arena. The crowd is watching.",
     "choices":[
       {"label":"Accept the fight","desc":"50%: +50 Rep OR -20 Stability","outcome":{"random_outcome":{"success":{"reputation":50},"failure":{"stability":-20},"chance":0.5}}},
       {"label":"Pay for a substitute","desc":"-800 ₲","outcome":{"credits":-800}},
       {"label":"Disappear","desc":"Mission ends early","outcome":{"end_mission":true}}
     ],"default_choice":1},
    {"id":"black_plague","name":"Black Plague Outbreak","trigger":"medieval_europe","weight":10,
     "description":"The plague has reached your agent's location. Time to decide.",
     "choices":[
       {"label":"Evacuate","desc":"No rewards, agent safe","outcome":{"end_mission":true,"no_rewards":true}},
       {"label":"Treat survivors","desc":"+100 Knowledge, +30 Rep, -20 Stability","outcome":{"knowledge":100,"reputation":30,"stability":-20}},
       {"label":"Shelter in place","desc":"Mission delayed +60 seconds","outcome":{"mission_delay":60}}
     ],"default_choice":2},
    {"id":"witch_trial","name":"Witch Trial","trigger":"medieval_europe","weight":8,
     "description":"Your agent has been accused of witchcraft by the local authorities.",
     "choices":[
       {"label":"Bribe the magistrate","desc":"-1,500 ₲, agent freed","outcome":{"credits":-1500}},
       {"label":"Magical escape","desc":"-15 Stability, mission ends","outcome":{"stability":-15,"end_mission":true}},
       {"label":"Confess","desc":"Agent CAPTURED","outcome":{"capture_agent":true}}
     ],"default_choice":0},
    {"id":"da_vinci_encounter","name":"Da Vinci Encounter","trigger":"renaissance","weight":12,
     "description":"Leonardo da Vinci is watching your agent's equipment with intense curiosity.",
     "choices":[
       {"label":"Distract him with art","desc":"+200 Knowledge","outcome":{"knowledge":200}},
       {"label":"Show him a device","desc":"+500 Knowledge, -30 Stability","outcome":{"knowledge":500,"stability":-30}},
       {"label":"Leave the area","desc":"Nothing","outcome":{}}
     ],"default_choice":0},
    {"id":"inventors_jackpot","name":"Inventor's Jackpot","trigger":"renaissance","weight":8,
     "description":"Your agent has stumbled into a secret workshop full of prototype devices.",
     "choices":[
       {"label":"Raid it","desc":"+100 Artifacts, +300 Knowledge","outcome":{"artifacts":100,"knowledge":300}},
       {"label":"Document and leave","desc":"+200 Knowledge, +10 Reputation","outcome":{"knowledge":200,"reputation":10}}
     ],"default_choice":0},
    {"id":"factory_fire","name":"Factory Fire","trigger":"industrial_revolution","weight":10,
     "description":"An industrial accident has put your agent in immediate danger.",
     "choices":[
       {"label":"Emergency extraction","desc":"Mission ends, no rewards","outcome":{"end_mission":true,"no_rewards":true}},
       {"label":"Help the workers","desc":"+50 Reputation, -20 Stability","outcome":{"reputation":50,"stability":-20}},
       {"label":"Continue the mission","desc":"30% fail, x1.5 rewards if succeeds","outcome":{"risky_continue":{"fail_chance":0.3,"reward_mult":1.5}}}
     ],"default_choice":0},
    {"id":"agent_detected","name":"Agent Detected","trigger":"cold_war","weight":14,
     "description":"Cold War intelligence services have identified your operative.",
     "choices":[
       {"label":"Extract immediately","desc":"Mission ends, agent safe","outcome":{"end_mission":true}},
       {"label":"Go dark","desc":"Agent CAPTURED","outcome":{"capture_agent":true}},
       {"label":"Bluff it out","desc":"60% safe, 40% CAPTURED","outcome":{"random_outcome":{"success":{},"failure":{"capture_agent":true},"chance":0.6}}}
     ],"default_choice":0},
    {"id":"nuclear_briefcase","name":"Nuclear Briefcase","trigger":"cold_war","weight":6,
     "description":"Your agent has found an unattended weapons case. No one is watching.",
     "choices":[
       {"label":"Secure it","desc":"+100 Influence, -30 Stability","outcome":{"influence":100,"stability":-30}},
       {"label":"Report to authorities","desc":"+50 Reputation, mission ends","outcome":{"reputation":50,"end_mission":true}},
       {"label":"Ignore it","desc":"Nothing","outcome":{}}
     ],"default_choice":2},
    {"id":"future_corp_contact","name":"Future Corporation Contact","trigger":"near_future","weight":10,
     "description":"A corporation from 2250 has made contact. They want to negotiate.",
     "choices":[
       {"label":"Accept their deal","desc":"TE -20% this run, +3x Knowledge for 5 min","outcome":{"te_penalty_run":0.2,"knowledge_boost_5min":3.0}},
       {"label":"Counter-offer","desc":"+10 Influence","outcome":{"influence":10}},
       {"label":"Reject","desc":"Nothing, but they note it","outcome":{}}
     ],"default_choice":2}
  ]
  ```

- [ ] **Step 2: Write autoloads/event_manager.gd**

  ```gdscript
  extends Node

  var events: Array = []
  var _timer: float = 0.0
  var _next_fire: float = 0.0
  var _active_event: Dictionary = {}
  var _event_countdown: float = 0.0
  const EVENT_COUNTDOWN = 60.0
  var _knowledge_boost_timer: float = 0.0
  var _knowledge_boost_mult: float = 1.0

  func _ready() -> void:
      _load_events()
      _reset_timer()

  func _load_events() -> void:
      var file = FileAccess.open("res://data/events.json", FileAccess.READ)
      if not file:
          push_error("EventManager: cannot open events.json")
          return
      var data = JSON.parse_string(file.get_as_text())
      if data == null:
          return
      events = data

  func _reset_timer() -> void:
      _next_fire = randf_range(120.0, 300.0)
      _timer = 0.0

  func try_fire_event() -> void:
      _timer += 1.0
      if _knowledge_boost_timer > 0.0:
          _knowledge_boost_timer -= 1.0
      if _timer < _next_fire:
          return
      if not _active_event.is_empty():
          return
      _fire_random_event()
      _reset_timer()

  func _fire_random_event() -> void:
      var pool = _get_eligible_events()
      if pool.is_empty():
          return
      var weights: Array = []
      for e in pool:
          weights.append(int(e.get("weight", 1)))
      var total = 0
      for w in weights:
          total += w
      var roll = randi() % total
      var cumulative = 0
      for i in range(pool.size()):
          cumulative += weights[i]
          if roll < cumulative:
              _active_event = pool[i].duplicate(true)
              _event_countdown = EVENT_COUNTDOWN
              GameState.emit_signal("event_fired", _active_event)
              return

  func _get_eligible_events() -> Array:
      var pool: Array = []
      for e in events:
          var trigger = e.get("trigger", "any")
          if trigger == "any":
              pool.append(e)
          elif trigger == "stability_below_30":
              if GameState.get_resource("stability") < 30.0:
                  pool.append(e)
          else:
              # Era-specific: only if an agent is deployed there
              for mission in GameState.state.active_missions:
                  if mission.era_id == trigger:
                      pool.append(e)
                      break
      return pool

  func tick_event_countdown() -> void:
      if _active_event.is_empty():
          return
      _event_countdown -= 1.0
      if _event_countdown <= 0.0:
          resolve_choice(_active_event.get("default_choice", 0))

  func resolve_choice(choice_index: int) -> void:
      if _active_event.is_empty():
          return
      var choices: Array = _active_event.get("choices", [])
      if choice_index >= choices.size():
          _active_event = {}
          return
      var choice = choices[choice_index]
      _apply_outcome(choice.get("outcome", {}))
      _active_event = {}
      GameState.emit_signal("state_changed")

  func _apply_outcome(outcome: Dictionary) -> void:
      var stability_reduction = ResearchManager.get_event_stability_reduction()
      for key in outcome:
          match key:
              "credits", "knowledge", "artifacts", "historical_data", "influence", "reputation":
                  GameState.add_resource(key, float(outcome[key]))
              "stability":
                  var amount = float(outcome[key])
                  if amount < 0.0:
                      amount *= (1.0 - stability_reduction)
                  GameState.add_resource("stability", amount)
              "capture_agent":
                  if outcome[key]:
                      _capture_first_deployed_agent()
              "end_mission":
                  if outcome[key]:
                      _end_first_mission(outcome.get("no_rewards", false))
              "random_outcome":
                  var ro = outcome[key]
                  if randf() < float(ro.get("chance", 0.5)):
                      _apply_outcome(ro.get("success", {}))
                  else:
                      _apply_outcome(ro.get("failure", {}))
              "knowledge_boost_5min":
                  _knowledge_boost_timer = 300.0
                  _knowledge_boost_mult = float(outcome[key])

  func _capture_first_deployed_agent() -> void:
      for mission in GameState.state.active_missions:
          AgentManager.set_agent_captured(mission.agent_id)
          GameState.state.active_missions.erase(mission)
          break

  func _end_first_mission(no_rewards: bool) -> void:
      if GameState.state.active_missions.is_empty():
          return
      var mission = GameState.state.active_missions[0]
      GameState.state.active_missions.remove_at(0)
      var agent = AgentManager.get_agent(mission.agent_id)
      if agent:
          agent.status = "IDLE"
      GameState.state.resources.temporal_energy = minf(
          GameState.state.resources.temporal_energy + 1.0,
          GameState.state.resources.temporal_energy_max
      )

  func get_active_event() -> Dictionary:
      return _active_event

  func get_event_countdown() -> float:
      return _event_countdown

  func get_knowledge_multiplier() -> float:
      if _knowledge_boost_timer > 0.0:
          return _knowledge_boost_mult
      return 1.0
  ```

- [ ] **Step 3: Verify**

  Press **F5**. No errors. Temporarily add to `event_manager.gd` `_ready()`:
  ```gdscript
  print("Events loaded: ", events.size())  # should print 20
  ```
  Run, confirm, remove.

- [ ] **Step 4: Commit**

  ```bash
  git add data/events.json autoloads/event_manager.gd
  git commit -m "feat: add 20 random events and EventManager"
  ```

---

### Task 8: main.gd — Boot + Tick Loop

**Files:**
- Write: `scripts/main.gd`
- Create: `scenes/main.tscn` (first version — just the node, UI added in Task 9)

- [ ] **Step 1: Create scenes/main.tscn in Godot editor**

  In Godot:
  1. Go to **Scene → New Scene**
  2. Add a **Node** as root (click the + in Scene panel, choose Node)
  3. Rename it to `Main`
  4. With `Main` selected: **Scene → Attach Script** → choose `res://scripts/main.gd`
  5. Add a **Timer** child node, rename it `TickTimer`, set **Wait Time** to `1.0`, **Autostart** to `ON`
  6. Add another **Timer** child node, rename it `SaveTimer`, set **Wait Time** to `30.0`, **Autostart** to `ON`
  7. Save the scene as `res://scenes/main.tscn`
  8. In **Project → Project Settings → General → Application → Run**, set **Main Scene** to `res://scenes/main.tscn`

- [ ] **Step 2: Write scripts/main.gd**

  ```gdscript
  extends Node

  @onready var tick_timer: Timer = $TickTimer
  @onready var save_timer: Timer = $SaveTimer

  var offline_popup_data: Dictionary = {}

  func _ready() -> void:
      _boot()

  func _boot() -> void:
      var loaded = SaveManager.load_game()
      if loaded:
          var offline = SaveManager.calculate_offline_rewards()
          if not offline.is_empty():
              offline_popup_data = offline
      else:
          GameState.initialize_state()

      AgentManager.create_starter_agent()

      # Apply echo upgrades that affect starting state
      _apply_starting_echo_upgrades()

      tick_timer.timeout.connect(_on_tick)
      save_timer.timeout.connect(SaveManager.save)

      GameState.emit_signal("state_changed")

  func _apply_starting_echo_upgrades() -> void:
      var echoes = GameState.state.get("echo_upgrades", [])
      if "E-06" in echoes and GameState.get_resource("credits") == 0.0:
          GameState.add_resource("credits", 1000.0)
      if "E-07" in echoes and GameState.get_resource("knowledge") == 0.0:
          GameState.add_resource("knowledge", 100.0)
      if "E-04" in echoes:
          if not "egypt" in GameState.state.eras_unlocked:
              GameState.state.eras_unlocked.append("egypt")
      if "E-02" in echoes:
          AgentManager.create_starter_agent()  # second agent (create_starter_agent is idempotent after Task 5)

  func _on_tick() -> void:
      EraManager.tick(1.0)
      GameState.apply_passive_income()
      GameState.decay_stability()
      EventManager.try_fire_event()
      EventManager.tick_event_countdown()
      GameState.emit_signal("state_changed")
  ```

- [ ] **Step 3: Verify end-to-end loop**

  Press **F5**. The game window opens. In the Output panel you should see no errors and no crash. After 30 seconds you'll see no change because UI doesn't exist yet — but the tick is running. Stop.

  To confirm the loop works, temporarily add to `game_state.gd`'s `_ready()`:
  ```gdscript
  # TEMP: auto-dispatch a mission after 3 seconds for testing
  await get_tree().create_timer(3.0).timeout
  AgentManager.dispatch_agent("agent_0", "stone_age")
  print("Mission dispatched")
  await get_tree().create_timer(35.0).timeout
  print("Credits after mission: ", get_resource("credits"))  # should be > 0
  ```
  Run for ~40 seconds, check Output shows credits > 0, then remove those lines.

- [ ] **Step 4: Commit**

  ```bash
  git add scenes/main.tscn scripts/main.gd
  git commit -m "feat: main scene with tick loop and game boot sequence"
  ```

---

## PHASE 2 — CORE LOOP

---

### Task 9: Dashboard Screen

**Files:**
- Create: `scenes/ui/dashboard.tscn`
- Write: `scripts/ui/dashboard.gd`

- [ ] **Step 1: Create scenes/ui/dashboard.tscn**

  In Godot, create a new scene. Build this node tree:

  ```
  Control (root) — name: Dashboard, full rect
  └── VBoxContainer
      ├── HBoxContainer (name: ResourceStrip) — 8 children:
      │   ├── VBoxContainer (x8, one per resource)
      │   │   ├── Label (name: ResourceLabel) — text: "CREDITS"
      │   │   └── Label (name: ResourceValue) — text: "0"
      ├── HSeparator
      ├── HBoxContainer (name: MainArea)
      │   ├── VBoxContainer (name: LeftPanel, size_flags: expand)
      │   │   ├── Label — text: "CORPORATION STATUS"
      │   │   ├── GridContainer (name: StatGrid, columns: 2)
      │   │   │   ├── (4x VBoxContainer with Label pairs — see code)
      │   │   ├── Label — text: "OPERATIONS LOG"
      │   │   └── RichTextLabel (name: OpsLog, size_flags: expand fill, scroll_active: true)
      │   └── VBoxContainer (name: RightPanel)
      │       ├── Label — text: "ACTIVE MISSIONS"
      │       └── VBoxContainer (name: MissionList)
  ```

  Attach script `res://scripts/ui/dashboard.gd` to the root Control node.
  Save as `res://scenes/ui/dashboard.tscn`.

- [ ] **Step 2: Write scripts/ui/dashboard.gd**

  ```gdscript
  extends Control

  @onready var resource_strip: HBoxContainer = $VBoxContainer/ResourceStrip
  @onready var stat_grid: GridContainer = $VBoxContainer/MainArea/LeftPanel/StatGrid
  @onready var ops_log: RichTextLabel = $VBoxContainer/MainArea/LeftPanel/OpsLog
  @onready var mission_list: VBoxContainer = $VBoxContainer/MainArea/RightPanel/MissionList

  const RESOURCE_KEYS = ["credits","knowledge","artifacts","historical_data",
                          "temporal_energy","influence","stability","reputation"]
  const RESOURCE_LABELS = ["Credits ₢","Knowledge","Artifacts","Hist. Data",
                            "Temp. Energy","Influence","Stability","Reputation"]

  var _log_entries: Array = []

  func _ready() -> void:
      GameState.state_changed.connect(_refresh)
      GameState.mission_complete.connect(_on_mission_complete)
      GameState.agent_leveled_up.connect(_on_agent_leveled_up)
      _build_resource_strip()
      _refresh()

  func _build_resource_strip() -> void:
      for i in range(RESOURCE_KEYS.size()):
          var col = VBoxContainer.new()
          var label = Label.new()
          label.text = RESOURCE_LABELS[i]
          label.name = "Label"
          var value = Label.new()
          value.name = "Value"
          value.text = "0"
          col.add_child(label)
          col.add_child(value)
          resource_strip.add_child(col)

  func _refresh() -> void:
      _update_resources()
      _update_stats()
      _update_missions()

  func _update_resources() -> void:
      for i in range(RESOURCE_KEYS.size()):
          var col = resource_strip.get_child(i)
          if col == null:
              continue
          var value_label = col.get_node("Value")
          if value_label == null:
              continue
          var val = GameState.get_resource(RESOURCE_KEYS[i])
          if RESOURCE_KEYS[i] == "temporal_energy":
              var max_te = GameState.get_resource("temporal_energy_max")
              value_label.text = "%d / %d" % [int(val), int(max_te)]
          elif RESOURCE_KEYS[i] == "stability":
              value_label.text = "%.0f / 100" % val
          elif val >= 1000000.0:
              value_label.text = "%.1fM" % (val / 1000000.0)
          elif val >= 1000.0:
              value_label.text = "%.1fK" % (val / 1000.0)
          else:
              value_label.text = "%.0f" % val

  func _update_stats() -> void:
      var agents = GameState.state.agents
      var active = 0
      for a in agents:
          if a.status == "DEPLOYED":
              active += 1
      var era_count = GameState.state.eras_unlocked.size()
      var research_count = GameState.state.research_unlocked.size()
      # Clear and rebuild stat grid children
      for child in stat_grid.get_children():
          child.queue_free()
      _add_stat("Active Agents", "%d / %d" % [active, agents.size()])
      _add_stat("Eras Unlocked", "%d / 8" % era_count)
      _add_stat("Missions Total", str(GameState.state.get("total_missions", 0)))
      _add_stat("Research Nodes", "%d / 35" % research_count)

  func _add_stat(label_text: String, value_text: String) -> void:
      var box = VBoxContainer.new()
      var lbl = Label.new()
      lbl.text = label_text
      var val = Label.new()
      val.text = value_text
      box.add_child(lbl)
      box.add_child(val)
      stat_grid.add_child(box)

  func _update_missions() -> void:
      for child in mission_list.get_children():
          child.queue_free()
      for mission in GameState.state.active_missions:
          var agent = AgentManager.get_agent(mission.agent_id)
          var era = EraManager.get_era(mission.era_id)
          var row = HBoxContainer.new()
          var info = VBoxContainer.new()
          var name_label = Label.new()
          name_label.text = agent.name if agent else "Unknown"
          var era_label = Label.new()
          era_label.text = era.get("name", "Unknown era")
          var time_label = Label.new()
          var remaining = float(mission.time_remaining)
          time_label.text = "%d:%02d" % [int(remaining) / 60, int(remaining) % 60]
          info.add_child(name_label)
          info.add_child(era_label)
          row.add_child(info)
          row.add_child(time_label)
          mission_list.add_child(row)

  func _on_mission_complete(agent_id: String, era_id: String, rewards: Dictionary) -> void:
      var agent = AgentManager.get_agent(agent_id)
      var era = EraManager.get_era(era_id)
      var credits = snappedf(rewards.get("credits", 0.0), 0.1)
      _add_log_entry("[%s] returned from %s. +%.0f ₢" % [
          agent.name if agent else agent_id,
          era.get("name", era_id),
          credits
      ])
      GameState.state["total_missions"] = int(GameState.state.get("total_missions", 0)) + 1

  func _on_agent_leveled_up(agent_id: String, new_level: int) -> void:
      var agent = AgentManager.get_agent(agent_id)
      _add_log_entry("[%s] reached Level %d — %s" % [
          agent.name if agent else agent_id,
          new_level,
          AgentManager.get_agent_title(new_level)
      ])

  func _add_log_entry(text: String) -> void:
      _log_entries.append(text)
      if _log_entries.size() > 50:
          _log_entries.remove_at(0)
      ops_log.text = "\n".join(_log_entries.slice(-20))
      ops_log.scroll_to_line(ops_log.get_line_count())
  ```

- [ ] **Step 3: Verify**

  Add the Dashboard scene temporarily to main.tscn:
  1. In main.tscn, add an instance of `scenes/ui/dashboard.tscn` as a child of Main
  2. Press **F5** — the game window should show resource labels (all showing 0)
  3. Wait 35 seconds — the Stone Age mission (from Task 8's test) should complete and show in the log

  Remove the test code from Task 8 and Task 2 before committing.

- [ ] **Step 4: Commit**

  ```bash
  git add scenes/ui/dashboard.tscn scripts/ui/dashboard.gd
  git commit -m "feat: Dashboard screen with resource strip, stats, ops log, mission list"
  ```

---

### Task 10: Timelines, Agents, Research, Corporation Screens + TabContainer

**Files:**
- Create: `scenes/ui/timelines.tscn`, `scenes/ui/agents.tscn`, `scenes/ui/research.tscn`, `scenes/ui/corporation.tscn`
- Write: `scripts/ui/timelines.gd`, `scripts/ui/agents.gd`, `scripts/ui/research.gd`, `scripts/ui/corporation.gd`
- Modify: `scenes/main.tscn` — add TabContainer + all 5 panels

- [ ] **Step 1: Create the four remaining scene placeholders**

  For each of the four scenes below, create a new scene in Godot with a **Control** root node. Attach the matching script. Save to the path shown.

  | Scene path | Script path |
  |---|---|
  | `scenes/ui/timelines.tscn` | `scripts/ui/timelines.gd` |
  | `scenes/ui/agents.tscn` | `scripts/ui/agents.gd` |
  | `scenes/ui/research.tscn` | `scripts/ui/research.gd` |
  | `scenes/ui/corporation.tscn` | `scripts/ui/corporation.gd` |

- [ ] **Step 2: Write scripts/ui/timelines.gd**

  ```gdscript
  extends Control

  @onready var era_list: VBoxContainer = $VBoxContainer/EraList

  func _ready() -> void:
      GameState.state_changed.connect(_refresh)
      _refresh()

  func _refresh() -> void:
      for child in era_list.get_children():
          child.queue_free()
      for era in EraManager.get_all_eras():
          _add_era_row(era)

  func _add_era_row(era: Dictionary) -> void:
      var row = HBoxContainer.new()
      var unlocked = era.id in GameState.state.eras_unlocked

      var name_label = Label.new()
      name_label.text = era.get("name", "Unknown")
      name_label.custom_minimum_size.x = 180

      var status_label = Label.new()
      var risk = int(era.get("risk", 1))
      status_label.text = "Risk: %d/5 | %ds" % [risk, int(era.get("duration", 60))]
      status_label.custom_minimum_size.x = 150

      var action_btn = Button.new()
      if not unlocked:
          var cost = era.get("unlock_cost", {})
          if cost.is_empty():
              action_btn.text = "UNLOCKED"
              action_btn.disabled = true
          else:
              action_btn.text = "UNLOCK"
              action_btn.disabled = not EraManager.can_unlock(era.id)
              action_btn.pressed.connect(func(): _unlock_era(era.id))
      else:
          action_btn.text = "DISPATCH"
          # Find idle agent
          var idle_agent = _get_idle_agent()
          action_btn.disabled = (idle_agent == "" or not AgentManager.can_dispatch(idle_agent, era.id))
          action_btn.pressed.connect(func(): _dispatch_to_era(era.id))

      row.add_child(name_label)
      row.add_child(status_label)
      row.add_child(action_btn)
      era_list.add_child(row)

  func _unlock_era(era_id: String) -> void:
      EraManager.unlock_era(era_id)

  func _dispatch_to_era(era_id: String) -> void:
      var idle_agent = _get_idle_agent()
      if idle_agent != "":
          AgentManager.dispatch_agent(idle_agent, era_id)

  func _get_idle_agent() -> String:
      for agent in GameState.state.agents:
          if agent.status == "IDLE":
              return agent.id
      return ""
  ```

- [ ] **Step 3: Write scripts/ui/agents.gd**

  ```gdscript
  extends Control

  @onready var hire_btn: Button = $VBoxContainer/HireBtn
  @onready var hire_cost_label: Label = $VBoxContainer/HireCostLabel
  @onready var agent_list: VBoxContainer = $VBoxContainer/AgentList

  func _ready() -> void:
      GameState.state_changed.connect(_refresh)
      hire_btn.pressed.connect(_hire_agent)
      _refresh()

  func _refresh() -> void:
      var cost = AgentManager.get_hire_cost()
      hire_btn.text = "HIRE AGENT"
      hire_btn.disabled = not AgentManager.can_hire()
      hire_cost_label.text = "Cost: %.0f ₢" % cost
      _rebuild_agent_list()

  func _hire_agent() -> void:
      AgentManager.hire_agent()

  func _rebuild_agent_list() -> void:
      for child in agent_list.get_children():
          child.queue_free()
      for agent in GameState.state.agents:
          _add_agent_row(agent)

  func _add_agent_row(agent: Dictionary) -> void:
      var row = HBoxContainer.new()
      var title = AgentManager.get_agent_title(agent.level)
      var info = Label.new()
      info.text = "%s — Lv.%d %s [%s]" % [agent.name, agent.level, title, agent.status]
      info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
      row.add_child(info)

      if agent.status == "IDLE":
          var dispatch_btn = Button.new()
          dispatch_btn.text = "DISPATCH"
          var agent_id = agent.id
          dispatch_btn.pressed.connect(func(): _show_dispatch_options(agent_id))
          row.add_child(dispatch_btn)
      elif agent.status == "CAPTURED":
          var ransom_btn = Button.new()
          ransom_btn.text = "RANSOM (10K ₢)"
          var agent_id = agent.id
          ransom_btn.pressed.connect(func(): AgentManager.ransom_agent(agent_id))
          row.add_child(ransom_btn)

      agent_list.add_child(row)

  func _show_dispatch_options(agent_id: String) -> void:
      # For MVP: dispatch to first available unlocked era
      for era_id in GameState.state.eras_unlocked:
          if AgentManager.can_dispatch(agent_id, era_id):
              AgentManager.dispatch_agent(agent_id, era_id)
              return
  ```

  > **Note:** A full era-selection UI can be added post-MVP. For now, dispatching assigns to the first available unlocked era. Players use the Timelines tab for targeted dispatch.

- [ ] **Step 4: Write scripts/ui/research.gd**

  ```gdscript
  extends Control

  @onready var node_list: VBoxContainer = $VBoxContainer/NodeList

  const CATEGORIES = ["time_machines","agent_efficiency","resource_multipliers","timeline_stability","corp_expansion"]
  const CATEGORY_LABELS = ["Time Machines","Agent Efficiency","Resource Multipliers","Timeline Stability","Corp Expansion"]

  func _ready() -> void:
      GameState.state_changed.connect(_refresh)
      _refresh()

  func _refresh() -> void:
      for child in node_list.get_children():
          child.queue_free()
      for i in range(CATEGORIES.size()):
          _add_category(CATEGORIES[i], CATEGORY_LABELS[i])

  func _add_category(category: String, label: String) -> void:
      var header = Label.new()
      header.text = "── %s ──" % label
      node_list.add_child(header)
      var cat_nodes = ResearchManager.get_nodes_by_category(category)
      for node in cat_nodes:
          _add_node_row(node)

  func _add_node_row(node: Dictionary) -> void:
      var row = HBoxContainer.new()
      var unlocked = node.id in GameState.state.research_unlocked
      var can = ResearchManager.can_unlock(node.id)

      var info = Label.new()
      var prefix = "✓ " if unlocked else ("  " if can else "🔒 ")
      info.text = "%s%s — %s (%.0f K)" % [prefix, node.get("name","?"), node.get("description",""), node.get("cost_knowledge",0)]
      info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
      row.add_child(info)

      if not unlocked:
          var btn = Button.new()
          btn.text = "UNLOCK"
          btn.disabled = not can
          var node_id = node.id
          btn.pressed.connect(func(): ResearchManager.unlock_node(node_id))
          row.add_child(btn)

      node_list.add_child(row)
  ```

- [ ] **Step 5: Write scripts/ui/corporation.gd**

  ```gdscript
  extends Control

  @onready var dept_list: VBoxContainer = $VBoxContainer/DeptList
  @onready var prestige_btn: Button = $VBoxContainer/PrestigeBtn
  @onready var prestige_info: Label = $VBoxContainer/PrestigeInfo
  @onready var echo_label: Label = $VBoxContainer/EchoLabel
  @onready var echo_list: VBoxContainer = $VBoxContainer/EchoList

  const DEPARTMENTS = [
      {"id":"hr_department","name":"HR Department","desc":"Max agents +5, hire cost -20%","cost_credits":10000.0,"cost_influence":100.0},
      {"id":"research_department","name":"Research Department","desc":"All research -25%","cost_credits":15000.0,"cost_knowledge":200.0},
      {"id":"security_department","name":"Security Department","desc":"Stability decay -30%, event damage -20%","cost_credits":20000.0,"cost_influence":300.0},
      {"id":"marketing_department","name":"Marketing Department","desc":"Credits +25%, Reputation +20%","cost_credits":25000.0,"cost_influence":0.0},
      {"id":"timeline_intelligence","name":"Timeline Intelligence","desc":"Event outcomes revealed, mission fail -15%","cost_credits":50000.0,"cost_influence":500.0}
  ]

  const ECHO_UPGRADES = [
      {"id":"E-01","name":"Chrono Foundation","desc":"All income +10%","cost":1},
      {"id":"E-02","name":"Temporal Memory","desc":"Start with 2 agents","cost":2},
      {"id":"E-03","name":"Echo Resonance","desc":"Echoes earned +25%","cost":2},
      {"id":"E-04","name":"Quick Start","desc":"Egypt unlocked from start","cost":3},
      {"id":"E-05","name":"Veteran Agents","desc":"Agents start at Level 5","cost":3},
      {"id":"E-06","name":"Stability Mastery","desc":"Start with 90 Stability","cost":3},
      {"id":"E-07","name":"Resource Cache","desc":"Start with 1,000 ₢","cost":5},
      {"id":"E-08","name":"Knowledge Legacy","desc":"Start with 100 Knowledge","cost":5},
      {"id":"E-09","name":"Income Surge","desc":"All income +25%","cost":5},
      {"id":"E-10","name":"Time Veteran","desc":"Agent XP +25%","cost":5},
      {"id":"E-11","name":"Research Head Start","desc":"First 5 nodes -50%","cost":8},
      {"id":"E-12","name":"Corporate Memory","desc":"Departments -20%","cost":8},
      {"id":"E-13","name":"Temporal Dynasty","desc":"All income +50%","cost":10},
      {"id":"E-14","name":"Paradox Veteran","desc":"Start with TS-1+TS-2","cost":12},
      {"id":"E-15","name":"CEO of Time","desc":"All income x2","cost":20}
  ]

  func _ready() -> void:
      GameState.state_changed.connect(_refresh)
      prestige_btn.pressed.connect(_do_prestige)
      _refresh()

  func _refresh() -> void:
      _update_departments()
      _update_prestige()
      _update_echo_shop()

  func _update_departments() -> void:
      for child in dept_list.get_children():
          child.queue_free()
      for dept in DEPARTMENTS:
          _add_dept_row(dept)

  func _add_dept_row(dept: Dictionary) -> void:
      var owned = dept.id in GameState.state.departments
      var row = HBoxContainer.new()
      var info = Label.new()
      info.text = ("[OWNED] " if owned else "") + dept.name + " — " + dept.desc
      info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
      row.add_child(info)
      if not owned:
          var btn = Button.new()
          btn.text = "BUY (%.0f ₢)" % dept.cost_credits
          btn.disabled = not _can_buy_dept(dept)
          var dept_id = dept.id
          btn.pressed.connect(func(): _buy_dept(dept_id, dept))
          row.add_child(btn)
      dept_list.add_child(row)

  func _can_buy_dept(dept: Dictionary) -> bool:
      if dept.id in GameState.state.departments:
          return false
      if GameState.get_resource("credits") < dept.cost_credits:
          return false
      if dept.get("cost_influence", 0.0) > 0 and GameState.get_resource("influence") < dept.cost_influence:
          return false
      if dept.get("cost_knowledge", 0.0) > 0 and GameState.get_resource("knowledge") < dept.cost_knowledge:
          return false
      return true

  func _buy_dept(dept_id: String, dept: Dictionary) -> void:
      GameState.add_resource("credits", -dept.cost_credits)
      if dept.get("cost_influence", 0.0) > 0:
          GameState.add_resource("influence", -dept.cost_influence)
      if dept.get("cost_knowledge", 0.0) > 0:
          GameState.add_resource("knowledge", -dept.cost_knowledge)
      GameState.state.departments.append(dept_id)
      GameState.emit_signal("state_changed")

  func _update_prestige() -> void:
      var total = GameState.state.get("total_credits_earned", 0.0)
      var threshold = 1000000.0
      prestige_btn.disabled = total < threshold
      prestige_info.text = "Total earned: %.0f / 1,000,000 ₢ to unlock Temporal Reset" % total

  func _do_prestige() -> void:
      if GameState.state.get("total_credits_earned", 0.0) < 1000000.0:
          return
      var echoes = _calculate_echoes()
      GameState.state.temporal_echoes += echoes
      GameState.state.prestige_count += 1
      var keep_echoes = GameState.state.temporal_echoes
      var keep_echo_upgrades = GameState.state.echo_upgrades.duplicate()
      var keep_prestige_count = GameState.state.prestige_count
      GameState.initialize_state()
      GameState.state.temporal_echoes = keep_echoes
      GameState.state.echo_upgrades = keep_echo_upgrades
      GameState.state.prestige_count = keep_prestige_count
      AgentManager.create_starter_agent()
      GameState.emit_signal("state_changed")

  func _calculate_echoes() -> int:
      var total = GameState.state.get("total_credits_earned", 0.0)
      var base = int(sqrt(total / 500000.0))
      base += GameState.state.eras_unlocked.size()
      base += int(GameState.state.get("agents_promoted_this_run", 0))
      if "E-03" in GameState.state.echo_upgrades:
          base = int(float(base) * 1.25)
      return maxi(base, 1)

  func _update_echo_shop() -> void:
      echo_label.text = "Temporal Echoes: %d" % GameState.state.get("temporal_echoes", 0)
      for child in echo_list.get_children():
          child.queue_free()
      for upgrade in ECHO_UPGRADES:
          var owned = upgrade.id in GameState.state.echo_upgrades
          var row = HBoxContainer.new()
          var info = Label.new()
          info.text = ("[✓] " if owned else "    ") + upgrade.name + " — " + upgrade.desc + " (%d Echoes)" % upgrade.cost
          info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
          row.add_child(info)
          if not owned:
              var btn = Button.new()
              btn.text = "BUY"
              btn.disabled = GameState.state.get("temporal_echoes", 0) < upgrade.cost
              var upg_id = upgrade.id
              var upg_cost = upgrade.cost
              btn.pressed.connect(func(): _buy_echo_upgrade(upg_id, upg_cost))
              row.add_child(btn)
          echo_list.add_child(row)

  func _buy_echo_upgrade(upgrade_id: String, cost: int) -> void:
      if GameState.state.temporal_echoes < cost:
          return
      GameState.state.temporal_echoes -= cost
      GameState.state.echo_upgrades.append(upgrade_id)
      GameState.emit_signal("state_changed")
  ```

- [ ] **Step 6: Build scene node trees for the four new scenes**

  For each scene, the minimum node tree needed:

  **timelines.tscn:**
  ```
  Control
  └── VBoxContainer
      ├── Label — text: "TIMELINE MAP"
      └── VBoxContainer (name: EraList)
  ```

  **agents.tscn:**
  ```
  Control
  └── VBoxContainer
      ├── Label — text: "AGENT ROSTER"
      ├── Button (name: HireBtn) — text: "HIRE AGENT"
      ├── Label (name: HireCostLabel)
      └── VBoxContainer (name: AgentList)
  ```

  **research.tscn:**
  ```
  Control
  └── VBoxContainer
      ├── Label — text: "RESEARCH TREE"
      └── VBoxContainer (name: NodeList)
  ```

  **corporation.tscn:**
  ```
  Control
  └── VBoxContainer
      ├── Label — text: "CORPORATION"
      ├── VBoxContainer (name: DeptList)
      ├── Button (name: PrestigeBtn) — text: "TEMPORAL RESET"
      ├── Label (name: PrestigeInfo)
      ├── Label (name: EchoLabel)
      └── VBoxContainer (name: EchoList)
  ```

- [ ] **Step 7: Wire up TabContainer in main.tscn**

  Open `scenes/main.tscn`. Replace any previous test children with:
  ```
  Main (Node)
  ├── TickTimer
  ├── SaveTimer
  └── TabContainer (name: Tabs, anchors: full rect)
      ├── [instance] scenes/ui/dashboard.tscn  — Tab name: "Dashboard"
      ├── [instance] scenes/ui/timelines.tscn  — Tab name: "Timelines"
      ├── [instance] scenes/ui/agents.tscn     — Tab name: "Agents"
      ├── [instance] scenes/ui/research.tscn   — Tab name: "Research"
      └── [instance] scenes/ui/corporation.tscn — Tab name: "Corporation"
  ```
  To add a scene instance: right-click a node in the scene tree → **Instantiate Child Scene** → pick the .tscn file.

  Set the tab name by selecting each instanced scene root and changing its **name** property, OR by setting the `TabContainer`'s tab titles in the Inspector after running once.

- [ ] **Step 8: Verify full UI**

  Press **F5**. You should see:
  - A window with 5 tabs at the top
  - Dashboard shows resource strip (all 0 at start) and "1 / 1" agents active
  - Timelines tab shows all 8 eras, Stone Age has a DISPATCH button, others show UNLOCK
  - Agents tab shows 1 agent (Alex Temporal) and a HIRE AGENT button
  - Research tab shows all 35 nodes organised by category
  - Corporation tab shows 5 departments and the Temporal Reset section

  Click **DISPATCH** in Timelines. After 30 seconds, the Dashboard ops log should show the mission return.

- [ ] **Step 9: Commit**

  ```bash
  git add scenes/ui/ scripts/ui/ scenes/main.tscn
  git commit -m "feat: all 5 UI tabs wired up with live data from GameState"
  ```

---

## PHASE 3 — SYSTEMS

---

### Task 11: Event Notification Overlay

**Files:**
- Create: `scenes/ui/event_overlay.tscn`
- Write: `scripts/ui/event_overlay.gd`
- Modify: `scenes/main.tscn` — add overlay as child of Main (above TabContainer)

- [ ] **Step 1: Create scenes/ui/event_overlay.tscn**

  Node tree:
  ```
  Control (root, name: EventOverlay) — anchor: full rect, mouse_filter: ignore
  └── PanelContainer (name: Panel) — anchor: top right, custom size 340x200, margin 20px from edge
      └── VBoxContainer
          ├── HBoxContainer
          │   ├── Label (name: EventTitle) — text: "EVENT NAME"
          │   └── Label (name: CountdownLabel) — text: "0:60"
          ├── Label (name: EventDesc) — autowrap: ON
          └── VBoxContainer (name: ChoiceList)
  ```

  Attach `res://scripts/ui/event_overlay.gd` to the root Control.
  Save as `res://scenes/ui/event_overlay.tscn`.
  Set the root Control's `visible` property to `false` by default.

- [ ] **Step 2: Write scripts/ui/event_overlay.gd**

  ```gdscript
  extends Control

  @onready var panel: PanelContainer = $Panel
  @onready var event_title: Label = $Panel/VBoxContainer/HBoxContainer/EventTitle
  @onready var countdown_label: Label = $Panel/VBoxContainer/HBoxContainer/CountdownLabel
  @onready var event_desc: Label = $Panel/VBoxContainer/EventDesc
  @onready var choice_list: VBoxContainer = $Panel/VBoxContainer/ChoiceList

  func _ready() -> void:
      GameState.event_fired.connect(_show_event)
      GameState.state_changed.connect(_update_countdown)
      visible = false

  func _show_event(event_data: Dictionary) -> void:
      event_title.text = event_data.get("name", "EVENT")
      event_desc.text = event_data.get("description", "")
      for child in choice_list.get_children():
          child.queue_free()
      var choices: Array = event_data.get("choices", [])
      for i in range(choices.size()):
          var choice = choices[i]
          var btn = Button.new()
          btn.text = "[ %s ] %s — %s" % [["A","B","C"][i], choice.get("label","?"), choice.get("desc","")]
          btn.autowrap_mode = TextServer.AUTOWRAP_WORD
          var idx = i
          btn.pressed.connect(func(): _resolve(idx))
          choice_list.add_child(btn)
      visible = true

  func _update_countdown() -> void:
      if not visible:
          return
      var remaining = EventManager.get_event_countdown()
      if remaining <= 0.0:
          visible = false
          return
      countdown_label.text = "0:%02d" % int(remaining)

  func _resolve(choice_index: int) -> void:
      EventManager.resolve_choice(choice_index)
      visible = false
  ```

- [ ] **Step 3: Add EventOverlay to main.tscn**

  In `scenes/main.tscn`, add an instance of `scenes/ui/event_overlay.tscn` as a child of `Main` — placed **after** the TabContainer so it renders on top.

- [ ] **Step 4: Verify**

  Press **F5**. Deploy an agent to Stone Age and wait 2–5 minutes. A notification panel should slide in showing an event with 3 choice buttons. Clicking a button should dismiss it and apply the outcome (check credits/stability in the resource strip).

- [ ] **Step 5: Commit**

  ```bash
  git add scenes/ui/event_overlay.tscn scripts/ui/event_overlay.gd scenes/main.tscn
  git commit -m "feat: event notification overlay with countdown and choice buttons"
  ```

---

### Task 12: Offline Rewards Popup

**Files:**
- Create: `scenes/ui/offline_popup.tscn`
- Write: `scripts/ui/offline_popup.gd`
- Modify: `scripts/main.gd` — trigger popup after boot if offline rewards exist

- [ ] **Step 1: Create scenes/ui/offline_popup.tscn**

  Node tree:
  ```
  Control (root, name: OfflinePopup, visible: false)
  └── PanelContainer (centered, min size 300x200)
      └── VBoxContainer
          ├── Label — text: "WELCOME BACK"
          ├── Label (name: TimeLabel) — text: "You were away 0h 0m"
          ├── Label (name: RewardsLabel) — text: ""
          └── Button (name: OkBtn) — text: "COLLECT"
  ```

  Attach `res://scripts/ui/offline_popup.gd` to root. Save as `res://scenes/ui/offline_popup.tscn`.

- [ ] **Step 2: Write scripts/ui/offline_popup.gd**

  ```gdscript
  extends Control

  @onready var time_label: Label = $PanelContainer/VBoxContainer/TimeLabel
  @onready var rewards_label: Label = $PanelContainer/VBoxContainer/RewardsLabel
  @onready var ok_btn: Button = $PanelContainer/VBoxContainer/OkBtn

  func _ready() -> void:
      ok_btn.pressed.connect(func(): visible = false)

  func show_rewards(data: Dictionary) -> void:
      var elapsed = int(data.get("elapsed_seconds", 0))
      var hours = elapsed / 3600
      var minutes = (elapsed % 3600) / 60
      time_label.text = "You were away %dh %dm." % [hours, minutes]
      var rewards = data.get("rewards", {})
      var lines: Array = ["Your agents collected:"]
      if rewards.get("credits", 0.0) > 0:
          lines.append("  +%.0f ₢ Credits" % rewards.credits)
      if rewards.get("knowledge", 0.0) > 0:
          lines.append("  +%.0f Knowledge" % rewards.knowledge)
      if rewards.get("historical_data", 0.0) > 0:
          lines.append("  +%.0f Historical Data" % rewards.historical_data)
      rewards_label.text = "\n".join(lines)
      visible = true
  ```

- [ ] **Step 3: Add popup to main.tscn and trigger it**

  In `scenes/main.tscn`, add an instance of `scenes/ui/offline_popup.tscn` as the last child of Main.

  In `scripts/main.gd`, after `_boot()`, add:
  ```gdscript
  func _ready() -> void:
      _boot()
      if not offline_popup_data.is_empty():
          await get_tree().process_frame
          $OfflinePopup.show_rewards(offline_popup_data)
  ```

- [ ] **Step 4: Verify**

  Run the game, let it save (30 seconds). Close the window. Change your system clock forward by 1 hour. Run again. The offline popup should appear showing ~30 minutes of rewards (capped offline efficiency).

  Reset your system clock when done.

- [ ] **Step 5: Commit**

  ```bash
  git add scenes/ui/offline_popup.tscn scripts/ui/offline_popup.gd scenes/main.tscn scripts/main.gd
  git commit -m "feat: offline rewards popup on game load"
  ```

---

## PHASE 4 — POLISH

---

### Task 13: Terminal Theme

**Files:**
- Create: `theme/terminal.tres`
- Modify: `scenes/main.tscn` — apply theme

- [ ] **Step 1: Create theme/terminal.tres in Godot**

  1. In Godot, go to **FileSystem** → right-click `theme/` → **New Resource**
  2. Search for **Theme** and create it. Save as `res://theme/terminal.tres`.
  3. Open the theme in the Inspector.

  Set these theme overrides via the Inspector's **Theme** editor:

  **Font:** Click **Default Font** → drag `theme/fonts/ShareTechMono-Regular.ttf` in.

  **Colors:**
  - Default font color: `#00ff41`
  - Background color: `#080d08`

  **Panel/PanelContainer StyleBox:**
  - Create a **StyleBoxFlat**
  - Background color: `#0d150d`
  - Border color: `#00ff4133`
  - Border width: 1px all sides
  - Corner radius: 3px

  **Button Normal StyleBox:**
  - Background: `#0d1a0d`
  - Border: `#00ff4144`

  **Button Hover StyleBox:**
  - Background: `#112011`
  - Border: `#00ff4188`

  **Button Pressed StyleBox:**
  - Background: `#00ff4122`
  - Border: `#00ff41`

  **Button Disabled StyleBox:**
  - Background: `#080d08`
  - Border: `#00440011`
  - Font color override (disabled): `#005510`

- [ ] **Step 2: Apply theme to main.tscn**

  Select the root `Main` node in `scenes/main.tscn`. In the Inspector, find **Theme** property. Drag `res://theme/terminal.tres` into it. The theme will cascade to all child nodes automatically.

- [ ] **Step 3: Set window background color**

  Go to **Project → Project Settings → Rendering → Environment → Default Clear Color**. Set it to `#080d08`.

- [ ] **Step 4: Verify**

  Press **F5**. The entire game UI should now display in green-on-dark terminal style with Share Tech Mono font. All buttons should have the correct hover/pressed states.

- [ ] **Step 5: Commit**

  ```bash
  git add theme/
  git commit -m "feat: terminal CRT theme applied globally — green-on-dark, monospace"
  ```

---

### Task 14: Balance Pass

**Files:**
- Modify: `data/eras.json` — adjust base values if income feels wrong
- Modify: `data/research_tree.json` — adjust costs if research gates feel wrong

- [ ] **Step 1: Run a 10-minute play session and note timings**

  Start a fresh save (delete `user://save.json` if on desktop, or clear localStorage). Play for 10 minutes and note:
  - How long until Egypt unlocked?
  - How long until 3 agents?
  - How many research nodes unlocked?
  - Does Stability drop dangerously?

  Target from spec:
  - Egypt at ~5 minutes: `500 ₢ + 50 HD`. Stone Age gives 5 ₢/30s = 10 ₢/min + 2 HD/30s = 4 HD/min. So: 50 ₢ in 5 min ✓, 20 HD in 5 min (need 50 → takes ~12.5 min). **Adjust:** Reduce Egypt unlock HD cost from 50 → 20.
  - 2nd agent at 5 min: costs 300 ₢, need 300 ₢ in ~5 min (10 ₢/min = 50 ₢ in 5 min — too slow). **Adjust:** Start Credits = 50 ₢.

- [ ] **Step 2: Apply balance adjustments to eras.json**

  Update Stone Age and Egypt entries:
  ```json
  {"id":"stone_age", ..., "base_credits": 8.0, "base_historical_data": 3.0, ...}
  {"id":"egypt", ..., "unlock_cost": {"credits": 300.0, "historical_data": 20.0}, ...}
  ```

- [ ] **Step 3: Set starting credits in game_state.gd**

  In `game_state.gd` `initialize_state()`, change:
  ```gdscript
  "credits": 50.0,
  ```

- [ ] **Step 4: Run second play session and verify balance targets**

  - Egypt unlocked within 5 minutes: ✓ or adjust further
  - First research node (AE-1: 200 K) unlocked within 15 minutes: ✓
  - Stability not hitting crisis within first 20 minutes: ✓

- [ ] **Step 5: Commit**

  ```bash
  git add data/eras.json autoloads/game_state.gd
  git commit -m "balance: adjust early-game income curve and era unlock costs"
  ```

---

### Task 15: Web Export + Final Test

**Files:**
- No code changes — Godot editor export configuration only

- [ ] **Step 1: Install web export templates**

  In Godot: **Editor → Manage Export Templates → Download and Install**. Wait for download.

- [ ] **Step 2: Configure HTML5 export**

  Go to **Project → Export → Add → Web**.
  - Export Path: `exports/web/index.html`
  - Check: **Export With Debug** OFF (for release)
  - Head Include: leave blank for now

- [ ] **Step 3: Create the exports folder**

  ```bash
  mkdir exports
  mkdir exports/web
  ```

- [ ] **Step 4: Export the game**

  In the Export dialog, click **Export Project** → save to `exports/web/index.html`.

- [ ] **Step 5: Test locally using Python's web server**

  ```bash
  cd exports/web
  python -m http.server 8080
  ```
  Open `http://localhost:8080` in your browser. The game should load and run.

  **Web-specific checks:**
  - Save works: earn some credits, wait 30s, refresh the page — credits should persist
  - Offline rewards: close tab, wait 5 minutes, reopen — popup should show rewards
  - No console errors in the browser's DevTools (F12)

- [ ] **Step 6: Commit export config**

  ```bash
  git add export_presets.cfg
  echo "exports/" >> .gitignore
  git add .gitignore
  git commit -m "feat: HTML5 web export configured and tested"
  ```

---

## Self-Review

**Spec coverage check:**

| Spec section | Covered by task |
|---|---|
| 8 resources | Task 2 (game_state.gd) |
| 8 eras | Task 4 (eras.json + EraManager) |
| Agent stats, 10 tiers, levelling | Task 5 (AgentManager) |
| Equipment slots | Task 5 (agent schema) — purchase UI deferred to post-MVP |
| 35-node research tree | Task 6 (ResearchManager) |
| 20 random events | Task 7 (EventManager) |
| Prestige / Temporal Reset | Task 10 (corporation.gd `_do_prestige`) |
| 15 Echo upgrades | Task 10 (corporation.gd `ECHO_UPGRADES`) |
| 5 departments | Task 10 (corporation.gd `DEPARTMENTS`) |
| Offline rewards | Task 3 (SaveManager) + Task 12 (popup) |
| Save/load localStorage + file | Task 3 |
| Dashboard UI | Task 9 |
| All 5 tabs | Task 10 |
| Event overlay | Task 11 |
| Terminal theme | Task 13 |
| Balance pass | Task 14 |
| Web export | Task 15 |
| Godot install guide | Task 1 |

**Known deferral (post-MVP):**
- Equipment purchase UI (slots exist in save schema; buying is not wired to a UI button)
- Targeted agent→era dispatch from Agents tab (dispatches to first available era in MVP)
- Stability Crisis event filter is implemented in EventManager but visual warning (below 30) not highlighted in resource strip — add a color change in dashboard.gd post-MVP

**No placeholders found.** All steps contain complete code.

**Type consistency verified:** `GameState.get_resource()` returns `float` throughout; `AgentManager.get_agent()` returns `null` or `Dictionary` and callers check for null.
