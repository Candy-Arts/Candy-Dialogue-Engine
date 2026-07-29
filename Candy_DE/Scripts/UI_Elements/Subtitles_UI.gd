#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Control

## REQUIRED: RichTextLabel for displaying spoken text.
@export var dialogue_node: RichTextLabel
## REQUIRED: The audio player these subtitles speak through.[br][br]
## An AudioStreamPlayer, AudioStreamPlayer2D or AudioStreamPlayer3D, usually carrying
## Voice_Player.gd so it can run the playback hooks.[br]
## Every UI element has a voice player of its own: this one plays the voice files and
## the TTS output of the lines displayed in these subtitles, and nothing else.
@export var voice_node: Node

#^ Setting overrides:
#? Each replaces the engine's while its enable_ switch is on. Overridden by the actor, then the line.

@export_group("Writing")
## Replace the engine's writing_speed with the value below.
@export var enable_writing_speed: bool = false
## Typewriter speed, in characters per second.[br]
## 0 writes the whole line at once.
@export var writing_speed: int = 30
## Replace the engine's continue_fast_speed with the value below.
@export var enable_continue_fast_speed: bool = false
## Typewriter speed while input_speed_dialogue is held.[br]
## 0 reveals the whole line; below 0 ignores the key.
@export var continue_fast_speed: int = 60
## Replace the engine's continue_slow_speed with the value below.
@export var enable_continue_slow_speed: bool = false
## Typewriter speed while input_slow_dialogue is held.[br]
## 0 reveals the whole line; below 0 ignores the key.
@export var continue_slow_speed: int = 15
## Replace the engine's sync_write_speed_voice with the value below.
@export var enable_sync_write_speed_voice: bool = false
## Match the typewriter's speed to the voice clip's length.[br]
## Synchronization breaks if the player speeds, slows or skips the typewriter.
@export var sync_write_speed_voice: bool = false
## Replace the engine's auto_advance with the value below.
@export var enable_auto_advance: bool = false
## Seconds to wait before moving to the next line on its own.[br]
## -1 to disable (manual advance only).
@export var auto_advance: float = -1.0
## Replace the engine's auto_advance_per_character with the value below.
@export var enable_auto_advance_per_character: bool = false
## Seconds added to auto_advance for each character the line shows.[br]
## Ignored when auto_advance is -1.
@export var auto_advance_per_character: float = 0.0

@export_group("Speaker Name")
## Replace the engine's show_speaker with the value below.
@export var enable_show_speaker: bool = false
## Write the speaker's name at the start of the line.
@export var show_speaker: bool = true
## Replace the engine's speaker_prefix with the value below.
@export var enable_speaker_prefix: bool = false
## Text added before the speaker's name.
@export var speaker_prefix: String = "("
## Replace the engine's speaker_suffix with the value below.
@export var enable_speaker_suffix: bool = false
## Text added after the speaker's name.
@export var speaker_suffix: String = ")"

@export_group("End of Line")
## Replace the engine's end_of_line_string with the value below.
@export var enable_end_of_line_string: bool = false
## Text shown after the line, [b]before[/b] dialogue advances (e.g. a blinking arrow).[br]
## Supports BBCode. Empty to show nothing.
@export var end_of_line_string: String = ""
## Replace the engine's advance_string with the value below.
@export var enable_advance_string: bool = false
## Text that replaces end_of_line_string [b]after[/b] dialogue advances.[br]
## Supports BBCode. Empty to show nothing.
@export var advance_string: String = ""

@export_group("Self Clear")
## Replace the engine's self_clear with the value below.
@export var enable_self_clear: bool = false
## Clear this UI element when dialogue advances to the next line.
@export var self_clear: bool = true

@export_group("Voice")
## Replace the engine's enable_voice with the value below.
@export var enable_enable_voice: bool = false
## Play voice files and TTS for spoken lines.
@export var enable_voice: bool = true
## Replace the engine's await_voice_playback with the value below.
@export var enable_await_voice_playback: bool = false
## Prevent manual and auto advance until voice playback has finished.
@export var await_voice_playback: bool = false

