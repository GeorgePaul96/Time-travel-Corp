extends PanelContainer

@export var node_id: String = ""
@export var node_name: String = ""

@onready var _name_label: Label = %NameLabel
@onready var _state_label: Label = %StateLabel
@onready var _stability_bar: ProgressBar = %StabilityBar
@onready var _production_label: Label = %ProductionLabel
@onready var _extractors_label: Label = %ExtractorsLabel
@onready var _h_box: HBoxContainer = %HBoxContainer
@onready var _add_btn: Button = %AddBtn
@onready var _remove_btn: Button = %RemoveBtn
@onready var _patch_btn: Button = %PatchBtn

var _style_stable: StyleBoxFlat
var _style_mutated: StyleBoxFlat

func _ready() -> void:
	_name_label.text = node_name
	_build_styles()

	_add_btn.pressed.connect(func(): GameManager.add_extractor(node_id))
	_remove_btn.pressed.connect(func(): GameManager.remove_extractor(node_id))
	_patch_btn.pressed.connect(func(): GameManager.patch_node(node_id))

	GameManager.state_changed.connect(_update_ui)
	_update_ui()

func _build_styles() -> void:
	_style_stable = StyleBoxFlat.new()
	_style_stable.bg_color = Color(0.1, 0.1, 0.1)
	_style_stable.border_width_left = 1
	_style_stable.border_width_right = 1
	_style_stable.border_width_top = 1
	_style_stable.border_width_bottom = 1
	_style_stable.border_color = Color(0.3, 0.3, 0.3)

	_style_mutated = StyleBoxFlat.new()
	_style_mutated.bg_color = Color(0.2, 0.0, 0.0)
	_style_mutated.border_width_left = 2
	_style_mutated.border_width_right = 2
	_style_mutated.border_width_top = 2
	_style_mutated.border_width_bottom = 2
	_style_mutated.border_color = Color.RED

func _update_ui() -> void:
	if not GameManager.state.nodes.has(node_id):
		return

	var data = GameManager.state.nodes[node_id]
	_stability_bar.value = data.stability
	_extractors_label.text = "Extractors: " + str(data.active_extractors)

	var prod = GameManager.calculate_node_production(node_id)
	var mult = GameManager.calculate_node_multiplier(node_id)
	var mult_text = "" if is_equal_approx(mult, 1.0) else " (x" + str(snapped(mult, 0.01)) + ")"

	if data.is_mutated:
		var mutation_name = "MUTATED"
		match node_id:
			"antiquity": mutation_name = "PRIMAL CHAOS"
			"middle_ages": mutation_name = "DARK AGE"
			"industrial": mutation_name = "DIESEL WASTES"
			"future": mutation_name = "SINGULARITY"

		_state_label.text = mutation_name
		_state_label.add_theme_color_override("font_color", Color.RED)
		_patch_btn.show()
		_h_box.hide()
		_production_label.text = "Anomalies: " + str(snapped(prod, 0.1)) + "/s" + mult_text
		add_theme_stylebox_override("panel", _style_mutated)
	else:
		_state_label.text = "STABLE"
		_state_label.add_theme_color_override("font_color", Color.GREEN)
		_patch_btn.hide()
		_h_box.show()
		_production_label.text = "Capital: " + str(snapped(prod, 0.1)) + "/s" + mult_text
		add_theme_stylebox_override("panel", _style_stable)
