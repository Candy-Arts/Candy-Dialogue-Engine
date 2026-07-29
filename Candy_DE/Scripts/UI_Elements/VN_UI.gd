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


## REQUIRED: The parent of the Busts.
@export var busts_container: Node
## OPTIONAL: only for "Animation_1" speaker highlight effect.
@export var highlight_player_1: Node						#/ Add more for simultaneous highlights
## The name (or path) of speech bubbles inside bust nodes.
@export var speech_bubbles_name: String = "SpeechBubble"

#^ File extensions, one per kind of node:
#? UI element level of each extension chain. Empty = inherit the engine's.
## Extension given to files named without one, on TextureRect, NinePatchRect and TextureButton busts.[br][br]
## Leave empty to inherit the engine's [code]default_image_extension[/code].
@export var default_image_extension: String = ""
## Extension given to spritesheet files named without one, on Sprite2D and Sprite3D busts.[br][br]
## Leave empty to inherit the engine's [code]default_sprite_extension[/code].
@export var default_sprite_extension: String = ""
## Extension given to SpriteFrames files named without one, on AnimatedSprite2D and
## AnimatedSprite3D busts.[br][br]
## Leave empty to inherit the engine's [code]default_animated_sprite_extension[/code].
@export var default_animated_sprite_extension: String = ""
## Extension given to video files named without one, on VideoStreamPlayer busts.[br][br]
## Leave empty to inherit the engine's [code]default_video_extension[/code].
@export var default_video_extension: String = ""
## Default file extension for AnimationLibrary files named without one.
@export var default_effect_extension = ".tres"

#^ Frame rates, one per kind of media:
#? UI element level of each FPS chain. 0 = inherit the engine's.
## Frame rate for frame-folder animations on TextureRect and NinePatchRect busts.[br][br]
## Leave at 0 to inherit the engine's [code]default_animated_image_fps[/code].[br]
## A "config.txt" in the animation's own folder overrides this, and the "FPS" key on the
## dialogue line overrides both.
@export var default_animated_image_fps: float = 0.0
## Frame rate for spritesheets on Sprite2D and Sprite3D busts.[br][br]
## Leave at 0 to inherit the engine's [code]default_sprite_fps[/code]. The "FPS" key on the
## dialogue line overrides this.
@export var default_sprite_fps: float = 0.0
## Frame rate for SpriteFrames animations saved with no speed of their own, on
## AnimatedSprite2D and AnimatedSprite3D busts.[br][br]
## Leave at 0 to inherit the engine's [code]default_animated_sprite_fps[/code]. The "FPS" key
## on the dialogue line overrides this; a speed saved in the SpriteFrames overrides both.
@export var default_animated_sprite_fps: float = 0.0
## Frame rate "f=" targets count at on VideoStreamPlayer busts whose video's own frame rate
## can't be read.[br][br]
## Leave at 0 to inherit the engine's [code]default_video_fps[/code]. The video's own rate
## overrides this, and the "FPS" key on the dialogue line overrides both.
@export var default_video_fps: float = 0.0
## Frame rate "f=" targets fall back to on effects whose animation has no frames of its own
## to count.[br][br]
## Leave at 0 to inherit the engine's [code]default_effect_fps[/code]. The "FPS" key on the
## dialogue line overrides this.
@export var default_effect_fps: float = 0.0

#^ Animation folders (see Candy_Properties.gd):
## Memory budget of one animation folder on TextureRect and NinePatchRect busts, in MB: one
## whose frames fit in it keeps every frame loaded while it plays, one that doesn't is
## streamed. 0 streams every animation.[br][br]
## Leave at -1 to inherit the engine's [code]animation_folder_cache[/code], and through it the
## project-wide setting in Candy_Properties.gd. A config.txt ("cache") overrides this.
@export var animation_folder_cache: int = -1
## While an animation folder is streamed, how many frames are loaded ahead.[br][br]
## Leave at -1 to inherit the engine's [code]animation_folder_stream[/code], and through it the
## project-wide setting in Candy_Properties.gd. A config.txt ("stream") overrides this.
@export var animation_folder_stream: int = -1

## Used for scaling Sprite2D or Sprite3D nodes to the desired size.[br][br]
## "Node Name": [height, width]
@export var bust_sizes = {
	"1": [1080, 1024],
	"2": [1080, 1024],
	"3": [1080, 1024],
	"4": [1080, 1024],
	"5": [1080, 1024],
	"6": [1080, 1024],
	"7": [1080, 1024],
	"8": [1080, 1024],
	"9": [1080, 1024],
}

#^ Join/Move/Leave Effect Player:
@export var jml_player_name = "JML"

#^ Join/Move/Leave effects:
#? Effects played on busts when an actor joins, moves or leaves.
#? Non-empty overrides the general settings; actor settings override these.
#+ The animation must exist in the bust's JML player (jml_player_name).
## ["Method", "Value"][br]
## Method: "Animation", "Tween" or custom method (Tween and custom require custom code)[br]
## Value: Animation name
@export var vn_join_effect = ["", ""]
## ["Method", "Value"][br]
## Method: "Animation", "Tween" or custom method (Tween and custom require custom code)[br]
## Value: Animation name
@export var vn_move_from_effect = ["", ""]
## ["Method", "Value"][br]
## Method: "Animation", "Tween" or custom method (Tween and custom require custom code)[br]
## Value: Animation name
@export var vn_move_to_effect = ["", ""]
## ["Method", "Value"][br]
## Method: "Animation", "Tween" or custom method (Tween and custom require custom code)[br]
## Value: Animation name
@export var vn_leave_effect = ["", ""]

#^ Speaker highlight:
## How to highlight speaker busts:
@export var speaker_highlight = {
	"NameTag": false,				#/ Name tag near the speaker bust
	"Outline": false,				#/ Overlay image/animation (e.g. colored outline)
	"OutlineHideReal": false,		#/ Hide the real bust behind the outline
	"Scale": false,					#/ Scale the speaker bust
	"Scale_Size": 1.1,
	"Animation_1": false,			#/ Add keys for more animations
	"AnimationName_1": "highlight",
	"Billboard": true,				#/ Billboard on Sprite3D / AnimatedSprite3D
}

#^ Automatic billboard:
## Change these values to match what billboard mode to set Sprite3D busts to
@export var billboard_on = BaseMaterial3D.BILLBOARD_ENABLED
@export var billboard_off = BaseMaterial3D.BILLBOARD_DISABLED

#^ Z Index:
## Default Z-order.
@export var default_z = 50

#^ Access:
@export_group("Access")
## [b]Private[/b]: only the engine that owns this scene can command it - the engine whose
## ui_elements_paths lists it as owned.[br]
## [b]Public[/b]: any engine can, as Public Mode allows.[br][br]
## The Unrestricted Commands are accepted from any engine either way.
@export_enum("Private", "Public") var access: int = 0
## Public scenes only. While an engine holds this scene (it put an actor on it, or moved or swapped some):[br]
## [b]Exclusive[/b]: other engines' commands are rejected.[br]
## [b]Semi-Exclusive[/b]: other engines may only send the Semi-Exclusive Commands.[br]
## [b]Free[/b]: other engines may send any command, and one that takes hold takes the scene over.[br][br]
## A hold covers the whole scene, every bust included.
@export_enum("Exclusive", "Semi-Exclusive", "Free") var public_mode: int = 0
## Commands other engines may still send to this scene while it is Semi-Exclusive and held.
@export var semi_exclusive_commands: Array[String] = ["VN_Pause", "VN_Resume", "VN_Stop", "VN_Skip",
	"VN_Effect_Pause", "VN_Effect_Resume", "VN_Effect_Stop", "VN_Effect_Skip"]
## Commands that make the engine sending them hold this scene, when it is Public.[br]
## A line's "Take_Hold" key overrides this: 1 takes hold anyway, -1 never does.
@export var hold_commands: Array[String] = ["VN_Play", "VN_Move", "VN_Swap"]
## Commands accepted from any engine, whether this scene is Private or Public, held or not:
## they don't act on the scene itself, only on the engine's own dialogue.
@export var unrestricted_commands: Array[String] = ["VN_Wait", "VN_Effect_Wait"]

#^ Held scene overrides:
@export_group("Held Scene Overrides")
## Let this scene override whether the engine holding it suspends it with its dialogue.[br]
## Overrides the engine's setting and Candy_Properties.gd. A Private scene is always
## suspended by its owner, so this only matters when it is Public.
@export var enable_suspend_held_media: bool = false
## Whether the engine holding this scene suspends it along with its dialogue.
@export var suspend_held_media: bool = true
## Let this scene override whether the engine holding it applies its end-of-dialogue
## treatment to it (persistent_busts_on_end, jml_on_end).[br]
## Overrides the engine's setting and Candy_Properties.gd. A Private scene always gets its
## owner's treatment, so this only matters when it is Public.
@export var enable_end_held_media: bool = false
## Whether the engine holding this scene applies its end-of-dialogue treatment to it. If not,
## the scene is left as it is and the engine lets go of it.
@export var end_held_media: bool = true
@export_group("")

#^ Owner engine (Private):
var owner_engine: Node = null
#^ Engine this scene plays for (Public), else null:
var holder: Node = null

var caller: Node

#^ Actor → {"pos" = bust node name}:
#? Shared by every engine using this scene.
var bust_positions = {}

#^ Bust playback, by actor:
#? See _new_bust_state().
var bust_node_data = {}

#^ Effect playback, by actor, then full animation name:
#? See play_effect().
var bust_effect_data = {}

#^ Whether a suspension paused this scene:
var _suspended: bool = false
#^ AnimationPlayers the suspension paused:
var _suspended_animplayers: Array = []

#^ Timer stepping frame folders and spritesheets:
const VN_FRAME_TIMER: String = "SpriteAnimTimer"


#^ A "Lines" pause on a bust or effect:
#? Holds the counters CandyPlayback.set_pause() and the line countdown use.
class VNPauseHandle extends RefCounted:
	var pause_count: int = 0
	var pause_mode: String = "speech"
	var pause_engine: Node = null
	var element: Node = null
	var actor: String = ""
	var effect: String = ""		#/ "" = the bust's own playback

	#* Called by the engine when the line count runs out:
	func unpause() -> void:
		pause_count = 0
		if element != null and is_instance_valid(element):
			element.unpause_target(actor, effect)



func _ready():
	self.z_index = default_z


#& Bust Highlight Logic
#? How the speaker's bust is emphasized.
#+ Add custom dialogue modes to the match below, or split it per mode.

#? Basic highlight options, meant as templates.

#! Don't add AnimationPlayers as direct children of busts: they may conflict with VN_Effect's.
#! Revert highlight_speaker()'s effects in end_highlight_speaker().

#* Highlight the speaker bust:
@warning_ignore("unused_parameter")
func highlight_speaker(speaker_ref, dialogue_mode, custom_data: Array = []):
	if not bust_positions.has(speaker_ref):
		return

	var speaker_bust_ref = bust_positions[speaker_ref]["pos"]
	var speaker_bust = busts_container.get_node_or_null(speaker_bust_ref)
	if speaker_bust == null:
		printerr("highlight_speaker(): bust node not found → ", speaker_bust_ref)
		return

	match dialogue_mode:
		#TODO: Split modes into separate cases for different highlights.
		"Box", "Bubbles", "VN_Bubbles", "Subtitles", "Chat", "Voice":
			if speaker_highlight["NameTag"] == true:
				var name_tag = speaker_bust.get_node_or_null("NameTag")
				if name_tag != null:
					#Ł Show NameTag:
					name_tag.visible = true

					#Ł Write speaker name:
					#Ł Plain text, translated:
					var display_name: String = CandyActors.get_shared().display_name(caller, self, str(speaker_ref))
					#+ Alternative: copy the dialogue box's speaker text to keep BBCode:
					#display_name = get_node(caller.dialogue_box_path).speaker_node.text
					name_tag.text = display_name

					#Ł Clear the dialogue box's speaker field:
					#+ Or hide the speaker area (revert it in end_highlight_speaker()).
					var dialogue_box = CandyUI.get_shared().get_element(caller, self, "dialogue_box_path")
					if dialogue_box != null and "speaker_node" in dialogue_box and dialogue_box.speaker_node != null:
						dialogue_box.speaker_node.text = ""

			if speaker_highlight["Outline"] == true:
				#Ł Show the outline node:
				var speaker_outline = speaker_bust.get_node_or_null("Outline")
				if speaker_outline:
					speaker_outline.visible = true
				#Ł Hide the real bust:
				if speaker_highlight["OutlineHideReal"] == true:
					_set_bust_transparency(speaker_bust, 0.0)		#/ Fully transparent
				#TODO Write logic to display the outline.

			if speaker_highlight["Scale"] == true and "scale" in speaker_bust:
				#Ł Store the base scale, so resets don't compound:
				if not speaker_bust.has_meta("candy_base_scale"):
					speaker_bust.set_meta("candy_base_scale", speaker_bust.scale)
				speaker_bust.scale = speaker_bust.get_meta("candy_base_scale") * speaker_highlight["Scale_Size"]

			if speaker_highlight["Animation_1"] == true:
				if highlight_player_1 == null or not (highlight_player_1 is AnimationPlayer):
					printerr("highlight_speaker(): 'Animation_1' is enabled but highlight_player_1 is not assigned.")
				elif not highlight_player_1.has_animation(speaker_highlight["AnimationName_1"]):
					printerr("highlight_speaker(): animation not found on highlight_player_1 → ", speaker_highlight["AnimationName_1"])
				else:
					highlight_player_1.stop()
					highlight_player_1.root_node = highlight_player_1.get_path_to(speaker_bust)
					highlight_player_1.play(speaker_highlight["AnimationName_1"])

			if speaker_highlight["Billboard"] == true and "billboard" in speaker_bust:
				speaker_bust.billboard = billboard_on


