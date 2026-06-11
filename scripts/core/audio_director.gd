extends Node

func play_sfx(sound_id: String) -> void:
	print("AudioDirector: Playing SFX ", sound_id)

func play_music(track_id: String) -> void:
	print("AudioDirector: Playing music ", track_id)

func stop_music() -> void:
	print("AudioDirector: Stopping music")
