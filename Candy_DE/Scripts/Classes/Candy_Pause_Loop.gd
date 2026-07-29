#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPauseLoop
extends RefCounted


#^ Values of "Pause_Loop_Resume":
const RESUME_MODES: Array[String] = ["Return", "Continue", "Finish_Return", "Finish_Continue"]

#^ Wrap detection tolerance:
const WRAP_TOLERANCE: float = 0.05
#^ Shortest loop:
const MIN_LOOP_LENGTH: float = 0.01

#^ Phases:
#? LOOPING   - paused: the loop repeats.
#? FINISHING - resumed by a "Finish_" mode: playing on to the loop's end.
#? DONE      - over.
enum {LOOPING, FINISHING, DONE}


var phase: int = LOOPING

#^ The loop, in seconds:
var pause_point: float = 0.0
var loop_start: float = 0.0
var loop_end: float = 0.0

#^ Resume mode and volume fade time:
var resume_mode: String = "Return"
var resume_volume_time: Variant = "0"

#^ Volume to restore:
var volume_before: float = 0.0

#^ "!" Pause_Volume_Time fade, else null:
var pause_fade: Tween = null

#^ Media host and its Callables:
var _host: Node = null
var _media: Dictionary = {}
#^ _host property holding the volume_db node; "" = _host itself, null = no volume:
var _volume_property: Variant = null
#^ Volume owed back:
var _volume_held: bool = false

#^ Pausing (then resuming) engine, and command:
var _source: CandyEngine = null
var _context: String = ""

#^ Last polled position, -1 = none:
var _last_position: float = -1.0
#^ Frozen (see freeze()), and the loop's volume:
var _frozen: bool = false
var _frozen_volume: float = 0.0
#^ Keeps this loop alive while polling:
var _keep_alive: CandyPauseLoop = null


