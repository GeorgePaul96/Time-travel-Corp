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

	# XP for agent (10 XP per risk level)
	rewards["xp"] = 10.0 * float(era.get("risk", 1))

	# Apply all rewards to game state
	for resource in rewards:
		if resource != "xp":
			GameState.add_resource(resource, rewards[resource])

	# Restore TE lock: 1 TE per returned mission
	GameState.state.resources.temporal_energy = minf(
		GameState.state.resources.temporal_energy + 1.0,
		GameState.state.resources.temporal_energy_max
	)

	AgentManager.return_agent(mission.agent_id, rewards)
	GameState.emit_signal("mission_complete", mission.agent_id, mission.era_id, rewards)
	GameState.emit_signal("state_changed")
