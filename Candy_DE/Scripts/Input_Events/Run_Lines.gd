#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends CandyInputEvent


func handle(engine: CandyEngine, input_ui: Node, depth: int, parameters: Variant, ctx: CandyContext) -> String:
	if not (parameters is Array) or parameters.is_empty():
		printerr("Input: 'run_lines' event received but parameters are missing or not an array.")
		return "Wait"

	var feedback = await CandyFlow.get_shared().run_nested_line(engine, self, parameters, ctx.conversation, ctx.block)
	if feedback == "END":
		return "END"

	#% Return → close the Input UI and unwind:
	if feedback == "Return":
		if is_instance_valid(input_ui):
			input_ui.queue_free()
		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] Input (Depth %s): 'run_lines' issued a Return; closing Input UI and unwinding." % str(depth))
		return "Return"

	return "Wait"
