extends Node

signal state_changed
signal node_mutated(node_id: String, new_state: String)

var state: Dictionary = {}

func _ready() -> void:
	initialize_state()

func initialize_state() -> void:
	state = {
		"resources": {
			"capital": 0.0,
			"energy": 100.0,
			"energy_max": 100.0,
			"anomalies": 0.0
		},
		"nodes": {
			"antiquity": {
				"stability": 100.0,
				"is_mutated": false,
				"active_extractors": 0
			},
			"middle_ages": {
				"stability": 100.0,
				"is_mutated": false,
				"active_extractors": 0
			},
			"industrial": {
				"stability": 100.0,
				"is_mutated": false,
				"active_extractors": 0
			},
			"future": {
				"stability": 100.0,
				"is_mutated": false,
				"active_extractors": 0
			}
		},
		"upgrades": {
			"stability_regen": 0,
			"energy_regen": 0,
			"production_bonus": 0
		},
		"last_save_timestamp": int(Time.get_unix_time_from_system())
	}

func _process(delta: float) -> void:
	# Energy regen
	var energy_regen_rate = 1.0 + (state.upgrades.energy_regen * 0.5)
	state.resources.energy = min(state.resources.energy + energy_regen_rate * delta, state.resources.energy_max)

	# Node processing
	for node_id in state.nodes:
		var node = state.nodes[node_id]
		var base_stability_regen = 0.5 + (state.upgrades.stability_regen * 0.2)
		var stability_drain = node.active_extractors * 2.0

		# Apply stability changes
		node.stability = clamp(node.stability + (base_stability_regen - stability_drain) * delta, 0.0, 100.0)

		# Check for mutation
		if node.stability <= 0.0 and not node.is_mutated:
			node.is_mutated = true
			node_mutated.emit(node_id, "mutated")
		elif node.stability > 0.0 and node.is_mutated:
			# Mutations must be manually patched, but if we decide otherwise later, handle it here.
			pass

		# Resource generation
		if node.active_extractors > 0:
			var production = calculate_node_production(node_id) * delta
			if node.is_mutated:
				# Mutated nodes produce anomalies instead of capital (or both depending on design)
				state.resources.anomalies += production * 0.1 # Example rate
			else:
				state.resources.capital += production

	state_changed.emit()

func calculate_node_production(node_id: String) -> float:
	var node = state.nodes[node_id]
	if node.active_extractors == 0:
		return 0.0

	var base_production = 0.0
	match node_id:
		"antiquity": base_production = 1.0
		"middle_ages": base_production = 2.0
		"industrial": base_production = 5.0
		"future": base_production = 10.0

	var multiplier = 1.0 + (state.upgrades.production_bonus * 0.1)

	# Dependency multipliers
	if node_id == "middle_ages":
		multiplier *= (state.nodes["antiquity"].stability / 100.0)
	elif node_id == "industrial":
		multiplier *= (state.nodes["middle_ages"].stability / 100.0)
	elif node_id == "future":
		multiplier *= (state.nodes["industrial"].stability / 100.0)

	if node.is_mutated:
		# Mutated nodes might have a fixed anomaly rate or scaled based on extractors
		return float(node.active_extractors) * 5.0 # Anomalies per extractor multiplier

	return base_production * float(node.active_extractors) * multiplier

func add_extractor(node_id: String) -> bool:
	if state.resources.energy >= 10.0:
		state.resources.energy -= 10.0
		state.nodes[node_id].active_extractors += 1
		state_changed.emit()
		return true
	return false

func remove_extractor(node_id: String) -> void:
	if state.nodes[node_id].active_extractors > 0:
		state.nodes[node_id].active_extractors -= 1
		state_changed.emit()

func patch_node(node_id: String) -> bool:
	if state.nodes[node_id].is_mutated and state.resources.energy >= 50.0:
		state.resources.energy -= 50.0
		state.nodes[node_id].is_mutated = false
		state.nodes[node_id].stability = 50.0 # Reset to a safe value
		node_mutated.emit(node_id, "restored")
		state_changed.emit()
		return true
	return false

func prestige() -> void:
	var anomalies_gained = floor(state.resources.capital / 1000.0) # Simple formula
	var total_anomalies = state.resources.anomalies + anomalies_gained
	var upgrades = state.upgrades.duplicate()
	initialize_state()
	state.resources.anomalies = total_anomalies
	state.upgrades = upgrades
	state_changed.emit()

func buy_upgrade(upgrade_id: String, cost: float) -> bool:
	if state.resources.anomalies >= cost:
		state.resources.anomalies -= cost
		if state.upgrades.has(upgrade_id):
			state.upgrades[upgrade_id] += 1
			state_changed.emit()
			return true
	return false
