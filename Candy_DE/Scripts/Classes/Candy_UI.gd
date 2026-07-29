#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyUI
extends RefCounted


#^ Key of a BG_Effect_ / VN_Effect_ target's effects:
const EFFECTS_KEY := "Effects"

#^ TextureButton slot → accepted file / state folder names (any case):
const BUTTON_TEXTURE_SLOTS := {
	"texture_pressed":		["texture_pressed", "pressed"],
	"texture_hover":		["texture_hover", "hover"],
	"texture_disabled":		["texture_disabled", "disabled"],
	"texture_focused":		["texture_focused", "focused"],
	"texture_click_mask":	["texture_click_mask", "click_mask", "mask"],
}

#^ Shared instance:
static var _shared: CandyUI = null

#* Get the shared instance:
static func get_shared() -> CandyUI:
	if _shared == null:
		_shared = CandyUI.new()
	return _shared


#? Unused 'caller' parameters:
@warning_ignore_start("unused_parameter")

#* Resolve a UI scene reference into a path:
func resolve_scene_path(source: CandyEngine, caller: Object, raw: Variant, folder: String) -> String:
	var ref: String = CandyMedia.to_path(source.candy_ref.resolve_value(source, source, raw, candy_de.candy_ref_symbol))
	if ref == "":
		return ""

	if not ref.ends_with(".tscn"):
		ref += ".tscn"

	#% Absolute path:
	if CandyMedia.is_resource_path(ref):
		return ref

	return folder.path_join(ref)


#* Get a UI element from ui_elements_paths:
func get_element(source: CandyEngine, caller: Object, key: String, context: String = "") -> Node:
	if not source.ui_elements_paths.has(key):
		if context != "":
			printerr(context, ": source.ui_elements_paths has no '", key, "' entry.")
		return null

	var path: String = source.ui_element_path(key).strip_edges()
	if path == "":
		if context != "":
			printerr(context, ": source.ui_elements_paths['", key, "'] is empty.")
		return null

	var node := source.get_node_or_null(path)
	if node == null and context != "":
		printerr(context, ": node not found at '", path, "' → source.ui_elements_paths['", key, "'].")
	return node


#* Find a node a line names:
func find_node(source: CandyEngine, caller: Object, ref: Variant, context: String = "") -> Node:
	if ref is Node:
		return ref

	var text := str(ref).strip_edges()
	if text == "":
		return null

	var node: Node = null
	if source.media_players_paths.has(text):
		node = source.get_node_or_null(source.media_player_path(text))
	elif source.ui_elements_paths.has(text):
		node = get_element(source, caller, text)
	else:
		node = source.get_node_or_null(text)

	if node == null and context != "":
		printerr(context, ": node not found → ", text)
	return node


#* Collect the targets a command lists inside a UI element:
func get_element_targets(source: CandyEngine, caller: Object, element_key: String, command_value: Variant,
		entries_key: String, methods: Array, context: String, depth: int = 1, resolve_roles: bool = false) -> Array:
	var targets: Array = []

	if typeof(command_value) != TYPE_DICTIONARY:
		printerr(context, ": expected a Dictionary → ", command_value)
		return targets
	var entries_value: Variant = command_value.get(entries_key)
	if typeof(entries_value) != TYPE_DICTIONARY:
		printerr(context, ": '", entries_key, "' must be a Dictionary of targets → ", entries_value)
		return targets

	var element := get_element(source, caller, element_key, context)
	if element == null:
		return targets

	var missing: Array = []
	for method in methods:
		if not element.has_method(method):
			missing.append(str(method) + "()")
	if not missing.is_empty():
		printerr(context, ": the '", element_key, "' element can't do this: its script has no ", ", ".join(missing), " → ", element.name)
		return targets

	#@ Step 1 - Resolve targets and settings:
	var entries: Array = []		#/ [target name, animation key, settings, custom_data]
	var take_hold: Variant = ""

	for target_ref in entries_value:
		var target_name := _target_name(source, target_ref)
		var line_settings: Variant = entries_value[target_ref]
		if resolve_roles:
			target_name = str(CandyActors.get_shared().actor_from_role(source, caller, target_name, context))		#/ "°role" key → actor

		if target_name == "":
			printerr(context, ": empty target → ", target_ref)
			continue
		if typeof(line_settings) != TYPE_DICTIONARY:
			printerr(context, ": settings for '", target_ref, "' must be a Dictionary (use {} for none) → ", line_settings)
			continue

		#¦ 1. Depth 1 - the targets:
		if depth < 2:
			var settings := _resolve_settings(source, line_settings)
			if str(take_hold) == "" and str(settings.get("Take_Hold", "")).strip_edges() != "":
				take_hold = settings["Take_Hold"]
			entries.append([target_name, "", settings, CandyCustomData.levels([command_value, line_settings])])
			continue

		#¦ 2. Depth 2 - their EFFECTS_KEY effects:
		var effects: Variant = line_settings.get(EFFECTS_KEY)
		if typeof(effects) != TYPE_DICTIONARY:
			printerr(context, ": '", EFFECTS_KEY, "' of '", target_ref, "' must be a Dictionary of effects → ", effects)
			continue

		for anim_ref in effects:
			var anim_key := str(source.candy_ref.resolve_value(source, source, anim_ref, candy_de.candy_ref_symbol)).strip_edges()
			var anim_settings: Variant = effects[anim_ref]

			if anim_key == "":
				printerr(context, ": empty animation on '", target_name, "' → ", anim_ref)
				continue
			if typeof(anim_settings) != TYPE_DICTIONARY:
				printerr(context, ": settings for '", target_name, "/", anim_ref, "' must be a Dictionary (use {} for none) → ", anim_settings)
				continue

			var settings := _resolve_settings(source, anim_settings)
			if str(take_hold) == "" and str(settings.get("Take_Hold", "")).strip_edges() != "":
				take_hold = settings["Take_Hold"]
			entries.append([target_name, anim_key, settings, CandyCustomData.levels([command_value, line_settings, anim_settings])])

	if entries.is_empty():
		return targets

	#@ Step 2 - Admit the command:
	if not CandyPlayback.get_shared().admit(source, caller, element, element_key, take_hold, context):
		return targets

	#@ Step 3 - Build targets:
	for entry in entries:
		var candy_args: Dictionary = {
			"caller": source,
			"command": context,
			"key": entry[0],
		}
		if depth >= 2:
			candy_args["animation"] = entry[1]
		targets.append([element, candy_args, entry[2], entry[3]])

	return targets		#/ [element, candy_args, settings, custom_data] per target, in line order