#* Undo speaker bust highlighting:
@warning_ignore("unused_parameter")
func end_highlight_speaker(speaker_ref, dialogue_mode, custom_data: Array = []):
	if not bust_positions.has(speaker_ref):
		return

	var speaker_bust_ref = bust_positions[speaker_ref]["pos"]
	var speaker_bust = busts_container.get_node_or_null(speaker_bust_ref)
	if speaker_bust == null:
		printerr("end_highlight_speaker(): bust node not found → ", speaker_bust_ref)
		return

	match dialogue_mode:
		#TODO: Split modes into separate cases for different highlights.
		"Box", "Bubbles", "VN_Bubbles", "Subtitles", "Chat", "Voice":
			if speaker_highlight["NameTag"] == true:
				var name_tag = speaker_bust.get_node_or_null("NameTag")
				if name_tag != null:
					#Ł Clear NameTag:
					name_tag.visible = false
					name_tag.text = ""

			if speaker_highlight["Outline"] == true:
				#Ł Hide the outline node:
				var speaker_outline = speaker_bust.get_node_or_null("Outline")
				if speaker_outline:
					speaker_outline.visible = false
				#Ł Show the real bust:
				if speaker_highlight["OutlineHideReal"] == true:
					_set_bust_transparency(speaker_bust, 1.0)
				#TODO Write logic to remove outline display.

			if speaker_highlight["Scale"] == true and "scale" in speaker_bust:
				if speaker_bust.has_meta("candy_base_scale"):
					speaker_bust.scale = speaker_bust.get_meta("candy_base_scale")
					speaker_bust.remove_meta("candy_base_scale")
				elif speaker_bust is Sprite2D or speaker_bust is Sprite3D:
					_scale_bust_to_size(speaker_bust, speaker_bust_ref)
				elif speaker_bust is Node3D:
					speaker_bust.scale = Vector3.ONE
				else:
					speaker_bust.scale = Vector2.ONE

			if speaker_highlight["Animation_1"] == true:
				if highlight_player_1 is AnimationPlayer:
					highlight_player_1.stop()
					var reset_name := CandyPlayback.get_shared().reset_animation(caller, self, highlight_player_1, str(speaker_highlight["AnimationName_1"]))
					if reset_name != "":
						highlight_player_1.play(reset_name)

			if speaker_highlight["Billboard"] == true and "billboard" in speaker_bust:
				speaker_bust.billboard = billboard_off


#* Set a bust's alpha:
func _set_bust_transparency(bust_node: Node, alpha: float) -> void:
	if bust_node == null or not is_instance_valid(bust_node):
		return

	if "self_modulate" in bust_node:
		var tint: Color = bust_node.self_modulate
		tint.a = alpha
		bust_node.self_modulate = tint
	#% 3D sprites only have modulate:
	elif "modulate" in bust_node:
		var tint: Color = bust_node.modulate
		tint.a = alpha
		bust_node.modulate = tint
	else:
		printerr("_set_bust_transparency(): bust node has no modulate property → ", bust_node)


#& Access:
#? Same Private / Public model as media players. A hold covers the whole scene.

#* Accept or reject an engine's command, taking hold if it does:
#? 'command': its script's file name, any case.
func admit_command(engine: Node, command: String, take_hold: int = 0) -> String:
	var command_key := command.to_lower()

	#@ Step 1 - Unrestricted commands:
	if _lists_command(unrestricted_commands, command_key):
		return ""			#/ Accepted

	#@ Step 2 - Private (owner only):
	if access == 0:
		if owner_engine == null or not is_instance_valid(owner_engine):
			return "it is Private and no engine owns it. Set its Access to Public, or list it as owned in an engine's ui_elements_paths"
		if engine != owner_engine:
			return "it is Private to " + str(owner_engine.name)
		caller = engine
		return ""			#/ Accepted

	#@ Step 3 - Public (another engine's hold):
	if holder != null and is_instance_valid(holder) and holder != engine:
		if public_mode == 0:
			return "it is Exclusive and held by " + str(holder.name)
		if public_mode == 1 and not _lists_command(semi_exclusive_commands, command_key):
			return "it is Semi-Exclusive and held by " + str(holder.name) + ", which only lets other engines send " + ", ".join(semi_exclusive_commands)

	caller = engine

	#@ Step 4 - Take hold:
	if take_hold == 1 or (take_hold == 0 and _lists_command(hold_commands, command_key)):
		_take_hold(engine)

	return ""			#/ Accepted


#* Take hold for 'engine':
func _take_hold(engine: Node) -> void:
	if holder == engine:
		return

	release_hold()
	holder = engine
	if not (self in engine.held_ui_elements):
		engine.held_ui_elements.append(self)


#* Release the holding engine:
func release_hold() -> void:
	if holder != null and is_instance_valid(holder):
		holder.held_ui_elements.erase(self)
		#Ł Lift its suspension:
		unsuspend_media({"caller": holder})

	holder = null


#* Whether a list has a command, any case:
func _lists_command(list: Array[String], command_key: String) -> bool:
	for entry in list:
		if entry.to_lower() == command_key:
			return true
	return false


#& Suspension and dialogue end:

#* Pause for a dialogue suspension:
func suspend_media(candy_args: Dictionary) -> void:
	var source: CandyEngine = candy_args["caller"]
	if not source.suspend_vn_busts or _suspended:
		return

	_suspended = true

	if source.suspend_bust_animations:
		#% Only what is playing, so unsuspend_media() never lifts a VN_Pause:
		for actor in bust_node_data:
			var state: Dictionary = bust_node_data[actor]
			if bool(state["active"]) and _bust_moves(state):
				_halt_bust(state)
				state["suspended"] = true

	_suspended_animplayers.clear()
	if source.suspend_bust_effects:
		for player in _find_animation_players(self):
			if player.is_playing():
				player.pause()
				_suspended_animplayers.append(player)


#* Resume from a dialogue suspension:
@warning_ignore("unused_parameter")
func unsuspend_media(candy_args: Dictionary) -> void:
	if not _suspended:
		return

	_suspended = false

	for actor in bust_node_data:
		var state: Dictionary = bust_node_data[actor]
		if bool(state["suspended"]):
			state["suspended"] = false
			if _bust_moves(state):
				_proceed_bust(state)

	for player in _suspended_animplayers:
		if is_instance_valid(player):
			player.play()
	_suspended_animplayers.clear()


#* End-of-dialogue treatment:
func end_media(candy_args: Dictionary) -> void:
	var source: CandyEngine = candy_args["caller"]
	if source.persistent_busts_on_end:
		return

	#% Leave effects need the scene visible:
	if not source.jml_on_end:
		visible = false
	await clear_busts(candy_args, source.jml_on_end)
	visible = false


#* Find AnimationPlayers recursively:
func _find_animation_players(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		if child is AnimationPlayer:
			result.append(child)
		result.append_array(_find_animation_players(child))
	return result


#& Bust Display Logic:
#? Called by VN_ commands, one actor at a time.
#? candy_args: "caller", "command" and "key" (the actor, roles resolved; also its busts_folder sub-folder).
#? settings: the actor's line keys, resolved.

#* Put an actor on a bust and play a file (VN_Play):
func play_bust(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> bool:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "VN_Play"))
	var loop: int			= CandyPlayback.get_shared().normalize_loop(source, self, settings.get("Loops", "1"))

	self.visible = true		#/ In case the scene is hidden

	#@ Step 1 - Which bust:
	var bust_name := str(settings.get("Bust", "")).strip_edges()
	if bust_name == "":
		if not bust_positions.has(actor):
			printerr(context, ": no Bust given, and '", actor, "' is on no bust.")
			return false
		bust_name = str(bust_positions[actor]["pos"])

	#@ Step 2 - Bust already taken:
	for other_actor in bust_positions:
		if other_actor != actor and str(bust_positions[other_actor]["pos"]) == bust_name:
			printerr(context, ": bust '", bust_name, "' is occupied by '", other_actor, "' - '", actor, "' was not assigned.")
			return false

	var bust_node := _bust_node(bust_name, context)
	if bust_node == null:
		return false

	#@ Step 3 - Leave the old bust:
	#? No Move effect.
	var is_new_actor: bool = not bust_positions.has(actor)
	var left_old_bust := false
	if not is_new_actor and str(bust_positions[actor]["pos"]) != bust_name:
		var old_node: Node = busts_container.get_node_or_null(str(bust_positions[actor]["pos"]))
		if old_node != null:
			clear_old_bust_nodes(old_node)
			left_old_bust = true
		_forget_effects(actor)

	bust_positions[actor] = {"pos": bust_name}

	#@ Step 4 - Show the file:
	var shown := await _show_file(source, actor, bust_node, bust_name, settings, loop, context, custom_data)

	#@ Step 5 - Roll back if displayed nowhere:
	#% Only a new actor, or one whose old bust was cleared:
	if shown == "failed":
		if is_new_actor or left_old_bust:
			bust_positions.erase(actor)
			bust_node_data.erase(actor)
			printerr(context, ": '", actor, "' could not be displayed on '", bust_name, "' - bust assignment removed.")
		return false

	#@ Step 6 - New actor (Join effect):
	if is_new_actor:
		await _on_play_jml(source, "Join", actor, bust_node, null, _line_jml(settings, "Join_Effect", context))

	return shown == "playing"			#/ Playback started


