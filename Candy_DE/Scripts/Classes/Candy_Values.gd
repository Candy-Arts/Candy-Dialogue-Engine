#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyValues
extends RefCounted


#^ Shared instance:
static var _shared: CandyValues = null

#* Get the shared instance:
static func get_shared() -> CandyValues:
	if _shared == null:
		_shared = CandyValues.new()
	return _shared


#? 'caller' is in every signature for consistency:
@warning_ignore_start("unused_parameter")

#* Evaluate an If / Elif / While condition (1, 0 or CandyEngine.IF_ERROR):
func evaluate_condition(source: CandyEngine, caller: Object, raw: Variant, context: String) -> int:
	var sym: String = candy_de.candy_ref_symbol
	if typeof(raw) == TYPE_STRING:
		if raw.strip_edges() == "":
			printerr(context, ": the condition is empty.")
			return CandyEngine.IF_ERROR
		#% Plain text refused (a non-empty String always passes):
		if not raw.begins_with(sym):
			printerr(context, ": the condition is plain text. Start it with ", sym, " to evaluate it → ", raw)
			return CandyEngine.IF_ERROR

	var value = source.candy_ref.resolve_value(source, source, raw, sym)
	if source.candy_ref.last_failed:
		printerr(context, ": could not evaluate the condition → ", raw)
		return CandyEngine.IF_ERROR

	if value:
		return 1
	return 0

