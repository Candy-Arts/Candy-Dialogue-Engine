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

	var choice_mode: String			= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Choice_Mode", "Last"), candy_de.candy_ref_symbol)).capitalize()
	var choice_tags_raw: String		= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Choice_Tags", ""), candy_de.candy_ref_symbol)).strip_edges()
	var category_mode: String		= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Category_Mode", "Last"), candy_de.candy_ref_symbol)).capitalize()
	var category_tags_raw: String	= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Category_Tags", ""), candy_de.candy_ref_symbol)).strip_edges()
	var menu_mode: String			= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Menu_Mode", "Last"), candy_de.candy_ref_symbol)).capitalize()
	var menu_tags_raw: String		= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Menu_Tags", ""), candy_de.candy_ref_symbol)).strip_edges()

	var enable_mode: String			= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Enable", "-"), candy_de.candy_ref_symbol)).capitalize()
	var active_mode: String			= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Activate", "-"), candy_de.candy_ref_symbol)).capitalize()
	var show_mode: String			= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Show", "-"), candy_de.candy_ref_symbol)).capitalize()
	var label_val: String			= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Label", ""), candy_de.candy_ref_symbol)).strip_edges()
	var tooltip_val: String			= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Tooltip", ""), candy_de.candy_ref_symbol)).strip_edges()

	#@ Step 1 - Split tags:
	var choice_tags = choice_tags_raw.split(",", false)
	var category_tags = category_tags_raw.split(",", false)
	var menu_tags = menu_tags_raw.split(",", false)

	#@ Step 2 - Empty = "-":
	if enable_mode == "":
		enable_mode = "-"
	if active_mode == "":
		active_mode = "-"
	if show_mode == "":
		show_mode = "-"

	#% Unknown filter modes change nothing:
	var filter_modes := ["Last", "Tags", "All"]
	var filters := {"Menu_Mode": menu_mode, "Category_Mode": category_mode, "Choice_Mode": choice_mode}
	for filter_key in filters.keys():
		if not (filters[filter_key] in filter_modes):
			push_warning("Candy DE: Choice_Status - unknown %s '%s' (expected \"Last\", \"Tags\" or \"All\"). Nothing was changed." % [filter_key, filters[filter_key]])
			return "Continue"

	#% Unknown change values:
	if not (enable_mode in ["Enable", "Disable", "Toggle", "-"]):
		push_warning("Candy DE: Choice_Status - unknown Enable '%s' (expected \"Enable\", \"Disable\", \"Toggle\" or \"-\"). Left unchanged." % enable_mode)
		enable_mode = "-"
	if not (active_mode in ["Activate", "Deactivate", "Toggle", "-"]):
		push_warning("Candy DE: Choice_Status - unknown Activate '%s' (expected \"Activate\", \"Deactivate\", \"Toggle\" or \"-\"). Left unchanged." % active_mode)
		active_mode = "-"
	if not (show_mode in ["Show", "Hide", "Toggle", "-"]):
		push_warning("Candy DE: Choice_Status - unknown Show '%s' (expected \"Show\", \"Hide\", \"Toggle\" or \"-\"). Left unchanged." % show_mode)
		show_mode = "-"

	#@ Step 3 - Target depths:
	var target_depths: Array = []

	if OS.is_debug_build() and engine.debug_prints == true:
		print("Choice_Status started...")
	if menu_mode == "Last":
		if engine.choice_list_data.size() > 0:
			var max_depth = engine.choice_list_data.keys().max()
			target_depths = [max_depth]
	elif menu_mode == "Tags":
		for depth in engine.choice_list_data.keys():
			var tags = engine.choice_lists.get(depth, {}).get("Tags", engine.choice_list_data.get(depth, {}).get("Tags", ""))
			for tag in menu_tags:
				if CandyChoices.get_shared().has_tag(engine, self, tags, tag):
					target_depths.append(depth)
					break
	elif menu_mode == "All":
		target_depths = engine.choice_list_data.keys()

	#@ Step 4 - Each target menu:
	for depth in target_depths:
		var cat_nodes: Dictionary = engine.choice_lists.get(depth, {}).get("Category Nodes", {})
		var categories_array: Array = engine.choice_list_data.get(depth, {}).get("Categories", [])
		if categories_array.is_empty():
			continue

		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] choice_list_data keys: %s" % str(engine.choice_list_data.keys()))
			print("[DEBUG] depth value: %s" % str(depth))
			print("[DEBUG] choice_list_data has depth: %s" % str(engine.choice_list_data.has(depth)))
		if engine.choice_list_data.has(depth):
			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Categories for depth: %s" % str(engine.choice_list_data[depth].get("Categories", "MISSING")))

		for category_entry in categories_array:
			for cat_key in category_entry.keys():
				var cat_data: Dictionary = category_entry[cat_key]
				var cat_tags: String = str(engine.candy_ref.resolve_value(engine, engine, cat_data.get("Tags", ""), candy_de.candy_ref_symbol)).strip_edges()
				var cat_node = cat_nodes.get(cat_key, {}).get("Node", null)

				#Ł Category filter:
				var include_category := true
				match category_mode:
					"Last":
						if not engine.choice_lists.has(depth) or not engine.choice_lists[depth].has("Last Choice"):
							include_category = false
						else:
							var last_cat = engine.choice_lists[depth]["Last Choice"]["Choice"][0]
							include_category = (last_cat == cat_key)
					"Tags":
						include_category = false
						for tag in category_tags:
							if CandyChoices.get_shared().has_tag(engine, self, cat_tags, tag):
								include_category = true
								break
					"All":
						if category_tags_raw != "":
							for tag in category_tags:
								if CandyChoices.get_shared().has_tag(engine, self, cat_tags, tag):
									include_category = false
									break
				if not include_category:
					continue

				#Ł Live choices:
				var choices_array: Array = cat_data.get("Choices", [])

				if OS.is_debug_build() and engine.debug_prints == true:
					print("[DEBUG] cat_data for '%s': %s" % [cat_key, str(cat_data)])
					print("[DEBUG] choices_array size: %d" % choices_array.size())

				for choice_entry in choices_array:
					for choice_key in choice_entry.keys():
						var choice_data: Dictionary = choice_entry[choice_key]
						var choice_tags_str: String = str(engine.candy_ref.resolve_value(engine, engine, choice_data.get("Tags", ""), candy_de.candy_ref_symbol)).strip_edges()
						if OS.is_debug_build() and engine.debug_prints == true:
							print("[DEBUG] Choice_Status: Checking choice '%s'" % choice_key)

						#Ł Choice filter:
						var include_choice := true
						match choice_mode:
							"Last":
								if not engine.choice_lists.has(depth) or not engine.choice_lists[depth].has("Last Choice"):
									include_choice = false
								else:
									var last_choice = engine.choice_lists[depth]["Last Choice"]["Choice"][1]
									include_choice = (last_choice == choice_key)
							"Tags":
								include_choice = false
								for tag in choice_tags:
									if CandyChoices.get_shared().has_tag(engine, self, choice_tags_str, tag):
										include_choice = true
										break
							"All":
								if choice_tags_raw != "":
									for tag in choice_tags:
										if CandyChoices.get_shared().has_tag(engine, self, choice_tags_str, tag):
											include_choice = false
											break

						if OS.is_debug_build() and engine.debug_prints == true:
							print("[DEBUG] Choice_Status: include_choice=%s for '%s'" % [str(include_choice), choice_key])

						if not include_choice:
							continue

						#Ł Default missing fields:
						if not choice_data.has("Enabled"):
							choice_data["Enabled"] = "1"
						if not choice_data.has("Active"):
							choice_data["Active"] = "1"
						if not choice_data.has("Invisible"):
							choice_data["Invisible"] = "0"

						#Ł Find the button:
						var button_list = null
						var button_node = null
						if cat_node != null and is_instance_valid(cat_node):
							button_list = cat_node.button_list
							if button_list != null and button_list.has_node(choice_key):
								button_node = button_list.get_node_or_null(choice_key)

						#Ł Read the current state:
						#? From the button once built: the data may hold a reference that has changed since.
						var is_enabled: int
						var is_active: int
						var is_invisible: int

						#¦ 1. Button → enabled:
						if button_node != null:
							is_enabled = 1
							is_active = int(button_node.choice_active)
							is_invisible = int(button_node.choice_invisible)

						#¦ 2. Category without the button → disabled:
						elif button_list != null:
							is_enabled = 0
							is_active = int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Active", 1.0))
							is_invisible = int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Invisible", 0.0))

						#¦ 3. Menu not built yet (e.g. in a Setup) → from the data:
						else:
							is_enabled = int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Enabled", 1.0))
							is_active = int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Active", 1.0))
							is_invisible = int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Invisible", 0.0))

						#Ł Already matching → "-":
						var effective_enable_mode := enable_mode
						var effective_active_mode := active_mode
						var effective_show_mode := show_mode

						match effective_enable_mode:
							"Enable":
								if is_enabled == 1:
									effective_enable_mode = "-"
							"Disable":
								if is_enabled == 0:
									effective_enable_mode = "-"
							_:
								pass

						match effective_active_mode:
							"Activate":
								if is_active == 1:
									effective_active_mode = "-"
							"Deactivate":
								if is_active == 0:
									effective_active_mode = "-"
							_:
								pass

						match effective_show_mode:
							"Show":
								if is_invisible == 0:
									effective_show_mode = "-"
							"Hide":
								if is_invisible == 1:
									effective_show_mode = "-"
							_:
								pass

						if OS.is_debug_build() and engine.debug_prints == true:
							print("[DEBUG] Choice_Status: effective_show_mode='%s' for '%s'" % [effective_show_mode, choice_key])

						#Ł Apply:
						#? Stores a literal - a reference stops being tracked.
						match effective_enable_mode:
							"Enable":
								choice_data["Enabled"] = "1"
								is_enabled = 1
							"Disable":
								choice_data["Enabled"] = "0"
								is_enabled = 0
							"Toggle":
								if is_enabled == 1:
									is_enabled = 0
								else:
									is_enabled = 1
								choice_data["Enabled"] = str(is_enabled)
							"-":
								pass

						match effective_active_mode:
							"Activate":
								choice_data["Active"] = "1"
								is_active = 1
							"Deactivate":
								choice_data["Active"] = "0"
								is_active = 0
							"Toggle":
								if is_active == 1:
									is_active = 0
								else:
									is_active = 1
								choice_data["Active"] = str(is_active)
							"-":
								pass

						match effective_show_mode:
							"Show":
								choice_data["Invisible"] = "0"
								is_invisible = 0
							"Hide":
								choice_data["Invisible"] = "1"
								is_invisible = 1
							"Toggle":
								if is_invisible == 1:
									is_invisible = 0
								else:
									is_invisible = 1
								choice_data["Invisible"] = str(is_invisible)
							"-":
								pass

						if OS.is_debug_build() and engine.debug_prints == true:
							print("[DEBUG] Choice_Status: choice_data after apply = %s" % str(choice_data))

						#Ł Label and tooltip:
						if label_val != "":
							choice_data["Label"] = label_val
						if tooltip_val != "":
							choice_data["Tooltip"] = tooltip_val

						#Ł Update the button:
						if OS.is_debug_build() and engine.debug_prints == true:
							print("[DEBUG] Choice_Status: cat_node=%s, button=%s" % [str(cat_node), str(button_node)])

						if cat_node:
							#¦ 1. Button exists:
							if button_list and button_list.has_node(choice_key):
								button_node = button_list.get_node_or_null(choice_key)
								if button_node:
									var old_label = button_node.label
									var old_tooltip = button_node.tooltip

									#Ł Sync state:
									button_node.choice_enabled = is_enabled
									button_node.choice_active = is_active
									button_node.choice_invisible = is_invisible
									var new_label = str(engine.candy_ref.resolve_value(engine, engine, choice_data.get("Label", ""), candy_de.candy_ref_symbol))
									if new_label == "":
										new_label = choice_key
									button_node.label = new_label
									button_node.tooltip = str(engine.candy_ref.resolve_value(engine, engine, choice_data.get("Tooltip", ""), candy_de.candy_ref_symbol))

									#¦ 1. Disabled - delete:
									if effective_enable_mode == "Disable" or (effective_enable_mode == "Toggle" and is_enabled == 0):
										await button_node._toggle_enabled()
										button_node.queue_free()
										await engine.get_tree().process_frame
										if OS.is_debug_build() and engine.debug_prints == true:
											print("[DEBUG] Choice_Status: Deleted choice button for '%s' in category '%s' (depth %s)" % [choice_key, cat_key, str(depth)])

									#¦ 2. Else update:
									else:
										if effective_active_mode != "-":						#/ Don't do this if Active hasn't changed
											await button_node._toggle_active()
										if effective_show_mode != "-":							#/ Don't do this if Invisible hasn't changed
											await button_node._toggle_invisible()

										if label_val != "" and label_val != old_label:			#/ Don't do this if Label hasn't changed
											await button_node._set_label()
										if tooltip_val != "" and tooltip_val != old_tooltip:	#/ Don't do this if Tooltip hasn't changed
											await button_node._set_tooltip()
										if OS.is_debug_build() and engine.debug_prints == true:
											print("[DEBUG] Choice_Status: Updated choice '%s' in category '%s' (depth %s)" % [choice_key, cat_key, str(depth)])

							#¦ 2. No button - create one:
							else:
								if effective_enable_mode == "Enable" or (effective_enable_mode == "Toggle" and is_enabled == 1):
									#Ł Run the choice's Setup:
									var feedback := await CandyChoices.get_shared().run_setup(engine, self, choice_data.get("Setup", {}), "Choice_Status.Setup ('%s')" % choice_key, current_conversation, current_block)
									if feedback in ["END", "Return"]:
										return feedback

									#Ł Re-fetch live data (Setup may change it):
									choice_data = {}
									for entry in engine.choice_list_data[depth].get("Categories", []):
										if entry.has(cat_key):
											for choice_entry_3 in entry[cat_key].get("Choices", []):
												if choice_entry_3.has(choice_key):
													choice_data = choice_entry_3[choice_key]
											break

									#Ł Re-read the state:
									is_enabled = int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Enabled", 0.0))
									is_active = int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Active", 1.0))
									is_invisible = int(CandyChoices.get_shared().state_num(engine, self, choice_data, "Invisible", 0.0))

									#% Disabled during Setup:
									if is_enabled == 0:
										if OS.is_debug_build() and engine.debug_prints == true:
											print("[DEBUG] Choice_Status: Spawn aborted for '%s' (disabled during Setup)." % choice_key)
										continue

									#Ł Spawn the button (as Choice_List Step 8):
									if button_list and button_list.has_node(choice_key):
										button_node = button_list.get_node_or_null(choice_key)
										if button_node:
											if OS.is_debug_build() and engine.debug_prints == true:
												print("[DEBUG] Choice_Status: Spawn skipped for '%s' (already exists after Setup)." % choice_key)
										else:
											button_node = null

									if button_node == null:
										var category_instance = cat_node
										if category_instance == null:
											continue
										if button_list == null:
											continue

										#Ł Button scene (choice > category > general):
										var general_button_scene: String = CandyUI.get_shared().resolve_scene_path(engine, self, engine.choice_list_data[depth].get("Button_Scene", "Default.tscn"), candy_de.choice_buttons_folder)
										if general_button_scene == "":
											general_button_scene = candy_de.choice_buttons_folder.path_join("Default.tscn")

										var category_data: Dictionary = {}
										for entry in engine.choice_list_data[depth].get("Categories", []):
											if entry.has(cat_key):
												category_data = entry[cat_key]
												break

										var category_button_scene: String = CandyUI.get_shared().resolve_scene_path(engine, self, category_data.get("Button_Scene", ""), candy_de.choice_buttons_folder)
										if category_button_scene == "":
											category_button_scene = general_button_scene

										var final_scene_path: String = CandyUI.get_shared().resolve_scene_path(engine, self, choice_data.get("Button_Scene", ""), candy_de.choice_buttons_folder)
										if final_scene_path == "":
											final_scene_path = category_button_scene

										if final_scene_path == "" or not CandyMedia.exists(final_scene_path):
											printerr("Choice_Status: Invalid button scene for choice '%s' → %s"
												% [choice_key, final_scene_path])
											continue

										var scene_res = load(final_scene_path)
										if not (scene_res is PackedScene):
											printerr("Choice_Status: Failed to load button scene at → %s" % final_scene_path)
											continue

										var button_instance = scene_res.instantiate()
										button_instance.name = choice_key
										if str(button_instance.name) != str(choice_key):
											printerr("Choice_Status: choice name '%s' contains characters Godot doesn't allow in node names (. : @ / %% \") - it became '%s' and can't be found. Rename the choice." % [choice_key, button_instance.name])
										button_instance.parent_category = category_instance
										button_instance.parent_menu = engine.choice_lists[depth]["Menu"]
										button_instance.caller = engine
										button_instance.choice_name = choice_key
										button_instance.category_name = cat_key

										var choice_label = str(engine.candy_ref.resolve_value(engine, engine, choice_data.get("Label", ""), candy_de.candy_ref_symbol))
										if choice_label == "":
											choice_label = choice_key

										button_instance.label = choice_label
										button_instance.tooltip = str(engine.candy_ref.resolve_value(engine, engine, choice_data.get("Tooltip", ""), candy_de.candy_ref_symbol))
										button_instance.tags = str(engine.candy_ref.resolve_value(engine, engine, choice_data.get("Tags", ""), candy_de.candy_ref_symbol)).strip_edges()
										button_instance.choice_enabled = 1
										button_instance.choice_active = is_active
										button_instance.choice_invisible = is_invisible
										button_list.add_child(button_instance)

										#+ Uncomment to have the button ready before setup():
										#await get_tree().process_frame

										var correct_index := 0
										var found := false
										for ce in choices_array:
											for ck in ce.keys():
												if ck == choice_key:
													found = true
													break
												if button_list.has_node(ck):
													correct_index += 1
											if found:
												break

										button_list.move_child(button_instance, correct_index)
										if button_instance.has_method("setup"):
											#Ł Custom Data of menu, category, choice:
											await button_instance.setup(CandyCustomData.levels([engine.choice_list_data[depth], category_data, choice_data]))

										#Ł Block it if the menu is shielded:
										CandyChoices.get_shared().block_new_button(engine, self, button_instance.parent_menu, button_instance)

										if OS.is_debug_build() and engine.debug_prints == true:
											print("[DEBUG] Choice_Status: Spawned choice '%s' under category '%s' (depth %s)" % [choice_key, cat_key, str(depth)])

	return "Continue"
