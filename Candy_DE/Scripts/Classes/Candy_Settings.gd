#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySettings
extends RefCounted


#^ Every setting, keyed by its UI element name:
#? "{mode}" / "{Mode}": the mode's settings_prefix(). "enum": the CandyEngine enum ("DialogueModes" = the mode scripts).
#? "ui": false = no UI element override (resolved before there is a UI element).
const SETTINGS := {
	#% Dialogue mode:
	"dialogue_mode": {"engine": "dialogue_mode", "actor": "DialogueMode", "line": "Dialogue_Mode", "enum": "DialogueModes", "ui": false},
	"bubbles_exempt_mode": {"engine": "bubbles_exempt_mode", "actor": "BubblesExemptMode", "line": "Bubbles_Exempt_Mode", "enum": "DialogueModes", "ui": false},

	#% Every mode:
	"enable_voice": {"engine": "enable_voice", "actor": "EnableVoice", "line": "Enable_Voice"},
	"await_voice_playback": {"engine": "await_voice_playback", "actor": "AwaitVoicePlayback", "line": "Await_Voice_Playback"},
	"text_to_speech": {"engine": "text_to_speech", "actor": "TTS", "line": "TTS"},
	"tts_advanced_fallback": {"engine": "tts_advanced_fallback", "actor": "TTSAdvancedFallback", "line": "TTS_Advanced_Fallback"},
	"llm_mode": {"engine": "llm_mode", "actor": "LLM", "line": "LLM"},
	"writing_speed": {"engine": "writing_speed", "actor": "WritingSpeed", "line": "Writing_Speed"},
	"continue_fast_speed": {"engine": "continue_fast_speed", "actor": "ContinueFastSpeed", "line": "Continue_Fast_Speed"},
	"continue_slow_speed": {"engine": "continue_slow_speed", "actor": "ContinueSlowSpeed", "line": "Continue_Slow_Speed"},
	"sync_write_speed_voice": {"engine": "sync_write_speed_voice", "actor": "SyncWriteSpeedVoice", "line": "Sync_Write_Speed_Voice"},
	"auto_advance": {"engine": "auto_advance", "actor": "AutoAdvance", "line": "Auto_Advance"},
	"auto_advance_per_character": {"engine": "auto_advance_per_character", "actor": "AutoAdvancePerCharacter", "line": "Auto_Advance_Per_Character"},
	"write_dialogue_history": {"engine": "write_dialogue_history", "actor": "WriteDialogueHistory", "line": "Write_Dialogue_History"},

	#% Per mode on the engine and actors:
	"text_bbcode": {"engine": "{mode}_text_bbcode", "actor": "{Mode}TextBBCode", "line": "Text_BBCode"},
	"speaker_bbcode": {"engine": "{mode}_speaker_bbcode", "actor": "{Mode}SpeakerBBCode", "line": "Speaker_BBCode"},
	"show_speaker": {"engine": "{mode}_show_speaker", "actor": "{Mode}ShowSpeaker", "line": "Show_Speaker"},
	"speaker_prefix": {"engine": "{mode}_speaker_prefix", "actor": "{Mode}SpeakerPrefix", "line": "Speaker_Prefix"},
	"speaker_suffix": {"engine": "{mode}_speaker_suffix", "actor": "{Mode}SpeakerSuffix", "line": "Speaker_Suffix"},
	"end_of_line_string": {"engine": "{mode}_end_of_line_string", "actor": "{Mode}EndOfLineString", "line": "End_Of_Line_String"},
	"advance_string": {"engine": "{mode}_advance_string", "actor": "{Mode}AdvanceString", "line": "Advance_String"},
	"self_clear": {"engine": "{mode}_self_clear", "actor": "{Mode}SelfClear", "line": "Self_Clear"},
	"portrait_self_clear": {"engine": "{mode}_portrait_self_clear", "actor": "{Mode}PortraitSelfClear", "line": "Portrait_Self_Clear"},
	"lexicon_mode": {"engine": "lexicon_{mode}_mode", "actor": "Lexicon{Mode}Mode", "line": "Lexicon_Mode"},
	"portrait_mode": {"engine": "{mode}_portrait_mode", "actor": "{Mode}PortraitMode", "line": "Portrait_Mode", "enum": "PortraitModes"},

	#% Chat lines:
	"line_scene": {"engine": "{mode}_line_scene", "actor": "{Mode}LineScene", "line": "Line_Scene"},
	"speaker_display": {"engine": "{mode}_speaker_display", "actor": "{Mode}SpeakerDisplay", "line": "Speaker_Display", "enum": "SpeakerDisplays"},
	"portrait_display": {"engine": "{mode}_portrait_display", "actor": "{Mode}PortraitDisplay", "line": "Portrait_Display", "enum": "PortraitDisplays"},
	"alignment": {"engine": "{mode}_alignment", "actor": "{Mode}Alignment", "line": "Alignment", "enum": "Alignments"},
	"keep_portrait_space": {"engine": "{mode}_keep_portrait_space", "actor": "{Mode}KeepPortraitSpace", "line": "Keep_Portrait_Space"},
	"keep_speaker_space": {"engine": "{mode}_keep_speaker_space", "actor": "{Mode}KeepSpeakerSpace", "line": "Keep_Speaker_Space"},
	"keep_alternate_portrait_space": {"engine": "{mode}_keep_alternate_portrait_space", "actor": "{Mode}KeepAlternatePortraitSpace", "line": "Keep_Alternate_Portrait_Space"},
	"keep_alternate_speaker_space": {"engine": "{mode}_keep_alternate_speaker_space", "actor": "{Mode}KeepAlternateSpeakerSpace", "line": "Keep_Alternate_Speaker_Space"},
}

#^ Shared instance:
static var _shared: CandySettings = null

#* Get the shared instance:
static func get_shared() -> CandySettings:
	if _shared == null:
		_shared = CandySettings.new()
	return _shared

#* Whether a value means "not set" ("null" or null):
static func is_not_set(value: Variant) -> bool:
	if value == null:
		return true
	if typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
		return str(value).strip_edges() == "null"
	return false


#? Unused 'caller' parameters:
@warning_ignore_start("unused_parameter")

#* Resolve every setting for a line's dialogue mode:
func resolve_all(source: CandyEngine, caller: Object, speech: CandySpeech, ui_node: Object) -> Dictionary:
	var resolved := {}
	for setting in SETTINGS:
		if SETTINGS[setting].get("ui", true) == false:
			continue
		var engine_name := level_name(source, caller, setting, "engine", speech.style)
		var engine_has: bool = engine_name != "" and engine_name in source
		var ui_has: bool = ui_node != null and setting in ui_node
		if not engine_has and not ui_has:
			continue
		resolved[setting] = resolve(source, caller, speech, ui_node, setting)
	return resolved		#/ {UI element name: value}

#* A setting's value for a line:
func resolve(source: CandyEngine, caller: Object, speech: CandySpeech, ui_node: Object, setting: String) -> Variant:
	return candidates(source, caller, speech, ui_node, setting)[0]

#* A resolved setting from speech.settings, else the engine's value:
func get_value(source: CandyEngine, caller: Object, speech: CandySpeech, setting: String) -> Variant:
	if speech != null and speech.settings.has(setting):
		return speech.settings[setting]
	var style := ""
	if speech != null:
		style = speech.style
	return source.get(level_name(source, caller, setting, "engine", style))

#* Every value a setting is given for a line, most specific first:
func candidates(source: CandyEngine, caller: Object, speech: CandySpeech, ui_node: Object, setting: String) -> Array:
	var entry: Dictionary = SETTINGS[setting]
	var engine_name := level_name(source, caller, setting, "engine", speech.style)
	var engine_value: Variant = null
	if engine_name != "" and engine_name in source:
		engine_value = source.get(engine_name)
	elif ui_node != null and setting in ui_node:
		engine_value = ui_node.get(setting)		#/ Developer's own mode: the UI element's value
	var enum_values := _enum_values(source, caller, str(entry.get("enum", "")))
	var values: Array = []

	#@ Step 1 - Line:
	var line_key := level_name(source, caller, setting, "line", speech.style)
	if speech.speech_data.has(line_key) and not is_not_set(speech.speech_data[line_key]):
		var line_raw: Variant = source.candy_ref.resolve_value(source, source, speech.speech_data[line_key], candy_de.candy_ref_symbol)
		if line_raw != null:
			var line_value: Variant = _convert(source, caller, line_raw, engine_value, enum_values)
			if line_value != null:
				values.append(line_value)
			else:
				_report_invalid(source, caller, "the line's '" + line_key + "'", line_raw, engine_value, enum_values)

	#@ Step 2 - Actor:
	var actor_key := level_name(source, caller, setting, "actor", speech.style)
	if actor_key != "" and candy_de.actors.has(speech.speaker_ref):
		var actor_entry: Variant = candy_de.actors[speech.speaker_ref]
		if typeof(actor_entry) == TYPE_DICTIONARY and actor_entry.get(actor_key) != null:
			var actor_raw: Variant = actor_entry[actor_key]
			var actor_value: Variant = _convert(source, caller, actor_raw, engine_value, enum_values)
			if actor_value != null:
				values.append(actor_value)
			else:
				_report_invalid(source, caller, "the '" + actor_key + "' of actor '" + str(speech.speaker_ref) + "'", actor_raw, engine_value, enum_values)

	#@ Step 3 - UI element (enable_ switch on):
	var ui_switch := "enable_" + setting
	if entry.get("ui", true) == true and ui_node != null and ui_switch in ui_node and setting in ui_node:
		if ui_node.get(ui_switch) == true:
			var ui_value: Variant = _convert(source, caller, ui_node.get(setting), engine_value, enum_values)
			if ui_value != null:
				values.append(ui_value)

	#@ Step 4 - Engine:
	values.append(engine_value)
	return values

