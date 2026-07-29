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


## REQUIRED: The Control the lines are drawn in.[br][br]
## The channel places the lines itself, so this must not be a Container; it clips them, so
## lines scrolled out of view don't show. Its width is the lines' width.
@export var lines_area: Control
## OPTIONAL: A VScrollBar to scroll the chat with. The mouse wheel scrolls it either way.
@export var scroll_bar: VScrollBar
## REQUIRED: The audio player this chat speaks through.[br][br]
## An AudioStreamPlayer, AudioStreamPlayer2D or AudioStreamPlayer3D, usually carrying
## Voice_Player.gd so it can run the playback hooks.[br]
## Every UI element has a voice player of its own: this one plays the voice files and
## the TTS output of the lines displayed in this chat, and nothing else.
@export var voice_node: Node

## A name for this channel. Not displayed.
@export var channel_name: String = ""


#^ Setting overrides:
#? Each replaces the engine's while its enable_ switch is on. Overridden by the actor, then the line.

@export_group("Chat Lines")
## Replace the engine's line_scene with the value below.
@export var enable_line_scene: bool = false
## The scene each line is displayed in (a Chat_Line): a path, or a file name in chat_lines_folder.
@export_file("*.tscn") var line_scene: String = "res://Candy_DE/Scenes/Chat_Lines/Default.tscn"
## Replace the engine's speaker_display with the value below.
@export var enable_speaker_display: bool = false
## When a line shows the speaker's name label.[br]
## "Every_Line": on every line. "Speaker_Change": only on the first of several lines in a row
## from the same speaker.
@export var speaker_display: CandyEngine.SpeakerDisplays = CandyEngine.SpeakerDisplays.Speaker_Change
## Replace the engine's portrait_display with the value below.
@export var enable_portrait_display: bool = false
## When a line shows the speaker's portrait (if portrait_mode allows one at all).[br]
## "Every_Line": on every line. "Speaker_Change": only on the first of several lines in a row
## from the same speaker. "Speaker_Or_Portrait_Change": also when the same speaker's portrait changes.
@export var portrait_display: CandyEngine.PortraitDisplays = CandyEngine.PortraitDisplays.Speaker_Or_Portrait_Change
## Replace the engine's alignment with the value below.
@export var enable_alignment: bool = false
## Which side of the text a line's portrait and name are on; the text aligns to the same side.[br]
## "Left" / "Right": always that side. "Alternate": the side opposite the previous line's when
## the speaker changes, the same side while the same speaker continues.
@export var alignment: CandyEngine.Alignments = CandyEngine.Alignments.Left
## Replace the engine's keep_portrait_space with the value below.
@export var enable_keep_portrait_space: bool = false
## Keep the space of a portrait that isn't shown on this line, so texts line up.
@export var keep_portrait_space: bool = true
## Replace the engine's keep_speaker_space with the value below.
@export var enable_keep_speaker_space: bool = false
## Keep the space of a name label that isn't shown on this line.
@export var keep_speaker_space: bool = false
## Replace the engine's keep_alternate_portrait_space with the value below.
@export var enable_keep_alternate_portrait_space: bool = false
## Keep the space of the portrait on the other side of the text.
@export var keep_alternate_portrait_space: bool = false
## Replace the engine's keep_alternate_speaker_space with the value below.
@export var enable_keep_alternate_speaker_space: bool = false
## Keep the space of the name label on the other side of the text.
@export var keep_alternate_speaker_space: bool = false

@export_group("Portrait")
## Replace the engine's portrait_mode with the value below.
@export var enable_portrait_mode: bool = false
## Whether to show the speaker's portrait.[br]
## "Off": never. "All": always. "Player": only for the player. "NPC": for everyone but the player.[br]
## "VN": only for speakers without a VN bust.
@export var portrait_mode: CandyEngine.PortraitModes = CandyEngine.PortraitModes.All

