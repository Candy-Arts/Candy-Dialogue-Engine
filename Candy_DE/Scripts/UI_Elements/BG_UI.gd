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


## REQUIRED: The parent of the background Layers.
@export var bg_container: Node

#^ File extensions, one per kind of node:
#? UI element level of each extension chain. Empty = inherit the engine's.
## Extension given to files named without one, on TextureRect, NinePatchRect and TextureButton layers.[br][br]
## Leave empty to inherit the engine's [code]default_image_extension[/code].
@export var default_image_extension: String = ""
## Extension given to spritesheet files named without one, on Sprite2D and Sprite3D layers.[br][br]
## Leave empty to inherit the engine's [code]default_sprite_extension[/code].
@export var default_sprite_extension: String = ""
## Extension given to SpriteFrames files named without one, on AnimatedSprite2D and
## AnimatedSprite3D layers.[br][br]
## Leave empty to inherit the engine's [code]default_animated_sprite_extension[/code].
@export var default_animated_sprite_extension: String = ""
## Extension given to video files named without one, on VideoStreamPlayer layers.[br][br]
## Leave empty to inherit the engine's [code]default_video_extension[/code].
@export var default_video_extension: String = ""
## Default file extension for AnimationLibrary files named without one.
@export var default_effect_extension = ".tres"

#^ Frame rates, one per kind of media:
#? UI element level of each FPS chain. 0 = inherit the engine's.
## Frame rate for frame-folder animations on TextureRect and NinePatchRect layers.[br][br]
## Leave at 0 to inherit the engine's [code]default_animated_image_fps[/code].[br]
## A "config.txt" in the animation's own folder overrides this, and the "FPS" key on the
## dialogue line overrides both.
@export var default_animated_image_fps: float = 0.0
## Frame rate for spritesheets on Sprite2D and Sprite3D layers.[br][br]
## Leave at 0 to inherit the engine's [code]default_sprite_fps[/code]. The "FPS" key on the
## dialogue line overrides this.
@export var default_sprite_fps: float = 0.0
## Frame rate for SpriteFrames animations saved with no speed of their own, on
## AnimatedSprite2D and AnimatedSprite3D layers.[br][br]
## Leave at 0 to inherit the engine's [code]default_animated_sprite_fps[/code]. The "FPS" key
## on the dialogue line overrides this; a speed saved in the SpriteFrames overrides both.
@export var default_animated_sprite_fps: float = 0.0
## Frame rate "f=" targets count at on VideoStreamPlayer layers whose video's own frame rate
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
## Memory budget of one animation folder on TextureRect and NinePatchRect layers, in MB: one
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
@export var bg_sizes = {
	"1": [1080, 1024],
	"2": [1080, 1024],
	"3": [1080, 1024],
}

#^ Z Index:
## Default Z-order.
@export var default_z = 25

#^ Access:
@export_group("Access")
## [b]Private[/b]: only the engine that owns this scene can command it - the engine whose
## ui_elements_paths lists it as owned.[br]
## [b]Public[/b]: any engine can, as Public Mode allows.[br][br]
## The Unrestricted Commands are accepted from any engine either way.
@export_enum("Private", "Public") var access: int = 0
## Public scenes only. While an engine holds this scene (it started what the scene shows):[br]
## [b]Exclusive[/b]: other engines' commands are rejected.[br]
## [b]Semi-Exclusive[/b]: other engines may only send the Semi-Exclusive Commands.[br]
## [b]Free[/b]: other engines may send any command, and one that takes hold takes the scene over.[br][br]
## A hold covers the whole scene, every layer included.
@export_enum("Exclusive", "Semi-Exclusive", "Free") var public_mode: int = 0
## Commands other engines may still send to this scene while it is Semi-Exclusive and held.
@export var semi_exclusive_commands: Array[String] = ["BG_Pause", "BG_Resume", "BG_Stop", "BG_Skip",
	"BG_Effect_Pause", "BG_Effect_Resume", "BG_Effect_Stop", "BG_Effect_Skip"]
## Commands that make the engine sending them hold this scene, when it is Public.[br]
## A line's "Take_Hold" key overrides this: 1 takes hold anyway, -1 never does.
@export var hold_commands: Array[String] = ["BG_Play", "BG_Effect_Play"]
## Commands accepted from any engine, whether this scene is Private or Public, held or not:
## they don't act on the scene itself, only on the engine's own dialogue.
@export var unrestricted_commands: Array[String] = ["BG_Wait", "BG_Effect_Wait"]

#^ Held scene overrides (override engine settings):
@export_group("Held Scene Overrides")
## Let this scene override whether the engine holding it suspends it with its dialogue.[br]
## Overrides the engine's setting and Candy_Properties.gd. A Private scene is always
## suspended by its owner, so this only matters when it is Public.
@export var enable_suspend_held_media: bool = false
## Whether the engine holding this scene suspends it along with its dialogue.
@export var suspend_held_media: bool = true
## Let this scene override whether the engine holding it applies its end-of-dialogue
## treatment to it (persistent_bg_on_end).[br]
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

#^ Layer playback, by layer name:
#? Used by the functions to store relevant data about each layer. See _new_layer_state().
var bg_layer_data = {}

#^ Effect playback, by layer, then full animation name:
#? See play_effect().
var bg_effect_data = {}

#^ Whether a suspension paused this scene:
var _suspended: bool = false
#^ AnimationPlayers the suspension paused:
var _suspended_animplayers: Array = []

#^ Frame Timer name:
const BG_FRAME_TIMER: String = "BGAnimTimer"


#^ A layer's or effect's "Lines" pause, counted down by the engine that issued it:
#? Same counters as a media player's (CandyPlayback.set_pause()).
class BGPauseHandle extends RefCounted:
	var pause_count: int = 0
	var pause_mode: String = "speech"
	var pause_engine: Node = null
	var element: Node = null
	var layer: String = ""
	var effect: String = ""		#/ "" = the layer's own playback

	#* Called when the line count runs out:
	func unpause() -> void:
		pause_count = 0
		if element != null and is_instance_valid(element):
			element.unpause_target(layer, effect)



func _ready():
	self.z_index = default_z


#& Access:
#? Same Private / Public model as media players. A hold covers the whole scene.

#* Accept or reject an engine's command, taking hold if it does:
func admit_command(engine: Node, command: String, take_hold: int = 0) -> String:
	var command_key := command.to_lower()		#/ Script file name, any case

	#@ Step 1 - Unrestricted commands:
	if _lists_command(unrestricted_commands, command_key):
		return ""

	#@ Step 2 - Private, owner only:
	if access == 0:
		if owner_engine == null or not is_instance_valid(owner_engine):
			return "it is Private and no engine owns it. Set its Access to Public, or list it as owned in an engine's ui_elements_paths"
		if engine != owner_engine:
			return "it is Private to " + str(owner_engine.name)
		caller = engine
		return ""		#/ Accepted

	#@ Step 3 - Public, another engine's hold:
	if holder != null and is_instance_valid(holder) and holder != engine:
		if public_mode == 0:
			return "it is Exclusive and held by " + str(holder.name)
		if public_mode == 1 and not _lists_command(semi_exclusive_commands, command_key):
			return "it is Semi-Exclusive and held by " + str(holder.name) + ", which only lets other engines send " + ", ".join(semi_exclusive_commands)

	caller = engine

	#@ Step 4 - Take hold:
	if take_hold == 1 or (take_hold == 0 and _lists_command(hold_commands, command_key)):
		_take_hold(engine)

	return ""		#/ Accepted


#* Take hold for 'engine', releasing the previous holder:
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
	if not source.suspend_backgrounds or _suspended:
		return

	_suspended = true

	#% Only what is playing, so unsuspend_media() never lifts a BG_Pause:
	if source.suspend_bg_animations:
		for layer in bg_layer_data:
			var state: Dictionary = bg_layer_data[layer]
			if bool(state["active"]) and _layer_moves(state):
				_halt_layer(state)
				state["suspended"] = true

	_suspended_animplayers.clear()
	if source.suspend_bg_effects:
		for player in _find_animation_players(self):
			if player.is_playing():
				player.pause()
				_suspended_animplayers.append(player)


#* Resume after a dialogue suspension:
@warning_ignore("unused_parameter")
func unsuspend_media(candy_args: Dictionary) -> void:
	if not _suspended:
		return

	_suspended = false

	for layer in bg_layer_data:
		var state: Dictionary = bg_layer_data[layer]
		if bool(state["suspended"]):
			state["suspended"] = false
			if _layer_moves(state):
				_proceed_layer(state)

	for player in _suspended_animplayers:
		if is_instance_valid(player):
			player.play()
	_suspended_animplayers.clear()