#* Start a pause, looping if the line gives a loop:
#? 'settings': the _Pause entry. 'media':
#?    "active"    bool                  whether a playback is running that a loop could repeat
#?    "reason"    String                why a loop can't play on this media at all, "" if it can
#?    "label"     String                what reports call the media (default: the name of 'host')
#?    "position"  Callable() -> float   where playback is, in seconds
#?    "length"    Callable() -> float   the media's length, 0 if unknown
#?    "time"      Callable(String, float) -> float   a line's time value → position from the base, -1 if unreadable
#?    "play_from" Callable(float)       play from that time
#?    "run"       Callable()            let the media play on from where it is
#? 'previous': the replaced loop. 'volume_property': as _volume_property.
static func start(source: CandyEngine, caller: Object, host: Node, settings: Dictionary, media: Dictionary,
		context: String, previous: CandyPauseLoop = null, volume_property: Variant = null) -> CandyPauseLoop:
	var loop := CandyPauseLoop.new()
	loop._host = host
	loop._media = media
	loop._volume_property = volume_property
	loop._source = source
	loop._context = context

	var label := str(media.get("label", host.name))

	#@ Step 1 - Take over from the previous loop:
	#? Its pause point and owed volume carry over.
	var point: float = float(media["position"].call())
	var owed_volume: Variant = null
	var took_position: bool = false		#/ Playback is in the previous loop
	if previous != null and previous.is_running():
		if previous.owns_position():
			point = previous.pause_point
			took_position = true
		owed_volume = previous._abandon()
	loop.pause_point = point

	#@ Step 2 - Read loop:
	var start_raw: Variant = settings.get("Pause_Loop_Start", "")
	var end_raw: Variant = settings.get("Pause_Loop_End", "")
	var looping: bool = not (is_unset(start_raw) and is_unset(end_raw))

	if looping and str(media.get("reason", "")) != "":
		printerr(context, ": '", label, "' can't loop while paused - ", media["reason"], ". Pausing without a loop.")
		looping = false
	elif looping and not bool(media.get("active", false)):
		printerr(context, ": '", label, "' isn't playing anything to loop. Pausing without a loop.")
		looping = false

	if looping:
		loop.loop_start = point
		loop.loop_end = point
		if not is_unset(start_raw):
			loop.loop_start = loop._resolve(start_raw, point)
		if not is_unset(end_raw):
			loop.loop_end = loop._resolve(end_raw, point)

		if loop.loop_start < 0.0 or loop.loop_end < 0.0:
			looping = false		#/ Reported by "time"
		else:
			var length: float = float(media["length"].call())
			if length > 0.0:
				loop.loop_start = clampf(loop.loop_start, 0.0, length)
				loop.loop_end = clampf(loop.loop_end, 0.0, length)
			if loop.loop_end - loop.loop_start < MIN_LOOP_LENGTH:
				printerr(context, ": the pause loop on '", label, "' must end after it starts (",
					snappedf(loop.loop_start, 0.001), "s → ", snappedf(loop.loop_end, 0.001), "s). Pausing without a loop.")
				looping = false

	#@ Step 3 - No loop, plain pause:
	if not looping:
		if took_position:
			media["play_from"].call(point)
		if owed_volume != null:
			CandyPlayback.get_shared().apply_volume_change(source, caller, host, volume_property, str(owed_volume), "0", context)
		if not is_unset(settings.get("Pause_Volume", "null")):
			printerr(context, ": '", label, "' - Pause_Volume only applies while a pause loop plays. Ignored.")
		return null			#/ Plain pause: the caller halts the media

	loop.resume_mode = loop._read_mode(settings.get("Pause_Loop_Resume", "null"), "Return")
	loop.resume_volume_time = _read_time(settings.get("Resume_Volume_Time", "null"), "0")

	#@ Step 4 - Loop volume:
	var volume_raw: Variant = settings.get("Pause_Volume", "null")
	if not is_unset(volume_raw):
		if volume_property == null:
			printerr(context, ": '", label, "' has no volume - Pause_Volume is ignored.")
		else:
			if owed_volume != null:
				loop.volume_before = float(owed_volume)
			else:
				loop.volume_before = CandyPlayback.get_shared().volume_target(source, caller, host, volume_property)
			loop.pause_fade = CandyPlayback.get_shared().apply_volume_change(source, caller, host, volume_property, volume_raw,
				_read_time(settings.get("Pause_Volume_Time", "null"), "0"), context)
			loop._volume_held = true
	elif owed_volume != null:
		#% Volume still owed by the previous loop:
		loop.volume_before = float(owed_volume)
		loop._volume_held = true

	#@ Step 5 - Play the loop:
	#? Inside it: carry on to its end first. Outside: jump to its start.
	if point >= loop.loop_start and point < loop.loop_end:
		if took_position:
			media["play_from"].call(point)
		else:
			media["run"].call()
	else:
		media["play_from"].call(loop.loop_start)

	loop._poll()
	return loop


#* Whether a loop key is unset ("null" or ""):
static func is_unset(value: Variant) -> bool:
	return CandySettings.is_not_set(value) or str(value).strip_edges() == ""


#* Whether the media counts as paused:
func holds_pause() -> bool:
	return phase == LOOPING


#* Whether the loop owns the playback position (paused, or finishing a "Finish_Return"):
func owns_position() -> bool:
	return phase == LOOPING or (phase == FINISHING and resume_mode == "Finish_Return")


#* Whether the loop owes the volume back:
func holds_volume() -> bool:
	return phase != DONE and _volume_held


func is_running() -> bool:
	return phase != DONE


#* Lift the pause:
func resume(source: CandyEngine, settings: Dictionary = {}) -> Tween:
	if phase != LOOPING:
		return null
	if source != null:
		_source = source

	var mode := _read_mode(settings.get("Pause_Loop_Resume", "null"), resume_mode)
	resume_volume_time = _read_time(settings.get("Resume_Volume_Time", "null"), str(resume_volume_time))
	resume_mode = mode

	match mode:
		"Return":
			_media["play_from"].call(pause_point)
			return _finish()
		"Continue":
			return _finish()

	phase = FINISHING
	_last_position = -1.0
	return null


#* The media reached its end - true when the loop takes it over:
func media_ended() -> bool:
	if _frozen:
		return owns_position()
	match phase:
		LOOPING:
			_media["play_from"].call(loop_start)
			_last_position = loop_start
			return true
		FINISHING:
			var returning: bool = resume_mode == "Finish_Return"
			_reach_end()
			return returning
	return false


#* Move the pause point (_Skip):
func move_pause_point(time_raw: Variant) -> void:
	var target := _resolve(time_raw, pause_point)
	if target < 0.0:
		return
	var length: float = float(_media["length"].call())
	if length > 0.0:
		target = clampf(target, 0.0, length)
	pause_point = target


#* Set the loop aside while its media moves node (VN_Move, VN_Swap):
func freeze() -> void:
	if _frozen:
		return
	_frozen = true
	#Ł Restore the old node's volume:
	if _volume_held and is_instance_valid(_host):
		_frozen_volume = CandyPlayback.get_shared().volume_target(_source, self, _host, _volume_property)
		CandyPlayback.get_shared().apply_volume_change(_source, self, _host, _volume_property, str(volume_before), "0", _context)


#* Resume the loop after freeze(), on 'host' if given:
func thaw(host: Node = null) -> void:
	if not _frozen:
		return
	_frozen = false
	_last_position = -1.0
	if host != null and is_instance_valid(host):
		_host = host
	if _volume_held and is_instance_valid(_host):
		CandyPlayback.get_shared().apply_volume_change(_source, self, _host, _volume_property, str(_frozen_volume), "0", _context)

	#Ł Restart the poll if it stopped:
	if _keep_alive == null and phase != DONE:
		_poll()


#* End the loop, restoring the volume at once:
func cancel() -> void:
	if phase == DONE:
		return
	_end()
	if _volume_held:
		_volume_held = false
		CandyPlayback.get_shared().apply_volume_change(_source, self, _host, _volume_property, str(volume_before), "0", _context)


#* End the loop for a replacing one; returns the owed volume, or null:
func _abandon() -> Variant:
	_end()
	if not _volume_held:
		return null
	_volume_held = false
	return volume_before


#* Mark the loop over:
func _end() -> void:
	phase = DONE
	_media = {}			#/ Drop the Callables (reference cycle)


#* Follow playback every frame:
func _poll() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	_keep_alive = self

	while phase != DONE:
		await tree.process_frame
		if phase == DONE or not is_instance_valid(_host):
			break
		if _frozen:
			continue

		var position: float = float(_media["position"].call())

		if phase == LOOPING:
			#% Past the end, or wrapped before the start:
			if position >= loop_end:
				#? Keep the overshoot, for timing.
				var target: float = loop_start + (position - loop_end)
				if target >= loop_end:
					target = loop_start
				_media["play_from"].call(target)
				position = target
			elif position < loop_start - WRAP_TOLERANCE:
				_media["play_from"].call(loop_start)
				position = loop_start

		elif phase == FINISHING:
			var wrapped: bool = _last_position >= 0.0 and position < _last_position - WRAP_TOLERANCE
			if position >= loop_end or wrapped:
				_reach_end()

		_last_position = position

	_keep_alive = null


#* Loop end after a "Finish_" resume:
func _reach_end() -> void:
	if resume_mode == "Finish_Return":
		_media["play_from"].call(pause_point)
	_finish()


#* End the loop and restore the volume:
func _finish() -> Tween:
	_end()
	if not _volume_held:
		return null
	_volume_held = false

	#% Engine gone - no fade:
	var time: Variant = resume_volume_time
	if _source == null or not is_instance_valid(_source):
		time = "0"
	return CandyPlayback.get_shared().apply_volume_change(_source, self, _host, _volume_property, str(volume_before), time, _context)			#/ A "!" Resume_Volume_Time fade, else null


#* A loop bound in seconds, -1 if unreadable:
func _resolve(raw: Variant, base: float) -> float:
	#% Native number - offset from 'base':
	if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
		return maxf(base + float(raw), 0.0)

	return float(_media["time"].call(str(raw).strip_edges(), base))


#* A "Pause_Loop_Resume" value (any case), else 'fallback':
func _read_mode(value: Variant, fallback: String) -> String:
	if is_unset(value):
		return fallback
	var text := str(value).strip_edges()
	for mode in RESUME_MODES:
		if mode.to_lower() == text.to_lower():
			return mode
	printerr(_context, ": invalid Pause_Loop_Resume → '", text, "' (use ", ", ".join(RESUME_MODES), "). Using ", fallback, ".")
	return fallback


#* A fade time, else 'fallback':
static func _read_time(value: Variant, fallback: String) -> String:
	if is_unset(value):
		return fallback
	return str(value).strip_edges()
