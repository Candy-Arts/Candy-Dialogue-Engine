#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyCutscene
extends RefCounted


#^ Fallback node names, when a target is given no "Node":
const CS_ANIM_FALLBACKS: Array = ["AnimationPlayer", "AnimationTree"]
const CS_SPRITE_FALLBACKS: Array = ["Sprite2D", "Sprite3D", "AnimatedSprite2D", "AnimatedSprite3D"]

#^ State an AnimationTree is sent to by CS_Anim_Stop with Default = -1:
#TODO: Rename if your state machines use a different resting state.
const CS_ANIM_TREE_IDLE: String = "Idle"

#^ Spritesheet frame Timer name:
const CS_SPRITE_TIMER: String = "CSSpriteTimer"


#^ "Lines" pause on a cutscene node:
#? Kept in the node's "cs_pause" meta: cutscene nodes have no Candy DE script.
class CSPauseHandle extends RefCounted:
	var pause_count: int = 0
	var pause_mode: String = "speech"
	var pause_engine: Node = null
	var node: Node = null

	#* Called when the line count runs out:
	func unpause() -> void:
		pause_count = 0
		if node != null and is_instance_valid(node):
			CandyCutscene.get_shared().unpause_node(pause_engine, self, node)


#^ Shared instance:
static var _shared: CandyCutscene = null

#* Get the shared instance:
static func get_shared() -> CandyCutscene:
	if _shared == null:
		_shared = CandyCutscene.new()
	return _shared


#? 'caller' is unused in some functions:
@warning_ignore_start("unused_parameter")

#?##############################
#& TARGETS:
#?#########
#region - Targets
#* Get a CS_ command's targets, settings resolved:
func get_targets(source: CandyEngine, caller: Object, command_value: Variant, entries_key: String, context: String) -> Array:
	var targets: Array = []

	if typeof(command_value) != TYPE_DICTIONARY:
		printerr(context, ": expected a Dictionary → ", command_value)
		return targets
	var nodes: Variant = command_value.get(entries_key)
	if typeof(nodes) != TYPE_DICTIONARY:
		printerr(context, ": '", entries_key, "' must be a Dictionary of target nodes → ", nodes)
		return targets

	for target_ref in nodes:
		var line_settings: Variant = nodes[target_ref]
		if typeof(line_settings) != TYPE_DICTIONARY:
			printerr(context, ": settings for '", target_ref, "' must be a Dictionary (use {} for none) → ", line_settings)
			continue

		var node := resolve_target(source, caller, target_ref, context)
		if node == null:
			continue

		var label := str(target_ref)
		if target_ref is Node:
			label = str(node.name)

		#? Nested Dictionaries (CS_Position's "Nodes", CS_Scene's "Instances") are left unresolved.
		targets.append([node, resolve_settings(source, caller, line_settings), label, CandyCustomData.levels([command_value, line_settings])])

	return targets			#/ [node, settings, label, custom_data] per target, in line order


#* Resolve settings through CandyRef:
func resolve_settings(source: CandyEngine, caller: Object, line_settings: Dictionary) -> Dictionary:
	var settings: Dictionary = {}
	for setting_key in line_settings:
		settings[setting_key] = source.candy_ref.resolve_value(source, source, line_settings[setting_key], candy_de.candy_ref_symbol)
	return settings


#* Find the node a CS_ key names:
func resolve_target(source: CandyEngine, caller: Object, ref: Variant, context: String) -> Node:
	var value: Variant = source.candy_ref.resolve_value(source, source, ref, candy_de.candy_ref_symbol)

	#% A Node:
	if value is Node:
		if is_instance_valid(value):
			return value
		printerr(context, ": target node no longer exists → ", ref)
		return null

	var text := str(value).strip_edges()
	if text == "":
		printerr(context, ": empty target.")
		return null

	var node: Node = null
	var slash := text.find("/")

	#¦ 1. "<cs_paths key>/<path>":
	if slash > 0 and source.cs_paths.has(text.substr(0, slash)):
		var container := container_node(source, caller, text.substr(0, slash), context)
		if container == null:
			return null

		#Ł Last part may be a °role:
		var parts := text.substr(slash + 1).split("/")
		var role_target = resolve_role(source, caller, parts[parts.size() - 1], context)
		if role_target == null:
			return null
		parts[parts.size() - 1] = str(role_target)

		node = container.get_node_or_null(NodePath("/".join(parts)))

	#¦ 2. A node path:
	else:
		if CandyActors.get_shared().role_name(source, caller, text) != "":
			printerr(context, ": a °role needs the container its node lives in, e.g. 'Actors/", text, "' → ", text)
			return null
		node = source.get_node_or_null(NodePath(text))

	if node == null:
		printerr(context, ": node not found → ", text)
	return node


#* Resolve a cs_paths key into its container node:
func container_node(source: CandyEngine, caller: Object, path_key: Variant, ctx: String, label: String = "container") -> Node:
	var container := source.get_node_or_null(source.cs_paths.get(path_key, ""))
	if not container:
		printerr(ctx, ": invalid ", label, " → ", path_key)
	return container


#* Resolve a °role into its node name:
func resolve_role(source: CandyEngine, caller: Object, ref: Variant, ctx: String, label: String = "target") -> Variant:
	var key := CandyActors.get_shared().role_name(source, caller, ref)
	if key == "":
		return ref

	if candy_de.roles.has(key):
		return candy_de.roles[key]

	printerr(ctx, ": Unknown role ", label, " → ", ref)
	return null


#* Resolve a target's "Node" setting:
func resolve_node(source: CandyEngine, caller: Object, target_node: Node, node_ref: Variant, fallbacks: Array = []) -> Node:
	if target_node == null or not is_instance_valid(target_node):
		return null

	#% Node itself:
	if node_ref is Node:
		if is_instance_valid(node_ref):
			return node_ref
		return null

	var key: String = str(node_ref).strip_edges()

	if key != "":
		#% internal_node_dict first:
		if "internal_node_dict" in target_node and target_node.internal_node_dict.has(key):
			var mapped = target_node.internal_node_dict[key]
			if mapped is Node:
				if is_instance_valid(mapped):
					return mapped
				return null
			#% Stored path:
			return target_node.get_node_or_null(NodePath(str(mapped)))
		return target_node.get_node_or_null(NodePath(key))		#/ Path relative to the target

	#% Empty - the target itself, if of a usable type:
	for fallback in fallbacks:
		if target_node.is_class(str(fallback)):
			return target_node

	#Ł Else its first child named in 'fallbacks':
	for fallback in fallbacks:
		var node: Node = target_node.get_node_or_null(NodePath(fallback))
		if node:
			return node

	return null


#* A CS_Anim_ target's AnimationPlayer / AnimationTree, or null:
func anim_node(source: CandyEngine, caller: Object, target_node: Node, settings: Dictionary, context: String) -> Node:
	var node := resolve_node(source, caller, target_node, settings.get("Node", ""), CS_ANIM_FALLBACKS)
	if node == null:
		printerr(context, ": no AnimationPlayer or AnimationTree found for → ", target_node.name)
	elif not (node is AnimationPlayer or node is AnimationTree):
		printerr(context, ": not an AnimationPlayer or AnimationTree → ", node.name)
		return null
	return node


#* A CS_Sprite_ target's sprite node, or null:
func sprite_node(source: CandyEngine, caller: Object, target_node: Node, settings: Dictionary, context: String) -> Node:
	var node := resolve_node(source, caller, target_node, settings.get("Node", ""), CS_SPRITE_FALLBACKS)
	if node == null:
		printerr(context, ": no Sprite2D/3D or AnimatedSprite2D/3D found for → ", target_node.name)
	elif not (node is Sprite2D or node is Sprite3D or node is AnimatedSprite2D or node is AnimatedSprite3D):
		printerr(context, ": not a Sprite2D/3D or AnimatedSprite2D/3D → ", node.name)
		return null
	return node

