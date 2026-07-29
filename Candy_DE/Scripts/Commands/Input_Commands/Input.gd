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
	var cr: CandyRef = engine.candy_ref
	var sym: String = candy_de.candy_ref_symbol

	var input_path: String			= CandyUI.get_shared().resolve_scene_path(engine, self, command_value.get("File", ""), candy_de.input_menus_folder)
	var parent_ref: Variant			= command_value.get("Parent", "null")	#/ CandyCutscene.resolve_target()
	var input_variable: Variant		= command_value.get("Variable", "")	#/ Write target, resolved by the Input scene (Input_Text.gd)
	var setup_mode: Variant			= cr.resolve_value(engine, engine, command_value.get("Mode", ""), sym)
	var input_instructions: Variant	= cr.resolve_value(engine, engine, command_value.get("Instructions", ""), sym)
	var input_placeholder: Variant	= cr.resolve_value(engine, engine, command_value.get("Placeholder", ""), sym)
	var input_default_text: Variant	= cr.resolve_value(engine, engine, command_value.get("Text", ""), sym)
	var custom_data: Array			= CandyCustomData.levels([command_value])	#/ As written

	#@ Step 1 - Instance name:
	if input_path == "":
		input_path = candy_de.input_menus_folder.path_join("Default.tscn")
		if OS.is_debug_build() and engine.debug_prints == true:
			print("Input: Missing 'File', defaulting to 'Default.tscn'.")

	#Ł File name only - a path breaks node names and has_node():
	var input_ui_name: String = input_path.get_file().trim_suffix(".tscn")

	#@ Step 2 - Store depth:
	var this_depth = engine.nesting_depth

	#Ł Store mouse mode:
	var previous_mouse_mode := Input.get_mouse_mode()

	#@ Step 3 - Find the parent:
	var input_parent: Node = null
	if CandySettings.is_not_set(parent_ref):
		input_parent = CandyUI.get_shared().get_element(engine, self, "input_node_path", "Input")
	else:
		input_parent = CandyCutscene.get_shared().resolve_target(engine, self, parent_ref, "Input: Parent")
	if input_parent == null:
		return "Continue"
	var input_instance: Node = null

	#@ Step 4 - Reuse an existing instance:
	#? Not one queued for deletion: it's renamed and a new one is built.
	if input_parent.has_node(input_ui_name):
		var existing: Node = input_parent.get_node(input_ui_name)
		if is_instance_valid(existing) and not existing.is_queued_for_deletion():
			input_instance = existing
			input_instance.depth = this_depth
			input_instance.caller = engine

			#% Same file name, different folder:
			if str(input_instance.get_meta("candy_input_scene", input_path)) != input_path:
				push_warning("Candy DE: Input reused '%s' from '%s' - another Input scene shares that file name."
					% [input_ui_name, str(input_instance.get_meta("candy_input_scene", ""))])
		elif is_instance_valid(existing):
			existing.name = input_ui_name + "_Closing"	#/ Free the name

	#@ Step 5 - Else instantiate:
	if input_instance == null:
		if not CandyMedia.exists(input_path):
			printerr("Input: missing Input UI scene → ", input_path)
			return "Continue"

		var input_scene = load(input_path)
		if not (input_scene is PackedScene):
			printerr("Input: failed to load Input UI scene → ", input_path)
			return "Continue"

		input_instance = input_scene.instantiate()
		input_instance.name = input_ui_name		#/ File name minus '.tscn'
		input_instance.set_meta("candy_input_scene", input_path)	#/ Source scene
		input_instance.caller = engine
		input_instance.depth = this_depth
		input_parent.add_child(input_instance)

	#Ł Track it:
	if not engine.input_scenes.has(input_instance):
		engine.input_scenes.append(input_instance)

	#@ Step 6 - Set up:
	if input_instance.has_method("setup"):
		input_instance.setup(input_variable, setup_mode, input_instructions, input_default_text, input_placeholder, custom_data)
	else:
		push_warning("[NOTICE] Input: setup() function missing in Input UI script.")

	#@ Step 7 - Run each event's Input_Events script:
	var sig
	var outcome := "Continue"
	while true:
		sig = await engine.input_received

		#% Killswitch:
		if engine.killswitch == true:
			return "END"

		#% Other depth:
		if sig[0] != this_depth:
			continue

		var event_type: String = str(sig[1]).to_lower()
		var parameters = {}
		if sig.size() >= 3:
			parameters = sig[2]

		#% Unknown event - leave, not to get stuck:
		if not engine.input_event_registry.has(event_type):
			push_warning("Candy DE: Input received the unknown event '%s' - no script for it in the Input_Events folder. Leaving the Input." % event_type)
			break

		var event_script: CandyInputEvent = engine.input_event_registry[event_type]
		@warning_ignore("redundant_await")
		outcome = await event_script.handle(engine, input_instance, this_depth, parameters, ctx)

		if engine.killswitch == true or outcome == "END":
			return "END"

		if outcome == "Wait":
			continue

		if outcome != "Continue" and outcome != "Return":
			push_warning("Candy DE: Input event '%s' returned '%s' - expected \"Wait\", \"Continue\", \"Return\" or \"END\". Leaving the Input." % [event_type, outcome])
			outcome = "Continue"
		break

	#@ Step 8 - Restore mouse mode:
	if Input.get_mouse_mode() != previous_mouse_mode:
		Input.set_mouse_mode(previous_mouse_mode)

	return outcome
