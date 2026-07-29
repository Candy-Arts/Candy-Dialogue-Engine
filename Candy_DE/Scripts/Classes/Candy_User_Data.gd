#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Node


#^ Table and function folders (sub-folders included):
const TABLE_FOLDERS: Array[String] = [
	"res://Candy_DE/Scripts/User_Data/Localization_Tables",
	"res://Candy_DE/Scripts/User_Data/Data_Tables",
]

const FUNCTION_FOLDERS: Array[String] = [
	"res://Candy_DE/Scripts/User_Data/Functions",
]

#^ Tables Candy DE reads (checked at startup):
const REQUIRED_TABLES: Array[String] = [
	#% Localization_Tables:
	"display_names",
	"choice_menu_titles",
	"choice_menu_prompts",
	"choice_category_titles",
	"choice_category_prompts",
	"choice_button_labels",
	"choice_button_tooltips",
	"input_instructions",
	"input_placeholder_texts",
	"input_default_texts",
	"input_blacklists",
	"input_whitelists",
	"input_error_messages",

	#% Data_Tables:
	"substitution_table",
	"lexicon",
	"lexicon_word_rules",
	"text_events",
	"literal_variables",
	"variables",
	"flags",
	"roles",
	"player_refs",
	"current_player",
	"actors",
	"hook_arguments",
]

#^ Functions Candy DE calls (checked at startup):
const REQUIRED_FUNCTIONS: Array[String] = [
	"change_game_state",
	"open_instance_history",
	"open_general_history",
	"_on_lexicon_clicked",
	"_on_lexicon_hovered",
	"clear_busts_ood",
	"clear_bg_layers_ood",
	"tts",
	"llm_query",
	"x_new_line",
	"x_command_start",
	"x_new_speech_start",
	"x_new_speech_display",
	"x_speech_advance",
	"x_choice_selected",
	"x_jump",
	"x_bridge",
	"x_return",
	"x_end",
	"x_dialogue_start",
	"x_dialogue_suspended",
	"x_dialogue_resumed",
	"x_dialogue_end",
	"x_flag_changed",
]

#^ Godot virtuals, never registered:
const RESERVED_METHODS: Array[String] = [
	"_init", "_ready", "_enter_tree", "_exit_tree", "_process", "_physics_process",
	"_notification", "_get", "_set", "_get_property_list", "_to_string",
	"_property_can_revert", "_property_get_revert", "_validate_property",
]


#^ Loaded tables, by variable name:
var _user_tables: Dictionary = {}

#^ Which file each table came from, for error messages:
var _user_table_files: Dictionary = {}

#^ Loaded functions by name (one Callable per file):
var _user_functions: Dictionary = {}

#^ Which file each function came from, for error messages:
var _user_function_files: Dictionary = {}

#^ Loaded function script instances:
var _user_function_providers: Array = []

#^ Loaded once:
var _user_data_loaded: bool = false


#& LOADING:
#* Load at instantiation, before any _ready():
func _init() -> void:
	_ensure_user_data_loaded()


#* Safety net, in case a derived _init() skips super():
func _enter_tree() -> void:
	_ensure_user_data_loaded()


#* Load once:
func _ensure_user_data_loaded() -> void:
	if _user_data_loaded:
		return
	_user_data_loaded = true

	for folder in TABLE_FOLDERS:
		var scripts: Dictionary = {}
		_collect_scripts_in_folder(folder, CandyDataTable, scripts)
		for script_key in scripts:
			_load_table_script(scripts[script_key])

	for folder in FUNCTION_FOLDERS:
		var scripts: Dictionary = {}
		_collect_scripts_in_folder(folder, CandyFunction, scripts)
		for script_key in scripts:
			_load_function_script(scripts[script_key])


