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
## OPTIONAL: RichTextLabel for displaying the speaker's name.[br][br]
## Leave empty for a dialogue box without a name label. To write the name at the start of
## the spoken text instead (or as well), turn on show_speaker.
@export var speaker_node: RichTextLabel
## REQUIRED: The node that displays the portrait file.
@export var portrait_node: Node
## REQUIRED: The audio player this dialogue box speaks through.[br][br]
## An AudioStreamPlayer, AudioStreamPlayer2D or AudioStreamPlayer3D, usually carrying
## Voice_Player.gd so it can run the playback hooks.[br]
## Every UI element has a voice player of its own: this one plays the voice files and
## the TTS output of the lines displayed in this dialogue box, and nothing else.
@export var voice_node: Node
## OPTIONAL: The container holding the portrait nodes.[br][br]
## Shown and hidden as a unit, so the portrait's background, foreground and effect
## layer disappear along with the image itself.[br]
## When left empty, only [member portrait_node] is shown and hidden.
@export var portrait_area: Node
## OPTIONAL: A node that displays a portrait background.
@export var portrait_bg: Node
## OPTIONAL: A node that displays a portrait foreground (e.g. a frame or overlay)
@export var portrait_fg: Node
## OPTIONAL: An AnimationPlayer for playing effects on portraits.
@export var portrait_effect_player: Node


#^ Setting overrides:
#? Each replaces the engine's while its enable_ switch is on. Overridden by the actor, then the line.

@export_group("Portrait")
## Replace the engine's portrait_mode with the value below.
@export var enable_portrait_mode: bool = false
## Whether to show the speaker's portrait.[br]
## "Off": never. "All": always. "Player": only for the player. "NPC": for everyone but the player.[br]
## "VN": only for speakers without a VN bust.
@export var portrait_mode: CandyEngine.PortraitModes = CandyEngine.PortraitModes.All

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
## Write the speaker's name at the start of the spoken text.[br]
## Independent of speaker_node: the name can show in either, both or neither.
@export var show_speaker: bool = false
## Replace the engine's speaker_prefix with the value below.
@export var enable_speaker_prefix: bool = false
## Text added before the speaker's name.
@export var speaker_prefix: String = ""
## Replace the engine's speaker_suffix with the value below.
@export var enable_speaker_suffix: bool = false
## Text added after the speaker's name.
@export var speaker_suffix: String = ":"

@export_group("End of Line")
## Replace the engine's end_of_line_string with the value below.
@export var enable_end_of_line_string: bool = false
## Text shown after the line, [b]before[/b] dialogue advances (e.g. a blinking arrow).[br]
## Supports BBCode. Empty to show nothing.
@export var end_of_line_string: String = "[pulse freq=1.5 color=black ease=-5.0] ▼[/pulse]"
## Replace the engine's advance_string with the value below.
@export var enable_advance_string: bool = false
## Text that replaces end_of_line_string [b]after[/b] dialogue advances.[br]
## Supports BBCode. Empty to show nothing.
@export var advance_string: String = " ▼"

@export_group("Self Clear")
## Replace the engine's self_clear with the value below.
@export var enable_self_clear: bool = false
## Clear this UI element when dialogue advances to the next line.
@export var self_clear: bool = false
## Replace the engine's portrait_self_clear with the value below.
@export var enable_portrait_self_clear: bool = false
## Clear the portrait when dialogue advances to the next line.
@export var portrait_self_clear: bool = false

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

@export_group("Extensions")
#? UI element level of each extension chain. Empty = inherit the engine's.
## Extension given to files named without one, on TextureRect, NinePatchRect and TextureButton portraits.[br][br]
## Leave empty to inherit the engine's [code]default_image_extension[/code].
@export var default_image_extension: String = ""
## Extension given to spritesheet files named without one, on Sprite2D and Sprite3D portraits.[br][br]
## Leave empty to inherit the engine's [code]default_sprite_extension[/code].
@export var default_sprite_extension: String = ""
## Extension given to SpriteFrames files named without one, on AnimatedSprite2D and
## AnimatedSprite3D portraits: a line's Sprite_Frames_File written without one.[br][br]
## Leave empty to inherit the engine's [code]default_animated_sprite_extension[/code].
@export var default_animated_sprite_extension: String = ""
## Extension given to video files named without one, on VideoStreamPlayer portraits.[br][br]
## Leave empty to inherit the engine's [code]default_video_extension[/code].
@export var default_video_extension: String = ""

