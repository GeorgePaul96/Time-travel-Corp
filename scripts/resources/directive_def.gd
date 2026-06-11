extends Resource
class_name DirectiveDef

@export_enum("gift", "deal", "mandate") var tone: int = 0
@export var id: StringName = &""
@export var title: String = ""
@export var body: String = ""
@export var effects: Array[Dictionary] = []
@export var duration_quarters: int = -1