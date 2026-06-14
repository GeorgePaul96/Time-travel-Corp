extends Control

@onready var result_label: Label = $VBox/ResultLabel
@onready var report_label: RichTextLabel = $VBox/ReportLabel
@onready var export_seed_btn: Button = $VBox/ExportSeedBtn
@onready var play_again_btn: Button = $VBox/NavButtons/PlayAgainBtn
@onready var main_menu_btn: Button = $VBox/NavButtons/MainMenuBtn

var _displayed_text: String = ""
var _char_index: int = 0
var _timer: Timer

func _ready() -> void:
	play_again_btn.pressed.connect(_on_play_again)
	main_menu_btn.pressed.connect(_on_main_menu)
	export_seed_btn.pressed.connect(_on_export_seed)
	
	if not RunSim.last_run_result.is_empty():
		_populate(RunSim.last_run_result)
	else:
		EventBus.run_ended.connect(_on_run_ended)

func _on_run_ended(result: Dictionary) -> void:
	_populate(result)

func _populate(result: Dictionary) -> void:
	var won: bool = result.get("won", false)
	var cause: String = result.get("cause", "")
	var seed_val: int = result.get("seed", 0)
	var capital: float = result.get("capital", 0.0)
	var quota: float = result.get("quota", 0.0)
	var anomalies_earned: int = result.get("anomalies_earned", 0)
	var mutations: int = result.get("mutations", 0)
	var mandate_id: StringName = result.get("mandate_id", &"")
	var mandate_won: bool = result.get("mandate_won", false)
	var mandate_bonus: int = result.get("mandate_bonus", 0)
	
	result_label.text = "CONTRACT COMPLETED" if won else "CONTRACT TERMINATED"
	if not won and cause == "singularity":
		result_label.text = "SOCIETAL COLLAPSE - GAME OVER"
		
	# Build the teletype Incident Report text
	var text := "==================================================\n"
	text += "          TIME TRAVEL CORP - INCIDENT REPORT\n"
	text += "==================================================\n"
	text += "TIMELINE SEED: %d\n" % seed_val
	text += "AUDIT LEVEL: A%d\n" % MetaState.audit_level
	text += "STATUS: %s\n" % ("FULFILLED" if won else "TERMINATED")
	if not won and cause == "singularity":
		text += "CAUSE: SINGULARITY CRITICAL COLLAPSE (100% threshold crossed)\n"
	elif not won:
		text += "CAUSE: FINANCIAL FAILURE (Quota shortfalls)\n"
	text += "--------------------------------------------------\n"
	text += "FINANCIAL PERFORMANCE PROGRESSION:\n"
	
	# Quota progression graph
	var state := RunSim.get_state()
	var cap_history: Array = state.quarter_capitals if state else [capital]
	if cap_history.is_empty():
		cap_history = [capital]
	for i in range(cap_history.size()):
		var q_cap: float = cap_history[i]
		var ratio := q_cap / quota if quota > 0.0 else 0.0
		var num_blocks := mini(20, int(ratio * 20.0))
		var bar := "#".repeat(num_blocks) + " ".repeat(20 - num_blocks)
		text += "Q%d: [%s]  µ%.0f\n" % [i + 1, bar, q_cap]
		
	text += "FINAL SCORE: µ%.0f / µ%.0f (%.0f%% of Quota)\n" % [capital, quota, (capital/quota * 100.0 if quota > 0.0 else 0.0)]
	text += "--------------------------------------------------\n"
	text += "HISTORICAL ANOMALY HIGHLIGHTS:\n"
	
	# Find largest harvest
	var max_harvest := 0.0
	var action_log: Array = result.get("action_log", [])
	for act in action_log:
		if act.get("action") == "harvest":
			var pay = act.get("data", {}).get("payout", 0.0)
			if pay > max_harvest:
				max_harvest = pay
	if max_harvest > 0.0:
		text += "- Largest Harvest payout: µ%.0f\n" % max_harvest
	else:
		text += "- Largest Harvest payout: N/A (No harvests recorded)\n"
		
	# Worst mutation
	if mutations > 0:
		var worst_era := ""
		var max_sev := 0
		if state:
			for es in state.eras:
				if es.mutation_severity > max_sev:
					max_sev = es.mutation_severity
					worst_era = es.era_id
		if worst_era != "":
			text += "- Worst Mutation: SEVERITY %d in %s\n" % [max_sev, worst_era.to_upper()]
		else:
			text += "- Worst Mutation: Severity Level %d registered\n" % mutations
	else:
		text += "- Worst Mutation: None (Spacetime integrity intact)\n"
		
	# Closest Call
	text += "- Final Singularity level: %.1f%% / 100%%\n" % result.get("singularity", 0.0)
	
	text += "--------------------------------------------------\n"
	
	# Redacted Board Mandate reveal
	if mandate_id != &"":
		var mandate := ContentDB.get_by_id(mandate_id) as MandateDef
		var m_name := mandate.display_name if mandate else str(mandate_id)
		text += "BOARD MANDATE: [REDACTED: %s]\n" % m_name.to_upper()
		text += "MANDATE STATUS: %s\n" % ("SUCCESS (+⌬%d bonus)" % mandate_bonus if mandate_won else "FAILED (No bonus)")
	else:
		text += "BOARD MANDATE: None assigned\n"
		
	text += "--------------------------------------------------\n"
	text += "NET ANOMALY REWARDS: ⌬%d earned\n" % anomalies_earned
	text += "==================================================\n"
	
	# Final evaluation/verdict memo from the Founder
	text += "EVALUATION BY THE FOUNDER:\n"
	if won:
		text += "\"PROMOTION APPROVED. Your spacetime extraction has met the required thresholds. Welcome to the Senior Manager tier. Stay greedy.\"\n"
	elif cause == "singularity":
		text += "\"DISASTER PROTOCOL ENGAGED. You collapsed the spacetime continuum. Sector deleted. The bill for timeline restructuring will be deducted from your final paycheck.\"\n"
	else:
		text += "\"CONTRACT TERMINATED. Your temporal extraction license has been revoked. We have dispatched security to relocate your timeline. Clean out your desk.\"\n"
		
	_start_teletype(text)

func _start_teletype(text: String) -> void:
	_displayed_text = text
	_char_index = 0
	report_label.text = ""
	
	if _timer:
		_timer.queue_free()
		
	_timer = Timer.new()
	_timer.wait_time = 0.005 # very fast typing since the report is quite long
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	_timer.start()

func _on_timer_timeout() -> void:
	if _char_index < _displayed_text.length():
		report_label.text += _displayed_text[_char_index]
		_char_index += 1
	else:
		_timer.stop()
		_timer.queue_free()
		_timer = null

func _on_export_seed() -> void:
	var seed_val = RunSim.last_run_result.get("seed", 0)
	DisplayServer.clipboard_set(str(seed_val))
	export_seed_btn.text = "SEED COPIED TO CLIPBOARD: %d" % seed_val

func _on_play_again() -> void:
	get_tree().change_scene_to_file("res://scenes/meta/contract_select.tscn")

func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/meta/main_menu.tscn")
