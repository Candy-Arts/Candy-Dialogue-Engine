#!###########################################################################################
#!																							#
#!        THIS SCRIPT CONTAINS CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS         #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                 Any unauthorized use constitutes copyright infringement.                 #
#!																							#
#!   This disclaimer must be featured at the top of any script featuring Candy Arts code,   #
#!                            and may not be removed or modified.                           #
#!																							#
#!###########################################################################################


extends Node


@onready var bg_container = get_node("BG_Control")

@export var default_image_extension = ".png"				#/ TextureRect, NinePatchRect, TextureButton
@export var default_sprite_extension = ".png"				#/ Sprite2D, Sprite3D
@export var default_animated_sprite_extension = ".tres"		#/ AnimatedSprite2D, AnimatedSprite3D
@export var default_video_extension = ".ogv"				#/ VideoStreamPlayer
@export var default_effect_extension = ".tres"				#/ AnimationPlayer

#? The FPS value to use for Sprite2D, Sprite3D, AnimatedSprite2D or AnimatedSprite3D animations.
@export var image_fps = 1.0
@export var sprite_fps = 10.0

#? Used for scaling Sprite2D or Sprite3D nodes to the desired size:
@export var bg_sizes = {
	"1": [1080, 1024],	#/ [height, width]
	"2": [1080, 1024],
	"3": [1080, 1024],
}

@export var default_z = 100

var caller: Node

#^ BG layer data:
#? Used by the functions to store relevant data about each layer
var bg_layer_data = {}



func _ready():
	self.z_index = default_z


#* Extracts the layer folder from a layer name:
func _get_layer_folder(layer: String) -> String:
	#@ Case 1 - purely numeric: no folder:
	if layer.is_valid_int():
		return ""

	#@ Case 2 - contains an underscore: remove last "_int":
	if "_" in layer:
		var parts = layer.split("_")
		parts.pop_back()             #/ remove last part (e.g. "1")
		return "_".join(parts)       #/ "sky_fg_1" → "sky_fg"

	#@ Case 3 - plain string, no underscore:
	return layer


#* Assign or animate a background image / animation / video:
func assign_bg(layer: String, file_ref: String, anim_name: String, loop: int, wait: int, time_target: float) -> void:
	self.visible = true		#/ Precaution, in case the scene is invisible for some reason. 

	#@ Step 1 - Locate the background node:
	var bg_node = bg_container.get_node_or_null(layer)
	if bg_node == null:
		printerr("assign_bg: Background layer not found: ", layer)
		return

	#@ Step 2 - Prepare runtime tracking:
	if not bg_layer_data.has(layer):
		bg_layer_data[layer] = {}

	var data = bg_layer_data[layer]
	data["loop_target"] = loop
	data["loops_played"] = 0
	data["wait_target"] = wait
	data["time_target"] = time_target
	data["elapsed_time"] = 0.0
	data["duration"] = 0.0
	data["resume_at"] = 0.0
	data["anim_id"] = "BG_%s" % layer
	data["paused"] = (loop == 0)

	#@ Step 3 - Resolve file path:
	var layer_folder = candy_de.background_folder.path_join(layer)
	var file_name = str(file_ref).strip_edges()
	var file_path: String
	if file_name == "":
		file_name = "Default"

	#% Pick appropriate extension or check for Animated folder:
	var animated_path = layer_folder.path_join("Animated").path_join(file_name)
	if file_name.find(".") == -1:
		if DirAccess.dir_exists_absolute(animated_path):
			file_path = animated_path
		else:
			if bg_node is TextureRect or bg_node is NinePatchRect:
				file_name += default_image_extension
			elif bg_node is Sprite2D or bg_node is Sprite3D:
				file_name += default_sprite_extension
			elif bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
				file_name += default_animated_sprite_extension
			elif bg_node is VideoStreamPlayer:
				file_name += default_video_extension

	#@ Step 4 - Stop existing playback:
	var timer := bg_node.get_node_or_null("BGAnimTimer")
	if timer:
		timer.stop()
		timer.queue_free()
	if bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
		bg_node.stop()
	elif bg_node is VideoStreamPlayer:
		bg_node.stop()

	#@ Step 5 - Determine resource path:
	if file_path == "":
		if bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
			file_path = layer_folder.path_join("Sprite_Frames").path_join(file_name)
		else:
			file_path = layer_folder.path_join(file_name)

	#@ Step 6 - Validate resource existence:
	if not ResourceLoader.exists(file_path):
		if not DirAccess.dir_exists_absolute(file_path):
			printerr("assign_bg(): Missing file: ", file_path, " → trying Default with same extension")
			var ext = file_name.get_extension()
			var fallback_same_ext = layer_folder.path_join("Default." + ext)
			if bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
				fallback_same_ext = layer_folder.path_join("Sprite_Frames").path_join("Default." + ext)

			if ResourceLoader.exists(fallback_same_ext):
				file_path = fallback_same_ext
			else:
				printerr("assign_bg(): Missing file: ", fallback_same_ext, " → trying Default with default extension")
				var default_ext = ""
				if bg_node is TextureRect or bg_node is NinePatchRect or bg_node is TextureButton:
					default_ext = default_image_extension
				elif bg_node is Sprite2D or bg_node is Sprite3D:
					default_ext = default_sprite_extension
				elif bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
					default_ext = default_animated_sprite_extension
				elif bg_node is VideoStreamPlayer:
					default_ext = default_video_extension

				var fallback_default_ext = layer_folder.path_join("Default" + default_ext)
				if bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
					fallback_default_ext = layer_folder.path_join("Sprite_Frames").path_join("Default" + default_ext)

				if ResourceLoader.exists(fallback_default_ext):
					file_path = fallback_default_ext
				else:
					printerr("assign_bg(): Missing file: ", fallback_default_ext, " → no fallback found, aborting")
					return

	var duration := 0.0

	#@ Static image / folder animation:
	if bg_node is TextureRect or bg_node is NinePatchRect:
		#% Check if file_path is a directory → folder animation:
		if DirAccess.dir_exists_absolute(file_path):
			var frames: Array[Texture2D] = []
			var dir = DirAccess.open(file_path)
			dir.list_dir_begin()
			var file = dir.get_next()
			while file != "":
				if not dir.current_is_dir() and not file.ends_with(".import") and not file.ends_with(".txt"):
					var loaded = load(file_path.path_join(file))
					if loaded is Texture2D:
						frames.append(loaded)
				file = dir.get_next()
			dir.list_dir_end()
			frames.sort_custom(func(a, b): return a.resource_path < b.resource_path)

			if frames.is_empty():
				printerr("assign_bg(): No frames found in folder: ", file_path)
				return

			bg_node.texture = frames[0]
			data["first_frame"] = frames[0]
			bg_node.visible = true

			if loop == 0:
				return

			var frame_state := {"index": 0}
			var anim_fps = image_fps
			var fps_txt := file_path.path_join("config.txt")
			if FileAccess.file_exists(fps_txt):
				var f := FileAccess.open(fps_txt, FileAccess.READ)
				if f:
					var line := f.get_as_text().strip_edges()
					f.close()
					if "=" in line:
						var val := line.split("=")[1].strip_edges()
						if val.is_valid_float():
							anim_fps = float(val)

			duration = float(frames.size()) / anim_fps
			data["duration"] = duration
			data["resume_at"] = (max(wait, 0) * duration) + max(time_target, 0.0)

			var new_timer = Timer.new()
			new_timer.name = "BGAnimTimer"
			new_timer.wait_time = 1.0 / anim_fps
			new_timer.autostart = true
			bg_node.add_child(new_timer)
			print("Timer added, wait_time=", new_timer.wait_time, " autostart=", new_timer.autostart, " in_tree=", new_timer.is_inside_tree())

			var _animate_folder := func():
				while true:
					await new_timer.timeout
					frame_state["index"] += 1
					if frame_state["index"] >= frames.size():
						frame_state["index"] = 0
						data["loops_played"] += 1
						data["elapsed_time"] = data["loops_played"] * duration
						if loop == -1:
							pass
						elif loop > 0 and data["loops_played"] >= loop:
							new_timer.stop()
							new_timer.queue_free()
							return
					bg_node.texture = frames[frame_state["index"]]
			_animate_folder.call_deferred()

		else:
			#% Static image:
			var tex := load(file_path)
			if tex is Texture2D:
				bg_node.texture = tex
				bg_node.visible = true
			return

	#@ TextureButton:
	if bg_node is TextureButton:
		var tex := load(file_path)
		if tex is Texture2D:
			bg_node.texture_normal = tex
			bg_node.visible = true
		else:
			printerr("assign_bg(): Invalid texture: ", file_path)
			return

		#@ Look for a matching subfolder in Button_Textures:
		#% Subfolder name is the file base name + underscore + extension (no dot),
		#% e.g. "Clouds.png" → "Clouds_png"
		var file_base = file_path.get_file().get_basename()
		var file_ext = file_path.get_extension().to_lower()
		var subfolder_name = file_base + "_" + file_ext
		var button_folder = layer_folder.path_join("Button_Textures").path_join(subfolder_name)

		if not DirAccess.dir_exists_absolute(button_folder):
			return

		#@ Scan the subfolder and assign files to their matching texture slots:
		var texture_slots = [
			"texture_pressed",
			"texture_hover",
			"texture_disabled",
			"texture_focused",
			"texture_click_mask",
		]
		var dir = DirAccess.open(button_folder)
		if not dir:
			return
		#% Build a list of all files in the subfolder once, then match against slots:
		var all_files = []
		dir.list_dir_begin()
		var fname = dir.get_next()
		while fname != "":
			if not dir.current_is_dir():
				all_files.append(fname)
			fname = dir.get_next()
		dir.list_dir_end()

		#% For each slot, find a file whose name contains the slot name as a prefix:
		for slot in texture_slots:
			for f in all_files:
				if f.get_basename().to_lower().begins_with(slot):
					var slot_tex := load(button_folder.path_join(f))
					if slot_tex is Texture2D:
						bg_node.set(slot, slot_tex)
					break

		return

	#@ Sprite:
	var regex := RegEx.new()
	regex.compile("(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")

	if bg_node is Sprite2D or bg_node is Sprite3D:
		var tex := load(file_path)
		if not (tex is Texture2D):
			printerr("assign_bg(): Invalid texture: ", file_path)
			return

		bg_node.texture = tex
		_scale_bg_to_size(bg_node, layer)    #/ Apply scaling here

		var result := regex.search(file_path.get_file())
		var hframes = 1
		var vframes = 1
		var missing = 0
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

		var total_frames = max(hframes * vframes - missing, 1)
		if total_frames <= 1 or loop == 0:
			return

		duration = total_frames / sprite_fps
		data["duration"] = duration
		data["resume_at"] = (max(wait, 0) * duration) + max(time_target, 0.0)

		var new_timer = Timer.new()
		new_timer.name = "BGAnimTimer"
		new_timer.wait_time = 1.0 / sprite_fps
		new_timer.autostart = true
		bg_node.add_child(new_timer)

		var _animate_sprite := func():
			while true:
				await new_timer.timeout
				data["elapsed_time"] += 1.0 / sprite_fps
				var next_frame = bg_node.frame + 1
				if next_frame >= total_frames:
					data["loops_played"] += 1
					next_frame = 0
					if loop == -1:
						pass	#/ Infinite — keep looping
					elif loop > 0 and data["loops_played"] >= loop:
						new_timer.stop()
						new_timer.queue_free()
						return
				bg_node.frame = next_frame
		_animate_sprite.call_deferred()

	#@ AnimatedSprite:
	elif bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
		var frames := load(file_path)
		if not (frames is SpriteFrames):
			printerr("assign_bg(): Invalid SpriteFrames resource: ", file_path)
			return

		bg_node.sprite_frames = frames
		bg_node.visible = true

		#% Select animation track:
		var anim = anim_name if anim_name != "" and frames.has_animation(anim_name) else (
			file_ref if frames.has_animation(file_ref) else (
				frames.get_animation_names()[0] if frames.get_animation_names().size() > 0 else ""
			)
		)
		if anim == "":
			printerr("assign_bg(): No valid animation in resource: ", file_path)
			return

		if loop == 0:
			bg_node.frame = 0
			bg_node.stop()
			return

		duration = frames.get_frame_count(anim) / sprite_fps
		data["duration"] = duration
		data["resume_at"] = (max(wait, 0) * duration) + max(time_target, 0.0)

		var _animate_asp := func():
			while true:
				bg_node.play(anim)
				await bg_node.animation_finished
				data["loops_played"] += 1
				data["elapsed_time"] = data["loops_played"] * duration
				if loop == -1:
					continue
				elif loop > 0 and data["loops_played"] >= loop:
					bg_node.stop()
					return
		_animate_asp.call_deferred()

	#@ Video:
	elif bg_node is VideoStreamPlayer:
		var stream := load(file_path)
		if not (stream is VideoStream):
			printerr("assign_bg(): Invalid video stream: ", file_path)
			return

		bg_node.stream = stream
		bg_node.visible = true
		duration = stream.get_length() if "get_length" in stream else 0.0
		data["duration"] = duration
		data["resume_at"] = (max(wait, 0) * duration) + max(time_target, 0.0)

		if loop == 0:
			bg_node.play()
			await get_tree().process_frame
			bg_node.paused = true
			return
		else:
			bg_node.paused = false
			bg_node.play()

		var _animate_video := func():
			while true:
				await bg_node.finished
				data["loops_played"] += 1
				data["elapsed_time"] = data["loops_played"] * duration
				if loop > 0 and data["loops_played"] >= loop:
					bg_node.stop()
					return
				else:
					bg_node.play()
		_animate_video.call_deferred()

	#@ Wait handling:
	if wait > 0 or time_target > 0.0:
		var target_time = (max(wait, 0) * duration) + max(time_target, 0.0)
		while data["elapsed_time"] < target_time:
			await get_tree().process_frame


#* Stop background animations for one or more layers:
func stop_bg_animation(layers: Array, default: int) -> void:
	#@ Step 1 - Resolve which layers to stop:
	var layers_to_stop: Array = []
	if layers.is_empty():
		for child in bg_container.get_children():
			if child is Node:
				layers_to_stop.append(child.name)
	else:
		layers_to_stop = layers.duplicate()

	#% Nothing to stop:
	if layers_to_stop.is_empty():
		return

	#@ Step 2 - Process each layer:
	for layer_name in layers_to_stop:
		var bg_node = bg_container.get_node_or_null(NodePath(layer_name))
		if bg_node == null:
			printerr("stop_bg_animation: Layer not found: ", layer_name)
			continue

		#% Stop timers if any (for frame-based sheets):
		var timer := bg_node.get_node_or_null("BGAnimTimer")
		if timer:
			timer.stop()
			timer.queue_free()

		#% Update tracking data:
		if bg_layer_data.has(layer_name):
			var data = bg_layer_data[layer_name]
			data["paused"] = true
			if default == 1:
				data["loops_played"] = 0
				data["elapsed_time"] = 0.0

		#@ Step 3 - Pause depending on node type:
		if bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
			bg_node.stop()
			if default == 1:
				bg_node.frame = 0
			bg_node.visible = true

		elif bg_node is Sprite2D or bg_node is Sprite3D:
			if default == 1:
				bg_node.frame = 0
			bg_node.visible = true

		elif bg_node is VideoStreamPlayer:
			bg_node.stop()
			if default == 1:
				bg_node.stream_position = 0.0
			bg_node.visible = true

		elif bg_node is TextureRect or bg_node is NinePatchRect:
			if default == 1 and bg_layer_data.has(layer_name) and bg_layer_data[layer_name].has("first_frame"):
				bg_node.texture = bg_layer_data[layer_name]["first_frame"]
			bg_node.visible = true

		else:
			printerr("stop_bg_animation: Unsupported background node type: ", bg_node)


#* Clear one or more background layers completely (remove all visuals/streams):
func clear_bg_nodes(layers: Array) -> void:
	#@ Step 1 - Resolve which layers to clear:
	var layers_to_clear: Array = []

	if layers.is_empty():
		for child in bg_container.get_children():
			if child is Node:
				layers_to_clear.append(child.name)
	else:
		layers_to_clear = layers.duplicate()

	#% Nothing to clear:
	if layers_to_clear.is_empty():
		return

	#@ Step 2 - Process each layer:
	for layer_name in layers_to_clear:
		var bg_node = bg_container.get_node_or_null(NodePath(layer_name))
		if bg_node == null:
			printerr("clear_bg_nodes: Background layer not found: ", layer_name)
			continue

		#% Stop any timer or animation:
		var timer := bg_node.get_node_or_null("BGAnimTimer")
		if timer:
			timer.stop()
			timer.queue_free()

		if bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
			bg_node.stop()
		elif bg_node is VideoStreamPlayer:
			bg_node.stop()

		#% Clean out tracking data:
		var anim_id := "BG_%s" % layer_name
		if anim_id in caller.active_bg_animations:
			caller.active_bg_animations.erase(anim_id)

		if bg_layer_data.has(layer_name):
			bg_layer_data.erase(layer_name)

		#@ Step 3 - Clear visuals per node type:
		if bg_node is TextureRect or bg_node is NinePatchRect:
			#bg_node.visible = false
			bg_node.texture = null

		elif bg_node is TextureButton:
			#bg_node.visible = false
			bg_node.texture_normal = null
			bg_node.texture_pressed = null
			bg_node.texture_hover = null
			bg_node.texture_disabled = null
			bg_node.texture_focused = null
			bg_node.texture_click_mask = null

		elif bg_node is Sprite2D or bg_node is Sprite3D:
			#bg_node.visible = false
			bg_node.texture = null
			bg_node.hframes = 1
			bg_node.vframes = 1
			bg_node.frame = 0
			bg_node.scale = Vector2(1, 1)

		elif bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
			#bg_node.visible = false
			bg_node.sprite_frames = null
			bg_node.frame = 0

		elif bg_node is VideoStreamPlayer:
			#bg_node.visible = false
			bg_node.stream = null
			bg_node.stream_position = 0.0

		else:
			printerr("clear_bg_nodes: Unsupported background node type: ", bg_node)


#* Flip BG layers horizontally or vertically:
func mirror_bg(layer, axis):
	#@ Step 1 - Find the correct bg node:
	var layer_node = bg_container.get_node_or_null(layer)
	if layer_node == null:
		printerr("bg node not found: ", layer)
		return

	#@ Step 2 - Flip axis based on node type:
	if (axis.to_lower() == "h flip" or axis.to_lower() == "both") and "flip_h" in layer_node:
		layer_node.flip_h = not layer_node.flip_h
	if (axis.to_lower() == "v flip" or axis.to_lower() == "both") and "flip_v" in layer_node:
		layer_node.flip_v = not layer_node.flip_v
	if axis.to_lower() == "reset" and "flip_h" in layer_node:	#/ Nodes always have both flip_h and flip_v
		layer_node.flip_h = false
		layer_node.flip_v = false

	if not "flip_h" in layer_node:
		printerr("mirror_bg(): Unsupported bg node type: ", layer_node)


#* Play one or more AnimationPlayer-based effects on one or more Background layers:
func play_bg_effects(layers: Array, library: String, effects: Array, loop: int = 0, wait: int = -1, time_target: float = 0.0) -> void:
	#@ Step 1 - Resolve target layers:
	var layers_to_play: Array = []
	if layers.is_empty():
		for child in bg_container.get_children():
			if child is Node:
				layers_to_play.append(child.name)
	else:
		layers_to_play = layers.duplicate()

	if layers_to_play.is_empty():
		return

	#@ Step 2 - Process each layer:
	for layer_name in layers_to_play:
		var bg_node = bg_container.get_node_or_null(layer_name)
		if bg_node == null:
			printerr("play_bg_effects(): Background layer not found: ", layer_name)
			continue

		var layer_folder = candy_de.background_folder.path_join(_get_layer_folder(layer_name))
		var lib_path = layer_folder.path_join("Animation_Libraries").path_join(library)
		if not lib_path.ends_with(".tres") and not lib_path.ends_with(".res"):
			lib_path = lib_path + default_effect_extension
		if not ResourceLoader.exists(lib_path):
			printerr("play_bg_effects(): Missing Background Animation Library: ", lib_path)
			continue

		var anim_lib := load(lib_path)
		if not (anim_lib is AnimationLibrary):
			printerr("play_bg_effects(): Invalid Background AnimationLibrary: ", lib_path)
			continue

		var lib_anims = anim_lib.get_animation_list()
		if lib_anims.is_empty():
			continue

		#@ Step 3 - Resolve effect names to play:
		var effects_to_play: Array = []
		if effects.is_empty():
			effects_to_play = lib_anims
		else:
			for e in effects:
				if e in lib_anims:
					effects_to_play.append(e)
				else:
					printerr("play_bg_effects(): Effect not found in library: ", e)

		#@ Step 4 - Start all effects asynchronously:
		for effect_name in effects_to_play:
			_play_single_bg_effect(bg_node, layer_name, anim_lib, library, effect_name, loop, wait, time_target)


#* Internal helper: play one animation effect asynchronously:
func _play_single_bg_effect(bg_node: Node, layer_name: String, anim_lib: AnimationLibrary, library: String, effect_name: String, loop_target: int, wait_target: int, time_target: float) -> void:
	var anim: Animation = anim_lib.get_animation(effect_name)
	if anim == null:
		printerr("play_bg_effects(): Background effect animation is null: ", effect_name)
		return

	#@ Step 1 - Find or create AnimationPlayer:
	var player: AnimationPlayer = null
	for child in bg_node.get_children():
		if child is AnimationPlayer and not child.is_playing():
			player = child
			break

	if player == null:
		player = AnimationPlayer.new()
		player.root_node = "."
		bg_node.add_child(player)

	#@ Step 2 - Register animation library:
	if not player.has_animation_library(library):
		#% Remove default empty library if present to avoid conflicts:
		if player.has_animation_library(""):
			player.remove_animation_library("")
		player.add_animation_library(library, anim_lib)

	#@ Step 3 - Prepare runtime data:
	if not bg_layer_data.has(layer_name):
		bg_layer_data[layer_name] = {}

	var layer_data = bg_layer_data[layer_name]
	if not layer_data.has("effects"):
		layer_data["effects"] = {}

	layer_data["effects"][effect_name] = {
		"loop_target": loop_target,
		"loops_played": 0,
		"wait_target": wait_target,
		"time_target": time_target,
		"duration": anim.length,
		"elapsed_time": 0.0,
		"player": player,
	}

	var effect_data = layer_data["effects"][effect_name]
	var resume_at = (max(wait_target, 0) * anim.length) + max(time_target, 0.0)

	#@ Step 4 - Launch asynchronous coroutine:
	var _run_effect := func():
		var loops_played := 0

		#% If no wait required, play and loop in background:
		if resume_at <= 0.0:
			player.play(library + "/" + effect_name)
			while true:
				await player.animation_finished
				loops_played += 1
				effect_data["loops_played"] = loops_played
				if loop_target > 0 and loops_played >= loop_target:
					player.seek(anim.length, true)
					return
				player.play(library + "/" + effect_name)
			return

		#% Wait until resume_at is reached:
		while true:
			player.play(library + "/" + effect_name)
			await player.animation_finished
			loops_played += 1
			effect_data["loops_played"] = loops_played
			effect_data["elapsed_time"] = loops_played * anim.length

			if effect_data["elapsed_time"] >= resume_at:
				var _finish := func():
					var bg_loops := loops_played
					while true:
						if loop_target > 0 and bg_loops >= loop_target:
							player.seek(anim.length, true)
							return
						player.play(library + "/" + effect_name)
						await player.animation_finished
						bg_loops += 1
				_finish.call_deferred()
				return

			if loop_target > 0 and loops_played >= loop_target:
				player.seek(anim.length, true)
				return

	_run_effect.call_deferred()


#* Stop ongoing effects on background layers:
func stop_bg_effects(layers: Array, effects: Array) -> void:
	#@ Step 1 - Resolve target layers:
	var layers_to_stop: Array = []

	if layers.is_empty():
		for child in bg_container.get_children():
			if child is Node:
				layers_to_stop.append(child.name)
	else:
		layers_to_stop = layers.duplicate()

	#% Nothing to stop:
	if layers_to_stop.is_empty():
		return

	#@ Step 2 - Iterate through each layer:
	for layer_name in layers_to_stop:
		var bg_node = bg_container.get_node_or_null(layer_name)
		if bg_node == null:
			continue

		#@ Step 3 - Stop effects on all AnimationPlayers:
		for child in bg_node.get_children():
			if not (child is AnimationPlayer):
				continue

			#% No specific effects → stop everything:
			if effects.is_empty():
				child.stop()
				continue

			#% Selective stop by effect name:
			for e in effects:
				for lib_name in child.get_animation_library_list():
					var full_name = (lib_name + "/" + e) if lib_name != "" else e
					if child.has_animation(full_name) and child.is_playing() and child.current_animation == full_name:
						child.stop()
						break

		#@ Step 4 - Clean runtime effect data:
		if bg_layer_data.has(layer_name) and bg_layer_data[layer_name].has("effects"):
			var eff_dict = bg_layer_data[layer_name]["effects"]
			if effects.is_empty():
				eff_dict.clear()
			else:
				for e in effects:
					eff_dict.erase(e)


#* Scale Sprite2D or Sprite3D backgrounds to match target dimensions:
func _scale_bg_to_size(bg_node: Node, layer: String) -> void:
	if not bg_sizes.has(layer):
		return

	var target_size: Array = bg_sizes[layer]
	if target_size.size() < 2:
		return

	var target_h = float(target_size[0])
	var target_w = float(target_size[1])

	#% Determine texture size:
	if bg_node is Sprite2D or bg_node is Sprite3D:
		var tex: Texture2D = bg_node.texture
		if tex == null:
			return
		var tex_size = tex.get_size()
		if tex_size.x == 0 or tex_size.y == 0:
			return

		#@ Calculate scale ratio:
		var scale_x = target_w / tex_size.x
		var scale_y = target_h / tex_size.y
		bg_node.scale = Vector2(scale_x, scale_y)
