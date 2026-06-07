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
	# Resources cannot go below 0 (stability and TE are clamped separately below)
	if key not in ["stability", "temporal_energy", "temporal_energy_max"]:
		if float(state.resources[key]) < 0.0:
			state.resources[key] = 0.0
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
	state_changed.emit()

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
	var floor_val = 0.0
	if ResearchManager.has_method("get_stability_floor"):
		floor_val = ResearchManager.get_stability_floor()
	var new_stability = maxf(state.resources.stability - decay, floor_val)
	state.resources.stability = new_stability
	state_changed.emit()

func calculate_income_per_second() -> Dictionary:
	var income = {"credits": 0.0, "knowledge": 0.0, "historical_data": 0.0, "influence": 0.0}
	for mission in state.active_missions:
		if not EraManager.has_method("get_era"):
			continue
		var era = EraManager.get_era(mission.era_id)
		if era.is_empty():
			continue
		if not AgentManager.has_method("get_agent_stats"):
			continue
		var agent_stats = AgentManager.get_agent_stats(mission.agent_id)
		var efficiency = agent_stats.get("efficiency", 1.0)
		var duration = float(era.get("duration", 60))
		if duration <= 0.0:
			continue
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
