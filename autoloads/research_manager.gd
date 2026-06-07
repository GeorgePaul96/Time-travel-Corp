extends Node


func _ready() -> void:
	pass

func get_stability_floor() -> float:
	return 0.0

func get_multiplier(_resource_key: String) -> float:
	return 1.0

func get_flat_bonus(_stat_key: String) -> float:
	return 0.0

func get_max_missions() -> int:
	return 1

func get_event_stability_reduction() -> float:
	return 0.0
