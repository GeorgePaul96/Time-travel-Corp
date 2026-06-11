extends Node

const SAVE_PATH = "user://meta_state.json"
const SAVE_VERSION = 1

var state: Dictionary = {}

func _ready() -> void:
	reset()

func reset() -> void:
	state = {
		"version": SAVE_VERSION,
		"total_runs": 0,
		"unlocked_content": []
	}

func load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		reset()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var parsed = JSON.parse_string(json_string)
		if parsed and typeof(parsed) == TYPE_DICTIONARY:
			state = parsed
			if not state.has("version"):
				state["version"] = SAVE_VERSION
			print("MetaState: Loaded successfully.")
		else:
			push_error("MetaState: Failed to parse save file.")
			reset()

func save() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state))
		print("MetaState: Saved successfully.")
	else:
		push_error("MetaState: Could not write save file.")
