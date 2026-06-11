extends PanelContainer

var era_id: StringName = &""

@onready var name_label: Label = $VBox/NameLabel
@onready var instability_bar: ProgressBar = $VBox/InstabilityBar
@onready var yield_label: Label = $VBox/YieldLabel
@onready var extractor_list: VBoxContainer = $VBox/ExtractorList
@onready var mutation_label: Label = $VBox/MutationLabel

func setup(p_era_id: StringName) -> void:
	era_id = p_era_id
	var era_def := ContentDB.get_by_id(era_id) as EraDef
	name_label.text = era_def.display_name if era_def else str(era_id)
	EventBus.tick_processed.connect(_refresh)

func _refresh() -> void:
	var state := RunSim.get_state()
	if not state:
		return
	for es in state.eras:
		if es.era_id == era_id:
			instability_bar.value = es.instability
			yield_label.text = "µ/s: %.1f" % RunSim._era_total_yield(es)
			mutation_label.text = _mutation_text(es.mutation_severity)
			_rebuild_extractors(es)
			return

func update_mutation(severity: int) -> void:
	mutation_label.text = _mutation_text(severity)

func _mutation_text(severity: int) -> String:
	match severity:
		1: return "MUTATED (I)"
		2: return "MUTATED (II)"
	return ""

func _rebuild_extractors(es: EraState) -> void:
	for child in extractor_list.get_children():
		child.queue_free()
	for i in range(es.extractors.size()):
		var rec: Dictionary = es.extractors[i]
		var ext_def := ContentDB.get_by_id(rec.type_id) as ExtractorDef
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = ext_def.display_name if ext_def else str(rec.type_id)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn := Button.new()
		btn.text = "X"
		btn.pressed.connect(_on_remove.bind(i))
		row.add_child(lbl)
		row.add_child(btn)
		extractor_list.add_child(row)

func _on_remove(index: int) -> void:
	RunSim.remove_extractor(era_id, index)
