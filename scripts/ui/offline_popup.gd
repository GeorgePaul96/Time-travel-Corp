extends Control

@onready var time_label: Label = $PanelContainer/VBoxContainer/TimeLabel
@onready var rewards_label: Label = $PanelContainer/VBoxContainer/RewardsLabel
@onready var ok_btn: Button = $PanelContainer/VBoxContainer/OkBtn

func _ready() -> void:
	ok_btn.pressed.connect(func(): visible = false)

func show_rewards(data: Dictionary) -> void:
	var elapsed = int(data.get("elapsed_seconds", 0))
	var hours = elapsed / 3600
	var minutes = (elapsed % 3600) / 60
	time_label.text = "You were away %dh %dm." % [hours, minutes]
	var rewards = data.get("rewards", {})
	var lines: Array = ["Your agents collected:"]
	if rewards.get("credits", 0.0) > 0:
		lines.append("  +%.0f ₢ Credits" % rewards.get("credits", 0.0))
	if rewards.get("knowledge", 0.0) > 0:
		lines.append("  +%.0f Knowledge" % rewards.get("knowledge", 0.0))
	if rewards.get("historical_data", 0.0) > 0:
		lines.append("  +%.0f Historical Data" % rewards.get("historical_data", 0.0))
	if lines.size() == 1:
		lines.append("  Nothing this time.")
	rewards_label.text = "\n".join(lines)
	visible = true
