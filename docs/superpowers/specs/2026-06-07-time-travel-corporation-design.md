# Time Travel Corporation — Game Design Specification
**Date:** 2026-06-07  
**Status:** Approved  
**Engine:** Godot 4 (GDScript)  
**Target platforms:** Browser (itch.io), Desktop (Steam)  
**Development timeline:** 30 days solo

---

## 1. Project Overview

### Core Fantasy
The player runs the world's first time travel corporation. Agents are sent into historical eras to extract resources, knowledge, artifacts, and technologies. The corporation grows from a single intern with a prototype time machine into a trillion-dollar empire spanning thousands of operatives and multiple timelines.

### Genre
- Idle / Incremental
- Management Simulator
- Single-player, PC-first

### Design Pillars
1. **Satisfying every 30 seconds** — a mission returns, a level-up happens, a resource milestone is hit within every 30-second window
2. **Data-driven** — eras, agents, research, and events are defined in JSON config files; adding content requires no code changes
3. **Zero art budget** — sci-fi terminal aesthetic (green-on-dark, CRT borders, monospace font) looks intentional and takes zero hours to produce
4. **Vertical slice over scope** — 8 polished eras beat 25 unfinished ones; polish what exists before adding more

### Target Session Profile
- **First session:** 15–30 min to unlock 3 eras and feel the loop
- **Daily return:** 5–10 min to collect offline rewards, send new missions, unlock one research node
- **Weekly depth:** Prestige reset, explore new era tier, buy a department

---

## 2. Folder Structure

```
Time Travel Corp/
├── project.godot                      # Godot project config — registers autoloads & export settings
├── autoloads/
│   ├── game_state.gd                  # Single source of truth: holds all runtime state, emits state_changed
│   ├── agent_manager.gd               # Owns agent lifecycle: hire → train → dispatch → return
│   ├── era_manager.gd                 # Owns era state: unlocks, active missions, cooldowns
│   ├── research_manager.gd            # Owns research tree: tracks unlocks, applies stat multipliers
│   ├── event_manager.gd               # Timer-driven event firing, choice resolution, outcome application
│   └── save_manager.gd                # Serialize/deserialize GameState to localStorage (web) or file (desktop)
├── data/
│   ├── eras.json                      # 8 era definitions: name, risk, rewards, unlock cost, events
│   ├── agent_tiers.json               # 10 agent tiers: title, stat ranges, promotion XP thresholds
│   ├── research_tree.json             # 35 research nodes: cost, effect type, value, prerequisites
│   └── events.json                    # 20 random events: era filter, choices, outcomes
├── scenes/
│   ├── main.tscn                      # Root scene: TabContainer holding all five UI panels
│   └── ui/
│       ├── dashboard.tscn             # Corp HQ: resource strip, stat grid, ops log, active missions
│       ├── timelines.tscn             # Era grid: browse, unlock, and launch missions
│       ├── agents.tscn                # Agent roster: hire, view stats, equip, assign missions
│       ├── research.tscn              # Research tree: unlock nodes with Knowledge
│       └── corporation.tscn           # Departments, Temporal Reset (prestige), milestones
├── scripts/
│   ├── main.gd                        # Boots game, starts tick timer, routes global signals to UI
│   └── ui/
│       ├── dashboard.gd               # Reads GameState, updates all Dashboard labels on state_changed
│       ├── timelines.gd               # Renders era cards, sends dispatch signals to EraManager
│       ├── agents.gd                  # Renders agent list, handles hire/equip/assign input
│       ├── research.gd                # Renders tree, handles unlock input
│       └── corporation.gd             # Handles department buys and prestige trigger
├── components/
│   ├── agent_card.tscn / agent_card.gd    # One agent row: name, level, status, dispatch button
│   ├── era_card.tscn / era_card.gd        # One era tile: name, risk badge, reward preview, lock state
│   └── resource_row.tscn / resource_row.gd # Animated resource counter with label and per-minute delta
└── theme/
    ├── terminal.tres                  # Godot Theme: green-on-dark, CRT border radius, monospace
    └── fonts/
        └── share_tech_mono.ttf        # Google Fonts — SIL Open Font License, Steam-safe
```

---

## 3. Architecture

### Design Rule
**GameState is the only place state lives.** Managers read config from `data/` and mutate GameState. UI scripts are read-only — they observe GameState and emit signals upward when the player takes an action. Managers respond to those signals, mutate state, emit `state_changed`. UI updates on `state_changed`.

### Autoloads

#### `game_state.gd`
```
Signals:
  state_changed()
  mission_complete(agent_id, era_id, rewards)
  event_fired(event_data)
  agent_leveled_up(agent_id, new_level)

State dictionary keys:
  resources: { credits, knowledge, artifacts, historical_data,
               temporal_energy, temporal_energy_max, influence,
               stability, reputation }
  agents: Array[Dictionary]          # see agent schema below
  eras_unlocked: Array[String]       # era IDs
  active_missions: Array[Dictionary] # { agent_id, era_id, time_remaining }
  research_unlocked: Array[String]   # node IDs
  departments: Array[String]         # department IDs
  prestige_count: int
  temporal_echoes: int
  echo_upgrades: Array[String]
  total_credits_earned: float        # lifetime, used for prestige calc
  run_start_timestamp: int           # Unix timestamp, for offline calc
  last_save_timestamp: int
```

#### `agent_manager.gd`
Loads `data/agent_tiers.json` on `_ready()`. Exposes:
- `hire_agent()` — creates new agent dict, deducts Credits, appends to GameState.agents
- `dispatch_agent(agent_id, era_id)` — validates TE available, creates active_mission entry
- `return_agent(agent_id, rewards)` — applies rewards, grants XP, checks for level-up/promotion
- `get_hire_cost()` → `200 * pow(1.5, agents.size())`
- `get_agent_stats(agent_id)` → base stats × research multipliers × equipment bonuses

#### `era_manager.gd`
Loads `data/eras.json` on `_ready()`. Exposes:
- `can_unlock(era_id)` — checks unlock cost against current resources
- `unlock_era(era_id)` — deducts cost, adds to eras_unlocked
- `tick(delta)` — decrements all active_mission timers; calls AgentManager.return_agent on completion

#### `research_manager.gd`
Loads `data/research_tree.json` on `_ready()`. Exposes:
- `can_unlock(node_id)` — checks Knowledge cost + prerequisites
- `unlock_node(node_id)` — deducts Knowledge, adds to research_unlocked, applies effect
- `get_multiplier(effect_type)` → cumulative multiplier from all unlocked nodes of that type

#### `event_manager.gd`
Loads `data/events.json` on `_ready()`. Contains a random Timer (120–300 seconds). On timeout:
- Filters events by active eras (era-specific events only fire if that era has a deployed agent)
- Picks one event at random (weighted by `weight` field)
- Emits `GameState.event_fired(event_data)`
- UI shows notification with 60-second countdown
- If no choice made in 60s: applies `default_outcome` automatically

#### `save_manager.gd`
- `save()` — serialises `GameState` dict to JSON; writes to localStorage (`JavaScriptBridge`) on web or `user://save.json` on desktop
- `load()` — reads JSON, restores GameState, calculates offline rewards
- `calculate_offline_rewards()` — `elapsed = now - last_save_timestamp` (capped at 86400); applies `elapsed × income_per_second × 0.5` for each resource; shows popup summary

### Game Tick
`main.gd` holds a `Timer` set to 1.0 second. On `timeout`:
1. `EraManager.tick(1.0)` — advance mission timers
2. `GameState.apply_passive_income()` — per-second resource gains (regen-only: TE, Stability)
3. `GameState.decay_stability()` — subtract 0.05 Stability
4. `EventManager.try_fire_event()` — rolls against event timer
5. `GameState.emit_signal("state_changed")` — all UI panels refresh

---

## 4. Economy Design

### The Eight Resources

| Resource | Symbol | Role |
|----------|--------|------|
| Credits | ₢ | Primary currency — funds everything |
| Knowledge | K | Fuels all research unlocks |
| Artifacts | A | Rare drops; research materials and secondary currency late-game |
| Historical Data | HD | Unlocks new eras (alongside Credits) |
| Temporal Energy | TE | Mission lock — 1 TE is reserved per active mission and returned on completion; cap limits simultaneous missions |
| Influence | I | Unlocks departments; reduces era risk |
| Stability | S | Global health 0–100; bad events drain it; below 30 = income penalty |
| Reputation | R | Unlocks agent tier promotions and corporation milestones |

### Resource Generation

| Resource | Source |
|----------|--------|
| Credits | Every mission return: `base × agent_efficiency × era_multiplier × research_multiplier` |
| Knowledge | Egypt, Renaissance, Cold War missions |
| Artifacts | Random drop on mission return: probability = `agent_luck` stat |
| Historical Data | All missions: small flat amount per completion |
| Temporal Energy | Regenerates at 1 TE/min base; consumed (1 TE) on mission launch; restored on return |
| Influence | High-risk mission completions; department bonuses |
| Stability | Passive regen from TS-4 research node; restored by some event choices |
| Reputation | Agent tier promotions; corporation milestones; prestige resets |