@export_group("Portrait Configuration")
#? UI element level of each FPS chain. 0 = inherit the engine's.
## Frame rate for frame-folder animations on TextureRect and NinePatchRect portraits.[br][br]
## Leave at 0 to inherit the engine's [code]default_animated_image_fps[/code]. A "config.txt"
## in the animation's own folder overrides this.
@export var default_animated_image_fps: float = 0.0
## Frame rate for spritesheets on Sprite2D and Sprite3D portraits.[br][br]
## Leave at 0 to inherit the engine's [code]default_sprite_fps[/code].
@export var default_sprite_fps: float = 0.0
## Frame rate for SpriteFrames animations saved with no speed of their own, on
## AnimatedSprite2D and AnimatedSprite3D portraits.[br][br]
## Leave at 0 to inherit the engine's [code]default_animated_sprite_fps[/code]. A speed saved
## in the SpriteFrames overrides this.
@export var default_animated_sprite_fps: float = 0.0
## Frame rate a Portrait_Stop frame counts at on VideoStreamPlayer portraits whose video's own
## frame rate can't be read.[br][br]
## Leave at 0 to inherit the engine's [code]default_video_fps[/code].
@export var default_video_fps: float = 0.0
## Memory budget of one animation folder shown as a portrait, in MB: one whose frames fit
## in it keeps every frame loaded while it plays, one that doesn't is streamed. 0 streams
## every animation.[br][br]
## Leave at -1 to inherit the engine's [code]animation_folder_cache[/code]. A config.txt
## ("cache") overrides this.
@export var animation_folder_cache: int = -1
## While an animation folder shown as a portrait is streamed, how many frames are loaded
## ahead.[br][br]
## Leave at -1 to inherit the engine's [code]animation_folder_stream[/code]. A config.txt
## ("stream") overrides this.
@export var animation_folder_stream: int = -1
## Used for scaling Sprite2D or Sprite3D nodes to the desired size:[br][br]
## The height the portrait should be scaled to.
@export var portrait_h = 256
## Used for scaling Sprite2D or Sprite3D nodes to the desired size:[br][br]
## The width the portrait should be scaled to.
@export var portrait_w = 256

@export_group("")
## Default Z-order.
@export var default_z = 100

var caller: Node

#^ Whether the current line shows a portrait, for show_line_portrait():
var _line_shows_portrait := false
#^ Current line's number, whether it has a voice, and whether that voice has ended (Portrait_Play -3):
var _line_serial := 0
var _line_has_voice := false
var _line_voice_ended := false