#endregion - Targets


#?##############################
#& PLAYBACK:
#?##########
#region - Playback
#* Play an animation (CS_Anim_Play):
func play_anim(source: CandyEngine, caller: Object, node: Node, settings: Dictionary, context: String, custom_data: Array = []) -> bool:
	var anim_name: String	= str(settings.get("Animation", "")).strip_edges()
	var loop: int			= CandyPlayback.get_shared().normalize_loop(source, caller, settings.get("Loops", "1"))

	if anim_name == "":
		printerr(context, ": no Animation for → ", node.name)
		return false

	var state: Dictionary = {}

	if node is AnimationPlayer:
		if not node.has_animation(anim_name):
			printerr(context, ": animation not found → '", anim_name, "' in ", node.name)
			return false
		state = _new_state(node, "player", anim_name, loop)
		state["duration"] = node.get_animation(anim_name).length
		state["start"] = func(start_loop: int) -> void:
			_start_player(source, caller, node, start_loop)

	else:
		if not (node.get("parameters/playback") is AnimationNodeStateMachinePlayback):
			printerr(context, ": the AnimationTree has no state machine playback → ", node.name)
			return false
		state = _new_state(node, "tree", anim_name, loop)
		state["duration"] = 1.0
		if node.has_animation(anim_name):
			state["duration"] = node.get_animation(anim_name).length
		state["start"] = func(start_loop: int) -> void:
			_start_tree(source, caller, node, start_loop)

	var duration_seconds := CandyPlayDuration.read(source, caller, settings.get("Duration", "null"), true, 0.0,
		_frame_converter(source, caller, node, settings))
	_set_end_frame(source, caller, node, state, settings, context)
	await _begin(source, caller, node, state, loop, custom_data, duration_seconds)
	return true			#/ Something to wait on


#* Show a sprite or play an animated one (CS_Sprite_Play):
func play_sprite(source: CandyEngine, caller: Object, target_node: Node, node: Node, settings: Dictionary, context: String, custom_data: Array = []) -> bool:
	var file_raw: Variant	= settings.get("File", "")
	var loop: int			= CandyPlayback.get_shared().normalize_loop(source, caller, settings.get("Loops", "1"))
	var animated: bool		= node is AnimatedSprite2D or node is AnimatedSprite3D

	#@ Step 1 - Empty File removes the sprite:
	if not (file_raw is Resource) and str(file_raw).strip_edges() == "":
		stop_node(source, caller, node, CandyPlayback.STOP_FRAME_CLEAR)
		return false

	#@ Step 2 - Resolve the file:
	var folder: String = candy_de.sprite_folder.path_join(str(target_node.name))
	var default_ext := CandyPlayback.get_shared().resolve_extension(source, caller, "default_sprite_extension")
	var frames_subfolder := ""
	if animated:
		default_ext = CandyPlayback.get_shared().resolve_extension(source, caller, "default_animated_sprite_extension")
		frames_subfolder = "Sprite_Frames"

	var resolved := CandyMedia.resolve_media(file_raw, folder, default_ext, frames_subfolder)
	if not resolved["found"]:
		printerr(context, ": missing or invalid path → ", resolved["path"])
		return false
	if bool(resolved["is_folder"]):
		printerr(context, ": a folder of frames can't be shown on a sprite node - use a spritesheet or SpriteFrames → ", resolved["path"])
		return false

	var state: Dictionary = {}

	#@ Step 3A - Spritesheet:
	if not animated:
		var tex = resolved["resource"]
		if tex == null:
			tex = CandyMedia.load_texture(str(resolved["path"]))
		if not (tex is Texture2D):
			printerr(context, ": not a texture → ", file_raw)
			return false

		#Ł Layout from the file name, "<name>_<H>x<V>[-<empty>]" ("Fire_4x3-2.png" = 4 x 3 frames, last 2 empty):
		var layout_source := str(resolved["path"])
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

		stop_node(source, caller, node, 0)
		node.texture = tex
		node.hframes = hframes
		node.vframes = vframes
		node.frame = 0
		node.visible = true

		state = _new_state(node, "sheet", "", loop)
		state["fps"] = CandyPlayback.get_shared().resolve_fps(source, caller, "default_sprite_fps", settings.get("FPS", ""),
			0.0, 0.0, str(resolved["path"]))
		state["frame_count"] = max(hframes * vframes - missing, 1)
		state["duration"] = float(state["frame_count"]) / float(state["fps"])
		state["start"] = func(start_loop: int) -> void:
			_start_sheet(source, caller, node, start_loop)

	#@ Step 3B - AnimatedSprite:
	else:
		var frames = resolved["resource"]
		if frames == null:
			frames = CandyMedia.load_sprite_frames(str(resolved["path"]))
		if not (frames is SpriteFrames):
			printerr(context, ": not a SpriteFrames resource → ", file_raw)
			return false

		#Ł "Animation", then one named like the file, then the first that has frames:
		var requested := str(settings.get("Animation", "")).strip_edges()
		var anim := ""
		if requested != "" and frames.has_animation(requested):
			anim = requested
		elif frames.has_animation(str(file_raw).get_file().get_basename()):
			anim = str(file_raw).get_file().get_basename()
		else:
			#% First with frames (a new SpriteFrames has an empty "default"):
			for candidate in frames.get_animation_names():
				if frames.get_frame_count(candidate) > 0:
					anim = candidate
					break
		if anim == "":
			printerr(context, ": no animation in → ", file_raw)
			return false

		#Ł FPS chain only fills a missing speed:
		frames = CandyPlayback.get_shared().sprite_frames_with_speed(source, caller, frames, anim, settings.get("FPS", ""),
			0.0, str(resolved["path"]))
		var speed: float = frames.get_animation_speed(anim)

		stop_node(source, caller, node, 0)
		node.sprite_frames = frames
		node.visible = true

		var duration := 0.0
		for i in frames.get_frame_count(anim):
			duration += frames.get_frame_duration(anim, i) / speed

		state = _new_state(node, "animated", anim, loop)
		state["duration"] = duration
		state["start"] = func(start_loop: int) -> void:
			_start_animated(source, caller, node, start_loop)

	var duration_seconds := CandyPlayDuration.read(source, caller, settings.get("Duration", "null"), true, 0.0,
		_frame_converter(source, caller, node, settings))
	_set_end_frame(source, caller, node, state, settings, context)
	await _begin(source, caller, node, state, loop, custom_data, duration_seconds)
	return true			#/ Something to wait on


#* Wait until a node reaches a loop count and/or time:
func wait_node(source: CandyEngine, caller: Object, node: Node, settings: Dictionary, context: String) -> String:
	var state := _state(node)
	if state.is_empty() or not bool(state["active"]):
		return "Continue"

	var wait: int = int(settings.get("Wait_Loops", "0"))
	var target_time := CandyPlayback.get_shared().resolve_time_target(source, caller, settings.get("Wait_Time", ""), true, 0.0,
		_frame_converter(source, caller, node, settings))
	if wait <= 0 and target_time <= 0.0:
		return "Continue"

	var target_total: float = max(wait, 0) * float(state["duration"]) + target_time
	var warned_open_pause := false

	while true:
		if source.killswitch == true:
			return "END"

		#% Gone, replaced by a newer playback, stopped, or finished:
		if not is_instance_valid(node) or not is_same(_state(node), state) or not bool(state["active"]):
			break

		#% Paused:
		if bool(state["paused"]):
			var handle = null
			if node.has_meta("cs_pause"):
				handle = node.get_meta("cs_pause")
			if handle != null and int(handle.pause_count) > 0:
				push_warning("%s: wait released - '%s' is paused for %d more line(s), which can't elapse while the dialogue waits." % [context, node.name, int(handle.pause_count)])
				break
			if not warned_open_pause:
				warned_open_pause = true
				push_warning("%s: waiting on '%s', which is paused with no line count - dialogue stays blocked until it is resumed from outside the dialogue." % [context, node.name])
			await source.get_tree().process_frame
			continue

		var elapsed: float = int(state["loops_played"]) * float(state["duration"]) + _position(source, caller, node, state)
		if elapsed >= target_total:
			break

		await source.get_tree().process_frame

	return "Continue"


#* Pause a node's playback (CS_Anim_Pause / CS_Sprite_Pause):
func pause_node(source: CandyEngine, caller: Object, node: Node, settings: Dictionary, context: String) -> void:
	var state := _state(node)
	if state.is_empty() or not bool(state["active"]):
		printerr(context, ": nothing is playing on → ", node.name)
		return

	var pause_loop := CandyPauseLoop.start(source, caller, node, settings, _pause_loop_media(source, caller, node, state, settings),
		context, state.get("pause_loop", null) as CandyPauseLoop)
	state["pause_loop"] = pause_loop

	if pause_loop == null:
		match str(state["kind"]):
			"player", "animated":
				node.pause()
			"tree":
				node.active = false
			"sheet":
				var timer := node.get_node_or_null(CS_SPRITE_TIMER)
				if timer is Timer:
					timer.paused = true
	state["paused"] = true

	var handle := CSPauseHandle.new()
	handle.node = node
	node.set_meta("cs_pause", handle)
	CandyPlayback.get_shared().set_pause(source, caller, handle, int(settings.get("Lines", -1)), int(settings.get("All", 0)))


#* Resume a node's playback (CS_Anim_Resume / CS_Sprite_Resume):
func resume_node(source: CandyEngine, caller: Object, node: Node, context: String, custom_data: Array = [],
		settings: Dictionary = {}) -> void:
	var state := _state(node)
	if state.is_empty():
		printerr(context, ": nothing was played on → ", node.name)
		return

	#% Held playback - start it:
	if int(state["loop_target"]) == 0 and (state["start"] as Callable).is_valid():
		await _begin(source, caller, node, state, 1, custom_data)
		return

	#Ł Else lift the pause and its "Lines" count:
	unpause_node(source, caller, node, settings)


#* Lift a pause (_Resume, or "Lines" ran out):
func unpause_node(source: CandyEngine, caller: Object, node: Node, settings: Dictionary = {}) -> void:
	_drop_pause(node)

	var state := _state(node)
	if state.is_empty() or not bool(state["paused"]):
		return

	var pause_loop: Variant = state.get("pause_loop", null)
	if pause_loop is CandyPauseLoop:
		pause_loop.resume(source, settings)		#/ settings: the _Resume entry, {} = the pause's own
	state["paused"] = false

	match str(state["kind"]):
		"player", "animated":
			node.play()
		"tree":
			node.active = true
		"sheet":
			var timer := node.get_node_or_null(CS_SPRITE_TIMER)
			if timer is Timer:
				timer.paused = false


#* Stop a node's playback (CS_Anim_Stop / CS_Sprite_Stop):
func stop_entry(source: CandyEngine, caller: Object, node: Node, settings: Dictionary, context: String) -> void:
	var stop_frame := CandyPlayback.get_shared().parse_stop_frame(source, caller, settings.get("Stop_Frame", ""), 0, context)
	var state := _state(node)

	#@ Step 1 - "Loops" / "Duration" schedule the stop:
	if not state.is_empty() and bool(state["active"]):
		var loop := CandyPlayDuration.read_stop_loop(settings.get("Loops", ""), context)
		var duration_seconds := CandyPlayDuration.read(source, caller, settings.get("Duration", ""), true, 0.0,
			_frame_converter(source, caller, node, settings))
		if CandyPlayDuration.schedules(loop, duration_seconds):
			state["end_frame"] = stop_frame
			state["end_converter"] = _frame_converter(source, caller, node, settings)
			_drop_play_duration(state)
			state["play_duration"] = CandyPlayDuration.schedule_stop(node, loop, duration_seconds,
				_play_duration_media(source, caller, node, state))
			return

	#@ Step 2 - Stop now (also when not playing):
	stop_node(source, caller, node, stop_frame)


#* Stop a node's playback at once:
#? stop_frame: 0 = current frame, -1 = last, N > 0 = frame N (from 1), STOP_FRAME_CLEAR = clear.
func stop_node(source: CandyEngine, caller: Object, node: Node, stop_frame: int) -> void:
	var state := _state(node)

	#@ Step 1 - End everything that drives the node:
	invalidate(source, caller, node)
	clear_sprite_timer(source, caller, node)
	_drop_pause(node)
	if not state.is_empty():
		_cancel_pause_loop(state)
		state["active"] = false
		state["paused"] = false
		node.remove_meta("cs_state")

	#@ Step 2 - Settle on the requested frame, or clear:
	#Ł Count an AnimationPlayer's frames on its assigned animation:
	var fallback_fps := 0.0
	if node is AnimationPlayer:
		fallback_fps = CandyPlayback.get_shared().resolve_fps(source, caller, "default_effect_fps", "", 0.0, 0.0,
			CandyPlayback.get_shared().animation_library_file(source, caller, node, str(node.assigned_animation)))
	_settle_node(source, caller, node, state, stop_frame,
		func(frame: float) -> float:
			return CandyPlayback.get_shared().animation_frame_to_time(source, caller, node.get_animation(node.assigned_animation), frame, fallback_fps))


#* Put a stopped node on a frame, or clear it:
func _settle_node(source: CandyEngine, caller: Object, node: Node, state: Dictionary, stop_frame: int,
		frame_to_time: Callable) -> void:
	var clearing: bool = stop_frame == CandyPlayback.STOP_FRAME_CLEAR

	if node is AnimationPlayer:
		if clearing:
			CandyPlayback.get_shared().clear_animation(source, caller, node)		#/ "RESET" pose if any, then stopped
		else:
			CandyPlayback.get_shared().settle_animation(source, caller, node, stop_frame, frame_to_time)		#/ frame_to_time: frame (from 0) → seconds

	elif node is AnimationTree:
		var playback = node.get("parameters/playback")
		if stop_frame == -1 and playback is AnimationNodeStateMachinePlayback:
			#! Keep the tree active: deactivating now cancels travel().
			playback.travel(CS_ANIM_TREE_IDLE)
		else:
			node.active = false

	elif node is AnimatedSprite2D or node is AnimatedSprite3D:
		#! pause(), since stop() rewinds to frame 0:
		node.pause()
		var sf: SpriteFrames = node.sprite_frames
		if clearing:
			node.sprite_frames = null
			node.visible = false
		elif stop_frame != 0 and sf != null and sf.has_animation(node.animation):
			var total: int = sf.get_frame_count(node.animation)
			if stop_frame == -1:
				node.frame = total - 1
			else:
				node.frame = clampi(stop_frame - 1, 0, total - 1)

	elif node is Sprite2D or node is Sprite3D:
		if clearing:
			node.texture = null
			node.visible = false
		elif stop_frame != 0 and node.texture != null:
			var total := CandyMedia.sheet_frame_count(node)
			if not state.is_empty() and int(state["frame_count"]) > 0:
				total = int(state["frame_count"])
			if stop_frame == -1:
				node.frame = total - 1
			else:
				node.frame = clampi(stop_frame - 1, 0, total - 1)