#* Show a file on a bust and start it, returning "failed", "static" or "playing":
func _show_file(source: CandyEngine, actor: String, bust_node: Node, bust_name: String, settings: Dictionary, loop: int, context: String, custom_data: Array) -> String:
	#@ Step 1 - Default extension by node type:
	var default_ext := ""
	var frames_subfolder := ""
	if bust_node is TextureRect or bust_node is NinePatchRect or bust_node is TextureButton:
		default_ext = CandyPlayback.get_shared().resolve_extension(source, self, "default_image_extension", default_image_extension)
	elif bust_node is Sprite2D or bust_node is Sprite3D:
		default_ext = CandyPlayback.get_shared().resolve_extension(source, self, "default_sprite_extension", default_sprite_extension)
	elif bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
		default_ext = CandyPlayback.get_shared().resolve_extension(source, self, "default_animated_sprite_extension", default_animated_sprite_extension)
		frames_subfolder = "Sprite_Frames"
	elif bust_node is VideoStreamPlayer:
		default_ext = CandyPlayback.get_shared().resolve_extension(source, self, "default_video_extension", default_video_extension)
	else:
		printerr(context, ": unsupported bust node type → ", bust_name, " (", bust_node.get_class(), ")")
		return "failed"

	#@ Step 2 - Resolve the reference:
	var resolved := CandyMedia.resolve_media(settings.get("File", ""), candy_de.busts_folder.path_join(actor), default_ext, frames_subfolder)
	if not bool(resolved["found"]):
		printerr(context, ": missing file → ", resolved["path"])
		return "failed"

	var file_path: String = str(resolved["path"])

	#@ Step 3 - Stop what the bust was playing:
	_invalidate_bust(bust_node)
	var state := _new_bust_state(actor, bust_node, loop)

	#Ł Drop the stored pre-highlight scale:
	if bust_node.has_meta("candy_base_scale"):
		bust_node.remove_meta("candy_base_scale")

	#@ Step 4 - Set up by node type:
	#¦ 1. TextureRect / NinePatchRect / TextureButton - frame folder:
	if (bust_node is TextureRect or bust_node is NinePatchRect or bust_node is TextureButton) and bool(resolved["is_folder"]):
		#Ł First frame loads now, the rest while playing (see CandyFrameStream):
		#? A TextureButton's state folders play along.
		var stream := CandyFrameStream.open(source, self, file_path, animation_folder_cache, animation_folder_stream, bust_node)
		if stream.count() == 0 or stream.frame_now(0) == null:
			printerr(context, ": no frames found in → ", file_path)
			return "failed"

		#Ł FPS (properties → engine → default_animated_image_fps → config.txt files → line):
		var anim_fps: float = CandyPlayback.get_shared().resolve_fps(source, self, "default_animated_image_fps", settings.get("FPS", ""),
			default_animated_image_fps, CandyMedia.read_config_fps(file_path), file_path)

		state["kind"] = "folder"
		state["stream"] = stream
		state["fps"] = anim_fps
		state["frame_count"] = stream.count()
		state["duration"] = float(stream.count()) / anim_fps
		state["start"] = func(start_loop: int) -> void:
			_start_folder(actor, start_loop)

		#Ł Clear the previous image's extra slots:
		if bust_node is TextureButton:
			_clear_button_slots(bust_node)
		stream.show_frame_now(bust_node, 0)
		bust_node.visible = true

	#¦ 2. TextureRect / NinePatchRect - a static image:
	elif bust_node is TextureRect or bust_node is NinePatchRect:
		var tex := _resolved_texture(resolved)
		if not (tex is Texture2D):
			printerr(context, ": invalid texture → ", file_path)
			return "failed"
		bust_node.texture = tex
		bust_node.visible = true
		return "static"			#/ Nothing plays

	#¦ 3. TextureButton - a static image, with its Button_Textures:
	elif bust_node is TextureButton:
		var tex := _resolved_texture(resolved)
		if not (tex is Texture2D):
			printerr(context, ": invalid texture → ", file_path)
			return "failed"

		#Ł Clear the previous image's extra slots:
		_clear_button_slots(bust_node)
		bust_node.texture_normal = tex
		bust_node.visible = true

		#Ł Button_Textures subfolder beside the file:
		var file_base = file_path.get_file().get_basename()
		var subfolder_name = file_base + "_" + file_path.get_extension().to_lower()
		var button_folder = file_path.get_base_dir().path_join("Button_Textures").path_join(subfolder_name)
		if DirAccess.dir_exists_absolute(button_folder):
			CandyUI.get_shared().apply_button_textures(source, self, bust_node, button_folder, file_base)

		return "static"			#/ Nothing plays

	#¦ 4. Sprite2D / Sprite3D - an image or a spritesheet:
	elif bust_node is Sprite2D or bust_node is Sprite3D:
		var tex := _resolved_texture(resolved)
		if not (tex is Texture2D):
			printerr(context, ": invalid texture → ", file_path)
			return "failed"

		#Ł Layout from the file name, "<name>_<H>x<V>[-<empty>]":
		var layout_source := file_path
		if layout_source == "":
			layout_source = str(tex.resource_path)
		var regex := RegEx.new()
		regex.compile("(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")
		var result := regex.search(layout_source.get_file())
		var hframes := 1
		var vframes := 1
		var missing := 0
		if result:
			hframes = int(result.get_string(1))
			vframes = int(result.get_string(2))
			if result.get_string(3) != "":
				missing = int(result.get_string(3))

		bust_node.texture = tex
		bust_node.hframes = hframes
		bust_node.vframes = vframes
		bust_node.frame = 0
		bust_node.visible = true
		_scale_bust_to_size(bust_node, bust_name)

		var sheet_fps: float = CandyPlayback.get_shared().resolve_fps(source, self, "default_sprite_fps", settings.get("FPS", ""),
			default_sprite_fps, 0.0, file_path)

		state["kind"] = "sheet"
		state["fps"] = sheet_fps
		state["frame_count"] = max(hframes * vframes - missing, 1)
		state["duration"] = float(state["frame_count"]) / sheet_fps

		#% A single frame has nothing to play:
		if int(state["frame_count"]) <= 1:
			return "static"

		state["start"] = func(start_loop: int) -> void:
			_start_sheet(actor, start_loop)

	#¦ 5. AnimatedSprite2D / AnimatedSprite3D - a SpriteFrames resource:
	elif bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
		var frames := _resolved_sprite_frames(resolved)
		if frames == null:
			printerr(context, ": invalid SpriteFrames resource → ", file_path)
			return "failed"

		#Ł "Animation", then one named like the file, then the first that has frames:
		var requested := str(settings.get("Animation", "")).strip_edges()
		var file_name := file_path.get_file().get_basename()
		var anim := ""
		if requested != "" and frames.has_animation(requested):
			anim = requested
		elif file_name != "" and frames.has_animation(file_name):
			anim = file_name
		else:
			for candidate in frames.get_animation_names():
				if frames.get_frame_count(candidate) > 0:
					anim = candidate
					break
		if anim == "":
			printerr(context, ": no animation in → ", file_path)
			return "failed"

		#Ł SpriteFrames' own speed wins; the FPS chain fills a missing one:
		frames = CandyPlayback.get_shared().sprite_frames_with_speed(source, self, frames, anim, settings.get("FPS", ""),
			default_animated_sprite_fps, file_path)
		var speed: float = frames.get_animation_speed(anim)

		bust_node.sprite_frames = frames
		bust_node.animation = anim
		bust_node.frame = 0
		bust_node.visible = true

		var duration := 0.0
		for i in frames.get_frame_count(anim):
			duration += frames.get_frame_duration(anim, i) / speed

		state["kind"] = "animated"
		state["anim"] = anim
		state["fps"] = speed
		state["frame_count"] = frames.get_frame_count(anim)
		state["duration"] = duration
		state["start"] = func(start_loop: int) -> void:
			_start_animated(actor, start_loop)

	#¦ 6. VideoStreamPlayer - a video:
	elif bust_node is VideoStreamPlayer:
		var stream := _resolved_video(resolved)
		if stream == null:
			printerr(context, ": invalid video stream → ", file_path)
			return "failed"

		bust_node.stream = stream
		bust_node.visible = true

		#Ł Video's own frame rate, for "f=" targets:
		state["kind"] = "video"
		state["fps"] = CandyPlayback.get_shared().resolve_fps(source, self, "default_video_fps", settings.get("FPS", ""),
			default_video_fps, CandyPlayback.get_shared().video_fps(source, self, stream), file_path)
		state["start"] = func(start_loop: int) -> void:
			await _start_video(actor, start_loop)

	#@ Step 5 - Start playback:
	var duration_seconds := CandyPlayDuration.read(source, self, settings.get("Duration", "null"), true, 0.0,
		_bust_frame_converter(state, settings))
	state["end_frame"] = CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""), 0, context, false)
	await _begin(source, actor, "", state, loop, custom_data, duration_seconds)
	return "playing"


#* Block until a bust reaches a loop count and/or time:
@warning_ignore("unused_parameter")
func wait_bust(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> String:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "VN_Wait"))

	var state: Dictionary = bust_node_data.get(actor, {})
	if state.is_empty() or not bool(state["active"]):
		return "Continue"

	var wait: int = int(settings.get("Wait_Loops", "0"))
	var target_time := CandyPlayback.get_shared().resolve_time_target(source, self, settings.get("Wait_Time", ""), true, 0.0,
		_bust_frame_converter(state, settings))
	if wait <= 0 and target_time <= 0.0:
		return "Continue"

	var warned_open_pause := false

	while true:
		if source.killswitch == true:
			return "END"

		#% Freeze while suspended:
		if source.dialogue_suspended == true:
			await source._await_suspension()
			continue

		#% Replaced, stopped or finished:
		if not is_same(bust_node_data.get(actor, {}), state) or not bool(state["active"]):
			break

		#% Paused by VN_Pause:
		if bool(state["paused"]):
			if _pause_blocks_wait(state["pause_handle"], context, actor, warned_open_pause):
				break
			warned_open_pause = true
			await get_tree().process_frame
			continue

		var duration := _bust_duration(state)
		var elapsed: float = int(state["loops_played"]) * duration + _bust_position(state)
		#% Wait_Loops × length + Wait_Time reached:
		if elapsed >= max(wait, 0) * duration + target_time:
			break

		await get_tree().process_frame

	return "Continue"


#* Pause a bust (VN_Pause):
@warning_ignore("unused_parameter")
func pause_bust(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> Tween:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "VN_Pause"))

	var state: Dictionary = bust_node_data.get(actor, {})
	if state.is_empty() or not bool(state["active"]):
		printerr(context, ": nothing is playing on the bust of → ", actor)
		return null

	#% Video busts - the loop lowers their own volume_db:
	var volume_property: Variant = null
	if str(state["kind"]) == "video":
		volume_property = ""
	var pause_loop := CandyPauseLoop.start(source, self, state["node"], settings, _bust_pause_loop_media(source, actor, state, settings),
		context, state.get("pause_loop", null) as CandyPauseLoop, volume_property)
	state["pause_loop"] = pause_loop

	#% Already suspended - stays halted as a VN_Pause, unless it loops:
	if pause_loop == null:
		if not bool(state["suspended"]):
			_halt_bust(state)
		state["suspended"] = false
	state["paused"] = true

	_drop_pause(state)
	var handle := VNPauseHandle.new()
	handle.element = self
	handle.actor = actor
	state["pause_handle"] = handle
	CandyPlayback.get_shared().set_pause(source, self, handle, int(settings.get("Lines", -1)), int(settings.get("All", 0)))

	if pause_loop != null:
		return pause_loop.pause_fade			#/ The fade a "!" Pause_Volume_Time waits on
	return null


#* Resume a bust (VN_Resume):
@warning_ignore("unused_parameter")
func resume_bust(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> Tween:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])

	var state: Dictionary = bust_node_data.get(actor, {})
	if state.is_empty():
		printerr(str(candy_args.get("command", "VN_Resume")), ": nothing was played on the bust of → ", actor)
		return null

	#% Start a held playback:
	if int(state["loop_target"]) == 0 and (state["start"] as Callable).is_valid():
		await _begin(source, actor, "", state, 1, custom_data)
		return null

	return unpause_target(actor, "", settings, source)			#/ The fade a "!" Resume_Volume_Time waits on


#* Stop a bust, keeping it on screen (VN_Stop):
@warning_ignore("unused_parameter")
func stop_bust(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "VN_Stop"))
	var stop_frame: int		= CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""), 0, context, false)

	var bust_node := _actor_node(actor, context)
	if bust_node == null:
		return

	var state: Dictionary = bust_node_data.get(actor, {})

	#@ Step 1 - Schedule a "Loops" / "Duration" stop:
	#? Kept on the playback, so it follows a moved bust.
	if not state.is_empty() and bool(state["active"]):
		var loop := CandyPlayDuration.read_stop_loop(settings.get("Loops", ""), context)
		var duration_seconds := CandyPlayDuration.read(source, self, settings.get("Duration", ""), true, 0.0,
			_bust_frame_converter(state, settings))
		if CandyPlayDuration.schedules(loop, duration_seconds):
			state["end_frame"] = stop_frame
			state["duration_loop"] = maxi(loop, 0)
			state["duration_seconds"] = duration_seconds
			_drop_play_duration(state)
			state["play_duration"] = CandyPlayDuration.schedule_stop(self, loop, duration_seconds, _play_duration_media(state, ""))
			return

	#@ Step 2 - End playback:
	_invalidate_bust(bust_node)
	if not state.is_empty():
		_drop_pause(state)
		_drop_pause_loop(state)
		state["active"] = false
		state["paused"] = false
		state["suspended"] = false

	#@ Step 3 - Settle on the stop frame:
	_settle_bust(bust_node, state, stop_frame)
	bust_node.visible = true


#* Settle a bust on its stop frame:
#? 'stop_frame': 0 = current, -1 = last, N = frame N from 1.
func _settle_bust(bust_node: Node, state: Dictionary, stop_frame: int) -> void:
	if stop_frame == 0:
		return

	if bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
		var sf: SpriteFrames = bust_node.sprite_frames
		if sf != null and sf.has_animation(bust_node.animation):
			var total: int = sf.get_frame_count(bust_node.animation)
			if stop_frame == -1:
				bust_node.frame = total - 1
			else:
				bust_node.frame = clampi(stop_frame - 1, 0, total - 1)

	elif bust_node is Sprite2D or bust_node is Sprite3D:
		if bust_node.texture != null:
			var total := CandyMedia.sheet_frame_count(bust_node)
			if not state.is_empty() and int(state["frame_count"]) > 0:
				total = int(state["frame_count"])
			if stop_frame == -1:
				bust_node.frame = total - 1
			else:
				bust_node.frame = clampi(stop_frame - 1, 0, total - 1)

	elif bust_node is TextureRect or bust_node is NinePatchRect or bust_node is TextureButton:
		if not state.is_empty() and str(state["kind"]) == "folder":
			var stream: CandyFrameStream = state["stream"]
			var index := 0
			if stop_frame == -1:
				index = stream.count() - 1
			else:
				index = clampi(stop_frame - 1, 0, stream.count() - 1)
			state["frame_index"] = index
			stream.show_frame_now(bust_node, index)

	elif bust_node is VideoStreamPlayer:
		#? stop() drops the picture, so pause to hold a frame. The last frame can't be seeked reliably.
		if stop_frame > 0 and not state.is_empty() and float(state["fps"]) > 0.0:
			#% An ended video has stopped - play it to show a frame:
			if not bust_node.is_playing():
				bust_node.play()
			bust_node.paused = true
			bust_node.stream_position = float(stop_frame - 1) / float(state["fps"])


#* Seek a bust within the current loop (VN_Skip):
@warning_ignore("unused_parameter")
func skip_bust(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])

	var state: Dictionary = bust_node_data.get(actor, {})
	if state.is_empty() or not (state["start"] as Callable).is_valid():
		printerr(str(candy_args.get("command", "VN_Skip")), ": nothing to skip through on the bust of → ", actor)
		return

	#% Pause loop playing - move the pause point instead:
	if _pause_loop_owns_position(state):
		state["pause_loop"].move_pause_point(settings.get("Time", 0.0))
		return

	#Ł Seek (a paused or held playback moves without starting):
	var target := _seek_target(source, _bust_position(state), settings.get("Time", 0.0), _bust_frame_converter(state, settings))
	_seek_bust(state, clampf(target, 0.0, _bust_duration(state)))


