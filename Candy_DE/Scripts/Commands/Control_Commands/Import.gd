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
	var cr: CandyRef = engine.candy_ref
	var sym: String = candy_de.candy_ref_symbol

	var import_format: String	= str(cr.resolve_value(engine, engine, command_value.get("Format", ""), sym))
	var file_name: String		= str(cr.resolve_value(engine, engine, command_value.get("File", "Export"), sym))
	var custom_path: String		= str(cr.resolve_value(engine, engine, command_value.get("Path", ""), sym))

	#@ Step 1 - Target Dictionary, as in Set's Variable:
	var dict_raw = command_value.get("Dictionary", "")
	var has_dict: bool = not (typeof(dict_raw) == TYPE_STRING and dict_raw.strip_edges() == "")

	#@ Step 2 - Folder:
	var import_folder = candy_de.export_folder
	if custom_path.strip_edges() != "":
		import_folder = custom_path

	#@ Step 3 - Sanitize filename and detect format:
	#? Same as Export.
	var invalid_chars := ['<', '>', ':', '"', '/', '\\', '|', '?', '*']
	for ch in invalid_chars:
		file_name = file_name.replace(ch, "_")

	#% No Format - take the file name's extension:
	if import_format == "" and file_name.rfind(".") != -1:
		import_format = file_name.get_extension().to_lower()
		file_name = file_name.get_basename()

	#@ Step 4 - Normalize format ("JSON", ".json" → "json"):
	var fmt = import_format.strip_edges().to_lower()
	if fmt.begins_with("."):
		fmt = fmt.substr(1)

	#@ Step 5 - Build the path:
	#% 'dialogue' → .txt:
	var full_path: String
	if fmt == "dialogue":
		full_path = import_folder.path_join(file_name + ".txt")
	else:
		full_path = "%s/%s.%s" % [import_folder, file_name, fmt]

	#% File exists:
	if not FileAccess.file_exists(full_path):
		printerr("Import: File not found → %s" % full_path)
		return "Continue"

	#@ Step 6 - Decode, by format:
	var imported_data := {}

	if fmt == "dialogue":
		#? As in load_scripted_dialogue():
		var file = FileAccess.open(full_path, FileAccess.READ)
		if file == null:
			printerr("Import: could not open file → ", full_path, " (error ", FileAccess.get_open_error(), ")")
			return "Continue"
		var content: String = file.get_as_text()
		file.close()

		#Ł Clean syntax:
		var text_data := engine._clean_dialogue_source(content)

		#Ł Parse:
		var expr := Expression.new()
		if expr.parse(text_data) != OK:
			printerr("Import dialogue: Failed to parse → %s" % full_path)
			return "Continue"
		var result = expr.execute()
		if expr.has_execute_failed() or typeof(result) != TYPE_DICTIONARY:
			printerr("Import dialogue: Failed to evaluate → %s" % full_path)
			return "Continue"

		#Ł Unwrap:
		if result.has("Dialogue"):
			imported_data = result["Dialogue"]
		else:
			imported_data = result

	else:
		#% Other formats - file_var()'s reader (restores Object references):
		if not (fmt in CandyEngine.FILE_VAR_EXTENSIONS):
			printerr("Import: Unknown format '%s'." % import_format)
			return "Continue"

		var read_data = CandyFileVars.get_shared().read_file(engine, self, full_path, fmt)
		if read_data == null:
			printerr("Import: could not read → ", full_path)
			return "Continue"
		if typeof(read_data) != TYPE_DICTIONARY:
			printerr("Import: '%s' does not contain a Dictionary (got %s)." % [full_path, type_string(typeof(read_data))])
			return "Continue"
		imported_data = read_data

	#% 'dialogue' needs a Dictionary:
	if fmt == "dialogue" and not has_dict:
		printerr("Import dialogue: A Dictionary reference must be provided.")
		return "Continue"

	#¦ 1. Into the target Dictionary:
	if has_dict:
		var found := cr.resolve_target(engine, engine, dict_raw, sym)
		if not found["ok"]:
			printerr("Import: invalid target reference → %s" % str(dict_raw))
			return "Continue"
		var target_dict = CandyTargets.get_shared().read_target(engine, self, found)
		if typeof(target_dict) != TYPE_DICTIONARY:
			printerr("Import: Target reference is not a dictionary → %s" % str(dict_raw))
			return "Continue"
		for k in imported_data.keys():
			target_dict[k] = imported_data[k]

		#Ł Write back (runs setters, saves file_var() targets):
		if not CandyTargets.get_shared().write_target(engine, self, found, target_dict, "=", "Import"):
			printerr("Import: failed to write target dictionary → %s" % str(dict_raw))
			return "Continue"

		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] Import: Copied %d entries into %s" % [imported_data.size(), str(dict_raw)])
	else:
		#¦ 2. Into each key's variable:
		for path_key in imported_data.keys():
			var value = imported_data[path_key]
			var found_key := cr.resolve_target(engine, engine, path_key, sym)
			if not found_key["ok"]:
				printerr("Import: invalid reference → %s" % path_key)
				continue
			if not CandyTargets.get_shared().write_target(engine, self, found_key, value, "=", "Import"):
				printerr("Import: failed to write → %s" % path_key)
				continue
			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Import: Set %s = %s" % [path_key, str(value)])

	return "Continue"
