extends Node

## Central simulation owner. Pure state machine; never references UI nodes.
## All sim→UI communication via EventBus typed signals.

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
var last_run_result: Dictionary = {}
var custom_seed: int = 0
var _sim_speed_multiplier: float = 1.0

func _ready() -> void:
	_balance = load("res://resources/balance_sheet.tres")

func _process(delta: float) -> void:
	if _phase != Phase.RUNNING:
		return
	_tick_accum += delta * _sim_speed_multiplier
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
	_state.seed = custom_seed if custom_seed != 0 else randi()
	_state.contract_id = contract_id
	_state.quarter = 1
	_state.sim_time = 0.0
	_state.quarter_time = 0.0
	_state.capital = 0.0
	_state.relics = 0
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

	# 1. Apply Meta upgrades (Starting Capital)
	if MetaState.unlocked_nodes.has(&"ops_starting_capital"):
		_state.capital += 100.0

	# 2. Starting Injunction count: basic + Legal branch unlock
	var starting_inj := contract.starting_injunctions
	if MetaState.unlocked_nodes.has(&"legal_injunction_slot"):
		starting_inj += 1
	_state.injunctions = starting_inj

	# 3. Setup Eras
	_state.eras = []
	for era_id in ERA_ORDER:
		var es := EraState.new()
		es.era_id = era_id
		_state.eras.append(es)

	# 4. Modifiers & Quota calculations (requires _has_modifier helper)
	if _has_modifier(&"austerity"):
		_state.injunctions = max(1, _state.injunctions - 1)

	for es in _state.eras:
		if _has_modifier("pre_mutated_" + es.era_id) or (es.era_id == &"middle_ages" and _has_modifier(&"pre_mutated")):
			es.mutation_severity = 1

	var quota := contract.quota
	if _has_modifier(&"cheap_money"):
		quota *= 1.3
	if _has_modifier(&"overtime"):
		quota *= 1.4
	# Audit Level scaling (+10% per level)
	quota *= (1.0 + float(MetaState.audit_level) * 0.1)
	_state.flags[&"run_quota"] = quota

	# 5. Secret Board Mandate selection
	var mandate_pool := contract.mandate_pool
	if mandate_pool.is_empty():
		mandate_pool = ContentDB.get_all_of_type("MandateDef")
	if not mandate_pool.is_empty():
		var chosen := mandate_pool[_rng.randi() % mandate_pool.size()] as MandateDef
		_state.flags[&"active_mandate_id"] = chosen.id

	_state.fronts = []
	_quarter_capital_start = 0.0
	_sim_speed_multiplier = 1.0
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

func place_extractor(era_id: StringName, ext_type_id: StringName, is_free: bool = false) -> bool:
	if _phase != Phase.RUNNING:
		return false
	var era_state := _get_era(era_id)
	var era_def := ContentDB.get_by_id(era_id) as EraDef
	var ext_def := ContentDB.get_by_id(ext_type_id) as ExtractorDef
	if not era_state or not era_def or not ext_def:
		return false

	if _has_modifier(&"skeleton_crew") and era_state.extractors.size() >= 2:
		return false

	var cost := 0.0
	if not is_free:
		cost = _extractor_cost(ext_def, era_state, era_def)
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

	var types: Array = _state.flags.get(&"mandate_placed_extractor_types", [])
	types.append(ext_type_id)
	_state.flags[&"mandate_placed_extractor_types"] = types

	_log_action("place_extractor", {"era_id": era_id, "type_id": ext_type_id, "cost": cost})
	EventBus.player_action.emit({"action": "place_extractor", "era_id": era_id, "type_id": ext_type_id})
	return true

