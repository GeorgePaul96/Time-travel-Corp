extends Control

func _ready() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(vbox)

	var title := Label.new()
	title.text = "TIME TRAVEL CORP"
	vbox.add_child(title)

	var start_btn := Button.new()
	start_btn.text = "NEW CONTRACT"
	start_btn.pressed.connect(_on_start)
	vbox.add_child(start_btn)

func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/meta/contract_select.tscn")
