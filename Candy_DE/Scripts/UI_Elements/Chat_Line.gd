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


## REQUIRED: RichTextLabel for the spoken text.[br][br]
## Turn on fit_content, so the line grows with its text.
@export var text_node: RichTextLabel
## OPTIONAL: The portrait on the left of the text (TextureRect, NinePatchRect, TextureButton,
## Sprite2D, AnimatedSprite2D or VideoStreamPlayer).[br][br]
## Keeping its space when it shows nothing relies on its minimum size.
@export var portrait_left: Node
## OPTIONAL: The portrait on the right of the text.
@export var portrait_right: Node
## OPTIONAL: RichTextLabel for the speaker's name, on the left.
@export var speaker_left: RichTextLabel
## OPTIONAL: RichTextLabel for the speaker's name, on the right.
@export var speaker_right: RichTextLabel

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
@export var portrait_h = 48
## Used for scaling Sprite2D or Sprite3D nodes to the desired size:[br][br]
## The width the portrait should be scaled to.
@export var portrait_w = 48
@export_group("")


#^ Engine of the shown line, for Lexicon clicks:
var caller: Node
#^ Parent Chat_Channel:
var channel: Node
#^ Record whose portrait is playing, or null, and whether it was stopped (-1, -3):
var _portrait_record = null
var _portrait_stopped := false


func _ready():
	#% Required node:
	if text_node == null:
		printerr("Chat_Line: '", self.name, "' has no text_node assigned.")
		return

	#@ Step 1 - Fix the text's height while writing:
	#? Otherwise the line rewraps as it grows.
	text_node.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING

	#@ Step 2 - Connect Lexicon click and hover:
	if not text_node.meta_clicked.is_connected(_on_meta_clicked):
		text_node.meta_clicked.connect(_on_meta_clicked)
	if not text_node.meta_hover_started.is_connected(_on_meta_hover_started):
		text_node.meta_hover_started.connect(_on_meta_hover_started)
	if not text_node.meta_hover_ended.is_connected(_on_meta_hover_ended):
		text_node.meta_hover_ended.connect(_on_meta_hover_ended)

	#@ Step 3 - Report labels with BBCode off:
	for label_node in [text_node, speaker_left, speaker_right]:
		if label_node != null and label_node.bbcode_enabled == false:
			printerr("Chat_Line: '", label_node.name, "' on '", self.name, "' has bbcode_enabled off - BBCode wraps, lexicon tags and end-of-line symbols will show as raw text.")


#* Lexicon click:
#+ Write custom behavior in _on_lexicon_clicked() (User_Data/Functions/On_Lexicon_Clicked.gd).
func _on_meta_clicked(meta) -> void:
	var data = Marshalls.base64_to_variant(str(meta))
	if typeof(data) != TYPE_DICTIONARY:
		printerr("Lexicon: malformed meta payload.")
		return
	candy_de.run_hook("_on_lexicon_clicked", {"data": data, "caller": caller, "ui": channel})


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
	candy_de.run_hook("_on_lexicon_hovered", {"data": data, "caller": caller, "ui": channel, "hovered": hovered})


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


#* Portrait nodes, for suspension:
func portrait_nodes() -> Array:
	var nodes: Array = []
	for portrait in [portrait_left, portrait_right]:
		if portrait != null:
			nodes.append(portrait)
	return nodes


#* Resolve a line's portrait on one side, or {}:
#? 'sprite_frames_raw': the line's Sprite_Frames_File.
func resolve_portrait(source: CandyEngine, speaker_ref: String, portrait_raw: String, side: String,
		sprite_frames_raw: String = "") -> Dictionary:
	var portrait := portrait_left
	if side == "Right":
		portrait = portrait_right
	if portrait == null:
		return {}
	return CandyPortrait.get_shared().resolve_portrait(source, self, portrait, speaker_ref, portrait_raw,
		sprite_frames_raw, portrait_config())


#* Show a record:
#? 'active': the line being written (only its portrait animates). 'source': null once freed.
func show_line(source: CandyEngine, record: Dictionary, active: bool) -> void:
	caller = source
	if text_node == null:
		return

	#@ Step 1 - Line side and other side:
	var left: bool = record["side"] != "Right"
	var name_node: RichTextLabel = speaker_left
	var other_name: RichTextLabel = speaker_right
	var portrait: Node = portrait_left
	var other_portrait: Node = portrait_right
	if not left:
		name_node = speaker_right
		other_name = speaker_left
		portrait = portrait_right
		other_portrait = portrait_left

	#@ Step 2 - Names:
	_show_name(name_node, record, record["show_speaker"], record["keep_speaker_space"])
	_show_name(other_name, record, false, record["keep_alternate_speaker_space"])

	#@ Step 3 - Portraits:
	_show_line_portrait(source, portrait, record, active)
	_show_portrait(source, other_portrait, record, false, record["keep_alternate_portrait_space"], 0)

	#@ Step 4 - Text, with the end-of-line or advance symbol:
	var ending: String = record["end_of_line"]
	if record["finished"] == true:
		ending = record["advance_string"]
	text_node.text = record["text"] + ending
	text_node.visible_characters = record["visible_characters"]

	#@ Step 5 - Alignment and direction:
	if left:
		text_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		text_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	text_node.text_direction = Control.TEXT_DIRECTION_LTR
	if record["direction"] == "rtl":
		text_node.text_direction = Control.TEXT_DIRECTION_RTL


#* Make the next show_line() restart the portrait (after a Line_Portrait change):
func reset_portrait() -> void:
	_portrait_record = null
	_portrait_stopped = false


#* Clear before reuse, stopping the portrait:
func clear_line() -> void:
	_portrait_record = null
	_portrait_stopped = false
	for portrait in [portrait_left, portrait_right]:
		if portrait != null:
			CandyPortrait.get_shared().clear_portrait(caller, self, portrait)
	if text_node != null:
		text_node.text = ""


#* Show a name label, keep its space, or hide it:
func _show_name(name_node: RichTextLabel, record: Dictionary, shown: bool, keep_space: bool) -> void:
	if name_node == null:
		return
	if shown or keep_space:
		name_node.text = record["speaker_name"]
		name_node.visible = true
		if shown:
			name_node.modulate.a = 1.0
		else:
			name_node.modulate.a = 0.0		#/ Kept space: the name, transparent
	else:
		name_node.visible = false


#* Show the line's own portrait:
func _show_line_portrait(source: CandyEngine, portrait: Node, record: Dictionary, active: bool) -> void:
	if portrait == null:
		return
	var loops: int = record["portrait_loops"]
	var stop_frame: int = record["portrait_stop"]
	var keep_space: bool = record["keep_portrait_space"]

	#Ł Whether it still plays as the active line (-3: until its voice ends):
	var playing := active
	if loops == CandyPortrait.PLAY_UNTIL_VOICE and record.get("voice_ended", false) == true:
		playing = false

	#¦ 1. Same line -the portrait carries on; a -1 one stops once advanced, a -3 one once its voice ends:
	if _portrait_record != null and is_same(_portrait_record, record):
		var endless_stop := loops == CandyPortrait.PLAY_UNTIL_ADVANCE or loops == CandyPortrait.PLAY_UNTIL_VOICE
		if not playing and endless_stop and record["show_portrait"] and not _portrait_stopped:
			_portrait_stopped = true
			CandyPortrait.get_shared().stop_portrait(source, self, portrait, stop_frame, _portrait_removed.bind(portrait, keep_space))
		return
	_portrait_record = record
	_portrait_stopped = false

	#¦ 2. New line -the active one plays, an earlier one shows stopped (or playing for -2):
	var play_loops := 0
	if playing or loops == CandyPortrait.PLAY_ALWAYS:
		play_loops = loops
	_show_portrait(source, portrait, record, record["show_portrait"], keep_space, play_loops, stop_frame)
	if not playing and loops != 0 and loops != CandyPortrait.PLAY_ALWAYS and record["show_portrait"]:
		_portrait_stopped = true
		CandyPortrait.get_shared().stop_portrait(source, self, portrait, stop_frame, _portrait_removed.bind(portrait, keep_space))

#* Show a portrait, keep its space, or hide it:
func _show_portrait(source: CandyEngine, portrait: Node, record: Dictionary, shown: bool, keep_space: bool,
		loops: int, stop_frame: int = CandyPortrait.DEFAULT_STOP_FRAME) -> void:
	if portrait == null:
		return
	if shown and not record["portrait"].is_empty():
		if CandyPortrait.get_shared().apply_portrait(source, self, portrait, record["portrait"], loops, stop_frame,
				portrait_config(), _portrait_removed.bind(portrait, keep_space)):
			portrait.visible = true
			return
	CandyPortrait.get_shared().clear_portrait(source, self, portrait)
	portrait.visible = keep_space		#/ Kept space: the empty node, held by its minimum size

#* Portrait removed on stop (Portrait_Stop 0) - keep its space or hide:
func _portrait_removed(portrait: Node, keep_space: bool) -> void:
	if is_instance_valid(portrait):
		portrait.visible = keep_space
