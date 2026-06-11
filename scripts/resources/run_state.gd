extends Resource
class_name RunState

@export var seed: int = 0
@export var contract_id: StringName = &""
@export var quarter: int = 1
@export var sim_time: float = 0.0
@export var quarter_time: float = 0.0
@export var capital: float = 0.0
@export var relics: int = 0
@export var injunctions: int = 3
@export var restock_count: int = 0
@export var singularity: float = 0.0
@export var eras: Array[EraState] = []
@export var fronts: Array[FrontState] = []
@export var active_directives: Array[Dictionary] = []
@export var flags: Dictionary = {}
@export var action_log: Array[Dictionary] = []
@export var parachute_used: bool = false
@export var quarter_capitals: Array[float] = []