#* Flip a bust (VN_Mirror):
@warning_ignore("unused_parameter")
func mirror_bust(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var actor: String	= str(candy_args["key"])
	var context: String	= str(candy_args.get("command", "VN_Mirror"))
	var axis: String	= str(settings.get("Axis", "Reset")).strip_edges().to_lower()

	var bust_node := _actor_node(actor, context)
	if bust_node == null:
		return

	if not ("flip_h" in bust_node):
		printerr(context, ": this bust's node type can't be flipped → ", actor, " (", bust_node.get_class(), ")")
		return

	if axis == "h flip" or axis == "both":
		bust_node.flip_h = not bust_node.flip_h
	if axis == "v flip" or axis == "both":
		bust_node.flip_v = not bust_node.flip_v
	if axis == "reset":		#/ Nodes with flip_h have flip_v
		bust_node.flip_h = false
		bust_node.flip_v = false


#* Move an actor to another bust, keeping its playback (VN_Move):
@warning_ignore("unused_parameter")
func move_bust(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> bool:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "VN_Move"))
	var new_bust: String	= str(settings.get("Bust", "")).strip_edges()

	self.visible = true		#/ In case the scene is hidden

	#@ Step 1 - Check the move:
	if not bust_positions.has(actor):
		printerr(context, ": '", actor, "' is on no bust - move skipped.")
		return false
	if new_bust == "":
		printerr(context, ": no Bust given for '", actor, "' - move skipped.")
		return false

	var old_bust: String = str(bust_positions[actor]["pos"])
	if old_bust == new_bust:
		return false

	for other_actor in bust_positions:
		if other_actor != actor and str(bust_positions[other_actor]["pos"]) == new_bust:
			printerr(context, ": bust '", new_bust, "' is occupied by '", other_actor, "' - move skipped. VN_Swap trades two actors' busts.")
			return false

	var bust_node_old := _bust_node(old_bust, context)
	var bust_node_new := _bust_node(new_bust, context)
	if bust_node_old == null or bust_node_new == null:
		return false

	if not _same_bust_kind(bust_node_old, bust_node_new, context):
		return false

	#@ Step 2 - Snapshot playback, copy visuals to the new node:
	var state: Dictionary = bust_node_data.get(actor, {})
	var snapshot := _snapshot_playback(state)

	_invalidate_bust(bust_node_new)
	bust_node_new.visible = false
	_apply_visuals(bust_node_new, new_bust, _capture_visuals(bust_node_old))

	#@ Step 3 - Switch the actor to the new bust:
	#? Waits follow state["node"] during the effects.
	if not state.is_empty():
		state["node"] = bust_node_new
	bust_positions[actor]["pos"] = new_bust
	_invalidate_bust(bust_node_old)

	await _on_play_jml(source, "Move_From", actor, bust_node_new, bust_node_old, _line_jml(settings, "Move_From_Effect", context))

	#Ł Re-parent effect players, so the actor keeps its effects:
	#? Before clear_old_bust_nodes(), which would stop them.
	for effect_child in _effect_players_of(bust_node_old):
		bust_node_old.remove_child(effect_child)
		bust_node_new.add_child(effect_child)

	clear_old_bust_nodes(bust_node_old)

	await _on_play_jml(source, "Move_To", actor, bust_node_new, bust_node_old, _line_jml(settings, "Move_To_Effect", context))

	bust_node_new.visible = true

	#@ Step 4 - Carry on playing where it was:
	await _resume_playback(state, bust_node_new, snapshot)

	return true			#/ Moved


#* Trade two actors' busts, keeping their playback (VN_Swap):
@warning_ignore("unused_parameter")
func swap_bust(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> bool:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "VN_Swap"))
	var other: String		= str(CandyActors.get_shared().actor_from_role(source, self, str(settings.get("With", "")).strip_edges(), context)).strip_edges()

	self.visible = true		#/ In case the scene is hidden

	#@ Step 1 - Check the swap:
	if other == "":
		printerr(context, ": no With given for '", actor, "' - swap skipped.")
		return false
	if other == actor:
		printerr(context, ": '", actor, "' can't swap with itself - swap skipped.")
		return false
	for swapped in [actor, other]:
		if not bust_positions.has(swapped):
			printerr(context, ": '", swapped, "' is on no bust - swap skipped.")
			return false

	var bust_a: String = str(bust_positions[actor]["pos"])
	var bust_b: String = str(bust_positions[other]["pos"])
	var node_a := _bust_node(bust_a, context)
	var node_b := _bust_node(bust_b, context)
	if node_a == null or node_b == null:
		return false

	if not _same_bust_kind(node_a, node_b, context):
		return false

	#@ Step 2 - Snapshot both playbacks and visuals:
	var state_a: Dictionary = bust_node_data.get(actor, {})
	var state_b: Dictionary = bust_node_data.get(other, {})
	var snapshot_a := _snapshot_playback(state_a)
	var snapshot_b := _snapshot_playback(state_b)
	var visuals_a := _capture_visuals(node_a)
	var visuals_b := _capture_visuals(node_b)

	_invalidate_bust(node_a)
	_invalidate_bust(node_b)

	#@ Step 3 - Both leave their busts:
	var move_from: Variant = _line_jml(settings, "Move_From_Effect", context)
	await _play_jml_together(source, "Move_From", [[actor, node_b, node_a, move_from], [other, node_a, node_b, move_from]])

	#@ Step 4 - Trade visuals, effect players and records:
	var effects_a := _effect_players_of(node_a)
	var effects_b := _effect_players_of(node_b)
	for effect_child in effects_a:
		node_a.remove_child(effect_child)
		node_b.add_child(effect_child)
	for effect_child in effects_b:
		node_b.remove_child(effect_child)
		node_a.add_child(effect_child)

	_apply_visuals(node_a, bust_a, visuals_b)
	_apply_visuals(node_b, bust_b, visuals_a)
	for swapped_node in [node_a, node_b]:
		if swapped_node.has_meta("candy_base_scale"):
			swapped_node.remove_meta("candy_base_scale")

	if not state_a.is_empty():
		state_a["node"] = node_b
	if not state_b.is_empty():
		state_b["node"] = node_a
	bust_positions[actor]["pos"] = bust_b
	bust_positions[other]["pos"] = bust_a

	#@ Step 5 - Both arrive on their new busts:
	var move_to: Variant = _line_jml(settings, "Move_To_Effect", context)
	await _play_jml_together(source, "Move_To", [[actor, node_b, node_a, move_to], [other, node_a, node_b, move_to]])

	#@ Step 6 - Carry on playing where they were:
	await _resume_playback(state_a, node_b, snapshot_a)
	await _resume_playback(state_b, node_a, snapshot_b)

	return true			#/ Swapped


#* Whether two bust nodes share a kind:
func _same_bust_kind(node_a: Node, node_b: Node, context: String) -> bool:
	var same := true
	if node_a is AnimatedSprite2D or node_a is AnimatedSprite3D:
		same = node_b is AnimatedSprite2D or node_b is AnimatedSprite3D
	elif node_a is Sprite2D or node_a is Sprite3D:
		same = node_b is Sprite2D or node_b is Sprite3D
	elif node_a is TextureButton:
		same = node_b is TextureButton
	elif node_a is TextureRect or node_a is NinePatchRect:
		same = node_b is TextureRect or node_b is NinePatchRect
	elif node_a is VideoStreamPlayer:
		same = node_b is VideoStreamPlayer

	if not same:
		printerr("%s: '%s' (%s) and '%s' (%s) are not the same node type - skipped."
			% [context, node_a.name, node_a.get_class(), node_b.name, node_b.get_class()])
	return same


#* Capture a bust node's visuals:
func _capture_visuals(bust_node: Node) -> Dictionary:
	var visuals: Dictionary = {"visible": bust_node.visible}

	#Ł Flips and tint, highlight included:
	for property in ["flip_h", "flip_v", "modulate", "self_modulate"]:
		if property in bust_node:
			visuals[property] = bust_node.get(property)

	var properties: Array = []
	if bust_node is Sprite2D or bust_node is Sprite3D:
		properties = ["texture", "hframes", "vframes", "frame"]
	elif bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
		properties = ["sprite_frames", "animation", "frame"]
	elif bust_node is VideoStreamPlayer:
		properties = ["stream", "loop"]
	elif bust_node is TextureRect or bust_node is NinePatchRect:
		properties = ["texture"]
	elif bust_node is TextureButton:
		properties = ["texture_normal", "texture_pressed", "texture_hover", "texture_disabled", "texture_focused", "texture_click_mask"]

	for property in properties:
		visuals[property] = bust_node.get(property)
	return visuals


#* Apply captured visuals to a bust node:
func _apply_visuals(bust_node: Node, bust_name: String, visuals: Dictionary) -> void:
	#@ Step 1 - All but visibility, left to the caller:
	for property in visuals:
		if property != "visible" and property in bust_node:
			bust_node.set(property, visuals[property])

	#@ Step 2 - Rescale spritesheets:
	if bust_node is Sprite2D or bust_node is Sprite3D:
		_scale_bust_to_size(bust_node, bust_name)


#* A bust node's effect AnimationPlayers (not the JML player):
func _effect_players_of(bust_node: Node) -> Array:
	var players: Array = []
	for child in bust_node.get_children():
		if child is AnimationPlayer and child.name != jml_player_name:
			players.append(child)
	return players


