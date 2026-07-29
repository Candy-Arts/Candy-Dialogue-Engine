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

	var this_depth = engine.nesting_depth
	engine.choice_list_data[this_depth] = command_value.duplicate(true)

	#@ Step 1 - Visibility:
	var choices_root := CandyUI.get_shared().get_element(engine, self, "choices_path", "Choice_List")
	if choices_root == null:
		CandyChoices.get_shared().clear_depth(engine, self, this_depth)
		return "Continue"

	#Ł Hide older menus:
	await CandyChoices.get_shared().hide_open_menus(engine, self, choices_root)

	#@ Steps 2 to 5 - Run Setups (menu, categories, choices, timers):
	#? Data re-fetched each time: a Setup may change it.
	var feedback := await CandyChoices.get_shared().run_setup(engine, self, engine.choice_list_data[this_depth].get("Setup", {}), "Choice_List.Setup", current_conversation, current_block)
	if feedback in ["END", "Return"]:
		await CandyChoices.get_shared().close_menu(engine, self, this_depth)
		return feedback

	#Ł Categories:
	for category_entry in engine.choice_list_data[this_depth].get("Categories", []):
		for cat_key in category_entry.keys():
			feedback = await CandyChoices.get_shared().run_setup(engine, self, category_entry[cat_key].get("Setup", {}), "Choice_List.Category.Setup ('%s')" % cat_key, current_conversation, current_block)
			if feedback in ["END", "Return"]:
				await CandyChoices.get_shared().close_menu(engine, self, this_depth)
				return feedback

	#Ł Choices:
	for category_entry in engine.choice_list_data[this_depth].get("Categories", []):
		for cat_key in category_entry.keys():
			for choice_entry in category_entry[cat_key].get("Choices", []):
				for choice_key in choice_entry.keys():
					var choice_data: Dictionary = choice_entry[choice_key]

					#% Disabled - Choice_Status runs its Setup when it spawns the button:
					if int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Enabled", 1.0)) == 0:
						continue

					feedback = await CandyChoices.get_shared().run_setup(engine, self, choice_data.get("Setup", {}), "Choice_List.Choice.Setup ('%s')" % choice_key, current_conversation, current_block)
					if feedback in ["END", "Return"]:
						await CandyChoices.get_shared().close_menu(engine, self, this_depth)
						return feedback

	#Ł Timers:
	for timer_entry in engine.choice_list_data[this_depth].get("Timers", []):
		for timer_key in timer_entry.keys():
			feedback = await CandyChoices.get_shared().run_setup(engine, self, timer_entry[timer_key].get("Setup", {}), "Choice_List.Timer.Setup ('%s')" % timer_key, current_conversation, current_block)
			if feedback in ["END", "Return"]:
				await CandyChoices.get_shared().close_menu(engine, self, this_depth)
				return feedback

	#@ Step 6 - Create the menu:
	var parent_node = choices_root

	#Ł Menu scene:
	var full_menu_path: String = CandyUI.get_shared().resolve_scene_path(engine, self, engine.choice_list_data[this_depth].get("Menu_Scene", "Default.tscn"), candy_de.choice_menus_folder)
	if full_menu_path == "":
		full_menu_path = candy_de.choice_menus_folder.path_join("Default.tscn")
		if OS.is_debug_build() and engine.debug_prints == true:
			print("Choice_List: Missing 'Menu_Scene', defaulting to 'Default.tscn'.")

	var menu_scene: String = full_menu_path.get_file()	#/ For messages

	if not CandyMedia.exists(full_menu_path):
		printerr("Choice_List: Invalid or missing menu scene → %s" % full_menu_path)
		await CandyChoices.get_shared().close_menu(engine, self, this_depth)
		return "Continue"

	var menu_scene_res = load(full_menu_path)
	if not (menu_scene_res is PackedScene):
		printerr("Choice_List: Failed to load menu scene at → %s" % full_menu_path)
		await CandyChoices.get_shared().close_menu(engine, self, this_depth)
		return "Continue"

	var menu_node = menu_scene_res.instantiate()
	menu_node.caller = engine
	menu_node.nesting_depth = engine.nesting_depth

	#Ł Title, tags, prompt:
	var menu_title: String		= str(engine.candy_ref.resolve_value(engine, engine, engine.choice_list_data[this_depth].get("Title", ""), candy_de.candy_ref_symbol)).strip_edges()
	var menu_tags: String		= str(engine.candy_ref.resolve_value(engine, engine, engine.choice_list_data[this_depth].get("Tags", ""), candy_de.candy_ref_symbol)).strip_edges()
	var menu_prompt: String		= str(engine.candy_ref.resolve_value(engine, engine, engine.choice_list_data[this_depth].get("Prompt", ""), candy_de.candy_ref_symbol)).strip_edges()

	menu_node.title = menu_title
	menu_node.tags = menu_tags
	menu_node.prompt = menu_prompt

	#Ł Custom Data (categories and buttons add their level):
	var menu_custom_data: Array = CandyCustomData.levels([engine.choice_list_data[this_depth]])

	#Ł Hide older menus again (a Setup's menu may have re-shown one):
	await CandyChoices.get_shared().hide_open_menus(engine, self, parent_node)

	#Ł Add the menu:
	parent_node.add_child(menu_node)

	if menu_node.has_method("setup"):
		await menu_node.setup(menu_custom_data)

	if OS.is_debug_build() and engine.debug_prints == true:
		print("[DEBUG] Choice_List: Loaded main menu scene '%s' from '%s'" % [menu_scene, full_menu_path])

	#Ł Record in choice_lists:
	if not engine.choice_lists.has(engine.nesting_depth):
		engine.choice_lists[engine.nesting_depth] = {}

	engine.choice_lists[engine.nesting_depth]["Menu"] = menu_node
	engine.choice_lists[engine.nesting_depth]["Title"] = menu_title
	engine.choice_lists[engine.nesting_depth]["Tags"] = menu_tags

	if OS.is_debug_build() and engine.debug_prints == true:
		print("[DEBUG] Choice_List: Registered menu (Title='%s', Tags='%s') for depth %s" % [menu_title, menu_tags, str(engine.nesting_depth)])

	#@ Step 7 - Create categories:
	var main_category = str(engine.candy_ref.resolve_value(engine, engine, engine.choice_list_data[this_depth].get("Main", ""), candy_de.candy_ref_symbol)).strip_edges()

	#Ł No or unknown Main - first category:
	var first_category := ""
	var main_found := false
	for category_entry in engine.choice_list_data[this_depth].get("Categories", []):
		for cat_key in category_entry.keys():
			if first_category == "":
				first_category = str(cat_key)
			if str(cat_key) == main_category:
				main_found = true
	if not main_found:
		if main_category != "":
			push_warning("Choice_List: Main category '%s' not found - using first category '%s'." % [main_category, first_category])
		main_category = first_category
	var general_category_scene: String = CandyUI.get_shared().resolve_scene_path(engine, self, engine.choice_list_data[this_depth].get("Category_Scene", "Default.tscn"), candy_de.choice_categories_folder)
	if general_category_scene == "":
		general_category_scene = candy_de.choice_categories_folder.path_join("Default.tscn")

	var category_list: Node = menu_node.category_list
	if category_list == null:
		if OS.is_debug_build() and engine.debug_prints == true:
			print("Choice_List: Menu scene is missing a 'Categories' node.")
		await CandyChoices.get_shared().close_menu(engine, self, this_depth, menu_node)
		return "Continue"

	#Ł Category Nodes entry:
	if not engine.choice_lists.has(engine.nesting_depth):
		engine.choice_lists[engine.nesting_depth] = {}
	if not engine.choice_lists[engine.nesting_depth].has("Category Nodes"):
		engine.choice_lists[engine.nesting_depth]["Category Nodes"] = {}

	#Ł Re-fetch live data:
	var categories_array: Array = engine.choice_list_data[this_depth].get("Categories", [])

	for category_entry in categories_array:
		for cat_key in category_entry.keys():
			var cat_data: Dictionary = category_entry[cat_key]
			var cat_scene_name: String = CandyUI.get_shared().resolve_scene_path(engine, self, cat_data.get("Category_Scene", ""), candy_de.choice_categories_folder)

			if cat_scene_name == "":
				cat_scene_name = general_category_scene

			if cat_scene_name == "" or not CandyMedia.exists(cat_scene_name):
				printerr("Choice_List: Invalid category scene → %s" % cat_scene_name)
				continue

			var cat_scene = load(cat_scene_name)
			if not (cat_scene is PackedScene):
				printerr("Choice_List: Failed to load category scene → %s" % cat_scene_name)
				continue

			var category_instance = cat_scene.instantiate()

			var cat_tags: String = str(engine.candy_ref.resolve_value(engine, engine, cat_data.get("Tags", ""), candy_de.candy_ref_symbol)).strip_edges()

			category_instance.parent_menu = menu_node
			category_instance.caller = engine

			category_instance.general_title = str(engine.candy_ref.resolve_value(engine, engine, engine.choice_list_data[this_depth].get("Title", ""), candy_de.candy_ref_symbol))
			category_instance.category_title = str(engine.candy_ref.resolve_value(engine, engine, cat_data.get("Title", ""), candy_de.candy_ref_symbol))
			category_instance.general_prompt = str(engine.candy_ref.resolve_value(engine, engine, engine.choice_list_data[this_depth].get("Prompt", ""), candy_de.candy_ref_symbol))
			category_instance.category_prompt = str(engine.candy_ref.resolve_value(engine, engine, cat_data.get("Prompt", ""), candy_de.candy_ref_symbol))
			category_instance.tags = cat_tags

			category_instance.name = cat_key
			if str(category_instance.name) != str(cat_key):
				printerr("Choice_List: category name '%s' contains characters Godot doesn't allow in node names (. : @ / %% \") - it became '%s' and can't be found. Rename the category." % [cat_key, category_instance.name])

			category_list.add_child(category_instance)

			if category_instance.has_method("setup"):
				await category_instance.setup(CandyCustomData.extend(menu_custom_data, cat_data))

			if cat_key != main_category:
				category_instance.visible = false

			#Ł Record node and tags:
			engine.choice_lists[engine.nesting_depth]["Category Nodes"][cat_key] = {
				"Node": category_instance,
				"Tags": cat_tags
			}

			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Choice_List: Spawned category '%s' (Tags='%s') under menu (depth %s)" % [cat_key, cat_tags, str(engine.nesting_depth)])

	#@ Step 8 - Create buttons for enabled choices:
	var general_button_scene: String = CandyUI.get_shared().resolve_scene_path(engine, self, engine.choice_list_data[this_depth].get("Button_Scene", "Default.tscn"), candy_de.choice_buttons_folder)
	if general_button_scene == "":
		general_button_scene = candy_de.choice_buttons_folder.path_join("Default.tscn")

	#Ł Re-fetch live data:
	categories_array = engine.choice_list_data[this_depth].get("Categories", [])

	for category_entry in categories_array:
		for cat_key in category_entry.keys():
			var cat_data: Dictionary = category_entry[cat_key]
			var category_instance = menu_node.category_list.get_node_or_null(cat_key)
			if category_instance == null:
				continue
			var button_list = category_instance.button_list
			if button_list == null:
				printerr("Choice_List: category '%s' has no button_list node." % cat_key)
				continue

			var category_button_scene: String = CandyUI.get_shared().resolve_scene_path(engine, self, cat_data.get("Button_Scene", ""), candy_de.choice_buttons_folder)
			if category_button_scene == "":
				category_button_scene = general_button_scene

			if not cat_data.has("Choices"):
				continue

			var category_custom_data: Array = CandyCustomData.extend(menu_custom_data, cat_data)

			var choices_array: Array = cat_data.get("Choices", [])
			for choice_entry in choices_array:
				for choice_key in choice_entry.keys():
					var choice_data: Dictionary = choice_entry[choice_key]

					#% Disabled:
					if int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Enabled", 1.0)) == 0:
						continue

					var final_scene_path: String = CandyUI.get_shared().resolve_scene_path(engine, self, choice_data.get("Button_Scene", ""), candy_de.choice_buttons_folder)
					if final_scene_path == "":
						final_scene_path = category_button_scene

					if final_scene_path == "" or not CandyMedia.exists(final_scene_path):
						printerr("Choice_List: Invalid button scene for choice '%s' in category '%s' → %s"
							% [choice_key, cat_key, final_scene_path])
						continue

					var scene_res = load(final_scene_path)
					if not (scene_res is PackedScene):
						printerr("Choice_List: Failed to load button scene at → %s" % final_scene_path)
						continue

					var button_instance = scene_res.instantiate()
					button_instance.name = choice_key
					if str(button_instance.name) != str(choice_key):
						printerr("Choice_List: choice name '%s' contains characters Godot doesn't allow in node names (. : @ / %% \") - it became '%s' and can't be found. Rename the choice." % [choice_key, button_instance.name])
					button_instance.parent_category = category_instance
					button_instance.parent_menu = menu_node
					button_instance.caller = engine
					button_instance.choice_name = choice_key
					button_instance.category_name = cat_key

					var choice_label = str(engine.candy_ref.resolve_value(engine, engine, choice_data.get("Label", ""), candy_de.candy_ref_symbol))
					if choice_label == "":
						choice_label = choice_key
					button_instance.label = choice_label
					button_instance.tooltip = str(engine.candy_ref.resolve_value(engine, engine, choice_data.get("Tooltip", ""), candy_de.candy_ref_symbol))
					button_instance.tags = str(engine.candy_ref.resolve_value(engine, engine, choice_data.get("Tags", ""), candy_de.candy_ref_symbol)).strip_edges()

					button_instance.choice_enabled = int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Enabled", 1.0))
					button_instance.choice_active = int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Active", 1.0))
					button_instance.choice_invisible = int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Invisible", 0.0))

					button_list.add_child(button_instance)
					if button_instance.has_method("setup"):
						await button_instance.setup(CandyCustomData.extend(category_custom_data, choice_data))

					if OS.is_debug_build() and engine.debug_prints == true:
						print("[DEBUG] Choice_List: Spawned button '%s' under category '%s' using '%s'" % [choice_key, cat_key, final_scene_path])

	#@ Step 9 - Main category's Mouse_Mode:
	#Ł Store mouse mode for closing:
	if not engine.choice_lists.has(this_depth):
		engine.choice_lists[this_depth] = {}
	engine.choice_lists[this_depth]["Mouse Before"] = Input.get_mouse_mode()

	#Ł Apply (live data):
	var main_cat_data: Dictionary = {}
	for category_entry in engine.choice_list_data[this_depth].get("Categories", []):
		if category_entry.has(main_category):
			main_cat_data = category_entry[main_category]
			break
	CandyChoices.get_shared().apply_category_mouse(engine, self, engine.choice_list_data[this_depth], main_cat_data, "on menu open (main category '%s')" % main_category)

	#@ Step 10 - Create timers:
	var timers_array: Array = engine.choice_list_data[this_depth].get("Timers", [])

	#Ł Timer container (may be unassigned):
	var timer_list: Node = null
	if "timer_list" in menu_node:
		timer_list = menu_node.timer_list

	if not timers_array.is_empty() and timer_list == null:
		printerr("Choice_List: Menu scene '%s' has no timer_list node - %d timer(s) skipped." % [menu_scene, timers_array.size()])
		timers_array = []

	if timers_array.is_empty():
		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] Choice_List: No timers found at depth %s." % str(this_depth))
	else:
		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] Choice_List: Initializing %d timer(s) at depth %s." % [timers_array.size(), str(this_depth)])

	for timer_entry in timers_array:
		#? { "Timer_1": {...} }
		for timer_key in timer_entry.keys():
			var timer_data: Dictionary = timer_entry[timer_key]
			if timer_data.is_empty():
				continue

			#Ł Parameters:
			var time_val: float = CandyChoices.get_shared().state_num(engine, self, timer_data, "Time", 0.0)
			var auto_mode: String = str(engine.candy_ref.resolve_value(engine, engine, timer_data.get("Auto", "Start"), candy_de.candy_ref_symbol)).strip_edges()
			var loop_val: int = int(CandyChoices.get_shared().state_num(engine, self, timer_data, "Loops", 1.0))
			var tags: String = str(engine.candy_ref.resolve_value(engine, engine, timer_data.get("Tags", ""), candy_de.candy_ref_symbol)).strip_edges()

			#Ł Normalize Loops, for Choice_Events/Timer.gd:
			#? -1 = infinite, 1+ = times the timer fires.
			if loop_val < -1:
				printerr("Choice_List: Timer '%s' - invalid Loops value %s, treated as 1." % [timer_key, str(loop_val)])
				loop_val = 1
			elif loop_val == 0:
				loop_val = 1
			timer_data["Loops"] = loop_val

			#Ł Reset Status (not "Pending Status", which a Setup's Timer_Status may have set):
			timer_data["Status"] = "Hold"

			#Ł Create the Timer:
			var timer_node: Timer = Timer.new()
			timer_node.name = timer_key
			if str(timer_node.name) != str(timer_key):
				printerr("Choice_List: timer name '%s' contains characters Godot doesn't allow in node names (. : @ / %% \") - it became '%s' and can't be found. Rename the timer." % [timer_key, timer_node.name])
			timer_node.wait_time = CandyChoices.get_shared().safe_wait_time(engine, self, time_val, "Choice_List timer '%s'" % timer_key)
			timer_node.one_shot = true
			timer_node.autostart = false
			timer_list.add_child(timer_node)

			#Ł timeout →menu's _on_timer_timeout():
			timer_node.timeout.connect(
				func(key = timer_key):
					if menu_node.has_method("_on_timer_timeout"):
						menu_node._on_timer_timeout(key)
					else:
						printerr("Choice_List: Menu missing _on_timer_timeout() while running timer '%s'." % timer_key)
			)

			#% Auto "Start" - queue the start, unless a Setup's Timer_Status set one:
			#? Started just before Step 12, so none expires unheard.
			if auto_mode == "Start" and not timer_data.has("Pending Status"):
				timer_data["Pending Status"] = "Start/Resume"
			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Choice_List: Created timer '%s' (Auto=%s, pending='%s', time=%.2f, loop=%s, tags='%s')." % [timer_key, auto_mode, str(timer_data.get("Pending Status", "")), time_val, str(loop_val), tags])

	if OS.is_debug_build() and engine.debug_prints == true:
		print("[DEBUG] Choice_List: Finished initializing timers for depth %s." % str(this_depth))

	#@ Step 11 - Hook and timers:
	#. Hook call:
	await candy_de.run_node_hook(menu_node, "x_initialization_finished",
		{"caller": engine, "node": menu_node}, menu_custom_data)

	#% Killswitch or suspension during setup (nothing listened yet):
	if engine.killswitch == true:
		await CandyChoices.get_shared().close_menu(engine, self, this_depth, menu_node)
		return "END"

	if engine.dialogue_suspended == true:
		await engine._await_suspension()
		if engine.killswitch == true:
			await CandyChoices.get_shared().close_menu(engine, self, this_depth, menu_node)
			return "END"

	#Ł Start timers:
	CandyChoices.get_shared().apply_timers(engine, self, menu_node, engine.choice_list_data[this_depth].get("Timers", []), "on menu ready")


	#@ Step 12 - Run each event's Choice_Events script:
	return await _await_choice_events(engine, menu_node, this_depth, ctx)


#* Step 12 - Run choice_list_event scripts:
#! Keep in its own function: inside execute(), Godot 4.6 crashed after an event script awaited.
func _await_choice_events(engine: CandyEngine, menu_node: Node, this_depth: int, ctx: CandyContext) -> String:
	var sig
	var outcome := "Wait"
	while true:
		sig = await engine.choice_list_event

		#% Killswitch:
		if engine.killswitch == true:
			return "END"

		#% Other depth:
		if sig[0] != this_depth:
			continue

		var event_type: String = str(sig[1]).to_lower()

		#% Unknown event:
		if not engine.choice_event_registry.has(event_type):
			push_warning("Candy DE: Choice_List received the unknown event '%s' - no script for it in the Choice_Events folder. Ignored." % event_type)
			continue

		var event_script: CandyChoiceEvent = engine.choice_event_registry[event_type]
		@warning_ignore("redundant_await")
		outcome = await event_script.handle(engine, menu_node, this_depth, sig[2], sig[3], sig[4], ctx)

		if outcome == "Continue" or outcome == "Return" or outcome == "END":
			return outcome

		#% Killswitch raised during the event:
		if engine.killswitch == true:
			return "END"

		if outcome == "Wait":
			continue

		push_warning("Candy DE: Choice_List event '%s' returned '%s' - expected \"Wait\", \"Continue\", \"Return\" or \"END\". Closing the menu." % [event_type, outcome])
		break

	await CandyChoices.get_shared().close_menu(engine, self, this_depth, menu_node)
	return "Continue"
