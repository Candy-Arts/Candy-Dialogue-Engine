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

	var export_format: String	= str(cr.resolve_value(engine, engine, command_value.get("Format", "json"), sym))
	var file_name: String		= str(cr.resolve_value(engine, engine, command_value.get("File", "Export"), sym))
	var custom_path: String		= str(cr.resolve_value(engine, engine, command_value.get("Path", ""), sym))
	var method: String			= str(cr.resolve_value(engine, engine, command_value.get("Method", "Overwrite"), sym))

	#@ Step 1 - Variables, as in Set ("globals.gold, globals.hp"), evaluated first with the symbol:
	var data_value = cr.resolve_value(engine, engine, command_value.get("Data", ""), sym)
	if cr.last_failed or data_value == null:
		printerr("Export: could not resolve Data → ", command_value.get("Data", ""))
		return "Continue"

	var data_str := str(data_value)

	if data_str.is_empty():
		printerr("Export: missing Data parameter.")
		return "Continue"

	#@ Step 2 - Split Data into entries:
	#? Not at commas inside brackets or quotes.
	var var_entries: Array = []
	var entry_depth := 0
	var entry_start := 0
	var entry_index := 0

	while entry_index < data_str.length():
		var entry_ch := data_str[entry_index]

		#% Skip quotes:
		if entry_ch == "\"" or entry_ch == "'":
			entry_index = CandyLiteral.get_shared().find_quote_end(engine, self, data_str, entry_index)
			continue

		if entry_ch == "(" or entry_ch == "[" or entry_ch == "{":
			entry_depth += 1
		elif entry_ch == ")" or entry_ch == "]" or entry_ch == "}":
			entry_depth -= 1
		elif entry_ch == "," and entry_depth == 0:
			var_entries.append(data_str.substr(entry_start, entry_index - entry_start))
			entry_start = entry_index + 1

		entry_index += 1

	var_entries.append(data_str.substr(entry_start))

	var export_dict := {}

	for entry in var_entries:
		entry = entry.strip_edges()
		if entry.is_empty():
			continue

		#Ł Read each variable:
		var value = cr.resolve_candy_ref(engine, engine, entry, sym)
		if cr.last_failed:
			printerr("Export: Unresolved variable → ", entry)
			continue

		#Ł Objects stored as references Import can resolve:
		export_dict[entry] = CandyFileVars.get_shared().encode_value(engine, self, value)

	#@ Step 3 - Export folder:
	var export_folder = candy_de.export_folder
	if custom_path.strip_edges() != "":
		export_folder = custom_path

	#@ Step 4 - Create local folder:
	if export_folder.begins_with("res://") or export_folder.begins_with("user://"):
		if not DirAccess.dir_exists_absolute(export_folder):
			DirAccess.make_dir_recursive_absolute(export_folder)

	#@ Step 5 - Sanitize filename and extension:
	var invalid_chars := ['<', '>', ':', '"', '/', '\\', '|', '?', '*']
	for ch in invalid_chars:
		file_name = file_name.replace(ch, "_")

	#@ Step 6 - Normalize format ("JSON", ".json" → "json"):
	var fmt = export_format.strip_edges().to_lower()
	if fmt.begins_with("."):
		fmt = fmt.substr(1)

	#% 'dialogue' → .txt:
	var file_ext: String = fmt
	if fmt == "dialogue":
		file_ext = "txt"

	var full_path := "%s/%s.%s" % [export_folder, file_name, file_ext]

	#@ Step 7 - Existing file, by Method:
	if FileAccess.file_exists(full_path):
		match method:
			"Overwrite":
				pass

			"Skip":
				if OS.is_debug_build() and engine.debug_prints == true:
					print("[DEBUG] Export: File already exists, skipping → %s" % full_path)
				return "Continue"

			"Duplicate":
				var base_name = file_name
				var counter := 1
				while FileAccess.file_exists("%s/%s(%d).%s" % [export_folder, base_name, counter, file_ext]):
					counter += 1
				full_path = "%s/%s(%d).%s" % [export_folder, base_name, counter, file_ext]

			"Timestamp":
				var t := Time.get_datetime_dict_from_system(true)
				var dt := "%04d-%02d-%02d_%02d-%02d-%02d" % [t["year"], t["month"], t["day"], t["hour"], t["minute"], t["second"]]
				full_path = "%s/%s_%s.%s" % [export_folder, file_name, dt, file_ext]
			_:
				printerr("Export: Unknown Method '%s'." % method)
				return "Continue"

	#@ Step 8 - Write, by format:
	match fmt:
		"dialogue": 	#% Data: one reference to a dialogue Dictionary:
			if export_dict.size() != 1:
				printerr("Export dialogue: Data field must contain exactly one variable reference to a dialogue dictionary.")
				return "Continue"
			var dialogue_data = export_dict.values()[0]
			if typeof(dialogue_data) != TYPE_DICTIONARY:
				printerr("Export dialogue: The referenced variable must be a Dictionary.")
				return "Continue"
			var wrapper := {
				"Meta": {
					"Exported By": "Candy Dialogue Engine",
					"Dialogue Version": "1.2",
				},
				"Dialogue": dialogue_data,
			}
			var f = FileAccess.open(full_path, FileAccess.WRITE)
			if f == null:
				printerr("Export dialogue: Failed to open file for writing → %s" % full_path)
				return "Continue"
			var ascii_hash := "\u0023"
			f.store_string(ascii_hash + " Exported By: Candy Dialogue Engine\n")
			f.store_string(ascii_hash + " Dialogue Version: 1.2\n\n")
			f.store_string(var_to_str(wrapper))
			f.close()
			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Export dialogue: Wrote dialogue to %s" % full_path)

		"json":
			var serialized := {}
			for k in export_dict.keys():
				serialized[k] = var_to_str(export_dict[k])
			var json_str = JSON.stringify(serialized, "\t")
			var file = FileAccess.open(full_path, FileAccess.WRITE)
			if file == null:
				printerr("Export: could not open file for writing → ", full_path, " (error ", FileAccess.get_open_error(), ")")
				return "Continue"
			file.store_string(json_str)
			file.close()

			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Export: Wrote %d entries to %s" % [export_dict.size(), full_path])

		"txt":
			var txt := ""
			for k in export_dict.keys():
				var v = export_dict[k]
				txt += "%s = %s\n" % [k, var_to_str(v)]
			var file = FileAccess.open(full_path, FileAccess.WRITE)
			if file == null:
				printerr("Export: could not open file for writing → ", full_path, " (error ", FileAccess.get_open_error(), ")")
				return "Continue"
			file.store_string(txt)
			file.close()

			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Export: Wrote %d entries to %s" % [export_dict.size(), full_path])

		"csv":
			var file = FileAccess.open(full_path, FileAccess.WRITE)
			if file == null:
				printerr("Export: could not open file for writing → ", full_path, " (error ", FileAccess.get_open_error(), ")")
				return "Continue"
			for k in export_dict.keys():
				file.store_csv_line([k, var_to_str(export_dict[k])])
			file.close()

			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Export: Wrote %d entries to %s" % [export_dict.size(), full_path])

		"cfg", "ini":
			var cfg = ConfigFile.new()
			for k in export_dict.keys():
				cfg.set_value(CandyFileVars.CFG_DEFAULT_SECTION, k, CandyFileVars.get_shared().cfg_write_value(engine, self, export_dict[k]))
			if cfg.save(full_path) != OK:
				printerr("Export: could not save config file → ", full_path)
				return "Continue"

			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Export: Wrote %d entries to %s" % [export_dict.size(), full_path])

		"bin":
			var file = FileAccess.open(full_path, FileAccess.WRITE)
			if file == null:
				printerr("Export: could not open file for writing → ", full_path, " (error ", FileAccess.get_open_error(), ")")
				return "Continue"
			#? full_objects off - Objects are already references.
			file.store_var(export_dict, false)
			file.close()

			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Export: Wrote %d entries to %s" % [export_dict.size(), full_path])

		"b64", "base64":
			var encoded = Marshalls.variant_to_base64(export_dict)
			var file = FileAccess.open(full_path, FileAccess.WRITE)
			if file == null:
				printerr("Export: could not open file for writing → ", full_path, " (error ", FileAccess.get_open_error(), ")")
				return "Continue"
			file.store_string(encoded)
			file.close()

			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Export: Wrote %d entries (Base64) to %s" % [export_dict.size(), full_path])

		"tres", "res":
			#? Stored in one metadata Dictionary: a plain Resource has no properties to set().
			var res := Resource.new()
			res.set_meta(CandyFileVars.CANDY_EXPORT_META, export_dict)
			var err = ResourceSaver.save(res, full_path)

			if err == OK:
				if OS.is_debug_build() and engine.debug_prints == true:
					print("[DEBUG] Export: Wrote %d entries to %s" % [export_dict.size(), full_path])
			else:
				printerr("Export: Failed to save Resource (%s)." % full_path)

		_:
			printerr("Export: Unknown format '%s'." % export_format)

	return "Continue"
