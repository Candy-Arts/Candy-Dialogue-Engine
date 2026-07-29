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


#^ Max passes for nested text variables:
const TEXT_VARIABLE_MAX_PASSES := 16

#^ Stand-ins for escaped (doubled) symbols:
#? Unicode noncharacters: never in written text.
const ESCAPED_TEXT_VAR_START := "﷐"
const ESCAPED_TEXT_VAR_END := "﷑"
const ESCAPED_SUBSTITUTION_START := "﷒"
const ESCAPED_SUBSTITUTION_END := "﷓"


func execute(engine: CandyEngine, command_value: Variant, ctx: CandyContext) -> String:
	#Ł Unpack context:
	var current_conversation = ctx.conversation
	var current_block = ctx.block
	var line_index = ctx.line_index
	var line_data: Dictionary = ctx.line_data

	#Ł Default outcome:
	ctx.speech_outcome = "Skipped"

	#. Hook call:
	#? No variation yet: line's Custom Data only.
	await candy_de.run_hook("x_new_speech_start", {"caller": engine, "line_data": line_data}, CandyCustomData.levels([command_value]))

	#@ Step 1 - Validate format:
	if typeof(command_value) != TYPE_DICTIONARY:
		return "Continue"

	var speech_data: Dictionary = command_value

	#@ Step 2 - Resolve speaker reference:
	#? A role ("°npc1") gives its actor.
	var speaker_ref = CandyActors.get_shared().actor_from_role(engine, self, engine.candy_ref.resolve_value(engine, engine, speech_data.get("Reference", ""), candy_de.candy_ref_symbol), "Spoken_Line", engine.candy_ref.last_literal)

	#@ Step 3A - Resolve disposition condition:
	var disposition_value = engine.candy_ref.resolve_value(engine, engine, speech_data.get("Disposition", ""), candy_de.candy_ref_symbol)
	var disposition_cond := ""
	if disposition_value != null:
		disposition_cond = str(disposition_value).strip_edges()
	engine.prev_resolved_disp_tracker = engine.resolved_disp_tracker
	engine.resolved_disp_tracker = disposition_cond

	#@ Step 3B - Actor's dispositions (none if unknown):
	var actor_disp_raw: String = ""
	if candy_de.actors.has(speaker_ref):
		actor_disp_raw = str(candy_de.actors[speaker_ref].get("Disposition", "")).strip_edges()
	else:
		if disposition_cond != "":
			push_warning("Candy DE - Disposition: speaker '" + str(speaker_ref) + "' not found in the actors dictionary, treated as having no dispositions.")

	var actor_disps: Array = actor_disp_raw.split(",", false)
	actor_disps = actor_disps.map(func(x): return x.strip_edges())

	#@ Step 3C - Parse disposition condition:
	var prefix_disp := ""
	var match_count := -1		#/ -1 = no numeric condition
	var is_negated := false

	#Ł Read prefix characters:
	var prefix_chars := ["=", "+", "-", "!"]
	var p_i := 0
	while p_i < disposition_cond.length():
		var ch = disposition_cond[p_i]
		if ch in prefix_chars:
			prefix_disp += ch
			p_i += 1
		elif ch == " " or ch == "\t":
			p_i += 1
		else:
			break

	disposition_cond = disposition_cond.substr(p_i).strip_edges()

	#Ł Numeric "(n)":
	var numeric_regex := RegEx.new()
	numeric_regex.compile(r"^\((\d+)\)")
	var match_num := numeric_regex.search(disposition_cond)
	if match_num:
		match_count = int(match_num.get_string(1))
		disposition_cond = disposition_cond.substr(match_num.get_end(0)).strip_edges()

	#Ł Prefix flags:
	is_negated = prefix_disp.find("!") != -1
	var has_plus = prefix_disp.find("+") != -1
	var has_minus = prefix_disp.find("-") != -1
	var has_equal = prefix_disp.find("=") != -1

	#@ Step 3D - Split disposition list:
	var cond_disps: Array = []
	if disposition_cond != "":
		disposition_cond = disposition_cond.trim_suffix(",").strip_edges()
		cond_disps = disposition_cond.split(",", false)
		cond_disps = cond_disps.map(func(x): return x.strip_edges())

	#@ Step 3E - Evaluate:
	var overlap_count = actor_disps.filter(func(d): return cond_disps.has(d)).size()
	var passes := false

	#¦ 1. Numeric form:
	if match_count >= 0:
		if is_negated:
			if has_plus:
				passes = ((cond_disps.size() - overlap_count) >= match_count)	#/ n or more must NOT match
			elif has_minus:
				passes = ((cond_disps.size() - overlap_count) < match_count)	#/ less than n must NOT match
			else:
				#% Exactly n must NOT match:
				passes = ((cond_disps.size() - overlap_count) == match_count)
				#% Strict mode (=!) → actor cannot have extra dispositions:
				if has_equal and passes:
					passes = actor_disps.all(func(d): return cond_disps.has(d))

		else:
			if has_plus:
				passes = (overlap_count >= match_count)							#/ n or more must match
			elif has_minus:
				passes = (overlap_count < match_count)							#/ less than n must match
			else:
				#% Exactly n must match:
				passes = (overlap_count == match_count)
				#% Strict mode (=) → actor cannot have extra dispositions:
				if has_equal and passes:
					passes = actor_disps.all(func(d): return cond_disps.has(d))

	#¦ 2. Symbolic or plain form:
	else:
		if is_negated:
			passes = cond_disps.all(func(d): return not actor_disps.has(d))		#/ none must match
		elif has_equal:
			passes = (actor_disps.size() == cond_disps.size()) and actor_disps.all(func(d): return cond_disps.has(d))
		elif has_plus:
			passes = cond_disps.all(func(d): return actor_disps.has(d))			#/ all listed must match
		elif has_minus:
			passes = actor_disps.all(func(d): return cond_disps.has(d))			#/ all actors must match
		else:
			passes = cond_disps.any(func(d): return actor_disps.has(d))			#/ at least one must match

	#% No dispositions listed → passes:
	if cond_disps.is_empty():
		passes = true

	#@ Step 3F - On failure, skip:
	if not passes:
		#Ł Count for Media_Pause:
		if engine.mp_count_dispositions == true:
			ctx.speech_outcome = "Counted"

		return "Continue"

	#@ Step 4A - Variation selection:
	var chosen_variation: String = engine.use_language
	var variations: Array = speech_data.get("Variations", [])

	#Ł Built-in tag values:
	var active_tags: Dictionary = {}

	#Ł Player tags:
	if "current_player" in candy_de:
		var current_player = candy_de.current_player
		if current_player != "" and candy_de.actors.has(current_player):
			for tag_key in engine.player_tags.keys():
				var actor_attr: String = engine.player_tags[tag_key]
				if candy_de.actors[current_player].has(actor_attr):
					active_tags[tag_key] = str(candy_de.actors[current_player][actor_attr])
	else:
		printerr("Unable to check Player tags: 'var current_player' is missing from User_Data/Data_Tables/Player_Refs.gd. Please see the 'Variations & Translations' guide.")

	#Ł Speaker tags:
	if candy_de.actors.has(speaker_ref):
		for tag_key in engine.speaker_tags.keys():
			var actor_attr: String = engine.speaker_tags[tag_key]
			if candy_de.actors[speaker_ref].has(actor_attr):
				active_tags[tag_key] = str(candy_de.actors[speaker_ref][actor_attr])

	#Ł Passed / disabled tags, most specific first (line, speaker, engine):
	var speaker_data = {}
	if candy_de.actors.has(speaker_ref) and typeof(candy_de.actors[speaker_ref]) == TYPE_DICTIONARY:
		speaker_data = candy_de.actors[speaker_ref]
	var tag_context := " (in %s > %s, line %s)" % [str(current_conversation), str(current_block), str(line_index)]
	var tag_levels: Array = [
		_tag_level(engine, speech_data.get("Passed_Tags", {}), speech_data.get("Disabled_Tags", {}), "the line's Passed_Tags / Disabled_Tags" + tag_context),
		_tag_level(engine, speaker_data.get("PassedTags", []), speaker_data.get("DisabledTags", []), "the PassedTags / DisabledTags of actor '" + str(speaker_ref) + "'" + tag_context),
		_tag_level(engine, engine.passed_tags, engine.disabled_tags, "the passed_tags / disabled_tags of engine '" + str(engine.name) + "'" + tag_context),
	]

	#Ł Script tag answers (one run per tag value):
	var script_tag_results: Dictionary = {}

	#@ Step 4B - Filter variations:
	#? Passes if its language is use_language, all its tags pass, and it isn't numbered (_#int).
	#! Unknown tags (no table entry, no script) fail the variation.
	var passing_variations: Array = []
	for entry in variations:
		for variation_name in entry.keys():
			#% Skip TTS variations:
			if variation_name.ends_with("_TTS") or "_TTS_" in variation_name:
				continue

			#% No text:
			if entry[variation_name].get("Text", "") == "":
				continue

			var parts = variation_name.split("_", false)
			if parts.is_empty():
				continue

			#% Language:
			if parts[0] != engine.use_language:
				continue

			#Ł Tags:
			var all_pass := true
			var is_numbered := false
			for i in range(1, parts.size()):
				var part = parts[i]
				#% Numbered sub-variations (Step 4E):
				if part.begins_with("\u0023") and part.substr(1).is_valid_int():
					is_numbered = true
					break
				var equals_idx = part.find("=")
				var tag_passes := false
				if equals_idx == -1:
					#% Bare tag:
					tag_passes = _tag_state(part, tag_levels) == "passed"
				else:
					var tag_key = part.substr(0, equals_idx)
					var tag_val = part.substr(equals_idx + 1)
					tag_passes = await _tag_passes(engine, tag_key, tag_val, active_tags, tag_levels, speaker_ref, ctx, script_tag_results)
				if not tag_passes:
					all_pass = false
					break

			if is_numbered or not all_pass:
				continue

			passing_variations.append({
				"name": variation_name,
				"tags": {},
				"entry": entry
			})

			#Ł Tags dict for Step 4C:
			var v = passing_variations.back()
			for i in range(1, parts.size()):
				var part = parts[i]
				var equals_idx = part.find("=")
				if equals_idx != -1:
					v["tags"][part.substr(0, equals_idx)] = part.substr(equals_idx + 1)
				else:
					v["tags"][part] = ""

	#@ Step 4C - Drop variations whose tags are a subset of another's:
	var filtered_variations: Array = []
	for i in range(passing_variations.size()):
		var v = passing_variations[i]
		var is_subset := false
		for j in range(passing_variations.size()):
			if i == j:
				continue
			var other = passing_variations[j]
			if v["tags"].size() >= other["tags"].size():
				continue
			var all_in_other := true
			for tag_key in v["tags"].keys():
				if not other["tags"].has(tag_key) or other["tags"][tag_key] != v["tags"][tag_key]:
					all_in_other = false
					break
			if all_in_other:
				is_subset = true
				break
		if not is_subset:
			filtered_variations.append(v)

	#@ Step 4D - Weighted pool:
	var variation_pool: Array = []
	for v in filtered_variations:
		var variation_name: String = v["name"]
		var v_entry = v["entry"]
		if v_entry == null or not v_entry.has(variation_name):
			continue
		var weight := 1
		var raw_weight = v_entry[variation_name].get("Weight", "1")
		if typeof(raw_weight) == TYPE_STRING and raw_weight.strip_edges().is_valid_int():
			weight = max(1, int(raw_weight.strip_edges()))
		for _i in range(weight):
			variation_pool.append(v)

	#Ł Pick one:
	var chosen_v = null
	if variation_pool.size() > 0:
		if engine.random_variations:
			chosen_v = variation_pool[randi() % variation_pool.size()]
		else:
			chosen_v = variation_pool[0]

	#@ Step 4E - Pick the text, among numbered sub-variations:
	var chosen_text := ""
	var text_direction := ""
	var pool: Array = []
	var pool_names: Array = []
	var pool_directions: Array = []

	if chosen_v != null:
		var base_name: String = chosen_v["name"]
		var base_entry = chosen_v["entry"]

		#Ł The variation itself:
		if base_entry.has(base_name):
			var weight := 1
			var raw_weight = base_entry[base_name].get("Weight", "1")
			if typeof(raw_weight) == TYPE_STRING and raw_weight.strip_edges().is_valid_int():
				weight = max(1, int(raw_weight.strip_edges()))
			for _i in range(weight):
				pool.append(base_entry[base_name].get("Text", ""))
				pool_names.append(base_name)
				pool_directions.append(base_entry[base_name].get("Direction", ""))

		#Ł Numbered sub-variations, if random:
		if engine.random_variations:
			for entry in variations:
				for sub_name in entry.keys():
					if not sub_name.begins_with(base_name + "_%s" % "\u0023"):
						continue
					var suffix = sub_name.substr(base_name.length() + 2)
					var suffix_parts = suffix.split("_", false)
					if suffix_parts.is_empty():
						continue
					var number_part = suffix_parts[0]
					if not number_part.is_valid_int():
						continue

					#% Skip TTS:
					if sub_name.ends_with("_TTS") or "_TTS_" in sub_name:
						continue

					#% Skip empty:
					if entry[sub_name].get("Text", "") == "":
						continue
					var weight := 1
					var raw_weight = entry[sub_name].get("Weight", "1")
					if typeof(raw_weight) == TYPE_STRING and raw_weight.strip_edges().is_valid_int():
						weight = max(1, int(raw_weight.strip_edges()))
					for _i in range(weight):
						pool.append(entry[sub_name].get("Text", ""))
						pool_names.append(sub_name)
						pool_directions.append(entry[sub_name].get("Direction", ""))

	#Ł Pick:
	if pool.size() > 0:
		if engine.random_variations:
			var index := randi() % pool.size()
			chosen_text = pool[index]
			chosen_variation = pool_names[index]
			text_direction = pool_directions[index]
			if OS.is_debug_build() and engine.debug_prints == true:
				print("Variation - random: " + str(chosen_variation))
		else:
			chosen_text = pool[0]
			chosen_variation = pool_names[0]
			text_direction = pool_directions[0]

	#Ł A text written as an expression ("¢…") is evaluated first; "¢¢" escapes:
	chosen_text = _evaluate_text(engine, chosen_text)

	#@ Step 4F - No variation, skip:
	if chosen_text == "":
		#Ł Count for Media_Pause:
		if engine.mp_count_variations == true:
			ctx.speech_outcome = "Counted"

		return "Continue"

	var line_str = chosen_text

	#Ł Custom Data of line and variation:
	var custom_data: Array = CandyCustomData.levels([speech_data, _variation_data(variations, chosen_variation)])

	#@ Steps 5 and 6 - Text variables and word substitution:
	var text_context := " (in %s > %s, line %s)" % [str(current_conversation), str(current_block), str(line_index)]
	line_str = _resolve_text(engine, line_str, chosen_variation, text_context)

	#@ Step 6B - Text event markers:
	#? Marked after text variables and substitutions, so a value can bring markers of its own.
	var marked: Dictionary = CandyTextEvents.get_shared().mark_text(engine, self, line_str)
	line_str = marked["text"]
	var text_events: Array = CandyTextEvents.get_shared().resolve(engine, self, speech_data, chosen_variation, marked["names"], text_context)

	#@ Step 6C - Lexicon escapes, as stand-ins the lexicon skips and the display removes:
	line_str = CandyWriting.get_shared().mark_lexicon_escapes(engine, self, line_str)

	#@ Step 7 - Display the line:
	ctx.speech_outcome = "Displayed"

	#° Preparation:
	#Ł Line data:
	var speaker_raw					= speech_data.get("Reference", "")
	speaker_ref						= str(CandyActors.get_shared().actor_from_role(engine, self, engine.candy_ref.resolve_value(engine, engine, speaker_raw, candy_de.candy_ref_symbol), "Spoken_Line", engine.candy_ref.last_literal))
	var portrait_raw: String		= speech_data.get("Portrait", "")
	var sprite_frames_raw: String	= speech_data.get("Sprite_Frames_File", "")
	var play_portrait: String		= str(engine.candy_ref.resolve_value(engine, engine, speech_data.get("Portrait_Play", "1"), candy_de.candy_ref_symbol))
	var portrait_stop: String		= str(engine.candy_ref.resolve_value(engine, engine, speech_data.get("Portrait_Stop", "1"), candy_de.candy_ref_symbol))
	var voice_raw: String			= speech_data.get("Voice", "")
	var direction					= str(engine.candy_ref.resolve_value(engine, engine, text_direction, candy_de.candy_ref_symbol)).to_lower()

	#Ł Role:
	var role_flag := typeof(speaker_raw) == TYPE_STRING and str(speaker_raw).begins_with(candy_de.role_symbol)
	if role_flag and speaker_ref.strip_edges() == "":
		printerr("Spoken_Line: role has no actor assigned → ", str(speaker_raw))
		speaker_ref = str(speaker_raw)

	#. Hook call:
	#? "text": resolved, before the LLM.
	await candy_de.run_hook("x_new_speech_display", {"caller": engine, "line_data": line_data,
		"speaker": speaker_ref, "variation": chosen_variation,
		"text": CandyTextEvents.get_shared().strip_stand_ins(engine, self, line_str)}, custom_data)

	#Ł Resolve Voice:
	var audio = voice_raw
	var voice_value = engine.candy_ref.resolve_value(engine, engine, voice_raw, candy_de.candy_ref_symbol)
	if not engine.candy_ref.last_failed and voice_value != null:
		audio = CandyMedia.to_path(voice_value)

	#Ł Voice path:
	#? No extension added yet: the player's default is (CandyVoice.resolve_stream()).
	#? The variation's folder is in the voice language (voice_language), which can differ from the text's.
	var voice_file := ""
	var voice_variation := CandyVoice.get_shared().voice_variation(engine, self, chosen_variation)
	#¦ 1. Absolute path → the "Default" file:
	if typeof(audio) == TYPE_STRING and CandyMedia.is_resource_path(audio):
		voice_file = audio

		#Ł Variation subfolder, e.g. "res://Folder/hello.ogg" → "res://Folder/French/hello.ogg":
		voice_file = CandyVoice.get_shared().insert_variation_folder(engine, self, voice_file, voice_variation)

	#¦ 2. File name → voice_logic and voice_path:
	else:
		var file_name = str(audio)
		if file_name == "":
			file_name = "Default"

		#? A nested line (in a choice...) takes its block line's number.
		var voice_line := int(line_index)
		if ctx.nested and typeof(engine.line_tracker) == TYPE_INT:
			voice_line = engine.line_tracker

		voice_file = CandyVoice.get_shared().build_path(engine, self, file_name, speaker_ref,
			str(current_conversation), str(current_block), voice_line, voice_variation)

	#Ł Display name:
	#? The name gets no lexicon: an escaped one (a sanitized player input) loses its symbols.
	var speaker_display: String = CandyWriting.get_shared().remove_lexicon_escapes(engine, self, CandyActors.get_shared().display_name(engine, self, speaker_ref))
	#% A literal name (Literal_Variables.gd) - its BBCode is displayed as written, unless allowed:
	var name_rule = CandyActors.get_shared().display_name_rule(engine, self, speaker_ref)
	if not CandySanitizer.literal_allows(name_rule, "bbcode"):
		speaker_display = CandySanitizer.bbcode(speaker_display)

	#Ł Speech:
	var speech := CandySpeech.new()
	speech.speaker_ref = speaker_ref
	speech.speech_data = speech_data
	speech.line_data = line_data
	speech.conversation = str(current_conversation)
	speech.block = str(current_block)
	speech.line_index = int(line_index)
	speech.custom_data = custom_data

	#° Dialogue Mode:
	#Ł Mode and bubbles exempt mode:
	var style := _resolve_mode(engine, speech, "dialogue_mode")
	var exempt_style := _resolve_mode(engine, speech, "bubbles_exempt_mode")

	#Ł Prepare, or hand to another mode:
	style = _prepare_mode(engine, speech, style, exempt_style)

	#Ł Display node:
	#? If null, the previous line is still cleared.
	var display_node := _display_node(engine, style, speech)

	#Ł Resolve settings:
	speech.style = style
	speech.settings = CandySettings.get_shared().resolve_all(engine, self, speech, display_node)

	#Ł "_TTS" variation text, for TTS modes other than "Off" and "Simple":
	var tts_mode := CandyVoice.tts_mode_name(CandySettings.get_shared().get_value(engine, self, speech, "text_to_speech"))
	if CandySettings.get_shared().get_value(engine, self, speech, "enable_voice") == true \
			and tts_mode != CandyVoice.TTS_OFF and tts_mode != CandyVoice.TTS_SIMPLE:
		#Ł Resolve, then strip text event markers (values can bring some):
		var tts_text: String = _evaluate_text(engine, str(_variation_data(variations, chosen_variation + "_TTS").get("Text", "")))
		if tts_text != "":
			tts_text = _resolve_text(engine, tts_text, chosen_variation, text_context)
			tts_text = CandyTextEvents.get_shared().strip_markers(engine, self, tts_text)
			speech.tts_text = CandyWriting.get_shared().remove_lexicon_escapes(engine, self, tts_text)

	#Ł LLM:
	#? Before clearing, so a slow reply doesn't leave the screen empty.
	if speech.settings.get("llm_mode", false) == true:
		#Ł All dispositions:
		var actor_disps_array: Array = []
		if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].get("Disposition") != null:
			var raw_disp = str(candy_de.actors[speaker_ref]["Disposition"]).strip_edges()
			actor_disps_array = raw_disp.split(",", false)
			actor_disps_array = actor_disps_array.map(func(x): return x.strip_edges())

		#Ł Replaces the text, markers included:
		var llm_result = await candy_de.call_hook("llm_query", {
			"caller": engine, "actor_ref": speaker_ref, "actor_name": speaker_display,
			"actor_disps": actor_disps_array, "text": CandyTextEvents.get_shared().strip_stand_ins(engine, self, line_str), "variation": chosen_variation,
			"dialogue": engine.running_dialogue_file, "conversation": str(current_conversation),
			"block": str(current_block), "line_index": int(line_index), "line_data": line_data}, custom_data)
		#% No reply - keep the text:
		if typeof(llm_result) == TYPE_STRING:
			line_str = llm_result

	#Ł Clear previous dialogue:
	engine.clear_previous_dialogue(style, speech)
	engine.previous_mode = style
	engine.previous_speaker = speaker_ref

	if display_node == null:
		return "Continue"

	#Ł Lexicon off - keywords written as their "Disabled" text (displays only format when it's on):
	if speech.settings.get("lexicon_mode", true) != true and candy_de.lexicon is Dictionary:
		line_str = CandyWriting.get_shared().apply_lexicon_disabled(engine, self, line_str, candy_de.lexicon, chosen_variation)

	#Ł Fill the speech:
	speech.speaker_display = speaker_display
	speech.text = line_str
	speech.disposition = disposition_cond
	speech.chosen_variation = chosen_variation
	speech.direction = direction
	speech.voice_file = voice_file
	speech.voice_variation = voice_variation
	speech.portrait_raw = portrait_raw
	speech.sprite_frames_raw = sprite_frames_raw
	speech.play_portrait = play_portrait
	speech.portrait_stop = portrait_stop
	speech.text_events = text_events
	speech.display_node = display_node

	#Ł Display the line:
	@warning_ignore("redundant_await")
	await display_node.display(engine, speech, custom_data)

	#Ł Strip leftover markers:
	speech.text = CandyTextEvents.get_shared().strip_stand_ins(engine, self, speech.text)

	#. Hook call:
	#? Not if stopped.
	if engine.killswitch == false:
		await candy_de.run_hook("x_speech_advance", {"caller": engine, "line_data": line_data, "speech": speech}, custom_data)

	return "Continue"


#* Resolve text variables and word substitutions:
func _resolve_text(engine: CandyEngine, text: String, chosen_variation: String, context: String) -> String:
	#@ Step 1 (5) - Text variables:
	#? Rescanned until unchanged, as values can hold text variables. ¤¤ = the symbol.
	var start_tag: String = candy_de.text_var_start_symbol
	var end_tag: String = candy_de.text_var_end_symbol
	text = _hide_escaped_symbols(text, start_tag, end_tag, ESCAPED_TEXT_VAR_START, ESCAPED_TEXT_VAR_END, true)

	var text_var_passes := 0
	var changed := true
	while changed and start_tag != "" and end_tag != "":
		changed = false
		text_var_passes += 1
		if text_var_passes > TEXT_VARIABLE_MAX_PASSES:
			printerr("Candy DE - Text variables still expanding after ", TEXT_VARIABLE_MAX_PASSES, " passes: a value probably contains itself", context)
			break

		var pos := 0
		while true:
			var start_idx := text.find(start_tag, pos)
			if start_idx == -1:
				break
			var inner_start := start_idx + start_tag.length()
			var end_idx := _find_text_variable_end(text, inner_start, end_tag)
			if end_idx == -1:
				break

			var inner := text.substr(inner_start, end_idx - inner_start)
			#Ł Escape doubled symbols in the value:
			var replacement := _text_variable(engine, inner, context)
			replacement = _hide_escaped_symbols(replacement, start_tag, end_tag, ESCAPED_TEXT_VAR_START, ESCAPED_TEXT_VAR_END, true)

			#Ł Replace:
			text = text.substr(0, start_idx) + replacement + text.substr(end_idx + end_tag.length())
			pos = start_idx + replacement.length()
			changed = true

	#@ Step 2 (6) - Word substitution:
	#? Tokens - •word¦actor• or •word¦actor¦property•, •• = the symbol.
	text = _hide_escaped_symbols(text, candy_de.substitution_start_symbol, candy_de.substitution_end_symbol, ESCAPED_SUBSTITUTION_START, ESCAPED_SUBSTITUTION_END, false)
	if candy_de.substitution_table != null:
		var gsym = candy_de.substitution_start_symbol
		var gend = candy_de.substitution_end_symbol
		var gsep = candy_de.separator_symbol
		var search_pos := 0

		#Ł Helper - nested value ("stats.Age", "stats.0.Name"):
		var _get_nested_property = func(data: Variant, path: String) -> Variant:
			var parts = path.split(".", false)
			var current = data
			for part in parts:
				if typeof(current) == TYPE_DICTIONARY:
					if not current.has(part):
						return null
					current = current[part]
				elif typeof(current) == TYPE_ARRAY:
					if not part.is_valid_int():
						return null
					var idx = int(part)
					if idx < 0 or idx >= current.size():
						return null
					current = current[idx]
				else:
					return null
			return current

		#Ł Helper - capitalize the first letter:
		#! capitalize() turns underscores into spaces.
		var _capitalize_first = func(word: String) -> String:
			if word == "":
				return word
			return word.substr(0, 1).to_upper() + word.substr(1)

		#Ł Type names for type hints and 'type':
		var type_map := {
			"int": TYPE_INT,
			"float": TYPE_FLOAT,
			"bool": TYPE_BOOL,
			"string": TYPE_STRING,
			"array": TYPE_ARRAY,
			"dict": TYPE_DICTIONARY,
			"dictionary": TYPE_DICTIONARY,
		}

		while true:
			var start_idx := text.find(gsym, search_pos)

			if start_idx == -1:
				break

			var end_idx := text.find(gend, start_idx + gsym.length())
			if end_idx == -1:
				break

			#Ł "word¦actor" or "word¦actor¦property":
			var token := text.substr(
				start_idx + gsym.length(),
				end_idx - (start_idx + gsym.length())
			)

			var parts := token.split(gsep, false)
			if parts.size() < 2:
				push_warning("Candy DE - Word Substitution: token '" + token + "' has no actor reference" + context)
				search_pos = end_idx + gend.length()
				continue

			var source_word_raw := parts[0]
			var source_word := parts[0].strip_edges()
			var actor_ref2 := parts[1].strip_edges()

			#Ł Each part may be a reference, as in text variables ("°npc1", "¢globals.word"):
			var word_res := _inline_value(engine, source_word)
			if word_res["resolved"] and word_res["value"] != null:
				source_word = str(word_res["value"]).strip_edges()
				source_word_raw = source_word

			var actor_res := _inline_value(engine, actor_ref2)
			if actor_res["resolved"] and actor_res["value"] != null:
				actor_ref2 = str(actor_res["value"]).strip_edges()

			var category_override := ""
			if parts.size() >= 3:
				category_override = parts[2].strip_edges()
				var category_res := _inline_value(engine, category_override)
				if category_res["resolved"] and category_res["value"] != null:
					category_override = str(category_res["value"]).strip_edges()

			if not candy_de.actors.has(actor_ref2):
				push_warning("Candy DE - Word Substitution: actor '" + actor_ref2 + "' not found in the actors dictionary, from token '" + token + "'" + context)
				search_pos = end_idx + gend.length()
				continue

			var base := source_word.to_lower()
			var replacement_base := ""
			var matched := false
			var case_rule := "auto"

			#Ł Matching variations:
			var variation_matches_array: Array = []
			var exact_matches: Array = []

			for variation_key in candy_de.substitution_table.keys():
				var vk: String = variation_key
				if vk == "*":
					variation_matches_array.append(variation_key)
				elif vk.ends_with("*"):
					var prefix = vk.substr(0, vk.length() - 1)
					if chosen_variation.begins_with(prefix):
						variation_matches_array.append(variation_key)
				elif vk == chosen_variation:
					variation_matches_array.append(variation_key)
					exact_matches.append(variation_key)

			#Ł Those with the word:
			var word_table: Dictionary
			var viable_variations: Array = []

			for variation_key in variation_matches_array:
				word_table = candy_de.substitution_table[variation_key]
				for key in word_table.keys():
					var options: Array = key.split(",", false)
					options = options.map(func(x): return x.strip_edges().to_lower())
					if options.has(base):
						viable_variations.append(variation_key)
						break

			if viable_variations.size() == 0:
				push_warning("Candy DE - Word Substitution: keyword '" + source_word + "' not found in any substitution table matching variation '" + chosen_variation + "', from token '" + token + "'" + context)
				search_pos = end_idx + gend.length()
				continue

			#Ł Sort by specificity (most specific last):
			viable_variations.sort_custom(func(a, b):
				var la: int = a.trim_suffix("*").length()
				var lb: int = b.trim_suffix("*").length()
				if la == lb:
					return a < b
				return la < lb
			)

			#Ł Exact matches last:
			for ex in exact_matches:
				if viable_variations.has(ex):
					viable_variations.erase(ex)
					viable_variations.append(ex)

			var best_variation_key = viable_variations.back()
			word_table = candy_de.substitution_table[best_variation_key]

			#Ł Word groups ("he, she", "class"...):
			for key in word_table.keys():
				var options: Array = key.split(",", false)
				options = options.map(func(x): return x.strip_edges().to_lower())
				if not options.has(base):
					continue

				var category_list = word_table[key]

				#Ł Case rule (optional first element):
				var entry_start_index := 0
				if category_list.size() > 0 and typeof(category_list[0]) == TYPE_STRING:
					case_rule = category_list[0]
					entry_start_index = 1
				else:
					case_rule = "auto"

				#% Numeric override → index:
				var specific_entry_index := -1
				if category_override.is_valid_int():
					specific_entry_index = clamp(int(category_override) - 1 + entry_start_index, entry_start_index, category_list.size() - 1)

				#Ł Multi-category search:
				var i_start := entry_start_index
				var i_end = category_list.size()

				#¦ 1. Numeric override → that property only:
				if specific_entry_index >= 0:
					i_start = specific_entry_index
					i_end = specific_entry_index + 1

				#¦ 2. No property specified → first property only:
				elif category_override == "":
					i_end = min(entry_start_index + 1, category_list.size())

				#¦ 3. Named override → filtered by name below:
				for i in range(i_start, i_end):
					var entry = category_list[i]
					for category_key in entry.keys():
						var override_names: Array = category_override.split(",", false)
						override_names = override_names.map(func(x): return x.strip_edges())

						var cat_names: Array = category_key.split(",", false)
						cat_names = cat_names.map(func(x): return x.strip_edges())

						if category_override != "" and not category_override.is_valid_int() and cat_names != override_names:
							continue

						var actor_values := []
						var actor_raw_values := []
						var valid_group := true
						for cname in cat_names:
							var val = _get_nested_property.call(candy_de.actors[actor_ref2], cname)
							if val == null:
								valid_group = false
								break
							actor_raw_values.append(val)
							actor_values.append(str(val).strip_edges())
						if not valid_group:
							continue

						var value_map = entry[category_key]

						#Ł Match rules:
						for vk_rule in value_map.keys():
							var rules: Array = vk_rule.split(",", false)
							rules = rules.map(func(x): return x.strip_edges())
							var all_match := true
							for r_i in range(rules.size()):
								#% More values than properties → fails:
								if r_i >= actor_values.size():
									all_match = false
									break

								var rule = rules[r_i].strip_edges()

								#% Skip marker (empty_symbol):
								if rule == engine.empty_symbol:
									continue

								var prop_value = actor_values[r_i]

								#Ł Property value as text:
								match typeof(prop_value):
									TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
										prop_value = str(prop_value)
									TYPE_ARRAY, TYPE_DICTIONARY:
										prop_value = JSON.stringify(prop_value)
									TYPE_STRING:
										prop_value = prop_value.strip_edges()
									_:
										prop_value = str(prop_value)

								#Ł Parse rule:
								var op_part := ""
								var value_part = rule
								var type_hint := ""
								var type_compare := false
								var parts_rule = rule.split(gsep, false)

								#% operator¦value¦type:
								if parts_rule.size() == 3:
									op_part = parts_rule[0].strip_edges()
									value_part = parts_rule[1].strip_edges()
									type_hint = parts_rule[2].strip_edges().to_lower()

								elif parts_rule.size() == 2:
									var known_types := ["int", "float", "bool", "string", "array", "dict", "dictionary"]
									var left = parts_rule[0].strip_edges()
									var right = parts_rule[1].strip_edges().to_lower()
									var left_lc = left.to_lower()

									var is_operator = left in [">", "<", ">=", "<="]
									var is_number = right.is_valid_float() or right.is_valid_int()
									var is_known_type = right in known_types
									var is_type_compare = right == "type" and left_lc in known_types

									if is_operator and is_number:
										op_part = left
										value_part = right
									elif is_type_compare:
										type_compare = true
										value_part = left_lc
									elif is_known_type:
										value_part = left
										type_hint = right
									else:
										value_part = rule

								else:
									value_part = rule

								#% Type comparison (int¦type...):
								if type_compare:
									var nested_val = _get_nested_property.call(candy_de.actors[actor_ref2], cat_names[r_i])
									if nested_val == null or typeof(nested_val) != type_map.get(value_part, -1):
										all_match = false
									continue

								#% Type hint - property must be of that type:
								if type_hint != "":
									if typeof(actor_raw_values[r_i]) != type_map.get(type_hint, -1):
										all_match = false
										break

								#Ł Convert by type hint:
								match type_hint:
									"int":
										value_part = int(value_part)
										prop_value = int(prop_value)
									"float":
										value_part = float(value_part)
										prop_value = float(prop_value)
									"bool":
										value_part = (value_part.to_lower() in ["true", "1", "yes"])
										prop_value = str(prop_value).to_lower() in ["true", "1", "yes"]
									"array":
										var parsed_value = JSON.parse_string(value_part)
										var parsed_prop = JSON.parse_string(prop_value)
										if typeof(parsed_value) == TYPE_ARRAY and typeof(parsed_prop) == TYPE_ARRAY:
											value_part = parsed_value
											prop_value = parsed_prop
									"dict", "dictionary":
										var parsed_value = JSON.parse_string(value_part)
										var parsed_prop = JSON.parse_string(prop_value)
										if typeof(parsed_value) == TYPE_DICTIONARY and typeof(parsed_prop) == TYPE_DICTIONARY:
											value_part = parsed_value
											prop_value = parsed_prop
									_:
										pass

								#Ł Operator or equality:
								if op_part != "":
									#% Non-numeric property → fails:
									if not str(prop_value).is_valid_float():
										all_match = false
									else:
										var num_prop := float(prop_value)
										var num_val := float(value_part)
										match op_part:
											">": if not num_prop > num_val: all_match = false
											"<": if not num_prop < num_val: all_match = false
											">=": if not num_prop >= num_val: all_match = false
											"<=": if not num_prop <= num_val: all_match = false
								else:
									if prop_value != value_part:
										all_match = false

								if not all_match:
									break

							if all_match:
								replacement_base = str(value_map[vk_rule])
								matched = true
								break

						if matched:
							break
					if matched:
						break
				if matched:
					break

			#% No substitution:
			if not matched or replacement_base == "":
				if matched:
					push_warning("Candy DE - Word Substitution: keyword '" + source_word + "' matched a rule in '" + str(best_variation_key) + "' but its substitute word is empty, from token '" + token + "'" + context)
				else:
					push_warning("Candy DE - Word Substitution: no rule in '" + str(best_variation_key) + "' matched actor '" + actor_ref2 + "' for keyword '" + source_word + "', from token '" + token + "'" + context)
				search_pos = end_idx + gend.length()
				continue

			#Ł Case:
			var final_word := ""
			match case_rule.to_lower():
				"custom", "x":
					final_word = replacement_base
				"lowercase", "lower", "low", "l":
					final_word = replacement_base.to_lower()
				"uppercase", "upper", "up", "u":
					final_word = replacement_base.to_upper()
				"capitalized", "cap", "c":
					final_word = _capitalize_first.call(replacement_base)
				"auto", "a", "", _:
					if source_word_raw == source_word_raw.to_upper():
						final_word = replacement_base.to_upper()
					elif source_word_raw == source_word_raw.to_lower():
						final_word = replacement_base.to_lower()
					elif source_word_raw == _capitalize_first.call(source_word_raw):
						final_word = _capitalize_first.call(replacement_base)
					else:
						final_word = replacement_base.to_lower()

			#Ł Replace token:
			text = text.substr(0, start_idx) \
					+ final_word \
					+ text.substr(end_idx + gend.length())

			search_pos = start_idx + final_word.length()

	#Ł Restore escaped symbols, single:
	text = text.replace(ESCAPED_TEXT_VAR_START, candy_de.text_var_start_symbol)
	text = text.replace(ESCAPED_TEXT_VAR_END, candy_de.text_var_end_symbol)
	text = text.replace(ESCAPED_SUBSTITUTION_START, candy_de.substitution_start_symbol)
	text = text.replace(ESCAPED_SUBSTITUTION_END, candy_de.substitution_end_symbol)

	return text


