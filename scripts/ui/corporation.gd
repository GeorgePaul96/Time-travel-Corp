extends Control

@onready var dept_list: VBoxContainer = $VBoxContainer/DeptList
@onready var prestige_btn: Button = $VBoxContainer/PrestigeBtn
@onready var prestige_info: Label = $VBoxContainer/PrestigeInfo
@onready var echo_label: Label = $VBoxContainer/EchoLabel
@onready var echo_list: VBoxContainer = $VBoxContainer/EchoList

const DEPARTMENTS = [
    {"id":"hr_department","name":"HR Department","desc":"Max agents +5, hire cost -20%","cost_credits":10000.0,"cost_influence":100.0},
    {"id":"research_department","name":"Research Department","desc":"All research -25%","cost_credits":15000.0,"cost_knowledge":200.0},
    {"id":"security_department","name":"Security Department","desc":"Stability decay -30%, event damage -20%","cost_credits":20000.0,"cost_influence":300.0},
    {"id":"marketing_department","name":"Marketing Department","desc":"Credits +25%, Reputation +20%","cost_credits":25000.0,"cost_influence":0.0},
    {"id":"timeline_intelligence","name":"Timeline Intelligence","desc":"Event outcomes revealed, mission fail -15%","cost_credits":50000.0,"cost_influence":500.0}
]

const ECHO_UPGRADES = [
    {"id":"E-01","name":"Chrono Foundation","desc":"All income +10%","cost":1},
    {"id":"E-02","name":"Temporal Memory","desc":"Start with 2 agents","cost":2},
    {"id":"E-03","name":"Echo Resonance","desc":"Echoes earned +25%","cost":2},
    {"id":"E-04","name":"Quick Start","desc":"Egypt unlocked from start","cost":3},
    {"id":"E-05","name":"Veteran Agents","desc":"Agents start at Level 5","cost":3},
    {"id":"E-06","name":"Stability Mastery","desc":"Start with 90 Stability","cost":3},
    {"id":"E-07","name":"Resource Cache","desc":"Start with 1,000 ₢","cost":5},
    {"id":"E-08","name":"Knowledge Legacy","desc":"Start with 100 Knowledge","cost":5},
    {"id":"E-09","name":"Income Surge","desc":"All income +25%","cost":5},
    {"id":"E-10","name":"Time Veteran","desc":"Agent XP +25%","cost":5},
    {"id":"E-11","name":"Research Head Start","desc":"First 5 nodes -50%","cost":8},
    {"id":"E-12","name":"Corporate Memory","desc":"Departments -20%","cost":8},
    {"id":"E-13","name":"Temporal Dynasty","desc":"All income +50%","cost":10},
    {"id":"E-14","name":"Paradox Veteran","desc":"Start with TS-1+TS-2","cost":12},
    {"id":"E-15","name":"CEO of Time","desc":"All income x2","cost":20}
]

func _ready() -> void:
    GameState.state_changed.connect(_refresh)
    prestige_btn.pressed.connect(_do_prestige)
    _refresh()

func _refresh() -> void:
    _update_departments()
    _update_prestige()
    _update_echo_shop()

func _update_departments() -> void:
    for child in dept_list.get_children():
        child.queue_free()
    for dept in DEPARTMENTS:
        _add_dept_row(dept)

func _add_dept_row(dept: Dictionary) -> void:
    var owned = dept.id in GameState.state.departments
    var row = HBoxContainer.new()
    var info = Label.new()
    info.text = ("[OWNED] " if owned else "") + dept.name + " — " + dept.desc
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(info)
    if not owned:
        var btn = Button.new()
        btn.text = "BUY (%.0f ₢)" % dept.cost_credits
        btn.disabled = not _can_buy_dept(dept)
        var dept_id = dept.id
        btn.pressed.connect(func(): _buy_dept(dept_id, dept))
        row.add_child(btn)
    dept_list.add_child(row)

func _can_buy_dept(dept: Dictionary) -> bool:
    if dept.id in GameState.state.departments:
        return false
    if GameState.get_resource("credits") < dept.cost_credits:
        return false
    if dept.get("cost_influence", 0.0) > 0 and GameState.get_resource("influence") < dept.cost_influence:
        return false
    if dept.get("cost_knowledge", 0.0) > 0 and GameState.get_resource("knowledge") < dept.cost_knowledge:
        return false
    return true

func _buy_dept(dept_id: String, dept: Dictionary) -> void:
    GameState.add_resource("credits", -dept.cost_credits)
    if dept.get("cost_influence", 0.0) > 0:
        GameState.add_resource("influence", -dept.cost_influence)
    if dept.get("cost_knowledge", 0.0) > 0:
        GameState.add_resource("knowledge", -dept.cost_knowledge)
    GameState.state.departments.append(dept_id)
    GameState.emit_signal("state_changed")

func _update_prestige() -> void:
    var total = GameState.state.get("total_credits_earned", 0.0)
    var threshold = 1000000.0
    prestige_btn.disabled = total < threshold
    prestige_info.text = "Total earned: %.0f / 1,000,000 ₢ to unlock Temporal Reset" % total

func _do_prestige() -> void:
    if GameState.state.get("total_credits_earned", 0.0) < 1000000.0:
        return
    var echoes = _calculate_echoes()
    GameState.state.temporal_echoes += echoes
    GameState.state.prestige_count += 1
    var keep_echoes = GameState.state.temporal_echoes
    var keep_echo_upgrades = GameState.state.echo_upgrades.duplicate()
    var keep_prestige_count = GameState.state.prestige_count
    GameState.initialize_state()
    GameState.state.temporal_echoes = keep_echoes
    GameState.state.echo_upgrades = keep_echo_upgrades
    GameState.state.prestige_count = keep_prestige_count
    AgentManager.create_starter_agent()
    GameState.emit_signal("state_changed")

func _calculate_echoes() -> int:
    var total = GameState.state.get("total_credits_earned", 0.0)
    var base = int(sqrt(total / 500000.0))
    base += GameState.state.eras_unlocked.size()
    base += int(GameState.state.get("agents_promoted_this_run", 0))
    if "E-03" in GameState.state.echo_upgrades:
        base = int(float(base) * 1.25)
    return maxi(base, 1)

func _update_echo_shop() -> void:
    echo_label.text = "Temporal Echoes: %d" % GameState.state.get("temporal_echoes", 0)
    for child in echo_list.get_children():
        child.queue_free()
    for upgrade in ECHO_UPGRADES:
        var owned = upgrade.id in GameState.state.echo_upgrades
        var row = HBoxContainer.new()
        var info = Label.new()
        info.text = ("[✓] " if owned else "    ") + upgrade.name + " — " + upgrade.desc + " (%d Echoes)" % upgrade.cost
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        if not owned:
            var btn = Button.new()
            btn.text = "BUY"
            btn.disabled = GameState.state.get("temporal_echoes", 0) < upgrade.cost
            var upg_id = upgrade.id
            var upg_cost = upgrade.cost
            btn.pressed.connect(func(): _buy_echo_upgrade(upg_id, upg_cost))
            row.add_child(btn)
        echo_list.add_child(row)

func _buy_echo_upgrade(upgrade_id: String, cost: int) -> void:
    if GameState.state.temporal_echoes < cost:
        return
    GameState.state.temporal_echoes -= cost
    GameState.state.echo_upgrades.append(upgrade_id)
    GameState.emit_signal("state_changed")
