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
	if data == null or not data is Array:
		push_error("EventManager: failed to parse events.json")
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
	if total <= 0:
		return
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
	if choice_index >= choices.size() or choice_index < 0:
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
	for i in range(GameState.state.active_missions.size()):
		var mission = GameState.state.active_missions[i]
		AgentManager.set_agent_captured(mission.agent_id)
		GameState.state.active_missions.remove_at(i)
		GameState.state.resources.temporal_energy = minf(
			GameState.state.resources.temporal_energy + 1.0,
			GameState.state.resources.temporal_energy_max
		)
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
	if not no_rewards:
		# Full base rewards for the era (no efficiency bonus for aborted missions)
		var era = EraManager.get_era(mission.era_id)
		if not era.is_empty():
			GameState.add_resource("credits", float(era.get("base_credits", 0.0)))
			GameState.add_resource("knowledge", float(era.get("base_knowledge", 0.0)))
			GameState.add_resource("historical_data", float(era.get("base_historical_data", 0.0)))

func get_active_event() -> Dictionary:
	return _active_event

func get_event_countdown() -> float:
	return _event_countdown

func get_knowledge_multiplier() -> float:
	if _knowledge_boost_timer > 0.0:
		return _knowledge_boost_mult
	return 1.0