func _ready():
	self.z_index = default_z

	#@ Step 1 - Connect Lexicon click and hover:
	if dialogue_node is RichTextLabel:
		if not dialogue_node.meta_clicked.is_connected(_on_meta_clicked):
			dialogue_node.meta_clicked.connect(_on_meta_clicked)
		if not dialogue_node.meta_hover_started.is_connected(_on_meta_hover_started):
			dialogue_node.meta_hover_started.connect(_on_meta_hover_started)
		if not dialogue_node.meta_hover_ended.is_connected(_on_meta_hover_ended):
			dialogue_node.meta_hover_ended.connect(_on_meta_hover_ended)

	#% Missing voice player:
	if voice_node == null:
		printerr("Box_UI: no voice_node assigned on '", self.name, "' - voiced lines and TTS will not play in this dialogue box.")

	#@ Step 2 - Report labels with BBCode off:
	for label_node in [speaker_node, dialogue_node]:
		if label_node != null and label_node.bbcode_enabled == false:
			printerr("Box_UI: '", label_node.name, "' on '", self.name, "' has bbcode_enabled off - BBCode wraps, lexicon tags and end-of-line symbols will show as raw text.")


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
		printerr("Box_UI: '", self.name, "' has no dialogue_node assigned.")
		return

	if voice_node != null:
		voice_node.caller = engine

	self.visible = true

	#Ł Settings:
	var settings: Dictionary = speech.settings

	#@ Step 1 - Speaker label:
	if speaker_node != null:
		speaker_node.text = CandyWriting.get_shared().wrap_bbcode(engine, self, speech.speaker_display, settings["speaker_bbcode"])

	#@ Step 2 - Dialogue text:
	dialogue_node.text = ""

	#@ Step 3 - Variation layout:
	#! Use Control.TEXT_DIRECTION_*, not TextServer.DIRECTION_* (a different enum).
	dialogue_node.text_direction = Control.TEXT_DIRECTION_LTR
	dialogue_node.layout_direction = Control.LAYOUT_DIRECTION_LTR

	if speech.direction == "rtl":
		dialogue_node.text_direction = Control.TEXT_DIRECTION_RTL
		dialogue_node.layout_direction = Control.LAYOUT_DIRECTION_RTL

	#% VN Mode:
	if CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref):
		CandyWriting.get_shared().bust_highlight(engine, self, speech.speaker_ref, speech.style, true, custom_data)

	#@ Step 4 - Portrait (portrait_mode):
	var line_portrait_mode: int = settings["portrait_mode"]
	var show_portrait := false

	#¦ 1. "All" - every speaker:
	if line_portrait_mode == CandyEngine.PortraitModes.All:
		show_portrait = true

	#¦ 2. "Player" - the player only:
	elif line_portrait_mode == CandyEngine.PortraitModes.Player:
		show_portrait = speech.speaker_ref in candy_de.player_refs

	#¦ 3. "NPC" - everyone but the player:
	elif line_portrait_mode == CandyEngine.PortraitModes.NPC:
		show_portrait = speech.speaker_ref not in candy_de.player_refs

	#¦ 4. "VN" - in VN mode, speakers without a bust:
	elif line_portrait_mode == CandyEngine.PortraitModes.VN:
		show_portrait = engine.vn_mode == true and not CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref)

	#¦ 5. "Off", or any other value - no portrait:

	#Ł Apply:
	#? Kept for Line_Portrait.
	_line_shows_portrait = show_portrait
	_line_serial += 1
	_line_has_voice = false
	_line_voice_ended = false
	if show_portrait:
		receive_portrait(speech.speaker_ref, speech.portrait_raw, speech.play_portrait, speech.portrait_stop,
			speech.sprite_frames_raw)
	else:
		no_portrait()

	#@ Step 5 - Lexicon tags:
	var bbcode_text = speech.text
	if settings["lexicon_mode"] == true:
		if dialogue_node.bbcode_enabled and candy_de.lexicon != null:
			bbcode_text = CandyWriting.get_shared().apply_lexicon_tags(engine, self, speech.text, candy_de.lexicon, speech.chosen_variation)

	#@ Step 6 - Place text events:
	#? After the lexicon tags, before the BBCode wrap and the speaker's name.
	bbcode_text = CandyTextEvents.get_shared().place_events(engine, self, speech, bbcode_text)

	#@ Step 7 - Voice:
	var voice_player = null
	if voice_node != null:
		voice_player = await CandyVoice.get_shared().resolve_stream(engine, self, voice_node, speech, bbcode_text)

	#@ Step 8 - BBCode wrap:
	#? Before the end-of-line symbol, which keeps its own formatting.
	bbcode_text = CandyWriting.get_shared().wrap_bbcode(engine, self, bbcode_text, settings["text_bbcode"])

	#@ Step 9 - End-of-line symbol:
	var end_of_line: String = settings["end_of_line_string"]
	var base_text = bbcode_text
	bbcode_text = base_text + end_of_line

	#@ Step 10 - Speaker name:
	var speaker_label_text := ""
	if settings["show_speaker"] == true:
		speaker_label_text = CandyWriting.get_shared().wrap_bbcode(engine, self, settings["speaker_prefix"] + speech.speaker_display + settings["speaker_suffix"], settings["speaker_bbcode"]) + " "
		bbcode_text = speaker_label_text + bbcode_text
		base_text = speaker_label_text + base_text

	#@ Step 11 - Start voice:
	await CandyVoice.get_shared().start_playback(engine, self, voice_player, speech)
	_follow_voice(engine, speech, voice_player, _line_serial)		#/ Not awaited: stops a -3 portrait when the voice ends
	_line_has_voice = voice_player != null and voice_player.playing
	if show_portrait and not _line_has_voice:
		_portrait_without_voice(engine, speech)

	#@ Step 12 - Writing:
	dialogue_node.visible_characters = 0
	dialogue_node.text = bbcode_text
	var total_all = dialogue_node.get_total_character_count()

	#Ł Measure the speaker name (shown at once):
	var speaker_offset := 0
	if speaker_label_text != "":
		dialogue_node.text = speaker_label_text
		speaker_offset = dialogue_node.get_total_character_count()
		dialogue_node.text = bbcode_text		#/ restore full text for display/wrapping

	#Ł Measure the end-of-line symbol so the typewriter doesn't reveal it:
	var eol_visible := 0
	if end_of_line != "":
		dialogue_node.text = end_of_line
		eol_visible = dialogue_node.get_total_character_count()
		dialogue_node.text = bbcode_text		#/ restore full text for display/wrapping

	#Ł Characters shown, for auto-advance:
	speech.displayed_characters = total_all - speaker_offset - eol_visible

	#¦ 1. Instant:
	if settings["writing_speed"] <= 0:
		await CandyTextEvents.get_shared().write_instantly(engine, self, dialogue_node, [self], speech, voice_player)

	#¦ 2. Typewriter:
	else:
		#Ł Set full text immediately for correct word wrapping:
		dialogue_node.visible_characters = speaker_offset

		await CandyWriting.get_shared().typewriter(engine, self, dialogue_node, [self], speech.displayed_characters, speaker_offset, voice_player, speech)

	#. Hook call:
	await CandyWriting.get_shared().call_write_hook(engine, self, [self], "x_write_finished", custom_data)

	#@ Step 13 - Wait for advance:
	await CandyWriting.get_shared().wait_for_player_advance(engine, self, voice_player, false, speech)

	#. Hook call:
	#? Not if the killswitch stopped the line.
	if engine.killswitch == false:
		await candy_de.run_node_hook(self, "x_speech_advance", {"caller": engine, "node": self}, custom_data)

	#@ Step 14 - Stop a Portrait_Play -1 portrait, or a -3 one whose voice hasn't ended:
	var play_loops := CandyPortrait.loops_of(speech.play_portrait)
	var until_voice := play_loops == CandyPortrait.PLAY_UNTIL_VOICE and _line_voice_ended == false
	if show_portrait and (play_loops == CandyPortrait.PLAY_UNTIL_ADVANCE or until_voice):
		CandyPortrait.get_shared().stop_portrait(engine, self, portrait_node, CandyPortrait.stop_frame_of(speech.portrait_stop), no_portrait)

	#@ Step 15 - Advance symbol:
	if settings["advance_string"] != end_of_line:
		dialogue_node.text = base_text + settings["advance_string"]
		dialogue_node.visible_characters = -1

	#% VN Mode:
	if CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref):
		CandyWriting.get_shared().bust_highlight(engine, self, speech.speaker_ref, speech.style, false, custom_data)

	#@ Step 16 - Self clear:
	var line_self_clear: bool = settings["self_clear"]
	if line_self_clear == true or settings["portrait_self_clear"] == true:
		clear(line_self_clear, line_self_clear, line_self_clear, settings["portrait_self_clear"])

	#@ Step 17 - Stop voice:
	CandyVoice.get_shared().stop_playback(engine, self, voice_player)

	#@ Step 18 - Log to history:
	CandyWriting.get_shared().log_speech_history(engine, self, speech)


