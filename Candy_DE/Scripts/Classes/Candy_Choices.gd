#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyChoices
extends RefCounted


#^ Shared instance:
static var _shared: CandyChoices = null

#* Get the shared instance:
static func get_shared() -> CandyChoices:
	if _shared == null:
		_shared = CandyChoices.new()
	return _shared


#? Unused 'caller' parameters:
@warning_ignore_start("unused_parameter")

#* Read a numeric field from stored choice / timer data:
func state_num(source: CandyEngine, caller: Object, data: Dictionary, key: String, fallback: float) -> float:
	if data.is_empty():
		return fallback

	#? Stored data is unresolved - fields may be expressions.
	var resolved = source.candy_ref.resolve_value(source, source, data.get(key, fallback), candy_de.candy_ref_symbol)

	if resolved == null:
		return fallback

	match typeof(resolved):
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
			return float(resolved)
		TYPE_STRING:
			var text: String = resolved.strip_edges()
			if text.is_valid_float() or text.is_valid_int():
				return float(text)

	printerr("state_num(): '%s' could not be read as a number → %s" % [key, str(resolved)])
	return fallback		#/ Unreadable

#* Whether a comma-separated tag list holds a tag (whole entries, any case):
func has_tag(source: CandyEngine, caller: Object, tag_list: Variant, tag: String) -> bool:
	var wanted := tag.strip_edges().to_lower()
	if wanted == "":
		return false

	for entry in str(tag_list).split(",", false):
		if entry.strip_edges().to_lower() == wanted:
			return true
	return false

#* Whether a transition hides its menu (Hide_Menu):
func transition_hides_menu(source: CandyEngine, caller: Object, menu_data: Dictionary, cat_data: Dictionary,
		transition_data: Dictionary, context: String) -> bool:
	#Ł Transition → category → menu:
	var levels: Array = [[transition_data, "transition"], [cat_data, "category"], [menu_data, "menu"]]
	var i := 0
	while i < levels.size():
		var level_data: Dictionary = levels[i][0]
		var raw: Variant = level_data.get("Hide_Menu", "null")
		var value: Variant = source.candy_ref.resolve_value(source, source, raw, candy_de.candy_ref_symbol)

		#% "Menu" - skip the category:
		if i == 0 and typeof(value) == TYPE_STRING and value.strip_edges().to_lower() == "menu":
			i = 2
			continue

		#% "null" passes to the next level:
		if not CandySettings.is_not_set(value):
			var hide_menu: Variant = CandySettings.get_shared().convert_value(source, caller, value, true, "")
			if hide_menu != null:
				return hide_menu
			var expected := "1 or 0"
			if i == 0:
				expected = "1, 0 or Menu"
			printerr(context, ": the %s's 'Hide_Menu' can't be %s - expected %s." % [levels[i][1], var_to_str(raw), expected])
		i += 1
	return false

#* Hide a menu while a transition's lines run:
func hide_for_transition(source: CandyEngine, caller: Object, depth: int, menu_node) -> void:	#/ Untyped: menu_node may already be freed
	if menu_node == null or not is_instance_valid(menu_node) or menu_node.is_queued_for_deletion():
		return
	#Ł Keep close_menu() and Bridge from showing it meanwhile:
	if source.choice_lists.has(depth):
		source.choice_lists[depth]["Transition Hidden"] = true
	if menu_node.has_method("deactivate"):
		await menu_node.deactivate(menu_custom_data(source, caller, depth))
	else:
		menu_node.visible = false

#* Show a menu hidden by hide_for_transition():
func show_after_transition(source: CandyEngine, caller: Object, depth: int, menu_node) -> void:	#/ Untyped: menu_node may already be freed
	if source.choice_lists.has(depth):
		source.choice_lists[depth].erase("Transition Hidden")
	if menu_node == null or not is_instance_valid(menu_node) or menu_node.is_queued_for_deletion():
		return
	if source.killswitch == true:
		return
	if menu_node.has_method("reactivate"):
		await menu_node.reactivate(menu_custom_data(source, caller, depth))
	else:
		menu_node.visible = true

#* Show or hide a choice menu's optional shield node:
func set_shield(source: CandyEngine, caller: Object, menu_node, shown: bool) -> void:	#/ Untyped: menu_node may already be freed (e.g. by Jump)
	if menu_node == null or not is_instance_valid(menu_node):
		return
	var shield = menu_node.get("shield")
	if shield != null and is_instance_valid(shield) and "visible" in shield:
		shield.visible = shown

	#Ł Block keyboard and controller selection too:
	#? The shield only covers the mouse.
	_set_focus_blocked(source, caller, menu_node, shown)