#* A variation's keys by name, or {}:
func _variation_data(variations: Array, variation_name: String) -> Dictionary:
	for entry in variations:
		if typeof(entry) == TYPE_DICTIONARY and entry.has(variation_name) and typeof(entry[variation_name]) == TYPE_DICTIONARY:
			return entry[variation_name]
	return {}


#* One level's tags: {"passed": [tags], "disabled": [tags]}:
func _tag_level(engine: CandyEngine, passed: Variant, disabled: Variant, label: String) -> Dictionary:
	var level := {"passed": _tag_list(engine, passed, label), "disabled": _tag_list(engine, disabled, label)}
	var in_both: Array = level["passed"].filter(func(tag): return level["disabled"].has(tag))
	if not in_both.is_empty():
		push_warning("Candy DE - Variation tags: '" + "', '".join(in_both) + "' both passed and disabled in " + label + " - treated as disabled.")
	return level


#* Tags in a passed or disabled list:
func _tag_list(engine: CandyEngine, value: Variant, label: String) -> Array:
	var entries: Array = []
	if typeof(value) == TYPE_DICTIONARY:
		entries = value.values()
	elif typeof(value) == TYPE_ARRAY or typeof(value) == TYPE_PACKED_STRING_ARRAY:
		entries = Array(value)
	elif not CandySettings.is_not_set(value):
		push_warning("Candy DE - Variation tags: " + label + " should be a list of tags, not '" + str(value) + "' - ignored.")
		return []

	var tags: Array = []
	for entry in entries:
		var resolved = engine.candy_ref.resolve_value(engine, engine, entry, candy_de.candy_ref_symbol)
		var found: Array = [resolved]
		if typeof(resolved) == TYPE_ARRAY or typeof(resolved) == TYPE_PACKED_STRING_ARRAY:
			found = Array(resolved)
		for tag in found:
			if CandySettings.is_not_set(tag):
				continue
			var text := str(tag).strip_edges()
			if text != "" and not tags.has(text):
				tags.append(text)
	return tags