#* Recursive folder scan, keyed by lowercase file name:
func _collect_scripts_in_folder(folder: String, base_class: Script, scripts: Dictionary) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		#% Missing folder:
		push_error("Candy DE: could not open the folder '" + folder + "'.")
		return

	for file_name in dir.get_files():
		#Ł Trim .gd/.gdc suffixes:
		var script_name := ""
		if file_name.ends_with(".gd"):
			script_name = file_name.trim_suffix(".gd")
		elif file_name.ends_with(".gd.remap"):
			script_name = file_name.trim_suffix(".gd.remap")
		elif file_name.ends_with(".gdc"):
			script_name = file_name.trim_suffix(".gdc")

		if script_name == "":
			continue

		var script_path := folder.path_join(script_name + ".gd")
		var loaded_script := load(script_path) as Script
		if loaded_script == null or not loaded_script.can_instantiate():
			push_error("Candy DE: could not load script → " + script_path)
			continue

		#Ł Check base class:
		var ancestor: Script = loaded_script
		while ancestor != null and ancestor != base_class:
			ancestor = ancestor.get_base_script()

		if ancestor == null:
			push_error("Candy DE: '" + script_path + "' does not extend " \
				+ base_class.resource_path.get_file().trim_suffix(".gd") + " - skipped.")
			continue

		#% Duplicate name:
		if scripts.has(script_name.to_lower()):
			push_warning("Candy DE: '%s' and '%s' have the same name - only '%s' is used." % [scripts[script_name.to_lower()], script_path, script_path])
		scripts[script_name.to_lower()] = script_path

	for sub_folder in dir.get_directories():
		_collect_scripts_in_folder(folder.path_join(sub_folder), base_class, scripts)