#* Move a node's playback within the current loop (_Skip commands):
func skip_node(source: CandyEngine, caller: Object, node: Node, settings: Dictionary, context: String) -> void:
	var state := _state(node)
	if state.is_empty():
		printerr(context, ": nothing was played on → ", node.name)
		return
	if str(state["kind"]) == "tree":
		printerr(context, ": an AnimationTree state can't be skipped → ", node.name)
		return

	#% Pause loop playing - move the pause point:
	if _pause_loop_owns_position(state):
		state["pause_loop"].move_pause_point(settings.get("Time", 0.0))
		return

	#@ Step 1 - Resolve the target position:
	var target: float = CandyPlayback.get_shared().resolve_relative_time(source, caller, _position(source, caller, node, state),
		settings.get("Time", 0.0), true, 0.0, _frame_converter(source, caller, node, settings))
	target = clampf(target, 0.0, float(state["duration"]))

	#@ Step 2 - Move there (a paused or held playback doesn't start):
	match str(state["kind"]):
		"player":
			node.seek(target, true)
		"animated":
			_set_animated_time(node, state, target)
		"sheet":
			node.frame = clampi(int(target * float(state["fps"])), 0, int(state["frame_count"]) - 1)
			var timer := node.get_node_or_null(CS_SPRITE_TIMER)
			if timer is Timer and not timer.is_stopped():
				timer.start()		#/ A paused timer stays paused

#endregion - Playback


#?##############################
#& MARKERS:
#?#########
#region - Markers
#* Move a node onto a marker (CS_Position):
func move_to_marker(source: CandyEngine, caller: Object, node: Node, marker: Node, settings: Dictionary,
		label: String, marker_label: String, context: String) -> Array:
	var rotate: bool = int(settings.get("Rotate", "1")) == 1

	#@ Step 1 - Target position (where the marker is now) and turn step:
	var start_position: Variant = null
	var end_position: Variant = null
	var turn := Callable()
	var turn_degrees := 0.0
	if node is Node3D and marker is Node3D:
		start_position = node.global_position
		end_position = marker.global_position
		if rotate:
			var start_basis: Basis = node.global_basis
			var end_basis: Basis = marker.global_basis
			turn_degrees = rad_to_deg(start_basis.get_rotation_quaternion().angle_to(end_basis.get_rotation_quaternion()))
			turn = func(weight: float) -> void:
				node.global_basis = _slerp_basis(start_basis, end_basis, weight)
	elif node is Node2D and marker is Node2D:
		start_position = node.global_position
		end_position = marker.global_position
		if rotate:
			var start_angle: float = node.global_rotation
			var end_angle: float = marker.global_rotation
			turn_degrees = absf(rad_to_deg(angle_difference(start_angle, end_angle)))
			turn = func(weight: float) -> void:
				node.global_rotation = _lerp_angle_to(start_angle, end_angle, weight)
	elif node is Control and marker is CanvasItem and "global_position" in marker:
		start_position = node.global_position
		end_position = marker.global_position
		if rotate and "rotation" in marker:
			var start_angle: float = node.rotation
			var end_angle: float = marker.rotation
			turn_degrees = absf(rad_to_deg(angle_difference(start_angle, end_angle)))
			turn = func(weight: float) -> void:
				node.rotation = _lerp_angle_to(start_angle, end_angle, weight)
	else:
		printerr(context, ": node and marker must both be 2D (or UI) or both be 3D → ", label, " / ", marker_label)
		return []

	#@ Step 2 - Move, replacing a running move:
	var length := fade_length(settings, start_position.distance_to(end_position), label, context)
	var fades: Array = []
	var move := _start_fade(node, "cs_move_fade", float(length["duration"]), func(weight: float) -> void:
		if weight >= 1.0:
			node.global_position = end_position
		else:
			node.global_position = start_position.lerp(end_position, weight))
	if move != null and bool(length["blocking"]):
		fades.append(move)
	if not turn.is_valid():
		return fades			#/ For wait_fades()

	#@ Step 3 - Turn, replacing a running turn:
	var turn_length := length		#/ At a Speed, a node already on the marker turns at once
	if str(settings.get("Turn_Progression", "Move")).strip_edges().to_lower() != "move":
		turn_length = fade_length(settings, turn_degrees, label, context, "Turn_")
	var turning := _start_fade(node, "cs_turn_fade", float(turn_length["duration"]), turn)
	if turning != null and bool(turn_length["blocking"]):
		fades.append(turning)
	return fades			#/ For wait_fades()


#* Turn a node to face a marker (CS_Look):
func look_at_marker(source: CandyEngine, caller: Object, node: Node, marker: Node, settings: Dictionary,
		label: String, marker_label: String, context: String) -> Array:
	var axis := str(settings.get("Axis", "")).strip_edges().to_lower()
	var ignore_y: bool = int(settings.get("Ignore_Y", "0")) == 1

	var degrees := 0.0
	var turn := Callable()
	if node is Node3D and marker is Node3D:
		var end_basis: Variant = _look_basis_3d(node, marker, axis, ignore_y, label, context)
		if end_basis == null:
			return []
		var start_basis: Basis = node.global_basis
		degrees = rad_to_deg(start_basis.get_rotation_quaternion().angle_to(end_basis.get_rotation_quaternion()))
		turn = func(weight: float) -> void:
			node.global_basis = _slerp_basis(start_basis, end_basis, weight)
	elif node is Node2D and marker is Node2D:
		var end_angle: Variant = _look_angle_2d(node, marker, axis, ignore_y, label, context)
		if end_angle == null:
			return []
		var start_angle: float = node.global_rotation
		degrees = absf(rad_to_deg(angle_difference(start_angle, end_angle)))
		turn = func(weight: float) -> void:
			node.global_rotation = _lerp_angle_to(start_angle, end_angle, weight)
	else:
		printerr(context, ": node and marker must both be 2D or both be 3D → ", label, " / ", marker_label)
		return []

	#Ł Replaces a running turn; a running move keeps going:
	var length := fade_length(settings, degrees, label, context)
	var turning := _start_fade(node, "cs_turn_fade", float(length["duration"]), turn)
	if turning != null and bool(length["blocking"]):
		return [turning]		#/ For wait_fades()
	return []


#* 3D basis turning 'axis' towards the marker, scale kept, or null:
func _look_basis_3d(node: Node3D, marker: Node3D, axis: String, ignore_y: bool, label: String, context: String) -> Variant:
	var look_target: Vector3 = marker.global_position
	if ignore_y:
		look_target.y = node.global_position.y

	var direction: Vector3 = look_target - node.global_position

	#% No direction to face:
	if direction.length_squared() < 0.0001:
		if ignore_y:
			printerr(context, ": the marker is straight above or below the node, so there is no sideways direction to face → ", label)
		else:
			printerr(context, ": node and marker are at the same position → ", label)
		return null

	#@ Step 1 - Up vector not parallel to the direction:
	#! Basis.looking_at() fails when the marker is straight above or below the node.
	#? Fallbacks: the node's back axis (keeps its facing), then FORWARD, then RIGHT.
	var look_dir: Vector3 = direction.normalized()
	var up_vector: Vector3 = Vector3.UP
	if absf(look_dir.dot(up_vector)) > 0.999:
		up_vector = node.global_transform.basis.z.normalized()
		if up_vector.length_squared() < 0.0001 or absf(look_dir.dot(up_vector)) > 0.999:
			up_vector = Vector3.FORWARD
			if absf(look_dir.dot(up_vector)) > 0.999:
				up_vector = Vector3.RIGHT

	var basis := Basis.looking_at(direction, up_vector)

	#@ Step 2 - looking_at() aims -Z, so turn the requested axis instead:
	match axis:
		"", "-z":
			pass
		"+z", "z":
			basis = basis * Basis(Vector3.UP, PI)
		"+x", "x":
			basis = basis * Basis(Vector3.UP, -PI / 2.0)
		"-x":
			basis = basis * Basis(Vector3.UP, PI / 2.0)
		"+y", "y":
			basis = basis * Basis(Vector3.RIGHT, PI / 2.0)
		"-y":
			basis = basis * Basis(Vector3.RIGHT, -PI / 2.0)
		_:
			printerr(context, ": unknown Axis → '", axis, "' for ", label, ". Using -Z.")
	return basis * Basis.from_scale(node.global_basis.get_scale())


#* 2D rotation turning 'axis' towards the marker, or null:
func _look_angle_2d(node: Node2D, marker: Node2D, axis: String, ignore_y: bool, label: String, context: String) -> Variant:
	var direction: Vector2 = marker.global_position - node.global_position
	if ignore_y:
		direction.y = 0.0

	if direction.length_squared() < 0.0001:
		if ignore_y:
			printerr(context, ": the marker is straight above or below the node, so there is no sideways direction to face → ", label)
		else:
			printerr(context, ": node and marker are at the same position → ", label)
		return null

	#Ł atan2 measures from +X, so offset for the requested axis:
	var angle: float = atan2(direction.y, direction.x)
	match axis:
		"", "+x", "x":
			pass
		"-x":
			angle += PI
		"+y", "y":
			angle -= PI / 2.0		#/ Godot's 2D +Y points down
		"-y":
			angle += PI / 2.0
		_:
			printerr(context, ": Axis '", axis, "' is not a 2D axis (x or y) for ", label, ". Using +X.")
	return angle

#endregion - Markers


#?##############################
#& LIGHTS:
#?########
#region - Lights
#* Change a light's color and/or energy (CS_Light):
func change_light(source: CandyEngine, caller: Object, light: Node, settings: Dictionary, context: String) -> Array:
	var fades: Array = []
	var length := fade_length(settings, -1.0, str(light.name), context)
	var duration := float(length["duration"])
	var blocking := bool(length["blocking"])

	#? Light2D and Light3D name these properties differently.
	var color_property := "color"
	var energy_property := "energy"
	if light is Light3D:
		color_property = "light_color"
		energy_property = "light_energy"

	#@ Step 1 - Color:
	var color_value: Variant = settings.get("Color", null)
	if color_value != null and str(color_value) != "":
		var fade := _fade_property(light, "cs_light_color_fade", color_property, light_color(color_value), duration)
		if fade != null and blocking:
			fades.append(fade)

	#@ Step 2 - Energy:
	var energy_value: Variant = settings.get("Energy", null)
	if energy_value == null or str(energy_value) == "":
		return fades			#/ For wait_fades()

	var value := 0.0
	if typeof(energy_value) in [TYPE_INT, TYPE_FLOAT]:
		value = float(energy_value)
	elif typeof(energy_value) == TYPE_STRING and energy_value.is_valid_float():
		value = float(energy_value)
	else:
		printerr(context, ": invalid Energy → ", energy_value, " for ", light.name)
		return fades

	#Ł A relative change counts from where a running fade is heading:
	var new_energy: float = light.get(energy_property)
	if _running_fade(light, "cs_light_energy_fade") != null:
		new_energy = float(light.get_meta("cs_light_energy_fade_target"))
	match str(settings.get("Operator", "=")).strip_edges():
		"=":
			new_energy = value
		"+":
			new_energy += value
		"-":
			new_energy -= value
		"*":
			new_energy *= value
		"/":
			if value == 0.0:
				printerr(context, ": division by zero for ", light.name)
				return fades
			new_energy /= value
		_:
			printerr(context, ": unknown Operator → ", settings.get("Operator"), " for ", light.name)
			return fades

	var energy_fade := _fade_property(light, "cs_light_energy_fade", energy_property, new_energy, duration)
	if energy_fade != null and blocking:
		fades.append(energy_fade)
	return fades			#/ For wait_fades()


#* Read a CS_Light "Color" into a Color:
func light_color(value: Variant) -> Color:
	var color := Color(1, 1, 1)
	if value is Color:
		color = value
	elif typeof(value) == TYPE_STRING:
		var text: String = value.strip_edges()
		if text.begins_with("#"):
			color = Color(text)
		elif text.begins_with("(") and text.ends_with(")"):
			var nums := text.substr(1, text.length() - 2).split(",")
			match nums.size():
				3:
					color = Color(float(nums[0]), float(nums[1]), float(nums[2]))
				4:
					color = Color(float(nums[0]), float(nums[1]), float(nums[2]), float(nums[3]))
		else:
			color = Color(text)		#/ Named color
	elif typeof(value) == TYPE_ARRAY and value.size() >= 3:
		color = Color(float(value[0]), float(value[1]), float(value[2]))
	elif typeof(value) == TYPE_DICTIONARY:
		color = Color(float(value.get("r", 1)), float(value.get("g", 1)), float(value.get("b", 1)), float(value.get("a", 1)))
	return color

#endregion - Lights


#?##############################
#& FADES:
#?#######
#region - Fades
#? A fade is a Tween kept in its node's meta, replaced by a new change.
#? Ignores dialogue suspension and dialogue end.

#^ Fade metas (move, turn, light color, light energy):
const FADE_METAS: Array = ["cs_move_fade", "cs_turn_fade", "cs_light_color_fade", "cs_light_energy_fade"]

#* Read a change's length, and whether the dialogue waits:
#? 'amount': how far the change goes, in Speed's unit; negative = no Speed.
func fade_length(settings: Dictionary, amount: float, label: String, context: String, prefix: String = "") -> Dictionary:
	var key := prefix + "Time"
	if amount >= 0.0:
		var progression_key := prefix + "Progression"
		match str(settings.get(progression_key, "Time")).strip_edges().to_lower():
			"time":
				pass
			"speed":
				key = prefix + "Speed"
			_:
				printerr(context, ": unknown ", progression_key, " → ", settings.get(progression_key), " for ", label, " (", prefix, "Time is used)")

	var text := str(settings.get(key, "0")).strip_edges()
	var blocking := text.begins_with("!")		#/ "!": the dialogue waits
	if blocking:
		text = text.substr(1).strip_edges()
	var value := 0.0
	if text != "":
		if text.is_valid_float():
			value = float(text)
		else:
			printerr(context, ": invalid ", key, " → ", settings.get(key), " for ", label, " (changed at once)")

	var duration := value
	if key == prefix + "Speed":
		duration = 0.0
		if value > 0.0:
			duration = amount / value
	return {"duration": maxf(duration, 0.0), "blocking": blocking}


#* Wait for every fade:
func wait_fades(source: CandyEngine, caller: Object, fades: Array) -> String:
	for fade in fades:
		#% Poll (kill() doesn't emit finished):
		while fade is Tween and fade.is_valid() and fade.is_running():
			if source.killswitch == true:
				return "END"
			await source.get_tree().process_frame
	return "Continue"


