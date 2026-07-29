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

	var flag_expr: String	= str(cr.resolve_value(engine, engine, command_value.get("Flag", ""), sym)).strip_edges()
	var rhs_raw				= command_value.get("Expression", "")
	var operator: String	= str(cr.resolve_value(engine, engine, command_value.get("Operator", "="), sym)).strip_edges()

	if flag_expr == "":
		return "Continue"

	#@ Step 1 - Evaluate the value:
	#% Empty = null (operators other than "=" use the current value):
	var rhs_empty: bool = typeof(rhs_raw) == TYPE_STRING and rhs_raw.strip_edges().is_empty()
	if rhs_empty and operator == "=":
		printerr("Flag: empty expression")
		return "Continue"

	var rhs_value: Variant = null
	if not rhs_empty:
		rhs_value = cr.resolve_value(engine, engine, rhs_raw, sym)
		if cr.last_failed:
			printerr("Flag: could not evaluate Expression → ", rhs_raw)
			return "Continue"

	#@ Step 2 - Apply operator:
	var final_value = CandyValues.get_shared().calculate_value(engine, self, candy_de.flags.get(flag_expr), rhs_value, operator)

	#@ Step 3 - Assign:
	candy_de.flags[flag_expr] = final_value

	#. Hook:
	#TODO: Hook called without 'await'. Add 'await' if desired.
	candy_de.run_hook("x_flag_changed", {"caller": engine, "flag": flag_expr, "value": final_value}, CandyCustomData.levels([command_value]))

	if OS.is_debug_build() and engine.debug_prints == true:
		print("[DEBUG] Flag →", flag_expr, operator, rhs_raw, "=", final_value)

	return "Continue"