### Resource Sinks

| Resource | Consumed by |
|----------|-------------|
| Credits | Hire agents, buy equipment, unlock eras, buy departments |
| Knowledge | All research node unlocks |
| Artifacts | Late-tier research requirements; sold for Credits via RM-5 |
| Historical Data | Era unlock requirements (alongside Credits) |
| Temporal Energy | Each mission launch (1 TE); restored on return |
| Influence | Department purchases; some event choices |
| Stability | Natural decay −0.05/sec; event burst damage (−10 to −30) |
| Reputation | Agent tier unlock thresholds |

### Balance Targets

| Phase | Credits/min | Session marker |
|-------|------------|----------------|
| Start | 5–10 | 1 agent, Stone Age only |
| 5 min in | 30–50 | Egypt unlocked, 2 agents |
| 30 min in | 500–1K | 4 eras, 5 agents, first research |
| 2 hr in | 10K–50K | 6 eras, 2 departments, mid-research |
| First prestige | 1M total earned | All 8 eras seen |

Doubling time target: ~3 min early game, ~12 min late pre-prestige.

### Stability Penalty Tiers
- S ≥ 30: no penalty
- S < 30: all resource income −25%
- S < 10: missions have 20% auto-fail chance
- S = 0: all income halved, events fire 2× more frequently

---

## 5. Era Design

All values are base (before research multipliers or agent stats).

| # | Era | Date | Risk | Duration | Credits | Other Resources | Unlock Cost |
|---|-----|------|------|----------|---------|----------------|-------------|
| 1 | Stone Age | 10,000 BC | 1/5 | 30s | ×5 | HD ×2 | Start |
| 2 | Ancient Egypt | 3,000 BC | 2/5 | 45s | ×12 | K ×3, A 15% drop | 500 ₢ + 50 HD |
| 3 | Roman Empire | 100 AD | 3/5 | 60s | ×20 | I ×2, A 10% drop | 2,000 ₢ + 200 HD + 50 K |
| 4 | Medieval Europe | 1200 AD | 3/5 | 75s | ×18 | K ×5, HD ×4 | 8,000 ₢ + 500 HD |
| 5 | Renaissance | 1500 AD | 4/5 | 90s | ×30 | K ×10, I ×3 | 30,000 ₢ + 1,000 K |
| 6 | Industrial Revolution | 1850 AD | 4/5 | 2 min | ×60 | HD ×10, TE +0.5/min passive | 100,000 ₢ + 2,000 HD + 500 I |
| 7 | Cold War | 1962 AD | 4/5 | 2.5 min | ×100 | K ×20, I ×10, A 20% drop | 500,000 ₢ + 5,000 K + 1,000 I |
| 8 | Near Future | 2050 AD | 5/5 | 5 min | ×250 | TE +2/min passive, S +5 on return | 2,000,000 ₢ + 10,000 K + 10,000 HD |

**Era-specific mechanics:**
- **Cold War:** Agents can enter CAPTURED state (Agent Detected event). Requires ransom to recover.
- **Near Future:** Passive Temporal Energy bonus applies as long as an agent is deployed there, even mid-mission.
- **Stone Age:** No events ever fire here — safe tutorial sandbox.

---

## 6. Agent System

### Core Stats

| Stat | Effect | Level 1 Base | Level 100 Cap |
|------|--------|-------------|--------------|
| Efficiency | Multiplier on all resources earned | ×1.0 | ×3.0 |
| Speed | Reduces mission duration | 0% | −50% |
| Luck | Artifact drop rate + bonus event chance | 5% | 50% |
| Resilience | Reduces Stability drain from events | 0% | 60% |

Stats grow linearly per level. At each tier promotion the player chooses one stat to receive +15% permanent boost.

### Agent Tiers

| Tier | Levels | Title |
|------|--------|-------|
| 1 | 1–9 | Intern |
| 2 | 10–19 | Field Operative |
| 3 | 20–29 | Senior Operative |
| 4 | 30–39 | Time Scout |
| 5 | 40–49 | Chrono Specialist |
| 6 | 50–59 | Temporal Agent |
| 7 | 60–69 | Chrono Veteran |
| 8 | 70–79 | Elite Operative |
| 9 | 80–89 | Chrono Commander |
| 10 | 90–100 | Elite Chrono Operative |

Tiers 1–4 are reachable in one prestige cycle. Tiers 5–7 require 2–3 prestiges. Tiers 8–10 are post-MVP endgame.

