#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPlayDuration
extends RefCounted


#^ Tolerance for a Duration ending on a whole loop:
const LOOP_TOLERANCE: float = 0.001
#^ Settle just before the end point, to hold its frame:
const SETTLE_BACKOFF: float = 0.0001


#^ The line's Loops and Duration:
var base_loops: int = 0
var seconds: float = 0.0

#^ Cut loop and position. -1 = unknown; _cut_at 0 = no cut:
var _cut_loop: int = -1
var _cut_at: float = -1.0

#^ Media host and its Callables:
var _host: Object = null
var _media: Dictionary = {}

#^ Length learning (loops at last poll, furthest position in the current loop):
var _seen_loops: int = 0
var _furthest: float = 0.0

var _done: bool = false
#^ Keeps this duration alive while polling:
var _keep_alive: CandyPlayDuration = null


#* Read a "Duration" in seconds; 0 for none:
#? 'fps' or 'frame_to_time' converts frames ("f=N").
static func read(source: CandyEngine, caller: Object, value: Variant, allow_frames: bool, fps: float = 0.0,
		frame_to_time: Callable = Callable()) -> float:
	if CandySettings.is_not_set(value) or str(value).strip_edges() == "":
		return 0.0
	return maxf(CandyPlayback.get_shared().resolve_time_target(source, caller, value, allow_frames, fps, frame_to_time), 0.0)


#* Whether a Duration decides the playback's end:
static func applies(loop: int, duration_seconds: float) -> bool:
	return loop >= 0 and duration_seconds > 0.0


#* Starting loop count - forever with a Duration, else 'loop':
static func play_loop(loop: int, duration_seconds: float) -> int:
	if applies(loop, duration_seconds):
		return -1
	return loop


#* Follow a playback started with play_loop()'s count:
#? 'media' Callables:
#?    "position"  Callable() -> float   where playback is in the current loop, in seconds
#?    "length"    Callable() -> float   one loop's length, 0 while unknown
#?    "loops"     Callable() -> int     loops the playback has completed
#?    "set_loops" Callable(int)         end the playback after that many loops
#?    "end"       Callable(float)       end the playback now, settled at that position
#?    "active"    Callable() -> bool    whether the playback still runs, paused or not
#?    "held"      Callable() -> bool    (optional) whether a pause loop owns the position
static func start(host: Object, loop: int, duration_seconds: float, media: Dictionary) -> CandyPlayDuration:
	if not applies(loop, duration_seconds):
		return null		#/ No Duration applies

	var duration := CandyPlayDuration.new()
	duration.base_loops = loop
	duration.seconds = duration_seconds
	duration._host = host
	duration._media = media

	#% Length known up front:
	if duration._step():
		duration._poll()
	return duration


#* Read a _Stop entry's "Loops", or -1 for none:
static func read_stop_loop(value: Variant, context: String) -> int:
	if CandySettings.is_not_set(value):
		return -1
	var text := str(value).strip_edges()
	if text == "":
		return -1
	if text.is_valid_int() and text.to_int() >= 0:
		return text.to_int()
	printerr(context, ": invalid Loops → ", value, " (use 0 or a number of loops; empty stops at once)")
	return -1


#* Whether a _Stop entry schedules its stop:
static func schedules(loop: int, duration_seconds: float) -> bool:
	return loop >= 0 or duration_seconds > 0.0


#* Schedule a _Stop's end from its "Loops" and "Duration":
#? 'media' as for start().
static func schedule_stop(host: Object, loop: int, duration_seconds: float, media: Dictionary) -> CandyPlayDuration:
	var loops: int = maxi(loop, 0)
	var loops_done: int = int(media["loops"].call())
	var position: float = float(media["position"].call())

	#@ Step 1 - End already passed (counted from the playback's start):
	var length: float = float(media["length"].call())
	var passed: bool = loops_done >= loops and duration_seconds <= 0.0
	if length > 0.0:
		passed = float(loops) * length + duration_seconds <= float(loops_done) * length + position
	if passed:
		media["end"].call(position)
		return null

	#@ Step 2 - Whole loops:
	if duration_seconds <= 0.0:
		media["set_loops"].call(loops)
		return null

	#@ Step 3 - Part of a loop:
	media["set_loops"].call(-1)
	return start(host, loops, duration_seconds, media)


#* Stop following the playback:
func cancel() -> void:
	_end()


#* Follow playback every frame:
func _poll() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	_keep_alive = self

	while not _done:
		await tree.process_frame
		if _done or not _step():
			break

	_end()
	_keep_alive = null


#* Check the playback; false when done:
func _step() -> bool:
	if _done:
		return false
	if _host == null or not is_instance_valid(_host) or not bool(_media["active"].call()):
		return false

	#% Pause loop owns the position:
	if _media.has("held") and bool(_media["held"].call()):
		_furthest = 0.0
		return true

	var loops: int = int(_media["loops"].call())
	var position: float = float(_media["position"].call())

	#@ Step 1 - Place the cut:
	if _cut_loop < 0:
		var length: float = float(_media["length"].call())

		#% Unknown length - learn it from the first rollover:
		if length <= 0.0:
			if loops > _seen_loops and _furthest > 0.0:
				length = _furthest
			else:
				_furthest = maxf(_furthest, position)
			_seen_loops = loops

		if length <= 0.0:
			#% Still unknown - cut inside the first counted loop only:
			if loops == base_loops and position >= seconds:
				_cut(seconds)
				return false
			return true

		if not _place_cut(length, loops):
			return false

	#@ Step 2 - Cut once reached:
	if _cut_at <= 0.0:
		return false		#/ Whole loop: the loop count ends it
	if loops > _cut_loop or (loops == _cut_loop and position >= _cut_at):
		_cut(_cut_at)
		return false
	return true


#* Place the cut and set the loop count; false when done:
func _place_cut(length: float, loops: int) -> bool:
	var whole: int = int(floor(seconds / length))
	var rest: float = seconds - float(whole) * length
	if rest >= length - LOOP_TOLERANCE:
		whole += 1
		rest = 0.0
	elif rest <= LOOP_TOLERANCE:
		rest = 0.0

	_cut_loop = base_loops + whole
	_cut_at = rest

	#¦ 1. Whole loop:
	if rest <= 0.0:
		if loops >= _cut_loop:
			_cut(length)		#/ Already past it
			return false
		_media["set_loops"].call(_cut_loop)
		return false

	#¦ 2. Loops holding the cut:
	_media["set_loops"].call(_cut_loop + 1)
	return true


#* End the playback at 'at' in the current loop:
func _cut(at: float) -> void:
	var end: Callable = _media["end"]
	_end()
	end.call(maxf(at - SETTLE_BACKOFF, 0.0))


#* Mark the duration over:
func _end() -> void:
	_done = true
	_media = {}		#/ Drop the Callables (reference cycle)
