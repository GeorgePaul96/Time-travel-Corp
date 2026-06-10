# TIME TRAVEL CORP — GAME DESIGN DOCUMENT
**Version 1.0 | June 2026**

---

## CONTEXT & CONSTRAINTS

| Factor | Detail |
|---|---|
| Developer | Solo, first commercial release |
| Dev pace | 5–10 hrs/week (~30 hrs/month) |
| Platform | Steam PC (Windows primary) |
| Art direction | Retro-industrial amber CRT terminal |
| Art execution | AI-assisted (Midjourney/Stable Diffusion) |
| Realistic ship window | 18–24 months from now |
| Target price | $6.99 |

Everything in this document is calibrated to these constraints. A feature that makes sense for a 5-person team in 6 months is often the wrong feature for a solo dev in 18 months.

---

## PHASE 1 — GAME DESIGN AUDIT

### Current Core Loop

```
Deploy extractors → Generate capital → Watch stability decline
→ Mutation crisis → Patch or let run → Prestige for anomalies
→ Buy permanent upgrades → Repeat
```

### What Is Already Fun

- **The cascade mechanic.** Antiquity's stability affecting Middle Ages, which affects Industrial, which affects Future — this creates genuine strategic interdependency. It is the single best idea in the prototype and not commonly found in idle games at this level.
- **Push-your-luck tension.** "How many extractors can I stack before the timeline collapses?" is a real decision with real consequences.
- **Mutation as crisis event.** The moment a node hits 0 stability and transforms creates urgency and demands active response.
- **Energy as a pacing resource.** The energy cost for extractors and patching creates genuine opportunity cost decisions.

### What Is Currently Repetitive

- **All 4 nodes play identically.** Deploying an extractor to Antiquity and deploying one to Future is the same action with different numbers. No differentiation in mechanics or feel.
- **Mutation response is always the same.** See mutation → spend 50 energy to patch. No decision space.
- **Only 3 upgrades.** Three upgrades in the prestige shop means runs have no distinct identity. Every prestige is the same as the last.
- **No session-level goals.** Nothing tells the player what to do this session. Opening the game after a day away offers no direction.

### Missing Systems

1. **Era-specific mechanics** — each era should play differently, not just scale differently
2. **Meaningful research/upgrade tree** — enough nodes to create distinct run strategies
3. **Narrative voice** — the corporate satire premise is completely absent in the prototype
4. **Visual urgency states** — stability decline doesn't feel dangerous enough
5. **Session goals** — daily objectives or missions to give short sessions direction
6. **Endgame** — no destination, no conclusion, no reason to stop pressing the button except boredom

### Weak Systems

- **Prestige** — currently underdelivers. Resetting for 3 upgrades doesn't feel meaningful. Needs more spending options and a progression milestones layer.
- **Energy** — with energy regen upgrades, energy becomes trivial quickly. Needs tiered costs to remain relevant.
- **Upstream penalties** — the downstream stability drain from upstream mutations is the right idea but currently too subtle to feel strategically important.

### Biggest Commercial Risks

1. **No visual identity.** The prototype has no style. On Steam you have ~3 seconds to earn a wishlist. Without the amber CRT aesthetic in place, there is no commercial product here.
2. **No hook sentence.** The game is hard to describe in one line because the differentiating mechanic (the cascade) is invisible from screenshots.
3. **No narrative layer.** Idle games that sell consistently have a satirical or narrative voice (Universal Paperclips, Cookie Clicker, A Dark Room, Idle Civilization). A purely mechanical game without voice is harder to recommend socially.
4. **Content thinness.** 4 mechanically identical nodes won't sustain 10+ hours, let alone the 20+ hours needed for positive word-of-mouth.
5. **First-time dev overhead.** Steam page, trailer, builds, reviews, launch timing — none of this is in a prototype budget. Plan for it explicitly.

### Biggest Design Risks

1. **Feature creep from Phase 4's system list.** Time Agents, Sabotage, Temporal Market, Historical Corporations — any two of these added to v1 will likely kill the project timeline.
2. **The "just another idle game" trap.** Without a clear differentiator, the game lands in a market where Cookie Clicker, Universal Paperclips, and Kittens Game are free alternatives.
3. **Idle vs. Active identity crisis.** The game currently needs to decide: do players manage it actively, or does it run while they work? This determines automation depth, session design, and pacing. Both answers are valid; uncommitted answers are fatal.

### The 20-Minute vs. 20-Hour Question

**Why someone plays for 20 minutes right now:**
The cascade mechanic fires, a mutation creates panic, the energy system creates some decision-making.

**Why they stop at 20 minutes:**
No goals. No surprises after the first mutation. No narrative pull. Every era is the same button.

**What would make someone play for 20 hours (currently absent):**
- Era-specific mechanics that create genuinely different strategic problems
- A research tree where this run feels different from last run
- Corporate memo events that make them laugh and want to see the next one
- An escalating late-game crisis that feels like an actual climax
- Daily objectives that give short sessions a concrete purpose

**Verdict:** This is currently a 20-minute game built on a 20-hour foundation. The cascade mechanic is the spine. Everything else needs to be built around it.

---

## PHASE 2 — DESIGN PILLARS

### Pillar 1: The Cascade
**Why it exists:** The upstream/downstream stability chain is the most interesting mechanic in the prototype and the thing no competitor has. Antiquity mutating should feel like a slow-motion disaster unfolding across all of history.

**What mechanics support it:**
- Upstream mutations accelerating downstream stability drain (already exists, needs visual emphasis)
- The FOUNDATION mechanic (Antiquity stable = production bonus for all nodes)
- Research upgrades that strengthen or partially sever connections
- Visual representation: the timeline web drawing connections that pulse with instability

**What must NOT be added:**
- "Quarantine" abilities that permanently sever node connections — kills the interdependency
- Per-node isolation upgrades that make nodes fully independent — the tension IS the chain
- Event systems that treat each node as independent — all events should reference the web

---

