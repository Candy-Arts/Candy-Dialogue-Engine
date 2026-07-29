#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyWriting
extends RefCounted


#^ Shared instance:
static var _shared: CandyWriting = null

#^ BBCode tags with no closing tag:
const SELF_CLOSING_TAGS := ["br", "hr", "lb", "rb", "char"]

#^ Lexicon escape stand-ins (Unicode noncharacters), from mark_lexicon_escapes() until the display:
#? CandyTextEvents.MARKER is U+FDD4, Spoken_Line's escaped-symbol stand-ins U+FDD0 to U+FDD3.
const LEXICON_ESCAPE_START := "﷕"
const LEXICON_ESCAPE_END := "﷖"

#* Get the shared instance:
static func get_shared() -> CandyWriting:
	if _shared == null:
		_shared = CandyWriting.new()
	return _shared


#? 'caller' is in every signature for consistency:
@warning_ignore_start("unused_parameter")

#* Highlight / end highlight of a speaker's bust:
func bust_highlight(source: CandyEngine, caller: Object, speaker_ref, style, active: bool, custom_data: Array = []) -> void:
	var bust_scene := CandyUI.get_shared().actor_bust_scene(source, caller, speaker_ref)
	if bust_scene == null:
		return
	#Ł Reach this engine's dialogue box:
	bust_scene.caller = source
	if active:
		bust_scene.highlight_speaker(speaker_ref, style, custom_data)
	else:
		bust_scene.end_highlight_speaker(speaker_ref, style, custom_data)

#* Wrap text in BBCode, closing its tags:
func wrap_bbcode(source: CandyEngine, caller: Object, text: String, opening: String) -> String:
	if opening == "":
		return text
	return opening + text + _closing_tags(source, caller, opening)

#* Closing tags for a BBCode wrap, innermost first:
func _closing_tags(source: CandyEngine, caller: Object, opening: String) -> String:
	var open_tags: Array[String] = []
	var regex := RegEx.new()
	regex.compile("\\[([^\\[\\]]+)\\]")
	for found in regex.search_all(opening):
		#? Not trimmed - "[ b ]" isn't a tag.
		var inner := found.get_string(1)

		#% Closing tag cancels its latest opening tag:
		if inner.begins_with("/"):
			var index := open_tags.rfind(inner.substr(1))
			if index != -1:
				open_tags.remove_at(index)
			continue

		#Ł Base name, before '=' or ' '; skip self-closing tags:
		var tag_name := inner.split("=")[0].split(" ")[0]
		if tag_name != "" and not SELF_CLOSING_TAGS.has(tag_name):
			open_tags.append(tag_name)

	var closing := ""
	for i in range(open_tags.size() - 1, -1, -1):
		closing += "[/" + open_tags[i] + "]"
	return closing

#* Run a write hook on each node:
func call_write_hook(source: CandyEngine, caller: Object, hook_nodes: Array, method: String, custom_data: Array = []) -> void:
	for hook_node in hook_nodes:
		if hook_node != null:
			await candy_de.run_node_hook(hook_node, method, {"caller": source, "node": hook_node}, custom_data)

#* Typewriter:
#? Settings from 'speech', else the engine's.
func typewriter(source: CandyEngine, caller: Object, text_node: Node, hook_nodes: Array, total_visible: int, start_offset: int, voice_player, speech: CandySpeech = null) -> void:
	var settings := CandySettings.get_shared()
	var text_events: CandyTextEvents = CandyTextEvents.get_shared()
	var fast_speed: int = settings.get_value(source, caller, speech, "continue_fast_speed")
	var slow_speed: int = settings.get_value(source, caller, speech, "continue_slow_speed")

	#Ł Base speed, when no speed key is held:
	#? Speed/Slow keys desync from the voice on purpose.
	var line_speed = settings.get_value(source, caller, speech, "writing_speed")
	var i := 0
	var char_progress = 0.0
	var last_time = Time.get_ticks_msec() / 1000.0

	#Ł Sync writing speed with the voice:
	var voice_synced := false
	if settings.get_value(source, caller, speech, "sync_write_speed_voice") == true:
		if settings.get_value(source, caller, speech, "enable_voice") == true and voice_player != null and voice_player.stream != null:
			var voice_length = voice_player.stream.get_length()		#/ seconds
			if voice_length > 0.1 and total_visible > 0:
				line_speed = float(total_visible) / voice_length
				voice_synced = true

	#Ł Text event positions:
	var scheduled: Array = text_events.schedule(source, caller, speech, text_node)
	var next_event := 0

	var base_speed = _event_speed(speech, line_speed)
	var effective_speed = base_speed

	#. Hook call:
	var custom_data: Array = []
	if speech != null:
		custom_data = speech.custom_data
	await call_write_hook(source, caller, hook_nodes, "x_write_begun", custom_data)

	#Ł Nodes with x_write_progress():
	var progress_nodes: Array = []
	for hook_node in hook_nodes:
		if hook_node != null and hook_node.has_method("x_write_progress"):
			progress_nodes.append(hook_node)

	#¬ Write text:
	while true:
		#@ Step 1 - Killswitch:
		if source.killswitch == true:
			return

		#@ Step 2 - Run reached text events:
		if next_event < scheduled.size() and int(scheduled[next_event]["position"]) <= i:
			var entry: Dictionary = scheduled[next_event]
			next_event += 1
			text_node.visible_characters = start_offset + i
			await text_events.run_event(source, caller, speech, entry, voice_player)
			last_time = Time.get_ticks_msec() / 1000.0		#/ Event time isn't writing time

			#Ł Write_Speed, else resync with the voice:
			base_speed = _event_speed(speech, line_speed)
			if voice_synced and speech.write_speed < 0.0 and text_events.resyncs_voice(source, caller, entry):
				line_speed = _remaining_voice_speed(voice_player, total_visible - i, line_speed)
				base_speed = line_speed
			continue

		if i >= total_visible:
			break

		#@ Step 3 - Suspension check:
		if source.dialogue_suspended == true:
			await source._await_suspension()
			last_time = Time.get_ticks_msec() / 1000.0		#/ No time jump after resume
			continue

		#@ Step 4 - Speed/Slow/Skip:
		#? Skipping runs the remaining text events without their waits.
		#¦ 1. Speed writing:
		if InputMap.has_action(source.input_speed_dialogue) and Input.is_action_pressed(source.input_speed_dialogue) and source.input_enabled == true:
			if fast_speed < 0:
				pass
			elif fast_speed == 0:
				text_node.visible_characters = -1
				_skip_writing(speech)
				break
			else:
				effective_speed = fast_speed

		#¦ 2. Slow writing:
		elif InputMap.has_action(source.input_slow_dialogue) and Input.is_action_pressed(source.input_slow_dialogue) and source.input_enabled == true:
			if slow_speed < 0:
				pass
			elif slow_speed == 0:
				text_node.visible_characters = -1
				_skip_writing(speech)
				break
			else:
				effective_speed = slow_speed

		#¦ 3. Skip writing:
		elif InputMap.has_action(source.input_skip_dialogue) and Input.is_action_pressed(source.input_skip_dialogue) and source.input_enabled == true:
			text_node.visible_characters = -1
			_skip_writing(speech)
			break

		#¦ 4. Base speed:
		else:
			effective_speed = base_speed

		#@ Step 5 - Time progression:
		#? Stop at the next text event:
		var limit := total_visible
		if next_event < scheduled.size():
			limit = mini(limit, int(scheduled[next_event]["position"]))

		var now := Time.get_ticks_msec() / 1000.0
		var delta = now - last_time
		last_time = now
		var chars_to_add = 0
		#% Speed 0 - write up to the next event at once:
		if effective_speed <= 0:
			chars_to_add = limit - i
		else:
			char_progress += effective_speed * delta
			chars_to_add = int(char_progress)
			char_progress -= chars_to_add

		if chars_to_add > 0:
			var written_before := i
			i = min(i + chars_to_add, limit)

			#Ł Update visible characters:
			text_node.visible_characters = start_offset + i

			#. Hook call:
			#? Once per frame at most.
			for hook_node in progress_nodes:
				if is_instance_valid(hook_node):
					candy_de.run_node_hook(hook_node, "x_write_progress", {"caller": source, "node": hook_node,
						"text_node": text_node, "added": i - written_before, "written": i, "total": total_visible}, custom_data)

		await source.get_tree().process_frame

	#@ Step 6 - Reveal the end-of-line symbol:
	text_node.visible_characters = -1

	#@ Step 7 - Unreached text events:
	#? Skipped ones run without their waits.
	await text_events.run_remaining(source, caller, speech, voice_player)

#* Base speed - Write_Speed's, else the line's:
func _event_speed(speech: CandySpeech, line_speed: Variant) -> Variant:
	if speech != null and speech.write_speed >= 0.0:
		return speech.write_speed
	return line_speed

#* Speed that ends 'remaining' characters with the voice, or 'fallback':
func _remaining_voice_speed(voice_player, remaining: int, fallback: Variant) -> Variant:
	if voice_player == null or not is_instance_valid(voice_player) or voice_player.stream == null or not voice_player.playing:
		return fallback
	var time_left: float = voice_player.stream.get_length() - voice_player.get_playback_position()
	if time_left <= 0.1 or remaining <= 0:
		return fallback
	return float(remaining) / time_left

#* Mark writing as skipped, for text events:
func _skip_writing(speech: CandySpeech) -> void:
	if speech != null:
		speech.write_skipped = true

#* Log a spoken line to history:
func log_speech_history(source: CandyEngine, caller: Object, speech: CandySpeech) -> void:
	if CandySettings.get_shared().get_value(source, caller, speech, "write_dialogue_history") != true:
		return

	#Ł The history has no lexicon - keywords written as their "Disabled" text (already, if the line had it off):
	var history_text: String = speech.text
	if speech.settings.get("lexicon_mode", true) == true and candy_de.lexicon is Dictionary:
		history_text = apply_lexicon_disabled(source, caller, history_text, candy_de.lexicon, speech.chosen_variation)

	var entry: Dictionary = {
		"Speech": {
			"speaker_ref": speech.speaker_ref,
			"display_name": speech.speaker_display,
			"speech": CandyTextEvents.get_shared().strip_stand_ins(source, caller, history_text),
			"portrait": speech.portrait_raw,
			"disposition": speech.disposition
		}
	}

	source.dialogue_history.append(entry)
	candy_de.general_dialogue_history.append(entry.duplicate(true))

#* Wait for player advance or auto-advance:
#? Settings from 'speech', else the engine's.
func wait_for_player_advance(source: CandyEngine, caller: Object, voice_player, command, speech: CandySpeech = null) -> void:
	if OS.is_debug_build() and source.debug_prints == true:
		print("Waiting for player advance.")

	#Ł Wait for the advance key's release:
	while (_action_pressed(source, caller, source.input_advance_dialogue) or _action_pressed(source, caller, source.input_player_advance)) and source.input_enabled == true:
		#% Killswitch:
		if source.killswitch == true:
			return

		await source.get_tree().process_frame

	#¦ 1. Command mode (Player_Advance) - manual input only:
	if command == true:
		while true:
			#% Killswitch:
			if source.killswitch == true:
				return

			await source.get_tree().process_frame

			if source.dialogue_suspended == true:
				await source._await_suspension()
				continue

			if _action_just_pressed(source, caller, source.input_player_advance) and source.input_enabled == true:
				break

		await source.get_tree().process_frame

		return

	#¦ 2. Spoken Line mode:
	var timer := 0.0
	var auto_advance: float = CandySettings.get_shared().get_value(source, caller, speech, "auto_advance")
	var await_voice: bool = CandySettings.get_shared().get_value(source, caller, speech, "await_voice_playback")
	var auto_enabled = auto_advance >= 0.0
	var wait_time := maxf(auto_advance, 0.0)

	#Ł Time per displayed character:
	if auto_enabled and speech != null:
		var per_character: float = CandySettings.get_shared().get_value(source, caller, speech, "auto_advance_per_character")
		if per_character != 0.0:
			wait_time = maxf(wait_time + per_character * displayed_characters(source, caller, speech), 0.0)

	while true:
		#% Killswitch:
		if source.killswitch == true:
			return

		await source.get_tree().process_frame

		#Ł Suspension check:
		if source.dialogue_suspended == true:
			await source._await_suspension()
			continue

		#Ł Auto-advance timer:
		if auto_enabled:
			timer += source.get_process_delta_time()

		#Ł Manual advance:
		#% Once the voice ends, if awaited:
		if _action_just_pressed(source, caller, source.input_advance_dialogue) and source.input_enabled == true:
			if not await_voice or voice_player == null or not voice_player.playing:
				break		#/ Before the timer ends too

		#Ł Auto-advance:
		#% Once the voice ends:
		if auto_enabled and timer >= wait_time:
			var voice_done = (voice_player == null or not voice_player.playing)
			if voice_done:
				break

	await source.get_tree().process_frame

#* Characters a line shows, as display() measured them:
#? Not measured (a display without the measure): counted from its text, before the lexicon.
func displayed_characters(source: CandyEngine, caller: Object, speech: CandySpeech) -> int:
	if speech.displayed_characters >= 0:
		return speech.displayed_characters
	return count_characters(source, caller, CandyTextEvents.get_shared().strip_stand_ins(source, caller, speech.text))

#* Characters a text shows, without its BBCode tags:
#? For text no label displays (Voice mode); a label measures with get_total_character_count().
func count_characters(source: CandyEngine, caller: Object, text: String) -> int:
	return bbcode_strip_tags(source, caller, text).length()

#* Input queries, silent for undefined actions:
func _action_pressed(source: CandyEngine, caller: Object, action: String) -> bool:
	return action != "" and InputMap.has_action(action) and Input.is_action_pressed(action)

func _action_just_pressed(source: CandyEngine, caller: Object, action: String) -> bool:
	return action != "" and InputMap.has_action(action) and Input.is_action_just_pressed(action)

#* Clear a text UI element (UI_Clear):
func clear_text_ui(source: CandyEngine, caller: Object, key: String, hide: bool = true, clear_text: bool = true, reset_z: bool = true, custom_data: Array = []) -> Node:
	var root := CandyUI.get_shared().get_element(source, source, key)
	if root == null:
		return null

	if hide:
		root.visible = false

	if clear_text:
		if "speaker_node" in root and root.speaker_node != null:
			root.speaker_node.text = ""
		if "dialogue_node" in root and root.dialogue_node != null:
			root.dialogue_node.text = ""

		if root.has_method("clear"):
			_call_ui_clear(source, caller, root, hide, clear_text, custom_data)
		elif "label" in root and root.label != null:
			root.label.text = ""

	if reset_z and "default_z" in root:
		root.z_index = root.default_z

	return root

#* Call a UI element's clear(), matching its signature:
func _call_ui_clear(source: CandyEngine, caller: Object, root: Node, hide: bool, clear_text: bool, custom_data: Array = [], master: bool = false) -> void:
	#@ Step 1 - Read clear()'s argument names:
	var arg_names: Array = []
	for m in root.get_method_list():
		if str(m["name"]) == "clear":
			for arg in m["args"]:
				arg_names.append(str(arg["name"]))
			break

	#@ Step 2 - Fill by name; of the rest, the first is the hide flag, the others text flags:
	#?   Barks / bubbles:  clear(engine, custom_data, master)
	#?   Subtitles:        clear(frame, custom_data)
	#?   Dialogue Box:     clear(frame, speech, speaker, portrait, custom_data)
	#?   Chat_Channel:     clear(frame, clear_text, custom_data)
	var args: Array = []
	for i in range(arg_names.size()):
		if arg_names[i] == "custom_data":
			args.append(custom_data)
		elif arg_names[i] == "engine":
			args.append(source)
		elif arg_names[i] == "master":
			args.append(master)
		elif i == 0:
			args.append(hide)
		else:
			args.append(clear_text)

	root.callv("clear", args)

#* Clear every VN speech bubble:
#? 'master': also bubbles another engine wrote last (UI_Clear's Bubbles "2").
func clear_vn_bubbles(source: CandyEngine, caller: Object, custom_data: Array = [], master: bool = false) -> void:
	var bust_scene := CandyUI.get_shared().get_element(source, source, "busts_path")
	if bust_scene == null or not ("busts_container" in bust_scene) or bust_scene.busts_container == null:
		return
	if not ("speech_bubbles_name" in bust_scene):
		return
	for bust in bust_scene.busts_container.get_children():
		var bubble = bust.get_node_or_null(str(bust_scene.speech_bubbles_name))
		if bubble != null and bubble.has_method("clear"):
			_call_ui_clear(source, caller, bubble, true, true, custom_data, master)

#* Clear an actor's speech bubble:
#? 'master': even if another engine wrote last (UI_Clear's Bubbles "2").
func clear_actor_bubble(source: CandyEngine, caller: Object, actor: Node, custom_data: Array = [], master: bool = false) -> void:
	if actor == null or not ("internal_node_dict" in actor):
		return
	var bubble = actor.internal_node_dict.get("Speech_Bubble")
	if bubble != null and is_instance_valid(bubble) and bubble.has_method("clear"):
		_call_ui_clear(source, caller, bubble, true, true, custom_data, master)

#* Whether a bracketed section is a BBCode tag:
func _is_valid_bbcode_tag(source: CandyEngine, caller: Object, tag: String) -> bool:
	if not tag.begins_with("[") or not tag.ends_with("]"):
		return false

	#@ Step 1 - Strip brackets:
	var inner = tag.substr(1, tag.length() - 2).strip_edges()
	if inner == "":
		return false

	#% Closing tag:
	var is_closing = false
	if inner.begins_with("/"):
		is_closing = true
		inner = inner.substr(1)		#/ strip the "/"

	#@ Step 2 - Base name, before '=' or ' ':
	var base_name := inner.split("=")[0].split(" ")[0]

	#% Known tag:
	var is_known = (
		candy_de.BBCODE_TAGS_SIMPLE.has(base_name)
		or candy_de.BBCODE_TAGS_EQUALS.has(base_name)
		or candy_de.BBCODE_TAGS_SPACE.has(base_name)
	)
	if not is_known:
		return false

	if is_closing:
		return true

	#¦ 1. No parameters:
	if inner == base_name and candy_de.BBCODE_TAGS_SIMPLE.has(base_name):
		return true

	#¦ 2. "=" parameter:
	if candy_de.BBCODE_TAGS_EQUALS.has(base_name):
		if inner.begins_with(base_name + "="):
			return true

	#¦ 3. Space-delimited parameters:
	if candy_de.BBCODE_TAGS_SPACE.has(base_name):
		if inner.begins_with(base_name + " "):
			return true

	#¦ 4. Known tag, unusual format:
	return true

#* Strip BBCode tags:
func bbcode_strip_tags(source: CandyEngine, caller: Object, text: String) -> String:
	var stripped := ""
	var inside_tag := false
	var current := ""

	for ch in text:
		#¦ 1. Opening bracket:
		if ch == "[":
			#% Second '[' - the previous one wasn't a tag:
			if inside_tag:
				stripped += current
			inside_tag = true
			current = "["
		#¦ 2. Closing bracket:
		elif ch == "]":
			current += "]"
			#¦ 1. Drop BBCode tags:
			if _is_valid_bbcode_tag(source, caller, current):
				pass
			#¦ 2. Keep literal [text]:
			else:
				stripped += current
			current = ""
			inside_tag = false
		elif inside_tag:
			current += ch
		else:
			stripped += ch

	#% Unclosed tag - literal:
	if inside_tag and current != "":
		stripped += current

	return stripped

#* Apply lexicon tags (tooltips, clickable URLs, BBCode):
func apply_lexicon_tags(source: CandyEngine, caller: Object, text: String, lexicon: Dictionary, chosen_variation: String) -> String:
	#@ Steps 1 to 5 - The keywords in the text, longest first:
	var found := _lexicon_keywords(text, lexicon, chosen_variation)
	var used: Array = found["used"]
	var entry_sources: Dictionary = found["sources"]
	if used.is_empty():
		return text

	#@ Step 6 - Build replacements:
	var replacements: Dictionary = {}

	for word in used:
		var variation_key: String = entry_sources[word]
		var entry: Dictionary = lexicon[variation_key][word]

		#Ł Display:
		var display_word: String = word
		if entry.has("Display"):
			var disp_val := str(entry["Display"]).strip_edges()
			if disp_val != "":
				display_word = disp_val

		#Ł Tooltip:
		var tooltip_text := ""
		if entry.has("Tooltip"):
			tooltip_text = str(entry["Tooltip"]).strip_edges()

		#Ł Clickable:
		var clickable_raw = entry.get("Clickable", false)
		var clickable := false
		match typeof(clickable_raw):
			TYPE_BOOL:
				clickable = clickable_raw
			TYPE_INT, TYPE_FLOAT:
				clickable = clickable_raw != 0
			_:
				clickable = str(clickable_raw).strip_edges().to_lower() in ["true", "1", "yes"]

		var keyword_click_data = entry.get("Click_Data", null)

		#Ł URL wrapper:
		var start_tags := ""
		var end_tags := ""
		if clickable:
			var meta_dict = {
				"keyword": word,
				"keyword_click_data": keyword_click_data,
				"keyword_variation": variation_key,
			}
			var encoded = Marshalls.variant_to_base64(meta_dict)
			start_tags += "[url=%s]" % encoded
			end_tags = "[/url]" + end_tags

		#Ł Tooltip wrapper:
		if tooltip_text != "":
			start_tags += "[hint=%s]" % tooltip_text
			end_tags = "[/hint]" + end_tags

		#Ł BBCode wrap:
		var bbcode := ""
		if entry.has("BBCode") and typeof(entry["BBCode"]) == TYPE_STRING:
			bbcode = entry["BBCode"]

		replacements[word] = start_tags + wrap_bbcode(source, caller, display_word, bbcode) + end_tags

	#@ Steps 7 and 8 - Replace them:
	return _replace_keywords(source, caller, text, used, replacements, chosen_variation)


