extends Resource
class_name BalanceSheetData

# Front travel
@export var front_travel_base: float = 45.0
@export var mutation_speed_bonus: float = 0.2

# Singularity
@export var soot_singularity_gain: float = 25.0
@export var multi_mutation_singularity_per_quarter: float = 10.0

# Extractors
@export var extractor_cost_scaling: float = 1.6
@export var extractor_salvage_rate: float = 0.25
@export var temporal_scar_instability: float = 10.0
@export var deep_antiquity_bonus: float = 1.5
@export var momentum_stack_rate: float = 0.05
@export var momentum_cap: float = 1.0

# Harvest
@export var harvest_speed_bonus: float = 0.75
@export var harvest_contract_bonus: float = 150.0

# Era interaction
@export var mutation_neighbor_pressure: float = 0.05

# Instability
@export var instability_overflow_reset: float = 40.0

# Restock
@export var restock_base_cost_pct: float = 0.15

# Q-phase multipliers
@export var early_quarter_instability_mult: float = 0.6
@export var late_quarter_yield_bonus: float = 0.25
@export var late_quarter_instability_reduction: float = 0.4

# Foundation downstream bonus
@export var foundation_max_bonus: float = 0.5

# Future speculation
@export var speculation_era_count: int = 4
