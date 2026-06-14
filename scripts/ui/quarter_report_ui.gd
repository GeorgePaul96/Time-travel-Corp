extends Control

@onready var quarter_label: Label = $VBox/QuarterLabel
@onready var capital_label: Label = $VBox/CapitalLabel
@onready var memo_label: RichTextLabel = $VBox/MemoLabel
@onready var directive_container: HBoxContainer = $VBox/DirectiveContainer
@onready var hint_label: Label = $VBox/HintLabel

var _displayed_text: String = ""
var _char_index: int = 0
var _timer: Timer

func _ready() -> void:
	hint_label.text = "Select a Directive to continue to the next quarter."
	var directives := RunSim.get_pending_directives()
	if not directives.is_empty():
		_on_directives_received(directives)
	else:
		EventBus.directive_required.connect(_on_directives_received)

func _on_directives_received(directives: Array) -> void:
	for child in directive_container.get_children():
		child.queue_free()

	var state := RunSim.get_state()
	if state:
		quarter_label.text = "Q%d QUARTERLY REPORT" % state.quarter
		var quota := RunSim.get_contract_quota()
		var pct := (state.capital / quota * 100.0) if quota > 0.0 else 0.0
		capital_label.text = "Capital: µ%.0f / µ%.0f  (%.0f%%)" % [state.capital, quota, pct]

		# Generate and teletype memo
		var voices = ["HR", "Legal", "The Board", "The Founder"]
		var voice = voices[(state.quarter - 1) % voices.size()]
		var full_memo = MemoGenerator.generate_memo(state, voice)
		_start_teletype(full_memo)

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

func _start_teletype(text: String) -> void:
	_displayed_text = text
	_char_index = 0
	memo_label.text = ""
	
	if _timer:
		_timer.queue_free()
		
	_timer = Timer.new()
	_timer.wait_time = 0.01
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start()

func _on_timer_timeout() -> void:
	if _char_index < _displayed_text.length():
		memo_label.text += _displayed_text[_char_index]
		_char_index += 1
	else:
		_timer.stop()
		_timer.queue_free()
		_timer = null

