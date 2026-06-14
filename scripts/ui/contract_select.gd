extends Control

@onready var contract_list: HBoxContainer = $VBox/ContractList
@onready var back_button: Button = $VBox/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back)

	# Create Audit Level Selector Row
	var audit_row := HBoxContainer.new()
	audit_row.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var audit_label := Label.new()
	audit_label.text = "BOARD AUDIT LEVEL: A%d " % MetaState.state.audit_level
	
	var audit_dec := Button.new()
	audit_dec.text = " - "
	audit_dec.pressed.connect(func():
		MetaState.state.audit_level = max(0, MetaState.state.audit_level - 1)
		MetaState.save()
		audit_label.text = "BOARD AUDIT LEVEL: A%d " % MetaState.state.audit_level
		_populate() # Refresh lists to show scaled quotas
	)

	var audit_inc := Button.new()
	audit_inc.text = " + "
	audit_inc.pressed.connect(func():
		MetaState.state.audit_level = min(10, MetaState.state.audit_level + 1)
		MetaState.save()
		audit_label.text = "BOARD AUDIT LEVEL: A%d " % MetaState.state.audit_level
		_populate()
	)
	
	audit_row.add_child(audit_label)
	audit_row.add_child(audit_dec)
	audit_row.add_child(audit_inc)
	
	# Create Seed Input Row
	var seed_row := HBoxContainer.new()
	seed_row.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var seed_label := Label.new()
	seed_label.text = "SEED CODE: "
	
	var seed_input := LineEdit.new()
	seed_input.placeholder_text = "RANDOM SEED (LEAVE BLANK)"
	seed_input.custom_minimum_size = Vector2(250, 0)
	seed_input.text_changed.connect(func(new_text: String):
		if new_text.is_empty():
			RunSim.custom_seed = 0
		else:
			var val = new_text.hash() if not new_text.is_valid_int() else int(new_text)
			RunSim.custom_seed = val
	)
	
	seed_row.add_child(seed_label)
	seed_row.add_child(seed_input)
	
	# Insert rows at the top of the VBox
	var vbox := $VBox
	vbox.add_child(audit_row)
	vbox.move_child(audit_row, 0) # Put it at the top
	vbox.add_child(seed_row)
	vbox.move_child(seed_row, 1)

	_populate()

func _populate() -> void:
	for child in contract_list.get_children():
		child.queue_free()
	for contract in ContentDB.get_all_contracts():
		contract_list.add_child(_make_card(contract))

func _get_displayed_quota(contract: ContractDef) -> float:
	var quota := contract.quota
	for m in contract.modifiers:
		if m.id == &"cheap_money":
			quota *= 1.3
		if m.id == &"overtime":
			quota *= 1.4
	quota *= (1.0 + float(MetaState.state.audit_level) * 0.1)
	return quota

func _make_card(contract: ContractDef) -> PanelContainer:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var tier_lbl := Label.new()
	tier_lbl.text = "TIER %d" % contract.tier

	var name_lbl := Label.new()
	name_lbl.text = contract.display_name

	var quota_lbl := Label.new()
	quota_lbl.text = "Quota: %s µ" % _fmt(_get_displayed_quota(contract))

	var inj_lbl := Label.new()
	inj_lbl.text = "Injunctions: %d" % contract.starting_injunctions

	var anomaly_lbl := Label.new()
	anomaly_lbl.text = "Anomaly reward: ⌬%d" % contract.anomaly_reward

	if not contract.modifiers.is_empty():
		var mods_lbl := Label.new()
		var mod_names: Array = []
		for m in contract.modifiers:
			mod_names.append(m.display_name)
		mods_lbl.text = "MODIFIERS: " + ", ".join(mod_names)
		vbox.add_child(mods_lbl)

	var start_btn := Button.new()
	var unlocked := contract.tier <= MetaState.state.ladder_tier
	if unlocked:
		start_btn.text = "ACCEPT CONTRACT"
		start_btn.pressed.connect(_on_start.bind(contract.id))
	else:
		start_btn.text = "LOCKED (TIER %d)" % contract.tier
		start_btn.disabled = true

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
