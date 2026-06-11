extends Resource
class_name MutationDef

@export var id: StringName = &""
@export var display_name: String = ""
@export var effects: Array[Dictionary] = []
@export var emission_interval_quarters: Array[int] = []
@export var yields_relics: bool = false