extends Control

@onready var resource_strip: HBoxContainer = $VBoxContainer/ResourceStrip
@onready var stat_grid: GridContainer = $VBoxContainer/MainArea/LeftPanel/StatGrid
@onready var ops_log: RichTextLabel = $VBoxContainer/MainArea/LeftPanel/OpsLog
@onready var mission_list: VBoxContainer = $VBoxContainer/MainArea/RightPanel/MissionList

const RESOURCE_KEYS = [
    "credits", "knowledge", "artifacts", "historical_data",
    "temporal_energy", "influence", "stability", "reputation"
]
const RESOURCE_LABELS = [
    "Credits", "Knowledge", "Artifacts", "Hist. Data",
    "Temp. Energy", "Influence", "Stability", "Reputation"
]

var _log_entries: Array = []

func _ready() -> void:
    GameState.state_changed.connect(_refresh)
    GameState.mission_complete.connect(_on_mission_complete)
    GameState.agent_leveled_up.connect(_on_agent_leveled_up)
    _build_resource_strip()
    _refresh()

func _build_resource_strip() -> void:
    for i in range(RESOURCE_KEYS.size()):
        var col = VBoxContainer.new()
        col.size_flags_horizontal = SIZE_EXPAND_FILL
        var label = Label.new()
        label.text = RESOURCE_LABELS[i]
        label.name = "Label"
        var value = Label.new()
        value.name = "Value"
        value.text = "0"
        col.add_child(label)
        col.add_child(value)
        resource_strip.add_child(col)

func _refresh() -> void:
    _update_resources()
    _update_stats()
    _update_missions()

func _update_resources() -> void:
    for i in range(RESOURCE_KEYS.size()):
        var col = resource_strip.get_child(i)
        if col == null:
            continue
        var value_label = col.get_node_or_null("Value")
        if value_label == null:
            continue
        var val = GameState.get_resource(RESOURCE_KEYS[i])
        if RESOURCE_KEYS[i] == "temporal_energy":
            var max_te = GameState.get_resource("temporal_energy_max")
            value_label.text = "%d / %d" % [int(val), int(max_te)]
        elif RESOURCE_KEYS[i] == "stability":
            value_label.text = "%.0f / 100" % val
        elif val >= 1000000.0:
            value_label.text = "%.1fM" % (val / 1000000.0)
        elif val >= 1000.0:
            value_label.text = "%.1fK" % (val / 1000.0)
        else:
            value_label.text = "%.0f" % val

func _update_stats() -> void:
    for child in stat_grid.get_children():
        child.queue_free()
    var agents = GameState.state.agents
    var active = 0
    for a in agents:
        if a.get("status", "") == "DEPLOYED":
            active += 1
    _add_stat("Agents", "%d / %d" % [active, agents.size()])
    _add_stat("Eras Unlocked", "%d / 8" % GameState.state.eras_unlocked.size())
    _add_stat("Research", "%d / 35" % GameState.state.research_unlocked.size())
    _add_stat("Prestige Runs", str(GameState.state.prestige_count))

func _add_stat(label_text: String, value_text: String) -> void:
    var lbl = Label.new()
    lbl.text = label_text + ":"
    stat_grid.add_child(lbl)
    var val = Label.new()
    val.text = value_text
    stat_grid.add_child(val)

func _update_missions() -> void:
    for child in mission_list.get_children():
        child.queue_free()
    if GameState.state.active_missions.is_empty():
        var empty_label = Label.new()
        empty_label.text = "[no active missions]"
        mission_list.add_child(empty_label)
        return
    for mission in GameState.state.active_missions:
        var agent = AgentManager.get_agent(mission.agent_id)
        var era = EraManager.get_era(mission.era_id)
        var row = HBoxContainer.new()
        var info = VBoxContainer.new()
        info.size_flags_horizontal = SIZE_EXPAND_FILL
        var name_label = Label.new()
        name_label.text = agent.name if agent else mission.agent_id
        var era_label = Label.new()
        era_label.text = era.get("name", mission.era_id) if not era.is_empty() else mission.era_id
        var time_label = Label.new()
        var remaining = float(mission.time_remaining)
        var mins = int(remaining) / 60
        var secs = int(remaining) % 60
        time_label.text = "%d:%02d" % [mins, secs]
        info.add_child(name_label)
        info.add_child(era_label)
        row.add_child(info)
        row.add_child(time_label)
        mission_list.add_child(row)

func _on_mission_complete(agent_id: String, era_id: String, rewards: Dictionary) -> void:
    var agent = AgentManager.get_agent(agent_id)
    var era = EraManager.get_era(era_id)
    var credits = snappedf(rewards.get("credits", 0.0), 0.1)
    var agent_name = agent.name if agent else agent_id
    var era_name = era.get("name", era_id) if not era.is_empty() else era_id
    _add_log_entry("%s returned from %s. +%.0f Credits" % [agent_name, era_name, credits])
    if not GameState.state.has("total_missions"):
        GameState.state["total_missions"] = 0
    GameState.state.total_missions += 1

func _on_agent_leveled_up(agent_id: String, new_level: int) -> void:
    var agent = AgentManager.get_agent(agent_id)
    var agent_name = agent.name if agent else agent_id
    var title = AgentManager.get_agent_title(new_level)
    _add_log_entry("%s reached Lv.%d — %s" % [agent_name, new_level, title])

func _add_log_entry(text: String) -> void:
    _log_entries.append(text)
    if _log_entries.size() > 50:
        _log_entries.remove_at(0)
    if is_instance_valid(ops_log):
        ops_log.text = "\n".join(_log_entries.slice(-20))
