extends Resource
class_name ContractDef

@export var id: StringName = &""
@export var tier: int = 1
@export var display_name: String = ""
@export var quota: float = 0.0
@export var quota_relics: int = 0
@export var quarters: int = 8
@export var starting_injunctions: int = 3
@export var modifiers: Array[ModifierDef] = []
@export var mandate_pool: Array[MandateDef] = []
@export var anomaly_reward: int = 10