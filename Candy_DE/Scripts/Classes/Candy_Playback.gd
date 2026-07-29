#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyPlayback
extends RefCounted


#^ Wait loop cutoff when a stream's length is unknown:
const MEDIA_WAIT_FALLBACK_MAX: float = 600.0
#^ Fallback frame rate:
const MEDIA_DEFAULT_FPS: float = 30.0
#^ What parse_stop_frame() returns for "Clear" / "X":
#? -1 already means the last frame.
const STOP_FRAME_CLEAR: int = -2
#^ Tolerance for a position to count as on a frame:
#? Absorbs position rounding.
const FRAME_POSITION_TOLERANCE: float = 0.001
#^ frame_at_time() search cutoff:
const FRAME_SEARCH_LIMIT: int = 1 << 30


#^ Shared instance:
static var _shared: CandyPlayback = null

#^ Video frame rates by resource path (-1.0 = unreadable):
var _video_fps_cache: Dictionary = {}

#* Get the shared instance:
static func get_shared() -> CandyPlayback:
	if _shared == null:
		_shared = CandyPlayback.new()
	return _shared


#? 'caller' is in every signature for consistency:
@warning_ignore_start("unused_parameter")

#* Parse a Time value into seconds or a frame target:
func parse_timecode(source: CandyEngine, caller: Object, time_raw: Variant, allow_frames: bool = true) -> Dictionary:
	var result: Dictionary = { "seconds": 0.0, "frame": -1.0 }

	#¦ 1. Number - seconds:
	if typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
		result["seconds"] = float(time_raw)
		return result

	if typeof(time_raw) != TYPE_STRING:
		return result

	var s: String = time_raw.strip_edges()
	if s == "":
		return result

	#¦ 2. Frame target (the caller resolves it):
	if allow_frames and (s.begins_with("f=") or s.begins_with("F=")):
		result["frame"] = float(s.substr(2, s.length()))
		return result

	#¦ 3. Relative frames:
	if allow_frames and relative_frame_sign(source, caller, s) != 0:
		printerr("Candy DE: '", s, "' - \"f+N\" / \"f-N\" moves from the current frame, so it only works where",
			" playback moves (the _Skip commands, pause loops). Give a frame with \"f=N\".")
		return result

	#¦ 4. Timestamp - HH:MM:SS.xx, MM:SS.xx or SS.xx:
	var parts := s.split(":")
	match parts.size():
		3:
			result["seconds"] = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
		2:
			result["seconds"] = int(parts[0]) * 60 + float(parts[1])
		1:
			result["seconds"] = float(parts[0])

	return result

#* Media folder name for a player:
func folder_name(source: CandyEngine, caller: Object, node_name: Variant, player_node: Node = null) -> String:
	if node_name is Node:
		return str(node_name.name)

	var text := str(node_name).strip_edges()
	if text == "" and player_node != null:
		return str(player_node.name)
	return text

#* Get a media player from a name, path key or Node:
func get_player(source: CandyEngine, caller: Object, node_name: Variant, expected_property: String = "") -> Node:
	var node: Node = null

	if node_name is Node:
		node = node_name
	else:
		var key := str(node_name).strip_edges()
		if not source.media_players_paths.has(key):
			printerr("Candy DE: unknown media player → ", key)
			return null
		node = source.get_node_or_null(source.media_player_path(key))

	if node == null:
		return null

	if expected_property != "" and not (expected_property in node):
		printerr("Candy DE: '", node_name, "' is not a ", expected_property.replace("_", " "), " → wrong Node for this command.")
		return null

	return node

#* Collect a Media_ / Effect_ command's players:
func get_media_targets(source: CandyEngine, caller: Object, command_value: Variant, entries_key: String, methods: Array, context: String) -> Array:
	var targets: Array = []

	if typeof(command_value) != TYPE_DICTIONARY:
		printerr(context, ": expected a Dictionary → ", command_value)
		return targets
	#Ł Players - name (or ¢ expression) → settings:
	var players: Variant = command_value.get(entries_key)
	if typeof(players) != TYPE_DICTIONARY:
		printerr(context, ": '", entries_key, "' must be a Dictionary of media players → ", players)
		return targets

	for player_ref in players:
		var player_key: Variant = source.candy_ref.resolve_value(source, source, player_ref, candy_de.candy_ref_symbol)
		var line_settings: Variant = players[player_ref]

		if typeof(line_settings) != TYPE_DICTIONARY:
			printerr(context, ": settings for '", player_ref, "' must be a Dictionary (use {} for none) → ", line_settings)
			continue

		var player_node := get_player(source, caller, player_key)
		if player_node == null:
			printerr(context, ": missing or invalid player node → ", player_ref)
			continue

		#% Player missing one of 'methods':
		var missing: Array = []
		for method in methods:
			if not player_node.has_method(method):
				missing.append(str(method) + "()")
		if not missing.is_empty():
			printerr(context, ": '", player_ref, "' can't do this: its script has no ", ", ".join(missing), " → ", player_node.name)
			continue

		#Ł Resolve settings through CandyRef:
		var settings: Dictionary = {}
		for setting_key in line_settings:
			settings[setting_key] = source.candy_ref.resolve_value(source, source, line_settings[setting_key], candy_de.candy_ref_symbol)

		if not admit(source, caller, player_node, player_ref, settings.get("Take_Hold", 0), context):
			continue

		var candy_args: Dictionary = {
			"caller": source,
			"key": folder_name(source, caller, player_key, player_node),			#/ Line name, also the files sub-folder
			"command": context,
		}

		targets.append([player_node, candy_args, settings, CandyCustomData.levels([command_value, line_settings])])

	return targets			#/ [player_node, candy_args, settings, custom_data] per player, in line order

#* Ask a player whether it admits a command:
#? 'caller' is the command: its file name is the command name.
func admit(source: CandyEngine, caller: Object, player_node: Node, player_ref: Variant, take_hold_raw: Variant, context: String) -> bool:
	#% No admit_command() - accepts everything:
	if not player_node.has_method("admit_command"):
		if "caller" in player_node:
			player_node.caller = source
		return true

	#% Empty - the player decides:
	var take_hold: int = 0
	if str(take_hold_raw).strip_edges() != "":
		take_hold = int(take_hold_raw)

	var rejection: String = player_node.admit_command(source, command_name(source, caller, context), take_hold)
	if rejection != "":
		#Ł Name a Node player:
		var label := str(player_ref)
		if player_ref is Node:
			label = str(player_ref.name)
		push_warning(context + ": '" + label + "' ignored the command - " + rejection + ".")
		return false

	return true

#* Command name of a script (its file name):
func command_name(source: CandyEngine, caller: Object, fallback: String) -> String:
	if caller != null and caller.get_script() != null:
		var path: String = caller.get_script().resource_path
		if path != "":
			return path.get_file().get_basename()
	return fallback			#/ No script file (e.g. game code)

#* Whether a player is playing something dialogue can wait on:
func is_media_active(source: CandyEngine, caller: Object, player_node: Node) -> bool:
	if player_node == null or not is_instance_valid(player_node):
		return false
	return player_node.get("media_active") == true

#* Resolve a held-player setting:
#? 'setting': "suspend_held_media" or "end_held_media".
func resolve_held_setting(source: CandyEngine, caller: Object, player_node: Node, setting: String) -> bool:
	#@ Step 1 - Candy_Properties.gd (default if it lacks it):
	var value: bool = true
	var property_value = candy_de.get(setting)
	if property_value != null:
		value = bool(property_value)

	#@ Step 2 - Engine, through its "enable_" switch:
	if source.get("enable_" + setting) == true:
		value = bool(source.get(setting))

	#@ Step 3 - Player, through its "enable_" switch:
	if player_node.get("enable_" + setting) == true:
		value = bool(player_node.get(setting))

	return value

#* Change a player's volume, absolute or relative, instantly or over time:
#? 'stream_property': property holding the volume_db node, or "" for the player itself.
func apply_volume_change(source: CandyEngine, caller: Object, player_node: Node, stream_property: String,
		value: Variant, time: Variant, context: String) -> Tween:

	#@ Step 1 - Validate player and stream node:
	if player_node == null or not is_instance_valid(player_node) or (stream_property != "" and not (stream_property in player_node)):
		printerr(context, ": invalid or missing player node → ", player_node)
		return null

	var stream_node = player_node
	if stream_property != "":
		stream_node = player_node.get(stream_property)
	if stream_node == null or not ("volume_db" in stream_node):
		printerr(context, ": player has no volume to set → ", player_node.name)
		return null

	#@ Step 2 - Absolute or relative:
	#? "-6", "+3", "3"  → absolute volume in dB.
	#? "-=6", "+=3"     → relative to the current volume.
	var value_str: String = str(value).strip_edges()
	var relative_sign: float = 0.0
	if value_str.begins_with("+="):
		relative_sign = 1.0
		value_str = value_str.substr(2).strip_edges()
	elif value_str.begins_with("-="):
		relative_sign = -1.0
		value_str = value_str.substr(2).strip_edges()

	if not value_str.is_valid_float():
		printerr(context, ": invalid volume value → ", str(value))
		return null

	#% Pause loop at its own volume - change the volume it returns to:
	var pause_loop: Variant = player_node.get("pause_loop")
	var redirected: bool = pause_loop is CandyPauseLoop and pause_loop.holds_volume()

	var target_volume: float = float(value_str)
	if relative_sign != 0.0:
		if redirected:
			target_volume = pause_loop.volume_before + relative_sign * target_volume
		else:
			target_volume = stream_node.volume_db + relative_sign * target_volume

	if redirected:
		pause_loop.volume_before = target_volume
		return null

	#@ Step 3 - Parse time and "!" prefix:
	var blocking: bool = false
	var time_str: String = str(time).strip_edges()
	if time_str.begins_with("!"):
		blocking = true
		time_str = time_str.substr(1)
	var time_value: float = float(time_str)

	#@ Step 4 - Cancel previous volume tween:
	#? get_meta() errors on a null default.
	if player_node.has_meta("candy_volume_tween"):
		var old_tween = player_node.get_meta("candy_volume_tween")
		if old_tween is Tween and old_tween.is_valid():
			old_tween.kill()
		player_node.remove_meta("candy_volume_tween")

	#@ Step 5 - Instant:
	if time_value <= 0.0:
		stream_node.volume_db = target_volume
		return null

	#@ Step 6 - Tween:
	#? Target kept for volume_target().
	var tween: Tween = player_node.create_tween()
	player_node.set_meta("candy_volume_tween", tween)
	player_node.set_meta("candy_volume_target", target_volume)
	tween.tween_property(stream_node, "volume_db", target_volume, time_value)

	#Ł Register, pruning finished tweens:
	_prune_volume_tweens(source, caller)
	source.active_volume_tweens.append(tween)
	if source.dialogue_suspended == true and source.suspend_media == true:
		tween.pause()			#/ Hold until resumed

	if not blocking:
		return null

	return tween			#/ "!": wait on it with await_tween()

#* Volume a player is heading to (a running fade's target), else its current volume:
func volume_target(source: CandyEngine, caller: Object, player_node: Node, stream_property: String) -> float:
	if player_node == null or not is_instance_valid(player_node) or (stream_property != "" and not (stream_property in player_node)):
		return 0.0
	var stream_node = player_node
	if stream_property != "":
		stream_node = player_node.get(stream_property)
	if stream_node == null or not ("volume_db" in stream_node):
		return 0.0

	if player_node.has_meta("candy_volume_tween") and player_node.has_meta("candy_volume_target"):
		var tween = player_node.get_meta("candy_volume_tween")
		if tween is Tween and tween.is_valid() and tween.is_running():
			return float(player_node.get_meta("candy_volume_target"))

	return float(stream_node.volume_db)

#* Wait for a volume fade, frozen while suspended:
func await_tween(source: CandyEngine, caller: Object, tween: Tween) -> String:
	if tween == null:
		return "Continue"

	#? kill() doesn't emit finished: poll.
	while tween.is_valid() and tween.is_running():
		if source.killswitch == true:
			return "END"
		await source.get_tree().process_frame

		#% Freeze while suspended:
		if source.dialogue_suspended == true:
			tween.pause()
			await source._await_suspension()
			if tween.is_valid():
				tween.play()
			continue

	return "Continue"

#* Prune finished volume tweens:
func _prune_volume_tweens(source: CandyEngine, caller: Object) -> void:
	var live: Array = []
	for tween in source.active_volume_tweens:
		if tween is Tween and tween.is_valid():
			live.append(tween)
	source.active_volume_tweens = live

#* Playback position, in seconds:
func _media_position(source: CandyEngine, caller: Object, player_node: Node, stream_property: String) -> float:
	if player_node == null or not is_instance_valid(player_node):
		return 0.0

	if player_node.has_method("get_media_position"):
		return float(player_node.get_media_position())

	var stream_node = player_node.get(stream_property)
	if stream_node == null:
		return 0.0

	if stream_node.has_method("get_playback_position"):
		return float(stream_node.get_playback_position())
	if "stream_position" in stream_node:
		return float(stream_node.stream_position)

	return 0.0

#* Length of one playback loop, in seconds, or 0.0 if unknown:
func _media_length(source: CandyEngine, caller: Object, player_node: Node, stream_property: String) -> float:
	if player_node == null or not is_instance_valid(player_node):
		return 0.0

	if player_node.has_method("get_media_length"):
		return float(player_node.get_media_length())

	var stream_node = player_node.get(stream_property)
	if stream_node == null:
		return 0.0

	#¦ 1. VideoStreamPlayer:
	if stream_node.has_method("get_stream_length"):
		return float(stream_node.get_stream_length())

	#¦ 2. AudioStream - length on the resource:
	if "stream" in stream_node and stream_node.stream != null and stream_node.stream.has_method("get_length"):
		return float(stream_node.stream.get_length())

	return 0.0

#* Whether a player is mid-playback:
func _media_is_playing(source: CandyEngine, caller: Object, player_node: Node, stream_property: String) -> bool:
	if player_node == null or not is_instance_valid(player_node):
		return false

	if player_node.has_method("is_media_playing"):
		return bool(player_node.is_media_playing())

	var stream_node = player_node.get(stream_property)
	if stream_node == null:
		return false

	#% Paused counts as playing:
	if "stream_paused" in stream_node and stream_node.stream_paused == true:
		return true
	if "paused" in stream_node and stream_node.paused == true:
		return true

	if "playing" in stream_node:
		return bool(stream_node.playing)
	if stream_node.has_method("is_playing"):
		return bool(stream_node.is_playing())

	return true

#* Whether a player is paused:
func _media_is_paused(source: CandyEngine, caller: Object, player_node: Node, stream_property: String) -> bool:
	if player_node == null or not is_instance_valid(player_node):
		return false

	#% A pause loop plays, but counts as paused:
	var pause_loop: Variant = player_node.get("pause_loop")
	if pause_loop is CandyPauseLoop and pause_loop.holds_pause():
		return true

	if player_node.has_method("is_media_paused"):
		return bool(player_node.is_media_paused())

	var stream_node = player_node.get(stream_property)
	if stream_node != null:
		if "stream_paused" in stream_node and stream_node.stream_paused == true:
			return true
		if stream_node is VideoStreamPlayer and stream_node.paused == true:
			return true

	var timer = player_node.get("timer")
	if timer is Timer and timer.paused and not timer.is_stopped():
		return true

	return false

#* Stop a stream from looping by itself:
func _disable_stream_loop(source: CandyEngine, caller: Object, stream_node) -> void:
	if stream_node == null or not is_instance_valid(stream_node):
		return

	if stream_node is VideoStreamPlayer and "loop" in stream_node:
		stream_node.loop = false

	if not ("stream" in stream_node):
		return
	var stream = stream_node.stream

	if stream is AudioStreamWAV:
		if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
			var copy = stream.duplicate()
			copy.loop_mode = AudioStreamWAV.LOOP_DISABLED
			stream_node.stream = copy
	elif stream is AudioStream and "loop" in stream:
		if stream.loop == true:
			var copy = stream.duplicate()
			copy.loop = false
			stream_node.stream = copy

#* Resolve a media's frame rate:
#? 'setting': "default_<kind>_fps" (animated_image, sprite, animated_sprite, video, effect).
func resolve_fps(source: CandyEngine, caller: Object, setting: String, command_fps: Variant,
		element_fps: Variant = 0.0, own_fps: float = 0.0, file_path: String = "") -> float:
	#@ Step 1 - Line's "FPS":
	if str(command_fps).strip_edges() != "":
		var line_fps := float(command_fps)
		if line_fps > 0.0:
			return line_fps

	#@ Step 2 - Media's own rate (frame folder's config.txt, video stream):
	if own_fps > 0.0:
		return own_fps

	#@ Step 3 - Folder's config.txt ("Files" entry, else "fps"):
	var folder_fps := CandyMedia.file_config_fps(file_path)
	if folder_fps > 0.0:
		return folder_fps

	#@ Step 4 - UI element or player:
	if float(element_fps) > 0.0:
		return float(element_fps)

	#@ Step 5 - Engine:
	if source != null and setting in source and float(source.get(setting)) > 0.0:
		return float(source.get(setting))

	#@ Step 6 - Candy_Properties.gd:
	var property_fps = candy_de.get(setting)
	if property_fps != null and float(property_fps) > 0.0:
		return float(property_fps)

	printerr("Candy_Properties.gd: '", setting, "' is missing or not above 0. Falling back to ", MEDIA_DEFAULT_FPS, " fps.")
	return MEDIA_DEFAULT_FPS

#* SpriteFrames with a playable speed for 'anim':
func sprite_frames_with_speed(source: CandyEngine, caller: Object, frames: SpriteFrames, anim: String,
		command_fps: Variant, element_fps: Variant = 0.0, file_path: String = "") -> SpriteFrames:
	if frames == null or not frames.has_animation(anim) or frames.get_animation_speed(anim) > 0.0:
		return frames
	#% Speed 0 - a copy (the resource is shared) at the "default_animated_sprite_fps" rate:
	var copy: SpriteFrames = frames.duplicate()
	copy.set_animation_speed(anim, resolve_fps(source, caller, "default_animated_sprite_fps", command_fps, element_fps, 0.0, file_path))
	return copy

#* File an AnimationPlayer's animation was loaded from:
func animation_library_file(source: CandyEngine, caller: Object, player: Node, anim_name: String) -> String:
	if not (player is AnimationMixer):
		return ""
	#Ł "Library/Name", else a global one:
	var library_name := ""
	if "/" in anim_name:
		library_name = anim_name.get_slice("/", 0)
	if not player.has_animation_library(library_name):
		return ""
	var path := str(player.get_animation_library(library_name).resource_path)
	if path == "" or "::" in path:
		return ""			#/ Built into the scene or made at runtime
	return path

#* Resolve the extension for a file named without one:
#? 'setting': "default_<kind>_extension" (image, sprite, animated_sprite, video, audio, voice).
func resolve_extension(source: CandyEngine, caller: Object, setting: String, element_ext: Variant = "") -> String:
	var extension := ""

	#@ Step 1 - UI element or player:
	if element_ext != null:
		extension = str(element_ext).strip_edges()

	#@ Step 2 - Engine:
	if extension == "" and source != null and setting in source:
		extension = str(source.get(setting)).strip_edges()

	#@ Step 3 - Candy_Properties.gd:
	if extension == "":
		var property_ext = candy_de.get(setting)
		if property_ext != null:
			extension = str(property_ext).strip_edges()
		if extension == "":
			printerr("Candy_Properties.gd: '", setting, "' is missing or empty.")
			return ""

	#@ Step 4 - Starts with ".":
	if not extension.begins_with("."):
		extension = "." + extension
	return extension

#* Resolve a time value into seconds:
func resolve_time_target(source: CandyEngine, caller: Object, time_raw: Variant, allow_frames: bool, fps: float = 0.0,
		frame_to_time: Callable = Callable()) -> float:
	var parsed := parse_timecode(source, caller, time_raw, allow_frames)
	var target_seconds: float = float(parsed["seconds"])

	#% "f=" - 'frame_to_time' (unevenly spaced frames), else 'fps':
	if allow_frames and float(parsed["frame"]) >= 0.0:
		if frame_to_time.is_valid():
			target_seconds = float(frame_to_time.call(float(parsed["frame"])))
		elif fps > 0.0:
			target_seconds = float(parsed["frame"]) / fps

	return target_seconds

#* Resolve a seek value from the player's current position:
func resolve_seek_target(source: CandyEngine, caller: Object, player_node: Node, stream_property: String,
		time_raw: Variant, allow_frames: bool, fps: float = 0.0, frame_to_time: Callable = Callable()) -> float:

	var current_pos: float = _media_position(source, caller, player_node, stream_property)
	return resolve_relative_time(source, caller, current_pos, time_raw, allow_frames, fps, frame_to_time)

#* Resolve a time value from the current position, in seconds:
func resolve_relative_time(source: CandyEngine, caller: Object, current_pos: float, time_raw: Variant,
		allow_frames: bool, fps: float = 0.0, frame_to_time: Callable = Callable()) -> float:

	#% Number - offset:
	if typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
		return max(0.0, current_pos + float(time_raw))

	if typeof(time_raw) != TYPE_STRING:
		return current_pos

	var s: String = time_raw.strip_edges()

	#@ Step 1 - Relative frames ("f+N" / "f-N"):
	#? Counted on frame indexes: frames aren't always evenly spaced.
	var frame_sign := relative_frame_sign(source, caller, s)
	if allow_frames and frame_sign != 0:
		var converter := frame_to_time
		if not converter.is_valid():
			if fps <= 0.0:
				return current_pos
			converter = func(frame: float) -> float:
				return frame / fps
		var current_frame := frame_at_time(source, caller, current_pos, converter)
		var target_frame := maxf(float(current_frame) + frame_sign * float(s.substr(2)), 0.0)
		return max(0.0, float(converter.call(target_frame)))

	#@ Step 2 - Strip relative prefix:
	var direction: int = 0
	if s.begins_with("+"):
		direction = 1
		s = s.substr(1).strip_edges()
	elif s.begins_with("-"):
		direction = -1
		s = s.substr(1).strip_edges()

	#% A signed "f=N" would move by frame N's time, not N frames:
	if allow_frames and direction != 0 and s.to_lower().begins_with("f="):
		printerr("Candy DE: '", time_raw, "' - to move by frames, write \"f+N\" / \"f-N\".")
		return current_pos

	#@ Step 3 - Parse the remainder (timestamp or "f=N"):
	var target_time: float = resolve_time_target(source, caller, s, allow_frames, fps, frame_to_time)

	#@ Step 4 - Apply the offset:
	if direction != 0:
		target_time = max(0.0, current_pos + direction * target_time)

	return target_time

#* Sign of an "f+N" / "f-N" value (any case):
func relative_frame_sign(source: CandyEngine, caller: Object, text: String) -> int:
	var lowered := text.strip_edges().to_lower()
	if lowered.begins_with("f+"):
		return 1
	if lowered.begins_with("f-"):
		return -1
	return 0

#* Frame showing at a position (from 0) - the last starting at or before it:
func frame_at_time(source: CandyEngine, caller: Object, position: float, frame_to_time: Callable) -> int:
	var limit := position + FRAME_POSITION_TOLERANCE
	var first_start := float(frame_to_time.call(0.0))
	if first_start > limit:
		return -1			#/ Before the first frame

	#Ł Double until past the position, or frames stop advancing:
	var low := 0				#/ Furthest frame starting at or before the position
	var previous_low := -1		#/ The one before it
	var high := 1
	var low_start := first_start
	while high < FRAME_SEARCH_LIMIT:
		var high_start := float(frame_to_time.call(float(high)))
		if high_start > limit:
			#% The frame before the first one past the position:
			return _first_frame_where(frame_to_time, low, high,
				func(start: float) -> bool:
					return start > limit) - 1
		if high_start <= low_start:
			#% Frames ended (the first frame starting no earlier than 'low'):
			#? Past the last frame: the frame after it (the end).
			return _first_frame_where(frame_to_time, previous_low, low,
				func(start: float) -> bool:
					return start >= low_start)
		previous_low = low
		low = high
		low_start = high_start
		high *= 2

	return low

#* First frame after 'low', up to 'high', whose start passes 'test':
func _first_frame_where(frame_to_time: Callable, low: int, high: int, test: Callable) -> int:
	while high - low > 1:
		@warning_ignore("integer_division")
		var middle := low + (high - low) / 2
		if test.call(float(frame_to_time.call(float(middle)))):
			high = middle
		else:
			low = middle
	return high

#* Wait until a player reaches a target loop and timestamp:
func await_target(source: CandyEngine, caller: Object, player_node: Node, stream_property: String,
		wait: int, target_seconds: float, loop_cap: int) -> String:

	#@ Step 1 - Nothing to wait for:
	if player_node == null or not is_instance_valid(player_node):
		return "Continue"
	if wait <= 0 and target_seconds <= 0.0:
		return "Continue"

	#@ Step 2 - Fold an overshooting timestamp into the target loop:
	var media_length: float = _media_length(source, caller, player_node, stream_property)
	var target_loop: int = wait
	var offset_time: float = target_seconds
	if media_length > 0.0:
		var loop_offset: int = int(target_seconds / media_length)
		offset_time = target_seconds - (loop_offset * media_length)
		target_loop = wait + loop_offset

	var prev_loops: int = player_node.loops_played
	var prev_pos: float = 0.0
	var warned_open_pause := false
	var idle_at_loop: int = -1		#/ loops_played when last seen idle, -1 = not idle

	#@ Step 3 - Poll until reached or ended:
	while is_media_active(source, caller, player_node):
		#% Killswitch:
		if source.killswitch == true:
			return "END"

		#% Freeze while suspended:
		if source.dialogue_suspended == true:
			await source._await_suspension()
			continue

		#% Playback ended or stopped:
		#? One idle frame is a loop boundary; two in a row with no loop counted means stopped.
		if not _media_is_playing(source, caller, player_node, stream_property):
			if idle_at_loop == player_node.loops_played:
				break
			idle_at_loop = player_node.loops_played
			await source.get_tree().process_frame
			continue
		idle_at_loop = -1

		#% Paused by Media_Pause or Effect_Pause:
		if _media_is_paused(source, caller, player_node, stream_property):
			if "pause_count" in player_node and int(player_node.pause_count) > 0:
				push_warning("Candy DE: wait released - '%s' is paused for %d more line(s), which can't elapse while the dialogue waits." % [player_node.name, int(player_node.pause_count)])
				break
			if not warned_open_pause:
				warned_open_pause = true
				push_warning("Candy DE: waiting on '%s', which is paused with no line count - dialogue stays blocked until it is resumed from outside the dialogue." % player_node.name)
			await source.get_tree().process_frame
			continue

		var position: float = _media_position(source, caller, player_node, stream_property)

		#% Length unknown - learn it from the first rollover:
		if media_length <= 0.0:
			if player_node.loops_played > prev_loops and prev_pos > 0.0:
				media_length = prev_pos
				var loop_offset: int = int(target_seconds / media_length)
				offset_time = target_seconds - (loop_offset * media_length)
				target_loop = wait + loop_offset

			#Ł Furthest position this playback:
			if player_node.loops_played == prev_loops:
				prev_pos = max(prev_pos, position)
			else:
				prev_pos = position
			prev_loops = player_node.loops_played

			#% Cutoff - length never learned:
			if position > MEDIA_WAIT_FALLBACK_MAX:
				break

		#% Player's loop cap:
		if loop_cap > 0 and player_node.loops_played >= loop_cap:
			break

		#% Past the target playback:
		if player_node.loops_played > target_loop:
			break

		#% Timestamp reached in the target playback:
		if player_node.loops_played == target_loop and position >= offset_time:
			break

		await source.get_tree().process_frame

	return "Continue"

#* Set a "pause for N lines" on a player:
#? Or any object with pause_count / pause_mode / pause_engine / unpause() (e.g. CandyCutscene's handle).
func set_pause(source: CandyEngine, caller: Object, player_node: Object, line_count: int, count_all: int) -> void:
	if player_node == null or not is_instance_valid(player_node):
		return
	if not ("pause_count" in player_node):
		return

	player_node.pause_count = line_count
	player_node.pause_mode = "speech"

	if line_count <= 0:
		return

	#Ł The issuing engine counts it down:
	if "pause_engine" in player_node:
		player_node.pause_engine = source
	if not (player_node in source.line_paused_media_players):
		source.line_paused_media_players.append(player_node)

	if count_all == 1:
		player_node.pause_mode = "all"
		player_node.pause_count = line_count + 1

#* Clear a player's "pause for N lines":
func clear_pause(source: CandyEngine, caller: Object, player_node: Node, stream_property: String = "") -> bool:
	if player_node == null or not is_instance_valid(player_node):
		return false

	if player_node.has_method("unpause"):
		player_node.unpause()
		return true

	#% No unpause() - unpause the stream node:
	var resumed: bool = false
	var stream_node = null
	if stream_property != "":
		stream_node = player_node.get(stream_property)
	if stream_node != null:
		if "stream_paused" in stream_node:
			stream_node.stream_paused = false
			resumed = true
		elif "paused" in stream_node:
			stream_node.paused = false
			resumed = true

	if "pause_count" in player_node:
		player_node.pause_count = 0
	if "pause_mode" in player_node:
		player_node.pause_mode = "speech"

	return resumed

#* Parse a Loops value:
func normalize_loop(source: CandyEngine, caller: Object, loop_raw: Variant) -> int:
	if str(loop_raw).strip_edges() == "":
		return 1
	var loop: int = int(loop_raw)
	if loop < 0:
		return -1
	return loop

#* Parse a "Stop_Frame" value:
func parse_stop_frame(source: CandyEngine, caller: Object, value: Variant, fallback: int, context: String,
		can_clear: bool = true) -> int:
	if value == null:
		return fallback

	#% Unquoted number:
	if typeof(value) == TYPE_INT:
		if int(value) >= -1:
			return int(value)
	elif typeof(value) == TYPE_FLOAT:
		if float(value) == floorf(float(value)) and float(value) >= -1.0:
			return int(value)
	else:
		var text := str(value).strip_edges()
		if text == "":
			return fallback

		var lowered := text.to_lower()
		if (lowered == "clear" or lowered == "x") and can_clear:
			return STOP_FRAME_CLEAR

		if text.is_valid_int() and text.to_int() >= -1:
			return text.to_int()

	#% Invalid (or "Clear" without 'can_clear'):
	if can_clear:
		printerr(context, ": invalid Stop_Frame → ", value, " (use -1, 0, a frame number, \"Clear\" or \"X\")")
	else:
		printerr(context, ": invalid Stop_Frame → ", value, " (use -1, 0 or a frame number)")
	return fallback

#* Stop an AnimationPlayer on a frame, keeping its pose:
#? 'stop_frame': from parse_stop_frame(), not STOP_FRAME_CLEAR.
func settle_animation(source: CandyEngine, caller: Object, player: AnimationPlayer, stop_frame: int, frame_to_time: Callable) -> void:
	if player == null or not is_instance_valid(player):
		return

	#Ł stop() resets to 0 - pause to keep the pose:
	player.pause()

	var anim_name := str(player.assigned_animation)
	if stop_frame == 0 or anim_name == "" or not player.has_animation(anim_name):
		return

	var anim: Animation = player.get_animation(anim_name)
	if stop_frame == -1:
		#Ł A looping animation wraps its length to 0 - stop just short:
		var last_time: float = anim.length
		if anim.loop_mode != Animation.LOOP_NONE:
			last_time = maxf(anim.length - 0.0001, 0.0)
		player.seek(last_time, true)
	else:
		player.seek(clampf(float(frame_to_time.call(float(stop_frame - 1))), 0.0, anim.length), true)

#* Pause an AnimationPlayer at 'time', with the pose playing there leaves:
func settle_animation_at(source: CandyEngine, caller: Object, player: AnimationPlayer, time: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	player.pause()
	#Ł Seeking back applies the later of two discrete keys - seek to 0 unapplied, then forward:
	player.seek(0.0, false)
	player.seek(time, true)

#* Clear an AnimationPlayer - RESET pose if any, then stop:
func clear_animation(source: CandyEngine, caller: Object, player: AnimationPlayer) -> void:
	if player == null or not is_instance_valid(player):
		return

	var reset_name := reset_animation(source, caller, player, str(player.assigned_animation))
	#Ł RESET before stop(), to avoid 'blinking' frame 0:
	if reset_name != "":
		player.play(reset_name)
	player.stop()

#* RESET animation for 'animation', or "":
func reset_animation(source: CandyEngine, caller: Object, player: AnimationPlayer, animation: String) -> String:
	if player == null or not is_instance_valid(player):
		return ""

	#¦ 1. Its library's ("FX/Shake" → "FX/RESET"):
	if animation.contains("/"):
		var library_reset := animation.get_slice("/", 0) + "/RESET"
		if player.has_animation(library_reset):
			return library_reset
	#¦ 2. The player's own:
	if player.has_animation("RESET"):
		return "RESET"
	return ""

#* Start a fresh playback and mark the player active:
func begin_playback(source: CandyEngine, caller: Object, player_node: Node, stream_property: String, loop: int) -> void:
	#@ Step 1 - Loop tracking:
	player_node.loop_target = loop
	player_node.loops_played = 0

	#@ Step 2 - Clear leftover pauses:
	clear_pause(source, caller, player_node, stream_property)

	#@ Step 2B - Candy counts loops, so disable the resource's own:
	_disable_stream_loop(source, caller, player_node.get(stream_property))

	player_node.caller = source

	#@ Step 3 - Loops 0 holds on the first frame:
	#? Not marked active: waits on the line resolve at once.
	if loop == 0:
		if "media_active" in player_node:
			player_node.media_active = false
		hold_first_frame(source, caller, player_node, stream_property)
		return

	#@ Step 4 - Mark active:
	if "media_active" in player_node:
		player_node.media_active = true

	#@ Step 5 - Start playback:
	if player_node.has_method("start"):
		player_node.start()
	else:
		var stream_node = player_node.get(stream_property)
		if stream_node != null and stream_node.has_method("play"):
			stream_node.play()

#* Show the first frame without playing:
func hold_first_frame(source: CandyEngine, caller: Object, player_node: Node, stream_property: String) -> void:
	#¦ 1. The player's own:
	if player_node.has_method("hold_first_frame"):
		player_node.hold_first_frame()
		return

	var stream_node = player_node.get(stream_property)
	if stream_node == null:
		return

	#¦ 2. Video - decode one frame, then freeze:
	if stream_node is VideoStreamPlayer:
		stream_node.play()
		stream_node.paused = true
		stream_node.stream_position = 0.0
		return

	#¦ 3. Images and audio - nothing to do:

#* Convert a frame index into a time offset within an animation:
func animation_frame_to_time(source: CandyEngine, caller: Object, anim: Animation, frame: float, fallback_fps: float = 30.0) -> float:
	if anim == null:
		return frame / fallback_fps

	#Ł Reference track - discrete value tracks (sprite frames) first:
	var best_track := -1
	var best_keys := 0
	var best_discrete := false

	for t in anim.get_track_count():
		if anim.track_get_type(t) != Animation.TYPE_VALUE:
			continue

		var keys: int = anim.track_get_key_count(t)
		if keys <= 0:
			continue

		var discrete: bool = anim.value_track_get_update_mode(t) == Animation.UPDATE_DISCRETE

		#% Discrete beats continuous; between equals, more keys wins:
		if best_track == -1 \
		or (discrete and not best_discrete) \
		or (discrete == best_discrete and keys > best_keys):
			best_track = t
			best_keys = keys
			best_discrete = discrete

	#¦ 1. Exact - the key at that index:
	var index := int(round(frame))
	if best_track >= 0 and index >= 0 and index < best_keys:
		return anim.track_get_key_time(best_track, index)

	#¦ 2. Out of range - extrapolate at the track's average rate:
	if best_track >= 0 and best_keys > 1 and anim.length > 0.0:
		return frame / (float(best_keys) / anim.length)

	#¦ 3. No usable track - the timeline step, then the default:
	var fps := fallback_fps
	if anim.step > 0.0 and anim.step != 0.1:
		fps = 1.0 / anim.step

	return frame / fps

#* A video stream's frame rate, or 'fallback':
func video_fps(source: CandyEngine, caller: Object, stream: VideoStream, fallback: float = 0.0) -> float:
	if stream == null:
		return fallback

	var path: String = stream.resource_path
	if path == "":
		return fallback

	#Ł Read the frame rate, or use the cache:
	#? -1.0: unreadable or no Theora stream.
	var fps := -1.0
	if _video_fps_cache.has(path):
		fps = _video_fps_cache[path]
	else:
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			#Ł Find the Theora identification packet in the first Ogg pages:
			#? Beginning-of-stream pages come first.
			var pages_checked := 0
			while pages_checked < 32:
				#Ł Page capture pattern:
				var capture := file.get_buffer(4)
				if capture.size() < 4 or capture.get_string_from_ascii() != "OggS":
					break

				#? version(1) + header_type(1) + granule(8) + serial(4) + sequence(4) + crc(4).
				file.seek(file.get_position() + 22)

				var segment_count := file.get_8()
				if segment_count <= 0:
					break

				var segment_table := file.get_buffer(segment_count)
				if segment_table.size() < segment_count:
					break

				var payload_size := 0
				for i in segment_count:
					payload_size += segment_table[i]

				var payload := file.get_buffer(payload_size)
				if payload.size() < payload_size:
					break

				#% Theora identification header - 0x80 followed by "theora":
				#? FRN occupies bytes 22-25 and FRD bytes 26-29, both big-endian.
				if payload.size() >= 30 and payload[0] == 0x80 \
				and payload.slice(1, 7).get_string_from_ascii() == "theora":
					var frn: int = (payload[22] << 24) | (payload[23] << 16) | (payload[24] << 8) | payload[25]
					var frd: int = (payload[26] << 24) | (payload[27] << 16) | (payload[28] << 8) | payload[29]
					if frd > 0 and frn > 0:
						fps = float(frn) / float(frd)
					break

				pages_checked += 1

			file.close()

		_video_fps_cache[path] = fps

	#% Nothing usable:
	#? A 0.0 fallback lets resolve_fps() use "default_video_fps".
	if fps <= 0.0:
		if fallback > 0.0:
			push_warning("Candy DE: could not read the frame rate from '" + path + "'. Falling back to " + str(fallback) + " fps.")
		else:
			push_warning("Candy DE: could not read the frame rate from '" + path + "'. Falling back to the default_video_fps settings.")
		return fallback

	return fps

#* Exact time of a frame index within a SpriteFrames animation:
func sprite_frames_frame_time(source: CandyEngine, caller: Object, frames: SpriteFrames, anim: String, frame: int) -> float:
	if frames == null or not frames.has_animation(anim):
		return 0.0

	var speed: float = frames.get_animation_speed(anim)
	if speed <= 0.0:
		return 0.0

	var total := 0.0
	for i in min(frame, frames.get_frame_count(anim)):
		total += frames.get_frame_duration(anim, i) / speed

	return total

#* Read a z-order value ("Box", UI_Z's "Z_Index"):
func read_z_value(source: CandyEngine, caller: Object, reference_node: Node, z_value: Variant, key_name: String, context: String) -> Variant:
	#Ł A number reads as it prints (5 is exact, -2 is relative):
	var text: String = str(z_value).strip_edges()
	if typeof(z_value) == TYPE_FLOAT:
		text = str(int(z_value))

	if text == "":
		return {}			#/ Leave alone

	if text.to_lower() == "reset":
		return {"reset": true}

	if not text.is_valid_int():
		printerr(context, ": invalid ", key_name, " value (use Reset, a number, +n or -n) → ", z_value)
		return null

	var target_z: int = int(text)

	#% Signed - relative to the reference node:
	if text.begins_with("+") or text.begins_with("-"):
		if reference_node == null or not is_instance_valid(reference_node) or not (reference_node is CanvasItem):
			printerr(context, ": ", key_name, " '", text, "' is relative, but there is no node with a z index to count from.")
			return null
		target_z = reference_node.z_index + target_z

	#? Godot rejects z indexes outside this range.
	return {"z": clampi(target_z, RenderingServer.CANVAS_ITEM_Z_MIN, RenderingServer.CANVAS_ITEM_Z_MAX)}

#* Set the dialogue UI's z-order (box, subtitles, chat, barks):
func apply_overlay_z(source: CandyEngine, caller: Object, reference_node: Node, box_value: Variant, context: String) -> bool:
	#@ Step 1 - Read the value:
	var z_order: Variant = read_z_value(source, caller, reference_node, box_value, "Box", context)
	if z_order == null:
		return false
	if z_order.is_empty():
		return true

	#@ Step 2 - Apply to each overlay element:
	#? The portrait moves with the dialogue box.
	for key in ["dialogue_box_path", "subtitles_path", "chat_path", "barks_path"]:
		var node := CandyUI.get_shared().get_element(source, source, key)
		if node == null or not (node is CanvasItem):
			continue
		if z_order.has("reset"):
			if "default_z" in node:
				node.z_index = node.default_z
		else:
			node.z_index = z_order["z"]

	return true

@warning_ignore_restore("unused_parameter")
