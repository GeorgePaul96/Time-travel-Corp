extends Control

@onready var anomaly_label: Label = $VBox/AnomalyLabel
@onready var grid_container: GridContainer = $VBox/GridContainer
@onready var back_button: Button = $VBox/BackButton

var upgrades := [
	{
		"id": &"ops_starting_capital",
		"dept": "OPERATIONS",
		"name": "Starting Capital",
		"desc": "Start with +100₵ capital.",
		"cost": 10
	},
	{
		"id": &"ops_salvage_rate",
		"dept": "OPERATIONS",
		"name": "Salvage Recovery",
		"desc": "Salvage returns 40% (up from 25%).",
		"cost": 15
	},
	{
		"id": &"ops_fifth_extractor_cap",
		"dept": "OPERATIONS",
		"name": "Cost Cap",
		"desc": "Extractor costs stop scaling past the 4th extractor.",
		"cost": 25
	},
	{
		"id": &"legal_injunction_slot",
		"dept": "LEGAL",
		"name": "Continuity Authorization",
		"desc": "Unlocks a 4th Injunction slot.",
		"cost": 20
	},
	{
		"id": &"legal_divert_discount",
		"dept": "LEGAL",
		"name": "Risk Redirection",
		"desc": "Divert cost reduced by 25%.",
		"cost": 15
	},
	{
		"id": &"rd_front_speed",
		"dept": "R&D",
		"name": "Timeline Calibration",
		"desc": "Reduce front travel speed by 10%.",
		"cost": 15
	},
	{
		"id": &"rd_harvest_value",
		"dept": "R&D",
		"name": "Profit Authenticator",
		"desc": "Increase Harvest payouts by 25%.",
		"cost": 20
	}
]

func _ready() -> void:
	back_button.pressed.connect(_on_back)
	_refresh_ui()

func _refresh_ui() -> void:
	anomaly_label.text = "ANOMALIES AVAILABLE: ◬%d" % MetaState.state.anomalies
	
	for child in grid_container.get_children():
		child.queue_free()
		
	# Group upgrades by department
	var depts = {}
	for u in upgrades:
		if not depts.has(u.dept):
			depts[u.dept] = []
		depts[u.dept].append(u)
		
	for dept_name in depts:
		var dept_box := VBoxContainer.new()
		dept_box.custom_minimum_size = Vector2(200, 0)
		
		var title := Label.new()
		title.text = "=== " + dept_name + " ==="
		title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		dept_box.add_child(title)
		
		for u in depts[dept_name]:
			var card := PanelContainer.new()
			var card_vbox := VBoxContainer.new()
			card.add_child(card_vbox)
			
			var name_lbl := Label.new()
			name_lbl.text = u.name
			name_lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			card_vbox.add_child(name_lbl)
			
			var desc_lbl := Label.new()
			desc_lbl.text = u.desc
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			desc_lbl.custom_minimum_size = Vector2(180, 0)
			card_vbox.add_child(desc_lbl)
			
			var cost_lbl := Label.new()
			cost_lbl.text = "Cost: ◬%d" % u.cost
			cost_lbl.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
			card_vbox.add_child(cost_lbl)
			
			var buy_btn := Button.new()
			var bought := MetaState.state.unlocked_nodes.has(u.id)
			if bought:
				buy_btn.text = "UNLOCKED [☕]"
				buy_btn.disabled = true
			else:
				buy_btn.text = "UNLOCK"
				buy_btn.disabled = MetaState.state.anomalies < u.cost
				buy_btn.pressed.connect(func():
					if MetaState.buy_upgrade(u.id, u.cost):
						_refresh_ui()
				)
			card_vbox.add_child(buy_btn)
			
			dept_box.add_child(card)
		grid_container.add_child(dept_box)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/meta/main_menu.tscn")