func remove_extractor(era_id: StringName, index: int) -> bool:
	if _phase != Phase.RUNNING:
		return false
	if _has_modifier(&"hands_off_clause"):
		return false
	var era_state := _get_era(era_id)
	if not era_state or index >= era_state.extractors.size():
		return false

	var rec: Dictionary = era_state.extractors[index]
	var ext_def := ContentDB.get_by_id(rec.type_id) as ExtractorDef
	var era_def := ContentDB.get_by_id(era_id) as EraDef

	# Remove first, then value the salvage at the post-removal count so the
	# refund matches what the extractor actually cost to place (scaling^(N-1)).
	era_state.extractors.remove_at(index)

	if ext_def and era_def:
		var salvage_rate := _balance.extractor_salvage_rate
		if MetaState.unlocked_nodes.has(&"ops_salvage_rate"):
			salvage_rate = 0.4
		if EffectResolver.has_flag("salvage_rate", _state.active_directives):
			salvage_rate = 1.0
		_state.capital += _extractor_cost(ext_def, era_state, era_def) * salvage_rate

	var scar_instability := _balance.temporal_scar_instability
	if MetaState.unlocked_nodes.has(&"ops_scar_reduction"):
		scar_instability = 5.0
	scar_instability *= EffectResolver.get_global_multiplier("scar_mult", _state.active_directives)
	era_state.instability = minf(era_state.instability + scar_instability, 100.0)

	if era_id == &"industrial":
		era_state.momentum = 0.0
		era_state.momentum_timer = 0.0

	_log_action("remove_extractor", {"era_id": era_id, "index": index})
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
	_state.flags[&"mandate_dampen_count"] = _state.flags.get(&"mandate_dampen_count", 0) + 1
	_log_action("dampen", {"front_uid": front_uid})
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
	if MetaState.unlocked_nodes.has(&"legal_divert_discount"):
		cost *= 0.75

	if _state.capital < cost:
		return false

	_state.capital -= cost
	front.diverted_from = front.target_era_id
	front.target_era_id = target_def.downstream_id
	front.progress = 0.0
	front.travel_time = _travel_time()

	_state.flags[&"mandate_divert_count"] = _state.flags.get(&"mandate_divert_count", 0) + 1
	_log_action("divert", {"front_uid": front_uid, "cost": cost, "new_target": front.target_era_id})
	EventBus.player_action.emit({"action": "divert", "front_uid": front_uid, "cost": cost})
	return true

func harvest_front(front_uid: int) -> bool:
	if _phase != Phase.RUNNING:
		return false
	if _has_modifier(&"inspection"):
		return false
	var front := _find_front(front_uid)
	if not front or front.harvested:
		return false

	var payout := _harvest_payout(front)
	payout *= EffectResolver.get_global_multiplier("harvest_mult", _state.active_directives)
	if MetaState.unlocked_nodes.has(&"rd_harvest_value"):
		payout *= 1.25

	front.harvested = true
	front.severity = mini(front.severity + 1, 2)
	front.travel_time *= _balance.harvest_speed_bonus

	_state.capital += payout
	_state.flags[&"mandate_harvest_count"] = _state.flags.get(&"mandate_harvest_count", 0) + 1
	if _state.flags.get(&"mandate_harvest_count", 0) == 1:
		_try_trigger_incident(&"first_harvest")
	_log_action("harvest", {"front_uid": front_uid, "payout": payout})
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
		"effects": directive.effects.duplicate(true),
	}
	_state.active_directives.append(entry)

	for effect in directive.effects:
		var dur: int = int(effect.get("duration", effect.get("duration_quarters", -1)))
		if dur == 0:
			if effect.get("stat", "") == "singularity":
				_set_singularity(EffectResolver.apply_op(_state.singularity, effect))
			else:
				EffectResolver.apply_global(effect, _state)

	if directive.id == &"synergy_initiative":
		_state.flags[&"synergy_initiative"] = true

	_log_action("directive", {"id": directive_id})
	_state.quarter += 1
	_pending_directives.clear()
	_phase = Phase.RUNNING
	_quarter_capital_start = _state.capital
	if _state.quarter >= 3 and _rng.randf() < 0.4:
		_try_trigger_incident(&"quarter_start")