#* End-of-dialogue treatment:
func end_media(candy_args: Dictionary) -> void:
	var source: CandyEngine = candy_args["caller"]
	if source.persistent_bg_on_end:
		return

	visible = false
	clear_layers()


#* Find all AnimationPlayers under a node:
func _find_animation_players(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		if child is AnimationPlayer:
			result.append(child)
		result.append_array(_find_animation_players(child))
	return result


#& Layer Display Logic:
#? Called by the BG_ commands, one layer at a time.
#? candy_args: "caller", "command", "key" (layer name, also its background_folder sub-folder).
#? settings: the line's layer keys, resolved through CandyRef.

#* Show and play a file on a layer (BG_Play):
func play_layer(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> bool:
	var source: CandyEngine	= candy_args["caller"]
	var layer: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "BG_Play"))
	var file_ref: Variant	= settings.get("File", "")
	var loop: int			= CandyPlayback.get_shared().normalize_loop(source, self, settings.get("Loops", "1"))

	self.visible = true		#/ In case it was hidden

	#@ Step 1 - Layer node:
	var bg_node := _layer_node(layer, context)
	if bg_node == null:
		return false

	#@ Step 2 - Default extension by node type:
	var default_ext := ""
	var frames_subfolder := ""
	if bg_node is TextureRect or bg_node is NinePatchRect or bg_node is TextureButton:
		default_ext = CandyPlayback.get_shared().resolve_extension(source, self, "default_image_extension", default_image_extension)
	elif bg_node is Sprite2D or bg_node is Sprite3D:
		default_ext = CandyPlayback.get_shared().resolve_extension(source, self, "default_sprite_extension", default_sprite_extension)
	elif bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
		default_ext = CandyPlayback.get_shared().resolve_extension(source, self, "default_animated_sprite_extension", default_animated_sprite_extension)
		frames_subfolder = "Sprite_Frames"
	elif bg_node is VideoStreamPlayer:
		default_ext = CandyPlayback.get_shared().resolve_extension(source, self, "default_video_extension", default_video_extension)
	else:
		printerr(context, ": unsupported layer node type → ", layer, " (", bg_node.get_class(), ")")
		return false

	#@ Step 3 - Resolve the reference:
	var resolved := CandyMedia.resolve_media(file_ref, candy_de.background_folder.path_join(layer), default_ext, frames_subfolder)
	if not bool(resolved["found"]):
		printerr(context, ": missing file → ", resolved["path"])
		return false

	var file_path: String = str(resolved["path"])

	#@ Step 4 - Stop what the layer was playing:
	_invalidate_layer(bg_node)
	var state := _new_layer_state(layer, bg_node, loop)

	#@ Step 5 - Set up by node type:
	#¦ 1. TextureRect / NinePatchRect / TextureButton - frame folder:
	if (bg_node is TextureRect or bg_node is NinePatchRect or bg_node is TextureButton) and bool(resolved["is_folder"]):
		#Ł Frames load as it plays (CandyFrameStream):
		#? A TextureButton's state folders play along.
		var stream := CandyFrameStream.open(source, self, file_path, animation_folder_cache, animation_folder_stream, bg_node)
		if stream.count() == 0 or stream.frame_now(0) == null:
			printerr(context, ": no frames found in → ", file_path)
			return false

		#Ł FPS (properties → engine → default_animated_image_fps → media folder config.txt → animation's config.txt → line):
		var anim_fps: float = CandyPlayback.get_shared().resolve_fps(source, self, "default_animated_image_fps", settings.get("FPS", ""),
			default_animated_image_fps, CandyMedia.read_config_fps(file_path), file_path)

		state["kind"] = "folder"
		state["stream"] = stream
		state["fps"] = anim_fps
		state["frame_count"] = stream.count()
		state["duration"] = float(stream.count()) / anim_fps
		state["start"] = func(start_loop: int) -> void:
			_start_folder(layer, start_loop)

		#Ł Drop previous extra slots:
		if bg_node is TextureButton:
			_clear_button_slots(bg_node)
		stream.show_frame_now(bg_node, 0)
		bg_node.visible = true

	#¦ 2. TextureRect / NinePatchRect - static image:
	elif bg_node is TextureRect or bg_node is NinePatchRect:
		var tex := _resolved_texture(resolved)
		if not (tex is Texture2D):
			printerr(context, ": invalid texture → ", file_path)
			return false
		bg_node.texture = tex
		bg_node.visible = true
		return false		#/ Nothing to play

	#¦ 3. TextureButton - static image, with its Button_Textures:
	elif bg_node is TextureButton:
		var tex := _resolved_texture(resolved)
		if not (tex is Texture2D):
			printerr(context, ": invalid texture → ", file_path)
			return false

		#Ł Drop previous extra slots:
		_clear_button_slots(bg_node)
		bg_node.texture_normal = tex
		bg_node.visible = true

		#Ł Button_Textures subfolder beside the file:
		var file_base = file_path.get_file().get_basename()
		var subfolder_name = file_base + "_" + file_path.get_extension().to_lower()
		var button_folder = file_path.get_base_dir().path_join("Button_Textures").path_join(subfolder_name)
		if DirAccess.dir_exists_absolute(button_folder):
			CandyUI.get_shared().apply_button_textures(source, self, bg_node, button_folder, file_base)

		return false		#/ Nothing to play

	#¦ 4. Sprite2D / Sprite3D - an image or a spritesheet:
	elif bg_node is Sprite2D or bg_node is Sprite3D:
		var tex := _resolved_texture(resolved)
		if not (tex is Texture2D):
			printerr(context, ": invalid texture → ", file_path)
			return false

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

		bg_node.texture = tex
		bg_node.hframes = hframes
		bg_node.vframes = vframes
		bg_node.frame = 0
		bg_node.visible = true
		_scale_bg_to_size(bg_node, layer)

		var sheet_fps: float = CandyPlayback.get_shared().resolve_fps(source, self, "default_sprite_fps", settings.get("FPS", ""),
			default_sprite_fps, 0.0, file_path)

		state["kind"] = "sheet"
		state["fps"] = sheet_fps
		state["frame_count"] = max(hframes * vframes - missing, 1)
		state["duration"] = float(state["frame_count"]) / sheet_fps

		#% A single frame has nothing to play:
		if int(state["frame_count"]) <= 1:
			return false

		state["start"] = func(start_loop: int) -> void:
			_start_sheet(layer, start_loop)

	#¦ 5. AnimatedSprite2D / AnimatedSprite3D - a SpriteFrames resource:
	elif bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
		var frames := _resolved_sprite_frames(resolved)
		if frames == null:
			printerr(context, ": invalid SpriteFrames resource → ", file_path)
			return false

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
			return false

		#Ł FPS chain only fills in a missing speed:
		frames = CandyPlayback.get_shared().sprite_frames_with_speed(source, self, frames, anim, settings.get("FPS", ""),
			default_animated_sprite_fps, file_path)
		var speed: float = frames.get_animation_speed(anim)

		bg_node.sprite_frames = frames
		bg_node.animation = anim
		bg_node.frame = 0
		bg_node.visible = true

		var duration := 0.0
		for i in frames.get_frame_count(anim):
			duration += frames.get_frame_duration(anim, i) / speed

		state["kind"] = "animated"
		state["anim"] = anim
		state["fps"] = speed
		state["frame_count"] = frames.get_frame_count(anim)
		state["duration"] = duration
		state["start"] = func(start_loop: int) -> void:
			_start_animated(layer, start_loop)

	#¦ 6. VideoStreamPlayer - a video:
	elif bg_node is VideoStreamPlayer:
		var stream := _resolved_video(resolved)
		if stream == null:
			printerr(context, ": invalid video stream → ", file_path)
			return false

		bg_node.stream = stream
		bg_node.visible = true

		#Ł Video's own frame rate, for "f=" targets:
		state["kind"] = "video"
		state["fps"] = CandyPlayback.get_shared().resolve_fps(source, self, "default_video_fps", settings.get("FPS", ""),
			default_video_fps, CandyPlayback.get_shared().video_fps(source, self, stream), file_path)
		state["start"] = func(start_loop: int) -> void:
			await _start_video(layer, start_loop)

	#@ Step 6 - Start playback:
	var duration_seconds := CandyPlayDuration.read(source, self, settings.get("Duration", "null"), true, 0.0,
		_layer_frame_converter(state, settings))
	state["end_frame"] = CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""), 0, context, false)
	await _begin(source, layer, "", state, loop, custom_data, duration_seconds)
	return true		#/ Playback started


#* Block until a layer reaches a loop count and/or a time:
@warning_ignore("unused_parameter")
func wait_layer(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> String:
	var source: CandyEngine	= candy_args["caller"]
	var layer: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "BG_Wait"))

	var state: Dictionary = bg_layer_data.get(layer, {})
	if state.is_empty() or not bool(state["active"]):
		return "Continue"

	var wait: int = int(settings.get("Wait_Loops", "0"))
	var target_time := CandyPlayback.get_shared().resolve_time_target(source, self, settings.get("Wait_Time", ""), true, 0.0,
		_layer_frame_converter(state, settings))
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
		if not is_same(bg_layer_data.get(layer, {}), state) or not bool(state["active"]):
			break

		#% Paused by BG_Pause:
		if bool(state["paused"]):
			if _pause_blocks_wait(state["pause_handle"], context, layer, warned_open_pause):
				break
			warned_open_pause = true
			await get_tree().process_frame
			continue

		#% Reached Wait_Loops × length + Wait_Time:
		var duration := _layer_duration(state)
		var elapsed: float = int(state["loops_played"]) * duration + _layer_position(state)
		if elapsed >= max(wait, 0) * duration + target_time:
			break

		await get_tree().process_frame

	return "Continue"


#* Pause a layer (BG_Pause):
@warning_ignore("unused_parameter")
func pause_layer(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> Tween:
	var source: CandyEngine	= candy_args["caller"]
	var layer: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "BG_Pause"))

	var state: Dictionary = bg_layer_data.get(layer, {})
	if state.is_empty() or not bool(state["active"]):
		printerr(context, ": nothing is playing on layer → ", layer)
		return null

	#% Videos - the loop lowers volume_db:
	var volume_property: Variant = null
	if str(state["kind"]) == "video":
		volume_property = ""
	var pause_loop := CandyPauseLoop.start(source, self, state["node"], settings, _layer_pause_loop_media(source, state, settings),
		context, state.get("pause_loop", null) as CandyPauseLoop, volume_property)
	state["pause_loop"] = pause_loop

	#% A suspension-halted layer stays halted, now by the pause, unless a pause loop plays:
	if pause_loop == null:
		if not bool(state["suspended"]):
			_halt_layer(state)
		state["suspended"] = false
	state["paused"] = true

	_drop_pause(state)
	var handle := BGPauseHandle.new()
	handle.element = self
	handle.layer = layer
	state["pause_handle"] = handle
	CandyPlayback.get_shared().set_pause(source, self, handle, int(settings.get("Lines", -1)), int(settings.get("All", 0)))

	if pause_loop != null:
		return pause_loop.pause_fade		#/ The fade a "!" Pause_Volume_Time waits on
	return null


#* Resume a layer (BG_Resume):
@warning_ignore("unused_parameter")
func resume_layer(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> Tween:
	var source: CandyEngine	= candy_args["caller"]
	var layer: String		= str(candy_args["key"])

	var state: Dictionary = bg_layer_data.get(layer, {})
	if state.is_empty():
		printerr(str(candy_args.get("command", "BG_Resume")), ": nothing was played on layer → ", layer)
		return null

	#Ł Start a held playback:
	if int(state["loop_target"]) == 0 and (state["start"] as Callable).is_valid():
		await _begin(source, layer, "", state, 1, custom_data)
		return null

	return unpause_target(layer, "", settings, source)		#/ The fade a "!" Resume_Volume_Time waits on, or null


#* Stop a layer, keeping it on screen (BG_Stop):
@warning_ignore("unused_parameter")
func stop_layer(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine	= candy_args["caller"]
	var layer: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "BG_Stop"))
	var stop_frame: int		= CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""), 0, context, false)

	var bg_node := _layer_node(layer, context)
	if bg_node == null:
		return

	var state: Dictionary = bg_layer_data.get(layer, {})

	#@ Step 1 - "Loops" or "Duration" schedules the stop:
	if not state.is_empty() and bool(state["active"]):
		var loop := CandyPlayDuration.read_stop_loop(settings.get("Loops", ""), context)
		var duration_seconds := CandyPlayDuration.read(source, self, settings.get("Duration", ""), true, 0.0,
			_layer_frame_converter(state, settings))
		if CandyPlayDuration.schedules(loop, duration_seconds):
			state["end_frame"] = stop_frame
			_drop_play_duration(state)
			state["play_duration"] = CandyPlayDuration.schedule_stop(self, loop, duration_seconds, _play_duration_media(state, ""))
			return

	#@ Step 2 - Stop what drives the layer:
	_invalidate_layer(bg_node)
	if not state.is_empty():
		_drop_pause(state)
		_drop_pause_loop(state)
		state["active"] = false
		state["paused"] = false
		state["suspended"] = false

	#@ Step 3 - Go to the stop frame:
	_settle_layer(bg_node, state, stop_frame)
	bg_node.visible = true


#* Set a stopped layer's frame:
#? 'stop_frame': as BG_Stop's. 'state': {} if none.
func _settle_layer(bg_node: Node, state: Dictionary, stop_frame: int) -> void:
	if stop_frame == 0:
		return

	if bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
		var sf: SpriteFrames = bg_node.sprite_frames
		if sf != null and sf.has_animation(bg_node.animation):
			var total: int = sf.get_frame_count(bg_node.animation)
			if stop_frame == -1:
				bg_node.frame = total - 1
			else:
				bg_node.frame = clampi(stop_frame - 1, 0, total - 1)

	elif bg_node is Sprite2D or bg_node is Sprite3D:
		if bg_node.texture != null:
			var total := CandyMedia.sheet_frame_count(bg_node)
			if not state.is_empty() and int(state["frame_count"]) > 0:
				total = int(state["frame_count"])
			if stop_frame == -1:
				bg_node.frame = total - 1
			else:
				bg_node.frame = clampi(stop_frame - 1, 0, total - 1)

	elif bg_node is TextureRect or bg_node is NinePatchRect or bg_node is TextureButton:
		if not state.is_empty() and str(state["kind"]) == "folder":
			var stream: CandyFrameStream = state["stream"]
			var index := 0
			if stop_frame == -1:
				index = stream.count() - 1
			else:
				index = clampi(stop_frame - 1, 0, stream.count() - 1)
			state["frame_index"] = index
			stream.show_frame_now(bg_node, index)

	elif bg_node is VideoStreamPlayer:
		#Ł Pause to hold the frame (stop() blanks it):
		#? No last frame (-1): seeking there is unreliable.
		if stop_frame > 0 and not state.is_empty() and float(state["fps"]) > 0.0:
			#Ł A finished video plays again to show a frame:
			if not bg_node.is_playing():
				bg_node.play()
			bg_node.paused = true
			bg_node.stream_position = float(stop_frame - 1) / float(state["fps"])


