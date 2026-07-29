#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends CandyCommand


func execute(engine: CandyEngine, command_value: Variant, _ctx: CandyContext) -> String:
	var cr: CandyRef = engine.candy_ref
	var sym: String = candy_de.candy_ref_symbol

	var lhs_var = command_value.get("Variable", "")
	var rhs_raw = command_value.get("Expression", "")
	var operator: String = str(cr.resolve_value(engine, engine, command_value.get("Operator", "="), sym)).strip_edges()

	#% Empty = null (operators other than "=" use the current value):
	var rhs_empty: bool = typeof(rhs_raw) == TYPE_STRING and rhs_raw.strip_edges().is_empty()
	if rhs_empty and operator == "=":
		printerr("Set: empty expression")
		return "Continue"

	#@ Step 1 - Evaluate the value:
	var rhs_value = null
	if not rhs_empty:
		rhs_value = cr.resolve_value(engine, engine, rhs_raw, sym)
		if cr.last_failed:
			printerr("Set: could not evaluate Expression → ", rhs_raw)
			return "Continue"

	#@ Step 2 - Find the variable and write to it:
	var found := cr.resolve_target(engine, engine, lhs_var, sym)
	if not found["ok"]:
		printerr("Set: invalid variable → ", lhs_var)
		return "Continue"

	if not CandyTargets.get_shared().write_target(engine, self, found, rhs_value, operator, "Set"):
		printerr("Set: failed to write → ", lhs_var)

	return "Continue"
