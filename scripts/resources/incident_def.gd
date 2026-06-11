extends Resource
class_name IncidentDef

@export var id: StringName = &""
@export var trigger: StringName = &""
@export var trigger_filter: Dictionary = {}
@export var weight: float = 1.0
@export var requires_flags: Array[StringName] = []
@export var memo_text: String = ""
@export var choices: Array[Dictionary] = []
@export var once_per_run: bool = true