@export_group("Dialogue Start and End")
## Replace the engine's chat_clear_on_start with the value below.
@export var enable_clear_on_start: bool = false
## Clear the chat's lines when a dialogue starts.
@export var clear_on_start: bool = false
## Replace the engine's chat_clear_on_end with the value below.
@export var enable_clear_on_end: bool = false
## Clear the chat's lines when a dialogue ends.
@export var clear_on_end: bool = true
## Replace the engine's chat_hide_on_end with the value below.
@export var enable_hide_on_end: bool = false
## Hide the chat when a dialogue ends.
@export var hide_on_end: bool = true
## Replace the engine's chat_separator_scene with the value below.
@export var enable_separator_scene: bool = false
## The scene placed between two dialogues' lines, when they aren't cleared (a Chat_Separator):
## a path, or a file name in chat_separators_folder.
@export_file("*.tscn") var separator_scene: String = "res://Candy_DE/Scenes/Chat_Separators/Default.tscn"

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
## Independent of the lines' name labels: the name can show in either, both or neither.
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

@export_group("Scrolling")
## How far one turn of the mouse wheel scrolls, in pixels.
@export var scroll_step: float = 48.0
## How close to the bottom the chat must be scrolled to keep following new lines, in pixels.
@export var follow_margin: float = 8.0
## Extra room above and below the view where lines are already shown, in pixels, so they
## don't pop in while scrolling.
@export var view_margin: float = 64.0

@export_group("")
## Default Z-order.
@export var default_z = 100


#^ Height of an unmeasured line:
const ESTIMATED_HEIGHT := 48.0
#^ Line scene fallback:
const FALLBACK_LINE_SCENE := "res://Candy_DE/Scenes/Chat_Lines/Default.tscn"
#^ Scene folders without chat_lines_folder / chat_separators_folder:
const DEFAULT_LINES_FOLDER := "res://Candy_DE/Scenes/Chat_Lines"
const DEFAULT_SEPARATORS_FOLDER := "res://Candy_DE/Scenes/Chat_Separators"

var caller: Node

#^ Every line and separator, oldest first:
#? Each carries "height" and "width": the height measured at that width.
var records: Array[Dictionary] = []
#^ Scroll, in pixels from the top:
var scroll_offset: float = 0.0
#^ Following the newest line:
var following: bool = true
#^ Record being written, or -1 (its node isn't reused):
var active_record: int = -1

#^ Node showing each record in view, by index:
var _shown: Dictionary = {}
#^ Free nodes, by scene path:
var _free_nodes: Dictionary = {}
#^ Loaded scenes, by path:
var _scenes: Dictionary = {}
#^ Separator due before the next line:
var _separator_due: bool = false
#^ Record tops, from the last _layout():
var _tops: Array[float] = []
#^ Ignore value_changed while setting the scroll bar:
var _setting_bar: bool = false


func _ready():
	self.z_index = default_z

	#Ł Required nodes:
	if lines_area == null:
		printerr("Chat_Channel: '", self.name, "' has no lines_area assigned.")
	else:
		lines_area.clip_contents = true
		lines_area.resized.connect(_on_lines_area_resized)

	if scroll_bar != null:
		scroll_bar.value_changed.connect(_on_scroll_bar_changed)

	#% Missing voice player:
	if voice_node == null:
		printerr("Chat_Channel: no voice_node assigned on '", self.name, "' - voiced lines and TTS will not play in this chat.")


#* Mouse wheel scrolling:
#? Not in gui_input: the lines' labels take mouse input (Lexicon).
func _input(event: InputEvent) -> void:
	if lines_area == null or not is_visible_in_tree():
		return
	if not (event is InputEventMouseButton) or not event.pressed:
		return
	if not lines_area.get_global_rect().has_point(event.position):
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_scroll_to(scroll_offset - scroll_step)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_scroll_to(scroll_offset + scroll_step)
		get_viewport().set_input_as_handled()


#* Display a spoken line:
func display(engine: CandyEngine, speech: CandySpeech, custom_data: Array = []) -> void:
	caller = engine
	if voice_node != null:
		voice_node.caller = engine

	#% Required node:
	if lines_area == null:
		printerr("Chat_Channel: '", self.name, "' has no lines_area assigned.")
		return

	self.visible = true

	#Ł Settings:
	var settings: Dictionary = speech.settings

	#% VN Mode:
	if CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref):
		CandyWriting.get_shared().bust_highlight(engine, self, speech.speaker_ref, speech.style, true, custom_data)

	#@ Step 1 - Lexicon tags:
	var bbcode_text = speech.text
	if settings["lexicon_mode"] == true and candy_de.lexicon != null:
		bbcode_text = CandyWriting.get_shared().apply_lexicon_tags(engine, self, speech.text, candy_de.lexicon, speech.chosen_variation)

	#@ Step 2 - Place text events:
	#? After the lexicon tags, before the BBCode wrap and the speaker's name.
	bbcode_text = CandyTextEvents.get_shared().place_events(engine, self, speech, bbcode_text)

	#@ Step 3 - Voice:
	var voice_player = null
	if voice_node != null:
		voice_player = await CandyVoice.get_shared().resolve_stream(engine, self, voice_node, speech, bbcode_text)

	#@ Step 4 - BBCode wrap:
	#? Before the end-of-line symbol, which keeps its own formatting.
	bbcode_text = CandyWriting.get_shared().wrap_bbcode(engine, self, bbcode_text, settings["text_bbcode"])
	var body_text: String = bbcode_text

	#@ Step 5 - Speaker name:
	var speaker_label_text := ""
	if settings["show_speaker"] == true:
		speaker_label_text = CandyWriting.get_shared().wrap_bbcode(engine, self, settings["speaker_prefix"] + speech.speaker_display + settings["speaker_suffix"], settings["speaker_bbcode"]) + " "
		bbcode_text = speaker_label_text + bbcode_text

	#@ Step 6 - Separator, if due:
	if _separator_due and not records.is_empty():
		_append(_separator_record(engine))
	_separator_due = false

	#@ Step 7 - Add, show and measure the line:
	var record := _line_record(engine, speech, bbcode_text)
	var index := _append(record, true)
	_layout()
	await _measure_shown()
	var line_node = _shown.get(index)

	#@ Step 8 - Start voice:
	await CandyVoice.get_shared().start_playback(engine, self, voice_player, speech)
	_follow_voice(index, record, voice_player)		#/ Not awaited: stops a -3 portrait when the voice ends
	record["has_voice"] = voice_player != null and voice_player.playing
	if not record["has_voice"]:
		_portrait_without_voice(index, record, speech)

	#@ Step 9 - Measure the text (name shown at once):
	#? Out of view (no line node): counted from the text, for auto-advance.
	var speaker_offset := 0
	if line_node != null:
		var measure_label: RichTextLabel = line_node.text_node
		measure_label.text = speaker_label_text
		speaker_offset = measure_label.get_total_character_count()
		measure_label.text = record["text"]
		speech.displayed_characters = measure_label.get_total_character_count() - speaker_offset
		measure_label.text = record["text"] + record["end_of_line"]
	else:
		speech.displayed_characters = CandyWriting.get_shared().count_characters(engine, self, body_text)

	#@ Step 10 - Writing:
	#¦ 1. Instant:
	if settings["writing_speed"] <= 0 or line_node == null:
		var text_label: Node = null
		if line_node != null:
			text_label = line_node.text_node
		record["visible_characters"] = -1		#/ Whole if scrolled back into view
		await CandyTextEvents.get_shared().write_instantly(engine, self, text_label, [self], speech, voice_player)

	#¦ 2. Typewriter:
	else:
		var text_label: RichTextLabel = line_node.text_node
		text_label.visible_characters = speaker_offset
		await CandyWriting.get_shared().typewriter(engine, self, text_label, [self], speech.displayed_characters, speaker_offset, voice_player, speech)
	record["visible_characters"] = -1

	#. Hook call:
	await CandyWriting.get_shared().call_write_hook(engine, self, [self], "x_write_finished", custom_data)

	#@ Step 11 - Wait for advance:
	await CandyWriting.get_shared().wait_for_player_advance(engine, self, voice_player, false, speech)

	#. Hook call:
	#? Not if the killswitch stopped the line.
	if engine.killswitch == false:
		await candy_de.run_node_hook(self, "x_speech_advance", {"caller": engine, "node": self}, custom_data)

	#@ Step 12 - Finish the line (advance symbol, portrait stops):
	#% Unless the chat was cleared meanwhile:
	if index < records.size() and is_same(records[index], record):
		record["finished"] = true
		active_record = -1
		if _shown.has(index):
			_render(index, _shown[index])
		record["width"] = -1.0			#/ Remeasure: the advance symbol may change its height
		_layout()

	#% VN Mode:
	if CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref):
		CandyWriting.get_shared().bust_highlight(engine, self, speech.speaker_ref, speech.style, false, custom_data)

	#@ Step 13 - Stop voice:
	CandyVoice.get_shared().stop_playback(engine, self, voice_player)

	#@ Step 14 - Log to history:
	CandyWriting.get_shared().log_speech_history(engine, self, speech)


#* A dialogue started:
func dialogue_started(engine: CandyEngine) -> void:
	if _dialogue_setting(engine, "clear_on_start", "chat_clear_on_start") == true:
		clear(false, true)
	#% Kept lines - queue a separator:
	elif not records.is_empty():
		_separator_due = true


#* A dialogue ended:
func dialogue_ended(engine: CandyEngine) -> void:
	var clear_lines: bool = _dialogue_setting(engine, "clear_on_end", "chat_clear_on_end")
	var hide_chat: bool = _dialogue_setting(engine, "hide_on_end", "chat_hide_on_end")
	if clear_lines or hide_chat:
		clear(hide_chat, clear_lines)
	#% Kept lines - queue a separator:
	if not clear_lines and not records.is_empty():
		_separator_due = true


#* Clear the chat:
@warning_ignore("unused_parameter")
func clear(frame: bool = true, clear_text: bool = true, custom_data: Array = []) -> void:
	#@ Step 1 - Stop the voice player:
	#? The engine's media reset doesn't reach it.
	if voice_node != null:
		if voice_node.has_method("reset"):
			voice_node.reset()
		else:
			voice_node.stop()
		if caller != null and caller.active_voice_player == voice_node:
			caller.active_voice_player = null

	#@ Step 2 - Remove the lines:
	if clear_text:
		for index in _shown.keys():
			_release(index)
		records.clear()
		_tops.clear()
		scroll_offset = 0.0
		following = true
		active_record = -1
		_separator_due = false
		_layout()

	#@ Step 3 - Hide the chat:
	if frame:
		self.visible = false


#* Portrait nodes of the line being written, for suspension:
func portrait_nodes() -> Array:
	if active_record >= 0 and _shown.has(active_record) and _shown[active_record].has_method("portrait_nodes"):
		return _shown[active_record].portrait_nodes()
	return []


#* Change the portrait of the line being written (Line_Portrait):
@warning_ignore("unused_parameter")
func show_line_portrait(engine: CandyEngine, speech: CandySpeech, custom_data: Array = []) -> void:
	if active_record < 0 or active_record >= records.size():
		return
	var record: Dictionary = records[active_record]
	if record["kind"] != "line" or record["show_portrait"] != true:
		return

	#@ Step 1 - The record keeps the new portrait keys:
	#? Portrait_Play -3 without a voice: its fallback, or stopping at once.
	if record["has_voice"] == false and CandyPortrait.apply_voice_fallback(speech):
		record["voice_ended"] = true
	record["portrait_raw"] = speech.portrait_raw
	record["sprite_frames_raw"] = speech.sprite_frames_raw
	record["portrait_loops"] = CandyPortrait.loops_of(speech.play_portrait)
	record["portrait_stop"] = CandyPortrait.stop_frame_of(speech.portrait_stop)

	#@ Step 2 - Resolve with a node of the line's scene:
	var node = _shown.get(active_record)
	var resolver = node
	if resolver == null:
		resolver = _acquire(record["scene"])
	if resolver != null and resolver.has_method("resolve_portrait"):
		record["portrait"] = resolver.resolve_portrait(engine, record["speaker_ref"], record["portrait_raw"], record["side"],
			record["sprite_frames_raw"])
	if node == null:
		if resolver != null:
			_shown[active_record] = resolver
			_render(active_record, resolver)
			_layout()
		return

	#@ Step 3 - Show again, as far as written:
	if "text_node" in node and node.text_node != null:
		record["visible_characters"] = node.text_node.visible_characters
	if node.has_method("reset_portrait"):
		node.reset_portrait()
	_render(active_record, node)


#* Mark when the line's voice ends, for a Portrait_Play -3 portrait:
#? Without a playing voice, _portrait_without_voice() decides instead.
func _follow_voice(index: int, record: Dictionary, voice_player) -> void:
	if voice_player == null or not voice_player.playing:
		return
	await voice_player.finished

	#% Line cleared or finished since (a voice stopped early never emits finished):
	if index >= records.size() or not is_same(records[index], record) or record["finished"] == true:
		return
	record["voice_ended"] = true
	if _shown.has(index):
		_render(index, _shown[index])


#* Portrait_Play -3 on a line without a voice - play its fallback ("-3/2"), or stop at once:
func _portrait_without_voice(index: int, record: Dictionary, speech: CandySpeech) -> void:
	#¦ 1. No fallback - stops at once, as when a voice has ended:
	if CandyPortrait.apply_voice_fallback(speech):
		record["voice_ended"] = true

	#¦ 2. A fallback - play the portrait again with it:
	else:
		var loops := CandyPortrait.loops_of(speech.play_portrait)
		if loops == record["portrait_loops"]:
			return
		record["portrait_loops"] = loops
		if _shown.has(index) and _shown[index].has_method("reset_portrait"):
			_shown[index].reset_portrait()

	if _shown.has(index):
		_render(index, _shown[index])


#* Scroll to the bottom and follow:
func scroll_to_bottom() -> void:
	following = true
	_layout()


#& Records:
#* Build a line's record:
func _line_record(engine: CandyEngine, speech: CandySpeech, text: String) -> Dictionary:
	var settings: Dictionary = speech.settings
	var record := {
		"kind": "line",
		"scene": _valid_scene(engine, settings["line_scene"], engine.chat_line_scene),

		#Ł What it shows:
		"text": text,
		"end_of_line": settings["end_of_line_string"],
		"advance_string": settings["advance_string"],
		"finished": false,
		"has_voice": false,			#/ Portrait_Play -3
		"voice_ended": false,
		"visible_characters": 0,
		"direction": speech.direction,
		"speaker_ref": speech.speaker_ref,
		"speaker_name": CandyWriting.get_shared().wrap_bbcode(engine, self, speech.speaker_display, settings["speaker_bbcode"]),
		"portrait_raw": speech.portrait_raw,
		"sprite_frames_raw": speech.sprite_frames_raw,
		"portrait_loops": CandyPortrait.loops_of(speech.play_portrait),
		"portrait_stop": CandyPortrait.stop_frame_of(speech.portrait_stop),
		"portrait": {},
		"keep_portrait_space": settings["keep_portrait_space"],
		"keep_speaker_space": settings["keep_speaker_space"],
		"keep_alternate_portrait_space": settings["keep_alternate_portrait_space"],
		"keep_alternate_speaker_space": settings["keep_alternate_speaker_space"],

		#Ł Where it comes from:
		"engine": weakref(engine),
		"engine_id": engine.get_instance_id(),
		"engine_name": str(engine.name),
		"engine_mode": engine.engine_mode,
		"dialogue_file": engine.running_dialogue_file,
		"conversation": speech.conversation,
		"block": speech.block,
		"line_index": speech.line_index,
		"mode": speech.style,
		"variation": speech.chosen_variation,
		"time": Time.get_unix_time_from_system(),

		#Ł Layout:
		"height": -1.0,
		"width": -1.0,
	}

	#@ Step 1 - Previous line:
	#? None after a separator: counts as a speaker change, "Alternate" starts left.
	var previous: Dictionary = {}
	if not records.is_empty() and records[-1]["kind"] == "line":
		previous = records[-1]

	#@ Step 2 - Speaker change (another engine or dialogue counts):
	var speaker_changed := true
	var portrait_changed := true
	if not previous.is_empty():
		var same_source: bool = previous["engine_id"] == record["engine_id"] and previous["dialogue_file"] == record["dialogue_file"]
		speaker_changed = not same_source or previous["speaker_ref"] != record["speaker_ref"]
		portrait_changed = speaker_changed or previous["portrait_raw"] != record["portrait_raw"] \
			or previous["sprite_frames_raw"] != record["sprite_frames_raw"]

	#@ Step 3 - Side:
	var side := "Left"
	var line_alignment: int = settings["alignment"]
	if line_alignment == CandyEngine.Alignments.Right:
		side = "Right"
	elif line_alignment == CandyEngine.Alignments.Alternate and not previous.is_empty():
		side = previous["side"]
		if speaker_changed:
			if previous["side"] == "Left":
				side = "Right"
			else:
				side = "Left"
	record["side"] = side

	#@ Step 4 - Name label:
	record["show_speaker"] = settings["speaker_display"] == CandyEngine.SpeakerDisplays.Every_Line or speaker_changed

	#@ Step 5 - Portrait - portrait_mode, then portrait_display:
	var allowed := false
	var mode: int = settings["portrait_mode"]
	if mode == CandyEngine.PortraitModes.All:
		allowed = true
	elif mode == CandyEngine.PortraitModes.Player:
		allowed = speech.speaker_ref in candy_de.player_refs
	elif mode == CandyEngine.PortraitModes.NPC:
		allowed = speech.speaker_ref not in candy_de.player_refs
	elif mode == CandyEngine.PortraitModes.VN:
		allowed = engine.vn_mode == true and not CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref)

	var display_rule: int = settings["portrait_display"]
	var this_line := false
	if display_rule == CandyEngine.PortraitDisplays.Every_Line:
		this_line = true
	elif display_rule == CandyEngine.PortraitDisplays.Speaker_Change:
		this_line = speaker_changed
	elif display_rule == CandyEngine.PortraitDisplays.Speaker_Or_Portrait_Change:
		this_line = portrait_changed
	record["show_portrait"] = allowed and this_line

	return record

