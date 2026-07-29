#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends AudioStreamPlayer

#^ Default extension for voice files:
## Extension given to voice files named without one, for the lines this player speaks -
## as the standalone Voice player, or as a UI element's or bubble's voice_node.[br][br]
## Leave empty to inherit the engine's [code]default_voice_extension[/code], and through it
## the project-wide setting in Candy_Properties.gd.
@export var default_voice_extension: String = ""

#^ Setting overrides:
#? Each replaces the engine's setting while its enable_ switch is on.
#? Overridden by the actor, then the line (see Classes/Candy_Settings.gd).

@export_group("Advance")
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
## Replace Lexicon keywords with their "Display" value before TTS reads the line.
@export var lexicon_mode: bool = true

@export_group("History")
## Replace the engine's write_dialogue_history with the value below.
@export var enable_write_dialogue_history: bool = false
## Log spoken lines in the dialogue history.
@export var write_dialogue_history: bool = true

@export_group("")


var caller: Node



#* Speak a line without showing it ("Voice" mode):
func display(engine: CandyEngine, speech: CandySpeech, custom_data: Array = []) -> void:
	caller = engine

	#% VN Mode:
	if CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref):
		CandyWriting.get_shared().bust_highlight(engine, self, speech.speaker_ref, speech.style, true, custom_data)

	#@ Step 1 - Apply lexicon tags:
	#? For TTS Simple mode: keywords are read as their "Display" value.
	var bbcode_text = speech.text
	if speech.settings["lexicon_mode"] == true and candy_de.lexicon != null:
		bbcode_text = CandyWriting.get_shared().apply_lexicon_tags(engine, self, speech.text, candy_de.lexicon, speech.chosen_variation)

	#@ Step 2 - Take out text event markers:
	bbcode_text = CandyTextEvents.get_shared().place_events(engine, self, speech, bbcode_text)

	#Ł Characters the line would show, for auto-advance:
	speech.displayed_characters = CandyWriting.get_shared().count_characters(engine, self, bbcode_text)

	#@ Step 3 - Resolve voice stream:
	var voice_player = await CandyVoice.get_shared().resolve_stream(engine, self, self, speech, bbcode_text)

	#@ Step 4 - Start voice playback:
	await CandyVoice.get_shared().start_playback(engine, self, voice_player, speech)

	#@ Step 5 - Text events:
	#? Nothing is written: run them all now, without their waits.
	await CandyTextEvents.get_shared().write_instantly(engine, self, null, [], speech, voice_player)

	#@ Step 6 - Wait for player advance:
	await CandyWriting.get_shared().wait_for_player_advance(engine, self, voice_player, false, speech)

	#. Hook call:
	#? Not if the dialogue was stopped meanwhile.
	if engine.killswitch == false:
		await candy_de.run_node_hook(self, "x_speech_advance", {"caller": engine, "node": self}, custom_data)

	#% VN Mode:
	if CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref):
		CandyWriting.get_shared().bust_highlight(engine, self, speech.speaker_ref, speech.style, false, custom_data)

	CandyVoice.get_shared().stop_playback(engine, self, voice_player)

	#@ Step 7 - Log to history:
	CandyWriting.get_shared().log_speech_history(engine, self, speech)


#* Full reset:
func reset():
	self.stop()
	self.stream = null
	self.stream_paused = false


#* Release pause state (unused, kept for consistency with the other audio players):
func unpause():
	self.stream_paused = false


#* Hook - before voice playback starts (every dialogue mode):
@warning_ignore("unused_parameter")
func x_playback_starting(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook - after voice playback starts (every dialogue mode):
@warning_ignore("unused_parameter")
func x_playback_started(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook - when the line is advanced (player or auto-advance), before this node finishes with it:
@warning_ignore("unused_parameter")
func x_speech_advance(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass