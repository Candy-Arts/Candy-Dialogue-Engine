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
	var timer_mode: String		= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Timer_Mode", "Last"), candy_de.candy_ref_symbol)).capitalize()
	var timer_tags_raw: String	= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Timer_Tags", ""), candy_de.candy_ref_symbol)).strip_edges()
	var menu_mode: String		= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Menu_Mode", "Last"), candy_de.candy_ref_symbol)).capitalize()
	var menu_tags_raw: String	= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Menu_Tags", ""), candy_de.candy_ref_symbol)).strip_edges()

	#@ Step 1 - Modification fields:
	var time_val_str: String	= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Time", ""), candy_de.candy_ref_symbol)).strip_edges()
	var node_mode: String		= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Timer_Node", "Ignore"), candy_de.candy_ref_symbol)).capitalize()
	var loop_val_str: String	= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Loops", ""), candy_de.candy_ref_symbol)).strip_edges()
	var status_val: String		= str(engine.candy_ref.resolve_value(engine, engine, command_value.get("Status", ""), candy_de.candy_ref_symbol)).strip_edges()

	#@ Step 2 - Split tags:
	var timer_tags = timer_tags_raw.split(",", false)
	var menu_tags = menu_tags_raw.split(",", false)

	#% Unknown filter modes change nothing:
	var filters := {"Menu_Mode": menu_mode, "Timer_Mode": timer_mode}
	for filter_key in filters.keys():
		if not (filters[filter_key] in ["Last", "Tags", "All"]):
			push_warning("Candy DE: Timer_Status - unknown %s '%s' (expected \"Last\", \"Tags\" or \"All\"). Nothing was changed." % [filter_key, filters[filter_key]])
			return "Continue"

	#% Time and Loops must be numbers (a word would count as 0):
	if time_val_str != "" and not _is_number_change(time_val_str):
		push_warning("Candy DE: Timer_Status - Time '%s' is not a number (expected \"N\", \"+N\", \"-N\", \"*N\" or \"/N\"). Time left unchanged." % time_val_str)
		time_val_str = ""
	if loop_val_str != "" and not (loop_val_str.to_lower() in ["inf", "!"]) and not _is_number_change(loop_val_str):
		push_warning("Candy DE: Timer_Status - Loops '%s' is not a number (expected \"N\", \"+N\", \"-N\", \"*N\", \"/N\", \"inf\", \"!\" or \"0\"). Loops left unchanged." % loop_val_str)
		loop_val_str = ""

	if not (node_mode in ["Ignore", "Restart", "Update"]):
		push_warning("Candy DE: Timer_Status - unknown Timer_Node '%s' (expected \"Ignore\", \"Restart\" or \"Update\"). Using \"Ignore\"." % node_mode)
		node_mode = "Ignore"

	#@ Step 3 - Target depths:
	var target_depths: Array = []

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
		var timers_array: Array = engine.choice_list_data.get(depth, {}).get("Timers", [])
		if timers_array.is_empty():
			continue

		#Ł Menu node:
		var menu_node = engine.choice_lists.get(depth, {}).get("Menu", null)

		for timer_entry in timers_array:
			for timer_name in timer_entry.keys():
				var timer_data: Dictionary = timer_entry[timer_name]
				if timer_data.is_empty():
					continue

				var tags_str: String = str(engine.candy_ref.resolve_value(engine, engine, timer_data.get("Tags", ""), candy_de.candy_ref_symbol)).strip_edges()

				#Ł Timer filter:
				var include_timer := true
				match timer_mode:
					"Last":
						if not engine.choice_lists.has(depth) or not engine.choice_lists[depth].has("Last Timer"):
							include_timer = false
						else:
							var last_timer = engine.choice_lists[depth]["Last Timer"]
							include_timer = (last_timer == timer_name)
					"Tags":
						include_timer = false
						for tag in timer_tags:
							if CandyChoices.get_shared().has_tag(engine, self, tags_str, tag):
								include_timer = true
								break
					"All":
						if timer_tags_raw != "":
							for tag in timer_tags:
								if CandyChoices.get_shared().has_tag(engine, self, tags_str, tag):
									include_timer = false
									break

				if not include_timer:
					continue

				var timer_node := CandyChoices.get_shared().get_timer(engine, self, menu_node, timer_name)

				#Ł Time modification:
				if time_val_str != "":
					#Ł Resolve the stored Time (may be a reference):
					var old_time: float = CandyChoices.get_shared().state_num(engine, self, timer_data, "Time", 0.0)
					var new_time: float = old_time

					if time_val_str.begins_with("+"):
						new_time += float(time_val_str.substr(1))
					elif time_val_str.begins_with("-"):
						new_time -= float(time_val_str.substr(1))
					elif time_val_str.begins_with("*"):
						new_time *= float(time_val_str.substr(1))
					elif time_val_str.begins_with("/"):
						var divisor = float(time_val_str.substr(1))
						if divisor != 0.0:
							new_time /= divisor
					else:
						new_time = float(time_val_str)

					new_time = max(new_time, 0.0)
					timer_data["Time"] = str(new_time)

					if timer_node:
						match node_mode:
							"Restart":
								timer_data["Pending Restart"] = new_time
								if OS.is_debug_build() and engine.debug_prints == true:
									print("[DEBUG] Timer_Status: Timer '%s' flagged for restart (%.2fs)." % [timer_name, new_time])
							"Update":
								#Ł Compare with the pending countdown, if any:
								var remaining: float = timer_node.time_left
								if timer_data.has("Pending Restart"):
									remaining = float(timer_data["Pending Restart"])
								if new_time < remaining:
									timer_data["Pending Restart"] = new_time
									if OS.is_debug_build() and engine.debug_prints == true:
										print("[DEBUG] Timer_Status: Timer '%s' flagged for update (%.2fs < %.2fs remaining)." % [timer_name, new_time, remaining])
								else:
									if OS.is_debug_build() and engine.debug_prints == true:
										print("[DEBUG] Timer_Status: Timer '%s' not updated (%.2fs >= %.2fs remaining)." % [timer_name, new_time, remaining])
							"Ignore":
								pass

				#Ł Loops modification:
				if loop_val_str != "":
					var old_loop: int = int(CandyChoices.get_shared().state_num(engine, self, timer_data, "Loops", 0.0))
					var new_loop: int = old_loop

					var loop_str = loop_val_str.to_lower()
					var is_relative: bool = loop_str.begins_with("+") or loop_str.begins_with("-") or loop_str.begins_with("*") or loop_str.begins_with("/")
					if loop_str in ["inf", "!", "0"]:
						new_loop = -1

					#% Infinite stays infinite:
					elif is_relative and old_loop == -1:
						new_loop = -1

					else:
						if loop_str.begins_with("+"):
							new_loop += int(loop_str.substr(1))
						elif loop_str.begins_with("-"):
							new_loop -= int(loop_str.substr(1))
						elif loop_str.begins_with("*"):
							new_loop = roundi(float(old_loop) * float(loop_str.substr(1)))
						elif loop_str.begins_with("/"):
							var divisor = int(float(loop_str.substr(1)))
							if divisor != 0:
								new_loop = roundi(float(old_loop) / divisor)
						else:
							new_loop = int(loop_str)

						#Ł Floor at 0 (-1 = forever):
						if new_loop < 0:
							new_loop = 0

					timer_data["Loops"] = str(new_loop)
					if OS.is_debug_build() and engine.debug_prints == true:
						print("[DEBUG] Timer_Status: Timer '%s' loop count set to %s." % [timer_name, str(new_loop)])

				#Ł Status modification:
				#? Recorded - Choice_List applies it on return to the menu.
				if status_val != "":
					match status_val:
						"Start/Resume", "Pause", "Stop":
							timer_data["Pending Status"] = status_val
							if OS.is_debug_build() and engine.debug_prints == true:
								print("[DEBUG] Timer_Status: Timer '%s' will %s on return to its menu." % [timer_name, status_val])

						"-":
							if OS.is_debug_build() and engine.debug_prints == true:
								print("[DEBUG] Timer_Status: Timer '%s' unchanged." % timer_name)

						_:
							printerr("Timer_Status: Unknown Status '%s' for timer '%s' - ignored." % [status_val, timer_name])

				if OS.is_debug_build() and engine.debug_prints == true:
					print("[DEBUG] Timer_Status: Updated timer '%s' (depth %s, tags='%s')." % [timer_name, str(depth), tags_str])

	return "Continue"


#* Whether a Time / Loops change is a number, optionally after + - * /:
func _is_number_change(value: String) -> bool:
	var number := value
	if value.begins_with("+") or value.begins_with("-") or value.begins_with("*") or value.begins_with("/"):
		number = value.substr(1)
	return number.strip_edges().is_valid_float()