#* Call a function on targets, group by group (JML_Order, lowest first):
func run_in_order(source: CandyEngine, caller: Object, targets: Array, method: String, order_key: String = "JML_Order") -> Array:
	#@ Step 1 - Group by order:
	var groups: Dictionary = {}
	for target in targets:
		var order := 0
		var order_raw := str(target[2].get(order_key, "")).strip_edges()
		if order_raw != "":
			order = int(order_raw)
		if not groups.has(order):
			groups[order] = []
		groups[order].append(target)

	var orders: Array = groups.keys()
	orders.sort()

	#@ Step 2 - Run each group, its targets together:
	var succeeded: Array = []
	for order in orders:
		var batch: Dictionary = {"pending": groups[order].size()}
		for target in groups[order]:
			_run_target(target, method, batch, succeeded)
		while int(batch["pending"]) > 0:
			await source.get_tree().process_frame

	#@ Step 3 - Line order:
	var result: Array = []
	for target in targets:
		if target in succeeded:
			result.append(target)
	return result		#/ Targets whose call returned true


#* Run one target of a group:
func _run_target(target: Array, method: String, batch: Dictionary, succeeded: Array) -> void:
	var outcome = await target[0].call(method, target[1], target[2], target[3])
	if typeof(outcome) == TYPE_BOOL and outcome == true:
		succeeded.append(target)
	batch["pending"] = int(batch["pending"]) - 1


#* The VN bust scene if it shows an actor, else null (VN mode only):
func actor_bust_scene(source: CandyEngine, caller: Object, actor_ref: Variant) -> Node:
	if source.vn_mode == false:
		return null
	var bust_scene := get_element(source, caller, "busts_path")
	if bust_scene == null or not ("bust_positions" in bust_scene):
		return null
	if not bust_scene.bust_positions.has(actor_ref):
		return null
	return bust_scene


#* Whether an actor is on a VN bust (VN mode only):
func has_bust(source: CandyEngine, caller: Object, actor_ref: Variant) -> bool:
	return actor_bust_scene(source, caller, actor_ref) != null


#* The bust node an actor is on, or null (VN mode only):
func actor_bust(source: CandyEngine, caller: Object, actor_ref: Variant) -> Node:
	var bust_scene := actor_bust_scene(source, caller, actor_ref)
	if bust_scene == null or not ("busts_container" in bust_scene) or bust_scene.busts_container == null:
		return null
	return bust_scene.busts_container.get_node_or_null(str(bust_scene.bust_positions[actor_ref]["pos"]))


#* Target name (a ¢ expression may give a Node):
func _target_name(source: CandyEngine, target_ref: Variant) -> String:
	var value: Variant = source.candy_ref.resolve_value(source, source, target_ref, candy_de.candy_ref_symbol)
	if value is Node:
		if is_instance_valid(value):
			return str(value.name)
		return ""
	return str(value).strip_edges()


#* Resolve settings through CandyRef:
func _resolve_settings(source: CandyEngine, line_settings: Dictionary) -> Dictionary:
	var settings: Dictionary = {}
	for setting_key in line_settings:
		settings[setting_key] = source.candy_ref.resolve_value(source, source, line_settings[setting_key], candy_de.candy_ref_symbol)
	return settings