#* Load a table script's variables:
func _load_table_script(script_path: String) -> void:
	var table_script = load(script_path)
	var provider = table_script.new()
	if provider == null:
		push_error("Candy DE: could not instantiate the table script '" + script_path + "'.")
		return

	for property in provider.get_property_list():
		if not (property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue

		var member_name := String(property["name"])
		_user_tables[member_name] = provider.get(member_name)
		_user_table_files[member_name] = script_path


#* Register a function script's functions:
func _load_function_script(script_path: String) -> void:
	var function_script = load(script_path)
	var provider = function_script.new()
	if provider == null:
		push_error("Candy DE: could not instantiate the function script '" + script_path + "'.")
		return

	#@ Step 1 - Add as a child of candy_de:
	provider.name = script_path.get_file().get_basename()
	add_child(provider)
	_user_function_providers.append(provider)

	#@ Step 2 - Declared methods only:
	for method in function_script.get_script_method_list():
		var function_name := String(method["name"])
		if function_name in RESERVED_METHODS:
			continue

		if not _user_functions.has(function_name):
			_user_functions[function_name] = []
			_user_function_files[function_name] = []

		_user_functions[function_name].append(Callable(provider, function_name))
		_user_function_files[function_name].append(script_path)


#& VALIDATION:
#* Report missing required tables and functions:
func _ready() -> void:
	var missing: Array[String] = []
	for table_name in REQUIRED_TABLES:
		if not _user_tables.has(table_name):
			missing.append(table_name)

	if missing.size() > 0:
		push_error("Candy DE: these data tables were not found: " + ", ".join(missing) \
			+ ". Check that each one's script file is present and declares it.")

	var missing_functions: Array[String] = []
	for function_name in REQUIRED_FUNCTIONS:
		if not _user_functions.has(function_name):
			missing_functions.append(function_name)

	if missing_functions.size() > 0:
		push_error("Candy DE: these functions were not found: " + ", ".join(missing_functions) \
			+ ". Check that each one's script file is present and that the function name " \
			+ "is spelled correctly.")

	CandyVoice.check_settings(self)


#& HOOK DISPATCH:
#? Every hook takes three arguments:
#?   candy_args:  Candy DE's values, by name.
#?   user_args:   the developer's values, from the hook_arguments table.
#?   custom_data: the line's Custom Data (CandyCustomData).

#* Whether a function is loaded:
func has_user_function(function_name: String) -> bool:
	return _user_functions.has(function_name)


#* Run a hook in every script that implements it, in file name order:
func run_hook(function_name: String, candy_args: Dictionary = {}, custom_data: Array = []) -> void:
	if not _user_functions.has(function_name):
		return

	var user_args := _resolve_user_args(function_name, candy_args)
	for callable in _user_functions[function_name]:
		await callable.call(candy_args, user_args, custom_data)


#* Run a hook that returns a value:
func call_hook(function_name: String, candy_args: Dictionary = {}, custom_data: Array = []) -> Variant:
	if not _user_functions.has(function_name):
		return null		#/ No implementation

	var callables: Array = _user_functions[function_name]
	if callables.size() > 1:
		push_warning("Candy DE: '" + function_name + "' returns a value but is implemented " \
			+ "in more than one file (" + ", ".join(_user_function_files[function_name]) \
			+ "). Only the first is used.")

	var user_args := _resolve_user_args(function_name, candy_args)
	return await callables[0].call(candy_args, user_args, custom_data)


#* Run a hook on a node (UI elements, media players):
func run_node_hook(node: Object, function_name: String, candy_args: Dictionary = {}, custom_data: Array = []) -> Variant:
	if node == null or not node.has_method(function_name):
		return null

	var user_args := _resolve_user_args(function_name, candy_args)
	return await node.call(function_name, candy_args, user_args, custom_data)


#* Run an API function (called from game code, with ordinary arguments):
func run_user_function(function_name: String, args: Array = []) -> Variant:
	if not _user_functions.has(function_name):
		return null

	var result = null
	for callable in _user_functions[function_name]:
		result = await callable.callv(args)
	return result


#* Build a hook's user_args from hook_arguments:
func _resolve_user_args(function_name: String, candy_args: Dictionary) -> Array:
	var table = _user_tables.get("hook_arguments", {})
	if not table.has(function_name):
		return []

	var entries = table[function_name]
	if typeof(entries) != TYPE_ARRAY:
		push_error("Candy DE: hook_arguments['" + function_name \
			+ "'] must be an Array. Ignored.")
		return []

	#@ Step 1 - Resolve against the calling engine:
	var source: Node = self
	var candy_caller = candy_args.get("caller")
	if candy_caller is Node:
		source = candy_caller

	#? Declared in Candy_Properties.gd.
	var symbol := str(get("candy_ref_symbol"))

	#@ Step 2 - Evaluate candy_ref_symbol entries, on every call:
	var resolved: Array = []
	var candy_ref := CandyRef.get_shared()
	for entry in entries:
		resolved.append(candy_ref.resolve_value(source, source, entry, symbol))

	return resolved


#& PROPERTY ACCESS:
#? Tables as 'candy_de.<table name>'.

#* Read a table:
func _get(property: StringName):
	var member_name := String(property)
	if _user_tables.has(member_name):
		return _user_tables[member_name]
	return null


#* Assign a whole table:
func _set(property: StringName, value) -> bool:
	var member_name := String(property)
	if _user_tables.has(member_name):
		_user_tables[member_name] = value
		return true
	return false		#/ Unknown name: a typo errors


#* List the tables as properties:
func _get_property_list() -> Array:
	var list: Array = []
	for member_name in _user_tables:
		list.append({
			"name": member_name,
			"type": typeof(_user_tables[member_name]),
			"usage": PROPERTY_USAGE_DEFAULT,
		})
	return list


#& HELPERS:
#* Which file a table was loaded from:
func get_user_data_file(member_name: String) -> String:
	if _user_table_files.has(member_name):
		return _user_table_files[member_name]
	return ""


#* Every function name found in the Functions folders:
func get_user_function_names() -> Array:
	return _user_functions.keys()


#* Which files implement a function:
func get_user_function_files(function_name: String) -> Array:
	if _user_function_files.has(function_name):
		return _user_function_files[function_name]
	return []