#* Node shown and hidden with the portrait:
#! Never self: hiding it would hide the text too.
func portrait_root() -> Node:
	if portrait_area != null:
		return portrait_area
	return portrait_node


#* Show or hide the portrait area:
func show_portrait_area(shown: bool) -> void:
	var root := portrait_root()
	if root != null and "visible" in root:
		root.visible = shown


#* Portrait nodes, for suspension:
func portrait_nodes() -> Array:
	if portrait_node == null:
		return []
	return [portrait_node]


#* Portrait settings, for CandyPortrait:
func portrait_config() -> Dictionary:
	return {
		"default_image_extension": default_image_extension,
		"default_sprite_extension": default_sprite_extension,
		"default_animated_sprite_extension": default_animated_sprite_extension,
		"default_video_extension": default_video_extension,
		"default_animated_image_fps": default_animated_image_fps,
		"default_sprite_fps": default_sprite_fps,
		"default_animated_sprite_fps": default_animated_sprite_fps,
		"default_video_fps": default_video_fps,
		"animation_folder_cache": animation_folder_cache,
		"animation_folder_stream": animation_folder_stream,
		"portrait_w": portrait_w,
		"portrait_h": portrait_h,
	}


#* Show a portrait:
func receive_portrait(character_ref: String, portrait_raw: String, play_portrait: String, portrait_stop: String = "1",
		sprite_frames_raw: String = "") -> void:
	show_portrait_area(true)
	var shown := CandyPortrait.get_shared().show_portrait(caller, self, portrait_node, character_ref, portrait_raw,
		sprite_frames_raw, CandyPortrait.loops_of(play_portrait), CandyPortrait.stop_frame_of(portrait_stop),
		portrait_config(), no_portrait)
	if not shown:
		show_portrait_area(false)