### Levelling
- XP per mission: `10 × era_risk_level` (Stone Age = 10 XP, Near Future = 50 XP)
- XP to level: `level² × 50` (level 1→2 = 50 XP; level 9→10 = 4,050 XP)
- Promotion to next tier: automatic at level threshold

### Hiring
- First agent: free (named starter Intern, created in GameState initialisation)
- Additional agents: `200 × pow(1.5, agents.size())` Credits
- Agent cap: 3 base → 8 with HR Department → 10 with CE-3 → 12 with CE-5
- Names: auto-generated from historical name pool (defined in `agent_tiers.json`)

### Agent Status States
| State | Meaning | Recovery |
|-------|---------|---------|
| IDLE | Available | — |
| DEPLOYED | On mission, countdown running | Wait |
| CAPTURED | Cold War event outcome | Pay ransom (Credits + Influence) |

### Equipment (4 Slots)

| Item | Effect | Tier 1 | Tier 2 (CE-1 req) | Tier 3 (CE-6 req) |
|------|--------|--------|---------|---------|
| Temporal Scanner | +Luck | 500 ₢ | 5,000 ₢ | 50,000 ₢ |
| Chrono Shield | +Resilience | 500 ₢ | 5,000 ₢ | 50,000 ₢ |
| Efficiency Core | +Efficiency | 500 ₢ | 5,000 ₢ | 50,000 ₢ |
| Speed Accelerator | +Speed | 500 ₢ | 5,000 ₢ | 50,000 ₢ |

---

## 7. Research Tree (35 Nodes)

All costs are in Knowledge (K) unless Artifacts (A) are listed.  
Each column unlocks sequentially top-to-bottom; cross-column deps noted in parentheses.

### Time Machines (TM)
| ID | Name | Effect | Cost |
|----|------|--------|------|
| TM-1 | Mark II Prototype | Mission TE cost −20% | 100 K |
| TM-2 | Mark III Engine | Max TE cap +1 | 300 K |
| TM-3 | Quantum Stabilizer | Mission fail chance −10% | 500 K + 50 A |
| TM-4 | Dual-Core Drive | TE regen +50% | 1,000 K + 100 A |
| TM-5 | Mark IV Chrono | Max TE cap +3 | 2,000 K + 200 A |
| TM-6 | Temporal Fleet | Run 2 simultaneous missions | 5,000 K + 500 A |

### Agent Efficiency (AE)
| ID | Name | Effect | Cost |
|----|------|--------|------|
| AE-1 | Basic Training | All agents +5% Efficiency | 200 K |
| AE-2 | Field Handbook | All agents +5% Speed | 200 K |
| AE-3 | Advanced Training | All agents +10% Efficiency | 500 K (needs AE-1) |
| AE-4 | Rapid Deployment | All agents +10% Speed | 500 K (needs AE-2) |
| AE-5 | Specialist Curriculum | All agents +10% Luck | 800 K (needs AE-3) |
| AE-6 | Combat Resilience | All agents +15% Resilience | 800 K (needs AE-4) |
| AE-7 | Elite Operations | +15% Efficiency + 5% all stats | 2,000 K (needs AE-5, AE-6) |
| AE-8 | Chrono Mastery | Agent XP gain +50% | 5,000 K (needs AE-7) |

### Resource Multipliers (RM)
| ID | Name | Effect | Cost |
|----|------|--------|------|
| RM-1 | Acquisition Protocols | Credits from missions +25% | 300 K |
| RM-2 | Data Mining | Historical Data +50% | 300 K |
| RM-3 | Artifact Authentication | Artifact drop rate +10% | 500 K (needs RM-1) |
| RM-4 | Knowledge Synthesis | Knowledge from missions +30% | 500 K (needs RM-2) |
| RM-5 | Black Market Network | Sell Artifacts for 2× Credits | 1,000 K + 100 A (needs RM-3) |
| RM-6 | Historical Archives | HD from missions +100% | 1,000 K (needs RM-4) |
| RM-7 | Revenue Optimization | Credits from missions +50% | 3,000 K (needs RM-5) |
| RM-8 | Temporal Arbitrage | All resources +20% | 8,000 K + 500 A (needs RM-7, RM-6) |

### Timeline Stability (TS)
| ID | Name | Effect | Cost |
|----|------|--------|------|
| TS-1 | Paradox Dampener | Stability decay −20% | 200 K |
| TS-2 | Event Mitigation | Event Stability damage −15% | 300 K (needs TS-1) |
| TS-3 | Temporal Anchor | Stability floor raised to 20 | 500 K (needs TS-1) |
| TS-4 | Stabilizer Array | Stability regen +0.02/sec | 800 K (needs TS-2) |
| TS-5 | Quantum Buffer | Event Stability damage −30% | 1,500 K (needs TS-4) |
| TS-6 | Chrono Fortress | Stability floor raised to 40 | 3,000 K (needs TS-3, TS-5) |
| TS-7 | Temporal Immunity | Missions no longer drain Stability | 8,000 K + 300 A (needs TS-6) |

### Corporate Expansion (CE)
| ID | Name | Effect | Cost |
|----|------|--------|------|
| CE-1 | HR Optimization | Agent hire cost −20%; unlocks Tier 2 equipment | 500 K |
| CE-2 | Research Division | All research cost −25% | 500 K |
| CE-3 | Agent Cap I | Max agents +2 | 1,000 K (needs CE-1) |
| CE-4 | Department Efficiency | All dept. bonuses +25% | 1,500 K (needs CE-2) |
| CE-5 | Agent Cap II | Max agents +2 | 3,000 K (needs CE-3) |
| CE-6 | Tier 3 Equipment | Unlocks all Tier 3 gear slots | 5,000 K + 200 A (needs CE-4) |

---

## 8. Prestige System — Temporal Reset

### Trigger
Button appears in Corporation tab once `total_credits_earned ≥ 1,000,000`. Can reset at any time after.

### What Resets
Credits · Knowledge · Artifacts · Historical Data · Influence · all Agents except starter Intern · all era unlocks (Stone Age only) · all research · all departments · Stability back to 80

### What Persists
Temporal Echoes · echo_upgrades · prestige_count · total lifetime milestones · cosmetic terminal theme

### Temporal Echoes Formula
```
echoes_earned = floor(sqrt(total_credits_earned / 500_000))
              + length(eras_unlocked)
              + agents_promoted_this_run
```
Typical first reset: 12–20 Echoes. Later resets: 40–80.

### Why Players Reset
1. Each run is ~3× faster than the last due to stacking permanent bonuses
2. New CRT terminal colour theme unlocks each prestige (green → amber → white → red → blue)
3. Prestige 3 reveals a locked "Timeline Merger" button with tooltip *"Not yet. Keep growing."* — endgame hook for v1.1
4. Achievement + named agent spawns on first reset

### Prestige Upgrade Shop (15 Nodes)

| Cost (Echoes) | ID | Name | Effect |
|--------------|-----|------|--------|
| 1 | E-01 | Chrono Foundation | All income +10% permanent |
| 2 | E-02 | Temporal Memory | Start with 2 agents |
| 2 | E-03 | Echo Resonance | Echoes earned +25% on future resets |
| 3 | E-04 | Quick Start | Egypt unlocked from run start |
| 3 | E-05 | Veteran Agents | New agents start at Level 5 |
| 3 | E-06 | Stability Mastery | Start with 90 Stability |
| 5 | E-07 | Resource Cache | Start with 1,000 ₢ |
| 5 | E-08 | Knowledge Legacy | Start with 100 K |
| 5 | E-09 | Income Surge | All income +25% permanent |
| 5 | E-10 | Time Veteran | Agent XP gain +25% permanent |
| 8 | E-11 | Research Head Start | First 5 research nodes −50% cost |
| 8 | E-12 | Corporate Memory | Departments cost −20% |
| 10 | E-13 | Temporal Dynasty | All income +50% permanent |
| 12 | E-14 | Paradox Veteran | Start with TS-1 and TS-2 unlocked |
| 20 | E-15 | CEO of Time | All income ×2 permanent |

---

## 9. Random Events (20 MVP Events)

Events fire every 120–300 seconds (random). Player has 60 seconds to respond; timeout applies `default_outcome`.

Each event in `events.json` has a `trigger` field: `"any"` (always eligible), an era ID string (only eligible if an agent is deployed in that era), or a condition string such as `"stability_below_30"` (only eligible if Stability < 30). EventManager filters the eligible pool each roll using these triggers.

