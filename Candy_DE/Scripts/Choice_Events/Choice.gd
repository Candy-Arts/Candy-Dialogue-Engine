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


func handle(engine: CandyEngine, menu: Node, depth: int, category: Variant, choice: Variant, sender: Object, ctx: CandyContext) -> String:
	var category_name: String = category
	var choice_name: String = choice

	#% Ignore malformed events:
	if sender == null or not is_instance_valid(sender):
		printerr("Choice_List: 'Choice' event received with no source button - ignored.")
		return "Wait"

	if sender.get("choice_active") == 0:
		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] Choice_List: Ignored inactive choice '%s' (category '%s')." % [choice_name, category_name])
		return "Wait"

	#@ Step 1 - Pause timers:
	var timers_array: Array = engine.choice_list_data[depth].get("Timers", [])
	CandyChoices.get_shared().pause_timers(engine, self, menu, timers_array)

	#@ Step 2 - Record event:
	engine.choice_lists[depth]["Last Choice"] = { "Choice": [category_name, choice_name, sender] }
	if OS.is_debug_build() and engine.debug_prints == true:
		print("[DEBUG] Choice_List: Registered selection '%s' in category '%s' (depth %s)" % [choice_name, category_name, str(depth)])

	#@ Step 3 - Fetch live category data:
	var categories_array: Array = engine.choice_list_data[depth].get("Categories", [])
	var cat_data: Dictionary = {}
	for entry in categories_array:
		if entry.has(category_name):
			cat_data = entry[category_name]
			break

	if cat_data.size() == 0:
		printerr("Choice_List: Missing data for category '%s'." % category_name)
		await CandyChoices.get_shared().close_menu(engine, self, depth, menu)
		return "Continue"

	#@ Step 4 - Find choice data:
	var choice_data: Dictionary = {}
	if cat_data.has("Choices"):
		for choice_entry in cat_data["Choices"]:
			if choice_entry.has(choice_name):
				choice_data = choice_entry[choice_name]
				break

	if choice_data.size() == 0:
		printerr("Choice_List: Missing data for selected choice '%s' (category '%s')."
			% [choice_name, category_name])
		await CandyChoices.get_shared().close_menu(engine, self, depth, menu)
		return "Continue"

	#. Hook call:
	#? Before navigation and the Finish transition.
	await candy_de.run_hook("x_choice_selected", {"caller": engine, "menu": menu, "category": category_name,
		"choice": choice_name, "button": sender, "choice_data": choice_data},
		CandyCustomData.levels([engine.choice_list_data[depth], cat_data, choice_data]))

	#% Dialogue stopped during the hook:
	if engine.killswitch == true:
		return "END"

	#@ Step 5 - Fetch live Finish data:
	var finish_data: Dictionary = {}
	if cat_data.has("Choices"):
		for choice_entry in cat_data["Choices"]:
			if choice_entry.has(choice_name):
				finish_data = choice_entry[choice_name].get("Finish", {})
				break

	var convo: String = str(engine.candy_ref.resolve_value(engine, engine, finish_data.get("Conversation", ""), candy_de.candy_ref_symbol)).strip_edges()
	var block: String = str(engine.candy_ref.resolve_value(engine, engine, finish_data.get("Block", ""), candy_de.candy_ref_symbol)).strip_edges()
	var line_ref: String = str(engine.candy_ref.resolve_value(engine, engine, finish_data.get("Line", ""), candy_de.candy_ref_symbol)).strip_edges()

	#@ Step 6 - Navigation:
	var nav_target: String = str(engine.candy_ref.resolve_value(engine, engine, choice_data.get("Navigate", ""), candy_de.candy_ref_symbol)).strip_edges()
	if nav_target != "":
		var cat_dict = engine.choice_lists.get(depth, {}).get("Category Nodes", {})
		if cat_dict.has(category_name):
			var current_cat = cat_dict[category_name]
			if current_cat:
				current_cat["Node"].visible = false
		if cat_dict.has(nav_target):
			var target_cat = cat_dict[nav_target]
			if target_cat:
				target_cat["Node"].visible = true
		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] Choice_List: Navigated from '%s' → '%s'." % [category_name, nav_target])

		#Ł Apply the new category's Mouse:
		var nav_cat_data: Dictionary = {}
		for nav_category_entry in engine.choice_list_data[depth].get("Categories", []):
			if nav_category_entry.has(nav_target):
				nav_cat_data = nav_category_entry[nav_target]
				break
		CandyChoices.get_shared().apply_category_mouse(engine, self, engine.choice_list_data[depth], nav_cat_data, "after navigation to '%s'" % nav_target)

	#@ Step 7 - Resolve Finish type (some need no target):
	var trans_type: String = str(engine.candy_ref.resolve_value(engine, engine, finish_data.get("Type", "Bridge"), candy_de.candy_ref_symbol)).to_lower()
	var has_target: bool = (convo != "" or block != "" or line_ref != "")
	var needs_no_target: bool = trans_type in ["return", "end", "close"]

	#¦ 1. No Finish transition → resume timers:
	if not has_target and not needs_no_target:
		CandyChoices.get_shared().apply_timers(engine, self, menu, timers_array, "after choice")

	#¦ 2. Finish transition:
	if has_target or needs_no_target:

		match trans_type:
			"continue":
				var fake_line := CandyFlow.get_shared().transition_line(engine, self, "Bridge", convo, block, line_ref)
				var hide_menu: bool = CandyChoices.get_shared().transition_hides_menu(engine, self, engine.choice_list_data[depth], cat_data, finish_data,
					"Choice_List: choice '%s' (category '%s')" % [choice_name, category_name])
				CandyChoices.get_shared().set_shield(engine, self, menu, true)		#/ Block the menu until the Bridge returns
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

				#% Menu stays open → apply timer changes and resume timers:
				CandyChoices.get_shared().apply_timers(engine, self, menu, timers_array, "after Continue")
				return "Wait"

			"bridge", "jump", "return", "end":
				var cmd_to_run := "End"
				match trans_type:
					"bridge":
						cmd_to_run = "Bridge"
					"jump":
						cmd_to_run = "Jump"
					"return":
						cmd_to_run = "Return"
				var fake_line := CandyFlow.get_shared().transition_line(engine, self, cmd_to_run, convo, block, line_ref,
					str(finish_data.get("Levels", "1")))

				#Ł Play the closing animation:
				if not await CandyChoices.get_shared().play_closing(engine, self, depth, menu,
						{"category": category_name, "choice": choice_name, "button": sender, "finish": trans_type}):
					return "END"

				menu.visible = false
				#Ł Keep hidden when nested menus close:
				engine.choice_lists[depth]["Finishing"] = true

				#Ł Run the transition (a Jump frees the menus):
				var feedback = await CandyFlow.get_shared().run_nested_line(engine, self, fake_line, ctx.conversation, ctx.block)

				#Ł Close the menu:
				await CandyChoices.get_shared().close_menu(engine, self, depth, menu)

				if OS.is_debug_build() and engine.debug_prints == true:
					print("[DEBUG] Choice_List: Closed menu after '%s' transition and cleared data (depth ≥ %s)." % [trans_type, str(depth)])

				return feedback

			"close":
				#Ł Play the closing animation:
				if not await CandyChoices.get_shared().play_closing(engine, self, depth, menu,
						{"category": category_name, "choice": choice_name, "button": sender, "finish": trans_type}):
					return "END"

				await CandyChoices.get_shared().close_menu(engine, self, depth, menu)

				if OS.is_debug_build() and engine.debug_prints == true:
					print("[DEBUG] Choice_List: Closed menu after 'Close' directive; cleared data (depth ≥ %s)." % str(depth))

				return "Continue"

			_:
				#% Unknown type → resume timers:
				CandyChoices.get_shared().apply_timers(engine, self, menu, timers_array, "after unknown Finish type")

				if OS.is_debug_build() and engine.debug_prints == true:
					print("[DEBUG] Unknown Finish transition type '%s' in choice '%s' (category '%s')." % [trans_type, choice_name, category_name])

				return "Wait"

	return "Wait"
