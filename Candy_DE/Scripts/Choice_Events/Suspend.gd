#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends CandyChoiceEvent


func handle(engine: CandyEngine, _menu: Node, _depth: int, _category: Variant, _choice: Variant, _sender: Object, _ctx: CandyContext) -> String:
	await engine._await_suspension()
	if engine.killswitch == true:
		return "END"
	return "Wait"
