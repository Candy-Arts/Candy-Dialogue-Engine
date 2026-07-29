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


func handle(engine: CandyEngine, input_ui: Node, depth: int, parameters: Variant, _ctx: CandyContext) -> String:
	if OS.is_debug_build() and engine.debug_prints == true:
		print("[DEBUG] Input (Depth %s): Event: close (%s)." % [str(depth), parameters])
	input_ui.queue_free()
	return "Continue"
