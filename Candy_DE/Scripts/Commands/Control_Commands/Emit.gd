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

	var signal_raw = command_value.get("Signal", "")

	#% Validate:
	if typeof(signal_raw) == TYPE_STRING and signal_raw.strip_edges() == "":
		push_error("Emit: \"Signal\" is an empty string.")
		return "Continue"

	#@ Step 1 - Prepare arguments:
	var args_value = cr.resolve_value(engine, engine, command_value.get("Arguments", ""), sym)
	if cr.last_failed:
		printerr("Emit: could not evaluate Arguments → ", command_value.get("Arguments", ""))
		return "Continue"

	var args: Array = []
	if typeof(args_value) == TYPE_ARRAY:
		args = args_value
	elif not (typeof(args_value) == TYPE_STRING and args_value == ""):
		args = [args_value]

	#@ Step 2 - Find the signal:
	var target = CandyTargets.get_shared().resolve_named(engine, self, signal_raw)
	if cr.last_failed or typeof(target) != TYPE_SIGNAL:
		printerr("Emit: not a signal → ", signal_raw)
		return "Continue"

	var sig: Signal = target
	if not is_instance_valid(sig.get_object()):
		printerr("Emit: the signal's object no longer exists → ", signal_raw)
		return "Continue"

	#@ Step 3 - Emit:
	sig.get_object().callv("emit_signal", [sig.get_name()] + args)

	return "Continue"
