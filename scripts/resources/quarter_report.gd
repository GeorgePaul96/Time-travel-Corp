extends Resource
class_name QuarterReport

@export var quarter: int = 0
@export var capital_start: float = 0.0
@export var capital_end: float = 0.0
@export var fronts_dampened: int = 0
@export var fronts_harvested: int = 0
@export var fronts_diverted: int = 0
@export var mutations_this_quarter: int = 0
@export var directives_offered: Array[DirectiveDef] = []
@export var directive_chosen_id: StringName = &""