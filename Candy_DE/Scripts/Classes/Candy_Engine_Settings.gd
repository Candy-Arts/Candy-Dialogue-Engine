#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyEngineSettings
extends RefCounted


#^ Shared instance:
static var _shared: CandyEngineSettings = null

#* Get the shared instance:
static func get_shared() -> CandyEngineSettings:
	if _shared == null:
		_shared = CandyEngineSettings.new()
	return _shared


#? Unused 'caller' parameters:
@warning_ignore_start("unused_parameter")

#* Record every exported setting, for "Reset":
func record_defaults(source: CandyEngine, caller: Object) -> void:
	source.default_settings.clear()
	for property in source.get_property_list():
		var usage: int = property["usage"]
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (usage & PROPERTY_USAGE_STORAGE) != 0:
			source.default_settings[property["name"]] = _copy(source.get(property["name"]))

#* Apply an Engine command's keys to the engine's settings:
func apply_keys(source: CandyEngine, caller: Object, command_value: Variant, keys: Dictionary, context: String) -> void:
	if typeof(command_value) != TYPE_DICTIONARY:
		printerr(context, ": expected a dictionary of settings, got ", var_to_str(command_value), ".")
		return

	var cr: CandyRef = source.candy_ref
	var sym: String = candy_de.candy_ref_symbol
	var revert := resolve_revert(source, caller, command_value, context)

	for key in keys:
		if not command_value.has(key):
			continue
		#% "null" = not set:
		if CandySettings.is_not_set(command_value[key]):
			continue
		var setting: String = keys[key][0]
		var enum_name: String = keys[key][1]

		#@ Step 1 - Read value:
		var raw: Variant = cr.resolve_value(source, source, command_value[key], sym)
		if cr.last_failed:
			printerr(context, ": could not evaluate '", key, "' → ", command_value[key])
			continue

		#@ Step 2 - "Reset":
		var new_value: Variant = null
		if _is_reset(raw):
			if not source.default_settings.has(setting):
				printerr(context, ": '", key, "' can't be reset - the engine has no recorded value for '", setting, "'.")
				continue
			new_value = _copy(source.default_settings[setting])

		#@ Step 3 - Convert to the setting's type:
		else:
			if not (setting in source):
				printerr(context, ": the engine has no setting '", setting, "' for '", key, "'.")
				continue
			var current: Variant = source.get(setting)
			new_value = CandySettings.get_shared().convert_value(source, caller, raw, current, enum_name)
			if new_value == null:
				printerr(context, ": '", key, "' can't be ", var_to_str(raw), " - expected ",
						CandySettings.get_shared().expected_values(source, caller, current, enum_name), " or \"Reset\". Ignored.")
				continue

		#@ Step 4 - Apply:
		change_setting(source, caller, setting, new_value, revert)

		if OS.is_debug_build() and source.debug_prints == true:
			print("[DEBUG] ", context, ": ", setting, " = ", var_to_str(new_value), " (revert at dialogue end: ", revert, ")")

#* Change an engine setting, reverted at dialogue end or not:
#! 'value' must have the setting's type.
func change_setting(source: CandyEngine, caller: Object, setting: String, value: Variant, revert: bool) -> void:
	if revert == true:
		if not source.settings_to_revert.has(setting):
			source.settings_to_revert[setting] = _copy(source.get(setting))
	else:
		#Ł Cancel an earlier reverted change, which would undo this one:
		source.settings_to_revert.erase(setting)

	source.set(setting, value)

	#% Language is read at dialogue start - refresh now:
	if setting == "engine_language":
		source.refresh_language()

#* Revert settings changed during the dialogue:
func revert_settings(source: CandyEngine, caller: Object) -> void:
	if source.settings_to_revert.is_empty():
		return
	for setting in source.settings_to_revert:
		source.set(setting, source.settings_to_revert[setting])
		if OS.is_debug_build() and source.debug_prints == true:
			print("[DEBUG] Engine settings: ", setting, " reverted to ", var_to_str(source.settings_to_revert[setting]))
	source.settings_to_revert.clear()
	refresh_language(source, caller)

#* Set the engine's language:
func refresh_language(source: CandyEngine, caller: Object) -> void:
	if source.engine_language == "":
		source.use_language = candy_de.language
	else:
		source.use_language = source.engine_language

	if source.use_language == "":
		source.use_language = "Default"

#* Whether an Engine command's changes revert at dialogue end:
func resolve_revert(source: CandyEngine, caller: Object, command_value: Dictionary, context: String) -> bool:
	#% Missing from an older Candy_Properties.gd:
	var revert: bool = true
	var property_value = candy_de.get("revert_engine_settings")
	if property_value != null:
		revert = bool(property_value)

	if source.enable_revert_engine_settings == true:
		revert = source.revert_engine_settings

	#% "null" = not set:
	if command_value.has("Revert") and not CandySettings.is_not_set(command_value["Revert"]):
		var cr: CandyRef = source.candy_ref
		var raw: Variant = cr.resolve_value(source, source, command_value["Revert"], candy_de.candy_ref_symbol)
		var line_value: Variant = null
		if not cr.last_failed:
			line_value = CandySettings.get_shared().convert_value(source, caller, raw, true, "")
		if line_value == null:
			printerr(context, ": 'Revert' can't be ", var_to_str(command_value["Revert"]), " - expected true or false. Using ", revert, ".")
		else:
			revert = line_value

	return revert

#* Whether a value is "Reset", in any case:
func _is_reset(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING and typeof(value) != TYPE_STRING_NAME:
		return false
	return str(value).strip_edges().to_lower() == "reset"

#* Deep copy of a value:
func _copy(value: Variant) -> Variant:
	if typeof(value) == TYPE_ARRAY or typeof(value) == TYPE_DICTIONARY:
		return value.duplicate(true)
	return value
