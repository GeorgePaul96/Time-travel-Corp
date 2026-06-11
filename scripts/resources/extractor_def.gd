extends Resource
class_name ExtractorDef

@export var id: StringName = &""
@export var display_name: String = ""
@export var base_cost: float = 100.0
@export var yield_per_second: float = 10.0
@export var instability_per_second: float = 0.5
@export var burst_duration: float = 0.0
@export var burst_yield: float = 0.0
@export var burst_instability_spike: float = 0.0
@export var post_burst_yield: float = 0.0
@export var deep_countdown_quarters: int = 0