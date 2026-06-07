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
			# Write directly to avoid emitting state_changed per-resource during boot
			if GameState.state.resources.has(resource):
				GameState.state.resources[resource] = float(GameState.state.resources[resource]) + amount
				if resource == "credits" and amount > 0.0:
					GameState.state.total_credits_earned += amount
	# Resolve all active missions as complete (TE is a lock, not consumed)
	GameState.state.active_missions.clear()
	GameState.state.resources.temporal_energy = GameState.state.resources.temporal_energy_max
	# Reset all agent statuses to IDLE
	for agent in GameState.state.agents:
		agent.status = "IDLE"
	GameState.state_changed.emit()
	return {"elapsed_seconds": elapsed, "rewards": rewards}

func _save_web(json_string: String) -> void:
	var escaped = json_string.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("\r", "\\r")
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
