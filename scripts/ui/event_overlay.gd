extends Control

@onready var event_title: Label = $Panel/VBoxContainer/HBoxContainer/EventTitle
@onready var countdown_label: Label = $Panel/VBoxContainer/HBoxContainer/CountdownLabel
@onready var event_desc: Label = $Panel/VBoxContainer/EventDesc
@onready var choice_list: VBoxContainer = $Panel/VBoxContainer/ChoiceList

const CHOICE_LABELS = ["A", "B", "C"]

func _ready() -> void:
	GameState.event_fired.connect(_show_event)
	GameState.state_changed.connect(_update_countdown)

func _show_event(event_data: Dictionary) -> void:
	if visible:
		return
	event_title.text = event_data.get("name", "EVENT")
	event_desc.text = event_data.get("description", "")
	for child in choice_list.get_children():
		child.queue_free()
	var choices: Array = event_data.get("choices", [])
	if choices.is_empty():
		var btn = Button.new()
		btn.text = "[ OK ] Acknowledge"
		btn.pressed.connect(func(): _resolve(0))
		choice_list.add_child(btn)
	else:
		for i in range(choices.size()):
			var choice = choices[i]
			var btn = Button.new()
			var letter = CHOICE_LABELS[i] if i < CHOICE_LABELS.size() else str(i + 1)
			btn.text = "[ %s ] %s — %s" % [letter, choice.get("label","?"), choice.get("desc","")]
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD
			var idx = i
			btn.pressed.connect(func(): _resolve(idx))
			choice_list.add_child(btn)
	visible = true

func _update_countdown() -> void:
	if not visible:
		return
	var remaining = EventManager.get_event_countdown()
	if remaining <= 0.0:
		visible = false
		return
	var secs = int(remaining)
	countdown_label.text = "%d:%02d" % [secs / 60, secs % 60]

func _resolve(choice_index: int) -> void:
	EventManager.resolve_choice(choice_index)
	visible = false