### Pillar 2: Corporate Satire
**Why it exists:** "Time Travel Corp" is inherently absurdist. A faceless corporation exploiting all of human history for quarterly earnings is dark comedy gold. Without this voice, it's a numbers game with historical wallpaper. With it, it becomes a game people quote to friends.

**What mechanics support it:**
- All story events written as corporate memos, performance reviews, and HR advisories
- Upgrade names in corporate doublespeak ("Stakeholder Temporal Alignment Protocol")
- Mutation event descriptions framed as internal incident reports ("Re: Anomaly in Sector ANTIQUITY. The Board is monitoring.")
- Corporation rank titles players earn through prestige milestones
- Tutorial delivered as corporate onboarding packet

**What must NOT be added:**
- Serious worldbuilding or lore that competes with the satire
- Grim dark tone — this is Fallout Vault-Tec, not 1984
- Heavy narrative cutscenes or dialogue trees — flavor text only, never blocking

---

### Pillar 3: Push Your Luck
**Why it exists:** The best idle game sessions end with "I pushed it too far." That regret/satisfaction cycle is the core emotional loop. Every session should contain at least one moment where the player chose greed and paid for it, or pulled back just in time.

**What mechanics support it:**
- Stability drain that accelerates non-linearly with more extractors
- Higher anomaly output from low-stability nodes (reward for risk)
- Visual urgency when stability drops below 30%
- "Unstable Extraction" research that boosts output at critical stability levels

**What must NOT be added:**
- Undo buttons or rollback mechanics for stability collapse
- Full insurance systems that guarantee recovery without cost
- Auto-patch automation available from the start — it must be earned and feel like giving up control

---

### Pillar 4: Satisfying Escalation
**Why it exists:** An idle game that doesn't show you how far you've come doesn't keep players. Each era should feel meaningfully harder to control and more rewarding to extract from. Each prestige should reveal something new.

**What mechanics support it:**
- Tiered resource output per era (1x, 2x, 5x, 10x base rates)
- Tiered energy costs per era (deploying to Future costs 4x what Antiquity costs)
- Prestige milestone unlocks (new research branches, new event categories, new era mechanics)
- Corporation rank as visible progress marker

**What must NOT be added:**
- Flat linear scaling where each era is just "more of the same at a higher number"
- A new era every update that dilutes the depth of existing ones
- Power scaling so fast that early eras become irrelevant — Antiquity should remain strategically meaningful at prestige 50

---

### Pillar 5: Readable Complexity
**Why it exists:** Strategy games die when the player doesn't understand why something happened. The amber CRT aesthetic implies "reading data from a corporate terminal" — lean into that. Every mechanic must be immediately legible from the UI.

**What mechanics support it:**
- Clear visual hierarchy: stability bar is the dominant element per node
- Consistent color language: green = stable, amber = warning, red = crisis
- Tooltip system on every number and every upgrade
- Tutorial that explains the cascade explicitly within the first 5 minutes

**What must NOT be added:**
- Hidden multipliers with no UI representation
- Mechanics that interact across nodes invisibly
- Information density that requires external guides to optimize

---

### Pillar 6: Short Session Respect
**Why it exists:** At hobby development pace, this game will serve players who open it for 10 minutes before bed. Those sessions must feel worth having. This pillar is also a development constraint: build features that deliver value in 10 minutes, not just in 2-hour sessions.

**What mechanics support it:**
- Daily objectives (3 per day) that give each session a concrete 10-minute goal
- Offline progress that makes opening the game after a break feel rewarding
- The first meaningful decision should occur within 60 seconds of opening
- Visual state on load that immediately communicates "here's what changed since you left"

**What must NOT be added:**
- Mechanics requiring sustained 30+ minute active attention to resolve
- Cooldowns that force players to wait for anything interesting to happen
- Online connectivity requirements

---

## PHASE 3 — GAME VISION

### Positioning Statement

> You are the newly appointed CEO of Time Travel Corp. Quarterly earnings are below forecast. The Board has authorized unrestricted extraction across all historical epochs. Deploy your extractors, harvest human history, and file your reports on time. Paradox is not a recognized line item.

**Genre:** Incremental strategy game with idle elements
**Platform:** Steam PC (Windows, Mac secondary)
**Session length:** 5–30 minutes active; meaningful idle progress between sessions
**Monetization:** One-time purchase. No DLC, no IAP, no battle pass.
**Target price:** $6.99

### Art Direction

Amber phosphor-on-black CRT terminal. The entire game is rendered as a corporate management dashboard on aging hardware. Each era gets a distinct accent color within the amber palette. Scanline and phosphor glow shaders applied subtly — present but not fatiguing. UI elements use industrial gauges, oscilloscope readouts, and teletype-style text. AI-generated era illustrations appear only in story event popups — 8–12 images total at launch, each framed as a "field report photograph." No character sprites. No overworld map. This is a dashboard, not a world.

### Unique Selling Points

1. **The Cascade** — timeline instability propagates upstream-to-downstream across connected eras. No comparable idle game has this strategic interdependency.
2. **Corporate satirical voice** — every mechanic is framed as boardroom comedy. The game knows what it is and leans in.
3. **Push-your-luck strategy** — active decisions under pressure, not passive number watching.
4. **Aesthetic identity** — the amber CRT corporate terminal is visually distinctive and screenshot-friendly.

### Differentiation

| Game | What it does | How Time Travel Corp differs |
|---|---|---|
| Universal Paperclips | Narrative-driven one-playthrough idle | Replayable, systems-driven, no single-story arc |
| Cookie Clicker | Pure number ascension, minimal decisions | Genuine risk/consequence via cascade, strategic choices |
| Kittens Game | Extreme depth, steep learning curve | More accessible, tighter session design, stronger voice |
| Factorio | Spatial logistics, high complexity | No spatial layer, 10-minute sessions viable |
| Idle Planet Miner | Passive resource optimization | Active crisis management, mutation decisions |
| TimeWarpers | Upgrade optimization focus | Instability management as primary mechanic, not upgrade shopping |

---

## PHASE 4 — CORE SYSTEMS ROADMAP

