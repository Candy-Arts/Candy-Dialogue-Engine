#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Node3D

#^ Required Node Paths:
#? Update for a custom node hierarchy.
## REQUIRED: RichTextLabel for displaying spoken text.
@export var label: RichTextLabel
## REQUIRED: The Sprite3D node.
@export var sprite: Sprite3D
## REQUIRED: The viewport.
@export var viewport: SubViewport
## OPTIONAL: The voice player this bubble speaks its lines through.
@export var voice_node: Node

#^ Performance/Behavior Settings:
## Bubble offset on the Y axis.
@export var y_offset = 0
## Bubble offset on the X axis.
@export var x_offset = 0
## Bubble offset on the Z axis.
@export var z_offset = 0


## Maximum width the bubble can reach.
@export var max_width = 256
## Extra space on each side of the text.
@export var text_width_margin = 16

#^ Setting overrides:
#? Each replaces the engine's setting while its enable_ switch is on (see Classes/Candy_Settings.gd).

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

## BBCode tags wrapped around spoken text, e.g. "[color=#ff8080][i]".[br]
## Write only the opening tags: Candy DE adds the closing ones.[br][br]
## Overrides the engine's wrap.[br]
## Overridden by the speaking actor's wrap (Data_Tables/Actors.gd), then the line's.
@export_group("Text Style")
## Let this UI element override the engine's text wrap.[br]
## On with an empty wrap removes the engine's.
@export var enable_text_bbcode: bool = false
## Opening BBCode tags wrapped around the spoken text.
@export var text_bbcode: String = ""

#^ Display generation:
var _show_gen: int = 0

var caller: Node



func _ready():
	#@ Step 1 - Connect Lexicon click and hover signals:
	if label is RichTextLabel:
		if not label.meta_clicked.is_connected(_on_meta_clicked):
			label.meta_clicked.connect(_on_meta_clicked)
		if not label.meta_hover_started.is_connected(_on_meta_hover_started):
			label.meta_hover_started.connect(_on_meta_hover_started)
		if not label.meta_hover_ended.is_connected(_on_meta_hover_ended):
			label.meta_hover_ended.connect(_on_meta_hover_ended)

	#% Missing voice player:
	if voice_node == null:
		printerr("'", self.name, "' has no voice_node assigned - voiced lines and TTS will not play in this bubble.")

	#@ Step 2 - Report label with BBCode off:
	if label != null and label.bbcode_enabled == false:
		printerr("'", label.name, "' on '", self.name, "' has bbcode_enabled off - BBCode wraps, lexicon tags and end-of-line symbols will show as raw text.")


#* Lexicon keyword clicked:
#! Doesn't work in the default bubbles (text shown through a viewport).
#+ Write click behavior in User_Data/Functions/On_Lexicon_Clicked.gd.
func _on_meta_clicked(meta) -> void:
	var data = Marshalls.base64_to_variant(str(meta))
	if typeof(data) != TYPE_DICTIONARY:
		printerr("Lexicon: malformed meta payload.")
		return
	candy_de.run_hook("_on_lexicon_clicked", {"data": data, "caller": caller, "ui": self})


#* Lexicon keyword hovered:
#! Doesn't work in the default bubbles (text shown through a viewport).
#+ Write hover behavior in User_Data/Functions/On_Lexicon_Hovered.gd.
func _on_meta_hover_started(meta) -> void:
	_lexicon_hovered(meta, true)


func _on_meta_hover_ended(meta) -> void:
	_lexicon_hovered(meta, false)


func _lexicon_hovered(meta, hovered: bool) -> void:
	var data = Marshalls.base64_to_variant(str(meta))
	if typeof(data) != TYPE_DICTIONARY:
		return
	candy_de.run_hook("_on_lexicon_hovered", {"data": data, "caller": caller, "ui": self, "hovered": hovered})


#* Displays text in the bubble:
func show_text(spoken_text):
	self.visible = false	#/ Hidden while resizing
	_show_gen += 1
	var gen := _show_gen

	#@ Step 1 - Reset size before measuring:
	label.size.x = max_width + text_width_margin
	label.size.y = 0

	#@ Step 2 - Assign text to label:
	label.text = spoken_text

	await get_tree().process_frame
	if gen != _show_gen or not is_instance_valid(label):
		return

	#@ Step 3 - Apply required size:
	label.size.x = min(label.get_content_width(), max_width) + text_width_margin
	label.size.y = label.get_content_height()
	#Ł Round up, so truncation doesn't clip the last pixel:
	viewport.size = Vector2i(label.size.ceil())

	await get_tree().process_frame
	if gen != _show_gen or not is_instance_valid(label):
		return

	#@ Step 4 - Offset by size (half height, in world units):
	var px_size: float = 0.01
	if sprite != null:
		px_size = sprite.pixel_size
	self.position.y = y_offset + (label.size.y * px_size / 2.0)
	self.position.x = x_offset
	self.position.z = z_offset

	self.visible = true


#* Clear bubble:
@warning_ignore("unused_parameter")
func clear(engine: Node = null, custom_data: Array = [], master: bool = false):
	#% Skip another engine's bubble, unless master:
	#? 'master': UI_Clear's Bubbles "2". No engine (game code): always clear.
	if master == false and engine != null and caller != null and is_instance_valid(caller) and caller != engine:
		return

	#Ł Stop this bubble's voice player:
	#? Its own node: the engine's media player reset doesn't reach it.
	if voice_node != null:
		if voice_node.has_method("reset"):
			voice_node.reset()
		else:
			voice_node.stop()
		if caller != null and caller.active_voice_player == voice_node:
			caller.active_voice_player = null

	_show_gen += 1
	self.visible = false
	label.text = ""


