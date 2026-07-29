#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFileVars
extends RefCounted


#^ .tres/.res metadata entry holding every non-property key:
#? Keys often aren't valid metadata names.
const CANDY_EXPORT_META := "Candy_Export"

#^ cfg/ini section for top-level keys:
const CFG_DEFAULT_SECTION := "Export"

#^ Stands for null in cfg/ini files:
#? ConfigFile.set_value() removes a key set to null.
#TODO: Change if this could collide with real string values in your project.
const CFG_NULL := "@candy_null"



#^ Shared instance:
static var _shared: CandyFileVars = null

#* Get the shared instance:
static func get_shared() -> CandyFileVars:
	if _shared == null:
		_shared = CandyFileVars.new()
	return _shared


#? Unused 'caller' parameters:
@warning_ignore_start("unused_parameter")

#* Save file_var() data back to its file:
func save_var(source: CandyEngine, caller: Object, file_path: String, file_data: Variant) -> bool:
	if typeof(file_data) != TYPE_DICTIONARY:
		printerr("save_var(): only a Dictionary can be saved to a file variable → ", file_path)
		return false

	var dir := file_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

	return write_file(source, caller, file_path, file_path.get_extension().to_lower(), file_data)

#* Read a variable file into a Dictionary, or null:
func read_file(source: CandyEngine, caller: Object, file_path: String, ext: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		printerr("read_file(): file not found → ", file_path)
		return null

	var file_data = null

	match ext:
		"json":
			var file := FileAccess.open(file_path, FileAccess.READ)
			if file == null:
				printerr("read_file(): failed to open → ", file_path)
				return null
			var content := file.get_as_text()
			file.close()

			var parsed = JSON.parse_string(content)
			if typeof(parsed) != TYPE_DICTIONARY:
				printerr("read_file(): invalid JSON → ", file_path)
				return null

			file_data = {}
			for k in parsed.keys():
				var raw = parsed[k]
				if typeof(raw) == TYPE_STRING:
					file_data[k] = text_to_value(source, caller, raw)
				else:
					file_data[k] = raw

		"txt":
			var file := FileAccess.open(file_path, FileAccess.READ)
			if file == null:
				printerr("read_file(): failed to open → ", file_path)
				return null
			var content := file.get_as_text()
			file.close()

			file_data = _parse_key_value_text(source, caller, content)

		"cfg", "ini":
			var cfg := ConfigFile.new()
			if cfg.load(file_path) != OK:
				printerr("read_file(): failed to load → ", file_path)
				return null
			file_data = {}
			for section in cfg.get_sections():
				var section_data := {}
				for key in cfg.get_section_keys(section):
					section_data[key] = cfg_read_value(source, caller, cfg.get_value(section, key))

				#% CFG_DEFAULT_SECTION keys are top-level:
				if section == CFG_DEFAULT_SECTION:
					file_data.merge(section_data)
				else:
					file_data[section] = section_data

		"bin":
			var file := FileAccess.open(file_path, FileAccess.READ)
			if file == null:
				printerr("read_file(): failed to open → ", file_path)
				return null
			file_data = file.get_var(false)
			file.close()

		"b64", "base64":
			var file := FileAccess.open(file_path, FileAccess.READ)
			if file == null:
				printerr("read_file(): failed to open → ", file_path)
				return null
			file_data = Marshalls.base64_to_variant(file.get_as_text())
			file.close()

		"tres", "res":
			var res := ResourceLoader.load(file_path)
			if res == null:
				printerr("read_file(): failed to load resource → ", file_path)
				return null
			file_data = {}

			#Ł Script-declared properties:
			for p in res.get_property_list():
				if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
					file_data[p["name"]] = res.get(p["name"])

			#Ł Individual metadata entries:
			for meta_key in res.get_meta_list():
				if str(meta_key) == CANDY_EXPORT_META:
					continue
				file_data[str(meta_key)] = res.get_meta(meta_key)

			#Ł Candy_Export Dictionary, read last so it wins:
			if res.has_meta(CANDY_EXPORT_META):
				var bundled = res.get_meta(CANDY_EXPORT_META)
				if typeof(bundled) == TYPE_DICTIONARY:
					for k in bundled.keys():
						file_data[k] = bundled[k]
				else:
					printerr("read_file(): '", CANDY_EXPORT_META, "' metadata is not a Dictionary → ", file_path)

		"csv":
			var file := FileAccess.open(file_path, FileAccess.READ)
			if file == null:
				printerr("read_file(): failed to open → ", file_path)
				return null
			file_data = {}
			while not file.eof_reached():
				var cols := file.get_csv_line()
				if cols.size() >= 2:
					file_data[cols[0].strip_edges()] = text_to_value(source, caller, cols[1].strip_edges())
			file.close()

		_:
			printerr("read_file(): unknown extension → ", ext)
			return null

	if file_data == null:		#/ Content decoded to null too
		printerr("read_file(): failed to parse → ", file_path)
		return null

	#Ł Decode Object references:
	return decode_value(source, caller, file_data)

#* Write a Dictionary back to a variable file:
func write_file(source: CandyEngine, caller: Object, file_path: String, ext: String, file_data: Dictionary) -> bool:
	#Ł Encode Object references:
	var encoded: Dictionary = encode_value(source, caller, file_data)

	match ext:
		"json":
			var serialized := {}
			for k in encoded.keys():
				serialized[k] = var_to_str(encoded[k])
			var file := FileAccess.open(file_path, FileAccess.WRITE)
			if file == null:
				printerr("write_file(): failed to open → ", file_path)
				return false
			file.store_string(JSON.stringify(serialized, "\t"))
			file.close()

		"txt":
			var txt := ""
			for k in encoded.keys():
				txt += "%s = %s\n" % [k, var_to_str(encoded[k])]
			var file := FileAccess.open(file_path, FileAccess.WRITE)
			if file == null:
				printerr("write_file(): failed to open → ", file_path)
				return false
			file.store_string(txt)
			file.close()

		"cfg", "ini":
			#Ł Dictionaries become sections; other keys go into CFG_DEFAULT_SECTION:
			var cfg := ConfigFile.new()
			for k in encoded.keys():
				if typeof(encoded[k]) == TYPE_DICTIONARY:
					for sub_key in encoded[k].keys():
						cfg.set_value(str(k), str(sub_key), cfg_write_value(source, caller, encoded[k][sub_key]))
				else:
					cfg.set_value(CFG_DEFAULT_SECTION, str(k), cfg_write_value(source, caller, encoded[k]))
			if cfg.save(file_path) != OK:
				printerr("write_file(): failed to save → ", file_path)
				return false

		"bin":
			var file := FileAccess.open(file_path, FileAccess.WRITE)
			if file == null:
				printerr("write_file(): failed to open → ", file_path)
				return false
			#? full_objects off - Objects are already references.
			file.store_var(encoded, false)
			file.close()

		"b64", "base64":
			var file := FileAccess.open(file_path, FileAccess.WRITE)
			if file == null:
				printerr("write_file(): failed to open → ", file_path)
				return false
			file.store_string(Marshalls.variant_to_base64(encoded))
			file.close()

		"tres", "res":
			#? Declared properties get the raw value, other keys go into metadata.
			var res: Resource = null

			#Ł Load the existing resource, uncached:
			if ResourceLoader.exists(file_path):
				res = ResourceLoader.load(file_path, "", ResourceLoader.CACHE_MODE_IGNORE)
			if res == null:
				res = Resource.new()

			#Ł Declared properties:
			var declared := {}
			for p in res.get_property_list():
				if p["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
					declared[str(p["name"])] = true

			#Ł Other keys go into the Candy_Export Dictionary:
			var bundled := {}
			for k in file_data.keys():
				var key := str(k)
				if declared.has(key):
					res.set(key, file_data[k])			#/ Raw: keeps Resource references
				else:
					bundled[k] = encoded[k]				#/ Encoded

			#Ł Remove individual metadata entries for keys kept in 'bundled':
			for meta_key in res.get_meta_list():
				if str(meta_key) != CANDY_EXPORT_META and file_data.has(str(meta_key)):
					res.remove_meta(meta_key)

			res.set_meta(CANDY_EXPORT_META, bundled)

			if ResourceSaver.save(res, file_path) != OK:
				printerr("write_file(): failed to save resource → ", file_path)
				return false

		"csv":
			var file := FileAccess.open(file_path, FileAccess.WRITE)
			if file == null:
				printerr("write_file(): failed to open → ", file_path)
				return false
			for k in encoded.keys():
				file.store_csv_line([str(k), var_to_str(encoded[k])])
			file.close()

		_:
			printerr("write_file(): unknown extension → ", ext)
			return false

	return true

#* Value for ConfigFile.set_value(), null → CFG_NULL:
func cfg_write_value(source: CandyEngine, caller: Object, value: Variant) -> Variant:
	if value == null:
		return CFG_NULL
	return value

#* Value read from cfg/ini, CFG_NULL → null:
func cfg_read_value(source: CandyEngine, caller: Object, value: Variant) -> Variant:
	if typeof(value) == TYPE_STRING and value == CFG_NULL:
		return null
	return value

#* Stored text → Variant:
func text_to_value(source: CandyEngine, caller: Object, raw: String) -> Variant:
	var text := raw.strip_edges()

	#% Whole serialized Variants only (str_to_var("3 apples") → 3):
	if not CandyLiteral.get_shared()._is_serialized_variant_text(source, source, text):
		return raw		#/ Not a serialized Variant: as is

	var reconstructed = str_to_var(text)
	if reconstructed != null or text == "null":
		return reconstructed
	return raw

#* Parse "key = value" text (txt format):
func _parse_key_value_text(source: CandyEngine, caller: Object, content: String) -> Dictionary:
	var joined := PackedStringArray()
	var depth := 0
	var in_quote := ""
	var escaped := false

	for ch in content:
		if escaped:
			joined.append(ch)
			escaped = false
			continue

		if in_quote != "":
			if ch == "\\":
				escaped = true
			elif ch == in_quote:
				in_quote = ""
			if ch == "\n":
				joined.append("\\n")		#/ New line inside quotes: escaped
			else:
				joined.append(ch)
			continue

		if ch == "\"" or ch == "'":
			in_quote = ch
		elif ch == "{" or ch == "[":
			depth += 1
		elif ch == "}" or ch == "]":
			depth -= 1

		if ch == "\n" and depth > 0:
			joined.append(" ")		#/ New line inside brackets: a space
		else:
			joined.append(ch)

	var result := {}
	for line in "".join(joined).split("\n", false):
		line = line.strip_edges()
		if line.is_empty() or not line.contains("="):
			continue
		var eq_pos := line.find("=")
		var key := line.substr(0, eq_pos).strip_edges()
		result[key] = text_to_value(source, caller, line.substr(eq_pos + 1).strip_edges())
	return result

#* Replace Objects in a value with references:
func encode_value(source: CandyEngine, caller: Object, value: Variant, depth: int = 0) -> Variant:
	#% Self-referencing containers:
	if depth > 32:
		printerr("Export: value nested more than 32 levels deep - truncated.")
		return null

	match typeof(value):
		TYPE_ARRAY:
			var out := []
			for item in value:
				out.append(encode_value(source, caller, item, depth + 1))
			return out

		TYPE_DICTIONARY:
			var out := {}
			for k in value.keys():
				out[k] = encode_value(source, caller, value[k], depth + 1)
			return out

		TYPE_OBJECT:
			return _encode_object_reference(source, caller, value)

	return value


#^ Prefix of stored Object references:
#TODO: Change if this could collide with real string values in your project.
const OBJECT_REF_PREFIX := "@candy_object:"

#* Object → reference string:
func _encode_object_reference(source: CandyEngine, caller: Object, obj: Object) -> Variant:
	if obj == null:
		return null

	#% Nodes - path from /root/ ("@candy_object:World/Player"):
	if obj is Node:
		if obj.is_inside_tree():
			return OBJECT_REF_PREFIX + str(obj.get_path()).trim_prefix("/root/")
		printerr("Export: node '", obj.name, "' is not in the scene tree and cannot be referenced - stored as null.")
		return null

	#% Resources - file path (a sub-resource ("::") can't be loaded on its own):
	if obj is Resource:
		var res_path: String = obj.resource_path
		if res_path != "" and not res_path.contains("::"):
			return OBJECT_REF_PREFIX + res_path
		printerr("Export: resource of type '", obj.get_class(), "' has no file path of its own and cannot be referenced - stored as null.")
		return null

	printerr("Export: object of type '", obj.get_class(), "' is neither a Node nor a Resource and cannot be referenced - stored as null.")
	return null

#* Replace references in a value with Objects:
func decode_value(source: CandyEngine, caller: Object, value: Variant, depth: int = 0) -> Variant:
	if depth > 32:
		return value

	match typeof(value):
		TYPE_ARRAY:
			var out := []
			for item in value:
				out.append(decode_value(source, caller, item, depth + 1))
			return out

		TYPE_DICTIONARY:
			var out := {}
			for k in value.keys():
				out[k] = decode_value(source, caller, value[k], depth + 1)
			return out

		TYPE_STRING:
			if value.begins_with(OBJECT_REF_PREFIX):
				var ref: String = value.substr(OBJECT_REF_PREFIX.length())
				var resolved = _decode_object_reference(source, caller, ref)
				if resolved == null:
					printerr("Import: could not resolve stored object reference → ", ref)
				return resolved

	return value

#* Reference string → Object, or null:
func _decode_object_reference(source: CandyEngine, caller: Object, ref: String) -> Variant:
	if CandyMedia.is_resource_path(ref):
		if ResourceLoader.exists(ref):
			return load(ref)
		return null

	if ref != "" and source.is_inside_tree():
		return source.get_tree().root.get_node_or_null(NodePath(ref))

	return null

@warning_ignore_restore("unused_parameter")
