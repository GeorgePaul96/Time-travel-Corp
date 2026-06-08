extends Control

@onready var panel: PanelContainer = $Panel
@onready var event_title: Label = $Panel/VBoxContainer/HBoxContainer/EventTitle
@onready var countdown_label: Label = $Panel/VBoxContainer/HBoxContainer/CountdownLabel
@onready var event_desc: Label = $Panel/VBoxContainer/EventDesc
@onready var choice_list: VBoxContainer = $Panel/VBoxContainer/ChoiceList

func _ready() -> void:
	GameState.event_fired.connect(_show_event)
	GameState.state_changed.connect(_update_countdown)
	visible = false

func _show_event(event_data: Dictionary) -> void:
	event_title.text = event_data.get("name", "EVENT")
	event_desc.text = event_data.get("description", "")
	for child in choice_list.get_children():
		child.queue_free()
	var choices: Array = event_data.get("choices", [])
	for i in range(choices.size()):
		var choice = choices[i]
		var btn = Button.new()
		btn.text = "[ %s ] %s — %s" % [["A","B","C"][i], choice.get("label","?"), choice.get("desc","")]
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
	countdown_label.text = "0:%02d" % int(remaining)

func _resolve(choice_index: int) -> void:
	EventManager.resolve_choice(choice_index)
	visible = false
