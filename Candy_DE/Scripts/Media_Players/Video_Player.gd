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

## REQUIRED: The VideoStreamPlayer node.
@export var video_player: Node = self

var pause_count = 0
var pause_mode = "speech"
#^ Media_Pause's pause loop, if any:
var pause_loop: CandyPauseLoop = null

#^ Loop / wait tracking:
var loop_target: int = 1		#/ <0 = infinite, 0 = hold on the first frame, >0 = that many times
var loops_played: int = 0		#/ Completed loops
#^ Media_Play "Duration" tracker:
var play_duration: CandyPlayDuration = null

#^ Playback announced by the playback hooks:
#? Nothing is announced for "Loops": 0 or no playback.
var _announced: bool = false
var _announced_source = null		#/ Untyped: the engine may be freed first
var _announced_custom_data: Array = []

#^ Default extension for video files:
## Extension given to video files named without one.[br][br]
## Leave empty to inherit the engine's [code]default_video_extension[/code], and through it
## the project-wide setting in Candy_Properties.gd.
@export var default_video_extension: String = ""

#^ Fallback frame rate:
## Frame rate "f=" targets count at when a video's own frame rate can't be read from its file.[br][br]
## Leave at 0 to inherit the engine's [code]default_video_fps[/code], and through it the
## project-wide setting in Candy_Properties.gd. The video's own rate overrides this, and the
## "FPS" key on the dialogue line overrides both.
@export var default_video_fps: float = 0.0

## Default Z order.
@export var default_z = 120

var caller: Node

#^ Paused by dialogue suspension:
var _suspended: bool = false

#^ Media_Stop left it paused on a frame (only Media_Play restarts it):
var _stopped_on_frame: bool = false

#^ "Stop_Frame" used when playback ends by itself:
var end_frame: int = CandyPlayback.STOP_FRAME_CLEAR
#^ Frame rate for end_frame:
var _end_fps: float = 0.0
#^ Engine of the Media_Stop that scheduled the end, or null (its "Clear" resets the overlay):
var _end_stopper = null		#/ Untyped: the engine may be freed first
var _end_stopped: bool = false

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



func _ready():
	self.z_index = default_z

	#% video_player may not be self; don't double a scene connection:
	if video_player != null and video_player.has_signal("finished") and not video_player.finished.is_connected(_on_finished):
		video_player.finished.connect(_on_finished)


#* Accept or reject a command, taking hold if it does:
#? 'command': script file name. Returns "" if accepted, else why not.
func admit_command(engine: Node, command: String, take_hold: int = 0) -> String:
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
	if not source.suspend_video:
		return

	if video_player.is_playing() and not video_player.paused:
		video_player.paused = true
		_suspended = true			#/ So unsuspend_media() never lifts a Media_Pause


#* Resume from suspension, if suspend_media() paused it:
@warning_ignore("unused_parameter")
func unsuspend_media(candy_args: Dictionary) -> void:
	if not _suspended:
		return

	_suspended = false
	video_player.paused = false


#* Play a file (Media_Play):
func play_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> bool:
	var source: CandyEngine	= candy_args["caller"]
	var file_ref: Variant	= settings.get("File", "")
	var loop: int			= CandyPlayback.get_shared().normalize_loop(source, self, settings.get("Loops", "1"))
	var stop_frame: int		= CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""),
		CandyPlayback.STOP_FRAME_CLEAR, str(candy_args.get("command", "Media_Play")))

	#@ Step 1 - Resolve the file or stream:
	#Ł Sub-folder -the player's name on the line ("key"):
	var folder: String = candy_de.video_folder.path_join(str(candy_args.get("key", name)))
	var resolved := CandyMedia.resolve_media(file_ref, folder,
		CandyPlayback.get_shared().resolve_extension(source, self, "default_video_extension", default_video_extension))

	if not resolved["found"]:
		printerr("Media_Play: missing or invalid path → ", resolved["path"])
		return false

	#% An expression may give a loaded stream:
	var video_stream = resolved["resource"]
	if video_stream == null:
		video_stream = CandyMedia.load_video(str(resolved["path"]))

	if not (video_stream is VideoStream):
		printerr("Media_Play: invalid or missing video stream → ", file_ref)
		return false

	video_player.stream = video_stream

	visible = true

	#@ Step 2 - Adjust z-index:
	#% Only with "Box", so players on one line can't undo each other:
	if settings.has("Box"):
		CandyPlayback.get_shared().apply_overlay_z(source, self, self, settings["Box"], str(candy_args.get("command", "")))

	#@ Step 3 - Start playback:
	var duration_seconds := CandyPlayDuration.read(source, self, settings.get("Duration", "null"), true, _frame_rate(source, settings))
	end_frame = stop_frame
	_end_fps = _frame_rate(source, settings)
	_end_stopper = null
	_end_stopped = false
	await _begin_playback(source, loop, custom_data, duration_seconds)
	return true			#/ Playback started


#* Wait for a loop count and/or time (Media_Play, Media_Wait):
@warning_ignore("unused_parameter")
func wait_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> String:
	var source: CandyEngine	= candy_args["caller"]
	var wait: int			= int(settings.get("Wait_Loops", "0"))

	var target_seconds := CandyPlayback.get_shared().resolve_time_target(source, self, settings.get("Wait_Time", ""), true,
		_frame_rate(source, settings))

	return await CandyPlayback.get_shared().await_target(source, self, self, "video_player", wait, target_seconds, loop_target)


#* Pause playback (Media_Pause):
@warning_ignore("unused_parameter")
func pause_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> Tween:
	var source: CandyEngine = candy_args["caller"]
	var context := str(candy_args.get("command", "Media_Pause"))

	pause_loop = CandyPauseLoop.start(source, self, self, settings, _pause_loop_media(source, settings), context, pause_loop, "video_player")
	if pause_loop == null:
		video_player.paused = true
	CandyPlayback.get_shared().set_pause(source, self, self, int(settings.get("Lines", -1)), int(settings.get("All", 0)))
	#% Only with "Box", so players on one line can't undo each other:
	if settings.has("Box"):
		CandyPlayback.get_shared().apply_overlay_z(source, self, self, settings["Box"], str(candy_args.get("command", "")))

	if pause_loop != null:
		return pause_loop.pause_fade			#/ What a "!" Pause_Volume_Time waits on
	return null


#* Resume playback (Media_Resume):
func resume_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> Tween:
	var source: CandyEngine = candy_args["caller"]
	var fade: Tween = null

	#% Stopped on a frame - only Media_Play restarts it:
	if _stopped_on_frame:
		pass
	elif loop_target == 0 and video_player.stream != null:			#/ "Loops": 0 never started: play once
		await _begin_playback(source, 1, custom_data)
	else:
		fade = unpause(settings, source)

	#% Only with "Box", so players on one line can't undo each other:
	if settings.has("Box"):
		CandyPlayback.get_shared().apply_overlay_z(source, self, self, settings["Box"], str(candy_args.get("command", "")))

	return fade			#/ What a "!" Resume_Volume_Time waits on, or null


#* Stop the video and release waits (Media_Stop):
@warning_ignore("unused_parameter")
func stop_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine = candy_args["caller"]
	var context := str(candy_args.get("command", "Media_Stop"))
	var stop_frame := CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""),
		CandyPlayback.STOP_FRAME_CLEAR, context)

	#@ Step 1 - Schedule a "Loops" / "Duration" stop:
	var loop := CandyPlayDuration.read_stop_loop(settings.get("Loops", ""), context)
	var duration_seconds := CandyPlayDuration.read(source, self, settings.get("Duration", ""), true, _frame_rate(source, settings))

	if CandyPlayDuration.schedules(loop, duration_seconds) and media_active:
		end_frame = stop_frame
		_end_fps = _frame_rate(source, settings)
		_end_stopper = source
		_end_stopped = true
		_drop_play_duration()
		play_duration = CandyPlayDuration.schedule_stop(self, loop, duration_seconds, _play_duration_media())
		return

	#@ Step 2 - Stop now (also when not playing):
	_stop_on(source, stop_frame, _frame_rate(source, settings), -1.0, false)


#* Seek (Media_Skip):
@warning_ignore("unused_parameter")
func skip_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine = candy_args["caller"]

	if video_player.stream == null:
		printerr("Media_Skip: nothing is loaded on → ", name)
		return

	#% Pause loop playing - move the pause point:
	if pause_loop != null and pause_loop.owns_position():
		pause_loop.move_pause_point(settings.get("Time", 0.0))
		return

	video_player.stream_position = CandyPlayback.get_shared().resolve_seek_target(source, self, self, "video_player",
		settings.get("Time", 0.0), true, _frame_rate(source, settings))


#* Change the volume (Media_Volume):
@warning_ignore("unused_parameter")
func volume_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> Tween:
	#Ł Return the fade to wait on, or null:
	return CandyPlayback.get_shared().apply_volume_change(candy_args["caller"], self, self, "video_player",
		settings.get("Volume", "0.0"), settings.get("Time", "0.0"), "Media_Volume")


#* Move the dialogue UI's z-order after a Media_Wait:
@warning_ignore("unused_parameter")
func ui_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	CandyPlayback.get_shared().apply_overlay_z(candy_args["caller"], self, self, settings.get("Box", "Reset"), str(candy_args.get("command", "")))


#* Frame rate for "f=":
func _frame_rate(source: CandyEngine, settings: Dictionary) -> float:
	var file_path := ""
	if video_player.stream != null:
		file_path = str(video_player.stream.resource_path)
	return CandyPlayback.get_shared().resolve_fps(source, self, "default_video_fps", settings.get("FPS", ""),
		default_video_fps, CandyPlayback.get_shared().video_fps(source, self, video_player.stream), file_path)


#* Playback loop finished:
func _on_finished() -> void:
	#% Return if loop is a pause loop:
	if pause_loop != null and pause_loop.media_ended():
		return

	loops_played += 1

	#¦ 1. Replay:
	if loop_target < 0 or (loop_target > 0 and loops_played < loop_target):
		video_player.play()
		return

	#¦ 2. Playback finished:
	_end_playback(-1.0)


#* End playback by itself, on end_frame:
#? 'at': seconds into the current loop, -1.0 = at its end.
func _end_playback(at: float) -> void:
	var stop_frame := end_frame
	#% At its end the video has stopped, so frame 0 is its last frame:
	if stop_frame == 0 and at < 0.0:
		stop_frame = -1

	var stopper = null
	if _end_stopped and is_instance_valid(_end_stopper):
		stopper = _end_stopper
	_stop_on(stopper, stop_frame, _end_fps, at, not _end_stopped)


#* Stop on a "Stop_Frame", releasing waits:
#? 'source': the Media_Stop's engine, or null. 'ended': reached its end by itself, else stopped.
func _stop_on(source: Variant, stop_frame: int, fps: float, at: float, ended: bool) -> void:
	_drop_pause_loop()
	_drop_play_duration()

	#% Clearing, or nothing loaded - hide, unload, reset the Media_Stop's UI z-order:
	if stop_frame == CandyPlayback.STOP_FRAME_CLEAR or video_player.stream == null:
		reset(ended)
		if source != null:
			CandyPlayback.get_shared().apply_overlay_z(source, self, self, "Reset", "Media_Stop")
		return

	#@ Step 1 - Freeze the picture:
	#? A frame must be decoded to show, so play first.
	if not video_player.is_playing():
		video_player.play()
	video_player.paused = true

	#@ Step 2 - Seek to the frame:
	#? 0 = the one at 'at' (-1.0 = current), -1 = last, N > 0 = frame N from 1.
	var frame_length := 1.0 / maxf(fps, 0.001)
	var last_time := maxf(float(video_player.get_stream_length()) - frame_length, 0.0)
	if stop_frame == -1:
		video_player.stream_position = last_time
	elif stop_frame > 0:
		video_player.stream_position = clampf(float(stop_frame - 1) * frame_length, 0.0, last_time)
	elif at >= 0.0:
		video_player.stream_position = at

	#@ Step 3 - End playback, keep the picture:
	loops_played = 0
	loop_target = 1
	_suspended = false
	pause_count = 0
	pause_mode = "speech"
	_stopped_on_frame = true
	end_frame = CandyPlayback.STOP_FRAME_CLEAR
	_end_stopper = null
	_end_stopped = false

	#Ł Release waits and hold:
	media_active = false
	release_hold()

	_playback_finished(ended)


#* Clear pause state:
func unpause(resume_settings: Dictionary = {}, source: CandyEngine = null) -> Tween:
	var fade: Tween = null
	if pause_loop != null:
		fade = pause_loop.resume(source, resume_settings)			#/ Media_Resume's entry, {} = the pause's own

	#% Stopped on a frame - stay paused until Media_Play:
	if not _stopped_on_frame:
		video_player.paused = false

	pause_count = 0
	pause_mode = "speech"
	return fade			#/ What a "!" Resume_Volume_Time waits on, or null


#* Clear playback state and dialogue waits:
#? 'ended': reached its end by itself, else stopped.
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

	#@ Step 1 - Stop and release the stream:
	video_player.stop()
	video_player.stream = null
	video_player.paused = false
	_stopped_on_frame = false

	#@ Step 2 - Loop tracking:
	loops_played = 0
	loop_target = 1
	end_frame = CandyPlayback.STOP_FRAME_CLEAR
	_end_stopper = null
	_end_stopped = false

	#@ Step 3 - Dialogue suspension:
	_suspended = false

	#@ Step 4 - Pause bookkeeping:
	pause_count = 0
	pause_mode = "speech"

	#@ Step 5 - Display:
	self.visible = false


#* Start playback between the playback hooks:
func _begin_playback(source: CandyEngine, loop: int, custom_data: Array, duration_seconds: float = 0.0) -> void:
	var start_loop := CandyPlayDuration.play_loop(loop, duration_seconds)

	#Ł Lift a Media_Stop hold, so begin_playback() can unpause:
	_stopped_on_frame = false

	if start_loop != 0:
		await candy_de.run_node_hook(self, "x_playback_starting", {"caller": source, "node": self}, custom_data)

	_drop_pause_loop()
	_drop_play_duration()
	CandyPlayback.get_shared().begin_playback(source, self, self, "video_player", start_loop)
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
#? 'ended': reached its end by itself, else stopped.
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
		"position": func() -> float:
			return video_player.stream_position,
		"length": func() -> float:			#/ Read live: Theora reports none until playback starts
			return video_player.get_stream_length(),
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
func _pause_loop_media(source: CandyEngine, settings: Dictionary) -> Dictionary:
	return {
		"active": media_active and video_player.stream != null and not _stopped_on_frame,
		"position": func() -> float:
			return video_player.stream_position,
		"length": func() -> float:
			return video_player.get_stream_length(),
		"time": func(text: String, base: float) -> float:
			return CandyPlayback.get_shared().resolve_relative_time(source, self, base, text, true, _frame_rate(source, settings)),
		"play_from": func(time: float) -> void:
			if not video_player.is_playing():
				video_player.play()
			#Ł Stay paused if suspended:
			video_player.paused = _suspended
			video_player.stream_position = time,
		"run": func() -> void:
			if not _suspended:
				video_player.paused = false,
	}


#* Cancel the pause loop, restoring volume:
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
