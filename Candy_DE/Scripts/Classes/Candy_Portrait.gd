#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPortrait
extends RefCounted


#^ Portrait settings a caller can pass in 'config':
const DEFAULT_CONFIG := {
	"default_image_extension": "",				#/ TextureRect, NinePatchRect, TextureButton
	"default_sprite_extension": "",				#/ Sprite2D, Sprite3D
	"default_animated_sprite_extension": "",	#/ AnimatedSprite2D / AnimatedSprite3D
	"default_video_extension": "",				#/ VideoStreamPlayer
	"default_animated_image_fps": 0.0,			#/ Frame folders in TextureRect / NinePatchRect
	"default_sprite_fps": 0.0,					#/ Sprite sheets
	"default_animated_sprite_fps": 0.0,			#/ SpriteFrames saved with speed 0
	"default_video_fps": 0.0,					#/ Videos with no readable frame rate
	"animation_folder_cache": -1,				#/ Frame folders: memory budget in MB, -1 inherits
	"animation_folder_stream": -1,				#/ Frame folders: frames loaded ahead while streaming, -1 inherits
	"portrait_w": 256,							#/ Sprite2D / Sprite3D frame size (0 = no scaling)
	"portrait_h": 256,
}

#^ SpriteFrames sub-folder:
const SPRITE_FRAMES_FOLDER := "Sprite_Frames"

#^ Frame animation Timer name:
const FRAME_TIMER := "PortraitAnimTimer"

#^ Portrait_Play endless values:
const PLAY_UNTIL_ADVANCE := -1
const PLAY_ALWAYS := -2
const PLAY_UNTIL_VOICE := -3		#/ Until the line's voice ends; without a voice, its fallback ("-3/2") or the stop frame
#^ Separates -3 from the value used when the line has no voice ("-3/-2"):
const VOICE_FALLBACK_SEPARATOR := "/"
#^ Portrait_Stop values that aren't a frame number:
const STOP_REMOVE := 0
const STOP_LAST := -1
#^ Portrait_Play and Portrait_Stop defaults:
const DEFAULT_LOOPS := 1
const DEFAULT_STOP_FRAME := 1

#^ Node metas (loop state, connected signals):
#? LOOP_META holds {"loops", "count", "stop_frame", "on_removed"}.
const LOOP_META := "candy_portrait_loop"
const SIGNALS_META := "candy_portrait_signals"
#^ Node metas (frame folder stream, current frame, sprite sheet frame count):
const FRAMES_META := "candy_portrait_frames"
const FRAME_META := "candy_portrait_frame"
const SHEET_FRAMES_META := "candy_portrait_sheet_frames"
#^ Node meta (video frame rate):
const VIDEO_FPS_META := "candy_portrait_video_fps"


#^ Shared instance:
static var _shared: CandyPortrait = null

#* Get the shared instance:
static func get_shared() -> CandyPortrait:
	if _shared == null:
		_shared = CandyPortrait.new()
	return _shared


#? Unused 'caller' parameters:
@warning_ignore_start("unused_parameter")

#* Portrait_Play → loop count:
static func loops_of(value: Variant) -> int:
	var text := str(value).strip_edges().get_slice(VOICE_FALLBACK_SEPARATOR, 0).strip_edges()
	if text == "":
		return DEFAULT_LOOPS
	if not text.is_valid_int():
		printerr("Portrait_Play can't be '", text, "' - expected a number of loops, -1, -2 or -3. Playing once.")
		return DEFAULT_LOOPS
	return maxi(int(text), PLAY_UNTIL_VOICE)

#* Portrait_Play -3's value for a line without a voice ("-3/2" → "2"), or "" (stop at once):
static func voice_fallback_of(value: Variant) -> String:
	var text := str(value).strip_edges()
	if text.get_slice_count(VOICE_FALLBACK_SEPARATOR) < 2:
		return ""
	var fallback := text.get_slice(VOICE_FALLBACK_SEPARATOR, 1).strip_edges()
	if text.get_slice_count(VOICE_FALLBACK_SEPARATOR) > 2 or not fallback.is_valid_int() or int(fallback) < PLAY_ALWAYS:
		printerr("Portrait_Play can't be '", text, "' - expected -3/ followed by a number of loops, 0, -1 or -2. Stopping at once without a voice.")
		return ""
	return fallback

#* Portrait_Play -3 on a line without a voice - its fallback replaces it in the speech:
#? true when there is none: the portrait stops at once, on its Portrait_Stop.
static func apply_voice_fallback(speech: CandySpeech) -> bool:
	if loops_of(speech.play_portrait) != PLAY_UNTIL_VOICE:
		return false
	var fallback := voice_fallback_of(speech.play_portrait)
	if fallback == "":
		return true
	speech.play_portrait = fallback
	return false

#* Portrait_Stop → stop frame:
static func stop_frame_of(value: Variant) -> int:
	var text := str(value).strip_edges()
	if text == "":
		return DEFAULT_STOP_FRAME
	if not text.is_valid_int():
		printerr("Portrait_Stop can't be '", text, "' - expected a frame number, 0 or -1. Stopping on the first frame.")
		return DEFAULT_STOP_FRAME
	return maxi(int(text), STOP_LAST)

#* Resolve and show a portrait; returns whether one is shown:
func show_portrait(source: CandyEngine, caller: Object, portrait_node: Node, character_ref: String, portrait_raw: Variant,
		sprite_frames_raw: Variant, loops: int, stop_frame: int, config: Dictionary = {}, on_removed: Callable = Callable()) -> bool:
	var resolved := resolve_portrait(source, caller, portrait_node, character_ref, portrait_raw, sprite_frames_raw, config)
	if resolved.is_empty():
		clear_portrait(source, caller, portrait_node)
		return false
	return apply_portrait(source, caller, portrait_node, resolved, loops, stop_frame, config, on_removed)

#* Resolve what a portrait reference shows in this node, or {}:
func resolve_portrait(source: CandyEngine, caller: Object, portrait_node: Node, character_ref: String, portrait_raw: Variant,
		sprite_frames_raw: Variant = "", config: Dictionary = {}) -> Dictionary:
	if portrait_node == null:
		return {}

	#@ Step 1 - Evaluate CandyRef:
	var resolved = portrait_raw
	if source != null:
		var got = source.candy_ref.resolve_value(source, source, portrait_raw, candy_de.candy_ref_symbol)
		if not source.candy_ref.last_failed and got != null:
			resolved = CandyMedia.to_path(got)
	resolved = str(resolved)

	#@ Step 2 - AnimatedSprite takes an animation name:
	if portrait_node is AnimatedSprite2D or portrait_node is AnimatedSprite3D:
		var frames_path := sprite_frames_path(source, caller, character_ref, sprite_frames_raw, config)
		if not CandyMedia.exists(frames_path):
			printerr("Portrait: missing SpriteFrames for ", character_ref, ": ", frames_path)
			return {}
		return {"path": frames_path, "animation": resolved}		#/ SpriteFrames and animation name

	#@ Step 3 - Default extension for the node type:
	var default_ext := ""
	if portrait_node is TextureRect or portrait_node is NinePatchRect or portrait_node is TextureButton:
		default_ext = _extension(source, caller, config, "default_image_extension")
	elif portrait_node is Sprite2D or portrait_node is Sprite3D:
		default_ext = _extension(source, caller, config, "default_sprite_extension")
	elif portrait_node is VideoStreamPlayer:
		default_ext = _extension(source, caller, config, "default_video_extension")
	else:
		printerr("Unsupported portrait node type: ", portrait_node)
		return {}

	#@ Step 4 - Resolve the reference:
	var found := CandyMedia.resolve_media(resolved, candy_de.portraits_folder.path_join(character_ref), default_ext)
	if not bool(found["found"]):
		push_warning("Portrait: missing file: ", found["path"])
		return {}
	return {"path": str(found["path"])}

#* Path of the SpriteFrames a Sprite_Frames_File names:
func sprite_frames_path(source: CandyEngine, caller: Object, character_ref: String, sprite_frames_raw: Variant,
		config: Dictionary = {}) -> String:
	var value = sprite_frames_raw
	if source != null:
		var got = source.candy_ref.resolve_value(source, source, sprite_frames_raw, candy_de.candy_ref_symbol)
		if not source.candy_ref.last_failed and got != null:
			value = got
	var file_name := CandyMedia.to_path(value)
	#% Empty - named after the actor:
	if file_name == "":
		file_name = character_ref
	#Ł A path, or a file in portraits_folder/<actor>/Sprite_Frames/:
	var folder: String = candy_de.portraits_folder.path_join(character_ref).path_join(SPRITE_FRAMES_FOLDER)
	return CandyMedia.resolve_path(file_name, folder, _extension(source, caller, config, "default_animated_sprite_extension"))

#* Show a resolved portrait; returns whether it is shown:
func apply_portrait(source: CandyEngine, caller: Object, portrait_node: Node, resolved: Dictionary,
		loops: int, stop_frame: int = DEFAULT_STOP_FRAME, config: Dictionary = {}, on_removed: Callable = Callable()) -> bool:
	clear_portrait(source, caller, portrait_node)
	if portrait_node == null or resolved.is_empty():
		return false

	#Ł Loop state:
	if loops != 0:
		portrait_node.set_meta(LOOP_META, {"loops": loops, "count": 0, "stop_frame": stop_frame, "on_removed": on_removed})

	#? Loops 0 - first frame, not playing.
	var path := str(resolved.get("path", ""))
	if portrait_node is AnimatedSprite2D or portrait_node is AnimatedSprite3D:
		return _animated_sprite(source, caller, portrait_node, path, str(resolved.get("animation", "")), loops != 0, config)
	if portrait_node is TextureRect or portrait_node is NinePatchRect:
		return _texture_rect(source, caller, portrait_node, path, loops != 0, config)
	#% TextureButton frame folder:
	if portrait_node is TextureButton and DirAccess.dir_exists_absolute(path):
		return _texture_rect(source, caller, portrait_node, path, loops != 0, config)
	if portrait_node is TextureButton:
		return _texture_button(source, caller, portrait_node, path)
	if portrait_node is Sprite2D or portrait_node is Sprite3D:
		return _sprite(source, caller, portrait_node, path, loops != 0, config)
	if portrait_node is VideoStreamPlayer:
		return _video(source, caller, portrait_node, path, loops != 0, config)

	printerr("Unsupported portrait node type: ", portrait_node)
	return false

#* Stop a portrait on a frame:
func stop_portrait(source: CandyEngine, caller: Object, portrait_node: Node, stop_frame: int, on_removed: Callable = Callable()) -> void:
	if portrait_node == null or not is_instance_valid(portrait_node):
		return
	_end_playback(source, caller, portrait_node)

	#% Stop frame 0 - remove it and call on_removed:
	if stop_frame == STOP_REMOVE:
		clear_portrait(source, caller, portrait_node)
		if on_removed.is_valid():
			on_removed.call()
		return

	_go_to_frame(source, caller, portrait_node, stop_frame, true)

#* Jump to a frame (from 1, or -1 for the last), keeping play state (Line_Portrait):
func seek_portrait(source: CandyEngine, caller: Object, portrait_node: Node, frame: int) -> void:
	if portrait_node == null or not is_instance_valid(portrait_node):
		return
	_go_to_frame(source, caller, portrait_node, frame, false)

#* Show a frame (from 1, or -1 for the last); 'stop' stops there:
func _go_to_frame(source: CandyEngine, caller: Object, portrait_node: Node, frame: int, stop: bool) -> void:
	if portrait_node is AnimatedSprite2D or portrait_node is AnimatedSprite3D:
		if stop:
			portrait_node.stop()
		if portrait_node.sprite_frames != null:
			var count: int = portrait_node.sprite_frames.get_frame_count(portrait_node.animation)
			portrait_node.frame = _frame_index(frame, count)
			portrait_node.frame_progress = 0.0

	elif portrait_node is TextureRect or portrait_node is NinePatchRect or portrait_node is TextureButton:
		var stream = portrait_node.get_meta(FRAMES_META, null)
		if stream is CandyFrameStream and stream.count() > 0:
			var index := _frame_index(frame, stream.count())
			portrait_node.set_meta(FRAME_META, index)
			stream.show_frame_now(portrait_node, index)

	elif portrait_node is Sprite2D or portrait_node is Sprite3D:
		var total: int = portrait_node.get_meta(SHEET_FRAMES_META, 1)
		portrait_node.frame = _frame_index(frame, total)

	elif portrait_node is VideoStreamPlayer:
		if portrait_node.stream == null:
			return
		if stop:
			if not portrait_node.is_playing():
				portrait_node.play()		#/ Must be playing to show a frame
			portrait_node.paused = true
		var fps: float = portrait_node.get_meta(VIDEO_FPS_META, 0.0)
		if fps <= 0.0:
			fps = CandyPlayback.get_shared().resolve_fps(source, caller, "default_video_fps", "", 0.0,
				CandyPlayback.get_shared().video_fps(source, caller, portrait_node.stream), str(portrait_node.stream.resource_path))
		var length: float = portrait_node.get_stream_length()
		var position := (maxi(frame, 1) - 1) / fps
		if frame == STOP_LAST:
			position = length - 1.0 / fps
		portrait_node.stream_position = clampf(position, 0.0, maxf(length, 0.0))

#* Remove the portrait from its node:
func clear_portrait(source: CandyEngine, caller: Object, portrait_node: Node) -> void:
	if portrait_node == null:
		return
	_end_playback(source, caller, portrait_node)
	portrait_node.set_meta(FRAMES_META, null)
	portrait_node.set_meta(FRAME_META, null)
	portrait_node.set_meta(SHEET_FRAMES_META, null)
	portrait_node.set_meta(VIDEO_FPS_META, null)

	if portrait_node is TextureRect or portrait_node is NinePatchRect:
		portrait_node.texture = null

	elif portrait_node is TextureButton:
		portrait_node.texture_normal = null
		portrait_node.texture_pressed = null
		portrait_node.texture_hover = null
		portrait_node.texture_disabled = null
		portrait_node.texture_focused = null
		portrait_node.texture_click_mask = null

	elif portrait_node is Sprite2D or portrait_node is Sprite3D:
		portrait_node.texture = null

	elif portrait_node is AnimatedSprite2D or portrait_node is AnimatedSprite3D:
		portrait_node.stop()
		portrait_node.visible = false

	elif portrait_node is VideoStreamPlayer:
		portrait_node.stop()
		#Ł Unpause, or the next portrait starts paused:
		portrait_node.paused = false
		portrait_node.visible = false

#* Pause a portrait's animation; returns whether anything was paused:
func pause_portrait(source: CandyEngine, caller: Object, portrait_node: Node) -> bool:
	if portrait_node == null:
		return false
	if portrait_node is AnimatedSprite2D or portrait_node is AnimatedSprite3D:
		if portrait_node.is_playing():
			portrait_node.pause()
			return true
		return false
	if portrait_node is VideoStreamPlayer:
		if portrait_node.is_playing() and not portrait_node.paused:
			portrait_node.paused = true
			return true
		return false
	var timer = portrait_node.get_node_or_null(FRAME_TIMER)
	if timer is Timer and not timer.paused:
		timer.paused = true
		return true
	return false

#* Resume what pause_portrait() paused:
func resume_portrait(source: CandyEngine, caller: Object, portrait_node: Node) -> void:
	if portrait_node == null or not is_instance_valid(portrait_node):
		return
	if portrait_node is AnimatedSprite2D or portrait_node is AnimatedSprite3D:
		portrait_node.play()
		return
	if portrait_node is VideoStreamPlayer:
		portrait_node.paused = false
		return
	var timer = portrait_node.get_node_or_null(FRAME_TIMER)
	if timer is Timer:
		timer.paused = false


#& Per node type:
#* AnimatedSprite2D / AnimatedSprite3D:
func _animated_sprite(source: CandyEngine, caller: Object, portrait_node: Node, spriteframes_path: String, animation: String, play: bool, config: Dictionary) -> bool:
	var frames := CandyMedia.load_sprite_frames(spriteframes_path)
	if frames == null:
		printerr("Invalid or missing SpriteFrames resource: ", spriteframes_path)
		return false

	#@ Step 1 - Requested animation, else "default":
	var anim_to_use := animation
	if not frames.has_animation(anim_to_use):
		printerr("Animation not found in %s: '%s'" % [spriteframes_path, animation])
		if not frames.has_animation("default"):
			return false
		anim_to_use = "default"

	#@ Step 2 - Speed 0 → default_animated_sprite_fps:
	frames = CandyPlayback.get_shared().sprite_frames_with_speed(source, caller, frames, anim_to_use, "",
		_config(config, "default_animated_sprite_fps"), spriteframes_path)

	portrait_node.sprite_frames = frames
	portrait_node.visible = true

	if play:
		portrait_node.play(anim_to_use)
		#¦ 1. Count loops:
		_connect(portrait_node, "animation_looped", func(): _loop_ended(source, caller, portrait_node))
		_connect(portrait_node, "animation_finished", func():
			if not _loop_ended(source, caller, portrait_node):
				portrait_node.play(anim_to_use))
	else:
		#¦ 2. Not playing - first frame:
		portrait_node.animation = anim_to_use
		portrait_node.frame = 0
	return true

#* TextureRect / NinePatchRect (and TextureButton, frame folders only):
func _texture_rect(source: CandyEngine, caller: Object, portrait_node: Node, portrait_file: String, play: bool, config: Dictionary) -> bool:
	#¦ 1. Frame folder:
	if DirAccess.dir_exists_absolute(portrait_file):
		#Ł Open the frame stream:
		var stream := CandyFrameStream.open(source, caller, portrait_file,
			_config(config, "animation_folder_cache"), _config(config, "animation_folder_stream"), portrait_node)
		if stream.count() == 0 or stream.frame_now(0) == null:
			printerr("Portrait: no frames found in folder: ", portrait_file)
			return false

		stream.show_frame_now(portrait_node, 0)
		portrait_node.visible = true
		#Ł Store the stream on the node:
		portrait_node.set_meta(FRAMES_META, stream)
		portrait_node.set_meta(FRAME_META, 0)
		if not play:
			return true

		#Ł FPS - config.txt, else default_animated_image_fps:
		var anim_fps := CandyPlayback.get_shared().resolve_fps(source, caller, "default_animated_image_fps", "",
			_config(config, "default_animated_image_fps"), CandyMedia.read_config_fps(portrait_file), portrait_file)

		_add_frame_timer(source, caller, portrait_node, anim_fps, func():
			var node_stream = portrait_node.get_meta(FRAMES_META, null)
			if not (node_stream is CandyFrameStream) or node_stream.count() == 0:
				return
			var next: int = int(portrait_node.get_meta(FRAME_META, 0)) + 1
			if next >= node_stream.count():
				if _loop_ended(source, caller, portrait_node):
					return
				next = 0
			portrait_node.set_meta(FRAME_META, next)
			#? Skipped if not loaded yet.
			node_stream.show_frame(portrait_node, next)
		)
		return true

	#¦ 2. Single image:
	var tex := CandyMedia.load_texture(portrait_file)
	if tex == null:
		printerr("Portrait file not found or invalid: ", portrait_file)
		return false
	portrait_node.texture = tex
	portrait_node.visible = true
	return true

#* TextureButton, with optional Button_Textures:
func _texture_button(source: CandyEngine, caller: Object, portrait_node: Node, portrait_file: String) -> bool:
	var tex := CandyMedia.load_texture(portrait_file)
	if tex == null:
		printerr("Portrait file not found or invalid: ", portrait_file)
		return false

	portrait_node.texture_normal = tex
	portrait_node.visible = true

	#Ł Button_Textures subfolder:
	var character_folder = portrait_file.get_base_dir()
	var file_base = portrait_file.get_file().get_basename()
	var file_ext = portrait_file.get_extension().to_lower()
	var button_folder = character_folder.path_join("Button_Textures").path_join(file_base + "_" + file_ext)
	if DirAccess.dir_exists_absolute(button_folder):
		CandyUI.get_shared().apply_button_textures(source, caller, portrait_node, button_folder, file_base)
	return true

#* Sprite2D / Sprite3D sprite sheet, grid from the file name (e.g. "Happy_4x5-2.png"):
func _sprite(source: CandyEngine, caller: Object, portrait_node: Node, portrait_file: String, play: bool, config: Dictionary) -> bool:
	#@ Step 1 - Parse grid (4x5 or 4x5-2):
	var hframes := 1
	var vframes := 1
	var missing := 0
	var regex := RegEx.new()
	regex.compile("(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")
	var result := regex.search(portrait_file.get_file())
	if result:
		hframes = int(result.get_string(1))
		vframes = int(result.get_string(2))
		if result.get_string(3) != "":
			missing = int(result.get_string(3))
	hframes = max(abs(hframes), 1)
	vframes = max(abs(vframes), 1)
	missing = max(abs(missing), 0)

	var tex := CandyMedia.load_texture(portrait_file)
	if tex == null:
		printerr("Portrait file not found or invalid: ", portrait_file)
		return false

	portrait_node.texture = tex
	portrait_node.hframes = hframes
	portrait_node.vframes = vframes
	portrait_node.frame = 0
	portrait_node.visible = true

	#@ Step 2 - Scale:
	var portrait_w: float = _config(config, "portrait_w")
	var portrait_h: float = _config(config, "portrait_h")
	if portrait_w > 0 and portrait_h > 0:
		var frame_size = tex.get_size() / Vector2(hframes, vframes)
		if frame_size.x > 0.0 and frame_size.y > 0.0:
			var factor = Vector2(portrait_w, portrait_h) / frame_size
			if portrait_node is Sprite3D:
				portrait_node.scale = Vector3(factor.x, factor.y, 1.0)
			else:
				portrait_node.scale = factor

	#@ Step 3 - Animate:
	var total_frames = max(hframes * vframes - missing, 1)
	portrait_node.set_meta(SHEET_FRAMES_META, total_frames)		#/ For stop_portrait()
	var sprite_fps := CandyPlayback.get_shared().resolve_fps(source, caller, "default_sprite_fps", "",
		_config(config, "default_sprite_fps"), 0.0, portrait_file)
	if play and total_frames > 1 and sprite_fps > 0.0:
		_add_frame_timer(source, caller, portrait_node, sprite_fps, func():
			var next: int = portrait_node.frame + 1
			if next >= total_frames:
				if _loop_ended(source, caller, portrait_node):
					return
				next = 0
			portrait_node.frame = next
		)
	return true

#* VideoStreamPlayer:
func _video(source: CandyEngine, caller: Object, portrait_node: Node, portrait_file: String, play: bool, config: Dictionary) -> bool:
	var stream := CandyMedia.load_video(portrait_file)
	if stream == null:
		printerr("Portrait video not found or invalid: ", portrait_file)
		return false

	portrait_node.stream = stream
	#@ Step 1 - Frame rate, for stop frames:
	portrait_node.set_meta(VIDEO_FPS_META, CandyPlayback.get_shared().resolve_fps(source, caller, "default_video_fps", "",
		_config(config, "default_video_fps"), CandyPlayback.get_shared().video_fps(source, caller, stream), portrait_file))
	portrait_node.visible = true
	portrait_node.play()
	if not play:
		portrait_node.paused = true
		portrait_node.stream_position = 0
		return true
	#@ Step 2 - Count loops:
	_connect(portrait_node, "finished", func():
		if not _loop_ended(source, caller, portrait_node):
			portrait_node.play())
	return true

#* Run a frame animation on a Timer child of the portrait node:
func _add_frame_timer(source: CandyEngine, caller: Object, portrait_node: Node, fps: float, advance: Callable) -> void:
	_remove_frame_timer(source, caller, portrait_node)
	var timer := Timer.new()
	timer.name = FRAME_TIMER
	timer.wait_time = 1.0 / fps
	timer.autostart = true
	timer.timeout.connect(advance)
	portrait_node.add_child(timer)

#* Remove the frame animation Timer:
func _remove_frame_timer(source: CandyEngine, caller: Object, portrait_node: Node) -> void:
	var old_timer := portrait_node.get_node_or_null(FRAME_TIMER)
	if old_timer:
		old_timer.stop()
		portrait_node.remove_child(old_timer)	#/ Now, to free the name
		old_timer.queue_free()

#& Loops:
#* Count a finished loop; true when it was the last:
func _loop_ended(source: CandyEngine, caller: Object, portrait_node: Node) -> bool:
	var state = portrait_node.get_meta(LOOP_META, null)
	if not state is Dictionary:
		return false
	state["count"] = int(state["count"]) + 1
	var loops: int = state["loops"]
	if loops > 0 and int(state["count"]) >= loops:
		stop_portrait(source, caller, portrait_node, int(state["stop_frame"]), state["on_removed"])
		return true
	return false

#* Connect a portrait node signal (disconnected by _end_playback()):
func _connect(portrait_node: Node, signal_name: String, callable: Callable) -> void:
	portrait_node.connect(signal_name, callable)
	var connections: Array = portrait_node.get_meta(SIGNALS_META, [])
	connections.append([signal_name, callable])
	portrait_node.set_meta(SIGNALS_META, connections)

#* End playback (timer, signals, loop state):
func _end_playback(source: CandyEngine, caller: Object, portrait_node: Node) -> void:
	_remove_frame_timer(source, caller, portrait_node)
	for connection in portrait_node.get_meta(SIGNALS_META, []):
		if portrait_node.is_connected(connection[0], connection[1]):
			portrait_node.disconnect(connection[0], connection[1])
	portrait_node.set_meta(SIGNALS_META, null)
	portrait_node.set_meta(LOOP_META, null)

#* Portrait_Stop frame → index:
func _frame_index(stop_frame: int, count: int) -> int:
	if count <= 0:
		return 0
	if stop_frame == STOP_LAST:
		return count - 1
	return clampi(stop_frame - 1, 0, count - 1)

#* Resolve an extension setting:
func _extension(source: CandyEngine, caller: Object, config: Dictionary, setting: String) -> String:
	return CandyPlayback.get_shared().resolve_extension(source, caller, setting, _config(config, setting))

#* A 'config' setting, or its default:
func _config(config: Dictionary, key: String) -> Variant:
	if config.has(key):
		return config[key]
	return DEFAULT_CONFIG[key]