#* Build a separator's record:
func _separator_record(engine: CandyEngine) -> Dictionary:
	var scene_path = _dialogue_setting(engine, "separator_scene", "chat_separator_scene")
	return {
		"kind": "separator",
		"scene": _scene_path(engine, scene_path, _scenes_folder("chat_separators_folder", DEFAULT_SEPARATORS_FOLDER)),
		"height": -1.0,
		"width": -1.0,
	}

#* Append a record, returning its index:
func _append(record: Dictionary, active: bool = false) -> int:
	records.append(record)
	var index := records.size() - 1
	if active:		#/ The record being written
		active_record = index
	#Ł A line's portrait is resolved once, here:
	if record["kind"] == "line" and record["show_portrait"] == true:
		var node := _acquire(record["scene"])
		if node != null:
			var engine = record["engine"].get_ref()
			if node.has_method("resolve_portrait"):
				record["portrait"] = node.resolve_portrait(engine, record["speaker_ref"], record["portrait_raw"], record["side"],
					record["sprite_frames_raw"])
			_shown[index] = node
			_render(index, node)
	return index


#& Showing the records in view:
#* Place records, show those in view, free the others:
func _layout() -> void:
	if lines_area == null:
		return
	var width := lines_area.size.x
	var view_height := lines_area.size.y

	#@ Step 1 - Record tops:
	_tops.resize(records.size())
	var y := 0.0
	for index in records.size():
		_tops[index] = y
		y += _height_of(index)
	var content_height := y

	#@ Step 2 - Scroll (bottom while following):
	var max_scroll: float = max(0.0, content_height - view_height)
	if following:
		scroll_offset = max_scroll
	scroll_offset = clamp(scroll_offset, 0.0, max_scroll)
	_update_scroll_bar(content_height, view_height)

	#@ Step 3 - Records in view, plus the active one:
	var wanted := {}
	for index in records.size():
		var top: float = _tops[index] - scroll_offset
		if top + _height_of(index) >= -view_margin and top <= view_height + view_margin:
			wanted[index] = true
	if active_record >= 0 and active_record < records.size():
		wanted[active_record] = true

	#@ Step 4 - Free nodes out of view:
	for index in _shown.keys():
		if not wanted.has(index):
			_release(index)

	#@ Step 5 - Show records in view:
	var needs_measure := false
	for index in wanted:
		var node = _shown.get(index)
		if node == null:
			node = _acquire(records[index]["scene"])
			if node == null:
				continue
			_shown[index] = node
			_render(index, node)
		node.position = Vector2(0.0, _tops[index] - scroll_offset)
		node.size = Vector2(width, _height_of(index))
		if records[index]["width"] != width:
			needs_measure = true

	if needs_measure:
		_measure_shown()

#* Measure shown records, then relayout:
func _measure_shown() -> void:
	await get_tree().process_frame		#/ Wait for layout
	if lines_area == null:
		return
	#% Not laid out yet (hidden) - wait for a resize:
	var width := lines_area.size.x
	if width < 1.0:
		return
	var changed := false
	for index in _shown.keys():
		if index >= records.size():
			continue
		var record: Dictionary = records[index]
		var node: Control = _shown[index]
		var height: float = node.get_combined_minimum_size().y
		if absf(height - record["height"]) > 0.5 or record["width"] != width:
			#% Record above the view - shift the scroll, so the view stays put:
			if not following and index < _tops.size() and _tops[index] + _height_of(index) <= scroll_offset:
				scroll_offset += height - _height_of(index)
			record["height"] = height
			record["width"] = width
			changed = true
	if changed:
		_layout()

