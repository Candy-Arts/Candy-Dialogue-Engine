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


func handle(engine: CandyEngine, menu: Node, depth: int, _category: Variant, choice: Variant, _sender: Object, ctx: CandyContext) -> String:
	var timer_name: String = str(choice)
	if OS.is_debug_build() and engine.debug_prints == true:
		print("[DEBUG] Choice_List: Received 'timer' event → %s (depth %s)." % [timer_name, str(depth)])

	#@ Step 1 - Locate timer data:
	var timers_array: Array = engine.choice_list_data[depth].get("Timers", [])
	var timer_data: Dictionary = {}
	for timer_entry in timers_array:
		if timer_entry.has(timer_name):
			timer_data = timer_entry[timer_name]
			break
	if timer_data.is_empty():
		printerr("Choice_List: Timer '%s' not found in data (depth %s)." %
			[timer_name, str(depth)])
		return "Wait"

	#@ Step 2 - Update timer statuses:
	timer_data["Status"] = "Timeout"	#/ Mark current timer
	engine.choice_lists[depth]["Last Timer"] = timer_name		#/ Record for Timer_Status "Last" mode

	#Ł Count this firing before the Timeout transition:
	#? So a Timer_Status inside it sets the firings still to come.
	var fired_loop: int = int(CandyChoices.get_shared().state_num(engine, self, timer_data, "Loops", 0.0))
	if fired_loop > 0:
		timer_data["Loops"] = fired_loop - 1

	#Ł Pause other timers:
	CandyChoices.get_shared().pause_timers(engine, self, menu, timers_array, timer_name)

	#@ Step 3 - Execute Timeout transition (always Bridge):
	#? Optional: the next steps run without one.
	var timeout_data: Dictionary = timer_data.get("Timeout", {})
	var convo: String = str(engine.candy_ref.resolve_value(engine, engine, timeout_data.get("Conversation", ""), candy_de.candy_ref_symbol)).strip_edges()
	var block: String = str(engine.candy_ref.resolve_value(engine, engine, timeout_data.get("Block", ""), candy_de.candy_ref_symbol)).strip_edges()
	var line_ref: String = str(engine.candy_ref.resolve_value(engine, engine, timeout_data.get("Line", ""), candy_de.candy_ref_symbol)).strip_edges()
	if convo != "" or block != "" or line_ref != "":
		var fake_line := CandyFlow.get_shared().transition_line(engine, self, "Bridge", convo, block, line_ref)
		#? No category: Hide_Menu falls back to the menu's.
		var hide_menu: bool = CandyChoices.get_shared().transition_hides_menu(engine, self, engine.choice_list_data[depth], {}, timeout_data,
			"Choice_List: timer '%s'" % timer_name)
		CandyChoices.get_shared().set_shield(engine, self, menu, true)
		if hide_menu:
			await CandyChoices.get_shared().hide_for_transition(engine, self, depth, menu)
		var feedback = await CandyFlow.get_shared().run_nested_line(engine, self, fake_line, ctx.conversation, ctx.block)
		#% Re-show before dropping the shield, so no choice is picked during reactivate():
		if hide_menu and not (feedback in ["END", "Return"]):
			await CandyChoices.get_shared().show_after_transition(engine, self, depth, menu)
		CandyChoices.get_shared().set_shield(engine, self, menu, false)
		if feedback in ["END", "Return"]:
			await CandyChoices.get_shared().close_menu(engine, self, depth, menu)
			return feedback

		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] Choice_List: Timer '%s' executed Timeout Bridge → %s:%s:%s (feedback=%s)." % [timer_name, convo, block, line_ref, str(feedback)])

	elif OS.is_debug_build() and engine.debug_prints == true:
		print("[DEBUG] Choice_List: Timer '%s' has no Timeout transition defined." % timer_name)

	#@ Step 4 - Handle looping:
	#Ł Re-fetch (the transition may have changed it):
	timers_array = engine.choice_list_data[depth].get("Timers", [])
	timer_data = {}
	for timer_entry in timers_array:
		if timer_entry.has(timer_name):
			timer_data = timer_entry[timer_name]
			break

	if timer_data.is_empty():
		#? Fall through: Step 6 still releases the other timers.
		printerr("Choice_List: Timer '%s' not found after Timeout transition (depth %s)." %
			[timer_name, str(depth)])
	else:
		#Ł Firings left (this one counted in Step 2):
		var loop_val: int = int(CandyChoices.get_shared().state_num(engine, self, timer_data, "Loops", 0.0))
		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] Choice_List: Timer '%s' loops left after timeout = %s, full timer_data = %s" % [timer_name, str(loop_val), str(timer_data)])

		var loops_left: bool = (loop_val == -1 or loop_val > 0)

		#¦ 1. A Timer_Status from the transition wins:
		if timer_data.has("Pending Status"):
			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Choice_List: Timer '%s' - recorded '%s' overrides automatic looping." % [timer_name, timer_data["Pending Status"]])

		#¦ 2. Else loop (applied in Step 6):
		elif loops_left:
			timer_data["Pending Status"] = "Start/Resume"
			if OS.is_debug_build() and engine.debug_prints == true:
				var loops_remaining := str(timer_data["Loops"])
				if loop_val == -1:
					loops_remaining = "∞"
				print("[DEBUG] Choice_List: Timer '%s' queued to restart (loops remaining=%s)." % [timer_name, loops_remaining])

		else:
			timer_data["Status"] = "Hold"
			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Choice_List: Timer '%s' completed all loops (Status=Hold)." % timer_name)

	#@ Step 5 - Trigger Timer_Choices:
	var choice_trigger: String = str(engine.candy_ref.resolve_value(engine, engine, timer_data.get("Timer_Choices", ""), candy_de.candy_ref_symbol)).strip_edges()

	if choice_trigger != "":
		#Ł Accept both "[Category, Choice]" and "Category, Choice":
		#? to_array() adds its own brackets.
		if choice_trigger.begins_with("[") and choice_trigger.ends_with("]"):
			choice_trigger = choice_trigger.substr(1, choice_trigger.length() - 2).strip_edges()
		var parts: Array = CandyLiteral.get_shared().to_array(engine, self, choice_trigger)
		if parts.size() >= 2:
			var cat_name: String = str(parts[0]).strip_edges()
			var choice_name: String = str(parts[1]).strip_edges()
			if cat_name == "" or choice_name == "":
				if OS.is_debug_build() and engine.debug_prints == true:
					print("[DEBUG] Choice_List: Timer '%s' skipped invalid trigger (cat='%s', choice='%s')." % [timer_name, cat_name, choice_name])
			else:
				if OS.is_debug_build() and engine.debug_prints == true:
					print("[DEBUG] Choice_List: Timer '%s' triggering choice '%s' in category '%s'." % [timer_name, choice_name, cat_name])
				var cat_nodes: Dictionary = engine.choice_lists[depth].get("Category Nodes", {})
				if cat_nodes.has(cat_name):
					var cat_node = cat_nodes[cat_name].get("Node", null)
					if cat_node and cat_node.button_list.has_node(choice_name):
						var choice_button: Node = cat_node.button_list.get_node(choice_name)
						if choice_button.choice_enabled == 0:
							if OS.is_debug_build() and engine.debug_prints == true:
								print("[DEBUG] Choice_List: Timer '%s' skipped disabled choice '%s/%s'." % [timer_name, cat_name, choice_name])
						elif choice_button.has_method("_choice_selected"):
							choice_button.call_deferred("_choice_selected")
							if OS.is_debug_build() and engine.debug_prints == true:
								print("[DEBUG] Choice_List: Timer '%s' called _choice_selected() for '%s/%s'." % [timer_name, cat_name, choice_name])
						else:
							printerr("Choice_List: Choice node '%s/%s' missing _choice_selected()." % [cat_name, choice_name])
					else:
						printerr("Choice_List: Could not find choice button '%s' in category '%s'." % [choice_name, cat_name])
				else:
					printerr("Choice_List: Could not find category '%s' for timer-triggered choice." % cat_name)
		else:
			printerr("Choice_List: Timer '%s' 'Timer_Choices' must follow format '[Category, Choice]'." % timer_name)

	#@ Step 6 - Apply timer changes and resume timers:
	if OS.is_debug_build() and engine.debug_prints == true:
		print("timer data: " + str(timer_data))

	CandyChoices.get_shared().apply_timers(engine, self, menu, timers_array, "after timeout")

	return "Wait"
