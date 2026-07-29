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
	for target in CandyCutscene.get_shared().get_targets(engine, self, command_value, "Targets", "CS_Visible"):
		var node: Node = target[0]

		if not ("visible" in node):
			printerr("CS_Visible: node has no 'visible' property → ", target[2])
			continue

		var status := str(target[1].get("Visibility", "")).strip_edges().to_lower()
		match status:
			"true", "1", "on", "show", "unhidden", "visible":
				node.visible = true
			"false", "0", "off", "hide", "hidden", "invisible":
				node.visible = false
			"toggle", "swap", "switch":
				node.visible = not node.visible
			_:
				printerr("CS_Visible: unknown Visibility value → '", status, "' for ", target[2])

	return "Continue"