#* Snapshot an actor's playback before it changes bust:
func _snapshot_playback(state: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {"active": false, "paused": false, "position": 0.0, "loops": 0, "handle": null, "lines_left": 0, "pause_loop": null}
	if state.is_empty():
		return snapshot

	#@ Step 1 - Drop the Duration:
	_drop_play_duration(state)

	#@ Step 2 - Set the pause loop aside, so restarting doesn't end it:
	var pause_loop: Variant = state.get("pause_loop", null)
	if pause_loop is CandyPauseLoop and pause_loop.is_running():
		pause_loop.freeze()
		snapshot["pause_loop"] = pause_loop
	state["pause_loop"] = null

	snapshot["active"] = bool(state["active"])
	snapshot["paused"] = bool(state["paused"])
	snapshot["position"] = _bust_position(state)
	snapshot["loops"] = int(state["loops_played"])
	snapshot["handle"] = state["pause_handle"]
	if state["pause_handle"] != null:
		snapshot["lines_left"] = int(state["pause_handle"].pause_count)
	return snapshot


#* Resume an actor's playback on its new bust:
func _resume_playback(state: Dictionary, bust_node: Node, snapshot: Dictionary) -> void:
	var pause_loop: Variant = snapshot["pause_loop"]
	if bool(snapshot["active"]) and not state.is_empty() and (state["start"] as Callable).is_valid():
		#Ł Restart on the new node, then restore loop count, position and pause:
		await (state["start"] as Callable).call(int(state["loop_target"]))
		state["loops_played"] = int(snapshot["loops"])
		_seek_bust(state, float(snapshot["position"]))
		if pause_loop is CandyPauseLoop:
			state["pause_loop"] = pause_loop
			pause_loop.thaw(bust_node)
		#Ł Re-follow the Duration:
		_follow_duration(state, "")
		if bool(snapshot["paused"]):
			state["paused"] = true
			state["pause_handle"] = snapshot["handle"]
			if snapshot["handle"] != null:
				snapshot["handle"].pause_count = int(snapshot["lines_left"])
			if not _bust_moves(state):
				_halt_bust(state)
		return

	#% Nothing restarts - cancel the pause loop:
	if pause_loop is CandyPauseLoop:
		pause_loop.cancel()

	if bust_node is VideoStreamPlayer and bust_node.stream != null:
		var gen := int(bust_node.get_meta("bust_generation", 0))
		bust_node.loop = false
		bust_node.paused = false
		bust_node.play()
		await get_tree().process_frame
		if _is_current(bust_node, gen):
			bust_node.stream_position = float(snapshot["position"])
			bust_node.paused = true


#* Play one JML effect for several actors and wait for all:
#? 'jobs': [actor, new bust, old bust, line effect or null] per actor.
func _play_jml_together(source: Node, event: String, jobs: Array) -> void:
	var batch: Dictionary = {"pending": jobs.size()}
	for job in jobs:
		_play_jml_job(source, event, job, batch)
	while int(batch["pending"]) > 0:
		await get_tree().process_frame


#* Play one actor's JML effect, and count it done:
func _play_jml_job(source: Node, event: String, job: Array, batch: Dictionary) -> void:
	await _on_play_jml(source, event, job[0], job[1], job[2], job[3])
	batch["pending"] = int(batch["pending"]) - 1


#* A line's JML effect under 'key', or null:
func _line_jml(settings: Dictionary, key: String, context: String) -> Variant:
	if not settings.has(key) or CandySettings.is_not_set(settings[key]):
		return null			#/ The actor's effect plays

	var value: Variant = settings[key]
	if value is Array:
		if value.is_empty() or str(value[0]).strip_edges() == "":
			return []			#/ No effect
		if value.size() < 2:
			printerr(context, ": ", key, " must be [\"Method\", \"Value\"] or an animation name → ", value, " - no effect played.")
			return []
		return [str(value[0]).strip_edges(), str(value[1]).strip_edges()]

	var anim_name := str(value).strip_edges()
	if anim_name == "":
		return []			#/ No effect
	return ["Animation", anim_name]


#* Remove an actor from its bust (VN_Remove):
@warning_ignore("unused_parameter")
func remove_bust(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> bool:
	var actor: String	= str(candy_args["key"])
	var context: String	= str(candy_args.get("command", "VN_Remove"))
	if not bust_positions.has(actor):
		printerr(context, ": '", actor, "' is on no bust.")
		return false

	#Ł Leave effect, then remove:
	await _remove_actor(candy_args["caller"], actor, true, _line_jml(settings, "Leave_Effect", context))
	return true			#/ Removed


#* Remove every actor (UI_Clear, dialogue end):
@warning_ignore("unused_parameter")
func clear_busts(candy_args: Dictionary, play_leave: bool = false, custom_data: Array = []) -> void:
	#Ł One actor after another:
	for actor in bust_positions.keys():
		await _remove_actor(candy_args.get("caller", null), actor, play_leave)


#* Remove one actor and clear its bust:
func _remove_actor(source: Node, actor: String, play_leave: bool, line_effect: Variant = null) -> void:
	var bust_node: Node = busts_container.get_node_or_null(str(bust_positions[actor]["pos"]))

	#@ Step 1 - Stop playback and effects:
	if bust_node_data.has(actor):
		_drop_pause(bust_node_data[actor])
		_drop_pause_loop(bust_node_data[actor])
	_forget_effects(actor)

	if bust_node != null:
		_invalidate_bust(bust_node)
		for child in bust_node.get_children():
			if child is AnimationPlayer and child.name != jml_player_name:
				_stop_effect_player(child)

		#@ Step 2 - Leave effect:
		if play_leave:
			await _on_play_jml(source, "Leave", actor, null, bust_node, line_effect)

		#@ Step 3 - Clear the node:
		clear_old_bust_nodes(bust_node)

	#@ Step 4 - Forget the actor:
	bust_positions.erase(actor)
	bust_node_data.erase(actor)


#* Clear a bust node completely:
func clear_old_bust_nodes(bust_node_old: Node) -> void:
	#@ Step 1 - Stop playback:
	_invalidate_bust(bust_node_old)

	#Ł Stop effect players (not the JML player):
	for child in bust_node_old.get_children():
		if child is AnimationPlayer and child.name != jml_player_name:
			_stop_effect_player(child)

	#@ Step 2 - Clear visuals:
	if bust_node_old is TextureRect or bust_node_old is NinePatchRect:
		bust_node_old.texture = null

	elif bust_node_old is TextureButton:
		bust_node_old.texture_normal = null
		bust_node_old.texture_pressed = null
		bust_node_old.texture_hover = null
		bust_node_old.texture_disabled = null
		bust_node_old.texture_focused = null
		bust_node_old.texture_click_mask = null

	elif bust_node_old is Sprite2D or bust_node_old is Sprite3D:
		bust_node_old.texture = null
		bust_node_old.hframes = 1
		bust_node_old.vframes = 1
		bust_node_old.frame = 0
		if bust_node_old is Sprite3D:
			bust_node_old.scale = Vector3.ONE
		else:
			bust_node_old.scale = Vector2.ONE

	elif bust_node_old is AnimatedSprite2D or bust_node_old is AnimatedSprite3D:
		bust_node_old.sprite_frames = null
		bust_node_old.frame = 0

	elif bust_node_old is VideoStreamPlayer:
		bust_node_old.stop()
		bust_node_old.paused = false
		bust_node_old.stream = null
		bust_node_old.stream_position = 0.0

	bust_node_old.visible = false

	#@ Step 3 - Reset flips:
	if "flip_h" in bust_node_old:
		bust_node_old.flip_h = false
		bust_node_old.flip_v = false

	#@ Step 4 - Drop the stored pre-highlight scale:
	if bust_node_old.has_meta("candy_base_scale"):
		bust_node_old.remove_meta("candy_base_scale")


#* Lift a pause on a bust (effect "") or an effect:
#? 'settings': the _Resume entry ({} = the pause's own); 'source': null = the pausing engine.
func unpause_target(actor: String, effect: String, settings: Dictionary = {}, source: CandyEngine = null) -> Tween:
	var state := _target_state(actor, effect)
	if state.is_empty():
		return null

	#Ł Cancel the "Lines" count:
	_drop_pause(state)
	if not bool(state["paused"]):
		return null

	var fade: Tween = null
	var pause_loop: Variant = state.get("pause_loop", null)
	if pause_loop is CandyPauseLoop:
		fade = pause_loop.resume(source, settings)
	state["paused"] = false

	#% Suspended - stays halted until the suspension ends:
	if effect == "":
		if _suspended:
			state["suspended"] = true
		else:
			_proceed_bust(state)
		return fade			#/ The fade a "!" Resume_Volume_Time waits on

	var player: AnimationPlayer = state["player"]
	if not is_instance_valid(player):
		return fade			#/ The fade a "!" Resume_Volume_Time waits on
	if _suspended:
		if not (player in _suspended_animplayers):
			_suspended_animplayers.append(player)
	else:
		player.play()
	return fade			#/ The fade a "!" Resume_Volume_Time waits on


#& Join / Move / Leave effects:

#* Play a JML effect:
func _on_play_jml(source: Node, event: String, actor: String, bust_node_new: Node, bust_node_old: Node, line_effect: Variant = null) -> void:
	var jml_method = ""
	var jml_value = ""

	#@ Step 1 - Line effect wins; empty plays nothing:
	if line_effect != null:
		if line_effect.is_empty():
			return
		jml_method = str(line_effect[0])
		jml_value = str(line_effect[1])

	var actor_key := ""
	var scene_effect: Array = []
	var engine_key := ""
	match event:
		"Join":
			actor_key = "VNJoinEffect"
			scene_effect = vn_join_effect
			engine_key = "vn_join_effect"
		"Move_From":
			actor_key = "VNMoveFromEffect"
			scene_effect = vn_move_from_effect
			engine_key = "vn_move_from_effect"
		"Move_To":
			actor_key = "VNMoveToEffect"
			scene_effect = vn_move_to_effect
			engine_key = "vn_move_to_effect"
		"Leave":
			actor_key = "VNLeaveEffect"
			scene_effect = vn_leave_effect
			engine_key = "vn_leave_effect"

	#@ Step 2 - Else actor, then scene, then engine:
	if jml_method == "" and candy_de.actors.has(actor) and candy_de.actors[actor].has(actor_key):
		jml_method = candy_de.actors[actor][actor_key][0]
		jml_value = candy_de.actors[actor][actor_key][1]
	if jml_method == "" and scene_effect.size() >= 2:
		jml_method = scene_effect[0]
		jml_value = scene_effect[1]
	if jml_method == "" and source != null and engine_key in source:
		var engine_effect = source.get(engine_key)
		if engine_effect.size() >= 2:
			jml_method = engine_effect[0]
			jml_value = engine_effect[1]

	if jml_method == "":
		return

	#@ Step 3 - Play by method:
	match jml_method:
		#TODO: Add your own custom methods.
		#¦ 1. JML AnimationPlayer:
		"Animation":
			match event:
				"Join", "Move_To":
					var jml_player = bust_node_new.get_node_or_null(jml_player_name)
					if jml_player == null or not jml_player.has_animation(jml_value):
						return

					jml_player.play(jml_value)
					await get_tree().process_frame
					bust_node_new.visible = true
					await _await_jml(jml_player, jml_value)
					var reset_name := CandyPlayback.get_shared().reset_animation(source, self, jml_player, jml_value)
					if reset_name != "":
						jml_player.play(reset_name)

				"Move_From", "Leave":
					var jml_player = bust_node_old.get_node_or_null(jml_player_name)
					if jml_player == null or not jml_player.has_animation(jml_value):
						return
					jml_player.play(jml_value)
					await _await_jml(jml_player, jml_value)
					var reset_name := CandyPlayback.get_shared().reset_animation(source, self, jml_player, jml_value)
					if reset_name != "":
						jml_player.play(reset_name)

		#¦ 2. Tween:
		"Tween":
			#TODO: Write your tween code.
			pass

		_:
			print("_on_play_jml(): Error: unknown JML method")
			return


#* Wait for a JML animation to finish:
func _await_jml(jml_player: AnimationPlayer, anim_name: String) -> void:
	if not is_instance_valid(jml_player):
		return

	var anim: Animation = null
	if jml_player.has_animation(anim_name):
		anim = jml_player.get_animation(anim_name)
	var looping: bool = anim != null and anim.loop_mode != Animation.LOOP_NONE
	if looping:
		push_warning("Candy DE: JML animation '%s' is set to loop; waiting one cycle instead of animation_finished." % anim_name)

	var prev_pos: float = -1.0
	var prev_dir: int = 0

	while true:
		if not is_instance_valid(jml_player):
			return

		if jml_player.is_playing():
			if str(jml_player.current_animation) != anim_name:
				return

			if looping:
				var pos: float = jml_player.current_animation_position
				if anim.loop_mode == Animation.LOOP_LINEAR:
					if prev_pos >= 0.0 and pos < prev_pos:
						return
				else:
					var dir := prev_dir
					if prev_pos >= 0.0:
						if pos > prev_pos:
							dir = 1
						elif pos < prev_pos:
							dir = -1
					if prev_dir == -1 and dir == 1:
						return
					prev_dir = dir
				prev_pos = pos

		else:
			#% Paused by suspension - hold, and don't take the resume for a wrap:
			if jml_player in _suspended_animplayers and str(jml_player.assigned_animation) == anim_name:
				prev_pos = -1.0
			else:
				return

		await get_tree().process_frame


#& Bust Playback Internals:

#* The bust node a line names, or null after reporting:
func _bust_node(bust_name: String, context: String) -> Node:
	if busts_container == null:
		printerr(context, ": the bust scene has no busts_container.")
		return null
	var bust_node: Node = busts_container.get_node_or_null(bust_name)
	if bust_node == null:
		printerr(context, ": bust node not found → ", bust_name)
	return bust_node


#* The bust node an actor is on, or null after reporting:
func _actor_node(actor: String, context: String) -> Node:
	if not bust_positions.has(actor):
		printerr(context, ": '", actor, "' is on no bust.")
		return null
	return _bust_node(str(bust_positions[actor]["pos"]), context)


#* Create an actor's playback state, replacing any earlier one:
func _new_bust_state(actor: String, bust_node: Node, loop: int) -> Dictionary:
	if bust_node_data.has(actor):
		_drop_pause(bust_node_data[actor])
		_drop_pause_loop(bust_node_data[actor])

	var state: Dictionary = {
		"kind": "static",			#/ "static", "folder", "sheet", "animated" (SpriteFrames) or "video"
		"node": bust_node,
		"loop_target": loop,
		"loops_played": 0,
		"duration": 0.0,
		"active": false,			#/ A playback dialogue may wait on runs
		"paused": false,			#/ VN_Pause
		"suspended": false,		#/ Dialogue suspension
		"fps": 0.0,
		"frame_count": 0,
		"stream": null,
		"frame_index": 0,
		"anim": "",
		"start": Callable(),		#/ Callable(loop) that (re)starts it (VN_Resume on a held one, VN_Move / VN_Swap)
		"gen": -1,
		"pause_handle": null,
		"end_frame": 0,
	}

	bust_node_data[actor] = state
	return state


#* Start playback between the playback hooks:
func _begin(source: CandyEngine, actor: String, effect: String, state: Dictionary, loop: int, custom_data: Array,
		duration_seconds: float = 0.0) -> void:
	var hook_args := {"caller": source, "node": self, "actor": actor, "effect": effect}
	var start_loop := CandyPlayDuration.play_loop(loop, duration_seconds)

	if start_loop != 0:
		await candy_de.run_node_hook(self, "x_playback_starting", hook_args, custom_data)

	await (state["start"] as Callable).call(start_loop)

	#Ł Kept so VN_Move / VN_Swap can follow it:
	state["duration_loop"] = loop
	state["duration_seconds"] = duration_seconds
	_follow_duration(state, effect)

	if start_loop != 0:
		await candy_de.run_node_hook(self, "x_playback_started", hook_args, custom_data)


#* Reset a state for a fresh playback, run under generation 'gen':
func _reset_state(state: Dictionary, loop: int, gen: int) -> void:
	state["gen"] = gen
	state["loop_target"] = loop
	state["loops_played"] = 0
	state["active"] = loop != 0
	state["paused"] = false
	state["suspended"] = false
	_drop_pause(state)
	_drop_pause_loop(state)
	_drop_play_duration(state)


#* (Re)start a frame folder, stepping its frames on a Timer:
func _start_folder(actor: String, loop: int) -> void:
	var state: Dictionary = bust_node_data[actor]
	var bust_node: Node = state["node"]
	var stream: CandyFrameStream = state["stream"]
	var gen := _invalidate_bust(bust_node)
	_reset_state(state, loop, gen)

	state["frame_index"] = 0
	stream.show_frame_now(bust_node, 0)

	#% Held, or nothing to step through:
	if loop == 0 or stream.count() <= 1:
		state["active"] = false
		return

	var timer := _new_frame_timer(bust_node, float(state["fps"]))

	var animate := func() -> void:
		while true:
			await timer.timeout
			if not _is_current(bust_node, gen):
				return
			var index: int = int(state["frame_index"]) + 1
			if index >= stream.count():
				#% A pause loop may take over the end:
				if _pause_loop_takes_end(state):
					continue
				state["loops_played"] = int(state["loops_played"]) + 1
				#% Done - settle on the end frame:
				if int(state["loop_target"]) > 0 and int(state["loops_played"]) >= int(state["loop_target"]):
					state["active"] = false
					_clear_frame_timer(bust_node)
					_settle_bust(bust_node, state, int(state["end_frame"]))
					return
				index = 0
			state["frame_index"] = index
			#? Unloaded frames are skipped; timing goes on.
			stream.show_frame(bust_node, index)

	animate.call()


#* (Re)start a Sprite2D/3D spritesheet, stepping its frames on a Timer:
func _start_sheet(actor: String, loop: int) -> void:
	var state: Dictionary = bust_node_data[actor]
	var bust_node: Node = state["node"]
	var gen := _invalidate_bust(bust_node)
	_reset_state(state, loop, gen)

	bust_node.frame = 0

	#% Held, or nothing to step through:
	if loop == 0 or int(state["frame_count"]) <= 1:
		state["active"] = false
		return

	var timer := _new_frame_timer(bust_node, float(state["fps"]))

	var animate := func() -> void:
		while true:
			await timer.timeout
			if not _is_current(bust_node, gen):
				return
			var next_frame: int = bust_node.frame + 1
			if next_frame >= int(state["frame_count"]):
				#% A pause loop may take over the end:
				if _pause_loop_takes_end(state):
					continue
				state["loops_played"] = int(state["loops_played"]) + 1
				#% Done - settle on the end frame:
				if int(state["loop_target"]) > 0 and int(state["loops_played"]) >= int(state["loop_target"]):
					state["active"] = false
					_clear_frame_timer(bust_node)
					_settle_bust(bust_node, state, int(state["end_frame"]))
					return
				next_frame = 0
			bust_node.frame = next_frame

	animate.call()


#* (Re)start an AnimatedSprite2D/3D:
func _start_animated(actor: String, loop: int) -> void:
	var state: Dictionary = bust_node_data[actor]
	var bust_node: Node = state["node"]
	var anim: String = str(state["anim"])
	var gen := _invalidate_bust(bust_node)
	_reset_state(state, loop, gen)

	#? Set the animation first, or the previous one stays.
	bust_node.animation = anim
	bust_node.set_frame_and_progress(0, 0.0)

	#% Loops 0 holds on the first frame:
	if loop == 0:
		bust_node.stop()
		bust_node.animation = anim
		bust_node.frame = 0
		return

	#Ł A looping SpriteFrames animation never emits animation_finished:
	var anim_loops: bool = bust_node.sprite_frames.get_animation_loop(anim)

	var run := func() -> void:
		while true:
			#? play() restarts a finished animation.
			bust_node.play(anim)
			_mark_parked(bust_node, gen)
			if anim_loops:
				await bust_node.animation_looped
			else:
				await bust_node.animation_finished
			_clear_parked(bust_node, gen)

			if not _is_current(bust_node, gen):
				return

			#% A pause loop may take over the end:
			#? It already moved playback; play() only carries on.
			if _pause_loop_takes_end(state):
				continue

			state["loops_played"] = int(state["loops_played"]) + 1

			#% Done - settle on the end frame:
			#? pause(), as stop() rewinds.
			if int(state["loop_target"]) > 0 and int(state["loops_played"]) >= int(state["loop_target"]):
				bust_node.pause()
				state["active"] = false
				_settle_bust(bust_node, state, int(state["end_frame"]))
				return

	run.call()


#* (Re)start a video:
func _start_video(actor: String, loop: int) -> void:
	var state: Dictionary = bust_node_data[actor]
	var bust_node: Node = state["node"]
	var gen := _invalidate_bust(bust_node)
	_reset_state(state, loop, gen)

	#Ł Candy counts loops - the node's own loop swallows 'finished':
	bust_node.loop = false
	bust_node.stop()
	bust_node.paused = false
	bust_node.play()
	await get_tree().process_frame

	#% Reassigned during that frame:
	if not _is_current(bust_node, gen):
		return

	#? Theora reports no length until a frame plays (else Wait targets collapse to 0).
	state["duration"] = float(bust_node.get_stream_length())

	#% Loops 0 holds on the first frame:
	if loop == 0:
		bust_node.paused = true
		return

	var run := func() -> void:
		while true:
			_mark_parked(bust_node, gen)
			await bust_node.finished
			_clear_parked(bust_node, gen)
			if not _is_current(bust_node, gen):
				return
			#% A pause loop may take over the end:
			if _pause_loop_takes_end(state):
				continue
			state["loops_played"] = int(state["loops_played"]) + 1
			#% Done - settle on the end frame:
			if int(state["loop_target"]) > 0 and int(state["loops_played"]) >= int(state["loop_target"]):
				state["active"] = false
				_settle_bust(bust_node, state, int(state["end_frame"]))
				return
			bust_node.play()

	run.call()


#* Pause whatever drives a bust's playback:
func _halt_bust(state: Dictionary) -> void:
	var bust_node: Node = state["node"]
	if not is_instance_valid(bust_node):
		return

	match str(state["kind"]):
		"folder", "sheet":
			var timer := bust_node.get_node_or_null(VN_FRAME_TIMER)
			if timer is Timer:
				timer.paused = true
		"animated":
			bust_node.pause()
		"video":
			bust_node.paused = true


#* Undo _halt_bust():
func _proceed_bust(state: Dictionary) -> void:
	var bust_node: Node = state["node"]
	if not is_instance_valid(bust_node) or not bool(state["active"]):
		return

	match str(state["kind"]):
		"folder", "sheet":
			var timer := bust_node.get_node_or_null(VN_FRAME_TIMER)
			if timer is Timer:
				timer.paused = false
		"animated":
			bust_node.play()
		"video":
			bust_node.paused = false


#* Seek within the current loop:
func _seek_bust(state: Dictionary, target: float) -> void:
	var bust_node: Node = state["node"]
	if not is_instance_valid(bust_node):
		return

	match str(state["kind"]):
		"folder":
			var stream: CandyFrameStream = state["stream"]
			var index := clampi(int(target * float(state["fps"])), 0, stream.count() - 1)
			state["frame_index"] = index
			stream.show_frame_now(bust_node, index)
			_restart_frame_timer(bust_node)
		"sheet":
			bust_node.frame = clampi(int(target * float(state["fps"])), 0, int(state["frame_count"]) - 1)
			_restart_frame_timer(bust_node)
		"animated":
			_set_animated_time(bust_node, state, target)
		"video":
			bust_node.stream_position = target


#* Length of one loop of a bust's playback, in seconds:
func _bust_duration(state: Dictionary) -> float:
	#% Video length is only known once playing - read live until then:
	if str(state["kind"]) == "video" and float(state["duration"]) <= 0.0:
		var bust_node: Node = state["node"]
		if is_instance_valid(bust_node):
			state["duration"] = float(bust_node.get_stream_length())
	return float(state["duration"])


#* Position within the current loop of a bust's playback, in seconds:
func _bust_position(state: Dictionary) -> float:
	var bust_node: Node = state["node"]
	if not is_instance_valid(bust_node):
		return 0.0

	match str(state["kind"]):
		"folder":
			return float(state["frame_index"]) / float(state["fps"]) + _frame_timer_progress(bust_node)
		"sheet":
			return float(bust_node.frame) / float(state["fps"]) + _frame_timer_progress(bust_node)
		"animated":
			var sf: SpriteFrames = bust_node.sprite_frames
			var anim: String = str(state["anim"])
			if sf == null or not sf.has_animation(anim):
				return 0.0
			var elapsed: float = CandyPlayback.get_shared().sprite_frames_frame_time(null, self, sf, anim, bust_node.frame)
			var speed: float = sf.get_animation_speed(anim)
			if speed > 0.0 and bust_node.frame < sf.get_frame_count(anim):
				elapsed += float(bust_node.frame_progress) * sf.get_frame_duration(anim, bust_node.frame) / speed
			return elapsed
		"video":
			return float(bust_node.stream_position)
	return 0.0


#* "f=" frame → seconds, for a bust:
func _bust_frame_converter(state: Dictionary, settings: Dictionary) -> Callable:
	var line_fps := _line_fps(settings)
	return func(frame: float) -> float:
		if str(state["kind"]) == "animated":
			var bust_node: Node = state["node"]
			if is_instance_valid(bust_node) and bust_node.sprite_frames != null:
				return CandyPlayback.get_shared().sprite_frames_frame_time(null, self, bust_node.sprite_frames, str(state["anim"]), int(round(frame)))
		var frame_rate: float = float(state["fps"])
		if line_fps > 0.0:
			frame_rate = line_fps
		if frame_rate <= 0.0:
			return 0.0
		return frame / frame_rate


#* Place an AnimatedSprite at a time within its animation:
func _set_animated_time(bust_node: Node, state: Dictionary, target: float) -> void:
	var sf: SpriteFrames = bust_node.sprite_frames
	var anim: String = str(state["anim"])
	if sf == null or not sf.has_animation(anim):
		return
	var speed: float = sf.get_animation_speed(anim)
	var count: int = sf.get_frame_count(anim)
	if speed <= 0.0 or count <= 0:
		return

	var start := 0.0
	for i in count:
		var frame_length: float = sf.get_frame_duration(anim, i) / speed
		if target < start + frame_length or i == count - 1:
			var progress := 0.0
			if frame_length > 0.0:
				progress = clampf((target - start) / frame_length, 0.0, 1.0)
			bust_node.set_frame_and_progress(i, progress)
			return
		start += frame_length


#* Create the Timer that steps a frame folder or spritesheet:
func _new_frame_timer(bust_node: Node, frame_rate: float) -> Timer:
	_clear_frame_timer(bust_node)
	var timer := Timer.new()
	timer.name = VN_FRAME_TIMER
	timer.wait_time = 1.0 / max(frame_rate, 0.001)
	bust_node.add_child(timer)
	timer.start()
	return timer


#* Remove a bust's frame Timer:
func _clear_frame_timer(bust_node: Node) -> void:
	if not is_instance_valid(bust_node):
		return
	var timer := bust_node.get_node_or_null(VN_FRAME_TIMER)
	if timer:
		timer.stop()
		bust_node.remove_child(timer)
		timer.queue_free()


#* Restart the current frame after a skip:
func _restart_frame_timer(bust_node: Node) -> void:
	var timer := bust_node.get_node_or_null(VN_FRAME_TIMER)
	#% Paused and stopped Timers stay so:
	if timer is Timer and not timer.is_stopped():
		timer.start()


#* How far the current frame of a frame Timer has run, in seconds:
func _frame_timer_progress(bust_node: Node) -> float:
	var timer := bust_node.get_node_or_null(VN_FRAME_TIMER)
	if not (timer is Timer) or timer.is_stopped():
		return 0.0
	return clampf(timer.wait_time - timer.time_left, 0.0, timer.wait_time)


#* Whether a bust's generation still matches the one a coroutine started with:
func _is_current(bust_node: Node, gen: int) -> bool:
	return is_instance_valid(bust_node) and int(bust_node.get_meta("bust_generation", 0)) == gen


#* Mark a node as having a coroutine parked on its signals:
func _mark_parked(node: Node, generation: int) -> void:
	if is_instance_valid(node):
		node.set_meta("candy_parked_generation", generation)


#* Clear that mark after a signal arrived normally:
func _clear_parked(node: Node, generation: int) -> void:
	if is_instance_valid(node) and int(node.get_meta("candy_parked_generation", -1)) == generation:
		node.remove_meta("candy_parked_generation")


#* Clear a TextureButton bust's state textures:
func _clear_button_slots(bust_node: TextureButton) -> void:
	bust_node.texture_pressed = null
	bust_node.texture_hover = null
	bust_node.texture_disabled = null
	bust_node.texture_focused = null
	bust_node.texture_click_mask = null


#* Invalidate a bust's playback coroutine, halt it and wake it to exit:
func _invalidate_bust(bust_node: Node) -> int:
	if not is_instance_valid(bust_node):
		return 0

	var gen: int = int(bust_node.get_meta("bust_generation", 0)) + 1
	bust_node.set_meta("bust_generation", gen)

	_clear_frame_timer(bust_node)

	#@ Step 1 - Whether a coroutine is waiting on this node:
	var parked: bool = bust_node.has_meta("candy_parked_generation")
	if parked:
		bust_node.remove_meta("candy_parked_generation")

	#@ Step 2 - Wake it to exit, if it is there:
	#? Only parked nodes, so game code never sees a false completion.
	#? Halt, not stop: stop() rewinds AnimatedSprites and blanks videos. pause() never emits these signals.
	if bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
		bust_node.pause()
		if parked:
			bust_node.animation_finished.emit()
			bust_node.animation_looped.emit()
	elif bust_node is VideoStreamPlayer:
		if bust_node.is_playing():
			bust_node.paused = true
		if parked:
			bust_node.finished.emit()

	return gen			#/ The bust's new generation


#& Effect Logic:
#? Called by VN_Effect_ commands, one effect on one bust at a time.
#? candy_args: as for busts, plus "animation" (the effect's line key).
#? Effects play on a bust AnimationPlayer (not the JML one): its current one, a free one, or a new one.
#? Effects follow the actor when it moves.

#* Play an effect on a bust (VN_Effect_Play):
func play_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> bool:
	var source: CandyEngine		= candy_args["caller"]
	var actor: String			= str(candy_args["key"])
	var anim_key: String		= str(candy_args.get("animation", "")).strip_edges()
	var context: String			= str(candy_args.get("command", "VN_Effect_Play"))
	var library_ref: Variant	= settings.get("Library", "")
	var loop: int				= CandyPlayback.get_shared().normalize_loop(source, self, settings.get("Loops", "1"))

	var bust_node := _actor_node(actor, context)
	if bust_node == null:
		return false
	if anim_key == "":
		printerr(context, ": no animation given for → ", actor)
		return false

	#@ Step 1 - Load the Library:
	#? With a Library, the key names one of its animations.
	var library: AnimationLibrary = null
	var library_name := ""
	var full_name := anim_key

	if library_ref is Resource or str(library_ref).strip_edges() != "":
		var resolved := CandyMedia.resolve_media(library_ref, candy_de.busts_folder.path_join("Animation_Libraries"), default_effect_extension, "", false)
		if not bool(resolved["found"]) or bool(resolved["is_folder"]):
			printerr(context, ": missing AnimationLibrary → ", resolved["path"])
			return false

		var loaded = resolved["resource"]
		if loaded == null:
			loaded = CandyMedia.load_animation_library(str(resolved["path"]))
		if not (loaded is AnimationLibrary):
			printerr(context, ": not an AnimationLibrary → ", library_ref)
			return false
		library = loaded

		#Ł Name - file name, else resource name (runtime libraries):
		library_name = str(resolved["path"]).get_file().get_basename()
		if library_name == "":
			library_name = str(library.resource_name)
		if library_name == "":
			library_name = "Library"

		#Ł Load under its own name, whatever "Library/" prefix the key has:
		var anim_part := anim_key
		if "/" in anim_key:
			anim_part = anim_key.get_slice("/", 1)
		full_name = library_name + "/" + anim_part

		if not library.has_animation(anim_part):
			printerr(context, ": animation not found → '", anim_part, "' in library ", library_name)
			return false

	#@ Step 2 - Pick the AnimationPlayer:
	#? Without a Library: one that has the animation ("Library/Name" or its own).
	var player := _pick_effect_player(bust_node, actor, full_name, library_name, library)
	if player == null:
		printerr(context, ": animation not found → '", full_name, "' on the bust of ", actor, " (give a Library, or write it as 'Library/Name')")
		return false

	if library != null:
		var library_current := false
		if player.has_animation_library(library_name):
			library_current = player.get_animation_library(library_name) == library
		if not library_current:
			#Ł Swap out earlier effects' libraries; keep the global one:
			player.stop()
			for loaded_name in player.get_animation_library_list():
				if str(loaded_name) != "":
					player.remove_animation_library(loaded_name)
			player.add_animation_library(library_name, library)

	#Ł Forget earlier effects on this player:
	var effects: Dictionary = bust_effect_data.get(actor, {})
	for other_name in effects.keys():
		if other_name != full_name and effects[other_name]["player"] == player:
			_drop_pause(effects[other_name])
			_drop_pause_loop(effects[other_name])
			effects.erase(other_name)

	#@ Step 3 - Record the effect:
	if effects.has(full_name):
		_drop_pause(effects[full_name])
		_drop_pause_loop(effects[full_name])

	var state: Dictionary = {
		"player": player,
		"anim": full_name,
		"animation": player.get_animation(full_name),
		"loop_target": loop,
		"loops_played": 0,
		"duration": player.get_animation(full_name).length,
		"active": false,
		"paused": false,
		"suspended": false,
		"gen": -1,
		"pause_handle": null,
		"start": Callable(),
		"end_frame": 0,
		"end_converter": Callable(),
	}
	state["start"] = func(start_loop: int) -> void:
		_start_effect(state, start_loop)
	state["end_frame"] = CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""), 0, context)
	state["end_converter"] = _effect_frame_converter(source, state, settings)

	effects[full_name] = state
	bust_effect_data[actor] = effects

	#@ Step 4 - Start playback:
	var duration_seconds := CandyPlayDuration.read(source, self, settings.get("Duration", "null"), true, 0.0,
		_effect_frame_converter(source, state, settings))
	await _begin(source, actor, full_name, state, loop, custom_data, duration_seconds)
	return true			#/ Playback started


