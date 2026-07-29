#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyTargets
extends RefCounted


#^ Shared instance:
static var _shared: CandyTargets = null

#* Get the shared instance:
static func get_shared() -> CandyTargets:
	if _shared == null:
		_shared = CandyTargets.new()
	return _shared


#? Unused 'caller' parameters:
@warning_ignore_start("unused_parameter")

#* Write to a resolve_target() variable, applying the operator:
func write_target(source: CandyEngine, caller: Object, found: Dictionary, value: Variant, operator: String = "=", context: String = "") -> bool:
	if not found.get("ok", false):
		return false

	var container = found["container"]
	var key = found["key"]
	var members: Array = found.get("members", [])

	#@ Step 1 - Read the current value (e.g. position.x):
	#? levels[i] is the copy members[i] indexes into.
	var held = _read_held(source, caller, container, key)
	var levels: Array = []
	var current = held
	for member in members:
		levels.append(current)
		current = current[member]

	var final_value = CandyValues.get_shared().calculate_value(source, source, current, value, operator)

	#@ Step 2 - Write into the copies, innermost first:
	var new_held = final_value
	for i in range(members.size() - 1, -1, -1):
		var copy = levels[i]
		if not _value_fits(source, caller, copy[members[i]], new_held):
			printerr(context, ": '", members[i], "' can't hold a ", type_string(typeof(new_held)), " → ", new_held)
			return false
		copy[members[i]] = new_held
		new_held = copy

	#@ Step 3 - Write into the container:
	match typeof(container):
		TYPE_DICTIONARY, TYPE_ARRAY:
			container[key] = new_held
		TYPE_OBJECT:
			if not _set_object_property(source, caller, container, str(key), new_held):
				return false

	#@ Step 4 - Save file variable:
	var base_call: Dictionary = found.get("base_call", {})
	if base_call.get("name", "") == "file_var":
		var file_args: Array = base_call.get("args", [])
		if file_args.is_empty():
			printerr(context, ": source.file_var() was given no file path")
			return false
		if not CandyFileVars.get_shared().save_var(source, source, str(file_args[0]), base_call["value"]):
			return false

	if OS.is_debug_build() and source.debug_prints == true:
		print("[DEBUG] ", context, " → ", key, members, " = ", final_value)
	return true

#* Current value of a resolve_target() variable:
func read_target(source: CandyEngine, caller: Object, found: Dictionary) -> Variant:
	if not found.get("ok", false):
		return null
	var current = _read_held(source, caller, found["container"], found["key"])		#/ Missing Dictionary key: null
	for member in found.get("members", []):
		current = current[member]
	return current

#* Container's value at key, before members:
func _read_held(source: CandyEngine, caller: Object, container: Variant, key: Variant) -> Variant:
	match typeof(container):
		TYPE_DICTIONARY:
			return container.get(key)
		TYPE_ARRAY:
			return container[key]
		TYPE_OBJECT:
			return container.get(str(key))
	return null

#* Resolve a field that names something (Call's Function, Emit's Signal), "globals.my_func" → Callable:
#? Null on failure (check last_failed).
func resolve_named(source: CandyEngine, caller: Object, raw: Variant, lookup_node: Node = source) -> Variant:
	var sym: String = candy_de.candy_ref_symbol
	var named = source.candy_ref.resolve_value(source, lookup_node, raw, sym)		#/ ¢ expression: evaluated to get the name
	if source.candy_ref.last_failed:
		return null
	if typeof(named) != TYPE_STRING and typeof(named) != TYPE_STRING_NAME:
		return named		#/ Callable or Signal: used as is

	var name_text := str(named).strip_edges()
	if name_text == "":
		source.candy_ref.last_failed = true
		return null
	return source.candy_ref.resolve_candy_ref(source, lookup_node, name_text, sym)

#* Whether a value-type member accepts this value:
func _value_fits(source: CandyEngine, caller: Object, existing: Variant, value: Variant) -> bool:
	if typeof(existing) in [TYPE_INT, TYPE_FLOAT]:
		return typeof(value) in [TYPE_INT, TYPE_FLOAT]
	return typeof(existing) == typeof(value)

#* Set an Object property, converting typed containers:
func _set_object_property(source: CandyEngine, caller: Object, target: Object, key: String, value: Variant) -> bool:
	target.set(key, value)
	if target.get(key) == value:
		return true

	var existing = target.get(key)

	if typeof(existing) == TYPE_ARRAY and typeof(value) == TYPE_ARRAY:
		var converted: Array = existing.duplicate()
		converted.clear()
		converted.assign(value)
		target.set(key, converted)

	elif typeof(existing) == TYPE_DICTIONARY and typeof(value) == TYPE_DICTIONARY:
		var converted: Dictionary = existing.duplicate()
		converted.clear()
		converted.assign(value)
		target.set(key, converted)

	if target.get(key) != value:
		printerr("_set_object_property(): property '", key, "' refused the value → ", value)
		return false
	return true

#* Check argument count before calling a function:
func _call_arity_ok(source: CandyEngine, caller: Object, target: Object, method: String, args: Array, current_conversation, current_block, line_index) -> bool:
	if target == null:
		return false
	for m in target.get_method_list():
		if str(m["name"]) != method:
			continue
		#% Vararg methods accept anything:
		if int(m.get("flags", 0)) & METHOD_FLAG_VARARG:
			return true
		var total: int = (m["args"] as Array).size()
		var optional: int = (m.get("default_args", []) as Array).size()
		var required: int = total - optional
		if args.size() < required or args.size() > total:
			var expected_text: String = str(required)
			if required != total:
				expected_text = str(required) + " to " + str(total)
			printerr("Conversation: ", current_conversation, " Block: ", current_block,
				" Line: ", line_index, " - Call: '", method, "' takes ",
				expected_text, " argument(s), got ", args.size())
			return false
		return true
	#% Not listed - let callv handle it:
	return true

@warning_ignore_restore("unused_parameter")