#* Display a spoken line in this bubble:
#+ Return only once the line is over (typewriter, voice, advance).
func display(engine: CandyEngine, speech: CandySpeech, custom_data: Array = []) -> void:
	caller = engine
	if voice_node != null:
		voice_node.caller = engine

	#% Required node:
	if label == null:
		printerr("'", self.name, "' has no label assigned.")
		return

	#Ł Resolved line settings:
	var settings: Dictionary = speech.settings

	#@ Step 1 - Clear text:
	label.text = ""

	#@ Step 2 - Text direction:
	label.text_direction = Control.TEXT_DIRECTION_LTR
	label.layout_direction = Control.LAYOUT_DIRECTION_LTR
	if speech.direction == "rtl":
		label.text_direction = Control.TEXT_DIRECTION_RTL
		label.layout_direction = Control.LAYOUT_DIRECTION_RTL

	#@ Step 3 - Highlight VN bust:
	if CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref):
		CandyWriting.get_shared().bust_highlight(engine, self, speech.speaker_ref, speech.style, true, custom_data)

	#@ Step 4 - Apply lexicon tags:
	var bbcode_text = speech.text
	if settings["lexicon_mode"] == true:
		if label.bbcode_enabled and candy_de.lexicon != null:
			bbcode_text = CandyWriting.get_shared().apply_lexicon_tags(engine, self, speech.text, candy_de.lexicon, speech.chosen_variation)

	#@ Step 5 - Place text events:
	#? After the lexicon tags, before the BBCode wrap.
	bbcode_text = CandyTextEvents.get_shared().place_events(engine, self, speech, bbcode_text)

	#@ Step 6 - Resolve voice:
	var voice_player = null
	if voice_node != null:
		voice_player = await CandyVoice.get_shared().resolve_stream(engine, self, voice_node, speech, bbcode_text)

	#@ Step 7 - Apply BBCode wrap:
	#? Before the end-of-line symbol, which keeps its own formatting.
	bbcode_text = CandyWriting.get_shared().wrap_bbcode(engine, self, bbcode_text, settings["text_bbcode"])

	#@ Step 8 - Add end-of-line symbol:
	var end_of_line: String = settings["end_of_line_string"]
	var base_text = bbcode_text
	bbcode_text = base_text + end_of_line

	#@ Step 9 - Start voice playback:
	await CandyVoice.get_shared().start_playback(engine, self, voice_player, speech)

	#@ Step 10 - Write text:
	#Ł Set full text first, for word wrapping:
	var instant: bool = settings["writing_speed"] <= 0
	if not instant:
		label.visible_characters = 0
	await show_text(bbcode_text)

	#Ł Characters shown, without the end-of-line symbol:
	#? The typewriter doesn't reveal the symbol; auto-advance counts the rest.
	var total_all = label.get_total_character_count()
	var eol_visible := 0
	if end_of_line != "":
		label.text = end_of_line
		eol_visible = label.get_total_character_count()
		label.text = bbcode_text			#/ Restore full text
	speech.displayed_characters = total_all - eol_visible

	#¦ 1. Instant writing:
	if instant:
		#? Runs x_write_begun() and the text events, without their waits.
		await CandyTextEvents.get_shared().write_instantly(engine, self, label, [self], speech, voice_player)

	#¦ 2. Typewriter writing:
	else:
		await CandyWriting.get_shared().typewriter(engine, self, label, [self], speech.displayed_characters, 0, voice_player, speech)

	#. Hook call:
	await CandyWriting.get_shared().call_write_hook(engine, self, [self], "x_write_finished", custom_data)

	#@ Step 11 - Wait for player advance:
	await CandyWriting.get_shared().wait_for_player_advance(engine, self, voice_player, false, speech)

	#. Hook call:
	#? Not when the dialogue was stopped (no advance).
	if engine.killswitch == false:
		await candy_de.run_node_hook(self, "x_speech_advance", {"caller": engine, "node": self}, custom_data)

	#@ Step 12 - Swap end-of-line symbol for advance symbol:
	if settings["advance_string"] != end_of_line:
		label.text = base_text + settings["advance_string"]
		label.visible_characters = -1

	#@ Step 13 - Unhighlight VN bust:
	if CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref):
		CandyWriting.get_shared().bust_highlight(engine, self, speech.speaker_ref, speech.style, false, custom_data)

	#@ Step 14 - Stop voice playback:
	CandyVoice.get_shared().stop_playback(engine, self, voice_player)

	#@ Step 15 - Log spoken line to history:
	CandyWriting.get_shared().log_speech_history(engine, self, speech)


#* Hook, called when writing begins:
@warning_ignore("unused_parameter")
func x_write_begun(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook, called each time the typewriter adds characters:
#? At most once per frame (may add several characters); not for text shown at once.
#! Not awaited.
@warning_ignore("unused_parameter")
func x_write_progress(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook, called when writing finishes:
@warning_ignore("unused_parameter")
func x_write_finished(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook, called when the line is advanced:
@warning_ignore("unused_parameter")
func x_speech_advance(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass
