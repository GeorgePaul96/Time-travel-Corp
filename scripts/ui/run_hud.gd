extends Control

@onready var quota_bar: ProgressBar = $TopBar/QuotaBar
@onready var singularity_bar: ProgressBar = $TopBar/SingularityBar
@onready var clock_label: Label = $TopBar/ClockLabel
@onready var injunction_label: Label = $TopBar/InjunctionLabel
@onready var capital_label: Label = $TopBar/CapitalLabel
@onready var era_container: HBoxContainer = $Timeline/EraContainer
@onready var front_layer: Control = $Timeline/FrontLayer
@onready var verb_panel: HBoxContainer = $BottomDock/VerbPanel
@onready var build_panel: HBoxContainer = $BottomDock/BuildPanel
@onready var pause_button: Button = $BottomDock/PauseButton

var _selected_front_uid: int = -1
var _era_panels: Array = []
var _selected_era_id: StringName = &"antiquity"

const ERA_ORDER: Array[StringName] = [&"antiquity", &"middle_ages", &"industrial", &"future"]

func _ready() -> void:
	add_to_group("run_hud")

	EventBus.tick_processed.connect(_on_tick)
	EventBus.front_spawned.connect(_on_front_spawned)
	EventBus.front_resolved.connect(_on_front_resolved)
	EventBus.era_mutated.connect(_on_era_mutated)
	EventBus.singularity_changed.connect(_on_singularity_changed)
	EventBus.quarter_ended.connect(_on_quarter_ended)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.incident_triggered.connect(_on_incident_triggered)

	pause_button.pressed.connect(_toggle_pause)
	_setup_verb_buttons()
	_setup_build_buttons()

	for era_id in ERA_ORDER:
		var panel_name := "EraPanel_" + str(era_id)
		var panel := era_container.get_node_or_null(panel_name)
		if panel and panel.has_method("setup"):
			panel.setup(era_id)
			_era_panels.append(panel)

	# Rebuild view state that does not survive the per-quarter scene reload:
	# tokens for fronts already in flight (MB-1), and an incident popup that
	# was still open when the quarter boundary swapped scenes (MB-2).
	var state := RunSim.get_state()
	if state:
		for front in state.fronts:
			_on_front_spawned(front)
		var active_inc: StringName = state.flags.get(&"active_incident_id", &"")
		if active_inc != &"":
			var inc := ContentDB.get_by_id(active_inc) as IncidentDef
			if inc:
				_on_incident_triggered(inc)

	select_era(_selected_era_id)
	_refresh_hud()

func _setup_verb_buttons() -> void:
	for child in verb_panel.get_children():
		child.queue_free()

	var dampen_btn := Button.new()
	dampen_btn.name = "DampenBtn"
	dampen_btn.text = "DAMPEN (1 INJ)"
	dampen_btn.pressed.connect(_on_dampen)

	var divert_btn := Button.new()
	divert_btn.name = "DivertBtn"
	divert_btn.text = "DIVERT"
	divert_btn.pressed.connect(_on_divert)

	var harvest_btn := Button.new()
	harvest_btn.name = "HarvestBtn"
	harvest_btn.text = "HARVEST"
	harvest_btn.pressed.connect(_on_harvest)

	var restock_btn := Button.new()
	restock_btn.name = "RestockBtn"
	restock_btn.text = "RESTOCK INJ"
	restock_btn.pressed.connect(_on_restock)

	for btn in [dampen_btn, divert_btn, harvest_btn, restock_btn]:
		verb_panel.add_child(btn)

func _setup_build_buttons() -> void:
	for child in build_panel.get_children():
		child.queue_free()
	for ext_id in [&"steady", &"burst", &"deep"]:
		var ext_def := ContentDB.get_by_id(ext_id) as ExtractorDef
		if not ext_def:
			continue
		var btn := Button.new()
		btn.name = str(ext_id) + "Btn"
		btn.text = ext_def.display_name
		btn.pressed.connect(_on_build.bind(ext_id))
		build_panel.add_child(btn)

func _on_tick() -> void:
	_refresh_hud()

func _refresh_hud() -> void:
	var state := RunSim.get_state()
	if not state:
		return
	var quota := maxf(RunSim.get_contract_quota(), 1.0)

	quota_bar.max_value = quota
	quota_bar.value = state.capital
	singularity_bar.max_value = 100.0
	singularity_bar.value = state.singularity

	var remaining := maxf(90.0 - state.quarter_time, 0.0)
	clock_label.text = "Q%d  %d:%02d" % [state.quarter, int(remaining) / 60, int(remaining) % 60]
	injunction_label.text = "INJ: %d" % state.injunctions
	capital_label.text = "µ %.0f" % state.capital

	_update_verb_buttons()

func _update_verb_buttons() -> void:
	var state := RunSim.get_state()
	var has_front := _selected_front_uid >= 0 and _find_front_state(_selected_front_uid) != null
	var has_inj := state and state.injunctions > 0

	var dampen := verb_panel.get_node_or_null("DampenBtn")
	var divert := verb_panel.get_node_or_null("DivertBtn")
	var harvest := verb_panel.get_node_or_null("HarvestBtn")
	if dampen:
		dampen.disabled = not (has_front and has_inj)
	if divert:
		divert.disabled = not has_front
	if harvest:
		harvest.disabled = not has_front

func _find_front_state(uid: int) -> FrontState:
	var state := RunSim.get_state()
	if not state:
		return null
	for f in state.fronts:
		if f.uid == uid:
			return f
	return null

func _on_front_spawned(front: FrontState) -> void:
	var token: Control = load("res://scenes/run/front_token.tscn").instantiate()
	token.name = "Front_%d" % front.uid
	front_layer.add_child(token)
	token.setup(front)

func _on_front_resolved(front: FrontState, _resolution: int) -> void:
	var token := front_layer.get_node_or_null("Front_%d" % front.uid)
	if token:
		token.queue_free()
	if _selected_front_uid == front.uid:
		_selected_front_uid = -1
		_update_verb_buttons()

func _on_era_mutated(era_id: StringName, severity: int) -> void:
	for panel in _era_panels:
		if panel.era_id == era_id:
			panel.update_mutation(severity)

func _on_singularity_changed(value: float) -> void:
	singularity_bar.value = value

func _on_quarter_ended(_report: QuarterReport) -> void:
	get_tree().change_scene_to_file("res://scenes/ui/quarter_report.tscn")

func _on_run_ended(_result: Dictionary) -> void:
	get_tree().change_scene_to_file("res://scenes/ui/debrief.tscn")

func _on_incident_triggered(incident: IncidentDef) -> void:
	var popup: Control = load("res://scenes/run/incident_popup.tscn").instantiate()
	add_child(popup)
	popup.setup(incident)

func _on_dampen() -> void:
	if _selected_front_uid >= 0:
		RunSim.dampen_front(_selected_front_uid)

func _on_divert() -> void:
	if _selected_front_uid >= 0:
		RunSim.divert_front(_selected_front_uid)

func _on_harvest() -> void:
	if _selected_front_uid >= 0:
		RunSim.harvest_front(_selected_front_uid)

func _on_restock() -> void:
	RunSim.restock_injunctions()

func _on_build(ext_type_id: StringName) -> void:
	if _selected_era_id != &"":
		RunSim.place_extractor(_selected_era_id, ext_type_id)

func select_era(era_id: StringName) -> void:
	_selected_era_id = era_id
	for panel in _era_panels:
		if panel.has_method("set_selected"):
			panel.set_selected(panel.era_id == _selected_era_id)

func _toggle_pause() -> void:
	if RunSim.get_phase() == RunSim.Phase.RUNNING:
		RunSim.pause()
		pause_button.text = "RESUME"
	else:
		RunSim.resume()
		pause_button.text = "PAUSE"

func select_front(uid: int) -> void:
	_selected_front_uid = uid
	_update_verb_buttons()