#* Block or restore focus on a menu's choice buttons:
func _set_focus_blocked(source: CandyEngine, caller: Object, menu_node, blocked: bool) -> void:
	if menu_node == null or not is_instance_valid(menu_node):
		return

	#Ł For buttons spawned meanwhile:
	menu_node.set_meta("candy_focus_blocked", blocked)

	var category_list = menu_node.get("category_list")
	if category_list == null or not is_instance_valid(category_list):
		return

	for category in category_list.get_children():
		var button_list = category.get("button_list")
		if button_list == null or not is_instance_valid(button_list):
			continue

		for button in button_list.get_children():
			_set_button_focus_blocked(source, caller, button, blocked)

#* Block a new button if its menu's buttons are blocked:
func block_new_button(source: CandyEngine, caller: Object, menu_node, button: Node) -> void:	#/ Untyped: menu_node may already be freed
	if menu_node == null or not is_instance_valid(menu_node):
		return
	if menu_node.get_meta("candy_focus_blocked", false) == true:
		_set_button_focus_blocked(source, caller, button, true)

#* Block or restore focus on a choice button:
func _set_button_focus_blocked(source: CandyEngine, caller: Object, button: Node, blocked: bool) -> void:
	var focus_node = button.get("choice_button")
	if focus_node == null or not is_instance_valid(focus_node) or not (focus_node is Control):
		return

	if blocked:
		#Ł Keep the button's own focus_mode:
		if not focus_node.has_meta("candy_focus_mode"):
			focus_node.set_meta("candy_focus_mode", focus_node.focus_mode)
		focus_node.release_focus()
		focus_node.focus_mode = Control.FOCUS_NONE
	else:
		if focus_node.has_meta("candy_focus_mode"):
			focus_node.focus_mode = focus_node.get_meta("candy_focus_mode")
			focus_node.remove_meta("candy_focus_mode")

#* Get a choice menu's timer, or null:
func get_timer(source: CandyEngine, caller: Object, menu_node: Node, timer_key: String) -> Timer:
	if menu_node == null or not is_instance_valid(menu_node):
		return null
	if not ("timer_list" in menu_node) or menu_node.timer_list == null:
		return null
	var node = menu_node.timer_list.get_node_or_null(NodePath(timer_key))
	if node is Timer:
		return node
	return null

#* Clear choice list data from a depth down:
func clear_depth(source: CandyEngine, caller: Object, depth: int) -> void:
	for d in source.choice_lists.keys():
		if int(d) >= depth:
			source.choice_lists.erase(d)
	for d in source.choice_list_data.keys():
		if int(d) >= depth:
			source.choice_list_data.erase(d)

#* Pause a menu's running timers, for later resuming:
func pause_timers(source: CandyEngine, caller: Object, menu_node: Node, timers_array: Array, skip_key: String = "") -> void:
	for timer_entry in timers_array:
		for timer_key in timer_entry.keys():
			#% Timer to leave alone:
			if timer_key == skip_key:
				continue
			var t_data: Dictionary = timer_entry[timer_key]
			if t_data.get("Status", "") != "Run":
				continue
			var t_node := get_timer(source, caller, menu_node, timer_key)
			if t_node == null:
				continue
			t_node.set_paused(true)
			t_data["Status"] = "Signal Pause"
			if OS.is_debug_build() and source.debug_prints == true:
				print("[DEBUG] Choice_List: Timer '%s' paused (Signal Pause)." % timer_key)

