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

	_log_action("place_extractor", {"era_id": era_id, "type_id": ext_type_id, "cost": cost})
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
	if _state.capital < cost:
		return false

	_state.capital -= cost
	front.diverted_from = front.target_era_id
	front.target_era_id = target_def.downstream_id
	front.progress = 0.0
	front.travel_time = _travel_time()

	_log_action("divert", {"front_uid": front_uid, "cost": cost, "new_target": front.target_era_id})
	EventBus.player_action.emit({"action": "divert", "front_uid": front_uid, "cost": cost})
	return true

func harvest_front(front_uid: int) -> bool:
	if _phase != Phase.RUNNING:
		return false
	var front := _find_front(front_uid)
	if not front or front.harvested:
		return false

	var payout := _harvest_payout(front)
	payout *= EffectResolver.get_global_multiplier("harvest_mult", _state.active_directives)

	front.harvested = true
	front.severity = mini(front.severity + 1, 2)
	front.travel_time *= _balance.harvest_speed_bonus

	_state.capital += payout
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
		"effects": directive.effects,
	}
	_state.active_directives.append(entry)

	for effect in directive.effects:
		var dur: int = int(effect.get("duration", effect.get("duration_quarters", -1)))
		if dur == 0:
			EffectResolver.apply_global(effect, _state)

	if directive.id == &"synergy_initiative":
		_state.flags[&"synergy_initiative"] = true

	_log_action("directive", {"id": directive_id})
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

	var allow_cascade := not (_state.quarter <= 2 and _state.quarter_time < 60.0)

	for es in _state.eras:
		_tick_era(es, dt, allow_cascade)

	_tick_fronts(dt)

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

	if _state.quarter <= 2:
		inst_gain *= _balance.early_quarter_instability_mult

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
	es.mutation_severity += 1
	EventBus.era_mutated.emit(es.era_id, es.mutation_severity)

	if es.era_id == &"industrial":
		es.momentum = 0.0

	if _count_mutations() >= 2:
		_state.singularity += _balance.multi_mutation_singularity_per_quarter
		EventBus.singularity_changed.emit(_state.singularity)

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
		_state.singularity += gain
		EventBus.singularity_changed.emit(_state.singularity)
		EventBus.front_resolved.emit(front, 0)
		_check_singularity_loss()
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
					EffectResolver.apply_global(effect, _state)
					EventBus.singularity_changed.emit(_state.singularity)
				"momentum", "instability":
					EffectResolver.apply_to_era(effect, target, _state)

	EventBus.front_resolved.emit(front, 0)

	if target and target.instability >= 100.0 and target_def:
		_overflow(target, target_def)

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
		_state.capital += float(_state.relics) * 25.0
		_state.relics = 0

	if _state.flags.get(&"synergy_initiative", false):
		_apply_synergy_initiative()

	if _state.quarter >= 8:
		var contract := _get_contract()
		_end_run(_state.capital >= (contract.quota if contract else 0.0), "")
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
		place_extractor(lowest_era, &"steady")

# ── Run end ──────────────────────────────────────────────────────────────────

func _end_run(won: bool, cause: String) -> void:
	_phase = Phase.ENDED
	var contract := _get_contract()
	var anomalies := 0
	if won:
		anomalies = contract.anomaly_reward if contract else 0
	else:
		var quota := contract.quota if contract else 1.0
		if quota > 0.0 and _state.capital / quota >= 0.5:
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
	var global_mult := maxf(EffectResolver.get_global_multiplier("front_speed_mult", _state.active_directives), 0.1)
	return _balance.front_travel_base / (speed_mult * global_mult)

func _extractor_cost(ext_def: ExtractorDef, es: EraState, era_def: EraDef) -> float:
	var base := ext_def.base_cost * era_def.extractor_cost_mult
	base *= EffectResolver.get_era_multiplier("cost_mult", es.era_id, _state.active_directives)
	return base * pow(_balance.extractor_cost_scaling, float(es.extractors.size()))

func _extractor_yield(ext_def: ExtractorDef, rec: Dictionary, es: EraState, era_def: EraDef) -> float:
	var rate: float
	if ext_def.id == &"burst":
		rate = ext_def.burst_yield if rec.get("burst_active", false) else ext_def.post_burst_yield
	else:
		rate = ext_def.yield_per_second

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
			var foundation_mult := 1.5 - antiquity.instability / 200.0
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