func restock_injunctions() -> bool:
	var is_free := false
	var directive_to_remove: Dictionary = {}
	for directive in _state.active_directives:
		var effects: Array = directive.get("effects", [])
		var to_remove_idx := -1
		for i in range(effects.size()):
			if effects[i].get("stat", "") == "next_restock_free":
				is_free = true
				to_remove_idx = i
				break
		if is_free:
			if to_remove_idx != -1:
				effects.remove_at(to_remove_idx)
			if effects.is_empty():
				directive_to_remove = directive
			break
	if not directive_to_remove.is_empty():
		_state.active_directives.erase(directive_to_remove)

	var cost := 0.0
	if not is_free:
		cost = _restock_cost()
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

func get_pending_directives() -> Array[DirectiveDef]:
	return _pending_directives

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

	var allow_cascade := not (_state.quarter <= 2 and _state.quarter_time < 60.0)

	for es in _state.eras:
		_tick_era(es, dt, allow_cascade)

	_tick_fronts(dt)

	if _state.singularity >= 50.0 and not _state.flags.get(&"triggered_singularity_50", false):
		_state.flags[&"triggered_singularity_50"] = true
		_try_trigger_incident(&"singularity_50")

	_check_instability_timers(dt)

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

	# Yield from extractors
	var relic_key := &"relic_acc_" + es.era_id
	var relic_acc: float = float(_state.flags.get(relic_key, 0.0))

	for rec in es.extractors:
		var ext_def := ContentDB.get_by_id(rec.type_id) as ExtractorDef
		if not ext_def:
			continue

		if ext_def.id == &"burst" and rec.get("burst_active", false):
			rec["burst_timer"] = float(rec.get("burst_timer", 0.0)) + dt
			if rec["burst_timer"] >= ext_def.burst_duration:
				rec["burst_active"] = false

		var yield_rate := _extractor_yield(ext_def, rec, es, era_def)

		if es.era_id == &"middle_ages" and es.mutation_severity > 0:
			if ext_def.id == &"burst":
				relic_acc += yield_rate * dt
		else:
			_state.capital += yield_rate * dt

	if relic_acc > 0.0:
		if relic_acc >= 1.0:
			_state.relics += int(relic_acc)
			relic_acc = fmod(relic_acc, 1.0)
		_state.flags[relic_key] = relic_acc

	# Instability gain
	var inst_gain := 0.0
	for rec in es.extractors:
		var ext_def := ContentDB.get_by_id(rec.type_id) as ExtractorDef
		if not ext_def:
			continue
		var base_gain := ext_def.instability_per_second
		if ext_def.id == &"burst" and rec.get("burst_active", false):
			base_gain = ext_def.burst_instability_spike / ext_def.burst_duration
		inst_gain += base_gain

	inst_gain *= era_def.instability_gain_mult
	inst_gain *= EffectResolver.get_era_multiplier("instability_gain_mult", es.era_id, _state.active_directives)
	inst_gain *= EffectResolver.get_global_multiplier("instability_gain_mult", _state.active_directives)

	if es.era_id == &"antiquity" and _has_modifier(&"foundation_risk"):
		inst_gain *= 1.5

	if _state.quarter <= 2:
		inst_gain *= _balance.early_quarter_instability_mult
	elif _state.quarter >= 8:
		inst_gain *= 0.6

	var freeze_key := "osha_freeze_timer_" + es.era_id
	var freeze_t := float(_state.flags.get(freeze_key, 0.0))
	if freeze_t > 0.0:
		freeze_t = maxf(0.0, freeze_t - dt)
		_state.flags[freeze_key] = freeze_t
		inst_gain = 0.0

	es.instability = minf(es.instability + inst_gain * dt, 100.0)

	# Industrial Momentum
	if es.era_id == &"industrial" and es.mutation_severity == 0:
		es.momentum_timer += dt
		if es.momentum_timer >= 10.0:
			es.momentum_timer = 0.0
			es.momentum = minf(es.momentum + _balance.momentum_stack_rate, _balance.momentum_cap)

	# Mutated era emission
	if es.mutation_severity > 0 and allow_cascade:
		var mutation := era_def.mutation as MutationDef
		if mutation and mutation.emission_interval_quarters.size() > 0:
			var idx := mini(es.mutation_severity - 1, mutation.emission_interval_quarters.size() - 1)
			var interval_q := mutation.emission_interval_quarters[idx]
			if interval_q > 0:
				es.emission_timer += dt
				if es.emission_timer >= float(interval_q) * QUARTER_DURATION:
					es.emission_timer = 0.0
					_spawn_front(es, era_def)

	if es.instability >= 100.0 and allow_cascade:
		_overflow(es, era_def)

