extends PanelContainer

@onready var memo_label: RichTextLabel = $VBox/MemoLabel
@onready var choice1_btn: Button = $VBox/ButtonContainer/Choice1Btn
@onready var choice2_btn: Button = $VBox/ButtonContainer/Choice2Btn
@onready var title_label: Label = $VBox/TitleLabel

var _incident: IncidentDef
var _displayed_text: String = ""
var _char_index: int = 0
var _timer: Timer

func setup(incident: IncidentDef) -> void:
	_incident = incident
	# Hide buttons initially
	choice1_btn.hide()
	choice2_btn.hide()
	choice1_btn.disabled = true
	choice2_btn.disabled = true
	
	# Setup choices
	if incident.choices.size() > 0:
		choice1_btn.text = incident.choices[0].get("label", "")
	if incident.choices.size() > 1:
		choice2_btn.text = incident.choices[1].get("label", "")
		
	# Start teletype
	_displayed_text = incident.memo_text
	_char_index = 0
	memo_label.text = ""
	
	_timer = Timer.new()
	_timer.wait_time = 0.02
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
		# Show and enable buttons
		choice1_btn.show()
		choice1_btn.disabled = false
		if _incident.choices.size() > 1:
			choice2_btn.show()
			choice2_btn.disabled = false

func _ready() -> void:
	choice1_btn.pressed.connect(_on_choice_pressed.bind(0))
	choice2_btn.pressed.connect(_on_choice_pressed.bind(1))

func _on_choice_pressed(idx: int) -> void:
	RunSim.resolve_incident(idx)
	queue_free()