#* Stop a node's running fades, where they are:
#? For game code taking a node back (e.g. a skipped cutscene).
func stop_fades(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	for meta in FADE_METAS:
		_stop_fade(node, meta)


#* Start a fade in 'meta', replacing the running one:
func _start_fade(node: Node, meta: String, duration: float, step: Callable) -> Tween:
	_stop_fade(node, meta)
	if duration <= 0.0:
		step.call(1.0)
		return null			#/ Instant

	var fade: Tween = node.create_tween()
	fade.tween_method(step, 0.0, 1.0, duration)
	node.set_meta(meta, fade)
	return fade


#* Fade a property to 'target':
func _fade_property(node: Node, meta: String, property: String, target: Variant, duration: float) -> Tween:
	var start: Variant = node.get(property)
	var fade := _start_fade(node, meta, duration, func(weight: float) -> void:
		if weight >= 1.0:
			node.set(property, target)
		else:
			node.set(property, lerp(start, target, weight)))
	if fade != null:
		node.set_meta(meta + "_target", target)		#/ For relative changes
	return fade


#* Stop the fade in a node's 'meta', where it is:
func _stop_fade(node: Node, meta: String) -> void:
	var running := _running_fade(node, meta)
	if running != null:
		running.kill()
	if node.has_meta(meta):
		node.remove_meta(meta)
	if node.has_meta(meta + "_target"):
		node.remove_meta(meta + "_target")


#* The fade still running in a node's 'meta', or null:
func _running_fade(node: Node, meta: String) -> Tween:
	if not node.has_meta(meta):
		return null
	var fade = node.get_meta(meta)
	if fade is Tween and fade.is_valid() and fade.is_running():
		return fade
	return null


#* Slerp bases; exactly 'to' at 1:
func _slerp_basis(from: Basis, to: Basis, weight: float) -> Basis:
	if weight >= 1.0:
		return to
	return from.slerp(to, weight)


#* Lerp angles the short way; exactly 'to' at 1:
func _lerp_angle_to(from: float, to: float, weight: float) -> float:
	if weight >= 1.0:
		return to
	return lerp_angle(from, to, weight)

#endregion - Fades


#?##############################
#& PLAYBACK INTERNALS:
#?####################
#region - Playback Internals
#* A node's playback state, or {}:
func _state(node: Node) -> Dictionary:
	if node == null or not is_instance_valid(node):
		return {}
	return node.get_meta("cs_state", {})


#* Drop a node's "Lines" pause handle:
func _drop_pause(node: Node) -> void:
	#! get_meta() errors on a null default:
	if not node.has_meta("cs_pause"):
		return
	var handle = node.get_meta("cs_pause")
	if handle != null:
		handle.pause_count = 0
	node.remove_meta("cs_pause")


#* Create a node's playback state, replacing any earlier one:
func _new_state(node: Node, kind: String, anim_name: String, loop: int) -> Dictionary:
	var state: Dictionary = {
		"kind": kind,			#/ "player", "tree", "sheet" (spritesheet) or "animated" (AnimatedSprite)
		"anim": anim_name,
		"loop_target": loop,
		"loops_played": 0,
		"duration": 0.0,
		"active": false,		#/ A playback runs, paused or not
		"paused": false,
		"fps": 0.0,
		"frame_count": 0,
		"start": Callable(),	#/ Callable(loop) that (re)starts it
		"gen": -1,
		"end_frame": 0,
		"end_converter": Callable(),
	}

	_drop_pause(node)
	_cancel_pause_loop(_state(node))

	node.set_meta("cs_state", state)
	return state


#* Read a _Play line's "Stop_Frame":
func _set_end_frame(source: CandyEngine, caller: Object, node: Node, state: Dictionary, settings: Dictionary, context: String) -> void:
	state["end_frame"] = CandyPlayback.get_shared().parse_stop_frame(source, caller, settings.get("Stop_Frame", ""), 0, context)
	state["end_converter"] = _frame_converter(source, caller, node, settings)


#* Start a playback, between the playback hooks:
func _begin(source: CandyEngine, caller: Object, node: Node, state: Dictionary, loop: int, custom_data: Array,
		duration_seconds: float = 0.0) -> void:
	var start_loop := CandyPlayDuration.play_loop(loop, duration_seconds)

	if start_loop != 0:
		await candy_de.run_node_hook(node, "x_playback_starting", {"caller": source, "node": node}, custom_data)

	(state["start"] as Callable).call(start_loop)
	state["play_duration"] = CandyPlayDuration.start(node, loop, duration_seconds, _play_duration_media(source, caller, node, state))

	if start_loop != 0:
		await candy_de.run_node_hook(node, "x_playback_started", {"caller": source, "node": node}, custom_data)


#* Reset a state for a new playback:
func _reset_state(state: Dictionary, loop: int, gen: int) -> void:
	_cancel_pause_loop(state)
	_drop_play_duration(state)
	state["gen"] = gen
	state["loop_target"] = loop
	state["loops_played"] = 0
	state["active"] = loop != 0
	state["paused"] = false


#* (Re)start an AnimationPlayer playback:
func _start_player(source: CandyEngine, caller: Object, node: Node, loop: int) -> void:
	var state := _state(node)
	var anim_name := str(state["anim"])
	var gen: int = invalidate(source, caller, node)
	_reset_state(state, loop, gen)

	#% Loops 0 holds on the first frame:
	#? play() first, or seek() shows the previously assigned animation.
	if loop == 0:
		node.play(anim_name)
		node.seek(0.0, true)
		node.pause()
		return

	#Ł Looping Animations never emit animation_finished - track playback loops by position:
	var anim_res: Animation = node.get_animation(anim_name)
	var cycle_anim: Animation = null
	if anim_res.loop_mode != Animation.LOOP_NONE:
		cycle_anim = anim_res

	var play := func() -> void:
		#! stop() re-applies the last animation played, which may no longer exist.
		if node.has_animation(node.assigned_animation):
			node.stop()			#/ Restart from the top
		node.play(anim_name)
	var next_loop := func():
		return node.animation_finished

	playback_loop.bind(source, caller, node, gen, state, play, next_loop, anim_name, cycle_anim).call()


#* (Re)start an AnimatedSprite2D/3D playback:
func _start_animated(source: CandyEngine, caller: Object, node: Node, loop: int) -> void:
	var state := _state(node)
	var anim_name := str(state["anim"])
	var gen: int = invalidate(source, caller, node)
	_reset_state(state, loop, gen)

	#% Loops 0 holds on the first frame:
	#! Set the animation: stop() keeps the previous one.
	if loop == 0:
		node.stop()
		node.animation = anim_name
		node.frame = 0
		return

	#Ł A looping SpriteFrames animation never emits animation_finished:
	var anim_loops: bool = node.sprite_frames.get_animation_loop(anim_name)
	var play := func() -> void:
		node.animation = anim_name
		node.frame = 0
		node.play(anim_name)
	var next_loop := func():
		if anim_loops:
			return node.animation_looped
		return node.animation_finished

	playback_loop.bind(source, caller, node, gen, state, play, next_loop, anim_name, null).call()


#* (Re)start a spritesheet playback, on a Timer:
func _start_sheet(source: CandyEngine, caller: Object, node: Node, loop: int) -> void:
	var state := _state(node)
	var gen: int = invalidate(source, caller, node)
	_reset_state(state, loop, gen)
	clear_sprite_timer(source, caller, node)
	node.frame = 0

	#% Held, or nothing to step through:
	if loop == 0 or int(state["frame_count"]) <= 1:
		state["active"] = false
		return

	var timer := Timer.new()
	timer.name = CS_SPRITE_TIMER
	timer.wait_time = 1.0 / float(state["fps"])
	node.add_child(timer)
	timer.start()

	var animate := func() -> void:
		while true:
			await timer.timeout
			if not is_current(source, caller, node, gen):
				return
			var next_frame: int = node.frame + 1
			if next_frame >= int(state["frame_count"]):
				#% Pause loop took the end over - not a playback loop:
				if _pause_loop_takes_end(state):
					continue
				state["loops_played"] = int(state["loops_played"]) + 1
				next_frame = 0
				#% Done - last frame, or the end frame:
				if int(state["loop_target"]) > 0 and int(state["loops_played"]) >= int(state["loop_target"]):
					state["active"] = false
					clear_sprite_timer(source, caller, node)
					_end_on_frame(source, caller, node, state)
					return
			node.frame = next_frame

	animate.call()


#* (Re)start an AnimationTree state machine playback:
func _start_tree(source: CandyEngine, caller: Object, node: Node, loop: int) -> void:
	var state := _state(node)
	var anim_name := str(state["anim"])
	var playback: AnimationNodeStateMachinePlayback = node.get("parameters/playback")
	var gen: int = invalidate(source, caller, node)
	_reset_state(state, loop, gen)

	#% Loops 0 holds on the first frame:
	if loop == 0:
		node.active = true
		playback.travel(anim_name)
		node.advance(0.0)
		node.active = false
		return

	node.active = true
	playback.travel(anim_name)

	#Ł No finish signal - poll loops per frame:
	#! travel() passes through other states: a loop is entering the state, then leaving it.
	var tree_loop := func() -> void:
		var entered := false
		while true:
			await source.get_tree().process_frame
			if not is_current(source, caller, node, gen):
				return
			if bool(state["paused"]):
				continue
			if not node.active:
				state["active"] = false
				return

			var current_state: String = str(playback.get_current_node())
			if current_state == anim_name:
				entered = true
				continue
			#% Still travelling:
			if not entered:
				continue

			#% Left the state - one loop:
			entered = false
			state["loops_played"] = int(state["loops_played"]) + 1
			if int(state["loop_target"]) < 0 or int(state["loops_played"]) < int(state["loop_target"]):
				playback.travel(anim_name)
			else:
				state["active"] = false
				_end_on_frame(source, caller, node, state)
				return

	tree_loop.call()


#* Position within the current loop, in seconds:
func _position(source: CandyEngine, caller: Object, node: Node, state: Dictionary) -> float:
	match str(state["kind"]):
		"player":
			if str(node.assigned_animation) == str(state["anim"]):
				return float(node.current_animation_position)
		"tree":
			var playback = node.get("parameters/playback")
			if playback is AnimationNodeStateMachinePlayback and str(playback.get_current_node()) == str(state["anim"]):
				return float(playback.get_current_play_position())
		"animated":
			var sf: SpriteFrames = node.sprite_frames
			var anim_name := str(state["anim"])
			if sf == null or not sf.has_animation(anim_name):
				return 0.0
			var elapsed: float = CandyPlayback.get_shared().sprite_frames_frame_time(source, caller, sf, anim_name, node.frame)
			var speed: float = sf.get_animation_speed(anim_name)
			if speed > 0.0 and node.frame < sf.get_frame_count(anim_name):
				elapsed += float(node.frame_progress) * sf.get_frame_duration(anim_name, node.frame) / speed
			return elapsed
		"sheet":
			var elapsed: float = float(node.frame) / float(state["fps"])
			var timer := node.get_node_or_null(CS_SPRITE_TIMER)
			if timer is Timer and not timer.is_stopped():
				elapsed += clampf(timer.wait_time - timer.time_left, 0.0, timer.wait_time)
			return elapsed
	return 0.0


#* FPS setting for a node's kind:
func _fps_setting(node: Node) -> String:
	if node is AnimatedSprite2D or node is AnimatedSprite3D:
		return "default_animated_sprite_fps"
	if node is Sprite2D or node is Sprite3D:
		return "default_sprite_fps"
	return "default_effect_fps"


#* Converter from "f=" frames to seconds:
func _frame_converter(source: CandyEngine, caller: Object, node: Node, settings: Dictionary) -> Callable:
	var file_path := ""
	if node is AnimationPlayer:
		file_path = CandyPlayback.get_shared().animation_library_file(source, caller, node, str(node.assigned_animation))
	var fallback_fps := CandyPlayback.get_shared().resolve_fps(source, caller, _fps_setting(node), settings.get("FPS", ""),
		0.0, 0.0, file_path)
	return func(frame: float) -> float:
		var state := _state(node)
		if not state.is_empty():
			match str(state["kind"]):
				"player", "tree":
					var anim: Animation = null
					if node.has_animation(str(state["anim"])):
						anim = node.get_animation(str(state["anim"]))
					return CandyPlayback.get_shared().animation_frame_to_time(source, caller, anim, frame, fallback_fps)
				"animated":
					return CandyPlayback.get_shared().sprite_frames_frame_time(source, caller, node.sprite_frames, str(state["anim"]), int(round(frame)))
				"sheet":
					return frame / float(state["fps"])
		return frame / fallback_fps


#* Pause loop media for a node (CandyPauseLoop.start()):
func _pause_loop_media(source: CandyEngine, caller: Object, node: Node, state: Dictionary, settings: Dictionary) -> Dictionary:
	var reason := ""
	if str(state["kind"]) == "tree":
		reason = "an AnimationTree state has no timeline to loop"
	var frame_converter := _frame_converter(source, caller, node, settings)
	return {
		"active": bool(state["active"]),
		"reason": reason,
		"position": func() -> float:
			return _position(source, caller, node, state),
		"length": func() -> float:
			return float(state["duration"]),
		"time": func(text: String, base: float) -> float:
			return CandyPlayback.get_shared().resolve_relative_time(source, caller, base, text, true, 0.0, frame_converter),
		"play_from": func(time: float) -> void:
			_loop_play_from(node, state, time),
		"run": func() -> void:
			_loop_run(node, state),
	}


#* Pause loop - play from a time:
func _loop_play_from(node: Node, state: Dictionary, time: float) -> void:
	if not is_instance_valid(node):
		return
	match str(state["kind"]):
		"player":
			#Ł Seek after play(), which restarts a finished animation:
			if not node.is_playing():
				node.play(str(state["anim"]))
			node.seek(time, true)
		"animated":
			if not node.is_playing():
				node.play(str(state["anim"]))
			_set_animated_time(node, state, time)
		"sheet":
			node.frame = clampi(int(time * float(state["fps"])), 0, int(state["frame_count"]) - 1)
			var timer := node.get_node_or_null(CS_SPRITE_TIMER)
			if timer is Timer:
				timer.paused = false
				timer.start()


#* Pause loop - play on:
func _loop_run(node: Node, state: Dictionary) -> void:
	if not is_instance_valid(node):
		return
	match str(state["kind"]):
		"player", "animated":
			if not node.is_playing():
				node.play()
		"sheet":
			var timer := node.get_node_or_null(CS_SPRITE_TIMER)
			if timer is Timer:
				timer.paused = false


#* Whether the pause loop owns the position:
func _pause_loop_owns_position(state: Dictionary) -> bool:
	var pause_loop: Variant = state.get("pause_loop", null)
	return pause_loop is CandyPauseLoop and pause_loop.owns_position()


#* Whether the pause loop takes over the end just reached:
func _pause_loop_takes_end(state: Dictionary) -> bool:
	var pause_loop: Variant = state.get("pause_loop", null)
	return pause_loop is CandyPauseLoop and pause_loop.media_ended()


#* Cancel the pause loop:
func _cancel_pause_loop(state: Dictionary) -> void:
	var pause_loop: Variant = state.get("pause_loop", null)
	if pause_loop is CandyPauseLoop:
		pause_loop.cancel()
	state.erase("pause_loop")


#* Duration media for a node (CandyPlayDuration.start()):
func _play_duration_media(source: CandyEngine, caller: Object, node: Node, state: Dictionary) -> Dictionary:
	var gen: int = int(state["gen"])
	return {
		"position": func() -> float:
			return _position(source, caller, node, state),
		"length": func() -> float:
			#% A tree state may not be named after an animation:
			if str(state["kind"]) == "tree":
				var playback = node.get("parameters/playback")
				if playback is AnimationNodeStateMachinePlayback and str(playback.get_current_node()) == str(state["anim"]):
					return float(playback.get_current_length())
			return float(state["duration"]),
		"loops": func() -> int:
			return int(state["loops_played"]),
		"set_loops": func(count: int) -> void:
			state["loop_target"] = count,
		"end": func(time: float) -> void:
			_end_at(source, caller, node, state, time),
		"active": func() -> bool:
			return bool(state["active"]) and is_current(source, caller, node, gen),		#/ False once a newer playback starts
		"held": func() -> bool:
			return _pause_loop_owns_position(state),
	}


#* End a playback at 'time' in its current loop:
func _end_at(source: CandyEngine, caller: Object, node: Node, state: Dictionary, time: float) -> void:
	_cancel_pause_loop(state)
	state["active"] = false
	if not is_instance_valid(node):
		return

	invalidate(source, caller, node)
	#% End frame:
	if int(state["end_frame"]) != 0:
		clear_sprite_timer(source, caller, node)
		_end_on_frame(source, caller, node, state)
		return

	#Ł Else hold the frame at 'time' (an AnimationTree stops where it is):
	match str(state["kind"]):
		"player":
			CandyPlayback.get_shared().settle_animation_at(source, caller, node, time)
		"animated":
			node.pause()
			_set_animated_time(node, state, time)
		"sheet":
			clear_sprite_timer(source, caller, node)
			node.frame = clampi(int(time * float(state["fps"])), 0, int(state["frame_count"]) - 1)
		"tree":
			node.active = false


#* Put an ended playback on its end frame:
func _end_on_frame(source: CandyEngine, caller: Object, node: Node, state: Dictionary) -> void:
	var stop_frame := int(state["end_frame"])
	if stop_frame == 0 or not is_instance_valid(node):
		return			#/ 0 = leave as is
	_settle_node(source, caller, node, state, stop_frame, state["end_converter"])


#* Cancel a playback's Duration:
func _drop_play_duration(state: Dictionary) -> void:
	var play_duration: Variant = state.get("play_duration", null)
	if play_duration is CandyPlayDuration:
		play_duration.cancel()
	state.erase("play_duration")


#* Place an AnimatedSprite at a time within its animation:
func _set_animated_time(node: Node, state: Dictionary, target: float) -> void:
	var sf: SpriteFrames = node.sprite_frames
	var anim_name := str(state["anim"])
	if sf == null or not sf.has_animation(anim_name):
		return
	var speed: float = sf.get_animation_speed(anim_name)
	var count: int = sf.get_frame_count(anim_name)
	if speed <= 0.0 or count <= 0:
		return

	var start := 0.0
	for i in count:
		var frame_length: float = sf.get_frame_duration(anim_name, i) / speed
		if target < start + frame_length or i == count - 1:
			var progress := 0.0
			if frame_length > 0.0:
				progress = clampf((target - start) / frame_length, 0.0, 1.0)
			node.set_frame_and_progress(i, progress)
			return
		start += frame_length


#* Bump a node's generation and wake parked loops:
func invalidate(source: CandyEngine, caller: Object, node: Node) -> int:
	if node == null or not is_instance_valid(node):
		return 0

	var gen: int = int(node.get_meta("cs_generation", 0)) + 1
	node.set_meta("cs_generation", gen)

	#Ł stop() never emits these - wake parked coroutines:
	#! Only when one is parked, or game code gets a false finish.
	if node.has_meta("cs_playback_gen"):
		node.remove_meta("cs_playback_gen")
		if node is AnimationPlayer:
			node.animation_finished.emit(node.assigned_animation)
		elif node is AnimatedSprite2D or node is AnimatedSprite3D:
			node.animation_finished.emit()

	return gen


#* Whether a coroutine's generation is still current:
func is_current(source: CandyEngine, caller: Object, node: Node, gen: int) -> bool:
	return is_instance_valid(node) and int(node.get_meta("cs_generation", 0)) == gen


#* Remove a spritesheet's frame timer:
func clear_sprite_timer(source: CandyEngine, caller: Object, node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return

	var timer := node.get_node_or_null(CS_SPRITE_TIMER)
	if timer:
		timer.stop()
		node.remove_child(timer)
		timer.queue_free()


#* Loop an AnimationPlayer / AnimatedSprite playback until its Loops target:
func playback_loop(source: CandyEngine, caller: Object, node: Node, gen: int, state: Dictionary, play: Callable,
		next_loop: Callable, expected_anim: String = "", cycle_anim: Animation = null) -> void:

	#Ł Mark as driven, for invalidate():
	node.set_meta("cs_playback_gen", gen)

	#? Off after a pause loop took the end over (it moved playback already).
	var replay := true

	while true:
		if replay:
			play.call()
		replay = true

		#% Self-looping Animation - playback loops tracked by position:
		if cycle_anim != null:
			if not await _await_anim_cycle(source, caller, node, gen, state, cycle_anim, expected_anim):
				_release(source, caller, node, gen, state)
				return
		else:
			var finished = await next_loop.call()

			#% A finish for another animation (AnimationPlayer's carries its name): other code took over, let go:
			if typeof(finished) == TYPE_STRING and expected_anim != "" and str(finished) != expected_anim:
				_release(source, caller, node, gen, state)
				return

		if not is_current(source, caller, node, gen):
			_release(source, caller, node, gen, state)
			return

		#% Pause loop took the end over - not a playback loop:
		if _pause_loop_takes_end(state):
			replay = false
			continue

		state["loops_played"] = int(state["loops_played"]) + 1

		#% Loops -1 runs forever; else hold the final pose or the end frame:
		#! Not stop(): it rewinds to frame 0.
		if int(state["loop_target"]) > 0 and int(state["loops_played"]) >= int(state["loop_target"]):		#/ Target read each loop: a Duration sets it later
			if node.has_method("pause"):
				node.pause()
			elif node.has_method("stop"):
				node.stop()
			_release(source, caller, node, gen, state)
			_end_on_frame(source, caller, node, state)
			return


#* Wait for one playback loop of a self-looping Animation; false means the loop should let go:
func _await_anim_cycle(source: CandyEngine, caller: Object, player: Node, gen: int, state: Dictionary, anim: Animation, expected_anim: String) -> bool:
	var prev_pos := -1.0
	var prev_dir := 0

	while true:
		await source.get_tree().process_frame

		if not is_current(source, caller, player, gen):
			return false

		#% Taken over:
		if expected_anim != "" and str(player.assigned_animation) != expected_anim:
			return false

		if not player.is_playing():
			#% Paused - hold, so resuming isn't a wrap:
			if bool(state["paused"]):
				prev_pos = -1.0
				prev_dir = 0
				continue
			return false

		#% Pause loop moving the position isn't a wrap:
		if _pause_loop_owns_position(state):
			prev_pos = -1.0
			prev_dir = 0
			continue

		var pos: float = player.current_animation_position
		if anim.loop_mode == Animation.LOOP_PINGPONG:
			#% A loop ends when playback turns forward again:
			var dir := prev_dir
			if prev_pos >= 0.0:
				if pos > prev_pos:
					dir = 1
				elif pos < prev_pos:
					dir = -1
			if prev_dir == -1 and dir == 1:
				return true
			prev_dir = dir
		else:
			if prev_pos >= 0.0 and pos < prev_pos:
				return true

		prev_pos = pos

	#% Unreachable:
	return false


#* A playback loop is over:
func _release(source: CandyEngine, caller: Object, node: Node, gen: int, state: Dictionary) -> void:
	#! Only the current playback's loop may end it: a replaced loop exits late.
	if int(state["gen"]) == gen:
		state["active"] = false
	if is_instance_valid(node) and int(node.get_meta("cs_playback_gen", -1)) == gen:
		node.remove_meta("cs_playback_gen")

#endregion - Playback Internals

@warning_ignore_restore("unused_parameter")