#* Apply pending timer changes, back at a menu's Choice_List:
func apply_timers(source: CandyEngine, caller: Object, menu_node: Node, timers_array: Array, context: String = "") -> void:
	for timer_entry in timers_array:
		for timer_key in timer_entry.keys():
			var t_data: Dictionary = timer_entry[timer_key]
			var t_node := get_timer(source, caller, menu_node, timer_key)
			if t_node == null:
				continue

			var intent: String = str(t_data.get("Pending Status", ""))
			t_data.erase("Pending Status")

			#% No intent → resume engine-paused timers only:
			if intent == "":
				if t_data.get("Status", "") != "Signal Pause":
					continue
				intent = "Start/Resume"

			#% No loops left:
			if intent == "Start/Resume" and int(state_num(source, caller, t_data, "Loops", 1.0)) == 0:
				t_node.stop()
				t_node.set_paused(false)
				t_data.erase("Pending Restart")
				t_data["Status"] = "Hold"
				if OS.is_debug_build() and source.debug_prints == true:
					print("[DEBUG] Choice_List: Timer '%s' not started %s - no loops left." % [timer_key, context])
				continue

			match intent:
				"Start/Resume":
					t_node.set_paused(false)

					#¦ 1. Stopped → fresh start:
					if t_node.is_stopped():
						t_node.wait_time = safe_wait_time(source, caller, state_num(source, caller, t_data, "Time", 0.0), "Choice_List timer '%s' start" % timer_key)
						t_node.start()
						t_data.erase("Pending Restart")
						if OS.is_debug_build() and source.debug_prints == true:
							print("[DEBUG] Choice_List: Timer '%s' started (%.2fs) %s." % [timer_key, t_node.wait_time, context])

					#¦ 2. Time change queued → restart:
					elif t_data.has("Pending Restart"):
						t_node.wait_time = safe_wait_time(source, caller, float(t_data["Pending Restart"]), "Choice_List timer '%s' restart" % timer_key)
						t_node.start()
						t_data.erase("Pending Restart")
						if OS.is_debug_build() and source.debug_prints == true:
							print("[DEBUG] Choice_List: Timer '%s' restarted with new time (%.2fs) %s." % [timer_key, t_node.wait_time, context])

					#¦ 3. Mid-countdown → resume:
					else:
						if OS.is_debug_build() and source.debug_prints == true:
							print("[DEBUG] Choice_List: Timer '%s' resumed %s." % [timer_key, context])

					t_data["Status"] = "Run"

				"Pause":
					#? Keeps "Pending Restart".
					t_node.set_paused(true)
					t_data["Status"] = "Pause"
					if OS.is_debug_build() and source.debug_prints == true:
						print("[DEBUG] Choice_List: Timer '%s' paused %s." % [timer_key, context])

				"Stop":
					t_node.stop()
					t_node.set_paused(false)
					t_data.erase("Pending Restart")
					t_data["Status"] = "Stopped"
					if OS.is_debug_build() and source.debug_prints == true:
						print("[DEBUG] Choice_List: Timer '%s' stopped %s." % [timer_key, context])

#* Custom Data of the Choice_List at a depth, or []:
func menu_custom_data(source: CandyEngine, caller: Object, depth: int) -> Array:
	if not source.choice_list_data.has(depth):
		return []
	return CandyCustomData.levels([source.choice_list_data[depth]])

#* Run a closing menu's x_menu_closing hook:
func play_closing(source: CandyEngine, caller: Object, depth: int, menu_node: Node, picked: Dictionary) -> bool:
	_set_focus_blocked(source, caller, menu_node, true)

	var candy_args: Dictionary = {"caller": source, "node": menu_node}
	candy_args.merge(picked)
	await candy_de.run_node_hook(menu_node, "x_menu_closing", candy_args, menu_custom_data(source, caller, depth))

	return source.killswitch == false		#/ False if the killswitch was raised meanwhile

#* Close a choice menu and re-show the one underneath:
func close_menu(source: CandyEngine, caller: Object, depth: int, menu_node = null) -> void:	#/ Untyped: menu_node may already be freed (e.g. by Jump)
	#Ł Restore the mouse mode:
	var mouse_before = source.choice_lists.get(depth, {}).get("Mouse Before", null)

	clear_depth(source, caller, depth)

	if mouse_before != null and Input.get_mouse_mode() != mouse_before:
		Input.set_mouse_mode(mouse_before)

	if menu_node != null and is_instance_valid(menu_node):
		menu_node.queue_free()

	if source.hide_choice_lists != true:
		return

	#% Killswitch - every menu is freed, none re-shown:
	if source.killswitch == true:
		return

	var deepest := -1
	var target: Node = null
	for d in source.choice_lists.keys():
		var candidate = source.choice_lists[d].get("Menu", null)
		if candidate == null or not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
			continue
		#% Finishing (closes after its transition):
		if source.choice_lists[d].get("Finishing", false) == true:
			continue
		if int(d) > deepest:
			deepest = int(d)
			target = candidate

	#% Hidden for a transition - show_after_transition() shows it:
	if target != null and source.choice_lists[deepest].get("Transition Hidden", false) == true:
		return

	if target != null:
		if target.has_method("reactivate"):
			await target.reactivate(menu_custom_data(source, caller, deepest))
		else:
			target.visible = true

#* Free every choice menu this engine opened:
func free_menus(source: CandyEngine, caller: Object) -> void:
	var choices_root := CandyUI.get_shared().get_element(source, caller, "choices_path")
	if choices_root == null:
		return
	for child in choices_root.get_children():
		if child.get("caller") == source:
			child.queue_free()

#* Hide this engine's open menus (hide_choice_lists), except never_hide ones:
func hide_open_menus(source: CandyEngine, caller: Object, choices_root: Node) -> void:
	if source.hide_choice_lists != true or choices_root == null:
		return
	for child in choices_root.get_children():
		if child.get("never_hide") == true or child.get("caller") != source:
			continue

		#% Closing menu - awaiting it would never return:
		if child.is_queued_for_deletion():
			continue

		#% Already hidden:
		if child.get("visible") == false:
			continue

		if child.has_method("deactivate"):
			var depth := -1
			if child.get("nesting_depth") != null:
				depth = int(child.get("nesting_depth"))
			await child.deactivate(menu_custom_data(source, caller, depth))
		else:
			child.visible = false