#* The lexicon switched off - each keyword written as its "Disabled" text, with no tags:
#? A keyword with no "Disabled" text (or an empty one) is written as it is.
func apply_lexicon_disabled(source: CandyEngine, caller: Object, text: String, lexicon: Dictionary, chosen_variation: String) -> String:
	var found := _lexicon_keywords(text, lexicon, chosen_variation)
	var used: Array = found["used"]
	var entry_sources: Dictionary = found["sources"]
	if used.is_empty():
		return text

	#? Every keyword stays in the pattern, its own text or not: the longest one still wins.
	var replacements: Dictionary = {}
	var changed := false
	for word in used:
		var entry: Dictionary = lexicon[entry_sources[word]][word]
		replacements[word] = word
		if entry.has("Disabled"):
			var disabled_text := str(entry["Disabled"]).strip_edges()
			if disabled_text != "":
				replacements[word] = disabled_text
				changed = true
	if not changed:
		return text
	return _replace_keywords(source, caller, text, used, replacements, chosen_variation)


#* The keywords found in a text - "used": longest first, "sources": keyword -> its variation key:
func _lexicon_keywords(text: String, lexicon: Dictionary, chosen_variation: String) -> Dictionary:
	#@ Steps 1 to 3 - Matching variation keys, least specific first:
	var matches := _variation_keys(lexicon, chosen_variation)

	#@ Step 4 - Word → most specific variation:
	var entry_sources: Dictionary = {}
	for key in matches:
		var block = lexicon[key]
		if not block is Dictionary:
			continue
		for w in block.keys():
			entry_sources[w] = key

	#@ Step 5 - Keywords present, longest first:
	var used: Array = []
	for w in entry_sources.keys():
		if text.find(str(w)) >= 0:
			used.append(str(w))

	used.sort_custom(func(a, b): return a.length() > b.length())
	return {"used": used, "sources": entry_sources}


#* A table's variation keys matching a variation, least specific first ("*", "Default*", "Default"):
func _variation_keys(table: Dictionary, chosen_variation: String) -> Array:
	#@ Step 1 - Matching variations (case-sensitive):
	var matches: Array = []
	var exact_matches: Array = []

	for variation_key in table.keys():
		var vk: String = str(variation_key)

		if vk == "*":
			matches.append(variation_key)
		elif vk.ends_with("*"):
			var prefix = vk.substr(0, vk.length() - 1)
			if chosen_variation.begins_with(prefix):
				matches.append(variation_key)
		elif vk == chosen_variation:
			matches.append(variation_key)
			exact_matches.append(variation_key)

	#@ Step 2 - Sort by specificity, most specific last:
	matches.sort_custom(func(a, b):
		var la: int = a.trim_suffix("*").length()
		var lb: int = b.trim_suffix("*").length()
		if la == lb:
			return a < b
		return la < lb
	)

	#@ Step 3 - Exact matches last:
	for ex in exact_matches:
		matches.erase(ex)
		matches.append(ex)
	return matches