#* A setting's name at a level ("engine", "actor", "line") for a mode:
func level_name(source: CandyEngine, caller: Object, setting: String, level: String, style: String) -> String:
	var pattern := str(SETTINGS[setting][level])
	if not pattern.contains("{mode}") and not pattern.contains("{Mode}"):
		return pattern
	var mode_script := source.get_dialogue_mode(style)
	if mode_script == null:
		return ""		#/ Per-mode setting, unknown mode
	var prefix: String = mode_script.settings_prefix()
	return pattern.replace("{mode}", prefix).replace("{Mode}", prefix.to_pascal_case())

#* A CandyEngine enum's values, by name:
func _enum_values(source: CandyEngine, caller: Object, enum_name: String) -> Dictionary:
	match enum_name:
		"DialogueModes":
			#Ł The mode scripts, each mapped to its name ({"Box" = "Box"...}):
			var modes := {}
			for mode in source.dialogue_mode_names():
				modes[mode] = mode
			return modes
		"PortraitModes":
			return CandyEngine.PortraitModes
		"SpeakerDisplays":
			return CandyEngine.SpeakerDisplays
		"PortraitDisplays":
			return CandyEngine.PortraitDisplays
		"Alignments":
			return CandyEngine.Alignments
	return {}

#* Convert a value to the engine value's type, or null:
func _convert(source: CandyEngine, caller: Object, value: Variant, like: Variant, enum_values: Dictionary) -> Variant:
	#¦ 1. Enums - name (any case) or number:
	if not enum_values.is_empty():
		if typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and value == floorf(value)):
			if enum_values.values().has(int(value)):
				return int(value)
			return null
		if typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
			var wanted := str(value).strip_edges().to_lower()
			for value_name in enum_values:
				if str(value_name).to_lower() == wanted:
					return enum_values[value_name]
		return null

	match typeof(like):
		#¦ 2. Booleans - true / false or 1 / 0:
		TYPE_BOOL:
			if typeof(value) == TYPE_BOOL:
				return value
			if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
				if value == 1:
					return true
				if value == 0:
					return false
				return null
			if typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
				var text := str(value).strip_edges().to_lower()
				if text == "true" or text == "1":
					return true
				if text == "false" or text == "0":
					return false
			return null

		#¦ 3. Whole numbers - numbers or numeric text:
		TYPE_INT:
			if typeof(value) == TYPE_INT:
				return value
			if typeof(value) == TYPE_FLOAT:
				return int(value)
			if typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
				var text := str(value).strip_edges()
				if text.is_valid_int():
					return text.to_int()
				if text.is_valid_float():
					return int(text.to_float())
			return null

		#¦ 4. Decimal numbers - numbers or numeric text:
		TYPE_FLOAT:
			if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
				return float(value)
			if typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
				var text := str(value).strip_edges()
				if text.is_valid_float():
					return text.to_float()
			return null

		#¦ 5. Text - text only (rejects a Color):
		TYPE_STRING:
			if typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
				return str(value)
			return null

	return value

#* Convert a value to the type of 'like', or null:
#? 'enum_name': CandyEngine enum name, or "".
func convert_value(source: CandyEngine, caller: Object, value: Variant, like: Variant, enum_name: String) -> Variant:
	return _convert(source, caller, value, like, _enum_values(source, caller, enum_name))

#* Describe the values a setting takes, for errors:
func expected_values(source: CandyEngine, caller: Object, like: Variant, enum_name: String) -> String:
	return _expected(source, caller, like, _enum_values(source, caller, enum_name))

#* Report a value a setting can't take:
func _report_invalid(source: CandyEngine, caller: Object, where: String, value: Variant, like: Variant, enum_values: Dictionary) -> void:
	printerr("Candy DE: ", where, " can't be ", var_to_str(value), " - expected ", _expected(source, caller, like, enum_values), ". Ignored.")

#* Describe the values a setting takes:
func _expected(source: CandyEngine, caller: Object, like: Variant, enum_values: Dictionary) -> String:
	if not enum_values.is_empty():
		return "one of " + ", ".join(PackedStringArray(enum_values.keys()))
	match typeof(like):
		TYPE_BOOL:
			return "true or false"
		TYPE_INT:
			return "a whole number"
		TYPE_FLOAT:
			return "a number"
		TYPE_STRING:
			return "text"
	return type_string(typeof(like))
