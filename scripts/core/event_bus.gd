extends Node

# Simulation lifecycle
signal run_started
signal run_ended
signal run_paused
signal run_resumed
signal tick_processed

# Content pipeline
signal content_loaded
signal content_validation_failed(errors: Array)

# Generic system signals
signal screen_changed(screen_name: String)
