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


func execute(engine: CandyEngine, command_value: Variant, ctx: CandyContext) -> String:
	#. Hook call:
	#? "line" from the tracker: a nested line's own index is in its built line.
	await candy_de.run_hook("x_end", {"caller": engine, "line_data": ctx.line_data,
		"conversation": ctx.conversation, "block": ctx.block, "line": engine.line_tracker},
		CandyCustomData.levels([command_value]))

	CandyFlow.get_shared().log_transition(engine, self, "End")
	return "END"
