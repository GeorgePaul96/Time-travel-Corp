extends Node

var offline_popup_data: Dictionary = {}

func _ready() -> void:
	_boot()

func _boot() -> void:
	var loaded = SaveManager.load_game()
	if loaded:
		offline_popup_data = SaveManager.calculate_offline_rewards()
	else:
		GameState.initialize_state()

	AgentManager.create_starter_agent()
	_apply_starting_echo_upgrades()
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
		# Hire second starter agent if capacity allows
		if GameState.state.agents.size() < 2 and AgentManager.can_hire():
			AgentManager.hire_agent()

func _on_tick_timer_timeout() -> void:
	EraManager.tick(1.0)
	GameState.apply_passive_income()
	GameState.decay_stability()
	EventManager.try_fire_event()
	EventManager.tick_event_countdown()
	SaveManager.save()

func get_offline_popup_data() -> Dictionary:
	return offline_popup_data

func clear_offline_popup_data() -> void:
	offline_popup_data = {}