func _overflow(es: EraState, era_def: EraDef) -> void:
	es.instability = _balance.instability_overflow_reset
	_check_and_mutate(es, era_def)
	_spawn_front(es, era_def)

func _check_and_mutate(es: EraState, era_def: EraDef) -> void:
	if es.mutation_severity >= 2 or not era_def.mutation:
		return
	var before := es.mutation_severity
	es.mutation_severity += 1
	EventBus.era_mutated.emit(es.era_id, es.mutation_severity)

	if es.era_id == &"industrial":
		es.momentum = 0.0

	if _count_mutations() >= 2:
		_add_singularity(_balance.multi_mutation_singularity_per_quarter)

	if before == 0:
		_try_trigger_incident(&"first_mutation")

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

	if front.target_era_id == &"future":
		var gain := _balance.soot_singularity_gain * (1.5 if front.severity >= 2 else 1.0)
		EventBus.front_resolved.emit(front, 0)
		_add_singularity(gain)
		return

	var target := _get_era(front.target_era_id)
	var target_def := ContentDB.get_by_id(front.target_era_id) as EraDef
	var front_type := ContentDB.get_by_id(front.type_id) as FrontTypeDef

	if front_type and target:
		for effect in front_type.arrival_effects:
			if front.severity < int(effect.get("severity_min", 1)):
				continue
			var stat: String = effect.get("stat", "")
			match stat:
				"singularity":
					_set_singularity(EffectResolver.apply_op(_state.singularity, effect))
				"momentum", "instability":
					EffectResolver.apply_to_era(effect, target, _state)

	EventBus.front_resolved.emit(front, 0)

	if target and target.instability >= 100.0 and target_def:
		_overflow(target, target_def)

# Single funnel for ALL singularity mutation: clamps to [0,100], emits the
# change, and runs the loss check exactly once. Nothing should write
# _state.singularity directly except start_run's reset.
func _set_singularity(value: float) -> void:
	_state.singularity = clampf(value, 0.0, 100.0)
	EventBus.singularity_changed.emit(_state.singularity)
	_check_singularity_loss()

func _add_singularity(delta: float) -> void:
	_set_singularity(_state.singularity + delta)

func _check_singularity_loss() -> void:
	if _state.singularity < 85.0:
		return
	if not _state.parachute_used:
		_state.parachute_used = true
		_state.injunctions += 1
		EventBus.player_action.emit({"action": "parachute_fired"})
	if _state.singularity >= 100.0:
		_end_run(false, "singularity")

# ── Quarter boundary ─────────────────────────────────────────────────────────

