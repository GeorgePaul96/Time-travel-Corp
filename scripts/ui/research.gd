extends Control

@onready var node_list: VBoxContainer = $VBoxContainer/NodeList

const CATEGORIES = ["time_machines","agent_efficiency","resource_multipliers","timeline_stability","corp_expansion"]
const CATEGORY_LABELS = ["Time Machines","Agent Efficiency","Resource Multipliers","Timeline Stability","Corp Expansion"]

func _ready() -> void:
    GameState.state_changed.connect(_refresh)
    _refresh()

func _refresh() -> void:
    for child in node_list.get_children():
        child.queue_free()
    for i in range(CATEGORIES.size()):
        _add_category(CATEGORIES[i], CATEGORY_LABELS[i])

func _add_category(category: String, label: String) -> void:
    var header = Label.new()
    header.text = "── %s ──" % label
    node_list.add_child(header)
    var cat_nodes = ResearchManager.get_nodes_by_category(category)
    for node in cat_nodes:
        _add_node_row(node)

func _add_node_row(node: Dictionary) -> void:
    var row = HBoxContainer.new()
    var unlocked = node.id in GameState.state.research_unlocked
    var can = ResearchManager.can_unlock(node.id)

    var info = Label.new()
    var prefix = "✓ " if unlocked else ("  " if can else "🔒 ")
    info.text = "%s%s — %s (%.0f K)" % [prefix, node.get("name","?"), node.get("description",""), node.get("cost_knowledge",0)]
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(info)

    if not unlocked:
        var btn = Button.new()
        btn.text = "UNLOCK"
        btn.disabled = not can
        var node_id = node.id
        btn.pressed.connect(func(): ResearchManager.unlock_node(node_id))
        row.add_child(btn)

    node_list.add_child(row)