#* Compute a variable's new value, without setting it:
#! Test operators before relying on them, and check their code below.
#TODO Add your own operators here.
#? current: value before the change. value: the operand.
func calculate_value(source: CandyEngine, caller: Object, current: Variant, value: Variant, op: String) -> Variant:
	#% Null current → 0 for arithmetic:
	if current == null and op in ["+=", "-=", "*=", "×=", "/=", "÷=", "//=", "%=", "^=", "**=", "pow"]:
		current = 0
		printerr("calculate_value(): '", op, "' is null - defaulting to 0.")

	match op:
		#Ł BASIC ASSIGNMENT:
		"=":
			return value

		#Ł ARITHMETIC OPERATIONS:
		"+=":
			#% Two Strings concatenate:
			if typeof(current) == TYPE_STRING and typeof(value) == TYPE_STRING:
				return current + value
			#% One String - add if numeric:
			if typeof(current) == TYPE_STRING or typeof(value) == TYPE_STRING:
				if _both_numeric(source, caller, current, value):
					return _as_number(source, caller, current) + _as_number(source, caller, value)
				printerr("calculate_value: '+=' cannot mix %s and %s" % [type_string(typeof(current)), type_string(typeof(value))])
				return current
			#% Two Arrays concatenate:
			if typeof(current) == TYPE_ARRAY and typeof(value) == TYPE_ARRAY:
				return current + value
			if not _both_numeric(source, caller, current, value):
				printerr("calculate_value: '+=' expects two numbers, two strings or two arrays (got %s and %s)" % [type_string(typeof(current)), type_string(typeof(value))])
				return current
			return _as_number(source, caller, current) + _as_number(source, caller, value)
		"-=":
			if not _both_numeric(source, caller, current, value):
				printerr("calculate_value: '-=' expects numbers (got %s and %s)" % [type_string(typeof(current)), type_string(typeof(value))])
				return current
			return _as_number(source, caller, current) - _as_number(source, caller, value)
		"*=", "×=":
			if not _both_numeric(source, caller, current, value):
				printerr("calculate_value: '*=' expects numbers (got %s and %s)" % [type_string(typeof(current)), type_string(typeof(value))])
				return current
			return _as_number(source, caller, current) * _as_number(source, caller, value)
		"/=", "÷=":
			if not _both_numeric(source, caller, current, value):
				printerr("calculate_value: '/=' expects numbers (got %s and %s)" % [type_string(typeof(current)), type_string(typeof(value))])
				return current
			if float(value) == 0.0:
				printerr("calculate_value: division by zero")
				return current
			#Ł Float division ('//=' floors):
			return float(current) / float(value)
		"//=":
			if not _both_numeric(source, caller, current, value):
				printerr("calculate_value: '//=' expects numbers (got %s and %s)" % [type_string(typeof(current)), type_string(typeof(value))])
				return current
			var num_a = _as_number(source, caller, current)
			var num_b = _as_number(source, caller, value)
			if float(num_b) == 0.0:
				printerr("calculate_value: division by zero")
				return current
			return int(floor(float(num_a) / float(num_b)))
		"%=":
			if not _both_numeric(source, caller, current, value):
				printerr("calculate_value: '%=' expects numbers (got %s and %s)" % [type_string(typeof(current)), type_string(typeof(value))])
				return current
			var num_a = _as_number(source, caller, current)
			var num_b = _as_number(source, caller, value)
			if float(num_b) == 0.0:
				printerr("calculate_value: modulo by zero")
				return current
			#% Integer modulo only for two ints:
			if typeof(num_a) == TYPE_FLOAT or typeof(num_b) == TYPE_FLOAT:
				return fmod(float(num_a), float(num_b))
			return num_a % num_b
		"^=", "**=", "pow":
			if not _both_numeric(source, caller, current, value):
				printerr("calculate_value: '^=' expects numbers (got %s and %s)" % [type_string(typeof(current)), type_string(typeof(value))])
				return current
			return pow(_as_number(source, caller, current), _as_number(source, caller, value))

		#Ł STRING OPERATIONS:
		"strip_edges":
			var target = _value_or_current(source, caller, value, current)
			return str(target).strip_edges()
		"to_upper":
			var target = _value_or_current(source, caller, value, current)
			return str(target).to_upper()
		"to_lower":
			var target = _value_or_current(source, caller, value, current)
			return str(target).to_lower()
		"replace":
			if typeof(value) == TYPE_ARRAY and value.size() >= 2:
				return str(current).replace(str(value[0]), str(value[1]))
			return str(current)
		"substr":
			if typeof(value) == TYPE_ARRAY and value.size() >= 2:
				return str(current).substr(value[0], value[1])
			return str(current)
		"split":
			if typeof(current) == TYPE_STRING and typeof(value) == TYPE_STRING:
				return current.split(value)
			return current
		"split_to_array":
			if typeof(current) == TYPE_STRING and typeof(value) == TYPE_STRING:
				return Array(current.split(value))
			return current
		"join":
			#? Array has no join().
			if typeof(value) == TYPE_STRING:
				if typeof(current) == TYPE_ARRAY:
					var parts := PackedStringArray()
					for item in current:
						parts.append(str(item))
					return value.join(parts)
				if typeof(current) == TYPE_PACKED_STRING_ARRAY:
					return value.join(current)
			return current
		"path_join":
			if typeof(current) == TYPE_STRING and typeof(value) == TYPE_STRING:
				return current.path_join(value)
			return current

		#Ł ARRAY OPERATIONS:
		"append":
			if value == null:
				printerr("calculate_value: 'append' requires a value.")
				return current
			if typeof(current) == TYPE_ARRAY:
				var arr = current.duplicate()
				arr.append(value)
				return arr
			return current
		"append_first":
			if typeof(current) == TYPE_ARRAY:
				var arr = current.duplicate()
				arr.insert(0, value)
				return arr
			return current
		"insert":
			if typeof(current) == TYPE_ARRAY and typeof(value) == TYPE_ARRAY and value.size() >= 2:
				var arr = current.duplicate()
				arr.insert(value[0], value[1])
				return arr
			return current
		"erase":
			if typeof(current) == TYPE_ARRAY:
				var arr = current.duplicate()
				arr.erase(value)
				return arr
			return current
		"remove_at":
			if typeof(current) == TYPE_ARRAY and value is int and value >= 0 and value < current.size():
				var arr = current.duplicate()
				arr.remove_at(value)
				return arr
			return current
		"clear":
			var target = _value_or_current(source, caller, value, current)
			if typeof(target) == TYPE_ARRAY:
				return []
			elif typeof(target) == TYPE_DICTIONARY:
				return {}
			return current
		"slice":
			if typeof(current) == TYPE_ARRAY and typeof(value) == TYPE_ARRAY and value.size() >= 2:
				return current.slice(value[0], value[1])
			return current
		"reverse":
			var target = _value_or_current(source, caller, value, current)
			if typeof(target) == TYPE_ARRAY:
				var arr = target.duplicate()
				arr.reverse()
				return arr
			return current
		"sort":
			var target = _value_or_current(source, caller, value, current)
			if typeof(target) == TYPE_ARRAY:
				var arr = target.duplicate()
				arr.sort()
				return arr
			return current
		"shuffle":
			var target = _value_or_current(source, caller, value, current)
			if typeof(target) == TYPE_ARRAY:
				var arr = target.duplicate()
				arr.shuffle()
				return arr
			return current
		"unique":
			var target = _value_or_current(source, caller, value, current)
			if typeof(target) == TYPE_ARRAY:
				var arr = []
				for item in target:
					if item not in arr:
						arr.append(item)
				return arr
			return current

		#Ł DICTIONARY OPERATIONS:
		"merge":
			if typeof(current) == TYPE_DICTIONARY and typeof(value) == TYPE_DICTIONARY:
				var merged = current.duplicate()
				for k in value.keys():
					merged[k] = value[k]
				return merged
			return current
		"get":	#/ value: key, or [key, default]
			if typeof(current) == TYPE_DICTIONARY:
				if typeof(value) == TYPE_STRING:
					return current.get(value)
				elif typeof(value) == TYPE_ARRAY and value.size() == 2:
					return current.get(value[0], value[1])
				printerr("calculate_value: 'get' expects a string or array of two values")
				return null
			return null
		"set_key":
			if typeof(current) == TYPE_DICTIONARY and typeof(value) == TYPE_ARRAY and value.size() >= 2:
				var dict = current.duplicate()
				dict[value[0]] = value[1]
				return dict
			return current
		"duplicate":
			if value == null:
				printerr("calculate_value: 'duplicate' requires a value.")
				return current
			if value is Array or typeof(value) == TYPE_DICTIONARY:
				return value.duplicate(false)	#/ shallow copy
			return value
		"deep_duplicate":
			if value == null:
				printerr("calculate_value: 'sdeep-duplicate' requires a value.")
				return current
			if value is Array or typeof(value) == TYPE_DICTIONARY:
				return value.duplicate(true)	#/ deep copy
			return value

		#Ł TYPE & CONVERSION HELPERS:
		"typeof":
			var target = _value_or_current(source, caller, value, current)
			return typeof(target)
		"type_string":
			var target = _value_or_current(source, caller, value, current)
			return type_string(typeof(target))
		"is_array":
			var target = _value_or_current(source, caller, value, current)
			return typeof(target) == TYPE_ARRAY
		"is_dict":
			var target = _value_or_current(source, caller, value, current)
			return typeof(target) == TYPE_DICTIONARY
		"is_object":
			var target = _value_or_current(source, caller, value, current)
			return target is Object
		"is_nan":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'is_nan' expects a number")
				return current
			return is_nan(float(target))
		"is_inf":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'is_inf' expects a number")
				return current
			return is_inf(float(target))
		"to_int":
			var target = _value_or_current(source, caller, value, current)
			return int(target)
		"to_float":
			var target = _value_or_current(source, caller, value, current)
			return float(target)
		"to_string":
			var target = _value_or_current(source, caller, value, current)
			return str(target)
		"to_bool":
			var target = _value_or_current(source, caller, value, current)
			return _as_bool(source, caller, target)
		"toggle_bool":
			var target = _value_or_current(source, caller, value, current)
			return not _as_bool(source, caller, target)
		"var_to_str":
			var target = _value_or_current(source, caller, value, current)
			return var_to_str(target)
		"str_to_var":
			var target = _value_or_current(source, caller, value, current)
			return str_to_var(str(target))
		"json_to_str":
			var target = _value_or_current(source, caller, value, current)
			return JSON.stringify(target)
		"str_to_json":
			var target = _value_or_current(source, caller, value, current)
			return JSON.parse_string(str(target))
		"var_to_bytes":
			var target = _value_or_current(source, caller, value, current)
			return var_to_bytes(target)
		"bytes_to_var":
			var target = _value_or_current(source, caller, value, current)
			if typeof(target) == TYPE_PACKED_BYTE_ARRAY:
				return bytes_to_var(target)
			printerr("calculate_value: 'bytes_to_var' expects a PackedByteArray")
			return current

		#Ł MATH FUNCTIONS:
		"abs":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'abs' expects a number")
				return current
			return abs(target)
		"floor":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'floor' expects a number")
				return current
			if typeof(target) == TYPE_INT:
				return target
			return floor(target)
		"ceil":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'ceil' expects a number")
				return current
			if typeof(target) == TYPE_INT:
				return target
			return ceil(target)
		"round":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'round' expects a number")
				return current
			if typeof(target) == TYPE_INT:
				return target
			return round(target)
		"sqrt", "root":		#/ Square root
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'sqrt' expects a number")
				return current
			if target < 0:
				printerr("calculate_value: sqrt of negative value")
				return current
			return sqrt(target)
		"sign":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'sign' expects a number")
				return current
			return sign(target)
		"sin":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'sin' expects a number")
				return current
			return sin(target)
		"cos":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'cos' expects a number")
				return current
			return cos(target)
		"tan":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'tan' expects a number")
				return current
			return tan(target)
		"asin":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'asin' expects a number")
				return current
			#% Outside [-1, 1] gives NaN:
			if target < -1 or target > 1:
				printerr("calculate_value: asin expects a value between -1 and 1")
				return current
			return asin(target)
		"acos":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'acos' expects a number")
				return current
			#% Outside [-1, 1] gives NaN:
			if target < -1 or target > 1:
				printerr("calculate_value: acos expects a value between -1 and 1")
				return current
			return acos(target)
		"atan":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'atan' expects a number")
				return current
			return atan(target)
		"deg_to_rad":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'deg_to_rad' expects a number")
				return current
			return deg_to_rad(target)
		"rad_to_deg":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'rad_to_deg' expects a number")
				return current
			return rad_to_deg(target)
		"log":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'log' expects a number")
				return current
			if target <= 0:
				printerr("calculate_value: log of non-positive value")
				return current
			return log(target)
		"log10":
			var target = _as_number(source, caller, _value_or_current(source, caller, value, current))
			if target == null:
				printerr("calculate_value: 'log10' expects a number")
				return current
			if target <= 0:
				printerr("calculate_value: log of non-positive value")
				return current
			return log(target) / log(10.0)
		"log_base":
			if typeof(value) in [TYPE_FLOAT, TYPE_INT] and value != 1:
				var target = _as_number(source, caller, current)
				if target == null:
					printerr("calculate_value: 'log_base' expects a number")
					return current
				if target <= 0:
					printerr("calculate_value: log of non-positive value")
					return current
				#% Base must be positive:
				if value <= 0:
					printerr("calculate_value: log base must be positive")
					return current
				return log(target) / log(value)
			return current
		"clamp":
			if typeof(value) == TYPE_ARRAY and value.size() >= 2:
				#Ł Coerce if all numeric, else clamp as is (e.g. strings):
				var nums = _as_numbers(source, caller, [current, value[0], value[1]])
				if nums != null:
					return clamp(nums[0], nums[1], nums[2])
				return clamp(current, value[0], value[1])
			return current
		"min":
			if typeof(value) == TYPE_ARRAY and value.size() > 0:
				return value.min()
			var nums = _as_numbers(source, caller, [current, value])
			if nums != null:
				return min(nums[0], nums[1])
			return min(current, value)  #/ fallback for single value
		"max":
			if typeof(value) == TYPE_ARRAY and value.size() > 0:
				return value.max()
			var nums = _as_numbers(source, caller, [current, value])
			if nums != null:
				return max(nums[0], nums[1])
			return max(current, value)  #/ fallback for single value
		"lerp":
			if typeof(value) == TYPE_ARRAY and value.size() >= 2:
				#% Numbers only:
				var nums = _as_numbers(source, caller, [current, value[0], value[1]])
				if nums == null:
					printerr("calculate_value: 'lerp' expects numbers")
					return current
				return lerp(float(nums[0]), float(nums[1]), float(nums[2]))
			return current
		"wrap":
			if typeof(value) == TYPE_ARRAY and value.size() >= 2:
				#% Keep ints as ints (wrapf gives floats):
				if typeof(current) == TYPE_INT and typeof(value[0]) == TYPE_INT and typeof(value[1]) == TYPE_INT:
					return wrapi(current, value[0], value[1])
				return wrapf(float(current), float(value[0]), float(value[1]))
			return current

		#Ł RANDOM & UTILITY:
		"randi", "rand_i":
			if value != null:
				if typeof(value) == TYPE_ARRAY and value.size() >= 2:
					push_warning("Operator 'randi' was used with a range. Defaulting to 'randi_range' for backward compatibility. You should change to 'randi_range' in your dialogues.")
					return randi_range(int(value[0]), int(value[1]))
				return current
			return randi()
		"randi_range", "rand_i_range":
			var target = _value_or_current(source, caller, value, current)
			if typeof(target) == TYPE_ARRAY and target.size() >= 2:
				return randi_range(int(target[0]), int(target[1]))
			return current
		"randf", "rand_f":
			if value != null:
				if typeof(value) == TYPE_ARRAY and value.size() >= 2:
					push_warning("Operator 'randf' was used with a range. Defaulting to 'randf_range' for backward compatibility. You should change to 'randf_range' in your dialogues.")
					return randf_range(float(value[0]), float(value[1]))
				return current
			return randf()
		"randf_range", "rand_f_range":
			var target = _value_or_current(source, caller, value, current)
			if typeof(target) == TYPE_ARRAY and target.size() >= 2:
				return randf_range(float(target[0]), float(target[1]))
			return current
		"rand_pick":
			var target = _value_or_current(source, caller, value, current)
			if typeof(target) == TYPE_ARRAY and target.size() > 0:
				return target[randi() % target.size()]
			return current

		#Ł NODES:
		"get_node":
			if typeof(value) == TYPE_STRING:
				return source.get_node(value)
			return null
		"get_node_or_null":
			if typeof(value) == TYPE_STRING:
				var found := source.get_node_or_null(value)
				if found == null:
					return null
				return found
			return null

		#Ł CANDY SPECIALS:
		"candy_to_dict":
			if typeof(value) == TYPE_STRING or typeof(value) == TYPE_ARRAY:
				return CandyLiteral.get_shared().to_dict(source, source, value)
			return value
		"candy_to_array":
			if typeof(value) == TYPE_STRING or typeof(value) == TYPE_DICTIONARY:
				return CandyLiteral.get_shared().to_array(source, source, value)
			return value
		"candy_to_string":
			if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
				return CandyLiteral.get_shared().to_text(source, source, value)
			return str(value)

		#Ł FALLBACK:
		_:
			push_error("Unknown operator: " + op)
			return current

#* value, or current if value is null:
func _value_or_current(source: CandyEngine, caller: Object, value: Variant, current: Variant) -> Variant:
	if value != null:
		return value
	return current

#* Value as a number, or null:
func _as_number(source: CandyEngine, caller: Object, target: Variant) -> Variant:
	match typeof(target):
		TYPE_INT, TYPE_FLOAT:
			return target
		TYPE_BOOL:
			return int(target)
		TYPE_STRING:
			var text := str(target).strip_edges()
			if text.is_valid_int():
				return int(text)
			if text.is_valid_float():
				return float(text)
	return null

#* Value as a bool:
func _as_bool(source: CandyEngine, caller: Object, target: Variant) -> bool:
	#¦ 1. Text by meaning (bool() throws on Strings and containers):
	if typeof(target) == TYPE_STRING:
		var text := str(target).strip_edges().to_lower()
		if text in ["", "0", "false", "no", "off"]:
			return false
		if text.is_valid_float():
			return float(text) != 0.0
		return true

	#¦ 2. The rest by truthiness:
	if target:
		return true
	return false

#* Values as numbers, or null if any isn't numeric:
func _as_numbers(source: CandyEngine, caller: Object, values: Array) -> Variant:
	var out := []
	for v in values:
		var n = _as_number(source, caller, v)
		if n == null:
			return null
		out.append(n)
	return out

#* Whether both values are numeric:
func _both_numeric(source: CandyEngine, caller: Object, a: Variant, b: Variant) -> bool:
	return _as_number(source, caller, a) != null and _as_number(source, caller, b) != null

@warning_ignore_restore("unused_parameter")