#* Replace each keyword (used, longest first) with its replacement, as whole words:
func _replace_keywords(source: CandyEngine, caller: Object, text: String, used: Array, replacements: Dictionary, chosen_variation: String) -> String:
	#@ Step 7 - One whole-word pass, with the variation's word rules:
	var bounds := _word_boundaries(source, caller, chosen_variation)
	var regex := RegEx.new()
	if regex.compile(bounds[0] + "(" + "|".join(used) + ")" + bounds[1]) != OK:
		push_error("apply_lexicon_tags(): could not compile keyword pattern. Check for reserved symbols in Lexicon keywords.")
		return text

	#@ Step 8 - Replace from the end, keeping offsets valid, except inside lexicon escapes:
	var escaped := _lexicon_escaped_ranges(text)
	var results := regex.search_all(text)
	for i in range(results.size() - 1, -1, -1):
		var m := results[i]
		if _overlaps(escaped, m.get_start(0), m.get_end(0)):
			continue
		text = text.substr(0, m.get_start(0)) + replacements[m.get_string(1)] + text.substr(m.get_end(0))

	return text


#& Lexicon word rules:
#? Which characters may touch a keyword (Data_Tables/Lexicon_Word_Rules.gd), by variation:
#? "Word" characters make it fail on either side; "Joiners" only between two word characters.

#^ Used for a kind of rule no variation key of the table gives (and with no table):
const DEFAULT_WORD_RULES := {
	"Word": {"Categories": ["L", "N"], "Characters": ["_"], "Excluded": []},
	"Joiners": {"Categories": [], "Characters": []},
}

#^ Unicode categories already checked (name -> valid), and problems already reported:
static var _category_checks: Dictionary = {}
static var _reported_rules: Dictionary = {}

#* The lookbehind and lookahead around the keywords, for a variation - [before, after]:
func _word_boundaries(source: CandyEngine, caller: Object, chosen_variation: String) -> Array:
	var rules := _word_rules(chosen_variation)
	var word := _char_class(rules["Word"], "Characters")
	#% No word characters - keywords match anywhere (Chinese, Japanese...):
	if word == "":
		return ["", ""]
	var excluded := _char_class({"Characters": rules["Word"].get("Excluded", [])}, "Characters")
	if excluded != "":
		word = "(?:(?!" + excluded + ")" + word + ")"
	var before := "(?<!" + word + ")"
	var after := "(?!" + word + ")"
	var joiners := _char_class(rules["Joiners"], "Characters")
	if joiners != "":
		before += "(?<!" + word + joiners + ")"
		after += "(?!" + joiners + word + ")"
	return [before, after]

#* Each kind of rule from the most specific variation key that gives it:
func _word_rules(chosen_variation: String) -> Dictionary:
	var rules := DEFAULT_WORD_RULES.duplicate(true)
	var table = candy_de.get("lexicon_word_rules")
	if not table is Dictionary:
		return rules
	for key in _variation_keys(table, chosen_variation):
		var entry = table[key]
		if not entry is Dictionary:
			_report_rule("lexicon_word_rules[\"%s\"] should be a Dictionary." % key)
			continue
		for kind in ["Word", "Joiners"]:
			if not entry.has(kind):
				continue
			if entry[kind] is Dictionary:
				rules[kind] = entry[kind]
			else:
				_report_rule("lexicon_word_rules[\"%s\"][\"%s\"] should be a Dictionary." % [key, kind])
	return rules

#* A regex character class of a rule's categories and characters, "" if it has none:
func _char_class(rule: Dictionary, characters_key: String) -> String:
	var parts := ""
	var categories = rule.get("Categories", [])
	if categories is Array:
		for category in categories:
			if _valid_category(category):
				parts += "\\p{" + str(category) + "}"
	var characters = rule.get(characters_key, [])
	if characters is Array:
		for item in characters:
			if typeof(item) == TYPE_STRING and str(item).length() == 1:
				parts += "\\x{%x}" % str(item).unicode_at(0)		#/ Escaped: any character is safe
			else:
				_report_rule("lexicon_word_rules: \"%s\" isn't one character, so it's ignored. Each item of Characters and Excluded is one character." % str(item))
	if parts == "":
		return ""
	return "[" + parts + "]"

#* Whether a Unicode category or script name is known ("L", "Lu", "Han", "Latin"...):
func _valid_category(category: Variant) -> bool:
	var category_name := str(category)
	if _category_checks.has(category_name):
		return _category_checks[category_name]
	var valid := typeof(category) == TYPE_STRING and RegEx.create_from_string("^[A-Za-z_&]+$").search(category_name) != null
	if valid:
		valid = RegEx.new().compile("\\p{" + category_name + "}") == OK
	_category_checks[category_name] = valid
	if not valid:
		_report_rule("lexicon_word_rules: \"%s\" isn't a Unicode category or script name, so it's ignored (\"L\" for letters, \"N\" for digits, \"Han\", \"Latin\"...)." % category_name)
	return valid