#* Change the current line's portrait (Line_Portrait):
@warning_ignore("unused_parameter")
func show_line_portrait(engine: CandyEngine, speech: CandySpeech, custom_data: Array = []) -> void:
	if not _line_shows_portrait:
		return
	#Ł Portrait_Play -3 without a voice - its fallback, or stopping at once:
	if not _line_has_voice and CandyPortrait.apply_voice_fallback(speech):
		_line_voice_ended = true
	receive_portrait(speech.speaker_ref, speech.portrait_raw, speech.play_portrait, speech.portrait_stop,
		speech.sprite_frames_raw)

	#% Portrait_Play -3 once the voice has ended, or without a voice or fallback - stop at once:
	if _line_voice_ended and CandyPortrait.loops_of(speech.play_portrait) == CandyPortrait.PLAY_UNTIL_VOICE:
		CandyPortrait.get_shared().stop_portrait(engine, self, portrait_node, CandyPortrait.stop_frame_of(speech.portrait_stop), no_portrait)


#* Portrait_Play -3 on a line without a voice - play its fallback ("-3/2"), or stop at once:
func _portrait_without_voice(engine: CandyEngine, speech: CandySpeech) -> void:
	var written := speech.play_portrait

	#¦ 1. No fallback - the stop frame at once:
	if CandyPortrait.apply_voice_fallback(speech):
		_line_voice_ended = true
		CandyPortrait.get_shared().stop_portrait(engine, self, portrait_node, CandyPortrait.stop_frame_of(speech.portrait_stop), no_portrait)

	#¦ 2. A fallback - play the portrait again with it:
	elif speech.play_portrait != written:
		receive_portrait(speech.speaker_ref, speech.portrait_raw, speech.play_portrait, speech.portrait_stop,
			speech.sprite_frames_raw)


#* Stop a Portrait_Play -3 portrait when the line's voice ends:
#? Without a playing voice, _portrait_without_voice() decides instead.
func _follow_voice(engine: CandyEngine, speech: CandySpeech, voice_player, serial: int) -> void:
	if voice_player == null or not voice_player.playing:
		return
	await voice_player.finished

	#% Another line since (a voice stopped early never emits finished):
	if serial != _line_serial:
		return
	_line_voice_ended = true
	if _line_shows_portrait and CandyPortrait.loops_of(speech.play_portrait) == CandyPortrait.PLAY_UNTIL_VOICE:
		CandyPortrait.get_shared().stop_portrait(engine, self, portrait_node, CandyPortrait.stop_frame_of(speech.portrait_stop), no_portrait)


#* Hide the portrait:
@warning_ignore("unused_parameter")
func no_portrait(custom_data: Array = []):
	show_portrait_area(false)
	CandyPortrait.get_shared().clear_portrait(caller, self, portrait_node)


#* Clear the dialogue box:
@warning_ignore("unused_parameter")
func clear(frame: bool = true, speech: bool = true, speaker: bool = true, portrait: bool = true, custom_data: Array = []):
	#Ł Stop the voice player:
	#? The engine's media reset doesn't reach it.
	if voice_node != null:
		if voice_node.has_method("reset"):
			voice_node.reset()
		else:
			voice_node.stop()
		if caller != null and caller.active_voice_player == voice_node:
			caller.active_voice_player = null

	if portrait == true:
		no_portrait()
	if speech == true and dialogue_node != null:
		dialogue_node.text = ""
	if speaker == true and speaker_node != null:
		speaker_node.text = ""
	if frame == true:
		self.visible = false


#* Hook - writing begins:
@warning_ignore("unused_parameter")
func x_write_begun(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook - characters appear (typing sounds, mouth movement...):
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