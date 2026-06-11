extends Control

@onready var result_label: Label = $VBox/ResultLabel
@onready var capital_label: Label = $VBox/CapitalLabel
@onready var quota_label: Label = $VBox/QuotaLabel
@onready var stats_label: Label = $VBox/StatsLabel
@onready var anomaly_label: Label = $VBox/AnomalyLabel
@onready var play_again_btn: Button = $VBox/PlayAgainBtn
@onready var main_menu_btn: Button = $VBox/MainMenuBtn

func _ready() -> void:
	play_again_btn.pressed.connect(_on_play_again)
	main_menu_btn.pressed.connect(_on_main_menu)
	EventBus.run_ended.connect(_on_run_ended)

func _on_run_ended(result: Dictionary) -> void:
	_populate(result)

func _populate(result: Dictionary) -> void:
	var won: bool = result.get("won", false)
	result_label.text = "CONTRACT FULFILLED" if won else "CONTRACT TERMINATED"
	capital_label.text = "Final Capital: µ%.0f" % result.get("capital", 0.0)
	quota_label.text = "Quota: µ%.0f" % result.get("quota", 0.0)

	var cause := result.get("cause", "")
	var extra := ""
	if not won:
		extra = "\nTHE SINGULARITY HAS ARRIVED." if cause == "singularity" else "\nQuota not reached by Q8."

	stats_label.text = "Mutations: %d%s" % [result.get("mutations", 0), extra]
	anomaly_label.text = "Anomalies Earned: ⌬%d" % result.get("anomalies_earned", 0)

func _on_play_again() -> void:
	get_tree().change_scene_to_file("res://scenes/meta/contract_select.tscn")

func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/meta/main_menu.tscn")
