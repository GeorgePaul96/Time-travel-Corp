extends Node

func _ready() -> void:
	MetaState.load()
	ContentDB.load_all_content()
	ContentDB.validate_content()
	var err := get_tree().change_scene_to_file("res://scenes/meta/main_menu.tscn")
	if err != OK:
		push_error("Boot: failed to load main menu — error %d" % err)
