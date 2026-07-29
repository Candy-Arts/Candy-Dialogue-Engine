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


func handle(engine: CandyEngine, input_ui: Node, _depth: int, _parameters: Variant, _ctx: CandyContext) -> String:
	if input_ui.has_method("suspend_on"):
		input_ui.suspend_on()

	await engine._await_suspension()

	if input_ui.has_method("suspend_off"):
		input_ui.suspend_off()

	if engine.killswitch == true:
		return "END"

	return "Wait"
