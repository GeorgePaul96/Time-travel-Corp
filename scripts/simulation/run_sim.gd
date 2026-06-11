extends Node

## Central simulation owner and state machine for runs.

enum RunState {
	IDLE,
	INITIALIZING,
	RUNNING,
	PAUSED,
	COMPLETED,
	FAILED
}

var current_state: RunState = RunState.IDLE

func start_run() -> void:
	if current_state != RunState.IDLE and current_state != RunState.COMPLETED and current_state != RunState.FAILED:
		push_warning("RunSim: Cannot start run from current state.")
		return

	current_state = RunState.INITIALIZING
	# Setup logic goes here

	current_state = RunState.RUNNING
	EventBus.run_started.emit()

func end_run() -> void:
	if current_state != RunState.RUNNING and current_state != RunState.PAUSED:
		return

	current_state = RunState.COMPLETED
	EventBus.run_ended.emit()

func tick() -> void:
	if current_state != RunState.RUNNING:
		return

	# Process simulation mechanics
	EventBus.tick_processed.emit()

func pause() -> void:
	if current_state == RunState.RUNNING:
		current_state = RunState.PAUSED
		EventBus.run_paused.emit()

func resume() -> void:
	if current_state == RunState.PAUSED:
		current_state = RunState.RUNNING
		EventBus.run_resumed.emit()

func _process(_delta: float) -> void:
	if current_state == RunState.RUNNING:
		# Tick timer logic
		pass
