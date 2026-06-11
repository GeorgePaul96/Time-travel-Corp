extends Control

@onready var quarter_label: Label = $VBox/QuarterLabel
@onready var capital_label: Label = $VBox/CapitalLabel
@onready var directive_container: HBoxContainer = $VBox/DirectiveContainer
@onready var hint_label: Label = $VBox/HintLabel

func _ready() -> void:
	hint_label.text = "Select a Directive to continue to the next quarter."
	EventBus.directive_required.connect(_on_directives_received)

func _on_directives_received(directives: Array) -> void:
	for child in directive_container.get_children():
		child.queue_free()

	var state := RunSim.get_state()
	if state:
		quarter_label.text = "Q%d QUARTERLY REPORT" % state.quarter
		var contract := ContentDB.get_by_id(state.contract_id) as ContractDef
		var quota := contract.quota if contract else 0.0
		var pct := (state.capital / quota * 100.0) if quota > 0.0 else 0.0
		capital_label.text = "Capital: µ%.0f / µ%.0f  (%.0f%%)" % [state.capital, quota, pct]

	for item in directives:
		var d := item as DirectiveDef
		if d:
			directive_container.add_child(_make_card(d))

func _make_card(directive: DirectiveDef) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 0)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var tone_names := ["GIFT", "DEAL", "MANDATE"]
	var tone_lbl := Label.new()
	tone_lbl.text = tone_names[directive.tone] if directive.tone < tone_names.size() else ""

	var title_lbl := Label.new()
	title_lbl.text = directive.title

	var body_lbl := Label.new()
	body_lbl.text = directive.body
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	body_lbl.custom_minimum_size = Vector2(200, 0)

	var dur_lbl := Label.new()
	dur_lbl.text = _dur_text(directive.duration_quarters)

	var pick_btn := Button.new()
	pick_btn.text = "SELECT"
	pick_btn.pressed.connect(_on_pick.bind(directive.id))

	for node in [tone_lbl, title_lbl, body_lbl, dur_lbl, pick_btn]:
		vbox.add_child(node)
	return panel

func _dur_text(q: int) -> String:
	match q:
		-1: return "Permanent"
		0:  return "Instant"
		1:  return "This quarter"
		_:  return "%d quarters" % q

func _on_pick(directive_id: StringName) -> void:
	RunSim.pick_directive(directive_id)
	get_tree().change_scene_to_file("res://scenes/run/run.tscn")