#* Move a layer within its current loop (BG_Skip):
@warning_ignore("unused_parameter")
func skip_layer(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine	= candy_args["caller"]
	var layer: String		= str(candy_args["key"])

	var state: Dictionary = bg_layer_data.get(layer, {})
	if state.is_empty() or not (state["start"] as Callable).is_valid():
		printerr(str(candy_args.get("command", "BG_Skip")), ": nothing to skip through on layer → ", layer)
		return

	var duration := _layer_duration(state)

	#% During a pause loop, move the resume point:
	if _pause_loop_owns_position(state):
		state["pause_loop"].move_pause_point(settings.get("Time", 0.0))
		return

	#@ Step 1 - Target position:
	var target := _seek_target(source, _layer_position(state), settings.get("Time", 0.0), _layer_frame_converter(state, settings))
	target = clampf(target, 0.0, duration)

	#@ Step 2 - Move there:
	_move_layer(state, target)


#* Move a layer to 'target' within its loop:
func _move_layer(state: Dictionary, target: float) -> void:
	var bg_node: Node = state["node"]
	if not is_instance_valid(bg_node):
		return

	#? Paused or held playback moves without starting.
	match str(state["kind"]):
		"folder":
			var stream: CandyFrameStream = state["stream"]
			var index := clampi(int(target * float(state["fps"])), 0, stream.count() - 1)
			state["frame_index"] = index
			stream.show_frame_now(bg_node, index)
			_restart_frame_timer(bg_node)
		"sheet":
			bg_node.frame = clampi(int(target * float(state["fps"])), 0, int(state["frame_count"]) - 1)
			_restart_frame_timer(bg_node)
		"animated":
			_set_animated_time(bg_node, state, target)
		"video":
			bg_node.stream_position = target


#* Flip a layer (BG_Mirror):
@warning_ignore("unused_parameter")
func mirror_layer(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var layer: String	= str(candy_args["key"])
	var axis: String	= str(settings.get("Axis", "Reset")).strip_edges().to_lower()

	var bg_node := _layer_node(layer, str(candy_args.get("command", "BG_Mirror")))
	if bg_node == null:
		return

	if not ("flip_h" in bg_node):
		printerr(str(candy_args.get("command", "BG_Mirror")), ": this layer's node type can't be flipped → ", layer, " (", bg_node.get_class(), ")")
		return

	if axis == "h flip" or axis == "both":
		bg_node.flip_h = not bg_node.flip_h
	if axis == "v flip" or axis == "both":
		bg_node.flip_v = not bg_node.flip_v
	if axis == "reset":		#/ Nodes always have both flip_h and flip_v
		bg_node.flip_h = false
		bg_node.flip_v = false


#* Clear a layer and its effects (BG_Remove):
@warning_ignore("unused_parameter")
func remove_layer(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var layer: String = str(candy_args["key"])
	if _layer_node(layer, str(candy_args.get("command", "BG_Remove"))) == null:
		return
	_clear_layer(layer)


#* Clear every layer (UI_Clear, dialogue end):
@warning_ignore("unused_parameter")
func clear_layers(custom_data: Array = []) -> void:
	if bg_container == null:
		return
	for child in bg_container.get_children():
		_clear_layer(str(child.name))


#* Clear one layer - stop it, remove its visuals and state:
func _clear_layer(layer: String) -> void:
	var bg_node: Node = bg_container.get_node_or_null(layer)
	if bg_node == null:
		return

	#@ Step 1 - Stop the layer and its effects:
	_invalidate_layer(bg_node)
	if bg_layer_data.has(layer):
		_drop_pause(bg_layer_data[layer])
		_drop_pause_loop(bg_layer_data[layer])
		bg_layer_data.erase(layer)

	if bg_effect_data.has(layer):
		for full_name in bg_effect_data[layer]:
			_drop_pause(bg_effect_data[layer][full_name])
			_drop_pause_loop(bg_effect_data[layer][full_name])
		bg_effect_data.erase(layer)
	for child in bg_node.get_children():
		if child is AnimationPlayer:
			_stop_effect_player(child)

	#@ Step 2 - Clear visuals by node type:
	if bg_node is TextureRect or bg_node is NinePatchRect:
		bg_node.texture = null

	elif bg_node is TextureButton:
		bg_node.texture_normal = null
		bg_node.texture_pressed = null
		bg_node.texture_hover = null
		bg_node.texture_disabled = null
		bg_node.texture_focused = null
		bg_node.texture_click_mask = null

	elif bg_node is Sprite2D or bg_node is Sprite3D:
		bg_node.texture = null
		bg_node.hframes = 1
		bg_node.vframes = 1
		bg_node.frame = 0
		if bg_node is Sprite3D:
			bg_node.scale = Vector3.ONE
		else:
			bg_node.scale = Vector2.ONE

	elif bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
		bg_node.sprite_frames = null
		bg_node.frame = 0

	elif bg_node is VideoStreamPlayer:
		bg_node.stop()
		bg_node.paused = false
		bg_node.stream = null
		bg_node.stream_position = 0.0

	#@ Step 3 - Reset flips (2D only):
	if "flip_h" in bg_node:
		bg_node.flip_h = false
		bg_node.flip_v = false


#* Lift a layer's (effect "") or effect's pause:
#? 'settings': the _Resume entry ({} = the pause's own). 'source': resuming engine (null = the pausing one).
func unpause_target(layer: String, effect: String, settings: Dictionary = {}, source: CandyEngine = null) -> Tween:
	var state := _target_state(layer, effect)
	if state.is_empty():
		return null

	_drop_pause(state)
	if not bool(state["paused"]):
		return null

	var fade: Tween = null
	var pause_loop: Variant = state.get("pause_loop", null)
	if pause_loop is CandyPauseLoop:
		fade = pause_loop.resume(source, settings)
	state["paused"] = false

	if effect == "":
		#% Stays halted while suspended:
		if _suspended:
			state["suspended"] = true
		else:
			_proceed_layer(state)
		return fade		#/ The fade a "!" Resume_Volume_Time waits on, or null

	var player: AnimationPlayer = state["player"]
	if not is_instance_valid(player):
		return fade
	#% Stays halted while suspended:
	if _suspended:
		if not (player in _suspended_animplayers):
			_suspended_animplayers.append(player)
	else:
		player.play()
	return fade		#/ The fade a "!" Resume_Volume_Time waits on, or null


#& Layer Playback Internals:

#* Empty a TextureButton's state textures:
func _clear_button_slots(bg_node: TextureButton) -> void:
	bg_node.texture_pressed = null
	bg_node.texture_hover = null
	bg_node.texture_disabled = null
	bg_node.texture_focused = null
	bg_node.texture_click_mask = null


#* Layer node, or null after reporting:
func _layer_node(layer: String, context: String) -> Node:
	if bg_container == null:
		printerr(context, ": the background scene has no bg_container.")
		return null
	var bg_node: Node = bg_container.get_node_or_null(layer)
	if bg_node == null:
		printerr(context, ": layer not found → ", layer)
	return bg_node


#* Create a layer's playback state, replacing any earlier one:
func _new_layer_state(layer: String, bg_node: Node, loop: int) -> Dictionary:
	if bg_layer_data.has(layer):
		_drop_pause(bg_layer_data[layer])
		_drop_pause_loop(bg_layer_data[layer])

	var state: Dictionary = {
		"kind": "static",			#/ "static", "folder", "sheet", "animated" (SpriteFrames) or "video"
		"node": bg_node,
		"loop_target": loop,
		"loops_played": 0,
		"duration": 0.0,
		"active": false,			#/ A playback runs, paused or not
		"paused": false,			#/ BG_Pause
		"suspended": false,		#/ Suspension
		"fps": 0.0,
		"frame_count": 0,
		"stream": null,
		"frame_index": 0,
		"anim": "",
		"start": Callable(),		#/ Callable(loop) that (re)starts playback
		"gen": -1,
		"pause_handle": null,
		"end_frame": 0,
	}

	bg_layer_data[layer] = state
	return state


#* Start a playback between the playback hooks:
func _begin(source: CandyEngine, layer: String, effect: String, state: Dictionary, loop: int, custom_data: Array,
		duration_seconds: float = 0.0) -> void:
	var hook_args := {"caller": source, "node": self, "layer": layer, "effect": effect}
	var start_loop := CandyPlayDuration.play_loop(loop, duration_seconds)

	if start_loop != 0:
		await candy_de.run_node_hook(self, "x_playback_starting", hook_args, custom_data)

	await (state["start"] as Callable).call(start_loop)
	state["play_duration"] = CandyPlayDuration.start(self, loop, duration_seconds, _play_duration_media(state, effect))

	if start_loop != 0:
		await candy_de.run_node_hook(self, "x_playback_started", hook_args, custom_data)


#* Reset a state for a new playback (generation 'gen'):
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


#* (Re)start a frame folder:
func _start_folder(layer: String, loop: int) -> void:
	var state: Dictionary = bg_layer_data[layer]
	var bg_node: Node = state["node"]
	var stream: CandyFrameStream = state["stream"]
	var gen := _invalidate_layer(bg_node)
	_reset_state(state, loop, gen)

	state["frame_index"] = 0
	stream.show_frame_now(bg_node, 0)

	#% Held, or nothing to step through:
	if loop == 0 or stream.count() <= 1:
		state["active"] = false
		return

	var timer := _new_frame_timer(bg_node, float(state["fps"]))

	var animate := func() -> void:
		while true:
			await timer.timeout
			if not _is_current(bg_node, gen):
				return
			var index: int = int(state["frame_index"]) + 1
			if index >= stream.count():
				#% A pause loop may take the end over:
				if _pause_loop_takes_end(state):
					continue
				state["loops_played"] = int(state["loops_played"]) + 1
				#% Done - last frame, or the end frame:
				if int(state["loop_target"]) > 0 and int(state["loops_played"]) >= int(state["loop_target"]):
					state["active"] = false
					_clear_frame_timer(bg_node)
					_settle_layer(bg_node, state, int(state["end_frame"]))
					return
				index = 0
			state["frame_index"] = index
			#Ł Frame not loaded in time - skip it:
			stream.show_frame(bg_node, index)

	animate.call()


#* (Re)start a spritesheet:
func _start_sheet(layer: String, loop: int) -> void:
	var state: Dictionary = bg_layer_data[layer]
	var bg_node: Node = state["node"]
	var gen := _invalidate_layer(bg_node)
	_reset_state(state, loop, gen)

	bg_node.frame = 0

	#% Held, or nothing to step through:
	if loop == 0 or int(state["frame_count"]) <= 1:
		state["active"] = false
		return

	var timer := _new_frame_timer(bg_node, float(state["fps"]))

	var animate := func() -> void:
		while true:
			await timer.timeout
			if not _is_current(bg_node, gen):
				return
			var next_frame: int = bg_node.frame + 1
			if next_frame >= int(state["frame_count"]):
				#% A pause loop may take the end over:
				if _pause_loop_takes_end(state):
					continue
				state["loops_played"] = int(state["loops_played"]) + 1
				#% Done - last frame, or the end frame:
				if int(state["loop_target"]) > 0 and int(state["loops_played"]) >= int(state["loop_target"]):
					state["active"] = false
					_clear_frame_timer(bg_node)
					_settle_layer(bg_node, state, int(state["end_frame"]))
					return
				next_frame = 0
			bg_node.frame = next_frame

	animate.call()


#* (Re)start an AnimatedSprite2D/3D:
func _start_animated(layer: String, loop: int) -> void:
	var state: Dictionary = bg_layer_data[layer]
	var bg_node: Node = state["node"]
	var anim: String = str(state["anim"])
	var gen := _invalidate_layer(bg_node)
	_reset_state(state, loop, gen)

	#Ł Set the animation first - stop() keeps the previous one:
	bg_node.animation = anim
	bg_node.set_frame_and_progress(0, 0.0)

	#% Loops 0 holds on the first frame:
	if loop == 0:
		bg_node.stop()
		bg_node.animation = anim
		bg_node.frame = 0
		return

	#? A looping SpriteFrames animation never emits animation_finished.
	var anim_loops: bool = bg_node.sprite_frames.get_animation_loop(anim)

	var run := func() -> void:
		while true:
			#Ł play() restarts a finished animation:
			bg_node.play(anim)
			_mark_parked(bg_node, gen)
			if anim_loops:
				await bg_node.animation_looped
			else:
				await bg_node.animation_finished
			_clear_parked(bg_node, gen)

			if not _is_current(bg_node, gen):
				return

			#% A pause loop may take the end over:
			#? It already moved playback, so play() just carries on.
			if _pause_loop_takes_end(state):
				continue

			state["loops_played"] = int(state["loops_played"]) + 1

			#% Done - current frame, or the end frame:
			#? stop() would rewind.
			if int(state["loop_target"]) > 0 and int(state["loops_played"]) >= int(state["loop_target"]):
				bg_node.pause()
				state["active"] = false
				_settle_layer(bg_node, state, int(state["end_frame"]))
				return

	run.call()


#* (Re)start a video:
func _start_video(layer: String, loop: int) -> void:
	var state: Dictionary = bg_layer_data[layer]
	var bg_node: Node = state["node"]
	var gen := _invalidate_layer(bg_node)
	_reset_state(state, loop, gen)

	#Ł Candy counts loops - the node's own loop would swallow 'finished':
	bg_node.loop = false
	bg_node.stop()
	bg_node.paused = false
	bg_node.play()
	await get_tree().process_frame

	#% The layer may have been reassigned meanwhile:
	if not _is_current(bg_node, gen):
		return

	#? Length, once a frame has played (Theora reports none before).
	state["duration"] = float(bg_node.get_stream_length())

	#% Loops 0 holds on the first frame:
	if loop == 0:
		bg_node.paused = true
		return

	var run := func() -> void:
		while true:
			_mark_parked(bg_node, gen)
			await bg_node.finished
			_clear_parked(bg_node, gen)
			if not _is_current(bg_node, gen):
				return
			#% A pause loop may take the end over:
			if _pause_loop_takes_end(state):
				continue
			state["loops_played"] = int(state["loops_played"]) + 1
			#% Done - last frame, or the end frame:
			if int(state["loop_target"]) > 0 and int(state["loops_played"]) >= int(state["loop_target"]):
				state["active"] = false
				_settle_layer(bg_node, state, int(state["end_frame"]))
				return
			bg_node.play()

	run.call()


#* Pause whatever drives a layer's playback:
func _halt_layer(state: Dictionary) -> void:
	var bg_node: Node = state["node"]
	if not is_instance_valid(bg_node):
		return

	match str(state["kind"]):
		"folder", "sheet":
			var timer := bg_node.get_node_or_null(BG_FRAME_TIMER)
			if timer is Timer:
				timer.paused = true
		"animated":
			bg_node.pause()
		"video":
			bg_node.paused = true


#* Undo _halt_layer():
func _proceed_layer(state: Dictionary) -> void:
	var bg_node: Node = state["node"]
	if not is_instance_valid(bg_node) or not bool(state["active"]):
		return

	match str(state["kind"]):
		"folder", "sheet":
			var timer := bg_node.get_node_or_null(BG_FRAME_TIMER)
			if timer is Timer:
				timer.paused = false
		"animated":
			bg_node.play()
		"video":
			bg_node.paused = false


#* Loop length, in seconds:
func _layer_duration(state: Dictionary) -> float:
	#% Read live until a video's length is known:
	if str(state["kind"]) == "video" and float(state["duration"]) <= 0.0:
		var bg_node: Node = state["node"]
		if is_instance_valid(bg_node):
			state["duration"] = float(bg_node.get_stream_length())
	return float(state["duration"])


#* Position in the current loop, in seconds:
func _layer_position(state: Dictionary) -> float:
	var bg_node: Node = state["node"]
	if not is_instance_valid(bg_node):
		return 0.0

	match str(state["kind"]):
		"folder":
			return float(state["frame_index"]) / float(state["fps"]) + _frame_timer_progress(bg_node)
		"sheet":
			return float(bg_node.frame) / float(state["fps"]) + _frame_timer_progress(bg_node)
		"animated":
			var sf: SpriteFrames = bg_node.sprite_frames
			var anim: String = str(state["anim"])
			if sf == null or not sf.has_animation(anim):
				return 0.0
			var elapsed: float = CandyPlayback.get_shared().sprite_frames_frame_time(null, self, sf, anim, bg_node.frame)
			var speed: float = sf.get_animation_speed(anim)
			if speed > 0.0 and bg_node.frame < sf.get_frame_count(anim):
				elapsed += float(bg_node.frame_progress) * sf.get_frame_duration(anim, bg_node.frame) / speed
			return elapsed
		"video":
			return float(bg_node.stream_position)
	return 0.0


#* "f=" frame → seconds, for a layer:
func _layer_frame_converter(state: Dictionary, settings: Dictionary) -> Callable:
	var line_fps := _line_fps(settings)
	return func(frame: float) -> float:
		if str(state["kind"]) == "animated":
			var bg_node: Node = state["node"]
			if is_instance_valid(bg_node) and bg_node.sprite_frames != null:
				return CandyPlayback.get_shared().sprite_frames_frame_time(null, self, bg_node.sprite_frames, str(state["anim"]), int(round(frame)))
		var frame_rate: float = float(state["fps"])
		if line_fps > 0.0:
			frame_rate = line_fps
		if frame_rate <= 0.0:
			return 0.0
		return frame / frame_rate


#* Seek an AnimatedSprite to a time:
func _set_animated_time(bg_node: Node, state: Dictionary, target: float) -> void:
	var sf: SpriteFrames = bg_node.sprite_frames
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
			bg_node.set_frame_and_progress(i, progress)
			return
		start += frame_length


#* Create the frame Timer:
func _new_frame_timer(bg_node: Node, frame_rate: float) -> Timer:
	_clear_frame_timer(bg_node)
	var timer := Timer.new()
	timer.name = BG_FRAME_TIMER
	timer.wait_time = 1.0 / max(frame_rate, 0.001)
	bg_node.add_child(timer)
	timer.start()
	return timer


#* Remove the frame Timer:
func _clear_frame_timer(bg_node: Node) -> void:
	if not is_instance_valid(bg_node):
		return
	var timer := bg_node.get_node_or_null(BG_FRAME_TIMER)
	if timer:
		timer.stop()
		bg_node.remove_child(timer)
		timer.queue_free()


#* Restart the current frame after a skip:
func _restart_frame_timer(bg_node: Node) -> void:
	var timer := bg_node.get_node_or_null(BG_FRAME_TIMER)
	#% A paused Timer stays paused; a stopped one (held or finished) stays stopped:
	if timer is Timer and not timer.is_stopped():
		timer.start()


#* Time spent on the current frame, in seconds:
func _frame_timer_progress(bg_node: Node) -> float:
	var timer := bg_node.get_node_or_null(BG_FRAME_TIMER)
	if not (timer is Timer) or timer.is_stopped():
		return 0.0
	return clampf(timer.wait_time - timer.time_left, 0.0, timer.wait_time)


#* Whether a coroutine's generation is still current:
func _is_current(bg_node: Node, gen: int) -> bool:
	return is_instance_valid(bg_node) and int(bg_node.get_meta("bg_layer_generation", 0)) == gen


#* Mark a node as having a coroutine parked on its signals:
func _mark_parked(node: Node, generation: int) -> void:
	if is_instance_valid(node):
		node.set_meta("candy_parked_generation", generation)


#* Clear the mark after a normal signal:
func _clear_parked(node: Node, generation: int) -> void:
	if is_instance_valid(node) and int(node.get_meta("candy_parked_generation", -1)) == generation:
		node.remove_meta("candy_parked_generation")


#* Invalidate a layer node's playback coroutine, halt it, and wake the coroutine:
func _invalidate_layer(bg_node: Node) -> int:
	if not is_instance_valid(bg_node):
		return 0

	var gen: int = int(bg_node.get_meta("bg_layer_generation", 0)) + 1
	bg_node.set_meta("bg_layer_generation", gen)

	_clear_frame_timer(bg_node)

	#@ Step 1 - A coroutine parked on this node:
	var parked: bool = bg_node.has_meta("candy_parked_generation")
	if parked:
		bg_node.remove_meta("candy_parked_generation")

	#? Halt, not stop - stop() rewinds an AnimatedSprite and blanks a video.
	#@ Step 2 - Wake it, only if parked:
	#? So game code isn't told a cut animation completed.
	#? pause() doesn't emit these signals.
	if bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
		bg_node.pause()
		if parked:
			bg_node.animation_finished.emit()
			bg_node.animation_looped.emit()
	elif bg_node is VideoStreamPlayer:
		if bg_node.is_playing():
			bg_node.paused = true
		if parked:
			bg_node.finished.emit()

	return gen		#/ The layer's new generation


#& Effect Logic:
#? Called by the BG_Effect_ commands, one effect at a time.
#? candy_args: as for layers, plus "animation" (the effect's key).
#? Each plays on an AnimationPlayer child of its layer: the one holding it, a free one, or a new one.

#* Play an effect on a layer (BG_Effect_Play):
func play_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> bool:
	var source: CandyEngine		= candy_args["caller"]
	var layer: String			= str(candy_args["key"])
	var anim_key: String		= str(candy_args.get("animation", "")).strip_edges()
	var context: String			= str(candy_args.get("command", "BG_Effect_Play"))
	var library_ref: Variant	= settings.get("Library", "")
	var loop: int				= CandyPlayback.get_shared().normalize_loop(source, self, settings.get("Loops", "1"))

	var bg_node := _layer_node(layer, context)
	if bg_node == null:
		return false
	if anim_key == "":
		printerr(context, ": no animation given for layer → ", layer)
		return false

	#@ Step 1 - Load the line's "Library", if any:
	var library: AnimationLibrary = null
	var library_name := ""
	var full_name := anim_key

	if library_ref is Resource or str(library_ref).strip_edges() != "":
		var resolved := CandyMedia.resolve_media(library_ref, candy_de.background_folder.path_join("Animation_Libraries"), default_effect_extension, "", false)
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

		#Ł Named after its file, else its resource name:
		library_name = str(resolved["path"]).get_file().get_basename()
		if library_name == "":
			library_name = str(library.resource_name)
		if library_name == "":
			library_name = "Library"

		#Ł Loaded under its own name, whatever the key's "Library/" prefix:
		var anim_part := anim_key
		if "/" in anim_key:
			anim_part = anim_key.get_slice("/", 1)
		full_name = library_name + "/" + anim_part

		if not library.has_animation(anim_part):
			printerr(context, ": animation not found → '", anim_part, "' in library ", library_name)
			return false

	#@ Step 2 - Pick the AnimationPlayer:
	var player := _pick_effect_player(bg_node, layer, full_name, library_name, library)
	if player == null:
		printerr(context, ": animation not found → '", full_name, "' on layer ", layer, " (give a Library, or write it as 'Library/Name')")
		return false

	if library != null:
		var library_current := false
		if player.has_animation_library(library_name):
			library_current = player.get_animation_library(library_name) == library
		if not library_current:
			#Ł Swap out previous effects' libraries (keep the global one):
			player.stop()
			for loaded_name in player.get_animation_library_list():
				if str(loaded_name) != "":
					player.remove_animation_library(loaded_name)
			player.add_animation_library(library_name, library)

	#Ł Effects that played on this player before are gone:
	var effects: Dictionary = bg_effect_data.get(layer, {})
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
	bg_effect_data[layer] = effects

	#@ Step 4 - Start playback:
	var duration_seconds := CandyPlayDuration.read(source, self, settings.get("Duration", "null"), true, 0.0,
		_effect_frame_converter(source, state, settings))
	await _begin(source, layer, full_name, state, loop, custom_data, duration_seconds)
	return true		#/ Playback started


#* Block until an effect reaches a loop count and/or a time:
@warning_ignore("unused_parameter")
func wait_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> String:
	var source: CandyEngine	= candy_args["caller"]
	var layer: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "BG_Effect_Wait"))

	var full_name := _find_effect(layer, str(candy_args.get("animation", "")), settings)
	var state := _target_state(layer, full_name)
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
		if not is_same(_target_state(layer, full_name), state) or not bool(state["active"]):
			break

		#% Paused by BG_Effect_Pause:
		if bool(state["paused"]):
			if _pause_blocks_wait(state["pause_handle"], context, layer + "/" + full_name, warned_open_pause):
				break
			warned_open_pause = true
			await get_tree().process_frame
			continue

		var elapsed: float = int(state["loops_played"]) * float(state["duration"]) + _effect_position(state)
		if elapsed >= target_total:
			break

		await get_tree().process_frame

	return "Continue"


#* Pause an effect (BG_Effect_Pause):
@warning_ignore("unused_parameter")
func pause_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine	= candy_args["caller"]
	var layer: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "BG_Effect_Pause"))

	var full_name := _find_effect(layer, str(candy_args.get("animation", "")), settings)
	var state := _target_state(layer, full_name)
	if state.is_empty() or not bool(state["active"]):
		printerr(context, ": that effect is not playing on layer → ", layer, "/", candy_args.get("animation", ""))
		return

	var player: AnimationPlayer = state["player"]
	var pause_loop := CandyPauseLoop.start(source, self, player, settings, _effect_pause_loop_media(source, layer, state, settings),
		context, state.get("pause_loop", null) as CandyPauseLoop)
	state["pause_loop"] = pause_loop

	#% A suspension-halted loop stays held by the suspension until it ends:
	if pause_loop == null:
		if is_instance_valid(player) and player.is_playing():
			player.pause()
		_suspended_animplayers.erase(player)		#/ Held by the pause now
	state["paused"] = true

	_drop_pause(state)
	var handle := BGPauseHandle.new()
	handle.element = self
	handle.layer = layer
	handle.effect = full_name
	state["pause_handle"] = handle
	CandyPlayback.get_shared().set_pause(source, self, handle, int(settings.get("Lines", -1)), int(settings.get("All", 0)))


#* Resume an effect (BG_Effect_Resume):
func resume_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine	= candy_args["caller"]
	var layer: String		= str(candy_args["key"])

	var full_name := _find_effect(layer, str(candy_args.get("animation", "")), settings)
	var state := _target_state(layer, full_name)
	if state.is_empty():
		printerr(str(candy_args.get("command", "BG_Effect_Resume")), ": that effect was not played on layer → ", layer, "/", candy_args.get("animation", ""))
		return

	#Ł Start a held effect:
	if int(state["loop_target"]) == 0:
		await _begin(source, layer, full_name, state, 1, custom_data)
		return

	unpause_target(layer, full_name, settings, source)


#* Stop an effect, releasing waits on it (BG_Effect_Stop):
@warning_ignore("unused_parameter")
func stop_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine	= candy_args["caller"]
	var layer: String		= str(candy_args["key"])
	var context: String		= str(candy_args.get("command", "BG_Effect_Stop"))

	var full_name := _find_effect(layer, str(candy_args.get("animation", "")), settings)
	var state := _target_state(layer, full_name)
	if state.is_empty():
		printerr(context, ": that effect was not played on layer → ", layer, "/", candy_args.get("animation", ""))
		return

	var stop_frame := CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""),
		CandyPlayback.STOP_FRAME_CLEAR, context)

	#@ Step 1 - "Loops" or "Duration" schedules the stop:
	if bool(state["active"]):
		var loop := CandyPlayDuration.read_stop_loop(settings.get("Loops", ""), context)
		var duration_seconds := CandyPlayDuration.read(source, self, settings.get("Duration", ""), true, 0.0,
			_effect_frame_converter(source, state, settings))
		if CandyPlayDuration.schedules(loop, duration_seconds):
			state["end_frame"] = stop_frame
			state["end_converter"] = _effect_frame_converter(source, state, settings)
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
	bg_effect_data[layer].erase(full_name)


#* Move an effect within its current loop (BG_Effect_Skip):
@warning_ignore("unused_parameter")
func skip_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine	= candy_args["caller"]
	var layer: String		= str(candy_args["key"])

	var full_name := _find_effect(layer, str(candy_args.get("animation", "")), settings)
	var state := _target_state(layer, full_name)
	if state.is_empty() or not is_instance_valid(state["player"]):
		printerr(str(candy_args.get("command", "BG_Effect_Skip")), ": that effect was not played on layer → ", layer, "/", candy_args.get("animation", ""))
		return

	#% During a pause loop, move the resume point:
	if _pause_loop_owns_position(state):
		state["pause_loop"].move_pause_point(settings.get("Time", 0.0))
		return

	var target := _seek_target(source, _effect_position(state), settings.get("Time", 0.0), _effect_frame_converter(source, state, settings))
	state["player"].seek(clampf(target, 0.0, float(state["duration"])), true)		#/ Paused or held: moves without starting


#& Effect Internals:

#* AnimationPlayer to play an effect on:
func _pick_effect_player(bg_node: Node, layer: String, full_name: String, library_name: String, library: AnimationLibrary) -> AnimationPlayer:
	var effects: Dictionary = bg_effect_data.get(layer, {})

	#% Already playing this effect:
	if effects.has(full_name) and is_instance_valid(effects[full_name]["player"]):
		var current: AnimationPlayer = effects[full_name]["player"]
		if library == null or current.has_animation_library(library_name) or not _effect_player_busy(layer, current, full_name):
			return current

	var candidates: Array = []
	for child in bg_node.get_children():
		if child is AnimationPlayer:
			candidates.append(child)

	#% Without a library, the animation must exist:
	if library == null:
		var fallback: AnimationPlayer = null
		for player in candidates:
			if player.has_animation(full_name):
				if not _effect_player_busy(layer, player, full_name):
					return player
				if fallback == null:
					fallback = player
		return fallback

	#% A player with this library, then any free one:
	for player in candidates:
		if player.has_animation_library(library_name) and player.get_animation_library(library_name) == library and not _effect_player_busy(layer, player, full_name):
			return player
	for player in candidates:
		if not _effect_player_busy(layer, player, full_name):
			return player

	#% Else a new one:
	var new_player := AnimationPlayer.new()
	new_player.root_node = NodePath("..")
	bg_node.add_child(new_player)
	return new_player


#* Whether another effect on the layer still plays on 'player':
func _effect_player_busy(layer: String, player: AnimationPlayer, full_name: String) -> bool:
	var effects: Dictionary = bg_effect_data.get(layer, {})
	for other_name in effects:
		if other_name == full_name:
			continue
		var other: Dictionary = effects[other_name]
		if other["player"] == player and bool(other["active"]):
			return true
	return false


#* Full name of the effect a line names:
func _find_effect(layer: String, anim_key: String, settings: Dictionary) -> String:
	var key := anim_key.strip_edges()
	var effects: Dictionary = bg_effect_data.get(layer, {})

	#% Known, or "Library/Name" - as written:
	if effects.has(key) or "/" in key:
		return key

	#% Bare name - the line's "Library":
	var library_ref: Variant = settings.get("Library", "")
	if library_ref is AnimationLibrary:
		var library_name := str(library_ref.resource_path).get_file().get_basename()
		if library_name == "":
			library_name = str(library_ref.resource_name)
		return library_name + "/" + key
	if str(library_ref).strip_edges() != "":
		return str(library_ref).strip_edges().get_file().get_basename() + "/" + key

	#% Else any library's:
	for full_name in effects:
		if str(full_name).get_slice("/", 1) == key:
			return full_name
	return key


#* Playback state of a layer (effect "") or effect, or {}:
func _target_state(layer: String, effect: String) -> Dictionary:
	if effect == "":
		return bg_layer_data.get(layer, {})
	return bg_effect_data.get(layer, {}).get(effect, {})


#* (Re)start an effect's animation:
func _start_effect(state: Dictionary, loop: int) -> void:
	var player: AnimationPlayer = state["player"]
	var full_name: String = str(state["anim"])
	var anim: Animation = state["animation"]

	#@ Step 1 - Bump the generation, making old coroutines stale:
	var gen: int = int(player.get_meta("bg_effect_generation", 0)) + 1
	player.set_meta("bg_effect_generation", gen)
	_reset_state(state, loop, gen)
	_suspended_animplayers.erase(player)

	#@ Step 2 - Restart from the beginning:
	#? play() resumes a paused player and ignores a repeat; stop() re-applies the last animation, which may be gone.
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

			#% Done - final pose, or the end frame:
			if int(state["loop_target"]) > 0 and int(state["loops_played"]) >= int(state["loop_target"]):
				if int(state["end_frame"]) == 0:
					_hold_final_pose(player, anim)
					state["active"] = false
				else:
					_end_effect_at(state, anim.length)
				return

			#% A self-looping Animation restarts on its own:
			if anim.loop_mode == Animation.LOOP_NONE:
				player.play(full_name)

	run.call()


#* Wait for one loop of an effect; false = let go:
func _await_effect_cycle(player: AnimationPlayer, anim: Animation, state: Dictionary, gen: int) -> bool:
	var looping: bool = anim != null and anim.loop_mode != Animation.LOOP_NONE
	var prev_pos := -1.0
	var prev_dir := 0

	while true:
		await get_tree().process_frame
		if not is_instance_valid(player) or int(player.get_meta("bg_effect_generation", 0)) != gen:
			return false

		#% Player taken over:
		if str(player.assigned_animation) != str(state["anim"]):
			return false

		if not player.is_playing():
			#% Paused or suspended - hold, and don't mistake the resume for a wrap:
			if bool(state["paused"]) or player in _suspended_animplayers:
				prev_pos = -1.0
				prev_dir = 0
				continue
			#% One-shot reached its end, unless a pause loop takes it over:
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
			#% Ping-pong - a loop ends when playback turns forward:
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

	#? Unreachable (every path must return).
	return false


#* Apply an effect's final pose, stopping a self-looping one first:
func _hold_final_pose(player: AnimationPlayer, anim: Animation) -> void:
	if not is_instance_valid(player):
		return
	if player.is_playing():
		player.pause()
	player.seek(anim.length, true)


#* Stop an effect's AnimationPlayer and release its coroutine:
func _stop_effect_player(player: AnimationPlayer, clear: bool = true) -> void:
	if not is_instance_valid(player):
		return

	#Ł Invalidate the generation, so the coroutine exits:
	player.set_meta("bg_effect_generation", int(player.get_meta("bg_effect_generation", 0)) + 1)
	_suspended_animplayers.erase(player)
	if clear:
		CandyPlayback.get_shared().clear_animation(caller, self, player)

	#? No fake animation_finished: nothing waits on it, and game code would get a false completion.


#* Position in an effect's current loop, in seconds:
func _effect_position(state: Dictionary) -> float:
	var player: AnimationPlayer = state["player"]
	if not is_instance_valid(player) or str(player.assigned_animation) != str(state["anim"]):
		return 0.0
	return float(player.current_animation_position)


#* "f=" frame → seconds, for an effect:
func _effect_frame_converter(source: CandyEngine, state: Dictionary, settings: Dictionary) -> Callable:
	#Ł FPS chain - line → library config.txt → default_effect_fps → engine → properties:
	var fallback_fps := CandyPlayback.get_shared().resolve_fps(source, self, "default_effect_fps", settings.get("FPS", ""),
		default_effect_fps, 0.0, CandyPlayback.get_shared().animation_library_file(source, self, state["player"], str(state["anim"])))
	#Ł Counts the animation's frames, else uses the FPS:
	return func(frame: float) -> float:
		return CandyPlayback.get_shared().animation_frame_to_time(source, self, state["animation"], frame, fallback_fps)


#& Shared Internals:

#* Resolve a skip's "Time" from the current position:
func _seek_target(source: CandyEngine, current_pos: float, time_raw: Variant, frame_to_time: Callable) -> float:
	return CandyPlayback.get_shared().resolve_relative_time(source, self, current_pos, time_raw, true, 0.0, frame_to_time)


#* A line's "FPS", or 0.0:
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
	#% No line count - the wait blocks:
	if not already_warned:
		push_warning("%s: waiting on '%s', which is paused with no line count - dialogue stays blocked until it is resumed from outside the dialogue." % [context, label])
	return false


#* Whether a layer plays unsuspended (not paused, or with a pause loop):
func _layer_moves(state: Dictionary) -> bool:
	if not bool(state["paused"]):
		return true
	var pause_loop: Variant = state.get("pause_loop", null)
	return pause_loop is CandyPauseLoop and pause_loop.holds_pause()


#* Pause loop media for a layer (CandyPauseLoop.start()):
func _layer_pause_loop_media(source: CandyEngine, state: Dictionary, settings: Dictionary) -> Dictionary:
	var reason := ""
	if str(state["kind"]) == "static":
		reason = "a still image has nothing to loop"
	var frame_converter := _layer_frame_converter(state, settings)
	return {
		"active": bool(state["active"]),
		"reason": reason,
		"position": func() -> float:
			return _layer_position(state),
		"length": func() -> float:
			return _layer_duration(state),
		"time": func(text: String, base: float) -> float:
			return CandyPlayback.get_shared().resolve_relative_time(source, self, base, text, true, 0.0, frame_converter),
		"play_from": func(time: float) -> void:
			_loop_layer_from(state, time),
		"run": func() -> void:
			#% A suspension-halted layer plays once it ends:
			if not bool(state["suspended"]):
				_proceed_layer(state),
	}


#* Play a layer from a time, for its pause loop:
func _loop_layer_from(state: Dictionary, time: float) -> void:
	var bg_node: Node = state["node"]
	if not is_instance_valid(bg_node):
		return
	var held: bool = bool(state["suspended"])		#/ Suspension-halted: only move there

	match str(state["kind"]):
		"folder":
			var stream: CandyFrameStream = state["stream"]
			var index := clampi(int(time * float(state["fps"])), 0, stream.count() - 1)
			state["frame_index"] = index
			stream.show_frame_now(bg_node, index)
			_loop_restart_timer(bg_node, held)
		"sheet":
			bg_node.frame = clampi(int(time * float(state["fps"])), 0, int(state["frame_count"]) - 1)
			_loop_restart_timer(bg_node, held)
		"animated":
			#Ł play() restarts a finished animation, so set the time after:
			if not bg_node.is_playing() and not held:
				bg_node.play(str(state["anim"]))
			_set_animated_time(bg_node, state, time)
		"video":
			if not bg_node.is_playing():
				bg_node.play()
			bg_node.paused = held
			bg_node.stream_position = time


#* Restart the frame a pause loop moved a layer to, held if 'held':
func _loop_restart_timer(bg_node: Node, held: bool) -> void:
	var timer := bg_node.get_node_or_null(BG_FRAME_TIMER)
	if timer is Timer:
		timer.start()
		timer.paused = held


#* Pause loop media for an effect (CandyPauseLoop.start()):
func _effect_pause_loop_media(source: CandyEngine, layer: String, state: Dictionary, settings: Dictionary) -> Dictionary:
	var player: AnimationPlayer = state["player"]
	var frame_converter := _effect_frame_converter(source, state, settings)
	return {
		"active": bool(state["active"]) and is_instance_valid(player),
		"label": layer + "/" + str(state["anim"]),
		"position": func() -> float:
			return _effect_position(state),
		"length": func() -> float:
			return float(state["duration"]),
		"time": func(text: String, base: float) -> float:
			return CandyPlayback.get_shared().resolve_relative_time(source, self, base, text, true, 0.0, frame_converter),
		"play_from": func(time: float) -> void:
			if not is_instance_valid(player):
				return
			#Ł Suspension holds it here; play() restarts a finished animation:
			if not player.is_playing() and not (player in _suspended_animplayers):
				player.play(str(state["anim"]))
			player.seek(time, true),
		"run": func() -> void:
			if is_instance_valid(player) and not player.is_playing() and not (player in _suspended_animplayers):
				player.play(),
	}


#* Whether a pause loop owns the position (CandyPauseLoop.owns_position()):
func _pause_loop_owns_position(state: Dictionary) -> bool:
	var pause_loop: Variant = state.get("pause_loop", null)
	return pause_loop is CandyPauseLoop and pause_loop.owns_position()


#* Whether a pause loop takes over the media's end (CandyPauseLoop.media_ended()):
func _pause_loop_takes_end(state: Dictionary) -> bool:
	var pause_loop: Variant = state.get("pause_loop", null)
	return pause_loop is CandyPauseLoop and pause_loop.media_ended()


#* End a pause loop, restoring the volume:
func _drop_pause_loop(state: Dictionary) -> void:
	var pause_loop: Variant = state.get("pause_loop", null)
	if pause_loop is CandyPauseLoop:
		pause_loop.cancel()
	state["pause_loop"] = null


#* Cancel and remove a state's "Lines" pause handle:
func _drop_pause(state: Dictionary) -> void:
	var handle = state.get("pause_handle", null)
	if handle != null:
		handle.pause_count = 0
	state["pause_handle"] = null


#* Duration follower for a layer (effect "") or effect (CandyPlayDuration.start()):
func _play_duration_media(state: Dictionary, effect: String) -> Dictionary:
	var gen: int = int(state["gen"])

	if effect == "":
		return {
			"position": func() -> float:
				return _layer_position(state),
			"length": func() -> float:
				return _layer_duration(state),
			"loops": func() -> int:
				return int(state["loops_played"]),
			"set_loops": func(count: int) -> void:
				state["loop_target"] = count,
			"end": func(time: float) -> void:
				_end_layer_at(state, time),
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
			return bool(state["active"]) and is_instance_valid(player) and int(player.get_meta("bg_effect_generation", 0)) == gen,
		"held": func() -> bool:
			return _pause_loop_owns_position(state),
	}


#* End a layer's playback at 'time' in its loop:
func _end_layer_at(state: Dictionary, time: float) -> void:
	_drop_pause_loop(state)
	_invalidate_layer(state["node"])
	if int(state["end_frame"]) == 0:
		_move_layer(state, time)
	else:
		_settle_layer(state["node"], state, int(state["end_frame"]))
	state["active"] = false


#* End an effect at 'time' in its loop:
func _end_effect_at(state: Dictionary, time: float) -> void:
	var player: AnimationPlayer = state["player"]
	_drop_pause_loop(state)
	state["active"] = false
	if not is_instance_valid(player):
		return

	var stop_frame := int(state["end_frame"])
	if stop_frame == CandyPlayback.STOP_FRAME_CLEAR:
		_stop_effect_player(player)
		return

	#Ł Invalidate the generation, so the loop-counting coroutine exits:
	player.set_meta("bg_effect_generation", int(player.get_meta("bg_effect_generation", 0)) + 1)
	_suspended_animplayers.erase(player)
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


#* Scale Sprite2D / Sprite3D layers to bg_sizes:
func _scale_bg_to_size(bg_node: Node, layer: String) -> void:
	if not bg_sizes.has(layer):
		return

	var target_size: Array = bg_sizes[layer]
	if target_size.size() < 2:
		return

	var target_h = float(target_size[0])
	var target_w = float(target_size[1])

	#Ł Texture size:
	if bg_node is Sprite2D or bg_node is Sprite3D:
		var tex: Texture2D = bg_node.texture
		if tex == null:
			return
		var tex_size = tex.get_size() / Vector2(max(bg_node.hframes, 1), max(bg_node.vframes, 1))
		if tex_size.x == 0 or tex_size.y == 0:
			return

		#Ł Scale ratio:
		var scale_x = target_w / tex_size.x
		var scale_y = target_h / tex_size.y
		if bg_node is Sprite3D:
			bg_node.scale = Vector3(scale_x, scale_y, 1.0)
		else:
			bg_node.scale = Vector2(scale_x, scale_y)


#* Use the resource an expression loaded, or load the file:
func _resolved_texture(resolved: Dictionary) -> Texture2D:
	#% Such a resource may have no path, so it can't be reloaded:
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


#* Hook function, called before a layer or effect starts playback (BG_Play / BG_Effect_Play, or a _Resume on a held one):
@warning_ignore("unused_parameter")
func x_playback_starting(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook function, called once a layer or an effect has started playback:
@warning_ignore("unused_parameter")
func x_playback_started(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass
