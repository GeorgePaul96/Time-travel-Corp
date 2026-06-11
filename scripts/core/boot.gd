extends Node

func _ready() -> void:
	print("Booting Time Travel Corp...")

	# Initialize state and content
	MetaState.load()
	ContentDB.load_all_content()
	ContentDB.validate_content()

	# Transition to main menu
	var err = get_tree().change_scene_to_file("res://scenes/meta/main_menu.tscn")
	if err != OK:
		push_error("Boot: Failed to load main menu scene.")
