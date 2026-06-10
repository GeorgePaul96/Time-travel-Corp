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

	# 1. VISUAL URGENCY: Stability color transitions
	var stylebox = StyleBoxFlat.new()
	if data.stability > 75.0:
		stylebox.bg_color = Color(0, 0.8, 0) # Green (safe)
	elif data.stability > 50.0:
		stylebox.bg_color = Color(0.8, 0.8, 0) # Yellow (warning)
	elif data.stability > 25.0:
		stylebox.bg_color = Color(1.0, 0.5, 0) # Orange (danger)
	else:
		stylebox.bg_color = Color(1.0, 0, 0) # Red (critical)
	%StabilityBar.add_theme_stylebox_override("fill", stylebox)

	%ExtractorsLabel.text = "Extractors: " + str(data.active_extractors)

	var prod = GameManager.calculate_node_production(node_id)
	var mult = GameManager.calculate_node_multiplier(node_id)
	var mult_text = "" if mult == 1.0 else " (x" + str(snapped(mult, 0.01)) + ")"

	# 2. CASCADE VISIBILITY: Find upstream penalties
	var upstream_penalty_text = ""
	if mult < 1.0:
		var penalty_source = ""
		match node_id:
			"middle_ages": penalty_source = "Antiquity"
			"industrial": penalty_source = "Middle Ages"
			"future": penalty_source = "Industrial Age"
		upstream_penalty_text = "
[Penalty from " + penalty_source + "]"

	if data.is_mutated:
		var mutation_name = "MUTATED"
		match node_id:
			"antiquity": mutation_name = "PRIMAL CHAOS"
			"middle_ages": mutation_name = "DARK AGE"
			"industrial": mutation_name = "DIESEL WASTES"
			"future": mutation_name = "SINGULARITY"

		%StateLabel.text = mutation_name
		%StateLabel.add_theme_color_override("font_color", Color.RED)
		%PatchBtn.show()
		%HBoxContainer.hide()
		%ProductionLabel.text = "Anomalies: " + str(snapped(prod, 0.1)) + "/s" + mult_text + upstream_penalty_text

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.0, 0.0)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color.RED
		add_theme_stylebox_override("panel", style)
	else:
		# VISUAL URGENCY: Warning before mutation
		if data.stability <= 25.0:
			%StateLabel.text = "CRITICAL WARNING"
			%StateLabel.add_theme_color_override("font_color", Color.ORANGE)
		else:
			%StateLabel.text = "STABLE"
			%StateLabel.add_theme_color_override("font_color", Color.GREEN)

		%PatchBtn.hide()
		%HBoxContainer.show()
		%ProductionLabel.text = "Capital: " + str(snapped(prod, 0.1)) + "/s" + mult_text + upstream_penalty_text

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.3, 0.3)

		if data.stability <= 25.0:
			style.border_color = Color.ORANGE
			style.bg_color = Color(0.2, 0.1, 0.0)

		add_theme_stylebox_override("panel", style)
