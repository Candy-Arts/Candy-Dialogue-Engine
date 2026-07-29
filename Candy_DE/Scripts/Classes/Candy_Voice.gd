#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVoice
extends RefCounted


#^ Voice file settings (Candy_Properties.gd):
#? voice_logic values:
const VOICE_LOGICS: Array[String] = ["Folder"]
#? voice_path tags:
const VOICE_PATH_TAGS: Array[String] = ["{actor}", "{dialogue}", "{conversation}", "{block}", "{line}"]
#? Defaults when missing from Candy_Properties.gd:
const DEFAULT_VOICE_LOGIC := "Folder"
const DEFAULT_VOICE_PATH := "{actor}/{conversation}/{block}"

#^ TTS modes (text_to_speech, tts_advanced_fallback):
#? Other names are custom modes, passed to the tts() hook.
const TTS_OFF := "Off"
const TTS_SIMPLE := "Simple"
const TTS_ADVANCED := "Advanced"
const TTS_MODES: Array[String] = [TTS_OFF, TTS_SIMPLE, TTS_ADVANCED]


#^ Shared instance:
static var _shared: CandyVoice = null

#* Get the shared instance:
static func get_shared() -> CandyVoice:
	if _shared == null:
		_shared = CandyVoice.new()
	return _shared

#* Normalize a TTS mode name:
static func tts_mode_name(value: Variant) -> String:
	var mode_name := str(value).strip_edges()
	if mode_name == "":
		return TTS_OFF
	for known in TTS_MODES:
		if known.to_lower() == mode_name.to_lower():
			return known		#/ Known mode, in its own case
	return mode_name		#/ Custom mode, as written


#? Unused 'caller' parameters:
@warning_ignore_start("unused_parameter")

#* Start a line's voice playback:
func start_playback(source: CandyEngine, caller: Object, voice_player, speech: CandySpeech = null) -> void:
	if CandySettings.get_shared().get_value(source, caller, speech, "enable_voice") != true:
		return
	if voice_player == null or voice_player.stream == null:
		return

	var custom_data: Array = []
	if speech != null:
		custom_data = speech.custom_data

	#. Hook:
	await candy_de.run_node_hook(voice_player, "x_playback_starting",
		{"caller": source, "node": voice_player}, custom_data)

	source.active_voice_player = voice_player		#/ For suspension
	voice_player.play()

	#. Hook:
	await candy_de.run_node_hook(voice_player, "x_playback_started",
		{"caller": source, "node": voice_player}, custom_data)

#* Stop a line's voice playback:
func stop_playback(source: CandyEngine, caller: Object, voice_player) -> void:
	if voice_player == null:
		return

	voice_player.stop()

	if source.active_voice_player == voice_player:
		source.active_voice_player = null

#* Standalone Voice player ("Voice" mode), or null:
func get_player(source: CandyEngine, caller: Object) -> Node:
	return CandyUI.get_shared().get_element(source, caller, "voice_player_path")

#* Default voice file extension for a voice player:
func default_extension(source: CandyEngine, caller: Object, voice_player: Node) -> String:
	var player_extension = ""
	if voice_player != null and "default_voice_extension" in voice_player:
		player_extension = voice_player.default_voice_extension
	#? Candy_Properties.gd → engine → player.
	return CandyPlayback.get_shared().resolve_extension(source, caller, "default_voice_extension", player_extension)

#* Set the voice player's stream (TTS or voice file):
func resolve_stream(source: CandyEngine, caller: Object, voice_player, speech: CandySpeech, tts_text: String) -> Node:
	var settings := CandySettings.get_shared()

	#% Voice off:
	if settings.get_value(source, caller, speech, "enable_voice") != true:
		if voice_player != null:
			if voice_player.playing:
				voice_player.stop()
			voice_player.stream = null
		return voice_player

	#@ Step 1 - TTS mode, with fallback when there is no "_TTS" variation:
	var tts_mode := tts_mode_name(settings.get_value(source, caller, speech, "text_to_speech"))
	if tts_mode == TTS_ADVANCED and speech.tts_text == "":
		tts_mode = tts_mode_name(settings.get_value(source, caller, speech, "tts_advanced_fallback"))
		#? Fallback "Advanced" has nothing to read.
		if tts_mode == TTS_ADVANCED:
			tts_mode = TTS_OFF

	var use_tts: bool = tts_mode != TTS_OFF
	var tts_output

	#@ Step 2 - Call TTS query:
	if use_tts:
		#Ł Text to read:
		var read_text := ""
		if tts_mode == TTS_ADVANCED:
			read_text = speech.tts_text
		else:
			read_text = CandyWriting.get_shared().bbcode_strip_tags(source, caller, tts_text)		#/ The displayed text

		tts_output = await candy_de.call_hook("tts", {
			"caller": source, "mode": tts_mode, "text": read_text,
			"speaker_ref": speech.speaker_ref, "raw_dialogue": tts_text,
			"tts_variation_text": speech.tts_text, "line_data": speech.line_data,
			"variation": speech.chosen_variation}, speech.custom_data)
		if tts_output == null:
			use_tts = false

	#@ Step 3 - Use the output:
	if use_tts == true and voice_player != null:
		if tts_output is AudioStream:
			voice_player.stream = tts_output
		else:
			#Ł Path → load it:
			var stream: AudioStream = null
			if typeof(tts_output) == TYPE_STRING:
				stream = CandyMedia.load_audio(str(tts_output))

			#% Nothing usable → fallback:
			if stream != null:
				voice_player.stream = stream
			else:
				use_tts = false

	#@ Step 4 - No TTS → voice file:
	if use_tts == false:
		#Ł Add missing extension:
		var fallback_files := _fallback_files(speech)
		speech.voice_file = _with_extension(source, caller, voice_player, speech.voice_file)

		var voice_stream := CandyMedia.load_audio(speech.voice_file)

		#Ł Fall back to voice_fallback_language's file (with the variation's tags, then without):
		if voice_stream == null:
			for fallback in fallback_files:
				var fallback_file := _with_extension(source, caller, voice_player, fallback)
				var fallback_stream := CandyMedia.load_audio(fallback_file)
				if fallback_stream == null:
					continue
				if OS.is_debug_build() and source.debug_prints == true:
					print("Voice file not found → " + speech.voice_file + ", playing the fallback language's → " + fallback_file)
				speech.voice_file = fallback_file
				voice_stream = fallback_stream
				break

		#¦ 1. Valid file:
		if voice_player != null and voice_stream != null:
			voice_player.stream = voice_stream

		else:
			#¦ 2. No valid file found → stop or clear:
			if voice_player != null:
				if voice_player.playing:
					voice_player.stop()
				voice_player.stream = null

			#Ł Report the path tried:
			if speech.voice_file != "" and OS.is_debug_build() and source.debug_prints == true:
				print("Voice file not found → " + speech.voice_file)

	return voice_player

#* Add a missing extension to a voice file:
func _with_extension(source: CandyEngine, caller: Object, voice_player, voice_file: String) -> String:
	if voice_file == "" or voice_file.get_file().get_extension() != "":
		return voice_file
	return voice_file + CandyMedia.extension_in(voice_file.get_base_dir(), default_extension(source, caller, voice_player))		#/ Folder's config.txt "extension", else the player's default

#* Voice files in voice_fallback_language, to try in order (with the variation's tags, then without):
#? "French_S=F" with "English" → ".../English_S=F/hello", then ".../English/hello". "Default" has no folder.
func _fallback_files(speech: CandySpeech) -> Array[String]:
	var files: Array[String] = []
	var fallback = candy_de.get("voice_fallback_language")
	if fallback == null or str(fallback).strip_edges() == "" or speech.voice_file == "":
		return files

	#Ł The folder above the variation's own:
	var current := _variation_folder(speech.voice_variation)
	var base := speech.voice_file.get_base_dir()
	if current != "":
		if base.get_file() != current:
			return files		#/ Not a path this function built
		base = base.get_base_dir()

	for target in [with_language(speech.voice_variation, str(fallback).strip_edges()), str(fallback).strip_edges()]:
		var folder := _variation_folder(target)
		if folder == current:
			continue		#/ Already that language's file
		var file := base.path_join(speech.voice_file.get_file())
		if folder != "":
			file = base.path_join(folder).path_join(speech.voice_file.get_file())
		if not (file in files):
			files.append(file)
	return files