### System 1: Resource Economy
**Purpose:** Provides growth feedback and spending decisions
**Player motivation:** Numbers increasing, feeling of growing power
**Progression path:** Capital accumulates → spent on research → prestige for anomalies → permanent upgrades

**Resources at launch:**

| Resource | Source | Spent on | Inflation risk |
|---|---|---|---|
| Capital | Extractors on stable nodes | Research (new), extractor costs | HIGH — needs sinks |
| Energy | Passive regen + upgrades | Extractors, patching | LOW — naturally consumed |
| Anomalies | Prestige conversion + mutated nodes | Prestige shop upgrades | MEDIUM |
| Temporal Essence *(new)* | Industrial mutation (DIESEL WASTES) | High-tier research nodes | LOW — rare source |

**Capital sinks to add:**
- Research node purchases (flat costs: 50 / 150 / 400 / 1000 / 2500)
- "Temporal Insurance" — spend capital for a 30-second stability drain reduction
- Extractor deployment costs a small capital amount in addition to energy

**Verdict: ESSENTIAL**

---

### System 2: Timeline Stability
**Purpose:** Core risk/tension mechanic
**Player motivation:** Avoiding cascade collapse
**Progression path:** Manual panic response → research improves regen → automation handles routine cases

**Missing:** Visual urgency states. When stability < 30%, the entire node card should pulse amber. When < 10%, red flicker. This is critical for the push-your-luck emotional loop to work.

**Verdict: ESSENTIAL — needs visual polish more than mechanical expansion**

---

### System 3: Mutations
**Purpose:** Crisis events, decision pressure, era identity
**Player motivation:** Interesting problem + secondary resource opportunity (is it ever worth letting one run?)

Each era needs a unique mutation that creates a different strategic decision:

| Era | Mutation Name | Effect | Anomaly Rate | Strategic question |
|---|---|---|---|---|
| Antiquity | PRIMAL CHAOS | All nodes lose stability 2× faster | 1.5/s/extractor | Patch immediately — chain damage is catastrophic |
| Middle Ages | DARK AGE | Extractor output ÷2, anomaly gen ×3 | 4/s/extractor | Let it run? High anomaly reward for giving up capital |
| Industrial | DIESEL WASTES | Generates Temporal Essence; costs 75 energy to patch | 2/s + essence | Worth letting run to farm essence for research |
| Future | SINGULARITY | Can spread to ANY node (not just downstream) | 8/s/extractor | Never let this run — threat is too systemic |

**Verdict: ESSENTIAL — expand from current identical mutations to 4 distinct types**

---

### System 4: Research Tree
**Purpose:** Run differentiation, replayability, meaningful long-term choices
**Player motivation:** "This run I'm going full Exploitation branch"

**Three branches, 5–6 nodes each (15–18 nodes total at launch):**

