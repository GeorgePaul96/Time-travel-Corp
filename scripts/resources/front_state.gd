extends Resource
class_name FrontState

@export var uid: int = 0
@export var type_id: StringName = &""
@export var codename: String = ""
@export var severity: int = 1
@export var origin_era_id: StringName = &""
@export var target_era_id: StringName = &""
@export var progress: float = 0.0
@export var travel_time: float = 45.0
@export var harvested: bool = false
@export var diverted_from: StringName = &""
@export var spawn_quarter: int = 0