#* A variation's voice folder ("" for "Default", whose files sit one folder up):
static func _variation_folder(variation_name: String) -> String:
	if variation_name == "" or variation_name == "Default":
		return ""
	return variation_name

#* Language of a line's voice files: the engine's voice_language, else candy_de.voice_language; "" follows the text:
func voice_language(source: CandyEngine, caller: Object) -> String:
	var language := ""
	var property_value = candy_de.get("voice_language")
	if property_value != null:
		language = str(property_value).strip_edges()
	if "voice_language" in source and str(source.voice_language).strip_edges() != "":
		language = str(source.voice_language).strip_edges()
	return language

#* The variation whose voice files a line plays: the text's, in the voice language:
#? "French_S=F_#2" with voice language "Japanese" → "Japanese_S=F_#2".
func voice_variation(source: CandyEngine, caller: Object, variation_name: String) -> String:
	return with_language(variation_name, voice_language(source, caller))

#* A variation's name with another language ("" keeps it):
static func with_language(variation_name: String, language: String) -> String:
	if language == "":
		return variation_name
	var full_name := variation_name
	if full_name == "":
		full_name = "Default"
	var parts := full_name.split("_")
	parts[0] = language
	return "_".join(parts)

#* Full voice file path, following voice_logic:
func build_path(source: CandyEngine, caller: Object, file_name: String, speaker_ref: String,
		conversation: String, block: String, line_index: int, variation_name: String) -> String:
	var logic = candy_de.get("voice_logic")
	if logic == null:
		logic = DEFAULT_VOICE_LOGIC

	if str(logic) == "Folder":
		return _folder_path(source, caller, file_name, speaker_ref, conversation, block, line_index, variation_name)

	return ""		#/ Unknown voice_logic

#* "Folder" logic - voice_folder/<voice_path>/[<variation>/]<file_name>:
func _folder_path(source: CandyEngine, caller: Object, file_name: String, speaker_ref: String,
		conversation: String, block: String, line_index: int, variation_name: String) -> String:
	var sub_path = candy_de.get("voice_path")
	if sub_path == null:
		sub_path = DEFAULT_VOICE_PATH

	#@ Step 1 - Fill in the tags:
	var tag_values := {
		"{actor}": speaker_ref,
		"{dialogue}": source.running_dialogue_file,
		"{conversation}": conversation,
		"{block}": block,
		"{line}": str(line_index),		#/ From 0, like Jump line numbers
	}
	var filled_path := str(sub_path)
	for tag in tag_values:
		filled_path = filled_path.replace(tag, tag_values[tag])

	#@ Step 2 - Join folders, skipping empty ones:
	var path: String = candy_de.voice_folder
	for folder in filled_path.split("/", false):
		if folder.strip_edges() != "":
			path = path.path_join(folder)

	if variation_name != "" and variation_name != "Default":
		path = path.path_join(variation_name)

	return path.path_join(file_name)

#* Report invalid voice_logic and voice_path values:
static func check_settings(properties: Object) -> void:
	var logic = properties.get("voice_logic")
	if logic != null and not (str(logic) in VOICE_LOGICS):
		push_error("Candy DE: voice_logic '" + str(logic) + "' is not supported (" \
			+ ", ".join(VOICE_LOGICS) + "). Voice files will not be found.")

	var sub_path = properties.get("voice_path")
	if sub_path == null:
		return

	#Ł Unknown tags:
	var unknown: Array[String] = []
	var regex := RegEx.new()
	regex.compile("\\{[^{}]*\\}")
	for found in regex.search_all(str(sub_path)):
		var tag := found.get_string()
		if not (tag in VOICE_PATH_TAGS) and not (tag in unknown):
			unknown.append(tag)

	if unknown.size() > 0:
		push_error("Candy DE: voice_path '" + str(sub_path) + "' has unknown tags: " \
			+ ", ".join(unknown) + ". Supported tags: " + ", ".join(VOICE_PATH_TAGS) + ".")

#* Insert a variation subfolder into a voice path:
func insert_variation_folder(source: CandyEngine, caller: Object, path: String, variation_name: String) -> String:
	if variation_name == "" or variation_name == "Default":
		return path

	var file_name := path.get_file()
	if file_name == "":
		return path

	return path.get_base_dir().path_join(variation_name).path_join(file_name)

@warning_ignore_restore("unused_parameter")
