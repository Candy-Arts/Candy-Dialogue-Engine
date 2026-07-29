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
	var cutscene := CandyCutscene.get_shared()

	#@ Step 1 - Start every target:
	var started: Array = []
	for target in cutscene.get_targets(engine, self, command_value, "Targets", "CS_Sprite_Play"):
		var node := cutscene.sprite_node(engine, self, target[0], target[1], "CS_Sprite_Play")
		if node == null:
			continue
		if await cutscene.play_sprite(engine, self, target[0], node, target[1], "CS_Sprite_Play", target[3]):
			started.append([node, target[1]])

	#@ Step 2 - Wait on each target in turn:
	#? Sequential waits end with the last target.
	for entry in started:
		if await cutscene.wait_node(engine, self, entry[0], entry[1], "CS_Sprite_Play") == "END":
			return "END"

	return "Continue"