@export_group("Text-To-Speech")
## Replace the engine's text_to_speech with the value below.
@export var enable_text_to_speech: bool = false
## Text-to-speech.[br]
## "Off": no TTS. "Simple": TTS reads the spoken line.[br]
## "Advanced": TTS reads the line's "_TTS" variation (e.g. "English_TTS").[br]
## Any other name is a TTS mode of your own, handled in the tts() hook (Tts.gd).
@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, "Off,Simple,Advanced") var text_to_speech: String = "Off"
## Replace the engine's tts_advanced_fallback with the value below.
@export var enable_tts_advanced_fallback: bool = false
## TTS mode to use when text_to_speech is "Advanced" but the line has no "_TTS" variation.
@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, "Off,Simple") var tts_advanced_fallback: String = "Simple"

@export_group("LLM")
## Replace the engine's llm_mode with the value below.
@export var enable_llm_mode: bool = false
## Let the llm_query hook rewrite spoken lines.
@export var llm_mode: bool = false

@export_group("Lexicon")
## Replace the engine's lexicon_mode with the value below.
@export var enable_lexicon_mode: bool = false
## Mark Lexicon keywords in the spoken text.
@export var lexicon_mode: bool = true

@export_group("History")
## Replace the engine's write_dialogue_history with the value below.
@export var enable_write_dialogue_history: bool = false
## Log spoken lines in the dialogue history.
@export var write_dialogue_history: bool = true

## BBCode tags wrapped around spoken text and speaker names, e.g. "[color=#ff8080][i]".[br]
## Write only the opening tags: Candy DE adds the closing ones.[br][br]
## Overrides the engine's wraps.[br]
## Overridden by the speaking actor's wraps (Data_Tables/Actors.gd), then the line's.
@export_group("Text Style")
## Let this UI element override the engine's text wrap.[br]
## On with an empty wrap removes the engine's.
@export var enable_text_bbcode: bool = false
## Opening BBCode tags wrapped around the spoken text.
@export var text_bbcode: String = ""
## Let this UI element override the engine's speaker wrap.[br]
## On with an empty wrap removes the engine's.
@export var enable_speaker_bbcode: bool = false
## Opening BBCode tags wrapped around the speaker name.
@export var speaker_bbcode: String = ""

## Default Z-order.
@export var default_z = 100

var caller: Node


func _ready():
	self.z_index = default_z

	#@ Step 1 - Connect Lexicon click and hover:
	if dialogue_node != null:
		if not dialogue_node.meta_clicked.is_connected(_on_meta_clicked):
			dialogue_node.meta_clicked.connect(_on_meta_clicked)
		if not dialogue_node.meta_hover_started.is_connected(_on_meta_hover_started):
			dialogue_node.meta_hover_started.connect(_on_meta_hover_started)
		if not dialogue_node.meta_hover_ended.is_connected(_on_meta_hover_ended):
			dialogue_node.meta_hover_ended.connect(_on_meta_hover_ended)

	#@ Step 2 - Report a label with BBCode off:
	if dialogue_node != null and dialogue_node.bbcode_enabled == false:
		printerr("Subtitles_UI: '", dialogue_node.name, "' on '", self.name, "' has bbcode_enabled off - BBCode wraps, lexicon tags and end-of-line symbols will show as raw text.")

	#% Missing voice player:
	if voice_node == null:
		printerr("Subtitles_UI: no voice_node assigned on '", self.name, "' - voiced lines and TTS will not play in these subtitles.")


#* Lexicon click:
#+ Write custom behavior in _on_lexicon_clicked() (User_Data/Functions/On_Lexicon_Clicked.gd).
func _on_meta_clicked(meta) -> void:
	var data = Marshalls.base64_to_variant(str(meta))
	if typeof(data) != TYPE_DICTIONARY:
		printerr("Lexicon: malformed meta payload.")
		return
	candy_de.run_hook("_on_lexicon_clicked", {"data": data, "caller": caller, "ui": self})


#* Lexicon hover:
#+ Write custom behavior in _on_lexicon_hovered() (User_Data/Functions/On_Lexicon_Hovered.gd).
func _on_meta_hover_started(meta) -> void:
	_lexicon_hovered(meta, true)


func _on_meta_hover_ended(meta) -> void:
	_lexicon_hovered(meta, false)


func _lexicon_hovered(meta, hovered: bool) -> void:
	var data = Marshalls.base64_to_variant(str(meta))
	if typeof(data) != TYPE_DICTIONARY:
		return
	candy_de.run_hook("_on_lexicon_hovered", {"data": data, "caller": caller, "ui": self, "hovered": hovered})


#* Display a spoken line:
func display(engine: CandyEngine, speech: CandySpeech, custom_data: Array = []) -> void:
	caller = engine

	#% Required node:
	if dialogue_node == null:
		printerr("Subtitles_UI: '", self.name, "' has no dialogue_node assigned.")
		return

	if voice_node != null:
		voice_node.caller = engine

	self.visible = true

	#Ł Settings:
	var settings: Dictionary = speech.settings
	var line_show_speaker: bool = settings["show_speaker"]

	#@ Step 1 - Dialogue text:
	dialogue_node.text = ""

	#@ Step 2 - Variation layout:
	#! Use Control.TEXT_DIRECTION_*, not TextServer.DIRECTION_* (a different enum).
	dialogue_node.text_direction = Control.TEXT_DIRECTION_LTR
	dialogue_node.layout_direction = Control.LAYOUT_DIRECTION_LTR

	if speech.direction == "rtl":
		dialogue_node.text_direction = Control.TEXT_DIRECTION_RTL
		dialogue_node.layout_direction = Control.LAYOUT_DIRECTION_RTL

	#% VN Mode:
	if CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref):
		CandyWriting.get_shared().bust_highlight(engine, self, speech.speaker_ref, speech.style, true, custom_data)

	#@ Step 3 - Lexicon tags:
	var bbcode_text = speech.text
	if settings["lexicon_mode"] == true:
		if dialogue_node.bbcode_enabled and candy_de.lexicon != null:
			bbcode_text = CandyWriting.get_shared().apply_lexicon_tags(engine, self, speech.text, candy_de.lexicon, speech.chosen_variation)

	#@ Step 4 - Place text events:
	#? After the lexicon tags, before the BBCode wrap and the speaker's name.
	bbcode_text = CandyTextEvents.get_shared().place_events(engine, self, speech, bbcode_text)

	#@ Step 5 - Voice:
	var voice_player = null
	if voice_node != null:
		voice_player = await CandyVoice.get_shared().resolve_stream(engine, self, voice_node, speech, bbcode_text)

	#@ Step 6 - BBCode wrap:
	#? Before the end-of-line symbol, which keeps its own formatting.
	bbcode_text = CandyWriting.get_shared().wrap_bbcode(engine, self, bbcode_text, settings["text_bbcode"])

	#@ Step 7 - End-of-line symbol:
	var end_of_line: String = settings["end_of_line_string"]
	var base_text = bbcode_text
	bbcode_text = base_text + end_of_line

	#@ Step 8 - Speaker name:
	#? No speaker node: the name goes in the text.
	var speaker_label_text := speech.speaker_display
	if line_show_speaker == true:
		#Ł Prefix, suffix, BBCode wrap:
		speaker_label_text = CandyWriting.get_shared().wrap_bbcode(engine, self, settings["speaker_prefix"] + speech.speaker_display + settings["speaker_suffix"], settings["speaker_bbcode"])

	#@ Step 9 - Start voice:
	await CandyVoice.get_shared().start_playback(engine, self, voice_player, speech)

	#@ Step 10 - Add speaker name to text:
	if line_show_speaker == true:
		bbcode_text = speaker_label_text + " " + bbcode_text
		base_text = speaker_label_text + " " + base_text

	#@ Step 11 - Writing:
	dialogue_node.text = bbcode_text
	var total_visible_with_speaker = dialogue_node.get_total_character_count()

	var speaker_offset := 0
	if line_show_speaker == true:
		dialogue_node.text = speaker_label_text + " "
		speaker_offset = dialogue_node.get_total_character_count()
		dialogue_node.text = bbcode_text	#/ restore full text for display/wrapping

	#Ł Measure the end-of-line symbol so the typewriter doesn't reveal it:
	var eol_visible := 0
	if end_of_line != "":
		dialogue_node.text = end_of_line
		eol_visible = dialogue_node.get_total_character_count()
		dialogue_node.text = bbcode_text		#/ restore full text for display/wrapping

	#Ł Characters shown, for auto-advance:
	speech.displayed_characters = total_visible_with_speaker - speaker_offset - eol_visible

	#¦ 1. Instant:
	if settings["writing_speed"] <= 0:
		await CandyTextEvents.get_shared().write_instantly(engine, self, dialogue_node, [self], speech, voice_player)

	#¦ 2. Typewriter:
	else:
		#Ł Set full text immediately for correct word wrapping:
		dialogue_node.text = bbcode_text
		dialogue_node.visible_characters = speaker_offset

		await CandyWriting.get_shared().typewriter(engine, self, dialogue_node, [self], speech.displayed_characters, speaker_offset, voice_player, speech)

	#. Hook call:
	await CandyWriting.get_shared().call_write_hook(engine, self, [self], "x_write_finished", custom_data)

	#@ Step 12 - Wait for advance:
	await CandyWriting.get_shared().wait_for_player_advance(engine, self, voice_player, false, speech)

	#. Hook call:
	#? Not if the killswitch stopped the line.
	if engine.killswitch == false:
		await candy_de.run_node_hook(self, "x_speech_advance", {"caller": engine, "node": self}, custom_data)

	#@ Step 13 - Advance symbol:
	if settings["advance_string"] != end_of_line:
		dialogue_node.text = base_text + settings["advance_string"]
		dialogue_node.visible_characters = -1

	#% VN Mode:
	if CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref):
		CandyWriting.get_shared().bust_highlight(engine, self, speech.speaker_ref, speech.style, false, custom_data)

	#@ Step 14 - Self clear:
	if settings["self_clear"] == true:
		clear(true)

	#@ Step 15 - Stop voice:
	CandyVoice.get_shared().stop_playback(engine, self, voice_player)

	#@ Step 16 - Log to history:
	CandyWriting.get_shared().log_speech_history(engine, self, speech)


#* Clear the subtitles:
@warning_ignore("unused_parameter")
func clear(frame: bool = true, custom_data: Array = []):
	#Ł Stop the voice player:
	#? The engine's media reset doesn't reach it.
	if voice_node != null:
		if voice_node.has_method("reset"):
			voice_node.reset()
		else:
			voice_node.stop()
		if caller != null and caller.active_voice_player == voice_node:
			caller.active_voice_player = null

	if dialogue_node != null:
		dialogue_node.text = ""
	if frame == true:
		self.visible = false


#* Hook - writing begins:
@warning_ignore("unused_parameter")
func x_write_begun(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook - characters appear:
#? At most once per frame. Not for instant, skipped or sped-up text.
#! Not awaited.
@warning_ignore("unused_parameter")
func x_write_progress(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook - writing finishes:
@warning_ignore("unused_parameter")
func x_write_finished(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook - line advanced (by the player or auto-advance):
@warning_ignore("unused_parameter")
func x_speech_advance(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass