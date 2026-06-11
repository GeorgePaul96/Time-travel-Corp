extends Node

## Central repository for all static game content.
## Loads, validates, and indexes resources at boot.

var content_registry: Dictionary = {}

func load_all_content() -> void:
	content_registry.clear()

	var resource_dirs = [
		"res://resources/contracts",
		"res://resources/eras",
		"res://resources/fronts",
		"res://resources/incidents",
		"res://resources/directives",
		"res://resources/modifiers",
		"res://resources/mutations"
	]

	for dir_path in resource_dirs:
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir.current_is_dir() and file_name.ends_with(".tres"):
					var res_path = dir_path + "/" + file_name
					var res = load(res_path)
					if res and res.get("id"):
						content_registry[res.id] = res
				file_name = dir.get_next()

	EventBus.content_loaded.emit()

func validate_content() -> void:
	var errors: Array = []
	var seen_ids: Dictionary = {}

	for id in content_registry:
		# Check for duplicates (though Dictionary keys naturally prevent this,
		# we would ideally check during the load phase if we were tracking paths.
		# For Phase 0, we ensure the ID is valid.)
		if id == "":
			errors.append("Resource loaded with empty ID string.")

		var res = content_registry[id]
		# Basic reference validation check (example)
		# Phase 0 logic: Ensure all resources actually cast properly.
		if not is_instance_valid(res):
			errors.append("Invalid resource instance found for ID: " + id)

	if errors.size() > 0:
		EventBus.content_validation_failed.emit(errors)
		for err in errors:
			push_error("ContentDB Validation Error: " + err)
	else:
		print("ContentDB: All content validated successfully.")

func get_by_id(id: String) -> Resource:
	if content_registry.has(id):
		return content_registry[id]
	push_warning("ContentDB: Content not found for ID " + id)
	return null
