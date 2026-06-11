extends Resource
class_name EraState

@export var era_id: StringName = &""
@export var instability: float = 0.0
@export var extractors: Array[Dictionary] = []
@export var mutation_severity: int = 0
@export var momentum: float = 0.0
@export var momentum_timer: float = 0.0
@export var contained: bool = false
@export var emission_timer: float = 0.0