| ID | Name | Era filter | Choice A | Choice B | Choice C | Default |
|----|------|-----------|----------|----------|----------|---------|
| E01 | Temporal Anomaly | Any | Contain (−500 ₢, −10 S) | Study (+200 K, −25 S) | Ignore (−15 S) | Ignore |
| E02 | Corporate Spy | Any | Pay off (−2,000 ₢) | Confront (+5 I, −10 S) | Ignore (−500 K value) | Ignore |
| E03 | Government Inquiry | Any | Bribe (−5,000 ₢) | Cooperate (−30 I, +200 Rep) | Stonewall (−50 S) | Cooperate |
| E04 | Artifact Black Market | Any | Buy (−2,000 ₢, +20 A) | Investigate (+10 I) | Ignore | Ignore |
| E05 | Stability Crisis | Any (S<30) | Emergency (−1,000 ₢, +20 S) | Let it ride (−5 S) | — | Let it ride |
| E06 | Mammoth Stampede | Stone Age | Evacuate (mission +30s) | Study (+50% A this mission) | Ignore (20% fail) | Evacuate |
| E07 | Fire Discovery | Stone Age | Document (+100 K) | Participate (early return +50 ₢) | — | Document |
| E08 | Pharaoh's Interest | Egypt | Gift (−500 ₢, +50 I) | Escape (early, full rewards) | Stay (+25% rewards) | Escape |
| E09 | Pyramid Blueprint | Egypt | Acquire (+200 K, +30 A) | Leave | — | Leave |
| E10 | Tomb Curse | Egypt | Trust shield (−15 S) | Abort (no rewards, agent safe) | — | Trust shield |
| E11 | Senate Bribery | Rome | Bribe (−1,000 ₢, +20 I) | Decline | Frame rival (+10 I, −10 S) | Decline |
| E12 | Gladiator Challenge | Rome | Fight (50%: +50 Rep or −20 S) | Pay sub (−800 ₢) | Disappear (early exit) | Pay sub |
| E13 | Black Plague | Medieval | Evacuate (no rewards) | Treat (+100 K, +30 Rep, −20 S) | Shelter (+60s delay) | Shelter |
| E14 | Witch Trial | Medieval | Bribe (−1,500 ₢) | Magical escape (−15 S, early) | Confess (agent CAPTURED) | Bribe |
| E15 | Da Vinci Encounter | Renaissance | Distract (+200 K) | Show device (+500 K, −30 S) | Leave | Leave |
| E16 | Inventor's Jackpot | Renaissance | Raid (+100 A, +300 K) | Document (+200 K, +10 Rep) | — | Document |
| E17 | Factory Fire | Industrial | Extract (mission ends) | Help (+50 Rep, −20 S) | Continue (30% fail, ×1.5 if succeeds) | Extract |
| E18 | Agent Detected | Cold War | Extract (2× TE cost, safe) | Go dark (CAPTURED) | Bluff (60% safe, 40% CAPTURED) | Extract |
| E19 | Nuclear Briefcase | Cold War | Secure (+100 I, −30 S) | Report (+50 Rep, mission ends) | Ignore | Ignore |
| E20 | Future Corp Contact | Near Future | Accept (−20% TE this run, +3× K for 5min) | Counter (+10 I) | Reject | Reject |

---

## 10. Corporate Departments

Purchased once in Corporation tab. Costs Credits + Influence.

| Department | Cost | Effect |
|------------|------|--------|
| HR Department | 10,000 ₢ + 100 I | Max agents +5; hire cost −20% |
| Research Department | 15,000 ₢ + 200 K | All research node costs −25% |
| Security Department | 20,000 ₢ + 300 I | Stability decay −30%; event Stability damage −20% |
| Marketing Department | 25,000 ₢ | Credits from missions +25%; Reputation gain +20% |
| Timeline Intelligence | 50,000 ₢ + 500 I | Shows event outcomes before choosing; mission fail chance −15% |

---

## 11. Idle / Offline System

### Active Play
`main.gd` Timer fires every 1.0 second. Missions tick, resources accumulate, events roll.

### Offline Calculation
On game load, `save_manager.gd` calculates:
```gdscript
var elapsed = min(Time.get_unix_time_from_system() - last_save_timestamp, 86400)
var income_per_sec = GameState.calculate_income_per_second()
var offline_credits = elapsed * income_per_sec.credits * 0.5
# ... repeat for all resources
# Show popup: "You were away Xh Ym. Your agents collected: ..."
```

Offline penalty: **50% efficiency**. Temporal Energy is a lock, not a consumable — on load, all active missions are resolved immediately and TE is restored to its cap regardless of elapsed time.  
Events do **not** fire offline — only income accumulates.  
Maximum offline time: **24 hours** (86,400 seconds, hard cap).

---

## 12. UI Design

### Visual Style
Sci-fi terminal aesthetic: green-on-dark (`#00ff41` on `#080d08`), CRT-border panels, `Share Tech Mono` monospace font. Zero art assets required.

