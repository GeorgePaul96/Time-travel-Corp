extends Control

func _ready() -> void:
	SaveManager.load_game()
	SaveManager.calculate_offline_progress()

	GameManager.state_changed.connect(_update_ui)

	%TerminalButton.pressed.connect(func(): %TerminalOverlay.show())
	%SaveButton.pressed.connect(func(): SaveManager.save())
	$TerminalOverlay/CenterContainer/VBoxContainer/CloseTerminalBtn.pressed.connect(func(): %TerminalOverlay.hide())

	%StabilityUpgradeBtn.pressed.connect(func(): GameManager.buy_upgrade("stability_regen", 10.0))
	%EnergyUpgradeBtn.pressed.connect(func(): GameManager.buy_upgrade("energy_regen", 10.0))
	%ProductionUpgradeBtn.pressed.connect(func(): GameManager.buy_upgrade("production_bonus", 20.0))
	$TerminalOverlay/CenterContainer/VBoxContainer/UpgradesContainer/PrestigeBtn.pressed.connect(func():
		GameManager.prestige()
		%TerminalOverlay.hide()
	)

	_update_ui()

func _update_ui() -> void:
	var res = GameManager.state.resources
	%CapitalLabel.text = "Capital: " + str(snapped(res.capital, 0.1))
	%EnergyLabel.text = "Energy: " + str(snapped(res.energy, 0.1)) + "/" + str(res.energy_max)
	%AnomaliesLabel.text = "Anomalies: " + str(snapped(res.anomalies, 0.1))
