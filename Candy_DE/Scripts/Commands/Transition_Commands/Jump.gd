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
	#Ł Unpack context:
	var current_conversation = ctx.conversation
	var current_block = ctx.block
	var line_index = ctx.line_index

	var jump_target := CandyFlow.get_shared().resolve_transition_target(engine, self, "Jump", command_value, current_conversation, current_block, line_index)
	if not jump_target["ok"]:
		return "END"

	var new_conversation: String = jump_target["conversation"]
	var target_line: int = jump_target["line"]

	#. Hook call:
	#? "line" from the tracker: a nested line's own index is in its built line.
	await candy_de.run_hook("x_jump", {"caller": engine, "line_data": ctx.line_data,
		"conversation": current_conversation, "block": current_block, "line": engine.line_tracker,
		"new_conversation": new_conversation, "new_block": jump_target["block"], "new_line": target_line},
		CandyCustomData.levels([command_value]))

	#% Stopped during the hook:
	if engine.killswitch == true:
		return "END"

	#@ Step 1 - Log and raise the killswitch:
	CandyFlow.get_shared().log_transition(engine, self, "Jump", new_conversation, current_conversation)
	engine.raise_killswitch()

	#@ Step 2 - Run the target Block as a new dialogue:
	#Ł Cleanup:
	engine.nesting_depth = 0
	#Ł Restore the mouse from before the menus:
	CandyChoices.get_shared().restore_mouse(engine, self)
	engine.choice_lists.clear()
	engine.choice_list_data.clear()
	engine.if_array.clear()
	CandyFlow.get_shared().reset_return_state(engine, self)
	CandyChoices.get_shared().free_menus(engine, self)
	await engine.get_tree().process_frame

	#Ł Disable greenlight:
	engine.greenlight = false

	#Ł Jump:
	engine.jump_start_dialogue(new_conversation, jump_target["block"], target_line)
	return "END"