#* Replace a UI scene (backgrounds, busts) with another one:
func swap_scene(source: CandyEngine, caller: Object, key: String, scene_raw: Variant, folder: String, context: String) -> void:
	#@ Step 1 - Scene location:
	if not source.ui_elements_paths.has(key) or source.ui_element_path(key).strip_edges() == "":
		printerr(context, ": source.ui_elements_paths has no '", key, "' entry - scene not replaced.")
		return

	var node_path: String = source.ui_element_path(key).strip_edges().trim_suffix("/")
	var scene_node_name: String = node_path.get_file()
	var parent_path: String = node_path.get_base_dir()
	var parent: Node
	if parent_path == "":
		parent = source
	else:
		parent = source.get_node_or_null(parent_path)
	if parent == null:
		printerr(context, ": parent node not found at '", parent_path, "' (source.ui_elements_paths['", key, "']) - scene not replaced.")
		return

	#@ Step 2 - Validate the new scene first:
	var resolved = source.candy_ref.resolve_value(source, source, scene_raw, candy_de.candy_ref_symbol)
	var scene_res: PackedScene = null
	var scene_path := ""

	if resolved is PackedScene:
		scene_res = resolved
		scene_path = resolved.resource_path
	else:
		scene_path = CandyMedia.to_path(resolved)
		#% No scene - remove the current one:
		if scene_path == "":
			var removed_scene := source.get_node_or_null(node_path)
			if removed_scene == null:
				return
			_remove_scene(source, caller, removed_scene)
			if OS.is_debug_build() and source.debug_prints == true:
				print("[DEBUG] ", context, ": no scene given - the current scene was removed.")
			return
		if not CandyMedia.is_resource_path(scene_path):
			scene_path = folder.path_join(scene_path)
		if scene_path.get_extension() == "":
			scene_path += ".tscn"

		if not CandyMedia.exists(scene_path):
			printerr(context, ": scene not found → ", scene_path, " - the current scene was kept.")
			return
		var loaded = load(scene_path)
		if loaded is PackedScene:
			scene_res = loaded

	if scene_res == null:
		printerr(context, ": not a valid scene → ", scene_path, " - the current scene was kept.")
		return

	var scene_instance := scene_res.instantiate()
	if scene_instance == null:
		printerr(context, ": the scene could not be instantiated → ", scene_path, " - the current scene was kept.")
		return

	#@ Step 3 - Remove the old scene:
	var insert_index: int = -1
	var old_scene := source.get_node_or_null(node_path)
	if old_scene != null:
		if old_scene.get_parent() == parent:
			insert_index = old_scene.get_index()
		_remove_scene(source, caller, old_scene)

	#@ Step 4 - Add the new scene in its place:
	scene_instance.name = scene_node_name
	if "visible" in scene_instance:
		scene_instance.visible = true

	parent.add_child(scene_instance)
	if insert_index >= 0:
		parent.move_child(scene_instance, min(insert_index, parent.get_child_count() - 1))

	if str(scene_instance.name) != scene_node_name:
		printerr(context, ": the new scene was renamed to '", scene_instance.name, "' - source.ui_elements_paths['", key, "'] won't find it.")

	#@ Step 5 - Claim the new scene:
	source.claim_ui_element(key)
	if not ("access" in scene_instance) and "caller" in scene_instance:
		scene_instance.caller = source

#* Remove and free a UI scene:
func _remove_scene(source: CandyEngine, caller: Object, scene: Node) -> void:
	#@ Step 1 - Release hold:
	if scene.has_method("release_hold"):
		scene.release_hold()

	#@ Step 2 - Remove from owner:
	var owner_engine = scene.get("owner_engine")
	if owner_engine != null and is_instance_valid(owner_engine) and "owned_ui_elements" in owner_engine:
		owner_engine.owned_ui_elements.erase(scene)
	source.owned_ui_elements.erase(scene)

	scene.get_parent().remove_child(scene)
	scene.queue_free()


#* Assign Button_Textures files to a TextureButton's slots:
func apply_button_textures(source: CandyEngine, caller: Object, button_node: TextureButton, button_folder: String, file_base: String) -> void:
	#@ Step 1 - Export-safe listing:
	var all_files: Array[String] = CandyMedia.list_files(button_folder)
	if all_files.is_empty():
		printerr("apply_button_textures(): No files found in folder: ", button_folder)
		return

	var prefix := file_base.to_lower()

	#@ Step 2 - Assign files to slots:
	for slot in BUTTON_TEXTURE_SLOTS:
		for f in all_files:
			var base := f.get_basename().to_lower()

			#% File must match the prefix:
			if not base.begins_with(prefix):
				continue

			#% Suffix gives the slot:
			var suffix := base.substr(prefix.length()).lstrip("_- ")
			if not (suffix in BUTTON_TEXTURE_SLOTS[slot]):
				continue

			var slot_path := button_folder.path_join(f)
			if slot == "texture_click_mask":
				var mask := CandyMedia.load_bitmap(slot_path)
				if mask != null:
					button_node.texture_click_mask = mask
					break
			else:
				var slot_tex := CandyMedia.load_texture(slot_path)
				if slot_tex != null:
					button_node.set(slot, slot_tex)
					break

@warning_ignore_restore("unused_parameter")
