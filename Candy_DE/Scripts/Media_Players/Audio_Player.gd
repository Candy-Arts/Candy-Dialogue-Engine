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

## REQUIRED: The AudioStreamPlayer Node
@export var audio_player: Node = self

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
#^ A Media_Stop scheduled that end:
var _end_stopped: bool = false

#^ Playback announced by the playback hooks:
#? Nothing is announced for "Loops": 0 or no playback.
var _announced: bool = false
var _announced_source = null		#/ Untyped: the engine may be freed first
var _announced_custom_data: Array = []

#^ Default extension for audio files:
## Extension given to audio files named without one.[br][br]
## Leave empty to inherit the engine's [code]default_audio_extension[/code], and through it
## the project-wide setting in Candy_Properties.gd.
@export var default_audio_extension: String = ""

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



func _ready() -> void:
	#% audio_player may not be self; don't double a scene connection:
	if audio_player != null and audio_player.has_signal("finished") and not audio_player.finished.is_connected(_on_finished):
		audio_player.finished.connect(_on_finished)


#* Accept or reject a command, taking hold if it does:
#? 'command': script file name. Returns "" if accepted, else why not.
func admit_command(engine: Node, command: String, take_hold: int = 0) -> String:
	var command_key := command.to_lower()

	#@ Step 1 - Unrestricted commands:
	if _lists_command(unrestricted_commands, command_key):
		return ""

	#@ Step 2 - Private, owner only:
	if access == 0:
		if owner_engine == null or not is_instance_valid(owner_engine):
			return "it is Private and no engine owns it. Set its Access to Public, or list it as owned in an engine's media_players_paths"
		if engine != owner_engine:
			return "it is Private to " + str(owner_engine.name)
		caller = engine
		return ""

	#@ Step 3 - Public, check another engine's hold:
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
	if not source.suspend_audio:
		return

	if audio_player.playing and not audio_player.stream_paused:
		audio_player.stream_paused = true
		_suspended = true			#/ So unsuspend_media() never lifts a Media_Pause


#* Resume from suspension, if suspend_media() paused it:
@warning_ignore("unused_parameter")
func unsuspend_media(candy_args: Dictionary) -> void:
	if not _suspended:
		return

	_suspended = false
	audio_player.stream_paused = false


#* Play a file (Media_Play):
func play_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> bool:
	var source: CandyEngine	= candy_args["caller"]
	var file_ref: Variant	= settings.get("File", "")
	var loop: int			= CandyPlayback.get_shared().normalize_loop(source, self, settings.get("Loops", "1"))
	var stop_frame: int		= CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""),
		CandyPlayback.STOP_FRAME_CLEAR, str(candy_args.get("command", "Media_Play")))

	var duration_seconds := 0.0
	if not _is_frame_target(settings.get("Duration", "null"), str(candy_args.get("command", "Media_Play"))):
		duration_seconds = CandyPlayDuration.read(source, self, settings.get("Duration", "null"), false)

	#@ Step 1 - Resolve the file or stream:
	#? Sub-folder - the player's name on the line ("key").
	var folder: String = candy_de.audio_folder.path_join(str(candy_args.get("key", name)))
	var resolved := CandyMedia.resolve_media(file_ref, folder,
		CandyPlayback.get_shared().resolve_extension(source, self, "default_audio_extension", default_audio_extension))

	if not resolved["found"]:
		printerr("Media_Play: missing or invalid path → ", resolved["path"])
		return false

	#% An expression may give a loaded stream:
	var audio_stream = resolved["resource"]
	if audio_stream == null:
		audio_stream = CandyMedia.load_audio(str(resolved["path"]))

	if not (audio_stream is AudioStream):
		printerr("Media_Play: invalid or missing audio stream → ", file_ref)
		return false

	audio_player.stream = audio_stream

	#@ Step 2 - Start playback:
	end_frame = stop_frame
	_end_stopped = false
	await _begin_playback(source, loop, custom_data, duration_seconds)
	return true			#/ Playback started


#* Wait for a loop count and/or time (Media_Play, Media_Wait):
@warning_ignore("unused_parameter")
func wait_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> String:
	var source: CandyEngine	= candy_args["caller"]
	var wait: int			= int(settings.get("Wait_Loops", "0"))

	var target_seconds := 0.0
	if not _is_frame_target(settings.get("Wait_Time", "0"), str(candy_args.get("command", "Media_Wait"))):
		target_seconds = CandyPlayback.get_shared().resolve_time_target(source, self, settings.get("Wait_Time", "0"), false)

	return await CandyPlayback.get_shared().await_target(source, self, self, "audio_player", wait, target_seconds, loop_target)


#* Pause playback (Media_Pause):
@warning_ignore("unused_parameter")
func pause_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> Tween:
	var source: CandyEngine = candy_args["caller"]
	var context := str(candy_args.get("command", "Media_Pause"))

	pause_loop = CandyPauseLoop.start(source, self, self, settings, _pause_loop_media(source, context), context, pause_loop, "audio_player")
	if pause_loop == null:
		audio_player.stream_paused = true
	CandyPlayback.get_shared().set_pause(source, self, self, int(settings.get("Lines", -1)), int(settings.get("All", 0)))

	if pause_loop != null:
		return pause_loop.pause_fade			#/ What a "!" Pause_Volume_Time waits on
	return null


#* Resume playback (Media_Resume):
@warning_ignore("unused_parameter")
func resume_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> Tween:
	#% Never started ("Loops" = 0) - play once:
	if loop_target == 0 and audio_player.stream != null:
		await _begin_playback(candy_args["caller"], 1, custom_data)
		return null

	return unpause(settings, candy_args["caller"])			#/ What a "!" Resume_Volume_Time waits on, or null


#* Stop playback and release waits (Media_Stop):
@warning_ignore("unused_parameter")
func stop_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine = candy_args["caller"]
	var context := str(candy_args.get("command", "Media_Stop"))
	var stop_frame := CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""),
		CandyPlayback.STOP_FRAME_CLEAR, context)

	#@ Step 1 - Schedule a "Loops" / "Duration" stop:
	var loop := CandyPlayDuration.read_stop_loop(settings.get("Loops", ""), context)
	var duration_seconds := 0.0
	if not _is_frame_target(settings.get("Duration", ""), context):
		duration_seconds = CandyPlayDuration.read(source, self, settings.get("Duration", ""), false)

	if CandyPlayDuration.schedules(loop, duration_seconds) and media_active:
		end_frame = stop_frame
		_end_stopped = true
		_drop_play_duration()
		play_duration = CandyPlayDuration.schedule_stop(self, loop, duration_seconds, _play_duration_media())
		return

	#@ Step 2 - Stop now (also when not playing):
	_stop_on(stop_frame, false)


#* Seek (Media_Skip):
@warning_ignore("unused_parameter")
func skip_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine = candy_args["caller"]

	if audio_player.stream == null:
		printerr("Media_Skip: nothing is loaded on → ", name)
		return

	if _is_frame_target(settings.get("Time", 0.0), str(candy_args.get("command", "Media_Skip"))):
		return

	#% Pause loop playing - move the pause point:
	if pause_loop != null and pause_loop.owns_position():
		pause_loop.move_pause_point(settings.get("Time", 0.0))
		return

	var target_time := CandyPlayback.get_shared().resolve_seek_target(source, self, self, "audio_player", settings.get("Time", 0.0), false)

	audio_player.seek(target_time)


#* Change the volume (Media_Volume):
@warning_ignore("unused_parameter")
func volume_media(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> Tween:
	#Ł Return the fade to wait on, or null:
	return CandyPlayback.get_shared().apply_volume_change(candy_args["caller"], self, self, "audio_player",
		settings.get("Volume", "0.0"), settings.get("Time", "0.0"), "Media_Volume")


#* Playback loop finished:
func _on_finished() -> void:
	#% Return if loop is a pause loop:
	if pause_loop != null and pause_loop.media_ended():
		return

	loops_played += 1

	#¦ 1. Replay:
	if loop_target < 0 or (loop_target > 0 and loops_played < loop_target):
		audio_player.play()
		return

	#¦ 2. Playback finished:
	_end_playback()


#* End playback by itself, on end_frame:
func _end_playback() -> void:
	_stop_on(end_frame, not _end_stopped)


#* Stop on a "Stop_Frame":
#? 'ended': reached its end by itself, else stopped.
func _stop_on(stop_frame: int, ended: bool) -> void:
	var kept_stream: AudioStream = null
	if stop_frame != CandyPlayback.STOP_FRAME_CLEAR:
		kept_stream = audio_player.stream

	reset(ended)
	audio_player.stream = kept_stream


#* Clear pause state:
func unpause(resume_settings: Dictionary = {}, source: CandyEngine = null) -> Tween:
	var fade: Tween = null
	if pause_loop != null:
		fade = pause_loop.resume(source, resume_settings)			#/ Media_Resume's entry, {} = the pause's own

	audio_player.stream_paused = false

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
	audio_player.stop()
	audio_player.stream = null
	audio_player.stream_paused = false

	#@ Step 2 - Loop tracking:
	loops_played = 0
	loop_target = 1
	end_frame = CandyPlayback.STOP_FRAME_CLEAR
	_end_stopped = false

	#@ Step 3 - Dialogue suspension:
	_suspended = false

	#@ Step 4 - Pause bookkeeping:
	pause_count = 0
	pause_mode = "speech"


#* Start playback between the playback hooks:
func _begin_playback(source: CandyEngine, loop: int, custom_data: Array, duration_seconds: float = 0.0) -> void:
	var start_loop := CandyPlayDuration.play_loop(loop, duration_seconds)

	if start_loop != 0:
		await candy_de.run_node_hook(self, "x_playback_starting", {"caller": source, "node": self}, custom_data)

	_drop_pause_loop()
	_drop_play_duration()
	CandyPlayback.get_shared().begin_playback(source, self, self, "audio_player", start_loop)
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
			return audio_player.get_playback_position(),
		"length": func() -> float:
			if audio_player.stream == null:
				return 0.0
			return audio_player.stream.get_length(),
		"loops": func() -> int:
			return loops_played,
		"set_loops": func(count: int) -> void:
			loop_target = count,
		"end": func(_at: float) -> void:
			_end_playback(),
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
func _pause_loop_media(source: CandyEngine, context: String) -> Dictionary:
	return {
		"active": media_active and audio_player.stream != null,
		"position": func() -> float:
			return audio_player.get_playback_position(),
		"length": func() -> float:
			if audio_player.stream == null:
				return 0.0
			return audio_player.stream.get_length(),
		"time": func(text: String, base: float) -> float:
			if _is_frame_target(text, context):
				return -1.0
			return CandyPlayback.get_shared().resolve_relative_time(source, self, base, text, false),
		"play_from": func(time: float) -> void:
			audio_player.stream_paused = false
			audio_player.play(time)
			#% Stay paused if suspended:
			if _suspended:
				audio_player.stream_paused = true,
		"run": func() -> void:
			if not _suspended:
				audio_player.stream_paused = false,
	}


#* Cancel the pause loop, restoring volume:
func _drop_pause_loop() -> void:
	if pause_loop != null:
		pause_loop.cancel()
	pause_loop = null


#* Report a frame time value ("f=N", "f+N", "f-N") - audio has none:
func _is_frame_target(time_raw: Variant, context: String) -> bool:
	var text := str(time_raw).strip_edges().to_lower()
	if text.begins_with("+") or text.begins_with("-"):
		text = text.substr(1).strip_edges()
	if text.begins_with("f=") or text.begins_with("f+") or text.begins_with("f-"):
		printerr(context, ": '", str(time_raw), "' on ", name, " - audio has no frames, so it can't count them. Give a time instead.")
		return true
	return false


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
