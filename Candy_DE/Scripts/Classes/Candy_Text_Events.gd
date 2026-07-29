#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyTextEvents
extends RefCounted


#^ Marker stand-in (Unicode noncharacter):
#? Spoken_Line's escaped-symbol stand-ins use U+FDD0 to U+FDD3.
const MARKER := "﷔"

#^ Line and entry event keys:
const EVENTS_KEY := "Text_Events"
const ENTRY_EVENTS_KEY := "Events"

#^ Commands always allowed (no-ops):
const ALWAYS_ALLOWED: Array[String] = ["comment", "lm"]

#^ Default text_event_commands:
const DEFAULT_COMMANDS: Array[String] = [
	"Set", "Flag", "Call", "Emit", "Await", "Name", "Role", "Disposition", "Export", "Import",
	"If", "Elif", "Else", "For", "While",
	"Wait", "Custom", "Mouse", "UI_Z",
	"Media_*", "Effect_*", "BG_*", "VN_*", "CS_*",
	"Write_Speed", "Write_Pause", "Line_Portrait",
]

#^ Left out of skipped events:
#? Wait commands (and names ending in WAIT_SUFFIX):
const WAIT_COMMANDS: Array[String] = ["wait", "await", "write_pause"]
const WAIT_SUFFIX := "_wait"
#? Keys set to "0":
const WAIT_KEYS: Array[String] = ["Wait_Loops", "Wait_Time"]
#? Body key of condition and loop commands:
const BODY_KEY := "Commands"


#^ Shared instance:
static var _shared: CandyTextEvents = null

#* Get the shared instance:
static func get_shared() -> CandyTextEvents:
	if _shared == null:
		_shared = CandyTextEvents.new()
	return _shared


#? Unused 'caller' parameters:
@warning_ignore_start("unused_parameter")

#& Markers:
#* Replace markers with MARKER:
func mark_text(source: CandyEngine, caller: Object, text: String) -> Dictionary:
	var start_tag := _symbol("text_event_start_symbol")
	var end_tag := _symbol("text_event_end_symbol")
	var names: Array = []
	if start_tag == "" or end_tag == "":
		return {"text": text, "names": names}

	var result := ""
	var i := 0
	while i < text.length():
		#¦ 1. Doubled start symbol is literal:
		if text.substr(i, start_tag.length() * 2) == start_tag + start_tag:
			result += start_tag
			i += start_tag.length() * 2
			continue

		#¦ 2. Doubled end symbol is literal:
		if end_tag != start_tag and text.substr(i, end_tag.length() * 2) == end_tag + end_tag:
			result += end_tag
			i += end_tag.length() * 2
			continue

		#¦ 3. A marker:
		if text.substr(i, start_tag.length()) == start_tag:
			var inner_start := i + start_tag.length()
			var end_idx := text.find(end_tag, inner_start)
			if end_idx != -1:
				names.append(text.substr(inner_start, end_idx - inner_start).strip_edges())
				result += MARKER
				i = end_idx + end_tag.length()
				continue

		result += text[i]
		i += 1
	return {"text": result, "names": names}

#* Remove markers from a text:
func strip_markers(source: CandyEngine, caller: Object, text: String) -> String:
	return str(mark_text(source, caller, text)["text"]).replace(MARKER, "")

#* Remove MARKER stand-ins, and the lexicon escape ones (CandyWriting):
func strip_stand_ins(source: CandyEngine, caller: Object, text: String) -> String:
	return CandyWriting.get_shared().strip_lexicon_escapes(source, caller, text.replace(MARKER, ""))

#* Resolve each marker's event, in marker order:
func resolve(source: CandyEngine, caller: Object, speech_data: Dictionary, chosen_variation: String, names: Array, context: String) -> Array:
	var entries: Array = []
	if names.is_empty():
		return entries

	var line_table = speech_data.get(EVENTS_KEY, {})
	if typeof(line_table) != TYPE_DICTIONARY:
		printerr("Candy DE - Text events: ", EVENTS_KEY, " should be a Dictionary of variations, not '", str(line_table), "'", context)
		line_table = {}

	var shared_table = candy_de.get("text_events")
	if typeof(shared_table) != TYPE_DICTIONARY:
		shared_table = {}

	#@ Step 1 - Matching variation entries, least specific first:
	var line_matches := _variation_matches(line_table, chosen_variation)
	var shared_matches := _variation_matches(shared_table, chosen_variation)

	#@ Step 2 - Each name's event, line first:
	for event_name in names:
		var event := _find_event(line_table, line_matches, event_name, true)
		if event.is_empty():
			event = _find_event(shared_table, shared_matches, event_name, false)

		if event.is_empty():
			printerr("Candy DE - Text events: no event named '", event_name, "' for variation '", chosen_variation, "', in the line or in the text_events table - its marker runs nothing", context)

		entries.append({"name": event_name, "event": event, "prefix": "", "placed": false, "done": false})		#/ Unfound too
	return entries

#* Matching variation keys, least specific first:
func _variation_matches(table: Dictionary, chosen_variation: String) -> Array:
	var matches: Array = []
	var exact_matches: Array = []
	for variation_key in table.keys():
		var vk := str(variation_key)
		if vk == "*":
			matches.append(variation_key)
		elif vk.ends_with("*"):
			if chosen_variation.begins_with(vk.substr(0, vk.length() - 1)):
				matches.append(variation_key)
		elif vk == chosen_variation:
			matches.append(variation_key)
			exact_matches.append(variation_key)

	#Ł "*", then "Prefix*" by length, then the exact name:
	matches.sort_custom(func(a, b):
		var la: int = str(a).trim_suffix("*").length()
		var lb: int = str(b).trim_suffix("*").length()
		if la == lb:
			return str(a) < str(b)
		return la < lb
	)
	for ex in exact_matches:
		matches.erase(ex)
		matches.append(ex)
	return matches

#* A name's event in the most specific match, or {}:
func _find_event(table: Dictionary, matches: Array, event_name: String, wrapped: bool) -> Dictionary:
	for i in range(matches.size() - 1, -1, -1):
		var events = table[matches[i]]
		if wrapped:
			events = _entry_events(events)		#/ Line entries: events under "Events"
		if typeof(events) == TYPE_DICTIONARY and events.has(event_name) and typeof(events[event_name]) == TYPE_DICTIONARY:
			return events[event_name]
	return {}

#* A line entry's events, or {}:
func _entry_events(entry: Variant) -> Dictionary:
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	var events = entry.get(ENTRY_EVENTS_KEY, {})
	if typeof(events) != TYPE_DICTIONARY:
		return {}
	return events

#* Remove markers from a display's final text, storing each event's "prefix":
func place_events(source: CandyEngine, caller: Object, speech: CandySpeech, text: String) -> String:
	#? Called on every display's final text, after the lexicon: the lexicon escapes go too.
	text = CandyWriting.get_shared().strip_lexicon_escapes(source, caller, text)
	var clean := ""
	var index := 0
	var pos := text.find(MARKER)
	var from := 0
	#? A lost marker's event stays unplaced (runs when writing ends).
	while pos != -1:
		clean += text.substr(from, pos - from)
		if speech != null and index < speech.text_events.size():
			speech.text_events[index]["prefix"] = clean
			speech.text_events[index]["placed"] = true
		index += 1
		from = pos + MARKER.length()
		pos = text.find(MARKER, from)
	clean += text.substr(from)
	return clean

#* Set each placed event's "position", in the label's characters:
func schedule(source: CandyEngine, caller: Object, speech: CandySpeech, text_node: Node) -> Array:
	var scheduled: Array = []
	if speech == null or speech.text_events.is_empty() or text_node == null:
		return scheduled
	if not ("text" in text_node) or not text_node.has_method("get_total_character_count"):
		return scheduled

	var saved_text: String = text_node.text
	var saved_visible: int = text_node.visible_characters
	for entry in speech.text_events:
		if entry["placed"] != true or entry["done"] == true:
			continue
		text_node.text = entry["prefix"]
		entry["position"] = text_node.get_total_character_count()
		scheduled.append(entry)
	text_node.text = saved_text
	text_node.visible_characters = saved_visible
	return scheduled		#/ Events not run yet


#& Running:
#* Run a text event's lines:
func run_event(source: CandyEngine, caller: Object, speech: CandySpeech, entry: Dictionary, voice_player = null) -> void:
	if entry["done"] == true:
		return
	entry["done"] = true

	var event: Dictionary = entry["event"]
	var lines = event.get("Lines", [])
	if typeof(lines) != TYPE_ARRAY or lines.is_empty():
		return

	var skipping: bool = speech.write_skipped
	if skipping:
		if not _flag(source, caller, event, "Run_On_Skip", true, entry):
			return
		lines = without_waits(source, caller, lines)

	#@ Step 1 - Pause voice:
	var paused_voice := false
	if not skipping and voice_player != null and is_instance_valid(voice_player) and "stream_paused" in voice_player:
		if voice_player.playing and not voice_player.stream_paused and pauses_voice(source, caller, entry):
			voice_player.stream_paused = true
			paused_voice = true

	#@ Step 2 - Run lines nested:
	#? Restored after, for nested text events.
	var previous_speech: CandySpeech = source.text_event_speech
	source.text_event_speech = speech
	var feedback = await CandyFlow.get_shared().run_nested_line(source, caller, lines, speech.conversation, speech.block)
	source.text_event_speech = previous_speech

	if paused_voice and is_instance_valid(voice_player):
		voice_player.stream_paused = false

	#% Dialogue ended inside the event:
	if feedback == "END" and source.killswitch == false:
		source.raise_killswitch()
	elif feedback == "Return":
		printerr("Candy DE - Text events: Return can't unwind from a text event ('", entry["name"], "'). Ignored.")

#* Run the line's remaining events:
func run_remaining(source: CandyEngine, caller: Object, speech: CandySpeech, voice_player = null) -> void:
	if speech == null:
		return
	for entry in speech.text_events:
		if source.killswitch == true:
			return
		await run_event(source, caller, speech, entry, voice_player)

#* Write a line at once (writing speed 0):
func write_instantly(source: CandyEngine, caller: Object, text_node: Node, hook_nodes: Array, speech: CandySpeech, voice_player = null) -> void:
	var custom_data: Array = []
	if speech != null:
		custom_data = speech.custom_data
	await CandyWriting.get_shared().call_write_hook(source, caller, hook_nodes, "x_write_begun", custom_data)
	if text_node != null:
		text_node.visible_characters = -1
	if speech != null:
		speech.write_skipped = true
		await run_remaining(source, caller, speech, voice_player)

#* An event's lines without waits:
func without_waits(source: CandyEngine, caller: Object, lines: Array) -> Array:
	var result: Array = []
	#? Other waits (CS_Move, an awaiting Call) still wait.
	for line in lines:
		if typeof(line) != TYPE_DICTIONARY:
			result.append(line)
			continue
		var kept := _without_wait_commands(line.duplicate(true))
		_zero_wait_keys(kept)
		if not kept.is_empty():
			result.append(kept)
	return result

#* Remove wait commands, bodies included:
func _without_wait_commands(line: Dictionary) -> Dictionary:
	for key in line.keys():
		var cmd := str(key).to_lower()
		if WAIT_COMMANDS.has(cmd) or cmd.ends_with(WAIT_SUFFIX):
			line.erase(key)
			continue
		var value = line[key]
		if typeof(value) == TYPE_DICTIONARY and typeof(value.get(BODY_KEY)) == TYPE_DICTIONARY:
			value[BODY_KEY] = _without_wait_commands(value[BODY_KEY])
	return line

#* Set every Wait_Loops and Wait_Time in a value to "0":
func _zero_wait_keys(value: Variant) -> void:
	if typeof(value) == TYPE_DICTIONARY:
		for key in value.keys():
			if WAIT_KEYS.has(str(key)):
				value[key] = "0"
			else:
				_zero_wait_keys(value[key])
	elif typeof(value) == TYPE_ARRAY:
		for item in value:
			_zero_wait_keys(item)


#& Settings:
#* Whether text events may run a command:
func allows_command(source: CandyEngine, caller: Object, cmd: String) -> bool:
	if ALWAYS_ALLOWED.has(cmd):
		return true
	var allowed = candy_de.get("text_event_commands")
	if typeof(allowed) != TYPE_ARRAY and typeof(allowed) != TYPE_PACKED_STRING_ARRAY:
		allowed = DEFAULT_COMMANDS
	for pattern in allowed:
		var entry := str(pattern).strip_edges().to_lower()
		if entry.ends_with("*"):
			if cmd.begins_with(entry.substr(0, entry.length() - 1)):
				return true
		elif entry == cmd:
			return true
	return false

#* Whether the voice pauses during an event:
func pauses_voice(source: CandyEngine, caller: Object, entry: Dictionary) -> bool:
	var value: bool = _property("text_events_pause_voice", false)
	if source.enable_text_events_pause_voice == true:
		value = source.text_events_pause_voice
	return _flag(source, caller, entry["event"], "Pause_Voice", value, entry)

#* Whether voice-synced writing resyncs after an event:
func resyncs_voice(source: CandyEngine, caller: Object, entry: Dictionary) -> bool:
	var value: bool = _property("text_events_resync_voice", true)
	if source.enable_text_events_resync_voice == true:
		value = source.text_events_resync_voice
	return _flag(source, caller, entry["event"], "Resync_Voice", value, entry)

#* An event's flag key, else 'fallback':
func _flag(source: CandyEngine, caller: Object, event: Dictionary, key: String, fallback: bool, entry: Dictionary) -> bool:
	if not event.has(key) or CandySettings.is_not_set(event[key]):
		return fallback
	var cr: CandyRef = source.candy_ref
	var raw: Variant = cr.resolve_value(source, source, event[key], candy_de.candy_ref_symbol)
	var value: Variant = null
	if not cr.last_failed:
		value = CandySettings.get_shared().convert_value(source, caller, raw, true, "")
	if value == null:
		printerr("Candy DE - Text events: '", key, "' of event '", entry["name"], "' can't be ", var_to_str(event[key]), " - expected 1 or 0. Using ", fallback, ".")
		return fallback
	return bool(value)

#* A Candy_Properties.gd setting, else 'fallback':
func _property(setting: String, fallback: Variant) -> Variant:
	var value = candy_de.get(setting)
	if value == null:
		return fallback
	return value

#* A text event symbol, else "":
func _symbol(setting: String) -> String:
	var value = candy_de.get(setting)
	if value == null:
		return ""
	return str(value)

@warning_ignore_restore("unused_parameter")
