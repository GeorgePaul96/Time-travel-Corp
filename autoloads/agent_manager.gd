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
		push_error("AgentManager: failed to parse agent_tiers.json")
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
	var cost = get_hire_cost()
	if not (GameState.state.agents.size() < get_agent_cap()
			and GameState.get_resource("credits") >= cost):
		return
	GameState.add_resource("credits", -cost)
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
	if era.is_empty():
		push_error("AgentManager: cannot dispatch to unknown era: " + era_id)
		return
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
		agent.stat_boosts["efficiency"] = float(agent.stat_boosts.get("efficiency", 0.0)) + 0.15

func get_agent_stats(agent_id: String) -> Dictionary:
	var agent = get_agent(agent_id)
	if agent == null:
		return {"efficiency": 1.0, "speed": 0.0, "luck": 0.05, "resilience": 0.0}
	var t = clampf(float(agent.level - 1) / 99.0, 0.0, 1.0)
	var efficiency  = (1.0 + 2.0 * t) + float(agent.stat_boosts.get("efficiency", 0.0))
	var speed       = (0.5 * t)        + float(agent.stat_boosts.get("speed", 0.0))
	var luck        = (0.05 + 0.45 * t) + float(agent.stat_boosts.get("luck", 0.0))
	var resilience  = (0.6 * t)        + float(agent.stat_boosts.get("resilience", 0.0))
	efficiency += ResearchManager.get_flat_bonus("efficiency")
	speed      += ResearchManager.get_flat_bonus("speed")
	luck       += ResearchManager.get_flat_bonus("luck")
	resilience += ResearchManager.get_flat_bonus("resilience")
	return {"efficiency": efficiency, "speed": speed, "luck": luck, "resilience": resilience}
