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
	#Ł Shared by every movement - running count and outcome:
	var progress: Dictionary = {"running": 0, "outcome": "Continue"}

	#@ Step 1 - Start each target's movement:
	for target in CandyCutscene.get_shared().get_targets(engine, self, command_value, "Targets", "CS_Move"):
		var movement: String = str(target[1].get("Movement", "")).strip_edges()

		if movement == "":
			printerr("Conversation: " + str(ctx.conversation) + " Block: " + str(ctx.block) + " Line: " + str(ctx.line_index) + " - CS_Move: no 'Movement' for " + str(target[2]) + ".")
			continue

		if not engine.move_event_registry.has(movement.to_lower()):
			printerr("Conversation: " + str(ctx.conversation) + " Block: " + str(ctx.block) + " Line: " + str(ctx.line_index) + " - CS_Move: no script for the 'Movement' value '" + movement + "' in the Move_Events folder → " + str(target[2]))
			continue

		progress["running"] += 1
		_run_movement(engine, engine.move_event_registry[movement.to_lower()], movement, target, ctx, progress)

	#@ Step 2 - Wait for the movements that are still running:
	while progress["running"] > 0:
		await engine.get_tree().process_frame
		if engine.killswitch == true:
			return "END"

	if engine.killswitch == true:
		return "END"
	return progress["outcome"]


#* Run a target's movement script and record its outcome:
func _run_movement(engine: CandyEngine, event_script: CandyMoveEvent, movement: String, target: Array, ctx: CandyContext, progress: Dictionary) -> void:
	@warning_ignore("redundant_await")
	var outcome: String = await event_script.handle(engine, target[0], target[1].get("Data", ""), ctx, target[3])

	#Ł "END" beats "Return", which beats "Continue":
	if outcome == "END":
		progress["outcome"] = "END"
	elif outcome == "Return":
		if progress["outcome"] != "END":
			progress["outcome"] = "Return"
	elif outcome != "Continue":
		push_warning("Candy DE: CS_Move movement '%s' returned '%s' - expected \"Continue\", \"Return\" or \"END\"." % [movement, outcome])

	progress["running"] -= 1
