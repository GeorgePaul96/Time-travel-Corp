extends Node

const SAVE_KEY = "ttc_save_v2"
const MAX_OFFLINE_SECONDS = 86400

func save() -> void:
	GameManager.state.last_save_timestamp = int(Time.get_unix_time_from_system())
	var json_string = JSON.stringify(GameManager.state)
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
	GameManager.state = parsed
	return true

func calculate_offline_progress() -> void:
	var now = int(Time.get_unix_time_from_system())
	var last = int(GameManager.state.get("last_save_timestamp", now))
	var elapsed = mini(now - last, MAX_OFFLINE_SECONDS)
	if elapsed < 10:
		return

	# Simple offline progression simulation (could be improved)
	for i in range(elapsed):
		# Simulate 1 second steps to handle stability/mutations correctly
		GameManager._process(1.0)

	# Force save timestamp update
	GameManager.state.last_save_timestamp = now

func _save_web(json_string: String) -> void:
	var escaped = json_string.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n").replace("\r", "\\r")
	JavaScriptBridge.eval("localStorage.setItem('" + SAVE_KEY + "', '" + escaped + "')")

func _load_web() -> String:
	var result = JavaScriptBridge.eval("localStorage.getItem('" + SAVE_KEY + "') || ''")
	if result == null:
		return ""
	return str(result)

func _save_file(json_string: String) -> void:
	var file = FileAccess.open("user://save_v2.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)

func _load_file() -> String:
	if not FileAccess.file_exists("user://save_v2.json"):
		return ""
	var file = FileAccess.open("user://save_v2.json", FileAccess.READ)
	if not file:
		return ""
	return file.get_as_text()
