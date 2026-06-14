extends Node

## Central repository for all static game content.
## Loads, validates, and indexes resources at boot.

var _registry: Dictionary = {}       # id -> Resource
var _type_index: Dictionary = {}     # class_name string -> Array[Resource]

func load_all_content() -> void:
	_registry.clear()
	_type_index.clear()

	var dirs := [
		"res://resources/eras",
		"res://resources/fronts",
		"res://resources/mutations",
		"res://resources/extractors",
		"res://resources/contracts",
		"res://resources/directives",
		"res://resources/incidents",
		"res://resources/modifiers",
		"res://resources/mandates",
	]

	for dir_path in dirs:
		var dir := DirAccess.open(dir_path)
		if not dir:
			continue
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res := load(dir_path + "/" + file_name)
				if res and res.get("id") != null:
					var id = res.id
					if id != &"" and id != "":
						_registry[id] = res
						var type_name := ""
						var script := res.get_script() as Script
						if script:
							type_name = script.get_global_name()
						if type_name == "":
							type_name = res.get_class()
						
						if not _type_index.has(type_name):
							_type_index[type_name] = []
						_type_index[type_name].append(res)
			file_name = dir.get_next()

	EventBus.content_loaded.emit()

func validate_content() -> void:
	var errors: Array = []

	for id in _registry:
		if not is_instance_valid(_registry[id]):
			errors.append("Invalid resource instance for ID: " + str(id))

	if errors.size() > 0:
		EventBus.content_validation_failed.emit(errors)
		for err in errors:
			push_error("ContentDB: " + err)
	else:
		print("ContentDB: All content valid. %d resources loaded." % _registry.size())

func get_by_id(id: StringName) -> Resource:
	if _registry.has(id):
		return _registry[id]
	return null

func get_all_of_type(type_name: String) -> Array:
	return _type_index.get(type_name, []).duplicate()

func get_all_contracts() -> Array[ContractDef]:
	var result: Array[ContractDef] = []
	for r in _type_index.get("ContractDef", []):
		result.append(r as ContractDef)
	result.sort_custom(func(a, b): return a.tier < b.tier)
	return result
