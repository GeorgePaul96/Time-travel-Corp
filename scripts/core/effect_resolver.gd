class_name EffectResolver
extends RefCounted

## Static utility for interpreting op-list effects onto RunState / EraState.
## Effect Dictionary schema:
##   stat: String      — which stat to modify
##   op: String        — "add", "multiply", "set"
##   value: float      — the operand
##   scope: String     — "global", "era"
##   era_id: String    — required when scope == "era"
##   duration: int     — -1=permanent, 0=instant, N=quarters
##   duration_quarters — alias for duration

static func apply_op(base: float, effect: Dictionary) -> float:
	var op: String = effect.get("op", "add")
	var val := float(effect.get("value", 0.0))
	match op:
		"add":      return base + val
		"multiply": return base * val
		"set":      return val
	return base

static func apply_global(effect: Dictionary, state: RunState) -> void:
	match effect.get("stat", ""):
		"capital":
			state.capital = apply_op(state.capital, effect)
		"injunctions":
			state.injunctions = int(apply_op(float(state.injunctions), effect))
		"singularity":
			state.singularity = apply_op(state.singularity, effect)

static func apply_to_era(effect: Dictionary, era_state: EraState, state: RunState) -> void:
	match effect.get("stat", ""):
		"instability":
			era_state.instability = clampf(apply_op(era_state.instability, effect), 0.0, 100.0)
		"momentum":
			era_state.momentum = apply_op(era_state.momentum, effect)
		"singularity":
			state.singularity += float(effect.get("value", 25.0))

static func get_global_multiplier(stat: String, active_directives: Array) -> float:
	var result := 1.0
	for directive in active_directives:
		for effect in directive.get("effects", []):
			if effect.get("scope", "") == "global" and effect.get("stat", "") == stat:
				if effect.get("op", "") == "multiply":
					result *= float(effect.get("value", 1.0))
	return result

static func get_era_multiplier(stat: String, era_id: StringName, active_directives: Array) -> float:
	var result := 1.0
	for directive in active_directives:
		for effect in directive.get("effects", []):
			if (effect.get("scope", "") == "era"
					and StringName(effect.get("era_id", "")) == era_id
					and effect.get("stat", "") == stat
					and effect.get("op", "") == "multiply"):
				result *= float(effect.get("value", 1.0))
	return result

static func has_flag(flag: String, active_directives: Array) -> bool:
	for directive in active_directives:
		for effect in directive.get("effects", []):
			if effect.get("stat", "") == flag and float(effect.get("value", 0.0)) > 0.0:
				return true
	return false

static func tick_directive_durations(state: RunState) -> void:
	var to_remove: Array = []
	for directive in state.active_directives:
		var remaining: int = int(directive.get("quarters_remaining", -1))
		if remaining == -1:
			continue
		directive["quarters_remaining"] = remaining - 1
		if directive["quarters_remaining"] <= 0:
			to_remove.append(directive)
	for d in to_remove:
		state.active_directives.erase(d)
