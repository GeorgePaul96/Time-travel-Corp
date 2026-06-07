extends Node


func _ready() -> void:
	pass

func get_agent(_agent_id: String):
	return null

func get_agent_stats(_agent_id: String) -> Dictionary:
	return {"efficiency": 1.0, "speed": 0.0, "luck": 0.05, "resilience": 0.0}

func get_hire_cost() -> float:
	return 200.0

func can_hire() -> bool:
	return false

func get_agent_cap() -> int:
	return 3

func create_starter_agent() -> void:
	pass

func get_agent_title(_level: int) -> String:
	return "Agent"
