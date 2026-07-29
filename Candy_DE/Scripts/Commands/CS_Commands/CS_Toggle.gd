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
	for target in CandyCutscene.get_shared().get_targets(engine, self, command_value, "Targets", "CS_Toggle"):
		var node: Node = target[0]
		var settings: Dictionary = target[1]
		if node.has_method("candy_toggle"):
			node.candy_toggle(settings.get("Method", ""), settings.get("Properties", ""), settings.get("Value", ""))
		else:
			printerr("CS_Toggle: node has no candy_toggle() → ", target[2])

	return "Continue"
