#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends AnimationPlayer

## REQUIRED: The AnimationPlayer2D Node
@export var effect_player: Node = self

#^ Default extension for AnimationLibrary files:
## Default extension to use for AnimationLibrary files named without one.
@export var default_effect_extension = ".tres"

#^ Fallback frame rate for "f=":
## Frame rate "f=" targets fall back to when an animation can't provide one of its own.[br][br]
## Leave at 0 to inherit the engine's [code]default_effect_fps[/code], and through it
## the project-wide setting in Candy_Properties.gd. The "FPS" key on the dialogue line
## overrides this.
@export var default_effect_fps: float = 0.0

var pause_count = 0
var pause_mode = "speech"
#^ Effect_Pause's pause loop, if any:
var pause_loop: CandyPauseLoop = null

#^ Loop / wait tracking:
var loop_target: int = 1		#/ <0 = infinite, 0 = hold on the first frame, >0 = that many times
var loops_played: int = 0
var duration: float = 0.0
#^ Effect_Play "Duration" tracker:
var play_duration: CandyPlayDuration = null
#^ "Stop_Frame" used when playback ends by itself:
var end_frame: int = 0
#^ Converts end_frame to seconds (see _frame_converter()):
var _end_converter: Callable = Callable()
#^ An Effect_Stop scheduled that end:
var _end_stopped: bool = false

#^ Playback announced by the playback hooks:
#? Nothing is announced for "Loops": 0 or no playback.
var _announced: bool = false
var _announced_source = null		#/ Untyped: the engine may be freed first
var _announced_custom_data: Array = []

#^ Library the last "Library" key loaded (used by lines without one):
var current_library: String = ""

#^ Candy started the current playback and counts its loops:
#? A flag, since every loop_target value has a meaning.
var playback_armed: bool = false

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
@export var semi_exclusive_commands: Array[String] = ["Effect_Pause", "Effect_Resume", "Effect_Stop", "Effect_Skip"]
## Commands that make the engine sending them hold this player, when it is Public.[br]
## A line's "Take_Hold" key overrides this: 1 takes hold anyway, -1 never does.
@export var hold_commands: Array[String] = ["Effect_Play"]
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
#^ Engine whose Effect_Pause set pause_count:
var pause_engine: Node = null
#^ Playback the dialogue may wait on is running:
var media_active: bool = false


#^ Resource-level loop tracking:
var _cycle_prev_pos: float = -1.0
var _cycle_prev_dir: int = 0


func _ready() -> void:
	#Ł Loop tracking runs only for tracked looping animations:
	set_process(false)
	if effect_player != null and not effect_player.animation_started.is_connected(_on_animation_started):
		effect_player.animation_started.connect(_on_animation_started)

	#% effect_player may not be self; don't double a scene connection:
	if effect_player != null and effect_player.has_signal("animation_finished") and not effect_player.animation_finished.is_connected(_on_animation_finished):
		effect_player.animation_finished.connect(_on_animation_finished)


#* Accept a command (""), or say why not, taking hold if it does:
func admit_command(engine: Node, command: String, take_hold: int = 0) -> String:
	#Ł Script file name, case-insensitive:
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
	if not source.suspend_animations:
		return

	if effect_player.is_playing():
		effect_player.pause()
		_suspended = true


#* Resume from suspension, if suspend_media() paused it:
@warning_ignore("unused_parameter")
func unsuspend_media(candy_args: Dictionary) -> void:
	if not _suspended:
		return

	_suspended = false
	effect_player.play()


#* Play an animation (Effect_Play):
func play_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> bool:
	var source: CandyEngine	= candy_args["caller"]
	var anim_name: String	= str(settings.get("Animation", "")).strip_edges()
	var loop: int			= CandyPlayback.get_shared().normalize_loop(source, self, settings.get("Loops", "1"))
	var library_ref: Variant = settings.get("Library", "")

	#@ Step 1 - Load the line's library, or use the loaded one:
	if library_ref is Resource or str(library_ref).strip_edges() != "":
		var library_name := _add_library(library_ref)
		if library_name == "":
			return false
		if not ("/" in anim_name):
			anim_name = library_name + "/" + anim_name
	elif current_library != "" and not ("/" in anim_name) and effect_player.has_animation(current_library + "/" + anim_name):
		anim_name = current_library + "/" + anim_name

	#@ Step 2 - Check the animation:
	if anim_name == "" or not effect_player.has_animation(anim_name):
		printerr("Effect_Play: animation not found → '", anim_name, "' on ", name)
		return false

	#@ Step 3 - Start playback:
	var duration_seconds := CandyPlayDuration.read(source, self, settings.get("Duration", "null"), true, 0.0,
		_frame_converter(source, settings, anim_name))
	end_frame = CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""), 0,
		str(candy_args.get("command", "Effect_Play")))
	_end_converter = _frame_converter(source, settings, anim_name)
	_end_stopped = false
	await _begin_playback(source, anim_name, loop, custom_data, duration_seconds)
	return true


#* Wait for a loop count and/or time (Effect_Play, Effect_Wait):
@warning_ignore("unused_parameter")
func wait_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> String:
	var source: CandyEngine	= candy_args["caller"]
	var wait: int			= int(settings.get("Wait_Loops", "0"))

	var target_seconds := CandyPlayback.get_shared().resolve_time_target(source, self, settings.get("Wait_Time", ""), true, 0.0,
		_frame_converter(source, settings))

	return await CandyPlayback.get_shared().await_target(source, self, self, "effect_player", wait, target_seconds, loop_target)


#* Pause the animation (Effect_Pause):
@warning_ignore("unused_parameter")
func pause_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine = candy_args["caller"]
	var context := str(candy_args.get("command", "Effect_Pause"))

	pause_loop = CandyPauseLoop.start(source, self, self, settings, _pause_loop_media(source, settings), context, pause_loop)
	if pause_loop == null and effect_player.is_playing():
		effect_player.pause()
	CandyPlayback.get_shared().set_pause(source, self, self, int(settings.get("Lines", -1)), int(settings.get("All", 0)))


#* Resume the animation (Effect_Resume):
@warning_ignore("unused_parameter")
func resume_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var held_animation := _animation_name()
	#% Never started ("Loops" = 0) - play once:
	if loop_target == 0 and held_animation != "":
		await _begin_playback(candy_args["caller"], held_animation, 1, custom_data)
		return

	unpause(settings, candy_args["caller"])


#* Stop the animation and release waits (Effect_Stop):
@warning_ignore("unused_parameter")
func stop_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine = candy_args["caller"]
	var context := str(candy_args.get("command", "Effect_Stop"))
	var stop_frame := CandyPlayback.get_shared().parse_stop_frame(source, self, settings.get("Stop_Frame", ""),
		CandyPlayback.STOP_FRAME_CLEAR, context)

	#@ Step 1 - Schedule a "Loops" / "Duration" stop:
	var loop := CandyPlayDuration.read_stop_loop(settings.get("Loops", ""), context)
	var duration_seconds := CandyPlayDuration.read(source, self, settings.get("Duration", ""), true, 0.0,
		_frame_converter(source, settings))

	#% Only while playing - one that isn't stops at once:
	if CandyPlayDuration.schedules(loop, duration_seconds) and media_active:
		end_frame = stop_frame
		_end_converter = _frame_converter(source, settings)
		_end_stopped = true
		_drop_play_duration()
		play_duration = CandyPlayDuration.schedule_stop(self, loop, duration_seconds, _play_duration_media())
		return

	#@ Step 2 - Stop now:
	if stop_frame == CandyPlayback.STOP_FRAME_CLEAR:
		reset()
		return

	_end_playback()
	CandyPlayback.get_shared().settle_animation(source, self, effect_player, stop_frame, _frame_converter(source, settings))
	_playback_finished(false)


#* Seek within the current loop (Effect_Skip):
@warning_ignore("unused_parameter")
func skip_effect(candy_args: Dictionary, settings: Dictionary, custom_data: Array = []) -> void:
	var source: CandyEngine = candy_args["caller"]

	var anim := _animation()
	if anim == null:
		printerr("Effect_Skip: no animation is loaded on → ", name)
		return

	#% Pause loop playing - move the pause point:
	if pause_loop != null and pause_loop.owns_position():
		pause_loop.move_pause_point(settings.get("Time", 0.0))
		return

	var target_time := clampf(CandyPlayback.get_shared().resolve_seek_target(source, self, self, "effect_player",
		settings.get("Time", 0.0), true, 0.0, _frame_converter(source, settings)), 0.0, anim.length)

	effect_player.seek(target_time, true)		#/ A paused or held animation doesn't start


#* Clear pause state and resume playback:
func unpause(resume_settings: Dictionary = {}, source: CandyEngine = null) -> void:
	#% Pause loop - 'resume_settings' is Effect_Resume's entry ({} = the pause's own):
	if pause_loop != null:
		pause_loop.resume(source, resume_settings)

	pause_count = 0
	pause_mode = "speech"

	if media_active and not _suspended and not effect_player.is_playing():
		effect_player.play()


#* Position in the current loop, in seconds:
func get_media_position() -> float:
	if _animation_name() == "":
		return 0.0
	return float(effect_player.current_animation_position)


#* Length of one loop, in seconds:
func get_media_length() -> float:
	return duration


#* Whether a playback is running, paused or not:
func is_media_playing() -> bool:
	return media_active


#* Whether a running playback is paused:
func is_media_paused() -> bool:
	return media_active and not effect_player.is_playing()


func _on_animation_finished(_anim_name: StringName) -> void:
	_cycle_done(_anim_name, true)


#* Track loops only for a tracked self-looping animation:
func _on_animation_started(anim_name: StringName) -> void:
	_set_tracking(playback_armed and _is_self_looping(anim_name))


func _is_self_looping(anim_name: StringName) -> bool:
	if effect_player == null or not effect_player.has_animation(anim_name):
		return false
	var anim: Animation = effect_player.get_animation(anim_name)
	return anim != null and anim.loop_mode != Animation.LOOP_NONE


func _set_tracking(enabled: bool) -> void:
	_cycle_prev_pos = -1.0
	_cycle_prev_dir = 0
	set_process(enabled)


func _process(_delta: float) -> void:
	#% Nothing left to track:
	if effect_player == null or not playback_armed or not _is_self_looping(effect_player.assigned_animation):
		_set_tracking(false)
		return

	#% Paused, or a pause loop moving it - not a wrap:
	if not effect_player.is_playing() or (pause_loop != null and pause_loop.owns_position()):
		_cycle_prev_pos = -1.0
		_cycle_prev_dir = 0
		return

	var anim_name: StringName = effect_player.current_animation
	var anim: Animation = effect_player.get_animation(anim_name)

	var pos: float = effect_player.current_animation_position
	var wrapped := false

	if anim.loop_mode == Animation.LOOP_LINEAR:
		wrapped = _cycle_prev_pos >= 0.0 and pos < _cycle_prev_pos
	else:
		#% Ping-pong - a loop ends when it turns forward again:
		var dir := _cycle_prev_dir
		if _cycle_prev_pos >= 0.0:
			if pos > _cycle_prev_pos:
				dir = 1
			elif pos < _cycle_prev_pos:
				dir = -1
		wrapped = _cycle_prev_dir == -1 and dir == 1
		_cycle_prev_dir = dir

	_cycle_prev_pos = pos

	if wrapped:
		#% Restarts by itself - no replay:
		_cycle_done(anim_name, false)


#* Playback loop finished:
func _cycle_done(anim_name: StringName, replay: bool) -> void:
	#% Return if loop is a pause loop:
	if pause_loop != null and pause_loop.media_ended():
		return

	loops_played += 1

	#¦ 1. Replay:
	if loop_target < 0 or (loop_target > 0 and loops_played < loop_target):
		if replay:
			effect_player.play(anim_name)
		return

	#¦ 2. Playback done:
	var end_time: float = duration
	if effect_player.has_animation(anim_name):
		var anim: Animation = effect_player.get_animation(anim_name)
		if anim != null:
			end_time = anim.length

	_finish_playback(end_time)


#* End playback by itself, on end_frame (0 holds the pose at 'end_time'):
func _finish_playback(end_time: float) -> void:
	var stop_frame := end_frame
	var frame_to_time := _end_converter
	var ended := not _end_stopped

	#% Clear:
	if stop_frame == CandyPlayback.STOP_FRAME_CLEAR:
		_end_playback()
		CandyPlayback.get_shared().clear_animation(caller, self, effect_player)
		_playback_finished(ended)
		return

	_drop_play_duration()

	#@ Step 1 - Hold a still-running loop before the final pose:
	if stop_frame == 0 or not frame_to_time.is_valid():
		CandyPlayback.get_shared().settle_animation_at(caller, self, effect_player, end_time)
	else:
		CandyPlayback.get_shared().settle_animation(caller, self, effect_player, stop_frame, frame_to_time)
	_set_tracking(false)

	#@ Step 2 - Release waits and hold:
	media_active = false
	release_hold()

	#@ Step 3 - Reset loop state:
	loops_played = 0
	loop_target = 1
	playback_armed = false
	end_frame = 0
	_end_converter = Callable()
	_end_stopped = false

	_playback_finished(ended)


#* Clear playback state and dialogue waits:
func reset():
	#? First, so playback_armed doesn't track "RESET".
	_end_playback()

	#Ł Play "RESET" if any, and stop:
	CandyPlayback.get_shared().clear_animation(caller, self, effect_player)

	_playback_finished(false)


#* End playback state, keeping the pose:
func _end_playback() -> void:
	_drop_pause_loop()
	_drop_play_duration()
	_set_tracking(false)
	_suspended = false

	#@ Step 1 - Reset loop state:
	loops_played = 0
	loop_target = 1
	playback_armed = false
	end_frame = 0
	_end_converter = Callable()
	_end_stopped = false

	#@ Step 2 - Pause bookkeeping:
	pause_count = 0
	pause_mode = "speech"

	#@ Step 3 - Release waits and hold:
	media_active = false
	release_hold()


#* Start an animation from the beginning, between the playback hooks:
func _begin_playback(source: CandyEngine, anim_name: String, loop: int, custom_data: Array, duration_seconds: float = 0.0) -> void:
	var start_loop := CandyPlayDuration.play_loop(loop, duration_seconds)

	if start_loop != 0:
		await candy_de.run_node_hook(self, "x_playback_starting", {"caller": source, "node": self}, custom_data)

	#@ Step 1 - Set up loop tracking, clear pauses:
	_drop_pause_loop()
	_drop_play_duration()
	loop_target		= start_loop
	loops_played	= 0
	duration		= effect_player.get_animation(anim_name).length
	playback_armed	= true
	pause_count		= 0
	pause_mode		= "speech"
	caller			= source

	#@ Step 2 - Restart from the beginning:
	#? play() alone resumes a paused animation and ignores the one already playing.
	#? Skip stop() if a library swap removed the last animation.
	if effect_player.has_animation(effect_player.assigned_animation):
		effect_player.stop()
	effect_player.play(anim_name)
	effect_player.seek(0.0, true)

	#@ Step 3 - "Loops" = 0 holds on the first frame:
	#? Nothing to wait on; ends a replaced playback, for x_playback_finished().
	if start_loop == 0:
		media_active = false
		effect_player.pause()
		_playback_finished(false)
		return

	media_active = true
	play_duration = CandyPlayDuration.start(self, loop, duration_seconds, _play_duration_media())

	#@ Step 4 - Track for x_playback_finished():
	_announced = true
	_announced_source = source
	_announced_custom_data = custom_data

	await candy_de.run_node_hook(self, "x_playback_started", {"caller": source, "node": self}, custom_data)


#* Load an AnimationLibrary, returning its name, or "":
func _add_library(library_ref: Variant) -> String:
	var effects_folder = candy_de.get("effects_folder")
	if effects_folder == null:
		effects_folder = "res://Candy_DE/Media/General/Effects"

	#@ Step 1 - A name is in effects_folder/Animation_Libraries; a path or library is used as is:
	var resolved := CandyMedia.resolve_media(library_ref, str(effects_folder).path_join("Animation_Libraries"), default_effect_extension)
	if not resolved["found"] or bool(resolved["is_folder"]):
		printerr("Effect_Play: missing AnimationLibrary → ", resolved["path"])
		return ""

	var library = resolved["resource"]
	if library == null:
		library = CandyMedia.load_animation_library(str(resolved["path"]))
	if not (library is AnimationLibrary):
		printerr("Effect_Play: not an AnimationLibrary → ", library_ref)
		return ""

	#@ Step 2 - Name - file name, else resource name (runtime libraries):
	var library_name: String = str(resolved["path"]).get_file().get_basename()
	if library_name == "":
		library_name = str(library.resource_name)
	if library_name == "":
		library_name = "Library"

	#% Already loaded:
	if library_name == current_library and effect_player.has_animation_library(library_name) \
	and effect_player.get_animation_library(library_name) == library:
		return library_name

	#@ Step 3 - Replace the previous library, keeping the player's global one (with "RESET"):
	effect_player.stop()
	for loaded_name in effect_player.get_animation_library_list():
		if str(loaded_name) != "":
			effect_player.remove_animation_library(loaded_name)

	effect_player.add_animation_library(library_name, library)
	current_library = library_name
	return library_name


#* Last played animation's name, or "":
func _animation_name() -> String:
	var anim_name: String = str(effect_player.current_animation)
	#% current_animation empties when playback ends; assigned_animation stays:
	if anim_name == "":
		anim_name = str(effect_player.assigned_animation)
	return anim_name


#* Last played animation, or null:
func _animation() -> Animation:
	var anim_name := _animation_name()
	if anim_name == "" or not effect_player.has_animation(anim_name):
		return null
	return effect_player.get_animation(anim_name)


#* "f=" frame → seconds, from the current animation's frames:
#? 'anim_name': count that animation instead, for one about to play.
func _frame_converter(source: CandyEngine, settings: Dictionary, anim_name: String = "") -> Callable:
	var counted_name := anim_name
	if counted_name == "":
		counted_name = _animation_name()
	var fallback_fps := CandyPlayback.get_shared().resolve_fps(source, self, "default_effect_fps", settings.get("FPS", ""),
		default_effect_fps, 0.0, CandyPlayback.get_shared().animation_library_file(source, self, effect_player, counted_name))
	return func(frame: float) -> float:
		var anim := _animation()
		if anim_name != "" and effect_player.has_animation(anim_name):
			anim = effect_player.get_animation(anim_name)
		return CandyPlayback.get_shared().animation_frame_to_time(source, self, anim, frame, fallback_fps)


#* Callables for CandyPauseLoop.start():
func _pause_loop_media(source: CandyEngine, settings: Dictionary) -> Dictionary:
	var frame_converter := _frame_converter(source, settings)
	return {
		"active": media_active and _animation() != null,
		"position": get_media_position,
		"length": func() -> float:
			var anim := _animation()
			if anim == null:
				return 0.0
			return anim.length,
		"time": func(text: String, base: float) -> float:
			return CandyPlayback.get_shared().resolve_relative_time(source, self, base, text, true, 0.0, frame_converter),
		"play_from": func(time: float) -> void:
			var anim_name := _animation_name()
			if anim_name == "":
				return
			#Ł Stay paused if suspended:
			if not effect_player.is_playing() and not _suspended:
				effect_player.play(anim_name)
			effect_player.seek(time, true),
		"run": func() -> void:
			if not _suspended and not effect_player.is_playing():
				effect_player.play(),
	}


#* Cancel the pause loop:
func _drop_pause_loop() -> void:
	if pause_loop != null:
		pause_loop.cancel()
	pause_loop = null


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
		"end": _finish_playback,
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


#* Hook - before playback starts (Effect_Play, or Effect_Resume after "Loops" = 0):
@warning_ignore("unused_parameter")
func x_playback_starting(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook - after playback starts:
@warning_ignore("unused_parameter")
func x_playback_started(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook - after playback ends or is stopped:
#? Not called when a new Effect_Play replaces it.
#! Not awaited.
@warning_ignore("unused_parameter")
func x_playback_finished(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass
