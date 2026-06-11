extends Resource
class_name EraDef

@export var id: StringName = &""
@export var display_name: String = ""
@export var downstream_id: StringName = &""
@export var signature_rule: StringName = &""
@export var rule_params: Dictionary = {}
@export var extractor_cost_mult: float = 1.0
@export var instability_gain_mult: float = 1.0
@export var emits_front: StringName = &""
@export var mutation: MutationDef
@export var panel_art: Texture2D
@export var panel_art_mutated: Texture2D