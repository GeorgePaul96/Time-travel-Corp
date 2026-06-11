extends Control

@onready var contract_list: HBoxContainer = $VBox/ContractList
@onready var back_button: Button = $VBox/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back)
	_populate()

func _populate() -> void:
	for child in contract_list.get_children():
		child.queue_free()
	for contract in ContentDB.get_all_contracts():
		contract_list.add_child(_make_card(contract))

func _make_card(contract: ContractDef) -> PanelContainer:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var tier_lbl := Label.new()
	tier_lbl.text = "TIER %d" % contract.tier

	var name_lbl := Label.new()
	name_lbl.text = contract.display_name

	var quota_lbl := Label.new()
	quota_lbl.text = "Quota: %s µ" % _fmt(contract.quota)

	var inj_lbl := Label.new()
	inj_lbl.text = "Injunctions: %d" % contract.starting_injunctions

	var anomaly_lbl := Label.new()
	anomaly_lbl.text = "Anomaly reward: ⌬%d" % contract.anomaly_reward

	var start_btn := Button.new()
	start_btn.text = "ACCEPT CONTRACT"
	start_btn.pressed.connect(_on_start.bind(contract.id))

	for node in [tier_lbl, name_lbl, quota_lbl, inj_lbl, anomaly_lbl, start_btn]:
		vbox.add_child(node)
	return panel

func _on_start(contract_id: StringName) -> void:
	RunSim.start_run(contract_id)
	get_tree().change_scene_to_file("res://scenes/run/run.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/meta/main_menu.tscn")

func _fmt(n: float) -> String:
	return "%.0fK" % (n / 1000.0) if n >= 1000.0 else "%.0f" % n