func _end_quarter() -> void:
	_state.quarter_time = 0.0
	_state.quarter_capitals.append(_state.capital)

	EffectResolver.tick_directive_durations(_state)

	if _state.relics > 0:
		_state.flags[&"mandate_relics_converted"] = _state.flags.get(&"mandate_relics_converted", 0) + _state.relics
		_state.capital += float(_state.relics) * 25.0
		_state.relics = 0

	if _state.flags.get(&"synergy_initiative", false):
		_apply_synergy_initiative()

	# Passive singularity penalty for having 2+ mutations active
	if _count_mutations() >= 2:
		_add_singularity(10.0)

	# If the penalty (or any pending change) ended the run, don't fall through
	# and overwrite the ENDED phase with a quarter report.
	if _phase == Phase.ENDED:
		return

	var max_quarters := 9 if _has_modifier(&"overtime") else 8
	if _state.quarter >= max_quarters:
		var contract_quota := _get_contract_quota()
		_end_run(_state.capital >= contract_quota, "")
		return

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
	for item in all:
		if selected.size() >= 3:
			break
		var d := item as DirectiveDef
		if not d:
			continue
		if d.tone == 2 and mandate_count >= 1:
			continue
		if d.tone == 1 and deal_count >= 2:
			continue
		if d.tone == 2:
			mandate_count += 1
		elif d.tone == 1:
			deal_count += 1
		selected.append(d)
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
		place_extractor(lowest_era, &"steady", true)

# ── Run end ──────────────────────────────────────────────────────────────────

func _end_run(won: bool, cause: String) -> void:
	if _phase == Phase.ENDED:
		return
	_phase = Phase.ENDED
	var contract := _get_contract()
	var anomalies := 0
	var quota := _get_contract_quota()
	
	if won:
		anomalies = contract.anomaly_reward if contract else 0
	else:
		if quota > 0.0 and _state.capital / quota >= 0.5:
			anomalies = int((contract.anomaly_reward if contract else 0) * 0.4)

	# Check hidden Mandate
	var mandate_won := false
	var mandate_bonus := 0
	var active_mandate_id: StringName = _state.flags.get(&"active_mandate_id", &"")
	if active_mandate_id != &"":
		var mandate := ContentDB.get_by_id(active_mandate_id) as MandateDef
		if mandate:
			mandate_won = _check_mandate(mandate)
			if mandate_won:
				mandate_bonus = mandate.anomaly_bonus
				anomalies += mandate_bonus

	var result := {
		"won": won,
		"cause": cause,
		"seed": _state.seed,
		"capital": _state.capital,
		"quota": quota,
		"singularity": _state.singularity,
		"mutations": _count_mutations(),
		"anomalies_earned": anomalies,
		"action_log": _state.action_log,
		"contract_id": _state.contract_id,
		"mandate_id": active_mandate_id,
		"mandate_won": mandate_won,
		"mandate_bonus": mandate_bonus,
	}

	last_run_result = result
	MetaState.complete_run(result)
	EventBus.run_ended.emit(result)

# ── Calculations ─────────────────────────────────────────────────────────────

func _travel_time() -> float:
	var speed_mult := 1.0 + float(_count_mutations()) * _balance.mutation_speed_bonus
	if _has_modifier(&"accelerated_timeline"):
		speed_mult *= 1.25
	if MetaState.audit_level > 0:
		speed_mult *= (1.0 + float(MetaState.audit_level) * 0.05)
	if MetaState.unlocked_nodes.has(&"rd_front_speed"):
		speed_mult *= 0.9
	var global_mult := maxf(EffectResolver.get_global_multiplier("front_speed_mult", _state.active_directives), 0.1)
	return _balance.front_travel_base / (speed_mult * global_mult)

func _extractor_cost(ext_def: ExtractorDef, es: EraState, era_def: EraDef) -> float:
	var base := ext_def.base_cost * era_def.extractor_cost_mult
	if _has_modifier(&"cheap_money"):
		base *= 0.7
	base *= EffectResolver.get_era_multiplier("cost_mult", es.era_id, _state.active_directives)
	var size := es.extractors.size()
	if MetaState.unlocked_nodes.has(&"ops_fifth_extractor_cap"):
		size = min(size, 4)
	return base * pow(_balance.extractor_cost_scaling, float(size))

