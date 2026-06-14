extends Node

const SAVE_PATH := "user://meta_state.json"
const SCHEMA := 2

var state: Dictionary = {}

var unlocked_nodes: Array:
	get:
		return state.get("unlocked_nodes", [])

var audit_level: int:
	get:
		return state.get("audit_level", 0)

func _ready() -> void:
	reset()

func reset() -> void:
	state = {
		"schema": SCHEMA,
		"anomalies": 0,
		"unlocked_nodes": [],
		"ladder_tier": 1,
		"audit_level": 0,
		"completed_contracts": [],
		"lifetime_stats": {
			"runs_completed": 0,
			"runs_won": 0,
			"total_capital": 0.0,
			"total_mutations": 0,
			"total_harvests": 0,
		}
	}

func load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		reset()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		reset()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed or not parsed is Dictionary:
		push_error("MetaState: corrupt save — resetting.")
		reset()
		return
	state = _migrate(parsed)

func save() -> void:
	var tmp := SAVE_PATH + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if not file:
		push_error("MetaState: cannot write save.")
		return
	file.store_string(JSON.stringify(state))
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.rename_absolute(tmp, SAVE_PATH)

func complete_run(result: Dictionary) -> void:
	state.lifetime_stats.runs_completed += 1
	if result.get("won", false):
		state.lifetime_stats.runs_won += 1
		var cid = result.get("contract_id", &"")
		if cid != &"" and not state.completed_contracts.has(cid):
			state.completed_contracts.append(cid)
		
		# Ladder tier progress (tier+1)
		var contract := ContentDB.get_by_id(cid) as ContractDef
		if contract:
			state.ladder_tier = max(state.ladder_tier, contract.tier + 1)

	state.lifetime_stats.total_capital += result.get("capital", 0.0)
	state.lifetime_stats.total_mutations += result.get("mutations", 0)
	state.anomalies += int(result.get("anomalies_earned", 0))
	save()

func buy_upgrade(node_id: StringName, cost: int) -> bool:
	if state.anomalies >= cost and not state.unlocked_nodes.has(node_id):
		state.anomalies -= cost
		state.unlocked_nodes.append(node_id)
		save()
		return true
	return false

func _migrate(data: Dictionary) -> Dictionary:
	if int(data.get("schema", 1)) < 2:
		if not data.has("anomalies"): data["anomalies"] = 0
		if not data.has("unlocked_nodes"): data["unlocked_nodes"] = []
		if not data.has("ladder_tier"): data["ladder_tier"] = 1
		if not data.has("audit_level"): data["audit_level"] = 0
		if not data.has("completed_contracts"): data["completed_contracts"] = []
		if not data.has("lifetime_stats"):
			data["lifetime_stats"] = {
				"runs_completed": 0, "runs_won": 0,
				"total_capital": 0.0, "total_mutations": 0, "total_harvests": 0
			}
		data["schema"] = SCHEMA
	return data
