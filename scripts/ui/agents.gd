extends Control

@onready var hire_btn: Button = $VBoxContainer/HireBtn
@onready var hire_cost_label: Label = $VBoxContainer/HireCostLabel
@onready var agent_list: VBoxContainer = $VBoxContainer/AgentList

func _ready() -> void:
    GameState.state_changed.connect(_refresh)
    hire_btn.pressed.connect(_hire_agent)
    _refresh()

func _refresh() -> void:
    var cost = AgentManager.get_hire_cost()
    hire_btn.text = "HIRE AGENT"
    hire_btn.disabled = not AgentManager.can_hire()
    hire_cost_label.text = "Cost: %.0f ₢" % cost
    _rebuild_agent_list()

func _hire_agent() -> void:
    AgentManager.hire_agent()

func _rebuild_agent_list() -> void:
    for child in agent_list.get_children():
        child.queue_free()
    for agent in GameState.state.agents:
        _add_agent_row(agent)

func _add_agent_row(agent: Dictionary) -> void:
    var row = HBoxContainer.new()
    var title = AgentManager.get_agent_title(agent.level)
    var info = Label.new()
    info.text = "%s — Lv.%d %s [%s]" % [agent.name, agent.level, title, agent.status]
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(info)

    if agent.status == "IDLE":
        var dispatch_btn = Button.new()
        dispatch_btn.text = "DISPATCH"
        var agent_id = agent.id
        dispatch_btn.pressed.connect(func(): _show_dispatch_options(agent_id))
        row.add_child(dispatch_btn)
    elif agent.status == "CAPTURED":
        var ransom_btn = Button.new()
        ransom_btn.text = "RANSOM (10K ₢)"
        var agent_id = agent.id
        ransom_btn.pressed.connect(func(): AgentManager.ransom_agent(agent_id))
        row.add_child(ransom_btn)

    agent_list.add_child(row)

func _show_dispatch_options(agent_id: String) -> void:
    for era_id in GameState.state.eras_unlocked:
        if AgentManager.can_dispatch(agent_id, era_id):
            AgentManager.dispatch_agent(agent_id, era_id)
            return