#* Block until an effect reaches a loop count and/or time:
@warning_ignore("unused_parameter")
func wait_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> String:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "VN_Effect_Wait"))

	var full_name := _find_effect(actor, str(candy_args.get("animation", "")), settings)
	var state := _target_state(actor, full_name)
	if state.is_empty() or not bool(state["active"]):
		return "Continue"

	var wait: int = int(settings.get("Wait_Loops", "0"))
	var target_time := CandyPlayback.get_shared().resolve_time_target(source, self, settings.get("Wait_Time", ""), true, 0.0,
		_effect_frame_converter(source, state, settings))
	if wait <= 0 and target_time <= 0.0:
		return "Continue"

	var target_total: float = max(wait, 0) * float(state["duration"]) + target_time
	var warned_open_pause := false

	while true:
		if source.killswitch == true:
			return "END"

		#% Freeze while suspended:
		if source.dialogue_suspended == true:
			await source._await_suspension()
			continue

		#% Replaced, stopped or finished:
		if not is_same(_target_state(actor, full_name), state) or not bool(state["active"]):
			break

		#% Paused by VN_Effect_Pause:
		if bool(state["paused"]):
			if _pause_blocks_wait(state["pause_handle"], context, actor + "/" + full_name, warned_open_pause):
				break
			warned_open_pause = true
			await get_tree().process_frame
			continue

		var elapsed: float = int(state["loops_played"]) * float(state["duration"]) + _effect_position(state)
		if elapsed >= target_total:
			break

		await get_tree().process_frame

	return "Continue"


#* Pause an effect (VN_Effect_Pause):
@warning_ignore("unused_parameter")
func pause_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "VN_Effect_Pause"))

	var full_name := _find_effect(actor, str(candy_args.get("animation", "")), settings)
	var state := _target_state(actor, full_name)
	if state.is_empty() or not bool(state["active"]):
		printerr(context, ": that effect is not playing on → ", actor, "/", candy_args.get("animation", ""))
		return

	var player: AnimationPlayer = state["player"]
	var pause_loop := CandyPauseLoop.start(source, self, player, settings, _effect_pause_loop_media(source, actor, state, settings),
		context, state.get("pause_loop", null) as CandyPauseLoop)
	state["pause_loop"] = pause_loop

	#% A pause loop the suspension halted stays held by it:
	if pause_loop == null:
		if is_instance_valid(player) and player.is_playing():
			player.pause()
		_suspended_animplayers.erase(player)		#/ Now held by the pause
	state["paused"] = true

	_drop_pause(state)
	var handle := VNPauseHandle.new()
	handle.element = self
	handle.actor = actor
	handle.effect = full_name
	state["pause_handle"] = handle
	CandyPlayback.get_shared().set_pause(source, self, handle, int(settings.get("Lines", -1)), int(settings.get("All", 0)))


#* Resume an effect (VN_Effect_Resume):
func resume_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])

	var full_name := _find_effect(actor, str(candy_args.get("animation", "")), settings)
	var state := _target_state(actor, full_name)
	if state.is_empty():
		printerr(str(candy_args.get("command", "VN_Effect_Resume")), ": that effect was not played on → ", actor, "/", candy_args.get("animation", ""))
		return

	#% Start a held effect:
	if int(state["loop_target"]) == 0:
		await _begin(source, actor, full_name, state, 1, custom_data)
		return

	unpause_target(actor, full_name, settings, source)


#* Stop an effect, releasing waits on it (VN_Effect_Stop):
@warning_ignore("unused_parameter")
func stop_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "VN_Effect_Stop"))

	var full_name := _find_effect(actor, str(candy_args.get("animation", "")), settings)
	var state := _target_state(actor, full_name)
	if state.is_empty():
		printerr(context, ": that effect was not played on → ", actor, "/", candy_args.get("animation", ""))
		return

	var stop_frame := CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""),
		CandyPlayback.STOP_FRAME_CLEAR, context)

	#@ Step 1 - A "Loops" or "Duration" schedules the stop:
	if bool(state["active"]):
		var loop := CandyPlayDuration.read_stop_loop(settings.get("Loops", ""), context)
		var duration_seconds := CandyPlayDuration.read(source, self, settings.get("Duration", ""), true, 0.0,
			_effect_frame_converter(source, state, settings))
		if CandyPlayDuration.schedules(loop, duration_seconds):
			state["end_frame"] = stop_frame
			state["end_converter"] = _effect_frame_converter(source, state, settings)
			state["duration_loop"] = maxi(loop, 0)
			state["duration_seconds"] = duration_seconds
			_drop_play_duration(state)
			state["play_duration"] = CandyPlayDuration.schedule_stop(self, loop, duration_seconds, _play_duration_media(state, full_name))
			return

	#@ Step 2 - Stop now:
	_drop_pause(state)
	_drop_pause_loop(state)
	if stop_frame == CandyPlayback.STOP_FRAME_CLEAR:
		_stop_effect_player(state["player"])
	else:
		_stop_effect_player(state["player"], false)
		CandyPlayback.get_shared().settle_animation(source, self, state["player"], stop_frame,
			_effect_frame_converter(source, state, settings))
	bust_effect_data[actor].erase(full_name)


#* Seek an effect within its current loop (VN_Effect_Skip):
@warning_ignore("unused_parameter")
func skip_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine	= candy_args["caller"]
	var actor: String		= str(candy_args["key"])

	var full_name := _find_effect(actor, str(candy_args.get("animation", "")), settings)
	var state := _target_state(actor, full_name)
	if state.is_empty() or not is_instance_valid(state["player"]):
		printerr(str(candy_args.get("command", "VN_Effect_Skip")), ": that effect was not played on → ", actor, "/", candy_args.get("animation", ""))
		return

	#% Pause loop playing - move the pause point instead:
	if _pause_loop_owns_position(state):
		state["pause_loop"].move_pause_point(settings.get("Time", 0.0))
		return

	#Ł Seek (a paused or held effect moves without starting):
	var target := _seek_target(source, _effect_position(state), settings.get("Time", 0.0), _effect_frame_converter(source, state, settings))
	state["player"].seek(clampf(target, 0.0, float(state["duration"])), true)


#& Effect Internals:

#* Pick the AnimationPlayer for an effect (never the JML player):
func _pick_effect_player(bust_node: Node, actor: String, full_name: String, library_name: String, library: AnimationLibrary) -> AnimationPlayer:
	var effects: Dictionary = bust_effect_data.get(actor, {})

	#% Already playing this effect:
	if effects.has(full_name) and is_instance_valid(effects[full_name]["player"]):
		var current: AnimationPlayer = effects[full_name]["player"]
		if library == null or current.has_animation_library(library_name) or not _effect_player_busy(actor, current, full_name):
			return current

	var candidates: Array = []
	for child in bust_node.get_children():
		if child is AnimationPlayer and child.name != jml_player_name:
			candidates.append(child)

	#% Without a library, the animation must already be there:
	if library == null:
		var fallback: AnimationPlayer = null
		for player in candidates:
			if player.has_animation(full_name):
				if not _effect_player_busy(actor, player, full_name):
					return player
				if fallback == null:
					fallback = player
		return fallback

	#Ł A player that already has this library loaded, then any free one:
	for player in candidates:
		if player.has_animation_library(library_name) and player.get_animation_library(library_name) == library and not _effect_player_busy(actor, player, full_name):
			return player
	for player in candidates:
		if not _effect_player_busy(actor, player, full_name):
			return player

	var new_player := AnimationPlayer.new()
	new_player.root_node = NodePath("..")
	bust_node.add_child(new_player)
	return new_player


#* Whether another effect of the actor is still playing on an AnimationPlayer:
func _effect_player_busy(actor: String, player: AnimationPlayer, full_name: String) -> bool:
	var effects: Dictionary = bust_effect_data.get(actor, {})
	for other_name in effects:
		if other_name == full_name:
			continue
		var other: Dictionary = effects[other_name]
		if other["player"] == player and bool(other["active"]):
			return true
	return false


#* Full name of the effect a line names:
func _find_effect(actor: String, anim_key: String, settings: Dictionary) -> String:
	var key := anim_key.strip_edges()
	var effects: Dictionary = bust_effect_data.get(actor, {})

	#% Known, or "Library/Name" - exact:
	if effects.has(key) or "/" in key:
		return key

	#% Bare name - under the line's "Library":
	var library_ref: Variant = settings.get("Library", "")
	if library_ref is AnimationLibrary:
		var library_name := str(library_ref.resource_path).get_file().get_basename()
		if library_name == "":
			library_name = str(library_ref.resource_name)
		return library_name + "/" + key
	if str(library_ref).strip_edges() != "":
		return str(library_ref).strip_edges().get_file().get_basename() + "/" + key

	#Ł Else the actor's effect of that name:
	for full_name in effects:
		if str(full_name).get_slice("/", 1) == key:
			return full_name
	return key


#* Playback state of a bust (effect "") or effect, or {}:
func _target_state(actor: String, effect: String) -> Dictionary:
	if effect == "":
		return bust_node_data.get(actor, {})
	return bust_effect_data.get(actor, {}).get(effect, {})


#* Forget an actor's effects, stopping any still playing:
func _forget_effects(actor: String) -> void:
	if not bust_effect_data.has(actor):
		return
	for full_name in bust_effect_data[actor]:
		var state: Dictionary = bust_effect_data[actor][full_name]
		_drop_pause(state)
		_drop_pause_loop(state)
		_stop_effect_player(state["player"])
	bust_effect_data.erase(actor)


#* (Re)start an effect's animation:
func _start_effect(state: Dictionary, loop: int) -> void:
	var player: AnimationPlayer = state["player"]
	var full_name: String = str(state["anim"])
	var anim: Animation = state["animation"]

	#@ Step 1 - New generation - older coroutines on this player go stale:
	var gen: int = int(player.get_meta("bust_effect_generation", 0)) + 1
	player.set_meta("bust_effect_generation", gen)
	_reset_state(state, loop, gen)
	_suspended_animplayers.erase(player)

	#@ Step 2 - Restart from the beginning:
	#? play() resumes or ignores a repeat; stop() re-applies the last animation, which may be gone.
	if player.has_animation(player.assigned_animation):
		player.stop()
	player.play(full_name)
	player.seek(0.0, true)

	#% Loops 0 holds on the first frame:
	if loop == 0:
		player.pause()
		return

	var run := func() -> void:
		while true:
			if not await _await_effect_cycle(player, anim, state, gen):
				if int(state["gen"]) == gen:
					state["active"] = false
				return

			state["loops_played"] = int(state["loops_played"]) + 1

			#% Done - hold the final pose or settle on the end frame:
			if int(state["loop_target"]) > 0 and int(state["loops_played"]) >= int(state["loop_target"]):
				if int(state["end_frame"]) == 0:
					_hold_final_pose(player, anim)
					state["active"] = false
				else:
					_end_effect_at(state, anim.length)
				return

			#% Self-looping Animations restart on their own:
			if anim.loop_mode == Animation.LOOP_NONE:
				player.play(full_name)

	run.call()


#* Wait one effect loop; false = let go:
func _await_effect_cycle(player: AnimationPlayer, anim: Animation, state: Dictionary, gen: int) -> bool:
	var looping: bool = anim != null and anim.loop_mode != Animation.LOOP_NONE
	var prev_pos := -1.0
	var prev_dir := 0

	while true:
		await get_tree().process_frame
		if not is_instance_valid(player) or int(player.get_meta("bust_effect_generation", 0)) != gen:
			return false

		#% Taken over:
		if str(player.assigned_animation) != str(state["anim"]):
			return false

		if not player.is_playing():
			#% Paused (VN_Effect_Pause or suspension) - hold, and don't take the resume for a wrap:
			if bool(state["paused"]) or player in _suspended_animplayers:
				prev_pos = -1.0
				prev_dir = 0
				continue
			#% One-shot reached its end, unless a pause loop takes it:
			if _pause_loop_takes_end(state):
				continue
			return not looping

		#% A pause loop moving the position isn't a wrap:
		if _pause_loop_owns_position(state):
			prev_pos = -1.0
			prev_dir = 0
			continue

		if not looping:
			continue

		var pos: float = player.current_animation_position
		if anim.loop_mode == Animation.LOOP_LINEAR:
			if prev_pos >= 0.0 and pos < prev_pos:
				return true
		else:
			#% Ping-pong - a loop ends when playback turns forward again:
			var dir := prev_dir
			if prev_pos >= 0.0:
				if pos > prev_pos:
					dir = 1
				elif pos < prev_pos:
					dir = -1
			if prev_dir == -1 and dir == 1:
				return true
			prev_dir = dir
		prev_pos = pos

	#% Unreachable; the parser needs a return:
	return false


