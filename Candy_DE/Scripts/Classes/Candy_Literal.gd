#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyLiteral
extends RefCounted


#^ Constructors accepted when reading text:
#! No Object or resource constructors: reading a file must never build Objects.
const SAFE_VARIANT_CONSTRUCTORS := [
	"Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4", "Vector4i",
	"Color", "Rect2", "Rect2i", "Quaternion", "Plane", "AABB", "Basis",
	"Transform2D", "Transform3D", "Projection", "NodePath", "StringName",
	"Array", "Dictionary",
	"PackedByteArray", "PackedInt32Array", "PackedInt64Array", "PackedFloat32Array",
	"PackedFloat64Array", "PackedStringArray", "PackedVector2Array", "PackedVector3Array",
	"PackedVector4Array", "PackedColorArray",
]


#^ Shared instance:
static var _shared: CandyLiteral = null

#* Get the shared instance:
static func get_shared() -> CandyLiteral:
	if _shared == null:
		_shared = CandyLiteral.new()
	return _shared


#? 'caller' is in every signature for consistency:
@warning_ignore_start("unused_parameter")

#* Index after the closing quote:
func find_quote_end(source: CandyEngine, caller: Object, text: String, start: int) -> int:
	var quote := text[start]
	var i := start + 1
	while i < text.length():
		if text[i] == "\\":
			i += 2
			continue
		if text[i] == quote:
			return i + 1
		i += 1
	return text.length()		#/ Unclosed

#* Whether text is a safe "TypeName(...)" constructor:
func _is_constructor_text(source: CandyEngine, caller: Object, text: String) -> bool:
	if not text.ends_with(")"):
		return false
	var paren := text.find("(")
	if paren <= 0:
		return false

	var type_name := text.substr(0, paren).strip_edges()
	var bracket := type_name.find("[")
	#% Typed container, e.g. Array[int]([1, 2]):
	if bracket != -1:
		type_name = type_name.substr(0, bracket)

	return type_name in SAFE_VARIANT_CONSTRUCTORS

#* Whether text looks like var_to_str() output:
func _is_serialized_variant_text(source: CandyEngine, caller: Object, text: String) -> bool:
	if text == "":
		return false
	if text in ["null", "true", "false", "inf", "inf_neg", "-inf", "nan"]:
		return true
	if text.is_valid_int() or text.is_valid_float():
		return true
	if text.length() >= 2 and text.begins_with("\"") and text.ends_with("\""):
		return true
	if text.length() >= 3 and (text.begins_with("&\"") or text.begins_with("^\"")) and text.ends_with("\""):
		return true
	if (text.begins_with("[") and text.ends_with("]")) or (text.begins_with("{") and text.ends_with("}")):
		return true
	return _is_constructor_text(source, caller, text)

#* String or array → Dictionary:
func to_dict(source: CandyEngine, caller: Object, value: Variant) -> Dictionary:
	if typeof(value) == TYPE_STRING:
		#Ł Add outer {} implicitly:
		return _parse_dict(source, caller, "{" + value.strip_edges() + "}")
	elif typeof(value) == TYPE_ARRAY:
		var result := {}
		for item in value:
			if typeof(item) == TYPE_ARRAY and item.size() >= 2:
				result[str(item[0])] = item[1]
			else:
				result[str(item)] = null
		return result
	return value

#* String or dictionary → Array:
func to_array(source: CandyEngine, caller: Object, value: Variant) -> Array:
	if typeof(value) == TYPE_STRING:
		#Ł Add outer [] implicitly:
		return _parse_array(source, caller, "[" + value.strip_edges() + "]")
	elif typeof(value) == TYPE_DICTIONARY:
		var result := []
		for k in value.keys():
			var v = value[k]
			if v != null:
				result.append([str(k), v])
			else:
				result.append(str(k))
		return result
	return value

#* Dictionary or array → Candy text, without outer {} or []:
func to_text(source: CandyEngine, caller: Object, value: Variant) -> String:
	match typeof(value):
		TYPE_DICTIONARY:
			var parts: Array = []
			for k in value:
				var v = value[k]
				var val_str = _value_to_text(source, caller, v)
				var key_str = "\"" + str(k).replace("\"", "\\\"") + "\""
				parts.append(key_str + ": " + val_str)
			return ", ".join(parts)

		TYPE_ARRAY:
			var parts: Array = []
			for v in value:
				parts.append(_value_to_text(source, caller, v))
			return ", ".join(parts)

		_:
			return str(value)

func _value_to_text(source: CandyEngine, caller: Object, v: Variant) -> String:
	if v == null:
		return "null"

	match typeof(v):
		TYPE_STRING, TYPE_STRING_NAME:
			var escaped = v.replace("\\", "\\\\").replace("\"", "\\\"")
			return "\"" + escaped + "\""
		TYPE_BOOL:
			if v:
				return "true"
			else:
				return "false"
		TYPE_INT, TYPE_FLOAT:
			return str(v)
		TYPE_ARRAY:
			return "[" + to_text(source, caller, v) + "]"
		TYPE_DICTIONARY:
			return "{" + to_text(source, caller, v) + "}"
		#% Unquoted constructor syntax, unlike text:
		TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_VECTOR3, TYPE_VECTOR3I, TYPE_VECTOR4, TYPE_VECTOR4I, TYPE_COLOR, TYPE_RECT2, TYPE_RECT2I, TYPE_QUATERNION, TYPE_PLANE, TYPE_AABB, TYPE_BASIS, TYPE_TRANSFORM2D, TYPE_TRANSFORM3D, TYPE_PROJECTION, TYPE_NODE_PATH:
			return var_to_str(v)
		_:
			push_warning("UNSUPPORTED TYPE: " + str(typeof(v)) + "- Will be converted to literal string.")
			return "\"" + str(v) + "\""

#* Parse Candy text into a Dictionary:
func _parse_dict(source: CandyEngine, caller: Object, s: String) -> Dictionary:
	var result := {}
	s = s.strip_edges()
	if s.begins_with("{") and s.ends_with("}"):
		s = s.substr(1, s.length() - 2)

	var tokens = _split_top_level(source, caller, s)
	for token in tokens:
		token = token.strip_edges()
		if token == "":
			continue
		var kv: Array = _split_key_value(source, caller, token)
		var raw_key = kv[0].strip_edges()

		if (raw_key.begins_with('"') and raw_key.ends_with('"')) \
		or (raw_key.begins_with("'") and raw_key.ends_with("'")):
			raw_key = raw_key.substr(1, raw_key.length() - 2)

		var key = raw_key
		var val: Variant = null
		if kv.size() > 1:
			val = _parse_value(source, caller, kv[1].strip_edges())
		result[key] = val
	return result

#* Parse Candy text into an Array:
func _parse_array(source: CandyEngine, caller: Object, s: String) -> Array:
	var result: Array = []
	s = s.strip_edges()

	#Ł Check brackets:
	if not (s.begins_with("[") and s.ends_with("]")):
		printerr("Candy Parse Error: Array must start with '[' and end with ']': ", s)
		return result

	var tokens = _split_top_level(source, caller, s.substr(1, s.length() - 2))	#/ Inside only
	for token in tokens:
		token = token.strip_edges()
		if token == "":
			continue
		result.append(_parse_value(source, caller, token))

	return result

#* Parse one value (recursive):
func _parse_value(source: CandyEngine, caller: Object, text: String) -> Variant:
	text = text.strip_edges()
	if text == "":
		return null

	#¦ 1. Nested dict:
	if text.begins_with("{") and text.ends_with("}"):
		return _parse_dict(source, caller, text)
	#¦ 2. Nested array:
	if text.begins_with("[") and text.ends_with("]"):
		return _parse_array(source, caller, text)
	#¦ 3. Quoted string, always plain text:
	if (text.begins_with("'") and text.ends_with("'")) or (text.begins_with('"') and text.ends_with('"')):
		if text.length() >= 2:
			return text.substr(1, text.length() - 2).c_unescape()
	#¦ 4. Constructors, e.g. Vector2(1, 2):
	if _is_constructor_text(source, caller, text):
		var constructed = str_to_var(text)
		if constructed != null:
			return constructed
	#¦ 5. Booleans:
	if text.to_lower() == "true":
		return true
	if text.to_lower() == "false":
		return false
	#¦ 6. Null:
	if text.to_lower() == "null":
		return null
	#¦ 7. Number:
	if text.is_valid_int():
		return int(text)
	if text.is_valid_float():
		return float(text)
	#¦ 8. Fallback - raw text:
	return text

#* Split "key: value" at the first top-level colon:
func _split_key_value(source: CandyEngine, caller: Object, token: String) -> Array:
	var depth := 0
	var in_string := false
	var string_char := ""
	var escaped := false

	for i in token.length():
		var c := token[i]
		if in_string:
			if escaped:
				escaped = false
			elif c == "\\":
				escaped = true
			elif c == string_char:
				in_string = false
			continue

		match c:
			"'", "\"":
				in_string = true
				string_char = c
			"{", "[", "(":
				depth += 1
			"}", "]", ")":
				depth -= 1
			":":
				if depth == 0:
					return [token.substr(0, i), token.substr(i + 1)]		#/ [key, value]

	return [token]		#/ [key]

#* Split by top-level commas:
func _split_top_level(source: CandyEngine, caller: Object, s: String) -> Array:
	var tokens: Array = []
	var depth_curly := 0
	var depth_square := 0
	var depth_paren := 0
	var in_string := false
	var string_char := ""
	var escaped := false
	var current := ""

	for i in s.length():
		var c := s[i]
		#¦ 1. Inside a string:
		if in_string:
			current += c
			if escaped:
				escaped = false
				continue
			if c == "\\":
				escaped = true
				continue
			if c == string_char:
				in_string = false
				string_char = ""
			continue

		#¦ 2. Outside strings:
		match c:
			"'", "\"":
				in_string = true
				string_char = c
			"{":
				depth_curly += 1
			"}":
				depth_curly -= 1
			"[":
				depth_square += 1
			"]":
				depth_square -= 1
			"(":
				depth_paren += 1
			")":
				depth_paren -= 1
			",":
				if depth_curly == 0 and depth_square == 0 and depth_paren == 0:
					tokens.append(current)
					current = ""
					continue

		current += c

	if current.strip_edges() != "":
		tokens.append(current)

	return tokens

@warning_ignore_restore("unused_parameter")
