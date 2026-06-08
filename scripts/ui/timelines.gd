extends Control

@onready var era_list: VBoxContainer = $VBoxContainer/EraList

func _ready() -> void:
    GameState.state_changed.connect(_refresh)
    _refresh()

func _refresh() -> void:
    for child in era_list.get_children():
        child.queue_free()
    for era in EraManager.get_all_eras():
        _add_era_row(era)

func _add_era_row(era: Dictionary) -> void:
    var row = HBoxContainer.new()
    var unlocked = era.id in GameState.state.eras_unlocked

    var name_label = Label.new()
    name_label.text = era.get("name", "Unknown")
    name_label.custom_minimum_size.x = 180

    var status_label = Label.new()
    var risk = int(era.get("risk", 1))
    status_label.text = "Risk: %d/5 | %ds" % [risk, int(era.get("duration", 60))]
    status_label.custom_minimum_size.x = 150

    var action_btn = Button.new()
    if not unlocked:
        var cost = era.get("unlock_cost", {})
        if cost.is_empty():
            action_btn.text = "UNLOCKED"
            action_btn.disabled = true
        else:
            action_btn.text = "UNLOCK"
            action_btn.disabled = not EraManager.can_unlock(era.id)
            action_btn.pressed.connect(func(): _unlock_era(era.id))
    else:
        action_btn.text = "DISPATCH"
        var idle_agent = _get_idle_agent()
        action_btn.disabled = (idle_agent == "" or not AgentManager.can_dispatch(idle_agent, era.id))
        action_btn.pressed.connect(func(): _dispatch_to_era(era.id))

    row.add_child(name_label)
    row.add_child(status_label)
    row.add_child(action_btn)
    era_list.add_child(row)

func _unlock_era(era_id: String) -> void:
    EraManager.unlock_era(era_id)

func _dispatch_to_era(era_id: String) -> void:
    var idle_agent = _get_idle_agent()
    if idle_agent != "":
        AgentManager.dispatch_agent(idle_agent, era_id)

func _get_idle_agent() -> String:
    for agent in GameState.state.agents:
        if agent.status == "IDLE":
            return agent.id
    return ""