#* Run a Setup transition:
func run_setup(source: CandyEngine, caller: Object, setup: Dictionary, context: String, current_conversation, current_block) -> String:
	if setup.is_empty():
		return "Continue"

	var convo: String = str(source.candy_ref.resolve_value(source, source, setup.get("Conversation", ""), candy_de.candy_ref_symbol)).strip_edges()
	var block: String = str(source.candy_ref.resolve_value(source, source, setup.get("Block", ""), candy_de.candy_ref_symbol)).strip_edges()
	var line_ref: String = str(source.candy_ref.resolve_value(source, source, setup.get("Line", ""), candy_de.candy_ref_symbol)).strip_edges()
	var trans_type: String = str(source.candy_ref.resolve_value(source, source, setup.get("Type", "Bridge"), candy_de.candy_ref_symbol)).to_lower()

	#% No target:
	if convo == "" and block == "" and line_ref == "":
		return "Continue"

	match trans_type:
		"bridge":
			var fake_line := CandyFlow.get_shared().transition_line(source, caller, "Bridge", convo, block, line_ref)
			var feedback = await CandyFlow.get_shared().run_nested_line(source, caller, fake_line, current_conversation, current_block)
			if OS.is_debug_build() and source.debug_prints == true:
				print("[DEBUG] %s: ran Bridge → %s:%s:%s (feedback=%s)." % [context, convo, block, line_ref, str(feedback)])
			return str(feedback)		#/ Bridged lines' feedback
		_:
			if OS.is_debug_build() and source.debug_prints == true:
				print("[DEBUG] Unknown transition type in %s: %s" % [context, trans_type])

	return "Continue"

#* Apply the shown category's Mouse setting:
func apply_category_mouse(source: CandyEngine, caller: Object, menu_data: Dictionary, cat_data: Dictionary, context: String) -> void:
	var menu_mouse: String = str(source.candy_ref.resolve_value(source, source, menu_data.get("Mouse", "Default"), candy_de.candy_ref_symbol)).strip_edges()
	var final_mouse: String = str(source.candy_ref.resolve_value(source, source, cat_data.get("Mouse", "Default"), candy_de.candy_ref_symbol)).strip_edges()

	#% "Menu" - the menu's Mouse:
	if final_mouse.to_lower() == "menu":
		final_mouse = menu_mouse

	#% "Default" - mouse_mode_choice:
	if final_mouse.to_lower() == "default":
		match source.mouse_mode_choice:
			CandyEngine.MouseModes.None:
				final_mouse = ""
			CandyEngine.MouseModes.Visible:
				final_mouse = "Visible"
			CandyEngine.MouseModes.Hidden:
				final_mouse = "Hidden"
			CandyEngine.MouseModes.Captured:
				final_mouse = "Captured"
			CandyEngine.MouseModes.Confined:
				final_mouse = "Confined"
			CandyEngine.MouseModes.Confined_Hidden:
				final_mouse = "Confined_Hidden"

	match final_mouse.to_lower():
		"":
			if OS.is_debug_build() and source.debug_prints == true:
				print("[DEBUG] Choice_List: Mouse mode is None - left unchanged %s." % context)
			return
		"visible":
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		"hidden":
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		"captured", "locked":
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		"confined":
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		"confined_hidden":
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		_:
			if OS.is_debug_build() and source.debug_prints == true:
				print("[DEBUG] Choice_List: Unknown mouse mode '%s' %s - left unchanged." % [final_mouse, context])
			return

	if OS.is_debug_build() and source.debug_prints == true:
		print("[DEBUG] Choice_List: Mouse mode set to %s %s." % [final_mouse, context])

#* Restore the mouse mode from before the first menu opened, when every menu goes at once:
func restore_mouse(source: CandyEngine, caller: Object) -> void:
	var shallowest := -1
	var mouse_before = null
	for d in source.choice_lists.keys():
		if not source.choice_lists[d].has("Mouse Before"):
			continue
		if shallowest == -1 or int(d) < shallowest:
			shallowest = int(d)
			mouse_before = source.choice_lists[d]["Mouse Before"]

	if mouse_before != null and Input.get_mouse_mode() != mouse_before:
		Input.set_mouse_mode(mouse_before)

#* Clamp a Timer wait_time to a value Godot accepts:
func safe_wait_time(source: CandyEngine, caller: Object, value: float, context: String = "") -> float:
	if value > 0.0:
		return value
	if context != "":
		push_warning("Candy DE: Timer time is %s - clamped to 0.001s (%s)." % [str(value), context])
	return 0.001

@warning_ignore_restore("unused_parameter")
