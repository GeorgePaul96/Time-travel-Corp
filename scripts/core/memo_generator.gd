extends Node
class_name MemoGenerator

const VOICES = ["The Board", "HR", "Legal", "The Founder"]

static func get_pace_and_ratio(state: RunState, quota: float) -> Dictionary:
	if not state or quota <= 0.0:
		return {"pace": "On Pace", "ratio": 1.0, "diff_pct": 0.0}
	
	var ratio := state.capital / quota
	var expected_ratio := float(state.quarter) / 8.0
	
	var pace := "On Pace"
	var diff_pct := 0.0
	if ratio > expected_ratio:
		diff_pct = (ratio - expected_ratio) / expected_ratio * 100.0 if expected_ratio > 0 else 0.0
		if ratio >= expected_ratio * 1.2:
			pace = "Ahead"
		else:
			pace = "On Pace"
	else:
		diff_pct = (expected_ratio - ratio) / expected_ratio * 100.0 if expected_ratio > 0 else 0.0
		if ratio <= expected_ratio * 0.5:
			pace = "Catastrophic"
		else:
			pace = "Behind"
			
	return {"pace": pace, "ratio": ratio, "diff_pct": diff_pct}

static func generate_memo(state: RunState, voice: String) -> String:
	if not state:
		return ""
		
	var contract := ContentDB.get_by_id(state.contract_id) as ContractDef
	var quota := contract.quota if contract else 1000.0
	# Scale quota by audit level and modifiers
	for m in contract.modifiers if contract else []:
		if m.id == &"cheap_money": quota *= 1.3
		if m.id == &"overtime": quota *= 1.4
	quota *= (1.0 + float(MetaState.audit_level) * 0.1)

	var pace_data := get_pace_and_ratio(state, quota)
	var pace: String = pace_data.pace
	var diff_pct: float = pace_data.diff_pct
	
	var header := "TIME TRAVEL CORP // INTERNAL MEMO\n"
	header += "TO: Sector Manager #%d\n" % (state.seed % 10000)
	header += "FROM: %s\n" % voice.to_upper()
	header += "DATE: %s\n" % Time.get_date_string_from_system()
	header += "--------------------------------------------------\n\n"
	
	var body := ""
	match voice:
		"The Board":
			match pace:
				"Ahead":
					body = "RE: Quarterly Yield. The Board expresses moderate satisfaction. Your current margins exceed baseline projections by %.0f%%. Do not let compliance regulations slow this momentum." % diff_pct
				"On Pace":
					body = "RE: Performance Review. Capital extraction matches standard guidelines. Continue operations in the designated sectors."
				"Behind":
					body = "RE: Critical Deficit. Current yield is lagging behind targets by %.0f%%. The Board expects immediate corrective action." % diff_pct
				"Catastrophic":
					body = "RE: Immediate Termination Warning. Yields are negligible. Relic extraction is non-existent. Prepare for emergency audit."
		"HR":
			match pace:
				"Ahead":
					body = "RE: Employee Wellness. Due to record-breaking yields, you are awarded 5 minutes of extra break time. Please spend it in your designated cubicle."
				"On Pace":
					body = "RE: Mid-Year Check-In. We are happy to see you are meeting expectations. Keep up the standard performance!"
				"Behind":
					body = "RE: Performance Improvement Plan. Your extraction rate is substandard. Please consult the employee handbook on temporal efficiency."
				"Catastrophic":
					body = "RE: Offboarding Schedule. HR is organizing your exit interview. Pack your personal belongings in the nearest temporal waste container."
		"Legal":
			match pace:
				"Ahead":
					body = "RE: Regulatory Shielding. Profits are sufficient to settle three pending class-action lawsuits. Carry on."
				"On Pace":
					body = "RE: Compliance Audit. Operations conform to local spacetime laws. No injunctions have been breached."
				"Behind":
					body = "RE: Injunction Threat. Capital deficiency increases exposure to temporal regulator investigations. Rectify immediately."
				"Catastrophic":
					body = "RE: Spacetime Liability. Your negligence has created severe cascading temporal violations. Legal cannot protect you from the regulators."
		"The Founder":
			match pace:
				"Ahead":
					body = "RE: My Vision. When I built this corp, I envisioned disruptors like you. You are tearing history apart for pure profit. Beautiful."
				"On Pace":
					body = "RE: The Grind. Success is built on steady extraction. Don't look back at the eras you leave behind."
				"Behind":
					body = "RE: Disappointment. My legacy is built on extraction, not excuses. Why is antiquity still intact?"
				"Catastrophic":
					body = "RE: Failure. You have ruined my machine. Spacetime is collapsing, and my stock portfolio is down 40%%. Disgraceful."

	var log_str := "\n\n--------------------------------------------------\n"
	log_str += "HISTORICAL LOG EVENTS:\n"
	
	var events := 0
	# Add events from eras
	for es in state.eras:
		if es.mutation_severity > 0:
			log_str += "- [ERA: %s] MUTATION SEVERITY %d\n" % [es.era_id.to_upper(), es.mutation_severity]
			events += 1
			
	# Limit action log output to key events
	var actions := state.action_log.duplicate()
	actions.reverse()
	for act in actions:
		if events >= 4:
			break
		var action_name: String = act.get("action", "")
		var q: int = act.get("quarter", 1)
		var data: Dictionary = act.get("data", {})
		match action_name:
			"place_extractor":
				log_str += "- [Q%d] Placed %s extractor in %s\n" % [q, data.get("type_id", ""), data.get("era_id", "")]
				events += 1
			"harvest":
				log_str += "- [Q%d] Harvested anomaly (Payout: %.0f)\n" % [q, data.get("payout", 0.0)]
				events += 1
			"divert":
				log_str += "- [Q%d] Diverted front (Cost: %.0f)\n" % [q, data.get("cost", 0.0)]
				events += 1
			"dampen":
				log_str += "- [Q%d] Dampened front\n" % q
				events += 1
				
	if events == 0:
		log_str += "- No anomalous operational activity recorded.\n"
		
	return header + body + log_str