#* A tag's state: "passed", "disabled", or "" if unlisted:
func _tag_state(tag_key: String, tag_levels: Array) -> String:
	#? Most specific level first; in both → disabled.
	for level in tag_levels:
		if level["disabled"].has(tag_key):
			return "disabled"
		if level["passed"].has(tag_key):
			return "passed"
	return ""


#* Whether a "tag_key=tag_value" tag passes:
func _tag_passes(engine: CandyEngine, tag_key: String, tag_value: String, active_tags: Dictionary, tag_levels: Array, speaker_ref: Variant, ctx: CandyContext, script_results: Dictionary) -> bool:
	#% Passed / disabled tags:
	var state := _tag_state(tag_key, tag_levels)
	if state == "passed":
		return true
	if state == "disabled":
		return false

	#% player_tags / speaker_tags (even if the actor lacks the attribute):
	if engine.player_tags.has(tag_key) or engine.speaker_tags.has(tag_key):
		return active_tags.has(tag_key) and active_tags[tag_key] == tag_value

	#Ł Variation_Tags script, asked once per "tag_key=tag_value":
	var registry_key := tag_key.to_lower()
	if not engine.variation_tag_registry.has(registry_key):
		return false

	var result_key := tag_key + "=" + tag_value
	if not script_results.has(result_key):
		var tag_script: CandyVariationTag = engine.variation_tag_registry[registry_key]
		@warning_ignore("redundant_await")
		var answer = await tag_script.matches(engine, tag_value, str(speaker_ref), ctx)
		script_results[result_key] = answer == true

	return script_results[result_key]


