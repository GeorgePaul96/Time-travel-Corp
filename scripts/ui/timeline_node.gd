extends PanelContainer

@export var node_id: String = ""
@export var node_name: String = ""

func _ready() -> void:
	%NameLabel.text = node_name

	%AddBtn.pressed.connect(func(): GameManager.add_extractor(node_id))
	%RemoveBtn.pressed.connect(func(): GameManager.remove_extractor(node_id))
	%PatchBtn.pressed.connect(func(): GameManager.patch_node(node_id))

	GameManager.state_changed.connect(_update_ui)
	_update_ui()

func _update_ui() -> void:
	if not GameManager.state.nodes.has(node_id):
		return

	var data = GameManager.state.nodes[node_id]
	%StabilityBar.value = data.stability
	%ExtractorsLabel.text = "Extractors: " + str(data.active_extractors)

	var prod = GameManager.calculate_node_production(node_id)

	if data.is_mutated:
		%StateLabel.text = "MUTATED"
		%StateLabel.add_theme_color_override("font_color", Color.RED)
		%PatchBtn.show()
		%HBoxContainer.hide()
		%ProductionLabel.text = "Anomalies: " + str(snapped(prod, 0.1)) + "/s"

		# Visual feedback for mutation
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.0, 0.0)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color.RED
		add_theme_stylebox_override("panel", style)
	else:
		%StateLabel.text = "STABLE"
		%StateLabel.add_theme_color_override("font_color", Color.GREEN)
		%PatchBtn.hide()
		%HBoxContainer.show()
		%ProductionLabel.text = "Capital: " + str(snapped(prod, 0.1)) + "/s"

		# Visual feedback for stable
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.3, 0.3)
		add_theme_stylebox_override("panel", style)