func _extractor_yield(ext_def: ExtractorDef, rec: Dictionary, es: EraState, era_def: EraDef) -> float:
	var rate: float
	if ext_def.id == &"burst":
		rate = ext_def.burst_yield if rec.get("burst_active", false) else ext_def.post_burst_yield
	else:
		rate = ext_def.yield_per_second

	if _state.flags.get("osha_yield_penalty_" + es.era_id, false):
		rate *= 0.5

	if es.era_id == &"antiquity" and es.mutation_severity > 0:
		return 0.0

	if es.era_id == &"antiquity" and ext_def.id == &"deep":
		rate *= _balance.deep_antiquity_bonus

	if es.era_id == &"industrial" and es.mutation_severity == 0:
		rate *= (1.0 + es.momentum)

	if es.era_id == &"industrial" and es.mutation_severity > 0:
		rate *= [2.0, 3.0][mini(es.mutation_severity - 1, 1)]

	if es.era_id != &"antiquity":
		var antiquity := _get_era(&"antiquity")
		if antiquity and antiquity.mutation_severity == 0:
			var foundation_mult := 1.0 + _balance.foundation_max_bonus * (1.0 - antiquity.instability / 100.0)
			rate *= foundation_mult

	if es.era_id == &"future":
		var total_stability := 0.0
		for other_es in _state.eras:
			total_stability += 100.0 - other_es.instability
		rate *= total_stability / (100.0 * float(_balance.speculation_era_count))

	if _state.quarter >= 8:
		rate *= (1.0 + _balance.late_quarter_yield_bonus)

	rate *= EffectResolver.get_era_multiplier("yield_mult", es.era_id, _state.active_directives)
	rate *= EffectResolver.get_global_multiplier("yield_mult", _state.active_directives)
	return maxf(rate, 0.0)

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

func _divert_cost(front: FrontState) -> float:
	var front_type := ContentDB.get_by_id(front.type_id) as FrontTypeDef
	var base := (front_type.harvest_base if front_type else 150.0) + _balance.harvest_contract_bonus * float(_current_tier())
	return base * 0.3

func _harvest_payout(front: FrontState) -> float:
	var front_type := ContentDB.get_by_id(front.type_id) as FrontTypeDef
	var base := front_type.harvest_base if front_type else 150.0
	return _era_total_yield(_get_era(front.origin_era_id)) * 12.0 + base * float(_current_tier())

func _restock_cost() -> float:
	var contract := _get_contract()
	var quota := contract.quota if contract else 1000.0
	return quota * _balance.restock_base_cost_pct * pow(2.0, float(_state.restock_count))

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

func _log_action(action: String, data: Dictionary) -> void:
	_state.action_log.append({
		"action": action,
		"quarter": _state.quarter,
		"t": _state.sim_time,
		"data": data,
	})

func _has_modifier(modifier_id: StringName) -> bool:
	var contract := _get_contract()
	if not contract:
		return false
	for m in contract.modifiers:
		if m.id == modifier_id:
			return true
	return false

func _get_contract_quota() -> float:
	if not _state:
		return 0.0
	if _state.flags.has(&"run_quota"):
		return _state.flags.get(&"run_quota")
	var contract := _get_contract()
	return contract.quota if contract else 0.0

# Public accessor for UI: the audit/modifier-scaled quota that the win check
# actually uses. UI must display this, not the raw contract.quota.
func get_contract_quota() -> float:
	return _get_contract_quota()

func _check_mandate(mandate: MandateDef) -> bool:
	if not mandate:
		return false
	match mandate.id:
		&"harvest_twice":
			return _state.flags.get(&"mandate_harvest_count", 0) >= 2
		&"no_mutations":
			return _count_mutations() == 0
		&"relic_collector":
			return _state.flags.get(&"mandate_relics_converted", 0) >= 5
		&"steady_only":
			var types: Array = _state.flags.get(&"mandate_placed_extractor_types", [])
			for t in types:
				if t != &"steady":
					return false
			return true
		&"no_dampen":
			return _state.flags.get(&"mandate_dampen_count", 0) == 0
		&"no_divert":
			return _state.flags.get(&"mandate_divert_count", 0) == 0
	return false