### Screen Layout (all screens)
```
┌─────────────────────────────────────────────────────┐
│ TOP BAR: Corp name · prestige cycle · uptime · save │
├──────┬──────────┬────────┬───────────┬──────────────┤
│ Dash │Timelines │ Agents │ Research  │ Corporation  │  ← tab bar
├─────────────────────────────────────────────────────┤
│ RESOURCE STRIP: 8 resources, value + delta/min      │
├──────────────────────────┬──────────────────────────┤
│                          │                          │
│   LEFT PANEL             │   RIGHT PANEL            │
│   (varies by tab)        │   (varies by tab)        │
│                          │                          │
├─────────────────────────────────────────────────────┤
│ BOTTOM BAR: version · status · offline cap · save   │
└─────────────────────────────────────────────────────┘
```

### Tab Content Summary
| Tab | Left panel | Right panel |
|-----|-----------|------------|
| Dashboard | Corp stat grid + operations log | Active missions + current event |
| Timelines | Era card grid (unlock / dispatch) | Selected era detail + deploy button |
| Agents | Agent roster (hire + list) | Selected agent stats + equipment |
| Research | Research tree (5 columns) | Selected node detail + unlock button |
| Corporation | Department list + buy buttons | Prestige button + Echo shop |

---

## 13. Save System

### Schema (JSON)
```json
{
  "version": 1,
  "timestamp": 1749296400,
  "resources": {
    "credits": 48230.0,
    "knowledge": 1840.0,
    "artifacts": 34,
    "historical_data": 620.0,
    "temporal_energy": 7,
    "temporal_energy_max": 10,
    "influence": 210.0,
    "stability": 64.0,
    "reputation": 88
  },
  "agents": [
    {
      "id": "agent_0",
      "name": "Ada Kowalski",
      "level": 14,
      "xp": 1200,
      "tier": 2,
      "status": "IDLE",
      "stat_boost_choices": ["efficiency"],
      "equipment": {
        "scanner": "temporal_scanner_t1",
        "shield": null,
        "core": null,
        "accelerator": null
      }
    }
  ],
  "eras_unlocked": ["stone_age", "egypt", "rome", "medieval"],
  "active_missions": [
    { "agent_id": "agent_1", "era_id": "rome", "time_remaining": 17.4 }
  ],
  "research_unlocked": ["TM-1", "AE-1", "AE-2", "RM-1", "RM-2", "TS-1", "CE-1", "CE-2"],
  "departments": [],
  "prestige_count": 0,
  "temporal_echoes": 0,
  "echo_upgrades": [],
  "total_credits_earned": 52480.0,
  "agents_promoted_this_run": 3,
  "run_start_timestamp": 1749280000,
  "last_save_timestamp": 1749296400
}
```

### Platform Strategy
- **Web export:** `JavaScriptBridge.eval("localStorage.setItem('ttc_save_v1', '" + json + "')")`
- **Desktop export:** `FileAccess.open("user://save.json", FileAccess.WRITE)`
- Auto-save: every 30 seconds via a separate Timer in `main.gd`
- Manual save: button in Corporation tab

---

## 14. Installation & Setup Guide

