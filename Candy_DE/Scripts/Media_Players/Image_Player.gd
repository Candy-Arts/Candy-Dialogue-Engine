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

## REQUIRED: The node that displays images:[br][br]
## TextureRect, TextureButton, NinePatchRect, Sprite2D/3D, AnimatedSprite2D/3D.
@export var image_player: Node = self

var pause_count = 0
var pause_mode = "speech"
#^ Media_Pause's pause loop, if any:
var pause_loop: CandyPauseLoop = null

#^ Loop / wait tracking:
var loop_target: int = 1		#/ <0 = infinite, 0 = hold on the first frame, >0 = that many times
var loops_played: int = 0		#/ Completed loops
#^ Media_Play "Duration" tracker:
var play_duration: CandyPlayDuration = null
#^ "Stop_Frame" used when playback ends by itself:
var end_frame: int = CandyPlayback.STOP_FRAME_CLEAR
#^ Engine of the Media_Stop that scheduled the end, or null (its "Clear" resets the overlay):
var _end_stopper = null		#/ Untyped: the engine may be freed first
var _end_stopped: bool = false

#^ Playback announced by the playback hooks:
#? Nothing is announced for "Loops": 0 or no playback.
var _announced: bool = false
var _announced_source = null		#/ Untyped: the engine may be freed first
var _announced_custom_data: Array = []

#^ Animation / timing state:
#? Frame folder stream (see CandyFrameStream); null for a static image:
var frame_stream: CandyFrameStream = null
var fps: float = 0.0
var frame_index: int = 0
var animated: bool = false
var static_duration: float = 0.0		#/ Static image "Duration", 0 = until stopped

#^ Static image's Media_Skip position (the timer only runs the rest):
var _skip_offset: float = 0.0

#^ Default file extension for images:
## Extension given to image files named without one.[br][br]
## Leave empty to inherit the engine's [code]default_image_extension[/code], and through it
## the project-wide setting in Candy_Properties.gd.
@export var default_image_extension: String = ""

#^ Default frame rate for folder animations:
## Frame rate for folder animations played through this node.[br][br]
## Leave at 0 to inherit the engine's [code]default_animated_image_fps[/code], and through it
## the project-wide setting in Candy_Properties.gd.[br]
## A "config.txt" in the animation's own folder overrides this, and the "FPS" key on
## the dialogue line overrides both.
@export var default_animated_image_fps: float = 0.0

#^ Animation folder memory (see Candy_Properties.gd):
## Memory budget of one animation folder, in MB: one whose frames fit in it keeps every frame
## loaded while it plays, one that doesn't is streamed. 0 streams every animation.[br][br]
## Leave at -1 to inherit the engine's [code]animation_folder_cache[/code], and through it
## the project-wide setting in Candy_Properties.gd. A config.txt ("cache") overrides this.
@export var animation_folder_cache: int = -1
## While an animation folder is streamed, how many frames are loaded ahead.[br][br]
## Leave at -1 to inherit the engine's [code]animation_folder_stream[/code], and through it
## the project-wide setting in Candy_Properties.gd. A config.txt ("stream") overrides this.
@export var animation_folder_stream: int = -1

## Default Z order.
@export var default_z = 120

var caller: Node

#^ Paused by dialogue suspension:
var _suspended: bool = false

#^ Access:
@export_group("Access")
## [b]Private[/b]: only the engine that owns this player can command it - the engine whose
## media_players_paths lists it as owned.[br]
## [b]Public[/b]: any engine can, as Public Mode allows.[br][br]
## The Unrestricted Commands are accepted from any engine either way.
@export_enum("Private", "Public") var access: int = 0
## Public players only. While an engine holds this player (it started what the player is playing):[br]
## [b]Exclusive[/b]: other engines' commands are rejected.[br]
## [b]Semi-Exclusive[/b]: other engines may only send the Semi-Exclusive Commands.[br]
## [b]Free[/b]: other engines may send any command, and one that takes hold takes the player over.
@export_enum("Exclusive", "Semi-Exclusive", "Free") var public_mode: int = 0
## Commands other engines may still send to this player while it is Semi-Exclusive and held.
@export var semi_exclusive_commands: Array[String] = ["Media_Pause", "Media_Resume", "Media_Stop", "Media_Volume", "Media_Skip"]
## Commands that make the engine sending them hold this player, when it is Public.[br]
## A line's "Take_Hold" key overrides this: 1 takes hold anyway, -1 never does.
@export var hold_commands: Array[String] = ["Media_Play"]
## Commands accepted from any engine, whether this player is Private or Public, held or not:
## they don't act on the player itself, only on the engine's dialogue and UI around it.
@export var unrestricted_commands: Array[String] = ["Media_Wait", "Effect_Wait"]

#^ Held player overrides:
@export_group("Held Player Overrides")
## Let this player override whether the engine holding it suspends it with its dialogue.[br]
## Overrides the engine's setting and Candy_Properties.gd. A Private player is always
## suspended by its owner, so this only matters when it is Public.
@export var enable_suspend_held_media: bool = false
## Whether the engine holding this player suspends it along with its dialogue.
@export var suspend_held_media: bool = true
## Let this player override whether the engine holding it stops it when its dialogue ends.[br]
## Overrides the engine's setting and Candy_Properties.gd. A Private player is always
## stopped by its owner, so this only matters when it is Public.
@export var enable_end_held_media: bool = false
## Whether the engine holding this player stops it when its dialogue ends. If not, the
## player keeps playing and the engine lets go of it.
@export var end_held_media: bool = true
@export_group("")

#^ Owning engine (Private):
var owner_engine: Node = null
#^ Holding engine (Public), or null:
var holder: Node = null
#^ Engine whose Media_Pause set pause_count:
var pause_engine: Node = null
#^ Playback the dialogue may wait on is running:
var media_active: bool = false

#^ Display timer:
@onready var timer: Timer = get_node_or_null("Timer")



func _ready():
	self.z_index = default_z


#* Accept a command (""), or say why not, taking hold if it does:
func admit_command(engine: Node, command: String, take_hold: int = 0) -> String:
	#Ł Script file name, case-insensitive:
	var command_key := command.to_lower()

	#@ Step 1 - Unrestricted commands:
	if _lists_command(unrestricted_commands, command_key):
		return ""

	#@ Step 2 - Private (owner only):
	if access == 0:
		if owner_engine == null or not is_instance_valid(owner_engine):
			return "it is Private and no engine owns it. Set its Access to Public, or list it as owned in an engine's media_players_paths"
		if engine != owner_engine:
			return "it is Private to " + str(owner_engine.name)
		caller = engine
		return ""

	#@ Step 3 - Public (check another engine's hold):
	if holder != null and is_instance_valid(holder) and holder != engine:
		if public_mode == 0:
			return "it is Exclusive and held by " + str(holder.name)
		if public_mode == 1 and not _lists_command(semi_exclusive_commands, command_key):
			return "it is Semi-Exclusive and held by " + str(holder.name) + ", which only lets other engines send " + ", ".join(semi_exclusive_commands)

	caller = engine

	#@ Step 4 - Take hold:
	#? 'take_hold': 1 = take hold, -1 = never, 0 = hold_commands decide.
	if take_hold == 1 or (take_hold == 0 and _lists_command(hold_commands, command_key)):
		_take_hold(engine)

	return ""


#* Take hold for 'engine':
func _take_hold(engine: Node) -> void:
	if holder == engine:
		return

	release_hold()
	holder = engine
	if not (self in engine.held_media_players):
		engine.held_media_players.append(self)


#* Release the holding engine:
func release_hold() -> void:
	if holder != null and is_instance_valid(holder):
		holder.held_media_players.erase(self)
		#Ł Lift its suspension:
		unsuspend_media({"caller": holder})

	holder = null


#* Whether a list has a command, ignoring case:
func _lists_command(list: Array[String], command_key: String) -> bool:
	for entry in list:
		if entry.to_lower() == command_key:
			return true
	return false


#* Pause for dialogue suspension:
func suspend_media(candy_args: Dictionary) -> void:
	var source: CandyEngine = candy_args["caller"]
	if not source.suspend_images:
		return

	#% Tracked, so unsuspend_media() never lifts a Media_Pause:
	if timer != null and not timer.is_stopped() and not timer.paused:
		timer.paused = true
		_suspended = true


#* Resume from suspension, if suspend_media() paused it:
@warning_ignore("unused_parameter")
func unsuspend_media(candy_args: Dictionary) -> void:
	if not _suspended:
		return

	_suspended = false
	timer.paused = false


#* Show a file (Media_Play):
func play_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> bool:
	var source: CandyEngine	= candy_args["caller"]
	var file_ref: Variant	= settings.get("File", "")
	var animated_mode: int	= int(settings.get("Animated", -1))
	var duration_raw: Variant = settings.get("Duration", "null")
	var fps_raw: Variant	= settings.get("FPS", "")
	var loop: int			= CandyPlayback.get_shared().normalize_loop(source, self, settings.get("Loops", "1"))
	var stop_frame: int		= CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""),
		CandyPlayback.STOP_FRAME_CLEAR, str(candy_args.get("command", "Media_Play")))
	var duration_seconds := 0.0

	#@ Step 1 - Resolve the file, frame folder or texture:
	#? "key": the player's name on the line, also its image_folder sub-folder.
	var folder: String = candy_de.image_folder.path_join(str(candy_args.get("key", name)))
	var resolved := CandyMedia.resolve_media(file_ref, folder,
		CandyPlayback.get_shared().resolve_extension(source, self, "default_image_extension", default_image_extension))

	if not resolved["found"]:
		printerr("Media_Play: missing or invalid path → ", resolved["path"])
		return false

	#% Animated unset - a folder animates, a file doesn't:
	if animated_mode < 0:
		if bool(resolved["is_folder"]):
			animated_mode = 1
		else:
			animated_mode = 0

	#@ Step 2 - Set up image / animation:
	if animated_mode == 1:
		if not bool(resolved["is_folder"]):
			printerr("Media_Play: animation folder not found → ", resolved["path"])
			return false

		var animation_path := str(resolved["path"])

		#Ł FPS (properties → engine → player → media folder config.txt → animation config.txt → line):
		setup_animation(animation_path, CandyPlayback.get_shared().resolve_fps(source, self, "default_animated_image_fps", fps_raw,
			default_animated_image_fps, CandyMedia.read_config_fps(animation_path), animation_path), loop, source)

		#% Empty folder - would show a blank rect and end the loop:
		if _frame_count() == 0:
			printerr("Media_Play: no frames found in → ", animation_path)
			return false

		duration_seconds = CandyPlayDuration.read(source, self, duration_raw, true, fps)

	elif animated_mode == 0:
		#% An expression may give a loaded texture:
		var image_tex = resolved["resource"]
		if image_tex == null:
			image_tex = CandyMedia.load_texture(str(resolved["path"]))

		if not (image_tex is Texture2D):
			printerr("Media_Play: missing or invalid path → ", resolved["path"])
			return false

		#% No frames or loops - "Duration" is the whole display time:
		var duration_text := str(duration_raw).strip_edges().to_lower()
		if duration_text.begins_with("f=") or duration_text.begins_with("f+") or duration_text.begins_with("f-"):
			printerr(str(candy_args.get("command", "Media_Play")), ": '", str(duration_raw), "' on ", name,
				" - a static image has no frames to count. Give a time instead.")
		else:
			duration_seconds = CandyPlayDuration.read(source, self, duration_raw, false)

		#Ł Loop count for a static image:
		var static_loop := 1
		if duration_seconds <= 0.0:
			static_loop = 0
		elif loop < 0:
			static_loop = -1
		loop = static_loop
		setup_static_texture(image_tex, duration_seconds, loop)
		duration_seconds = 0.0		#/ Its timer ends it

	visible = true

	#@ Step 3 - Adjust z-index:
	#% Only with "Box", so players on one line can't undo each other:
	if settings.has("Box"):
		CandyPlayback.get_shared().apply_overlay_z(source, self, self, settings["Box"], str(candy_args.get("command", "")))

	#@ Step 4 - Start playback:
	end_frame = stop_frame
	_end_stopper = null
	_end_stopped = false
	await _begin_playback(source, loop, custom_data, duration_seconds)
	return true		#/ Playback started


#* Wait for a loop count and/or time (Media_Play, Media_Wait):
@warning_ignore("unused_parameter")
func wait_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> String:
	var source: CandyEngine	= candy_args["caller"]
	var wait: int			= int(settings.get("Wait_Loops", "0"))

	var target_seconds := CandyPlayback.get_shared().resolve_time_target(source, self, settings.get("Wait_Time", "0"), true, fps)

	return await CandyPlayback.get_shared().await_target(source, self, self, "image_player", wait, target_seconds, loop_target)


#* Pause the display timer (Media_Pause):
@warning_ignore("unused_parameter")
func pause_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> Tween:
	var source: CandyEngine = candy_args["caller"]
	var context := str(candy_args.get("command", "Media_Pause"))

	pause_loop = CandyPauseLoop.start(source, self, self, settings, _pause_loop_media(source), context, pause_loop)
	if pause_loop == null and timer != null:
		timer.paused = true
	CandyPlayback.get_shared().set_pause(source, self, self, int(settings.get("Lines", -1)), int(settings.get("All", 0)))
	#% Only with "Box", so players on one line can't undo each other:
	if settings.has("Box"):
		CandyPlayback.get_shared().apply_overlay_z(source, self, self, settings["Box"], str(candy_args.get("command", "")))

	return null		#/ No volume fade


#* Resume the display timer (Media_Resume):
func resume_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> Tween:
	var source: CandyEngine = candy_args["caller"]

	#% "Loops" = 0 never started - play once:
	#? A held static image (no "Duration") stays: playing would only remove it.
	if loop_target == 0 and visible:
		if (animated and _frame_count() > 0) or (not animated and static_duration > 0.0):
			await _begin_playback(source, 1, custom_data)
	else:
		unpause(settings, source)

	#% Only with "Box", so players on one line can't undo each other:
	if settings.has("Box"):
		CandyPlayback.get_shared().apply_overlay_z(source, self, self, settings["Box"], str(candy_args.get("command", "")))

	return null		#/ No volume fade


#* Stop the image and release waits (Media_Stop):
@warning_ignore("unused_parameter")
func stop_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine = candy_args["caller"]
	var context := str(candy_args.get("command", "Media_Stop"))
	var stop_frame := CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""),
		CandyPlayback.STOP_FRAME_CLEAR, context)

	#@ Step 1 - Schedule a "Loops" / "Duration" stop:
	var duration_raw: Variant = settings.get("Duration", "")
	var loop := -1
	var duration_seconds := 0.0
	if animated:
		loop = CandyPlayDuration.read_stop_loop(settings.get("Loops", ""), context)
		duration_seconds = CandyPlayDuration.read(source, self, duration_raw, true, fps)
	else:
		#% No frames or loops - "Duration" is the whole display time:
		var duration_text := str(duration_raw).strip_edges().to_lower()
		if duration_text.begins_with("f=") or duration_text.begins_with("f+") or duration_text.begins_with("f-"):
			printerr(context, ": '", str(duration_raw), "' on ", name, " - a static image has no frames to count. Give a time instead.")
		else:
			duration_seconds = CandyPlayDuration.read(source, self, duration_raw, false)

	if CandyPlayDuration.schedules(loop, duration_seconds) and media_active:
		end_frame = stop_frame
		_end_stopper = source
		_end_stopped = true
		_drop_play_duration()
		play_duration = CandyPlayDuration.schedule_stop(self, loop, duration_seconds, _play_duration_media())
		return

	#@ Step 2 - Stop now:
	_stop_on(source, stop_frame, -1.0, false)


#* End playback by itself, on end_frame:
#? 'at': seconds into the current loop, -1.0 = at its end.
func _end_playback(at: float) -> void:
	var stop_frame := end_frame
	#% At its end, frame_index wrapped to 0 with the last frame showing, so frame 0 means that one:
	if stop_frame == 0 and at < 0.0:
		stop_frame = -1

	var stopper = null
	if _end_stopped and is_instance_valid(_end_stopper):
		stopper = _end_stopper
	_stop_on(stopper, stop_frame, at, not _end_stopped)


#* Stop on a "Stop_Frame", releasing waits:
func _stop_on(source: Variant, stop_frame: int, at: float, ended: bool) -> void:
	_drop_pause_loop()
	_drop_play_duration()

	#% Clearing, or nothing shown:
	#? With 'source' (the Media_Stop's engine), also resets the UI z-order.
	if stop_frame == CandyPlayback.STOP_FRAME_CLEAR or not visible:
		reset(ended)
		if source != null:
			CandyPlayback.get_shared().apply_overlay_z(source, self, self, "Reset", "Media_Stop")
		return

	#@ Step 1 - Stop the display timer:
	if timer != null:
		timer.stop()
		timer.paused = false

	#@ Step 2 - Show the frame:
	#? 0 = the one at 'at' (-1.0 = current), -1 = last, N > 0 = frame N from 1. A static image stays.
	if animated and _frame_count() > 0 and (stop_frame != 0 or at >= 0.0):
		if stop_frame == -1:
			frame_index = _frame_count() - 1
		elif stop_frame > 0:
			frame_index = clampi(stop_frame - 1, 0, _frame_count() - 1)
		else:
			frame_index = clampi(int(at * fps), 0, _frame_count() - 1)
		_show_frame(frame_index, true)

	#@ Step 3 - End playback, keep the image:
	#? loop_target 1, so Media_Resume doesn't treat it as a "Loops": 0 hold.
	loops_played = 0
	loop_target = 1
	_suspended = false
	pause_count = 0
	pause_mode = "speech"
	end_frame = CandyPlayback.STOP_FRAME_CLEAR
	_end_stopper = null
	_end_stopped = false

	#Ł Release waits and hold:
	media_active = false
	release_hold()

	_playback_finished(ended)


#* Seek within the current loop (Media_Skip):
@warning_ignore("unused_parameter")
func skip_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine = candy_args["caller"]

	var cycle_length := get_media_length()
	if cycle_length <= 0.0:
		printerr("Media_Skip: nothing to skip through on → ", name)
		return

	#% Pause loop playing - move the pause point:
	if pause_loop != null and pause_loop.owns_position():
		pause_loop.move_pause_point(settings.get("Time", 0.0))
		return

	var target_time := clampf(CandyPlayback.get_shared().resolve_seek_target(source, self, self, "image_player",
		settings.get("Time", 0.0), true, fps), 0.0, cycle_length)

	#% Only restart a running timer (Timer.start() keeps a paused one paused):
	var running: bool = timer != null and not timer.is_stopped()

	if animated:
		#Ł Lands on the start of a frame:
		frame_index = mini(int(target_time * fps), _frame_count() - 1)
		_show_frame(frame_index, true)
		if running:
			start_frame_timer()
	else:
		_skip_offset = target_time
		if running:
			timer.start(max(static_duration - target_time, 0.001))


#* Move the dialogue UI's z-order after a Media_Wait:
@warning_ignore("unused_parameter")
func ui_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	CandyPlayback.get_shared().apply_overlay_z(candy_args["caller"], self, self, settings.get("Box", "Reset"), str(candy_args.get("command", "")))


#* Set up a static image:
func setup_static(path: String, duration: float, loop) -> void:
	setup_static_texture(CandyMedia.load_texture(path), duration, loop)


#* Set up a static image from a loaded texture:
func setup_static_texture(tex: Texture2D, duration: float, loop) -> void:
	_reset_state()

	loop_target = loop
	animated = false
	static_duration = max(duration, 0.0)

	_set_image_texture(tex)


#* Set up a folder animation:
#? 'fps_value': already resolved.
func setup_animation(anim_folder: String, fps_value: float, loop, source: CandyEngine = null) -> void:
	_reset_state()

	loop_target = loop
	animated = true

	fps = max(fps_value, 0.001)

	if not DirAccess.dir_exists_absolute(anim_folder):
		printerr("Image animation folder not found → ", anim_folder)
		return

	#Ł A TextureButton's state folders play along:
	#? Only the first frame loads now (see CandyFrameStream).
	frame_stream = CandyFrameStream.open(source, self, anim_folder, animation_folder_cache, animation_folder_stream, image_player)

	if _frame_count() > 0:
		_show_frame(0, true)


#* Start playback:
func start() -> void:
	if animated:
		start_frame_timer()
	else:
		start_static_timer()


#* Static image timer (one loop):
func start_static_timer() -> void:
	if timer == null:
		on_cycle_finished.call_deferred()
		return

	timer.stop()
	_skip_offset = 0.0

	#% Nothing to wait for:
	if static_duration <= 0.0:
		on_cycle_finished.call_deferred()
		return

	timer.wait_time = static_duration
	timer.start()


#* Frame timer (animated):
func start_frame_timer() -> void:
	if timer == null:
		on_cycle_finished.call_deferred()
		return

	timer.stop()

	if fps <= 0.0 or _frame_count() == 0:
		on_cycle_finished.call_deferred()
		return

	timer.wait_time = 1.0 / fps
	timer.start()


func _on_timer_timeout() -> void:
	if animated:
		frame_index += 1
		if frame_index >= _frame_count():
			frame_index = 0
			on_cycle_finished()
			return
		#Ł A frame not loaded in time is skipped:
		_show_frame(frame_index, false)
		start_frame_timer()
	else:
		on_cycle_finished()


#* Playback loop finished:
func on_cycle_finished() -> void:
	#% Return if loop is a pause loop:
	if pause_loop != null and pause_loop.media_ended():
		return

	loops_played += 1

	#% Nothing to replay (no frames, or no static duration) - would loop forever:
	if (animated and _frame_count() == 0) or (not animated and static_duration <= 0.0):
		reset(true)
		return

	if loop_target < 0 or (loop_target > 0 and loops_played < loop_target):
		if animated:
			frame_index = 0
			_show_frame(0, true)
			start_frame_timer()
		else:
			start_static_timer()
		return

	#Ł Done - end on end_frame:
	_end_playback(-1.0)


#* Clear pause state:
func unpause(resume_settings: Dictionary = {}, source: CandyEngine = null) -> Tween:
	#% Pause loop - 'resume_settings' is Media_Resume's entry ({} = the pause's own):
	if pause_loop != null:
		pause_loop.resume(source, resume_settings)

	if timer != null:
		timer.paused = false

	pause_count = 0
	pause_mode = "speech"
	return null		#/ No volume fade


#* Clear playback state and dialogue waits:
func reset(ended: bool = false) -> void:
	_reset_state()

	#Ł Release waits and hold:
	media_active = false
	release_hold()

	_playback_finished(ended)


#* Clear this player's state:
func _reset_state() -> void:
	_drop_pause_loop()
	_drop_play_duration()

	#@ Step 1 - Stop the display timer:
	if timer != null:
		timer.stop()
		timer.paused = false

	#@ Step 2 - Animation / timing state:
	if frame_stream != null:
		frame_stream.close()
	frame_stream = null
	frame_index = 0
	fps = 0.0
	animated = false
	static_duration = 0.0
	_skip_offset = 0.0

	#@ Step 3 - Loop tracking:
	loops_played = 0
	loop_target = 1
	end_frame = CandyPlayback.STOP_FRAME_CLEAR
	_end_stopper = null
	_end_stopped = false

	#@ Step 4 - Dialogue suspension:
	_suspended = false

	#@ Step 5 - Pause bookkeeping:
	pause_count = 0
	pause_mode = "speech"

	#@ Step 6 - Display:
	_set_image_texture(null)
	_clear_button_slots()
	visible = false


#* Show frame 'index', with a TextureButton's state frames:
func _show_frame(index: int, now: bool) -> void:
	if image_player == null or frame_stream == null:
		return
	#? 'now' = load at once (jumps); else a late frame is skipped.
	if now:
		frame_stream.show_frame_now(image_player, index)
	else:
		frame_stream.show_frame(image_player, index)


#* Clear a TextureButton's state textures:
func _clear_button_slots() -> void:
	if not (image_player is TextureButton):
		return
	image_player.texture_pressed = null
	image_player.texture_hover = null
	image_player.texture_disabled = null
	image_player.texture_focused = null
	image_player.texture_click_mask = null


#* Set the image player's texture:
func _set_image_texture(tex) -> void:
	if image_player == null:
		return
	if "texture" in image_player:
		image_player.texture = tex
	elif "texture_normal" in image_player:
		image_player.texture_normal = tex


#* Position in the current playback loop, in seconds:
func get_media_position() -> float:
	var elapsed: float = 0.0
	if timer != null and not timer.is_stopped() and timer.wait_time > 0.0:
		elapsed = clampf(timer.wait_time - timer.time_left, 0.0, timer.wait_time)

	if animated:
		if fps <= 0.0:
			return 0.0
		return (float(frame_index) / fps) + elapsed		#/ Frames elapsed + time into the current frame

	return _skip_offset + elapsed		#/ After any Media_Skip


#* Length of one playback loop, in seconds (0.0 = ends at once):
func get_media_length() -> float:
	if animated:
		if fps <= 0.0:
			return 0.0
		return float(_frame_count()) / fps

	return static_duration


#* Frame count, 0 for none:
func _frame_count() -> int:
	if frame_stream == null:
		return 0
	return frame_stream.count()


#* Start playback between the playback hooks:
func _begin_playback(source: CandyEngine, loop: int, custom_data: Array, duration_seconds: float = 0.0) -> void:
	var start_loop := CandyPlayDuration.play_loop(loop, duration_seconds)

	if start_loop != 0:
		await candy_de.run_node_hook(self, "x_playback_starting", {"caller": source, "node": self}, custom_data)

	_drop_pause_loop()
	_drop_play_duration()
	CandyPlayback.get_shared().begin_playback(source, self, self, "image_player", start_loop)
	play_duration = CandyPlayDuration.start(self, loop, duration_seconds, _play_duration_media())

	#Ł Track for x_playback_finished():
	#? "Loops": 0 is no playback: end the one it replaces.
	if start_loop == 0:
		_playback_finished(false)
	else:
		_announced = true
		_announced_source = source
		_announced_custom_data = custom_data

	if start_loop != 0:
		await candy_de.run_node_hook(self, "x_playback_started", {"caller": source, "node": self}, custom_data)


#* Run x_playback_finished(), if the playback was announced:
func _playback_finished(ended: bool) -> void:
	if not _announced:
		return

	var source = null
	if is_instance_valid(_announced_source):
		source = _announced_source
	var custom_data := _announced_custom_data

	_announced = false
	_announced_source = null
	_announced_custom_data = []

	candy_de.run_node_hook(self, "x_playback_finished", {"caller": source, "node": self, "ended": ended}, custom_data)


#* Callables for CandyPlayDuration.start():
func _play_duration_media() -> Dictionary:
	return {
		"position": get_media_position,
		"length": get_media_length,
		"loops": func() -> int:
			return loops_played,
		"set_loops": func(count: int) -> void:
			loop_target = count,
		"end": func(at: float) -> void:
			_end_playback(at),
		"active": func() -> bool:
			return media_active,
		"held": func() -> bool:
			return pause_loop != null and pause_loop.owns_position(),
	}


#* Drop the Duration tracker:
func _drop_play_duration() -> void:
	if play_duration != null:
		play_duration.cancel()
	play_duration = null


#* Callables for CandyPauseLoop.start():
func _pause_loop_media(source: CandyEngine) -> Dictionary:
	var reason := ""
	if visible and not animated:
		reason = "a static image has nothing to loop"
	return {
		"active": media_active and animated and _frame_count() > 0,		#/ Animations only
		"reason": reason,
		"position": get_media_position,
		"length": get_media_length,
		"time": func(text: String, base: float) -> float:
			return CandyPlayback.get_shared().resolve_relative_time(source, self, base, text, true, fps),
		"play_from": func(time: float) -> void:
			if _frame_count() == 0:
				return
			frame_index = clampi(int(time * fps), 0, _frame_count() - 1)
			_show_frame(frame_index, true)
			if timer != null:
				start_frame_timer()
				#Ł Stay paused if suspended:
				timer.paused = _suspended,
		"run": func() -> void:
			if timer != null and not _suspended:
				timer.paused = false,
	}


#* Cancel the pause loop:
func _drop_pause_loop() -> void:
	if pause_loop != null:
		pause_loop.cancel()
	pause_loop = null


#* Hook - before playback starts (Media_Play, or Media_Resume after "Loops" = 0):
@warning_ignore("unused_parameter")
func x_playback_starting(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook - after playback starts:
@warning_ignore("unused_parameter")
func x_playback_started(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook - after playback ends or is stopped:
#? Not called when a new Media_Play replaces it.
#! Not awaited.
@warning_ignore("unused_parameter")
func x_playback_finished(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass
