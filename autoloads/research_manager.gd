extends Node

# Additive bonuses applied by each node when unlocked.
const NODE_EFFECTS: Dictionary = {
	"TM-1": {"te_cost_reduction": 0.2},
	"TM-2": {"te_max": 1.0},
	"TM-3": {"mission_fail_reduction": 0.1},
	"TM-4": {"te_regen_bonus": 0.5},
	"TM-5": {"te_max": 3.0},
	"TM-6": {"extra_mission_slot": 1.0},
	"AE-1": {"efficiency": 0.05},
	"AE-2": {"speed": 0.05},
	"AE-3": {"efficiency": 0.10},
	"AE-4": {"speed": 0.10},
	"AE-5": {"luck": 0.10},
	"AE-6": {"resilience": 0.15},
	"AE-7": {"efficiency": 0.15, "speed": 0.05, "luck": 0.05, "resilience": 0.05},
	"AE-8": {},
	"RM-1": {"credits": 0.25},
	"RM-2": {"historical_data": 0.50},
	"RM-3": {"artifact_chance": 0.10},
	"RM-4": {"knowledge": 0.30},
	"RM-5": {},
	"RM-6": {"historical_data": 1.00},
	"RM-7": {"credits": 0.50},
	"RM-8": {"credits": 0.20, "knowledge": 0.20, "historical_data": 0.20, "influence": 0.20},
	"TS-1": {},
	"TS-2": {},
	"TS-3": {},
	"TS-4": {},
	"TS-5": {},
	"TS-6": {},
	"TS-7": {},
	"CE-1": {},
	"CE-2": {},
	"CE-3": {},
	"CE-4": {},
	"CE-5": {},
	"CE-6": {}
}

var nodes: Dictionary = {}

func _ready() -> void:
	_load_tree()

func _load_tree() -> void:
	var file = FileAccess.open("res://data/research_tree.json", FileAccess.READ)
	if not file:
		push_error("ResearchManager: cannot open research_tree.json")
		return
	var data = JSON.parse_string(file.get_as_text())
	if data == null or not data is Array:
		push_error("ResearchManager: failed to parse research_tree.json")
		return
	for node in data:
		nodes[node.id] = node

func get_node_data(node_id: String) -> Dictionary:
	return nodes.get(node_id, {})

func get_nodes_by_category(category: String) -> Array:
	var result: Array = []
	for node in nodes.values():
		if node.get("category", "") == category:
			result.append(node)
	return result

func can_unlock(node_id: String) -> bool:
	if node_id in GameState.state.research_unlocked:
		return false
	var node = nodes.get(node_id, {})
	if node.is_empty():
		return false
	for prereq in node.get("prerequisites", []):
		if not prereq in GameState.state.research_unlocked:
			return false
	var cost_mult = _get_cost_multiplier()
	if GameState.get_resource("knowledge") < float(node.get("cost_knowledge", 0.0)) * cost_mult:
		return false
	if GameState.get_resource("artifacts") < float(node.get("cost_artifacts", 0)):
		return false
	return true

func unlock_node(node_id: String) -> void:
	if not can_unlock(node_id):
		return
	var node = nodes.get(node_id, {})
	var cost_mult = _get_cost_multiplier()
	GameState.add_resource("knowledge", -float(node.get("cost_knowledge", 0.0)) * cost_mult)
	if float(node.get("cost_artifacts", 0)) > 0:
		GameState.add_resource("artifacts", -float(node.get("cost_artifacts", 0)))
	GameState.state.research_unlocked.append(node_id)
	_apply_immediate_effects(node_id)
	GameState.emit_signal("state_changed")

func _apply_immediate_effects(node_id: String) -> void:
	var effects = NODE_EFFECTS.get(node_id, {})
	if effects.has("te_max"):
		GameState.state.resources.temporal_energy_max += effects.te_max
		GameState.state.resources.temporal_energy = minf(
			GameState.state.resources.temporal_energy + effects.te_max,
			GameState.state.resources.temporal_energy_max
		)

func _get_cost_multiplier() -> float:
	var mult = 1.0
	if "CE-2" in GameState.state.research_unlocked:
		mult *= 0.75
	if "research_department" in GameState.state.departments:
		mult *= 0.75
	return mult

func get_multiplier(resource_key: String) -> float:
	var total = 1.0
	for node_id in GameState.state.research_unlocked:
		var effects = NODE_EFFECTS.get(node_id, {})
		total += float(effects.get(resource_key, 0.0))
	return maxf(total, 0.01)

func get_flat_bonus(stat_key: String) -> float:
	var total = 0.0
	for node_id in GameState.state.research_unlocked:
		var effects = NODE_EFFECTS.get(node_id, {})
		total += float(effects.get(stat_key, 0.0))
	return total

func get_stability_floor() -> float:
	if "TS-6" in GameState.state.research_unlocked:
		return 40.0
	if "TS-3" in GameState.state.research_unlocked:
		return 20.0
	return 0.0

func get_max_missions() -> int:
	if "TM-6" in GameState.state.research_unlocked:
		return 2
	return 1

func get_event_stability_reduction() -> float:
	var reduction = 0.0
	if "TS-2" in GameState.state.research_unlocked:
		reduction += 0.15
	if "TS-5" in GameState.state.research_unlocked:
		reduction += 0.30
	return minf(reduction, 0.9)