#* Report a malformed rule once:
func _report_rule(message: String) -> void:
	if _reported_rules.has(message):
		return
	_reported_rules[message] = true
	printerr("Candy DE - ", message)


#& Lexicon escapes:
#* Turn lexicon escape symbols into stand-ins ("¬Alice¬" → escaped "Alice"; "¬¬" → "¬"):
func mark_lexicon_escapes(source: CandyEngine, caller: Object, text: String) -> String:
	#? get(): an older Candy_Properties.gd may lack the symbols.
	var start_raw = candy_de.get("lexicon_escape_start_symbol")
	var end_raw = candy_de.get("lexicon_escape_end_symbol")
	if typeof(start_raw) != TYPE_STRING or typeof(end_raw) != TYPE_STRING or start_raw == "" or end_raw == "":
		return text
	var start_tag: String = start_raw
	var end_tag: String = end_raw

	var result := ""
	var inside := false
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

		#¦ 3. End of an escape (checked first: identical symbols toggle):
		if inside and text.substr(i, end_tag.length()) == end_tag:
			result += LEXICON_ESCAPE_END
			inside = false
			i += end_tag.length()
			continue

		#¦ 4. Start of an escape:
		if not inside and text.substr(i, start_tag.length()) == start_tag:
			result += LEXICON_ESCAPE_START
			inside = true
			i += start_tag.length()
			continue

		result += text[i]
		i += 1
	return result

#* Remove lexicon escape stand-ins:
func strip_lexicon_escapes(source: CandyEngine, caller: Object, text: String) -> String:
	return text.replace(LEXICON_ESCAPE_START, "").replace(LEXICON_ESCAPE_END, "")

#* Remove lexicon escape symbols from a text that gets no lexicon (names, TTS):
func remove_lexicon_escapes(source: CandyEngine, caller: Object, text: String) -> String:
	return strip_lexicon_escapes(source, caller, mark_lexicon_escapes(source, caller, text))

#* [start, end] of every escaped span (an unclosed one runs to the end):
func _lexicon_escaped_ranges(text: String) -> Array:
	var ranges: Array = []
	var start := text.find(LEXICON_ESCAPE_START)
	while start != -1:
		var end := text.find(LEXICON_ESCAPE_END, start)
		if end == -1:
			end = text.length()
		ranges.append([start, end])
		start = text.find(LEXICON_ESCAPE_START, end)
	return ranges

#* Whether [from, to) overlaps one of the ranges:
func _overlaps(ranges: Array, from: int, to: int) -> bool:
	for span in ranges:
		if from < span[1] and to > span[0]:
			return true
	return false

#* Translate a value with a translation table:
func translate(source: CandyEngine, caller: Object, new_value: String, table_raw: String = "") -> String:
	#% No engine, no language:
	if source == null:
		push_error("translate(): no engine was given for '" + new_value + "', so it has no language to be translated into. The text is left untranslated.")
		return new_value
	var language: String = source.use_language

	#@ Step 1 - Resolve the table:
	var translation_dict: Dictionary

	if table_raw == "":
		push_error("translate(): table_raw was empty value, cannot translate. Aborting.")
		return new_value

	var resolved = null
	#Ł Expression = the table, plain text = a candy_de table name:
	resolved = source.candy_ref.resolve_value(source, source, table_raw, candy_de.candy_ref_symbol)
	if typeof(resolved) == TYPE_STRING:
		resolved = candy_de.get(resolved)
	if typeof(resolved) == TYPE_DICTIONARY:
		translation_dict = resolved
	else:
		push_error("translate(): could not resolve table to a dictionary: " + table_raw)
		return new_value

	#@ Step 2 - Translate:
	if not translation_dict.has(new_value):
		return new_value

	#% Entry must be a Dictionary by language:
	var entry = translation_dict[new_value]
	if typeof(entry) != TYPE_DICTIONARY:
		push_error("translate(): the entry '" + new_value + "' in table '" + table_raw + "' should be a Dictionary of translations by language, such as {\"French\": \"...\"}, not '" + str(entry) + "'. The text is left untranslated.")
		return new_value

	if entry.has(language):
		return str(entry[language])

	#% No translation:
	return new_value

@warning_ignore_restore("unused_parameter")