#* Apply an effect's final pose, stopping a self-looping Animation first:
func _hold_final_pose(player: AnimationPlayer, anim: Animation) -> void:
	if not is_instance_valid(player):
		return
	if player.is_playing():
		player.pause()
	player.seek(anim.length, true)


#* Stop an effect AnimationPlayer and release its coroutine:
func _stop_effect_player(player: AnimationPlayer, clear: bool = true) -> void:
	if not is_instance_valid(player):
		return

	#Ł New generation, so attached coroutines exit:
	player.set_meta("bust_effect_generation", int(player.get_meta("bust_effect_generation", 0)) + 1)
	_suspended_animplayers.erase(player)
	#% Clear, else leave the player for the caller to settle:
	if clear:
		CandyPlayback.get_shared().clear_animation(caller, self, player)

	#? No fake animation_finished: nothing waits on it, and game code would see a false completion.


#* Position within the current loop of an effect, in seconds:
func _effect_position(state: Dictionary) -> float:
	var player: AnimationPlayer = state["player"]
	if not is_instance_valid(player) or str(player.assigned_animation) != str(state["anim"]):
		return 0.0
	return float(player.current_animation_position)


#* "f=" frame → seconds, counting the effect's own frames:
func _effect_frame_converter(source: CandyEngine, state: Dictionary, settings: Dictionary) -> Callable:
	#Ł No frames of its own - FPS chain (line → library config.txt → default_effect_fps → engine → properties):
	var fallback_fps := CandyPlayback.get_shared().resolve_fps(source, self, "default_effect_fps", settings.get("FPS", ""),
		default_effect_fps, 0.0, CandyPlayback.get_shared().animation_library_file(source, self, state["player"], str(state["anim"])))
	return func(frame: float) -> float:
		return CandyPlayback.get_shared().animation_frame_to_time(source, self, state["animation"], frame, fallback_fps)


#& Shared Internals:

#* Resolve a skip's "Time" from the current position:
func _seek_target(source: CandyEngine, current_pos: float, time_raw: Variant, frame_to_time: Callable) -> float:
	return CandyPlayback.get_shared().resolve_relative_time(source, self, current_pos, time_raw, true, 0.0, frame_to_time)


#* A line's "FPS", or 0.0 when it gives none:
func _line_fps(settings: Dictionary) -> float:
	var fps_raw: Variant = settings.get("FPS", "")
	if str(fps_raw).strip_edges() == "":
		return 0.0
	return max(float(fps_raw), 0.0)


#* Whether a pause releases a dialogue wait, warning either way:
func _pause_blocks_wait(handle: Variant, context: String, label: String, already_warned: bool) -> bool:
	#% Line count - release the wait:
	if handle != null and int(handle.pause_count) > 0:
		push_warning("%s: wait released - '%s' is paused for %d more line(s), which can't elapse while the dialogue waits." % [context, label, int(handle.pause_count)])
		return true
	if not already_warned:
		push_warning("%s: waiting on '%s', which is paused with no line count - dialogue stays blocked until it is resumed from outside the dialogue." % [context, label])
	return false


#* Whether a bust plays unless suspended (not paused, or pause looping):
func _bust_moves(state: Dictionary) -> bool:
	if not bool(state["paused"]):
		return true
	var pause_loop: Variant = state.get("pause_loop", null)
	return pause_loop is CandyPauseLoop and pause_loop.holds_pause()


#* Pause loop callbacks for a bust (see CandyPauseLoop.start()):
func _bust_pause_loop_media(source: CandyEngine, actor: String, state: Dictionary, settings: Dictionary) -> Dictionary:
	var reason := ""
	if str(state["kind"]) == "static":
		reason = "a still image has nothing to loop"
	var frame_converter := _bust_frame_converter(state, settings)
	return {
		"active": bool(state["active"]),
		"reason": reason,
		"label": actor,
		"position": func() -> float:
			return _bust_position(state),
		"length": func() -> float:
			return _bust_duration(state),
		"time": func(text: String, base: float) -> float:
			return CandyPlayback.get_shared().resolve_relative_time(source, self, base, text, true, 0.0, frame_converter),
		"play_from": func(time: float) -> void:
			_loop_bust_from(state, time),
		"run": func() -> void:
			#% A suspended bust plays on once the suspension ends:
			if not bool(state["suspended"]):
				_proceed_bust(state),
	}


#* Play a bust from a time, for its pause loop:
func _loop_bust_from(state: Dictionary, time: float) -> void:
	var bust_node: Node = state["node"]
	if not is_instance_valid(bust_node):
		return
	#? Suspended - only move, and play on once the suspension ends.
	var held: bool = bool(state["suspended"])

	match str(state["kind"]):
		"folder":
			var stream: CandyFrameStream = state["stream"]
			var index := clampi(int(time * float(state["fps"])), 0, stream.count() - 1)
			state["frame_index"] = index
			stream.show_frame_now(bust_node, index)
			_loop_restart_timer(bust_node, held)
		"sheet":
			bust_node.frame = clampi(int(time * float(state["fps"])), 0, int(state["frame_count"]) - 1)
			_loop_restart_timer(bust_node, held)
		"animated":
			#Ł play() restarts a finished animation, so set the time after:
			if not bust_node.is_playing() and not held:
				bust_node.play(str(state["anim"]))
			_set_animated_time(bust_node, state, time)
		"video":
			if not bust_node.is_playing():
				bust_node.play()
			bust_node.paused = held
			bust_node.stream_position = time


#* Restart a bust's frame Timer for a pause loop, paused if 'held':
func _loop_restart_timer(bust_node: Node, held: bool) -> void:
	var timer := bust_node.get_node_or_null(VN_FRAME_TIMER)
	if timer is Timer:
		timer.start()
		timer.paused = held


#* Pause loop callbacks for an effect (see CandyPauseLoop.start()):
func _effect_pause_loop_media(source: CandyEngine, actor: String, state: Dictionary, settings: Dictionary) -> Dictionary:
	var player: AnimationPlayer = state["player"]
	var frame_converter := _effect_frame_converter(source, state, settings)
	return {
		"active": bool(state["active"]) and is_instance_valid(player),
		"label": actor + "/" + str(state["anim"]),
		"position": func() -> float:
			return _effect_position(state),
		"length": func() -> float:
			return float(state["duration"]),
		"time": func(text: String, base: float) -> float:
			return CandyPlayback.get_shared().resolve_relative_time(source, self, base, text, true, 0.0, frame_converter),
		"play_from": func(time: float) -> void:
			if not is_instance_valid(player):
				return
			#% Stays put while suspended; once finished, play() starts it over:
			if not player.is_playing() and not (player in _suspended_animplayers):
				player.play(str(state["anim"]))
			player.seek(time, true),
		"run": func() -> void:
			if is_instance_valid(player) and not player.is_playing() and not (player in _suspended_animplayers):
				player.play(),
	}


#* Whether a pause loop decides the position (see CandyPauseLoop.owns_position()):
func _pause_loop_owns_position(state: Dictionary) -> bool:
	var pause_loop: Variant = state.get("pause_loop", null)
	return pause_loop is CandyPauseLoop and pause_loop.owns_position()


#* Whether a pause loop takes over the end just reached (see CandyPauseLoop.media_ended()):
func _pause_loop_takes_end(state: Dictionary) -> bool:
	var pause_loop: Variant = state.get("pause_loop", null)
	return pause_loop is CandyPauseLoop and pause_loop.media_ended()


#* End a pause loop for good, restoring the volume:
func _drop_pause_loop(state: Dictionary) -> void:
	var pause_loop: Variant = state.get("pause_loop", null)
	if pause_loop is CandyPauseLoop:
		pause_loop.cancel()
	state["pause_loop"] = null


#* Cancel and remove a state's "Lines" pause handle, if it has one:
func _drop_pause(state: Dictionary) -> void:
	var handle = state.get("pause_handle", null)
	if handle != null:
		handle.pause_count = 0
	state["pause_handle"] = null


#* Follow the line's "Duration" for a bust (effect "") or effect:
func _follow_duration(state: Dictionary, effect: String) -> void:
	_drop_play_duration(state)
	state["play_duration"] = CandyPlayDuration.start(self, int(state.get("duration_loop", 0)),
		float(state.get("duration_seconds", 0.0)), _play_duration_media(state, effect))


#* Duration callbacks for a bust (effect "") or effect (see CandyPlayDuration.start()):
func _play_duration_media(state: Dictionary, effect: String) -> Dictionary:
	#? Lets go once a newer generation replaces the playback.
	var gen: int = int(state["gen"])

	if effect == "":
		return {
			"position": func() -> float:
				return _bust_position(state),
			"length": func() -> float:
				return _bust_duration(state),
			"loops": func() -> int:
				return int(state["loops_played"]),
			"set_loops": func(count: int) -> void:
				state["loop_target"] = count,
			"end": func(time: float) -> void:
				_end_bust_at(state, time),
			"active": func() -> bool:
				return bool(state["active"]) and _is_current(state["node"], gen),
			"held": func() -> bool:
				return _pause_loop_owns_position(state),
		}

	return {
		"position": func() -> float:
			return _effect_position(state),
		"length": func() -> float:
			return float(state["duration"]),
		"loops": func() -> int:
			return int(state["loops_played"]),
		"set_loops": func(count: int) -> void:
			state["loop_target"] = count,
		"end": func(time: float) -> void:
			_end_effect_at(state, time),
		"active": func() -> bool:
			var player: AnimationPlayer = state["player"]
			return bool(state["active"]) and is_instance_valid(player) and int(player.get_meta("bust_effect_generation", 0)) == gen,
		"held": func() -> bool:
			return _pause_loop_owns_position(state),
	}


#* End a bust's playback at 'time' in its current loop:
func _end_bust_at(state: Dictionary, time: float) -> void:
	_drop_pause_loop(state)
	_invalidate_bust(state["node"])
	#Ł Stay on that frame, or go to the end frame:
	if int(state["end_frame"]) == 0:
		_seek_bust(state, time)
	else:
		_settle_bust(state["node"], state, int(state["end_frame"]))
	state["active"] = false


#* End an effect at 'time' in its current loop:
func _end_effect_at(state: Dictionary, time: float) -> void:
	var player: AnimationPlayer = state["player"]
	_drop_pause_loop(state)
	state["active"] = false
	if not is_instance_valid(player):
		return

	var stop_frame := int(state["end_frame"])
	#% "Clear" plays "RESET":
	if stop_frame == CandyPlayback.STOP_FRAME_CLEAR:
		_stop_effect_player(player)
		return

	#Ł New generation, so the loop-counting coroutine exits:
	player.set_meta("bust_effect_generation", int(player.get_meta("bust_effect_generation", 0)) + 1)
	_suspended_animplayers.erase(player)
	#Ł Hold the pose there, or end on the end frame:
	if stop_frame == 0 or not (state["end_converter"] as Callable).is_valid():
		CandyPlayback.get_shared().settle_animation_at(caller, self, player, time)
	else:
		CandyPlayback.get_shared().settle_animation(caller, self, player, stop_frame, state["end_converter"])


#* Stop following a state's Duration:
func _drop_play_duration(state: Dictionary) -> void:
	var play_duration: Variant = state.get("play_duration", null)
	if play_duration is CandyPlayDuration:
		play_duration.cancel()
	state["play_duration"] = null


#* Scale Sprite2D or Sprite3D busts to match target dimensions:
func _scale_bust_to_size(bust_node: Node, bust_ref: String) -> void:
	if not bust_sizes.has(bust_ref):
		return

	var target_size: Array = bust_sizes[bust_ref]
	if target_size.size() < 2:
		return

	var target_h = float(target_size[0])
	var target_w = float(target_size[1])

	#Ł Determine texture size:
	if bust_node is Sprite2D or bust_node is Sprite3D:
		var tex: Texture2D = bust_node.texture
		if tex == null:
			return
		var tex_size = tex.get_size() / Vector2(max(bust_node.hframes, 1), max(bust_node.vframes, 1))
		if tex_size.x == 0 or tex_size.y == 0:
			return

		#Ł Calculate scale ratio:
		var scale_x = target_w / tex_size.x
		var scale_y = target_h / tex_size.y
		if bust_node is Sprite3D:
			bust_node.scale = Vector3(scale_x, scale_y, 1.0)
		else:
			bust_node.scale = Vector2(scale_x, scale_y)


#* Use the resource an expression already loaded, or load the resolved file:
func _resolved_texture(resolved: Dictionary) -> Texture2D:
	if resolved["resource"] is Texture2D:
		return resolved["resource"]
	return CandyMedia.load_texture(str(resolved["path"]))


func _resolved_sprite_frames(resolved: Dictionary) -> SpriteFrames:
	if resolved["resource"] is SpriteFrames:
		return resolved["resource"]
	return CandyMedia.load_sprite_frames(str(resolved["path"]))


func _resolved_video(resolved: Dictionary) -> VideoStream:
	if resolved["resource"] is VideoStream:
		return resolved["resource"]
	return CandyMedia.load_video(str(resolved["path"]))


#* Hook - before a bust or effect starts playback (VN_Play, VN_Effect_Play, or a _Resume on a held one):
@warning_ignore("unused_parameter")
func x_playback_starting(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook - once a bust or effect has started playback:
@warning_ignore("unused_parameter")
func x_playback_started(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass
