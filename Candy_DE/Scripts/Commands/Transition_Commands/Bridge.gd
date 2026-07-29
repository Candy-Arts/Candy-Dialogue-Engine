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

	var bridge_target := CandyFlow.get_shared().resolve_transition_target(engine, self, "Bridge", command_value, current_conversation, current_block, line_index)
	if not bridge_target["ok"]:
		return "END"

	var new_conversation: String = bridge_target["conversation"]
	var target_line: int = bridge_target["line"]

	#. Hook call:
	#? "line" from the tracker: a nested line's own index is in its built line.
	await candy_de.run_hook("x_bridge", {"caller": engine, "line_data": ctx.line_data,
		"conversation": current_conversation, "block": current_block, "line": engine.line_tracker,
		"new_conversation": new_conversation, "new_block": bridge_target["block"], "new_line": target_line},
		CandyCustomData.levels([command_value]))

	#% Stopped during the hook:
	if engine.killswitch == true:
		return "END"

	#@ Step 1 - Log and run the Block:
	CandyFlow.get_shared().log_transition(engine, self, "Bridge", new_conversation, current_conversation)

	#Ł Save the caller's trackers:
	var caller_trackers := [engine.conversation_tracker, engine.block_tracker, engine.line_tracker, engine.line_data_tracker, engine.resolved_disp_tracker]

	engine.nesting_depth += 1
	if OS.is_debug_build() and engine.debug_prints == true:
		print(target_line)
	var bridge_result = await engine.run_dialogue(new_conversation, bridge_target["block"], target_line, "Text", false)
	engine.nesting_depth = max(0, engine.nesting_depth - 1)

	#Ł Restore the caller's trackers (not on "END"):
	if bridge_result != "END":
		engine.prev_conversation_tracker = engine.conversation_tracker
		engine.prev_block_tracker = engine.block_tracker
		engine.prev_line_tracker = engine.line_tracker
		engine.prev_line_data_tracker = engine.line_data_tracker
		engine.prev_resolved_disp_tracker = engine.resolved_disp_tracker

		engine.conversation_tracker = caller_trackers[0]
		engine.block_tracker = caller_trackers[1]
		engine.line_tracker = caller_trackers[2]
		engine.line_data_tracker = caller_trackers[3]
		engine.resolved_disp_tracker = caller_trackers[4]

	#@ Step 2 - Return from transition:
	#Ł Trim if_array entries left by the bridged Block:
	if engine.if_array.size() > engine.nesting_depth + 1:
		engine.if_array.resize(engine.nesting_depth + 1)

	#% "END":
	if bridge_result == "END":
		return "END"

	#% Unfinished Return - unwind this Block too:
	#? Before Step 3, so no menu is reactivated on an unwinding frame.
	if bridge_result == "Return":
		return "Return"

	#@ Step 3 - Reactivate this depth's choice menu:
	#? Not a Hide_Menu one: show_after_transition() shows it.
	if engine.choice_lists.has(engine.nesting_depth) and engine.choice_lists[engine.nesting_depth].get("Transition Hidden", false) != true:
		var previous_menu = engine.choice_lists[engine.nesting_depth].get("Menu", null)
		if previous_menu != null and is_instance_valid(previous_menu) and not previous_menu.is_queued_for_deletion():
			if previous_menu.has_method("reactivate"):
				await previous_menu.reactivate(CandyChoices.get_shared().menu_custom_data(engine, self, engine.nesting_depth))
			else:
				previous_menu.visible = true

	return "Continue"