### Step 1: Download Godot 4
1. Go to [godotengine.org](https://godotengine.org)
2. Download **Godot Engine 4.x** (not Mono / .NET unless you want C#)
3. Unzip — Godot is a single `.exe`, no installation needed
4. Double-click to launch

### Step 2: Create the Project
1. In the Godot Project Manager, click **New Project**
2. Name it `Time Travel Corp`
3. Set the project path to `C:\Users\georg\OneDrive\Desktop\Projects\Time travel Corp`
4. Renderer: **Compatibility** (required for HTML5 web export)
5. Click **Create & Edit**

### Step 3: Configure Autoloads
In Godot: **Project → Project Settings → Autoload**  
Add each file in this order:
```
autoloads/game_state.gd      → name: GameState
autoloads/agent_manager.gd   → name: AgentManager
autoloads/era_manager.gd     → name: EraManager
autoloads/research_manager.gd → name: ResearchManager
autoloads/event_manager.gd   → name: EventManager
autoloads/save_manager.gd    → name: SaveManager
```

### Step 4: Web Export Setup
In Godot: **Project → Export → Add → Web**  
- Check **Export with Debug** off for release
- Check **Head Include** — add `<meta name="viewport" content="width=device-width, initial-scale=1">` for itch.io

---

## 15. MVP Roadmap — 30 Days

### Week 1 — Foundation (Days 1–7)
- **Day 1:** Godot setup, create folder structure, create all empty `.gd` files and `.tscn` scenes
- **Day 2–3:** `game_state.gd` initialisation + `save_manager.gd` (save/load to localStorage working)
- **Day 4–5:** Game tick loop in `main.gd`; resource generation applying per second
- **Day 6–7:** Stone Age mission working end-to-end: dispatch agent → countdown → return → resources awarded

### Week 2 — Core Loop (Days 8–14)
- **Day 8–9:** `eras.json` loaded; all 8 eras unlock-able; era card components rendering
- **Day 10–11:** Full agent system: hire, level-up, tier promotion, equipment slots
- **Day 12–13:** `research_tree.json` loaded; all 35 nodes unlock-able with correct prerequisites
- **Day 14:** All 5 UI tabs functional (not polished, but interactable)

### Week 3 — Systems (Days 15–21)
- **Day 15–16:** Event system: `events.json` loaded, notification overlay, 60s timer, choice application
- **Day 17–18:** Prestige system: Temporal Reset flow, Echo calculation, Echo upgrade shop
- **Day 19–20:** All 5 departments purchasable with correct effects applied
- **Day 21:** Offline reward calculation + popup on game load

### Week 4 — Polish (Days 22–28)
- **Day 22–23:** Terminal theme applied (`terminal.tres`), Share Tech Mono font, CRT borders everywhere
- **Day 24–25:** Operations log (scrolling feed), resource delta display (+X/min labels)
- **Day 26:** Agent card and era card components fully styled
- **Day 27:** Browser export test on itch.io; save/load regression testing
- **Day 28:** Balance pass — adjust unlock costs, mission durations, income rates against targets

### Days 29–30 — Release Prep
- **Day 29:** itch.io page live; browser build uploaded; short gameplay GIF recorded
- **Day 30:** Steam store page drafted; feature list finalised; roadmap for v1.1 written

---

## 16. Steam Store Description

**Short description (30 words):**  
Run the world's first time travel corporation. Send agents through history, collect priceless artifacts, fund research, and build a trillion-dollar empire across time.

**Long description:**
```
TIME TRAVEL CORPORATION

You're the CEO of the world's only legal time travel operation.
Your agents travel to ancient Egypt, the Roman Senate, Cold War spy networks, 
and the near future — extracting resources, knowledge, and artifacts that 
would be worth billions in the present.

HIRE AND TRAIN AGENTS
From fresh-faced Interns to Elite Chrono Operatives, your team grows 
across 10 career tiers. Each agent earns XP on every mission, levels up, 
and can be equipped with temporal gear that changes how they operate.

SEND MISSIONS THROUGH TIME
8 historical eras, each with distinct risks and rewards. Stone Age is safe 
and steady. The Cold War is dangerous but lucrative. The Near Future is 
nearly impossible — and worth every Credit.

RESEARCH THE TIMELINE
A 35-node research tree lets you improve your time machines, 
boost your agents, multiply your income, and stabilise your corporate 
footprint across history.

MAKE HISTORY-CHANGING DECISIONS
20 hand-crafted random events with real consequences. A Roman senator wants 
a bribe. Da Vinci is asking questions. Your agent has been spotted by Cold 
War intelligence. Choose carefully — the timeline depends on it.

RESET. GROW. REPEAT.
The Temporal Reset prestige system lets you restart with permanent bonuses, 
new cosmetic terminal themes, and hints at a far larger endgame. Each run 
is faster, richer, and deeper than the last.

RUNS IN YOUR BROWSER
No download required. Play on itch.io instantly.
```

---

## 17. Feature List — Version 1.0

- [ ] 8 unlockable historical eras from Stone Age to Near Future
- [ ] 8 resource types with distinct generation, sinks, and interactions
- [ ] Agent system: hire, level (1–100), 10 career tiers, stat boost on promotion
- [ ] 4 equipment slots per agent with 3 upgrade tiers each
- [ ] 35-node research tree across 5 categories
- [ ] Temporal Reset prestige with 15 permanent upgrade nodes
- [ ] 20 hand-crafted random events with meaningful choices and 60-second timers
- [ ] 5 corporate departments with unique bonuses
- [ ] Offline progression up to 24 hours with reward popup
- [ ] Auto-save every 30 seconds (localStorage on web, file on desktop)
- [ ] Sci-fi terminal / CRT aesthetic — zero art assets
- [ ] 5 cosmetic terminal colour themes unlocked via prestige
- [ ] Operations log — scrolling feed of mission returns, events, level-ups
- [ ] Stability system — global health metric with income penalties
- [ ] Browser export (itch.io) + Desktop export (Steam)