#* Record height, or an estimate:
func _height_of(index: int) -> float:
	var height: float = records[index]["height"]
	if height < 0.0:
		return ESTIMATED_HEIGHT
	return height

#* Show a record in a node:
func _render(index: int, node: Node) -> void:
	var record: Dictionary = records[index]
	if record["kind"] == "line":
		if node.has_method("show_line"):
			node.show_line(record["engine"].get_ref(), record, index == active_record)
	elif node.has_method("show_separator"):
		node.show_separator(record)

#* Get a free node of a scene, or create one:
func _acquire(scene_path: String) -> Node:
	var free_nodes: Array = _free_nodes.get(scene_path, [])
	if not free_nodes.is_empty():
		var reused: Node = free_nodes.pop_back()
		reused.visible = true
		return reused

	if not _scenes.has(scene_path):
		_scenes[scene_path] = load(scene_path)
	var scene = _scenes[scene_path]
	if not (scene is PackedScene):
		printerr("Chat_Channel: '", scene_path, "' is not a scene - the line can't be shown.")
		return null

	var node := (scene as PackedScene).instantiate()
	if not (node is Control):
		printerr("Chat_Channel: the root of '", scene_path, "' must be a Control.")
		node.free()
		return null
	if "channel" in node:
		node.channel = self
	node.set_meta("candy_chat_scene", scene_path)
	lines_area.add_child(node)
	return node

#* Free a record's node, for reuse:
func _release(index: int) -> void:
	var node: Node = _shown[index]
	_shown.erase(index)
	if node.has_method("clear_line"):
		node.clear_line()
	node.visible = false
	var scene_path := str(node.get_meta("candy_chat_scene", ""))
	if not _free_nodes.has(scene_path):
		_free_nodes[scene_path] = []
	_free_nodes[scene_path].append(node)


#& Scrolling:
#* Scroll to a position (following again at the bottom):
func _scroll_to(offset: float) -> void:
	if lines_area == null:
		return
	var content_height := 0.0
	if not _tops.is_empty():
		content_height = _tops[-1] + _height_of(_tops.size() - 1)
	var max_scroll: float = max(0.0, content_height - lines_area.size.y)
	scroll_offset = clamp(offset, 0.0, max_scroll)
	following = scroll_offset >= max_scroll - follow_margin
	_layout()

func _on_scroll_bar_changed(value: float) -> void:
	if not _setting_bar:
		_scroll_to(value)

func _update_scroll_bar(content_height: float, view_height: float) -> void:
	if scroll_bar == null:
		return
	_setting_bar = true
	scroll_bar.max_value = content_height
	scroll_bar.page = view_height
	scroll_bar.value = scroll_offset
	scroll_bar.visible = content_height > view_height
	_setting_bar = false

func _on_lines_area_resized() -> void:
	_layout()


#& Helpers:
#* Dialogue start / end setting - this channel's if enabled, else the engine's:
func _dialogue_setting(engine: CandyEngine, setting: String, engine_setting: String) -> Variant:
	if get("enable_" + setting) == true:
		return get(setting)
	return engine.get(engine_setting)

#* Loadable line scene - resolved, else the engine's, else the default:
func _valid_scene(engine: CandyEngine, wanted: Variant, engine_scene: String) -> String:
	var folder := _scenes_folder("chat_lines_folder", DEFAULT_LINES_FOLDER)
	var wanted_path := _scene_path(engine, wanted, folder)
	for scene_path in [wanted_path, _scene_path(engine, engine_scene, folder), FALLBACK_LINE_SCENE]:
		if scene_path != "" and ResourceLoader.exists(scene_path):
			if scene_path != wanted_path:
				printerr("Chat_Channel: line scene '", wanted, "' can't be found - using '", scene_path, "'.")
			return scene_path
	return FALLBACK_LINE_SCENE

#* Scene setting as a path (file name looked up in folder), or "":
func _scene_path(engine: CandyEngine, value: Variant, folder: String) -> String:
	if value == null:
		return ""
	return CandyUI.get_shared().resolve_scene_path(engine, self, value, folder)

#* Scene folder from Candy_Properties.gd, or fallback:
func _scenes_folder(property: String, fallback: String) -> String:
	var folder = candy_de.get(property)
	if folder == null or str(folder) == "":
		return fallback
	return str(folder)


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
