extends Control

var front_uid: int = -1

@onready var label: Label = $Label

const ERA_ORDER: Array[StringName] = [&"antiquity", &"middle_ages", &"industrial", &"future"]

func setup(front: FrontState) -> void:
	front_uid = front.uid
	label.text = "%s\n%s" % [front.codename, "I" if front.severity == 1 else "II"]
	_update_position(front)
	EventBus.tick_processed.connect(_on_tick)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func _on_tick() -> void:
	var state := RunSim.get_state()
	if not state:
		return
	for f in state.fronts:
		if f.uid == front_uid:
			_update_position(f)
			label.modulate = Color.GOLD if f.harvested else Color.WHITE
			return

func _update_position(front: FrontState) -> void:
	var origin_idx := ERA_ORDER.find(front.origin_era_id)
	var target_idx := ERA_ORDER.find(front.target_era_id)
	if target_idx < 0:
		return
	if origin_idx < 0:
		origin_idx = maxi(target_idx - 1, 0)

	var parent_width := get_parent().size.x if get_parent() else 800.0
	var slot_w := parent_width / 4.0
	var x_start := slot_w * origin_idx + slot_w * 0.5
	var x_end := slot_w * target_idx + slot_w * 0.5
	position.x = lerpf(x_start, x_end, front.progress)
	position.y = 20.0

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hud := get_tree().get_first_node_in_group("run_hud")
		if hud and hud.has_method("select_front"):
			hud.select_front(front_uid)