func _check_instability_timers(dt: float) -> void:
	for es in _state.eras:
		if es.instability >= 90.0:
			var key = "instability_time_" + es.era_id
			var t = float(_state.flags.get(key, 0.0)) + dt
			_state.flags[key] = t
			if t >= 20.0 and not _state.flags.get(&"triggered_high_instability", false):
				_state.flags[&"triggered_high_instability"] = true
				_state.flags[&"osha_target_era"] = es.era_id
				_try_trigger_incident(&"high_instability")
		else:
			_state.flags["instability_time_" + es.era_id] = 0.0

func _try_trigger_incident(trigger_type: StringName) -> void:
	if _sim_speed_multiplier < 1.0:
		return

	var all_incidents := ContentDB.get_all_of_type("IncidentDef")
	var valid_incidents: Array[IncidentDef] = []
	var triggered_list = _state.flags.get(&"triggered_incidents", [])

	for item in all_incidents:
		var inc := item as IncidentDef
		if not inc or inc.trigger != trigger_type:
			continue
		if inc.once_per_run and inc.id in triggered_list:
			continue
		
		var flags_ok = true
		for f in inc.requires_flags:
			if not _state.flags.get(f, false):
				flags_ok = false
				break
		if not flags_ok:
			continue
			
		valid_incidents.append(inc)

	if valid_incidents.is_empty():
		return

	var total_weight := 0.0
	for inc in valid_incidents:
		total_weight += inc.weight
	
	if total_weight <= 0.0:
		return

	var roll := _rng.randf() * total_weight
	var selected_incident: IncidentDef = null
	var accum := 0.0
	for inc in valid_incidents:
		accum += inc.weight
		if roll <= accum:
			selected_incident = inc
			break

	if selected_incident:
		triggered_list.append(selected_incident.id)
		_state.flags[&"triggered_incidents"] = triggered_list
		_state.flags[&"active_incident_id"] = selected_incident.id
		_sim_speed_multiplier = 0.1
		EventBus.incident_triggered.emit(selected_incident)

func resolve_incident(choice_index: int) -> void:
	var active_id = _state.flags.get(&"active_incident_id", &"")
	if active_id == &"":
		return
	
	var incident := ContentDB.get_by_id(active_id) as IncidentDef
	if not incident or choice_index < 0 or choice_index >= incident.choices.size():
		return
	
	var choice: Dictionary = incident.choices[choice_index]
	
	# Apply effects
	var effects: Array = choice.get("effects", [])
	for effect in effects:
		var scope: String = effect.get("scope", "global")
		# Singularity always routes through the central funnel (clamp + loss check),
		# regardless of declared scope.
		if effect.get("stat", "") == "singularity":
			_set_singularity(EffectResolver.apply_op(_state.singularity, effect))
		elif scope == "global":
			EffectResolver.apply_global(effect, _state)
		else:
			var era_id: StringName = effect.get("era_id", &"")
			if era_id == &"":
				# If osha triggers, apply to osha_target_era
				if active_id == &"temporal_osha":
					era_id = _state.flags.get(&"osha_target_era", &"")
			var es := _get_era(era_id)
			if es:
				EffectResolver.apply_to_era(effect, es, _state)

	# Set flags
	var sets_flags: Dictionary = choice.get("sets_flags", {})
	for k in sets_flags:
		_state.flags[k] = sets_flags[k]
		
	# Special choices logic
	if active_id == &"temporal_osha":
		var target_era_id: StringName = _state.flags.get(&"osha_target_era", &"")
		if target_era_id != &"":
			if choice_index == 0:
				_state.flags["osha_freeze_timer_" + target_era_id] = 30.0
				_state.flags["osha_yield_penalty_" + target_era_id] = true
			elif choice_index == 1:
				var es := _get_era(target_era_id)
				if es:
					es.instability = minf(es.instability + 15.0, 100.0)
				_state.flags[&"osha_grudge"] = true

	# Resume normal speed
	_sim_speed_multiplier = 1.0
	_state.flags.erase(&"active_incident_id")
	EventBus.run_resumed.emit()
