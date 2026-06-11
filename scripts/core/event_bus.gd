extends Node

# Simulation lifecycle
signal run_started
signal run_ended(result: Dictionary)
signal run_paused
signal run_resumed
signal tick_processed

# Front events
signal front_spawned(front: FrontState)
signal front_resolved(front: FrontState, resolution: int)  # 0=arrived, 1=dampened, 2=diverted

# Era events
signal era_mutated(era_id: StringName, severity: int)
signal singularity_changed(value: float)

# Quarter events
signal quarter_ended(report: QuarterReport)
signal directive_required(directives: Array)

# Incident (Phase 2)
signal incident_triggered(incident: IncidentDef)

# Content pipeline
signal content_loaded
signal content_validation_failed(errors: Array)

# UI meta
signal screen_changed(screen_name: String)

# Player action relay — used for action log and replay
signal player_action(action: Dictionary)