**Extraction Branch** (boost output, increase risk)
- Aggressive Extraction: +20% capital output, +10% stability drain
- Overclocked Extractors: +1 max extractor per node
- Cascade Harvesting: +15% output when upstream node is mutated
- Redundant Drill Array: extractors survive a mutation event (don't auto-remove)
- Industrial Capacity: Future extractors cost 2 less energy

**Containment Branch** (stability, safety)
- Temporal Dampeners: −15% stability drain per extractor
- Emergency Protocols: auto-patch triggers at 15% stability (requires manual activation each session)
- Paradox Insurance: first mutation each prestige costs 0 energy to patch
- Cascade Isolators: upstream mutation penalty reduced 50%
- Temporal Bedrock: Antiquity stability cannot drop below 20% (removes FOUNDATION fragility)

**Exploitation Branch** (anomalies, mutations)
- Anomaly Harvesting: +25% anomaly gen from mutated nodes
- Paradox Farming: Temporal Essence from ALL mutations (not just Industrial)
- Controlled Collapse: can trigger a manual mutation for half the anomaly rate (no stability damage)
- Cascade Amplifier: each downstream mutated node boosts anomaly gen by 15%
- Temporal Arbitrage: convert excess capital to anomalies at a 500:1 rate

**Research costs:** Each branch has 5 nodes at costs 50 / 150 / 400 / 1000 / 2500 capital. Branch 3 nodes require Temporal Essence in addition to capital.

**Verdict: ESSENTIAL — this is the highest-priority missing system**

---

### System 5: Automation
**Purpose:** Reward mastery, enable idle sessions
**Player motivation:** "I've earned the right to step back"

**Automation unlocks (via research, not available from start):**
1. **Auto-Patch** (Containment Branch, Node 2): patches automatically when stability hits threshold
2. **Auto-Extractor** (Extraction Branch, Node 3): redeploys extractors after a mutation is resolved
3. **Offline Progress**: calculates resource generation during away time (capped at 8 hours)

**Rule:** Automation reduces micromanagement but must never remove the player's ability to do better by paying attention.

**Verdict: ESSENTIAL for idle viability**

---

### System 6: Prestige / Rebirth
**Purpose:** Long-term loop, replayability driver
**Player motivation:** "Start over but meaningfully stronger"

**Expanded prestige at launch:**

- **Trigger:** Manual — player initiates prestige when ready. No forced resets.
- **Conversion formula:** `anomalies_gained = floor(sqrt(capital / 100))` — soft curve, slows prestige farming without hard-capping
- **Carry-forward:** Anomalies, Temporal Essence, Research unlocks (partial — top tier resets)
- **Corporation Rank:** Tracks total prestige count. 10 tiers from "Temporal Intern" to "Chrono-Executive". Each rank unlocks a cosmetic or passive bonus.

**Prestige shop expansion (from 3 to 12 items):**

| Item | Cost | Effect |
|---|---|---|
| Stability Regen I | 5 anomalies | +0.2 base regen |
| Stability Regen II | 15 | +0.5 base regen |
| Energy Regen I | 5 | +2/s energy regen |
| Energy Regen II | 15 | +5/s energy regen |
| Production Bonus I | 10 | +10% all output |
| Production Bonus II | 30 | +25% all output |
| Cascade Dampener | 20 | Upstream penalty −25% |
| Starting Capital | 8 | Begin each run with 500 capital |
| Mutation Delay | 25 | +20 seconds before stability can reach 0 |
| Energy Cap+ | 12 | +50 max energy |
| Temporal Insight | 40 | See estimated time-to-mutation for each node |
| Paradox Memory | 50 | Retain one research node across prestige |

**Verdict: ESSENTIAL — current prestige is too thin to sustain replayability**

---

### System 7: Story Events
**Purpose:** Narrative voice, player delight, social sharing moments
**Player motivation:** "What does the memo say this time?" — creates narrative pull across sessions

**Format:** Corporate memo popup triggered by game events. Short (2–4 sentences), darkly funny, written in HR/legal doublespeak. Each event has a small resource effect attached.

**Event categories:**
- **Mutation Incident Reports** (one per era mutation type)
- **Prestige Review Letters** (one per prestige milestone tier)
- **Quarterly Earnings Summaries** (triggered by capital thresholds)
- **Board Directives** (triggered by unlocking research nodes)
- **Field Correspondent Updates** (triggered by first extractor deployment to each era)

**Target at launch:** 40 events. At ~15 minutes each to write and implement, that's ~10 hours of dev time for content that adds 15–20 hours of player entertainment. Highest ROI feature in the entire document.

**Example event (Antiquity PRIMAL CHAOS):**
> **INCIDENT REPORT — REF: TC-ANT-007**
> Temporal extraction activities in the ANTIQUITY sector have resulted in what the indigenous population is describing as "the dissolution of reality." The Board notes this characterisation is technically accurate but commercially premature. Recommend continued extraction pending legal review. Anomaly generation is up 47% this quarter.

**Verdict: ESSENTIAL — single cheapest high-impact feature on the list**

---

### System 8: Historical Corporations
**Purpose:** Run archetypes, alternate starting conditions, replayability layer
**Player motivation:** "This run, I'm playing as The Chaos Corp"

Three starting archetypes (Extraction Corp, Containment Corp, Exploitation Corp) with different passive modifiers.

**Verdict: NICE TO HAVE — post-launch. Too much balance complexity for v1.**

---

### System 9: Time Agents
**Purpose:** Active gameplay unit management layer
**Verdict: CUT. This is a different game. Adding units to manage violates Short Session Respect and Readable Complexity simultaneously. Never build this for v1.**

---

### System 10: Sabotage
**Purpose:** Competitive or self-challenge layer
**Verdict: CUT as a standalone system. The SINGULARITY mutation already provides organic sabotage. If self-sabotage mechanics are needed, frame them as Exploitation Branch research, not a separate system.**

---

### System 11: Temporal Market
**Purpose:** Dynamic resource exchange, trade between eras
**Simplified viable version:** A static exchange interface — spend 200 Capital from any era to gain 20 Energy. This adds a useful decision without requiring dynamic pricing.
**Verdict: NICE TO HAVE — implement only as a simple exchange button in the UI, not a full market system. Can add in Month 4 if ahead of schedule.**

---

### System 12: Achievements
**Purpose:** Retention goals, Steam integration, discovery
**Player motivation:** Checklist completion, earning Steam cards, secret hunting

**20 achievements at launch, including:**
- Standard: First prestige, 10 prestiges, first mutation, all 4 mutations triggered
- Milestone: Reach Corporation Rank 5, unlock all research branches
- Challenge: Survive a SINGULARITY without patching, reach prestige without patching any mutation
- Secret: Trigger all 4 mutations simultaneously, let Antiquity hit 0 stability

**Dev cost:** Low. Build alongside prestige/mutation systems. Never ship without this.

**Verdict: ESSENTIAL**

---

### System 13: Daily Missions
**Purpose:** Session goals, short-term retention
**Player motivation:** "What do I do today?"

**Format:** 3 daily objectives drawn randomly from a pool of 30. Soft reset at midnight.

**Example objectives:**
- "Extract 1,000 Capital from Antiquity"
- "Survive a SINGULARITY mutation"
- "Complete a prestige in under 10 minutes"
- "Have all 4 nodes simultaneously active for 3 minutes"
- "Generate 50 Temporal Essence"
- "Reach Stability < 15% on all nodes simultaneously and survive"

**Verdict: STRONG ADDITION — build in Month 5**

---

### System 14: Endgame
**Purpose:** Give the game a destination. Without an ending, Steam reviews will say "runs out of content."
**Player motivation:** "Something to work toward"

**The Temporal Collapse Event:**
Triggered after reaching Corporation Rank 8 (requires ~25+ prestiges). A corporation-wide crisis activates: all 4 nodes begin losing stability simultaneously with no passive regen. The player has 10 minutes to generate a target anomaly threshold (e.g., 5,000 anomalies) before full timeline collapse. Success: "Controlled Collapse" — massive anomaly reward, new rank unlocked. Failure: full reset with a consolation anomaly bonus.

This gives the game a climactic late-game experience without requiring infinite content.

**Verdict: ESSENTIAL — games without endings feel abandoned**

---

## PHASE 5 — DEVELOPMENT PHASES

*At 5–10 hrs/week (avg 7.5), budget: ~30 hrs/month.*

### Phase A — Vertical Slice (Months 1–4, ~120 hrs)
**Goal:** A stranger can pick this up and play it enjoyably for 1–2 hours.

**Build:**
- [ ] Visual identity: amber CRT aesthetic, scanlines, phosphor shader, stability urgency states
- [ ] Era-specific mechanics (FOUNDATION, FEUDAL CHAIN, INDUSTRIAL CAPACITY, RECURSIVE LOOP)
- [ ] 4 distinct mutations with unique behaviors
- [ ] Temporal Essence as 4th resource
- [ ] Tiered extractor energy costs per era
- [ ] Research tree: 3 branches, 15 nodes, capital as cost
- [ ] Expanded prestige shop (12 items)
- [ ] Corporation rank system (10 tiers)
- [ ] Tutorial: corporate onboarding memo
- [ ] 20 story events

**Delay:**
- Daily missions
- Achievements
- Sound design
- Endgame event

**Playtesting goal:** Do strangers understand the cascade without being told? Does each era feel different? Is the first prestige satisfying?

---

### Phase B — Early Access Candidate (Months 5–10, ~180 hrs)
**Goal:** 5–10 hours of content. Compelling Steam page. First real player feedback.

**Build:**
- [ ] Daily objectives system
- [ ] 20 additional story events (40 total)
- [ ] Endgame: Temporal Collapse event
- [ ] 20 Steam achievements
- [ ] Sound design: ambient industrial sounds, UI events, mutation SFX
- [ ] Offline progress calculation
- [ ] Research tree expanded to 18 nodes
- [ ] AI-generated era illustrations (8 images) for event popups
- [ ] Steam page assets: capsule art, 5 screenshots, short trailer
- [ ] Balance pass based on playtester data

**Delay:**
- Historical Corporations
- Mac build

**Playtesting goal:** Would a stranger pay $6.99 for this? Do sessions feel different from each other?

---

### Phase C — Steam Release (Months 11–18, ~210 hrs)
**Goal:** Polished, complete, commercially defensible product.

**Build:**
- [ ] Full story events (50+ total)
- [ ] Polish pass: animations, transitions, visual feedback
- [ ] Accessibility: font size slider, reduced motion, contrast modes
- [ ] Mac build
- [ ] Steam Cloud saves
- [ ] Press kit
- [ ] Steam page live (3 months before release date for wishlists)
- [ ] Launch trailer (gameplay capture + licensed ambient music)
- [ ] Full balancing pass
- [ ] Community engagement: devlog, forums, visibility posts

**Cut if behind schedule (add post-launch):**
- Mac build
- Steam Cloud saves
- Accessibility options

**Playtesting goal:** Is the first hour onboarding smooth? Does the endgame feel climactic?

---

### Phase D — Post Launch (Month 19+)
*Based on commercial reception.*

**If successful (>500 reviews within 3 months):**
- Historical Corporations (3 archetypes)
- Tier 2 eras (Renaissance, Classical Age, Cold War)
- Expanded prestige shop
- Steam Trading Cards application

**If struggling:**
- Balance patches based on negative review feedback
- QoL improvements from community requests
- Discounting strategy (33% off at 6 months)
- Curator Connect outreach

**Never build regardless of success:**
- Time Agents
- Multiplayer/Sabotage as standalone system
- Mobile port (different design contract)
- 10+ eras at launch-equivalent depth

---

## PHASE 6 — CONTENT ROADMAP

### Tier 1 Eras — Launch (4 eras)

---

**ANTIQUITY**
*"Everything that follows depends on this."*

| Attribute | Value |
|---|---|
| Flavor resource name | Tribute |
| Base production | 1.0/s per extractor |
| Stability drain | 1.5/extractor/s (slowest) |
| Max extractors | 3 |
| Energy cost per extractor | 5 |

**Unique mechanic — FOUNDATION:** While Antiquity is stable (>50% stability), all nodes gain +10% production bonus. This makes Antiquity worth protecting even when it offers the lowest raw output.

**Mutation — PRIMAL CHAOS:**
- Effect: All connected nodes lose stability at 2× normal rate
- Anomaly rate: 1.5/s per active extractor
- Patch cost: 50 energy (standard)
- Strategic question: Patch immediately — the cascade damage to all nodes is catastrophic

**Event hook:** "The dissolution of temporal cohesion in ANTIQUITY has led to what indigenous observers describe as 'the gods walking among men.' Our legal team has reviewed the footage and finds no actionable IP infringement."

---

**MIDDLE AGES**
*"Faith, plague, and excellent margins."*

| Attribute | Value |
|---|---|
| Flavor resource name | Tithe |
| Base production | 2.0/s per extractor |
| Stability drain | 2.0/extractor/s |
| Max extractors | 3 |
| Energy cost per extractor | 8 |

**Unique mechanic — FEUDAL CHAIN:** If Antiquity is mutated, each Middle Ages extractor costs +3 extra energy to deploy. Forces upstream awareness.

**Mutation — DARK AGE:**
- Effect: Extractor output halved; anomaly generation tripled
- Anomaly rate: 6.0/s per active extractor
- Patch cost: 50 energy (standard)
- Strategic question: Genuinely worth letting run if you need anomalies and can afford the capital loss. The highest-reward voluntary mutation.

**Event hook:** "Field correspondents report that the local population has begun worshipping the extraction equipment as divine artifacts. HR reminds all staff that unauthorized deity status requires Board approval and a standard licensing agreement."

---

**INDUSTRIAL AGE**
*"Progress. Efficiency. Acceptable casualties."*

| Attribute | Value |
|---|---|
| Flavor resource name | Output |
| Base production | 5.0/s per extractor |
| Stability drain | 3.0/extractor/s |
| Max extractors | 5 (unique — highest capacity) |
| Energy cost per extractor | 12 |

**Unique mechanic — INDUSTRIAL CAPACITY:** Industrial can hold 5 extractors vs. the standard 3. Highest total output ceiling but fastest total stability drain.

**Mutation — DIESEL WASTES:**
- Effect: Stops capital production; generates Temporal Essence instead of standard anomalies
- Temporal Essence rate: 0.5/s per active extractor
- Patch cost: 75 energy (elevated — harder to clear)
- Strategic question: The only voluntary mutation that makes strategic sense regularly. Temporal Essence is required for Branch 3 research upgrades.

**Event hook:** "Temporal contamination has introduced anachronistic diesel combustion technology to the Bronze Age. The resulting air quality metrics are well within acceptable parameters as defined by our 1987 regulatory filing."

---

**FUTURE**
*"It's not illegal if it hasn't been invented yet."*

| Attribute | Value |
|---|---|
| Flavor resource name | Data |
| Base production | 10.0/s per extractor |
| Stability drain | 5.0/extractor/s (fastest) |
| Max extractors | 3 |
| Energy cost per extractor | 20 |

**Unique mechanic — RECURSIVE LOOP:** Each active Future extractor grants +5% production to ALL other active extractors globally. One extractor gives a 5% global bonus; three give 15%. This makes Future powerful as a multiplier even without heavy direct investment.

**Mutation — SINGULARITY:**
- Effect: Can spread to any node (not just downstream), at random
- Anomaly rate: 8.0/s per active extractor
- Patch cost: 50 energy (standard) but if not patched within 60 seconds, spreads
- Strategic question: Never let this run. The spread risk to Antiquity is catastrophic.

**Event hook:** "An artificial general intelligence has emerged spontaneously in the FUTURE sector and has requested union representation. The Board's position is that sapience is not a recognized employment classification under current temporal jurisdiction."

---

### Tier 2 Eras — Post-Launch Update (If successful)

**RENAISSANCE**
- Resource: Patronage
- Unique mechanic: ARTISTIC LICENSE — every 5 minutes of continuous stability generates a capital bonus spike (rewards patience, punishes constant crisis)
- Mutation (INQUISITION): Locks one random research upgrade for 120 seconds
- Strategic purpose: Rewards calm sessions; counter-programming for players who prefer lower-anxiety runs

**CLASSICAL AGE (Greece/Rome)**
- Resource: Knowledge
- Unique mechanic: REPUBLIC — patches cost 35 energy instead of 50, but max extractors reduced to 2
- Mutation (DECADENCE): Anomalies spread to all connected nodes; very high anomaly rate
- Strategic purpose: Support node for Exploitation Branch runs

**COLD WAR / MODERN**
- Resource: Intelligence
- Unique mechanic: BRINKMANSHIP — mutation starts a 90-second countdown; if not patched, ALL nodes take 40% stability damage simultaneously
- Mutation (NUCLEAR BRINKMANSHIP): Time-pressure event unlike any other
- Strategic purpose: First hard-timer mechanic; raises skill ceiling

**STONE AGE / PREHISTORIC**
- Resource: Raw Material
- Unique mechanic: PRIMORDIAL — extremely slow stability drain (immune to cascade); very low output; cannot mutate
- Mutation: None
- Strategic purpose: Safe anchor for beginners; emergency fallback for experienced players

---

### Tier 3 Eras — Second Update or DLC (Stretch)

**POST-HUMAN FUTURE**
- Resource: Consciousness
- Connects to all nodes simultaneously; both positive and negative cascades
- Triggers OMEGA SINGULARITY endgame variant at maximum extraction

**Additional candidates:** Bronze Age, Viking Age, Silk Road Trade Network, Space Age, Neolithic

---

### Tier 4 — Alternate History Branches (Long-term DLC)
Divergent timeline nodes unlocked by specific mutation combinations. E.g., triggering PRIMAL CHAOS and DARK AGE simultaneously for 60+ seconds unlocks MEDIEVAL APOCALYPSE as a permanent new node. These are discovery rewards for committed players.

---

## PHASE 7 — RETENTION DESIGN

### The First Session (0–1 hour)

**Minute 0–5:** Corporate onboarding memo tutorial. Learn the cascade within 3 minutes. First extractor deployed within 2 minutes. First mutation crisis within 8 minutes.

**Minute 5–20:** First crisis resolved. Player discovers push-your-luck tension. First story event fires. Player begins making extractor deployment decisions across multiple nodes.

**Minute 20–40:** First prestige achievable. Corporation rank visible. First research unlock available. Player chooses which branch to invest in.

**Minute 40–60:** First Research Branch choice creates run identity. Second mutation type encountered. Player understands the strategic difference between eras. Leaves wanting to try a different research path.

---

### 10 Hours In

- Has seen all 4 unique mutations
- Has a preferred prestige strategy (Extraction vs. Exploitation focus)
- Has read 20+ corporate memo events and has a favorite
- Has completed ~30 daily objectives
- Knows the cascade risk hierarchy instinctively
- Has reached Corporation Rank 3–4

**Retention driver:** Research tree still has unexplored nodes. Endgame event not yet triggered. Achievement list has gaps.

---

### 50 Hours In

- Corporation Rank 6–8
- Has experimented with all three research branches
- Has triggered Temporal Collapse endgame at least once
- Achievement list mostly complete; hunting secrets
- Reading daily objectives to plan sessions

**Retention driver:** Optimization runs. "Can I prestige in under 8 minutes?" Achievement hunting. Anticipating post-launch content if the game has a community presence.

---

### 100 Hours In

- Nearing full achievement completion
- Playing for optimization satisfaction and daily objective streaks
- At this point, Historical Corporations (post-launch) would extend to 150+ hours naturally

---

### Daily Objective Pool (30 objectives)

| Category | Example |
|---|---|
| Production | "Generate 2,000 Capital from Antiquity" |
| Crisis | "Survive a SINGULARITY without patching" |
| Speed | "Complete a full prestige cycle in under 10 minutes" |
| Stability | "Have all 4 nodes at >80% stability simultaneously for 3 minutes" |
| Specialty | "Generate 75 Temporal Essence in a single run" |
| Risk | "Have all 4 nodes below 30% stability simultaneously and survive" |
| Research | "Unlock 3 research nodes in a single run" |
| Prestige | "Earn 200 anomalies in a single prestige" |

---

## PHASE 8 — ECONOMY DESIGN

### Economy Flow Diagram

```
EXTRACTORS
    │
    ├─── stable node ──► CAPITAL
    │                        │
    │                        ├─► Research purchases (sink)
    │                        ├─► Temporal Insurance (sink)
    │                        └─► Prestige conversion
    │
    └─── mutated node ──► ANOMALIES / TEMPORAL ESSENCE
                              │                   │
                        Prestige shop        High-tier research
                        upgrades (sink)      (sink)
```

```
ENERGY (passive regen)
    │
    ├─► Extractor deployment (sink)
    ├─► Patching mutations (sink)
    └─► Timeline Reinforcement (sink)
```

### Scaling Formulas

**Stability drain:**
```
drain_rate = (active_extractors × era_drain_multiplier) + upstream_penalty + cascade_modifier
```
Where `era_drain_multiplier` = 1.5 (Antiquity), 2.0 (Medieval), 3.0 (Industrial), 5.0 (Future)

**Node production:**
```
production = base_rate × active_extractors × stability_multiplier × research_multiplier × recursive_loop_bonus
```
Where `stability_multiplier` = clamp(stability / 100, 0.1, 1.0) (mutated nodes produce 0 capital)

**Prestige conversion (revised):**
```
anomalies_gained = floor(sqrt(capital / 100))
```
*Replaces the current linear formula. Soft-curves the prestige pump — early prestiges still reward quickly; late runs don't trivialize anomaly generation.*

**Research costs (per branch node):**
Node 1: 50 Capital | Node 2: 150 Capital | Node 3: 400 Capital | Node 4: 1,000 Capital | Node 5: 2,500 Capital + 10 Temporal Essence (Branch 3 only)

**Extractor energy costs (tiered):**
Antiquity: 5 | Middle Ages: 8 | Industrial: 12 | Future: 20

### Inflation Controls

**Capital:** Primary inflation risk. Research costs and Temporal Insurance drain capital meaningfully mid-game. Late-game, capital should feel abundant — that's the signal to prestige, not a balance failure.

**Anomalies:** Secondary risk. Expanding prestige shop to 12 items with costs up to 50 anomalies means the shop feels "just out of reach" for 10–15 prestiges.

**Energy:** Least inflation risk. Tiered extractor costs and elevated patch costs keep energy relevant.

**Temporal Essence:** Intentionally scarce. Only one source at launch (DIESEL WASTES). Players should feel the decision to take Industrial research upgrades as a meaningful investment.

### Potential Exploits

| Exploit | Risk | Mitigation |
|---|---|---|
| Industrial mutation farming (deliberate crash for essence) | Valid strategy — allow it, balance the rate | Cap essence at 5/s max; make patch cost 75 energy |
| Energy overflow with max regen upgrades | Energy becomes meaningless | Keep Future extractor cost at 20; add energy sink via Timeline Reinforcement |
| Prestige speed-run (farm anomalies in 2-min runs) | Fine for optimizers; check early game doesn't skip | Apply sqrt curve; minimum 5-min cooldown or anomaly floor |
| Antiquity neglect (never deploy, keep FOUNDATION bonus) | Undermines balance | Add Antiquity-specific research that makes extraction attractive; Prestige shop item "Starting Capital" requires Antiquity extractors in last run |
| DARK AGE farming (let Medieval mutate every run) | Valid strategy | This is Push Your Luck working as designed; ensure capital trade-off is meaningful |

---

## PHASE 9 — SOLO DEVELOPER PRIORITIZATION

### Tier S — Build Before Anything Else

| Feature | Why |
|---|---|
| CRT amber visual identity | Without this, there is no Steam page. Converts no wishlists. Build in Month 1 and never regress. |
| 4 distinct era mutations | The cascade with identical mutations is a demo. The cascade with 4 unique mutations is a game. |
| Research tree (15 nodes) | This is the replayability engine. Without it, every run is identical. |
| Story events / corporate memos (30+) | 10 hours of writing = 20 hours of player engagement. Highest ROI in this document. |
| Revised prestige economy | 3 upgrades can't sustain the long-term loop. Needs 12 items minimum before Early Access. |

---

### Tier A — Strong Addition, Build in Phase B

| Feature | Why |
|---|---|
| Daily objectives (3/day) | Proven retention driver across all idle games. Low build cost, high daily engagement return. |
| Automation (auto-patch) | Required for idle viability. Players expect it. Earn it through research. |
| Temporal Essence resource | Turns Industrial mutation from pure negative into a strategic decision. Changes the whole meta. |
| Corporation rank system | 10 titles, trivial to implement, highly satisfying. Players will display this in screenshots. |
| Endgame Temporal Collapse | Games without endings get "no endgame content" in negative reviews. Ship with this. |
| Steam achievements (20) | Free retention. Free discoverability. Never ship without. |

---

### Tier B — Build After Launch or If Ahead of Schedule

| Feature | Why |
|---|---|
| Sound design | Important but not blocking. Ship with free ambient music rather than delaying. |
| Mac build | Easy in Godot, low priority until Windows version is solid. |
| Historical Corporations | Adds replayability but requires balancing 3× the run archetypes. Post-launch. |
| Simple resource exchange | 200 Capital → 20 Energy button. If you have 2 free hours in Month 4, add it. |
| Weekly objectives | Daily objectives already cover session goal needs. Weekly is bonus. |
| Tier 2 eras | Only after the launch 4 are deep and polished. |

---

### Tier C — Do Not Build for Version 1

| Feature | Why NOT |
|---|---|
| Time Agents | Completely different game. Adds a unit-management layer that violates Short Session Respect and will take 3× as long to build and balance as estimated. |
| Sabotage (standalone system) | No multiplayer. Self-sabotage is already covered by SINGULARITY's spread mechanic. |
| Temporal Market (dynamic) | Dynamic pricing systems are notoriously hard to balance solo. Simple exchange button (Tier B) is enough. |
| Tier 3+ eras at launch | 4 deep eras beat 10 shallow ones. Every time. |
| Branching narrative | Wrong genre. Flavor text delivers the same emotional beat at 1% of the cost. |
| Mobile port | Different platform, different design contract, different monetization model, different testing pipeline. Never for v1. |
| Leaderboards | Community infrastructure requires community. Build this if the community forms organically. |

---

## PHASE 10 — FINAL MASTER ROADMAP

*30 hours/month. 18-month realistic total to launch-ready.*

---

### Month 1 — Foundation & Identity
**Theme: Make the game look and feel like what it wants to be.**

| Task | Category | Est. Hours |
|---|---|---|
| Amber CRT aesthetic, scanlines, phosphor shader | Visual | 10 |
| Per-node stability urgency states (amber <30%, red <10%) | Visual | 4 |
| Implement FOUNDATION mechanic (Antiquity) | Systems | 3 |
| Implement FEUDAL CHAIN (Middle Ages) | Systems | 2 |
| Implement INDUSTRIAL CAPACITY (Industrial) | Systems | 2 |
| Implement RECURSIVE LOOP (Future) | Systems | 2 |
| Implement 4 distinct mutations with unique behaviors | Systems | 5 |
| Add Temporal Essence as 4th resource | Systems | 2 |

**Playtesting goal:** Do playtesters understand the cascade without explanation? Does each era feel meaningfully different?

---

### Month 2 — Research & Depth
**Theme: Give runs different identities.**

| Task | Category | Est. Hours |
|---|---|---|
| Design and implement 3-branch research tree (15 nodes) | Systems | 14 |
| Tiered extractor energy costs per era | Balance | 2 |
| Capital as research cost (add to UI) | Systems | 3 |
| Revised prestige formula (sqrt curve) | Balance | 2 |
| Expand prestige shop to 12 items | Content | 4 |
| Corporation rank system (10 tiers) | Content | 3 |

**Playtesting goal:** Do players make different research choices across runs? Does Exploitation Branch feel meaningfully different from Containment?

---

### Month 3 — Story & Voice
**Theme: Make players care — and laugh.**

| Task | Category | Est. Hours |
|---|---|---|
| Write 30 corporate memo story events | Content | 12 |
| Implement event popup system in UI | Systems | 5 |
| Tutorial: corporate onboarding memo sequence | Content | 6 |
| Era flavor text (resource names, node descriptions) | Content | 3 |
| Upgrade and research node names in corporate doublespeak | Content | 2 |

**Playtesting goal:** Do playtesters laugh? Do they read the events? Do they share screenshots of specific events?

---

### Month 4 — Automation & Balance
**Theme: Make the idle loop work.**

| Task | Category | Est. Hours |
|---|---|---|
| Auto-patch automation (Containment Branch unlock) | Systems | 5 |
| Offline progress calculation (8-hour cap) | Systems | 6 |
| First full balance pass: drain rates, production, prestige curve | Balance | 10 |
| Simple resource exchange interface (if time allows) | Systems | 3 |

**Playtesting goal:** Does offline progress feel rewarding on return? Is the balance fair without feeling trivial?

---

### Month 5 — Endgame & Session Goals
**Theme: Give players a destination and a reason to return daily.**

| Task | Category | Est. Hours |
|---|---|---|
| Daily objectives system (3/day, pool of 30) | Systems | 8 |
| Temporal Collapse endgame event | Systems | 10 |
| 20 Steam achievements | Systems | 5 |
| Sound: ambient industrial/era sounds, event SFX | Audio | 5 |

**Playtesting goal:** Does the endgame feel climactic? Do daily objectives give short sessions purpose?

---

### Month 6 — Polish & Launch Prep
**Theme: Make it shippable.**

| Task | Category | Est. Hours |
|---|---|---|
| Full UI polish and animation pass | Visual | 8 |
| AI-generated era illustrations (8 images) for event popups | Art | 6 |
| Expand story events to 50 total | Content | 6 |
| Steam capsule art, 5 screenshots | Marketing | 4 |
| Short gameplay trailer (screen capture + licensed music) | Marketing | 4 |
| Press kit (itch.io page, presskit()) | Marketing | 2 |

**Steam page goes LIVE at end of Month 6. Begin wishlisting 3–6 months before release.**

**Target release: Month 12–18** — the exact date is determined by playtest feedback and wishlist momentum, not a hard calendar deadline.

---

## FINAL ASSESSMENT

### 1. Biggest reason this game could succeed

The cascade mechanic is genuinely interesting and not present in other idle games at this depth. Combined with the amber CRT aesthetic, the corporate satire voice, and the push-your-luck mutation crisis cycle, this has a coherent identity. The idle market has room for a game that makes players feel clever rather than just patient. The niche exists: there is no amber-CRT corporate-exploitation idle strategy game on Steam.

### 2. Biggest reason this game could fail

**Non-dev work will be underestimated.** A compelling Steam page, a trailer that shows the cascade in the first 10 seconds, 1,000+ wishlists before launch, and a launch window that avoids large indie releases — none of this is in the prototype and all of it is required. The game could be excellent and still fail if the store page doesn't communicate the cascade mechanic visually within 3 seconds. Budget 25% of total dev time on store presence.

### 3. Single most important mechanic to perfect

**The cascade.** Everything else is optional. If the visual and mechanical feeling of upstream instability rippling through connected timelines isn't tense, surprising, and satisfying to manage, no amount of story events or research nodes will save it. The cascade must be legible, dramatic, and satisfying to prevent **and** to survive. Get this right before Month 2.

### 4. Features that should never be built

- Time Agents — wrong game
- Multiplayer or true Sabotage system — wrong genre pivot
- Mobile port — different design contract
- Branching narrative or dialogue trees — wrong cost-to-benefit for idle
- 10+ eras at launch — dilutes depth; 4 deep > 10 shallow, always

### 5. Recommended Steam positioning

**Tags:** Idle, Incremental, Strategy, Management, Dark Humor, Sci-fi
**Comparable to:** Universal Paperclips, Cookie Clicker, Kittens Game
**Capsule headline:** *"Every era of history, ruthlessly optimized for profit."*
**Key GIF for store page:** Show the cascade — Antiquity mutating, the red border spreading to Middle Ages, then Industrial. 6 seconds. No UI explanation needed. That visual IS the hook.
**Avoid:** Positioning as a clicker (you barely click). Position as incremental strategy.

### 6. Recommended pricing strategy

**$6.99 at launch, no launch discount.**

The sweet spot for this genre: under the impulse-buy threshold, above shovelware signal, compatible with Humble Bundle and curator bundles. Apply a **33% discount at 3 months post-launch** for the first major sale event. Never discount below $3.49 (50% off) in the first year — it trains the audience to wait and damages review velocity.

Do not launch with Early Access pricing. Ship when it's done and ship at full price. The incremental game audience is exceptionally tolerant of a small complete game; they are not tolerant of an incomplete one.

---

*End of document. Version 1.0.*
*Next step: Implementation planning via writing-plans skill.*