#* The mode's display node, or null:
func _display_node(engine: CandyEngine, style: String, speech: CandySpeech) -> Node:
	var mode_script := engine.get_dialogue_mode(style)
	if mode_script == null:
		printerr("Spoken_Line: unknown dialogue mode → ", style, " (no script of that name in Dialogue_Modes)")
		return null

	var node: Node = mode_script.display_node(engine, speech)
	if node == null:
		printerr("Spoken_Line: nothing to display the line with in '%s' mode." % style)
		return null

	if not node.has_method("display"):
		printerr("Spoken_Line: '%s' has no display() function, so it can't display lines in '%s' mode." % [node.name, style])
		return null

	return node


#* The line's dialogue_mode or bubbles_exempt_mode:
func _resolve_mode(engine: CandyEngine, speech: CandySpeech, setting: String) -> String:
	#? Line, else actor, else engine; unavailable line / actor modes skipped.
	var values: Array = CandySettings.get_shared().candidates(engine, self, speech, null, setting)
	for i in values.size():
		var mode_script := engine.get_dialogue_mode(values[i])
		if i == values.size() - 1:
			if mode_script == null:
				return str(values[i])
			return mode_script.mode_name()		#/ Script's name ("box" → "Box")
		if mode_script != null and mode_script.is_available(engine):
			return mode_script.mode_name()		#/ Script's name
	return str(values[-1])


#* The mode that displays the line, after each mode's prepare():
func _prepare_mode(engine: CandyEngine, speech: CandySpeech, style: String, exempt_style: String) -> String:
	var mode := style
	var tried: Array[String] = []
	while true:
		var mode_script := engine.get_dialogue_mode(mode)
		if mode_script == null:
			return mode
		mode = mode_script.mode_name()
		tried.append(mode)

		var next_mode := mode_script.prepare(engine, speech)
		#% "" → exempt mode:
		if next_mode == "":
			next_mode = exempt_style
		var next_script := engine.get_dialogue_mode(next_mode)
		if next_script != null:
			next_mode = next_script.mode_name()

		if next_mode == mode:
			return mode
		#% Mode met twice:
		if next_mode in tried:
			printerr("Spoken_Line: dialogue modes ", " → ".join(tried), " → ", next_mode, " hand the line back and forth - using '", next_mode, "'.")
			return next_mode
		mode = next_mode
	return mode


#?##############################
#& REFERENCES INSIDE TEXT:
#?########################
#region
#* A text variable's text. "inner": between the symbols:
func _text_variable(engine: CandyEngine, inner: String, context: String) -> String:
	var text := inner.strip_edges()
	var sym: String = candy_de.candy_ref_symbol

	#¦ 1. Bare role (¤°npc1¤) - its actor's name:
	var role_key := CandyActors.get_shared().role_name(engine, self, text)
	if role_key != "" and _path_start(role_key) == -1:
		if not candy_de.roles.has(role_key):
			printerr("Candy DE - Text variable: unknown role → ", inner, context)
			return inner
		var role_actor := str(candy_de.roles[role_key])
		if not candy_de.actors.has(role_actor):
			printerr("Candy DE - Text variable: the role's actor '", role_actor, "' is not in the actors dictionary → ", inner, context)
			return inner
		return _literal_text(CandyActors.get_shared().text_name(engine, self, role_actor), CandyActors.get_shared().text_name_rule(engine, self, role_actor))

	#¦ 2. Expression (¤¢globals.hp + 1¤), or shortcut / lookup symbol (¤°npc1.Age¤):
	if text.begins_with(sym) or _starts_with_symbol(engine.candy_ref, text):
		var result := _inline_value(engine, text)
		if result["resolved"]:
			return _literal_text(_display_text(result["value"]), engine.candy_ref.last_literal)
		printerr("Candy DE - Text variable: could not resolve → ", inner, context)
		return inner

	#¦ 3. Actor (¤Alice¤), optionally with a key (¤Alice.Age¤, ¤Alice["Age"]¤):
	var split := _path_start(text)
	var actor_name := text
	if split != -1:
		actor_name = text.substr(0, split).strip_edges()

	if not candy_de.actors.has(actor_name):
		printerr("Candy DE - Text variable: '", actor_name, "' is not an actor, and has no symbol to evaluate it → ", inner, context)
		return inner

	if split == -1:
		return _literal_text(CandyActors.get_shared().text_name(engine, self, actor_name), CandyActors.get_shared().text_name_rule(engine, self, actor_name))

	#Ł Alice.Age →¢candy_de.actors["Alice"].Age:
	var expression := sym + "candy_de.actors[" + var_to_str(actor_name) + "]" + text.substr(split)
	var value = engine.candy_ref.resolve_value(engine, engine, expression, sym)
	if engine.candy_ref.last_failed:
		printerr("Candy DE - Text variable: could not resolve → ", inner, context)
		return inner
	return _literal_text(_display_text(value), engine.candy_ref.last_literal)


#* Evaluate a spoken text written as an expression, before markers and text variables:
#? "¢globals.greeting" → its value; "¢¢Price" → "¢Price"; a failed expression keeps the text as written.
func _evaluate_text(engine: CandyEngine, text: String) -> String:
	var sym: String = candy_de.candy_ref_symbol
	if sym == "" or not text.begins_with(sym):
		return text
	var value = engine.candy_ref.resolve_value(engine, engine, text, sym)
	if engine.candy_ref.last_failed:
		return text		#/ Error printed by CandyRef
	if value == null:
		return ""
	return _literal_text(str(value), engine.candy_ref.last_literal)


#* Evaluate a reference inside spoken text:
func _inline_value(engine: CandyEngine, text: String) -> Dictionary:
	var sym: String = candy_de.candy_ref_symbol
	var expression := text.strip_edges()
	#% Shortcut / lookup symbol - "°npc1.Age" → "¢°npc1.Age":
	if not expression.begins_with(sym):
		if not _starts_with_symbol(engine.candy_ref, expression):
			return {"resolved": false, "value": text}		#/ Plain text
		expression = sym + expression

	var value = engine.candy_ref.resolve_value(engine, engine, expression, sym)
	if engine.candy_ref.last_failed:
		return {"resolved": false, "value": text}		#/ Failed
	return {"resolved": true, "value": value}


#* Whether text starts with a shortcut or lookup symbol:
func _starts_with_symbol(cr: CandyRef, text: String) -> bool:
	for symbol in cr.shortcut_symbols.keys() + cr.lookup_symbols.keys():
		if typeof(symbol) == TYPE_STRING and symbol != "" and text.begins_with(symbol):
			return true
	return false


#* Index where a key path starts ('[' or '.'), or -1 if there is none:
func _path_start(text: String) -> int:
	var bracket := text.find("[")
	var dot := text.find(".")
	if bracket == -1:
		return dot
	if dot == -1:
		return bracket
	return mini(bracket, dot)


#* A value as text (null → ""):
func _display_text(value: Variant) -> String:
	if value == null:
		return ""
	return str(value)


#* A value for spoken text - escaped as its literal rule says (Literal_Variables.gd), if it has one:
#? rule: CandyRef's last_literal, or CandyActors' name rule; null for an ordinary value.
func _literal_text(text: String, rule: Variant) -> String:
	if rule is Array:
		return CandySanitizer.literal(text, rule)
	return text


#* Index of a text variable's end symbol outside quotes and brackets, or -1:
func _find_text_variable_end(text: String, from: int, end_tag: String) -> int:
	var depth := 0
	var quote := ""
	var i := from
	while i < text.length():
		var ch := text[i]

		#% Inside quotes:
		if quote != "":
			if ch == "\\":
				i += 2
				continue
			if ch == quote:
				quote = ""
			i += 1
			continue

		if depth == 0 and text.substr(i, end_tag.length()) == end_tag:
			return i

		if ch == "\"" or ch == "'":
			quote = ch
		elif ch == "(" or ch == "[" or ch == "{":
			depth += 1
		elif (ch == ")" or ch == "]" or ch == "}") and depth > 0:
			depth -= 1
		i += 1
	return -1


#* Replace doubled symbols (¤¤, ••) with stand-ins:
func _hide_escaped_symbols(text: String, start_tag: String, end_tag: String, start_mark: String, end_mark: String, expression_tokens: bool) -> String:
	if start_tag == "" or end_tag == "":
		return text

	var result := ""
	var i := 0
	while i < text.length():
		#% Doubled start symbol (¤¤¤A¤ = a "¤", then a text variable):
		if text.substr(i, start_tag.length() * 2) == start_tag + start_tag:
			result += start_mark
			i += start_tag.length() * 2
			continue

		#% Doubled end symbol (if different):
		if end_tag != start_tag and text.substr(i, end_tag.length() * 2) == end_tag + end_tag:
			result += end_mark
			i += end_tag.length() * 2
			continue

		#% Token - kept whole, so doubles inside don't count (¤A¤¤B¤, ¤A¤¤¤):
		if text.substr(i, start_tag.length()) == start_tag:
			var inner_start := i + start_tag.length()
			var end_idx := -1
			#Ł Text variables skip quotes / brackets, others end at the first end symbol:
			if expression_tokens:
				end_idx = _find_text_variable_end(text, inner_start, end_tag)
			else:
				end_idx = text.find(end_tag, inner_start)
			if end_idx != -1:
				result += text.substr(i, end_idx + end_tag.length() - i)
				i = end_idx + end_tag.length()
				continue

		result += text[i]
		i += 1
	return result
#endregion
