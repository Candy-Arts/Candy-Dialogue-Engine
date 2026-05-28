#!###########################################################################################
#!																							#
#!         THIS SCRIPT CONTAINS CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS        #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                 Any unauthorized use constitutes copyright infringement.                 #
#!																							#
#!   This disclaimer must be featured at the top of any script featuring Candy Arts code,   #
#!                            and may not be removed or modified.                           #
#!																							#
#!###########################################################################################


extends Node


@onready var busts_container = get_node("Busts_Control")
@onready var highlight_player_1 = get_node("HighlightPlayer_1")	#/ Add more AnimationPlayers for multiple simultaneous highlight animations

@export var default_image_extension = ".png"				#/ TextureRect, NinePatchRect, TextureButton
@export var default_sprite_extension = ".png"				#/ Sprite2D, Sprite3D
@export var default_animated_sprite_extension = ".tres"		#/ AnimatedSprite2D, AnimatedSprite3D
@export var default_video_extension = ".ogv"				#/ VideoStreamPlayer
@export var default_effect_extension = ".tres"				#/ AnimationPlayer

#? The FPS value to use for Sprite2D, Sprite3D, AnimatedSprite2D or AnimatedSprite3D animations.
@export var image_fps = 30.0
@export var sprite_fps = 30.0

#? Used for scaling Sprite2D or Sprite3D nodes to the desired size:
@export var bust_sizes = {
	"1": [1080, 1024],	#/ [height, width]
	"2": [1080, 1024],
	"3": [1080, 1024],
	"4": [1080, 1024],
	"5": [1080, 1024],
	"6": [1080, 1024],
	"7": [1080, 1024],
	"8": [1080, 1024],
	"9": [1080, 1024],
}

#^ Join/Move/Leave Effect Player:
@export var jml_player_name = "JML"

#^ Join/Move/Leave effects:
#? Visual effects to automatically play on bust nodes when an actor joins, moves or leaves.
#? If not empty (""), overriddes the general settings.
#? Can be overridden by the actors dictionary settings.
#% Write the name of the animations to play.
#+ The animation must exist in the bust node's child animation player.
@export var vn_join_effect = ["", ""]
@export var vn_move_from_effect = ["", ""]
@export var vn_move_to_effect = ["", ""]
@export var vn_leave_effect = ["", ""]

#^ Speaker highlight:
#? How to highlight speaker busts:
@export var speaker_highlight = {
	"NameTag": false,				#/ Display a name tag over/under/above/near the speaker bust.
	"Outline": false,				#/ Display another image/animation over the original (e.g. colored outline).
	"OutlineHideReal": false,		#/ Hide the real image/animation to simulate temporary replacement.
	"Scale": false,					#/ Change the scale of the speaker bust.
	"Scale_Size": 1.1,
	"Animation_1": false,			#/ Can add keys for multiple animations.
	"AnimationName_1": "highlight",
	"Billboard": true,				#/ Set the Billboard property on Sprite3D or AnimatedSprite3D
}

#^ Automatic billboard:
#? Change these values to match what billboard mode to set Sprite3D busts to
@export var billboard_on = BaseMaterial3D.BILLBOARD_ENABLED
@export var billboard_off = BaseMaterial3D.BILLBOARD_DISABLED

#^ Z Index:
@export var default_z = 100

#^ Bust node data:
#? Used by the functions to store relevant data about each bust node
var bust_node_data = {}

var caller: Node



func _ready():
	self.z_index = default_z


#& Bust Highlight Logic
#? These functions determine how the speaker's bust is visually emphasized.
#? Code under "Box" mode can be copy/pasted to other modes.
#? If you create custom dialogue modes, add them to these functions.

#? Basic highlight options are provided for convenience and as templates.
#? The logic is designed to let you easily add your own behaviors as desired.

#! Do not add AnimationPlayer nodes as direct children of bust nodes: may conflict with §VNEffect AnimationPlayers.
#! Remember to revert the effects of highlight_speaker() in end_highlight_speaker()

#* Highlight the speaker bust:
func highlight_speaker(speaker_ref, dialogue_mode):
	var speaker_bust_ref = caller.bust_positions[speaker_ref]["pos"]
	var speaker_bust = busts_container.get_node(speaker_bust_ref)
	match dialogue_mode:
		"Box":
			if speaker_highlight["NameTag"] == true:
				#% Show NameTag:
				speaker_bust.get_node("NameTag").visible = true

				#% Write speaker name in NameTag:
				#+ No BBCode:
				speaker_bust.get_node("NameTag").text = candy_de.actors[speaker_ref]["DisplayName"]
				#+ Alternative - copy text from dialogue box speaker field to replicate BBCode formating:
				#speaker_bust.get_node("NameTag").text = get_node(caller.dialogue_box_path).speaker_node.text

				#% Clear text in dialogue box speaker field to avoid redundancy:
				#+ You can also make speaker area invisible, but revert the change in end_highlight_speaker()
				get_node(candy_de.dialogue_box_path).speaker_node.text = ""

			if speaker_highlight["Outline"] == true:
				#% Find the outline node if it exists:
				var speaker_outline = speaker_bust.get_node_or_null("Outline")
				if speaker_outline:
					speaker_outline.visible = true
				#% Hide the 'real' (original) bust node by making it transparent:
				if speaker_highlight["OutlineHideReal"] == true:
					speaker_bust.self_modulate = Color(1, 1, 1, 0)	#/ Fully transparent
				#TODO Write logic to display the outline.

			if speaker_highlight["Scale"] == true and "scale" in speaker_bust:
				speaker_bust.scale *= speaker_highlight["Scale_Size"]

			if speaker_highlight["Animation_1"] == true:
				highlight_player_1.stop()
				highlight_player_1.root_node = highlight_player_1.get_path_to(speaker_bust)
				highlight_player_1.play(speaker_highlight["AnimationName_1"])

			if speaker_highlight["Billboard"] == true and "billboard" in speaker_bust:
				speaker_bust.billboard = billboard_on

		"Bubbles", "VN_Bubbles":	#/ Candy DE defaults from "Bubbles" to "VN_Bubbles" in VN mode.
			pass

		"Subtitles":
			pass

		"Chat":
			pass

		"Voice":
			pass


#* Undo speaker bust highlighting when dialogue line finishes:
func end_highlight_speaker(speaker_ref, dialogue_mode):
	var speaker_bust_ref = caller.bust_positions[speaker_ref]["pos"]
	var speaker_bust = busts_container.get_node(speaker_bust_ref)
	match dialogue_mode:
		"Box":
			if speaker_highlight["NameTag"] == true:
				speaker_bust.get_node("NameTag").visible = false
				speaker_bust.get_node("NameTag").text = ""

			if speaker_highlight["Outline"] == true:
				#% Find the outline node if it exists:
				var speaker_outline = speaker_bust.get_node_or_null("Outline")
				if speaker_outline:
					speaker_outline.visible = false
				#% Unhide the 'real' (original) bust node by making it opaque again:
				if speaker_highlight["OutlineHideReal"] == true:
					speaker_bust.self_modulate = Color(1, 1, 1, 1)
				#TODO Write logic to remove outline display.

			if speaker_highlight["Scale"] == true and "scale" in speaker_bust:
				if speaker_bust is Sprite2D or speaker_bust is Sprite3D:
					_scale_bust_to_size(speaker_bust, speaker_bust_ref)
				else:
					speaker_bust.scale = Vector2(1, 1)

			if speaker_highlight["Animation_1"] == true:
				highlight_player_1.stop()

			if speaker_highlight["Billboard"] == true and "billboard" in speaker_bust:
				speaker_bust.billboard = billboard_off

		"Bubbles", "VN_Bubbles":	#/ Candy DE defaults from Bubbles to VN_Bubbles in VN mode.
			pass

		"Subtitles":
			pass

		"Chat":
			pass

		"Voice":
			pass



#& Bust Display Logic:
#? The functions below are called by VN commands to display busts and animations of all sorts.

#* Assign a bust and play/pause depending on Play:
func set_bust(actor: String, bust_ref: String, file_ref: String, anim_name: String, loop: int, wait: int, time_target: float) -> void:
	self.visible = true		#/ Precaution, in case the scene is invisible for some reason.

	var bust_node = busts_container.get_node_or_null(bust_ref)
	if bust_node == null:
		printerr("set_bust: Bust node not found: ", bust_ref)
		return

	if not bust_node_data.has(actor):
		bust_node_data[actor] = {}
	var data = bust_node_data[actor]
	data["loop_target"] = loop
	data["loops_played"] = 0
	data["wait_target"] = wait
	data["time_target"] = time_target
	data["elapsed_time"] = 0.0
	data["duration"] = 0.0
	data["resume_at"] = 0.0
	data["paused"] = (loop == 0)

	#@ Step 1 - Resolve file path:
	var actor_folder = candy_de.busts_folder.path_join(actor)
	var file_name = file_ref.strip_edges()
	var file_path: String
	if file_name == "":
		file_name = "Default"

	#% Pick appropriate extension or check for Animated folder:
	var animated_path = actor_folder.path_join("Animated").path_join(file_name)
	if file_name.find(".") == -1:
		if DirAccess.dir_exists_absolute(animated_path):
			file_path = animated_path
		else:
			if bust_node is TextureRect or bust_node is NinePatchRect or bust_node is TextureButton:
				file_name += default_image_extension
			elif bust_node is Sprite2D or bust_node is Sprite3D:
				file_name += default_sprite_extension
			elif bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
				file_name += default_animated_sprite_extension
			elif bust_node is VideoStreamPlayer:
				file_name += default_video_extension

	#@ Step 2 - Stop existing playback:
	var timer := bust_node.get_node_or_null("SpriteAnimTimer")
	if timer:
		timer.stop()
		timer.queue_free()
	if bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
		bust_node.stop()
	elif bust_node is VideoStreamPlayer:
		bust_node.stop()

	#@ Step 3 - Determine path depending on node type:
	if file_path == "":
		if bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
			file_path = actor_folder.path_join("Sprite_Frames").path_join(file_name)
		else:
			file_path = actor_folder.path_join(file_name)

	#@ Step 4 - Validate resource existence:
	if not ResourceLoader.exists(file_path):
		if not DirAccess.dir_exists_absolute(file_path):
			printerr("set_bust: Missing file: ", file_path, " → trying Default with same extension")
			var ext = file_name.get_extension()
			var fallback_same_ext = actor_folder.path_join("Default." + ext)
			if bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
				fallback_same_ext = actor_folder.path_join("Sprite_Frames").path_join("Default." + ext)

			if ResourceLoader.exists(fallback_same_ext):
				file_path = fallback_same_ext
			else:
				printerr("set_bust: Missing file: ", fallback_same_ext, " → trying Default with default extension")
				var default_ext = ""
				if bust_node is TextureRect or bust_node is NinePatchRect or bust_node is TextureButton:
					default_ext = default_image_extension
				elif bust_node is Sprite2D or bust_node is Sprite3D:
					default_ext = default_sprite_extension
				elif bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
					default_ext = default_animated_sprite_extension
				elif bust_node is VideoStreamPlayer:
					default_ext = default_video_extension

				var fallback_default_ext = actor_folder.path_join("Default" + default_ext)
				if bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
					fallback_default_ext = actor_folder.path_join("Sprite_Frames").path_join("Default" + default_ext)

				if ResourceLoader.exists(fallback_default_ext):
					file_path = fallback_default_ext
				else:
					printerr("set_bust: Missing file: ", fallback_default_ext, " → no fallback found, aborting")
					return

	var duration := 0.0

	#@ Static image / folder animation:
	if bust_node is TextureRect or bust_node is NinePatchRect:
		if DirAccess.dir_exists_absolute(file_path):
			var frames: Array = []
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
				printerr("set_bust: No frames found in folder: ", file_path)
				return

			bust_node.texture = frames[0]
			bust_node.visible = true
			data["first_frame"] = frames[0]

			#% Read FPS from config.txt:
			var anim_fps = image_fps
			var config_txt := file_path.path_join("config.txt")
			if FileAccess.file_exists(config_txt):
				var f := FileAccess.open(config_txt, FileAccess.READ)
				if f:
					var line := f.get_as_text().strip_edges()
					f.close()
					if "=" in line:
						var val := line.split("=")[1].strip_edges()
						if val.is_valid_float():
							anim_fps = float(val)

			if loop == 0:
				await _on_play_jml("Join", actor, bust_node, null)
				return

			duration = float(frames.size()) / anim_fps
			data["duration"] = duration
			data["resume_at"] = (max(wait, 0) * duration) + max(time_target, 0.0)
			data["anim_fps"] = anim_fps
			data["frames"] = frames

			var new_timer = Timer.new()
			new_timer.name = "SpriteAnimTimer"
			new_timer.wait_time = 1.0 / anim_fps
			new_timer.autostart = true
			bust_node.add_child(new_timer)

			var frame_state := {"index": 0}
			data["frame_state"] = frame_state

			var _animate := func():
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
					bust_node.texture = frames[frame_state["index"]]
			_animate.call_deferred()

			await _on_play_jml("Join", actor, bust_node, null)

		else:
			var tex := load(file_path)
			if tex is Texture2D:
				bust_node.texture = tex
				bust_node.visible = true
			else:
				printerr("set_bust: Invalid texture: ", file_path)
			await _on_play_jml("Join", actor, bust_node, null)

		return

	#@ TextureButton:
	if bust_node is TextureButton:
		var tex := load(file_path)
		if tex is Texture2D:
			bust_node.texture_normal = tex
			bust_node.visible = true
		else:
			printerr("set_bust: Invalid texture: ", file_path)
			return

		#@ Look for a matching subfolder in Button_Textures:
		#% Subfolder name is the file base name + underscore + extension (no dot),
		#% e.g. "Alice.png" → "Button_Textures/Alice_png"
		var file_base = file_path.get_file().get_basename()
		var file_ext = file_path.get_extension().to_lower()
		var subfolder_name = file_base + "_" + file_ext
		var button_folder = actor_folder.path_join("Button_Textures").path_join(subfolder_name)

		if DirAccess.dir_exists_absolute(button_folder):
			var texture_slots = [
				"texture_pressed",
				"texture_hover",
				"texture_disabled",
				"texture_focused",
				"texture_click_mask",
			]
			#% Scan the subfolder once, then match files to slots by checking if the filename contains the slot name anywhere in its basename:
			var dir = DirAccess.open(button_folder)
			if dir:
				var all_files = []
				dir.list_dir_begin()
				var fname = dir.get_next()
				while fname != "":
					if not dir.current_is_dir():
						all_files.append(fname)
					fname = dir.get_next()
				dir.list_dir_end()

				for slot in texture_slots:
					for f in all_files:
						if f.get_basename().to_lower().contains(slot):
							var slot_tex := load(button_folder.path_join(f))
							if slot_tex is Texture2D:
								bust_node.set(slot, slot_tex)
							break

		await _on_play_jml("Join", actor, bust_node, null)
		return

	#@ Sprite:
	if bust_node is Sprite2D or bust_node is Sprite3D:
		var tex := load(file_path)
		if not (tex is Texture2D):
			printerr("set_bust: Invalid texture: ", file_path)
			return

		bust_node.texture = tex
		_scale_bust_to_size(bust_node, bust_ref)

		#% Parse "WxH" pattern for frame layout:
		var regex := RegEx.new()
		regex.compile("(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")
		var result := regex.search(file_path.get_file())
		var hframes = 1
		var vframes = 1
		var missing = 0
		if result:
			hframes = int(result.get_string(1))
			vframes = int(result.get_string(2))
			if result.get_string(3) != "":
				missing = int(result.get_string(3))

		bust_node.texture = tex
		bust_node.hframes = hframes
		bust_node.vframes = vframes
		bust_node.frame = 0
		bust_node.visible = true

		await _on_play_jml("Join", actor, bust_node, null)

		var total_frames = max(hframes * vframes - missing, 1)
		duration = total_frames / sprite_fps
		data["duration"] = duration
		data["resume_at"] = (max(wait, 0) * duration) + max(time_target, 0.0)

		if loop == 0 or total_frames <= 1:
			return

		var new_timer = Timer.new()
		new_timer.name = "SpriteAnimTimer"
		new_timer.wait_time = 1.0 / sprite_fps
		new_timer.autostart = true
		bust_node.add_child(new_timer)

		var _animate := func():
			while true:
				await new_timer.timeout
				data["elapsed_time"] += 1.0 / sprite_fps
				var next_frame = bust_node.frame + 1
				if next_frame >= total_frames:
					data["loops_played"] += 1
					next_frame = 0
					if loop == -1:
						pass    #/ Infinite — keep looping
					elif loop > 0 and data["loops_played"] >= loop:
						new_timer.stop()
						new_timer.queue_free()
						return
				bust_node.frame = next_frame
		_animate.call_deferred()

	#@ AnimatedSprite:
	elif bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
		var frames := load(file_path)
		if not (frames is SpriteFrames):
			printerr("set_bust: Invalid SpriteFrames: ", file_path)
			return

		bust_node.sprite_frames = frames
		bust_node.visible = true

		await _on_play_jml("Join", actor, bust_node, null)

		#% Select animation track:
		var anim = anim_name if anim_name != "" and frames.has_animation(anim_name) else (
			file_ref if frames.has_animation(file_ref) else (
				frames.get_animation_names()[0] if frames.get_animation_names().size() > 0 else ""
			)
		)
		if anim == "":
			printerr("set_bust: No valid animation in ", file_path)
			return

		if loop == 0:
			bust_node.frame = 0
			bust_node.stop()
			return

		duration = frames.get_frame_count(anim) / sprite_fps
		data["duration"] = duration
		data["resume_at"] = (max(wait, 0) * duration) + max(time_target, 0.0)

		var _anim_loop := func():
			while true:
				bust_node.play(anim)
				await bust_node.animation_finished
				data["loops_played"] += 1
				data["elapsed_time"] = data["loops_played"] * duration
				if loop == -1:
					continue    #/ Infinite — keep looping
				elif loop > 0 and data["loops_played"] >= loop:
					bust_node.stop()
					return
		_anim_loop.call_deferred()

	#@ Video:
	elif bust_node is VideoStreamPlayer:
		var stream := load(file_path)
		if not (stream is VideoStream):
			printerr("set_bust: Invalid video stream: ", file_path)
			return

		bust_node.stream = stream
		bust_node.visible = true
		duration = stream.get_length() if "get_length" in stream else 0.0
		data["duration"] = duration
		data["resume_at"] = (max(wait, 0) * duration) + max(time_target, 0.0)

		bust_node.play()
		await get_tree().process_frame
		bust_node.paused = true

		await _on_play_jml("Join", actor, bust_node, null)

		if loop == 0:
			return

		bust_node.paused = false
		bust_node.play()

		var _animate_video := func():
			while true:
				await bust_node.finished
				data["loops_played"] += 1
				data["elapsed_time"] = data["loops_played"] * duration
				if loop > 0 and data["loops_played"] >= loop:
					bust_node.stop()
					return
				else:
					bust_node.play()
		_animate_video.call_deferred()

	#@ Wait handling:
	if wait > 0 or time_target > 0.0:
		var target_time = (max(wait, 0) * duration) + max(time_target, 0.0)
		while data["elapsed_time"] < target_time:
			await get_tree().process_frame


#* Move a bust to another node, preserving animation and playback state:
func move_bust(actor: String, old_bust: String, new_bust: String) -> void:
	self.visible = true		#/ Precaution, in case the scene is invisible for some reason.

	var bust_node_old = busts_container.get_node_or_null(old_bust)
	var bust_node_new = busts_container.get_node_or_null(new_bust)
	if bust_node_old == null or bust_node_new == null:
		printerr("move_bust: Missing bust node(s): ", old_bust, " or ", new_bust)
		return

	#@ Retrieve tracking data:
	if not bust_node_data.has(actor):
		printerr("move_bust: No bust data found for actor: ", actor)
		return

	#@ Check that old and new node are same type:
	if (bust_node_old is AnimatedSprite2D or bust_node_old is AnimatedSprite3D) and not (bust_node_new is AnimatedSprite2D or bust_node_new is AnimatedSprite3D):
		return
	if (bust_node_old is Sprite2D or bust_node_old is Sprite3D) and not (bust_node_new is Sprite2D or bust_node_new is Sprite3D):
		return
	if (bust_node_old is TextureRect or bust_node_old is NinePatchRect) and not (bust_node_new is TextureRect or bust_node_new is NinePatchRect):
		return

	var data = bust_node_data[actor]

	#@ Preserve current animation name if applicable:
	if (bust_node_old is AnimatedSprite2D or bust_node_old is AnimatedSprite3D) and bust_node_old.animation != "":
		data["current_anim"] = bust_node_old.animation

	#@ Preserve visual/animation state depending on node type:
	if bust_node_old is Sprite2D or bust_node_old is Sprite3D:
		bust_node_new.texture = bust_node_old.texture
		bust_node_new.hframes = bust_node_old.hframes
		bust_node_new.vframes = bust_node_old.vframes
		bust_node_new.frame = bust_node_old.frame

	elif bust_node_old is AnimatedSprite2D or bust_node_old is AnimatedSprite3D:
		bust_node_new.sprite_frames = bust_node_old.sprite_frames
		bust_node_new.animation = bust_node_old.animation
		bust_node_new.frame = bust_node_old.frame

	elif bust_node_old is VideoStreamPlayer:
		bust_node_new.stream = bust_node_old.stream
		bust_node_new.stream_position = bust_node_old.stream_position
		bust_node_new.loop = bust_node_old.loop
		bust_node_new.paused = bust_node_old.paused

	elif bust_node_old is TextureRect or bust_node_old is NinePatchRect:
		#% Stop timer on old node:
		var old_timer := bust_node_old.get_node_or_null("SpriteAnimTimer")
		if old_timer:
			old_timer.stop()
			old_timer.queue_free()

		#% Copy current texture:
		bust_node_new.texture = bust_node_old.texture

		#% If it was a folder animation, restart it on the new node from current frame:
		var actor_data = bust_node_data.get(actor, {})
		if actor_data.has("frames") and actor_data.has("frame_state"):
			var frames = actor_data["frames"]
			var frame_state = actor_data["frame_state"]
			var anim_fps = actor_data.get("anim_fps", image_fps)
			var loop = actor_data.get("loop_target", -1)

			var new_timer = Timer.new()
			new_timer.name = "SpriteAnimTimer"
			new_timer.wait_time = 1.0 / anim_fps
			new_timer.autostart = true
			bust_node_new.add_child(new_timer)

			var _animate := func():
				while true:
					await new_timer.timeout
					frame_state["index"] += 1
					if frame_state["index"] >= frames.size():
						frame_state["index"] = 0
						actor_data["loops_played"] += 1
						actor_data["elapsed_time"] = actor_data["loops_played"] * actor_data["duration"]
						if loop == -1:
							pass
						elif loop > 0 and actor_data["loops_played"] >= loop:
							new_timer.stop()
							new_timer.queue_free()
							return
					bust_node_new.texture = frames[frame_state["index"]]
			_animate.call_deferred()

	elif bust_node_old is TextureButton:
		bust_node_new.texture_normal = bust_node_old.texture_normal
		bust_node_new.texture_pressed = bust_node_old.texture_pressed
		bust_node_new.texture_hover = bust_node_old.texture_hover
		bust_node_new.texture_disabled = bust_node_old.texture_disabled
		bust_node_new.texture_focused = bust_node_old.texture_focused
		bust_node_new.texture_click_mask = bust_node_old.texture_click_mask

	await _on_play_jml("Move_From", actor, bust_node_new, bust_node_old)
	clear_old_bust_nodes(bust_node_old)
	bust_node_new.visible = true
	await _on_play_jml("Move_To", actor, bust_node_new, bust_node_old)

	#@ Continue playback if it was active:
	if not data.get("paused", false):
		if bust_node_new is AnimatedSprite2D or bust_node_new is AnimatedSprite3D:
			var anim_name = data.get("current_anim", "")
			if anim_name != "" and bust_node_new.sprite_frames and bust_node_new.sprite_frames.has_animation(anim_name):
				bust_node_new.play(anim_name)
			else:
				bust_node_new.play()
		elif bust_node_new is VideoStreamPlayer:
			bust_node_new.play()


#* Clear old bust node depending on node type:
func clear_old_bust_nodes(bust_node_old: Node) -> void:
	#@ Step 1 - Clear visuals:
	if bust_node_old is TextureRect or bust_node_old is NinePatchRect:
		bust_node_old.texture = null
		bust_node_old.visible = false

	elif bust_node_old is TextureButton:
		bust_node_old.texture_normal = null
		bust_node_old.texture_pressed = null
		bust_node_old.texture_hover = null
		bust_node_old.texture_disabled = null
		bust_node_old.texture_focused = null
		bust_node_old.texture_click_mask = null
		bust_node_old.visible = false

	elif bust_node_old is Sprite2D or bust_node_old is Sprite3D:
		bust_node_old.texture = null
		bust_node_old.hframes = 1
		bust_node_old.vframes = 1
		bust_node_old.frame = 0
		bust_node_old.visible = false
		bust_node_old.scale = Vector2(1, 1)

	elif bust_node_old is AnimatedSprite2D or bust_node_old is AnimatedSprite3D:
		bust_node_old.sprite_frames = null
		bust_node_old.frame = 0
		bust_node_old.visible = false

	elif bust_node_old is VideoStreamPlayer:
		bust_node_old.stream = null
		bust_node_old.stream_position = 0.0
		bust_node_old.visible = false

	#@ Step 2 - Reset flips (only valid for 2D visuals):
	if "flip_h" in bust_node_old:
		bust_node_old.flip_h = false
		bust_node_old.flip_v = false


#* Stop bust animations for one or more actors:
func stop_bust_animation(actors: Array, default: int) -> void:
	#@ Step 1 - Resolve which actors to process:
	var actors_to_stop: Array = []

	if actors.is_empty():
		actors_to_stop = caller.bust_positions.keys()
	else:
		for actor in actors:
			if caller.bust_positions.has(actor):
				actors_to_stop.append(actor)

	#% Nothing to clear
	if actors_to_stop.is_empty():
		return

	#@ Step 2 - Process each actor:
	for actor in actors_to_stop:
		if not caller.bust_positions.has(actor):
			continue

		var bust_ref = caller.bust_positions[actor]["pos"]
		var bust_node = busts_container.get_node_or_null(bust_ref)
		if bust_node == null:
			printerr("stop_bust_animation: Bust node not found: ", bust_ref)
			continue

		#% Stop timers if any:
		var timer := bust_node.get_node_or_null("SpriteAnimTimer")
		if timer:
			timer.stop()
			timer.queue_free()

		#@ Step 3 - Handle each node type:
		if bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
			#% Pause current animation:
			bust_node.stop()
			if default == 1:
				bust_node.frame = 0    #/ rewind to first frame
			bust_node.visible = true

		elif bust_node is Sprite2D or bust_node is Sprite3D:
			#% Pause frame sheet animation:
			if default == 1:
				bust_node.frame = 0
			bust_node.visible = true

		elif bust_node is VideoStreamPlayer:
			bust_node.stop()
			if default == 1:
				bust_node.stream_position = 0.0
			bust_node.visible = true

		elif bust_node is TextureRect or bust_node is NinePatchRect or bust_node is TextureButton:
			if default == 1 and bust_node_data.has(actor) and bust_node_data[actor].has("first_frame"):
				bust_node.texture = bust_node_data[actor]["first_frame"]
			bust_node.visible = true

		else:
			printerr("stop_bust_animation: Unsupported bust type: ", bust_node)

		#@ Step 4 - Mark as paused in tracking data:
		if bust_node_data.has(actor):
			var data = bust_node_data[actor]
			data["paused"] = true
			if  default == 1:
				data["elapsed_time"] = 0.0
				data["loops_played"] = 0
			if default == 0:
				data.get("elapsed_time", 0.0)
				data.get("loops_played", 0)

		#@ Step 5 - Remove from active animation tracking (optional):
		for i in range(caller.active_bust_animations.size() - 1, -1, -1):
			var anim_data = caller.active_bust_animations[i]
			if anim_data.has("actor") and anim_data["actor"] == actor:
				caller.active_bust_animations.remove_at(i)


#* Clear one or more bust nodes completely (remove all visuals/streams):
func clear_bust_nodes(actors: Array) -> void:
	#@ Step 1 - Resolve which actors to clear:
	var actors_to_clear: Array = []

	if actors.is_empty():
		actors_to_clear = caller.bust_positions.keys()
	else:
		for actor in actors:
			if caller.bust_positions.has(actor):
				actors_to_clear.append(actor)

	#% Nothing to clear
	if actors_to_clear.is_empty():
		return

	#@ Step 2 - Process each actor:
	for actor in actors_to_clear:
		if not caller.bust_positions.has(actor):
			continue

		var bust_ref = caller.bust_positions[actor]["pos"]
		var bust_node = busts_container.get_node_or_null(bust_ref)
		if bust_node == null:
			printerr("clear_bust_nodes: Bust node not found: ", bust_ref)
			continue

		#% Stop any timer or animation:
		var timer := bust_node.get_node_or_null("SpriteAnimTimer")
		if timer:
			timer.stop()
			timer.queue_free()

		if bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
			bust_node.stop()
		elif bust_node is VideoStreamPlayer:
			bust_node.stop()

		#% Play JML before node is cleared
		await _on_play_jml("Leave", actor, null, bust_node)

		#@ Step 3 - Clear visuals per node type:
		if bust_node is TextureRect or bust_node is NinePatchRect:
			bust_node.texture = null
			bust_node.visible = false

		elif bust_node is TextureButton:
			bust_node.texture_normal = null
			bust_node.texture_pressed = null
			bust_node.texture_hover = null
			bust_node.texture_disabled = null
			bust_node.texture_focused = null
			bust_node.texture_click_mask = null
			bust_node.visible = false

		elif bust_node is Sprite2D or bust_node is Sprite3D:
			bust_node.texture = null
			bust_node.hframes = 1
			bust_node.vframes = 1
			bust_node.frame = 0
			bust_node.visible = false
			bust_node.scale = Vector2(1, 1)

		elif bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
			bust_node.sprite_frames = null
			bust_node.frame = 0
			bust_node.visible = false

		elif bust_node is VideoStreamPlayer:
			bust_node.stream = null
			bust_node.stream_position = 0.0
			bust_node.visible = false

		else:
			printerr("clear_bust_nodes: Unsupported bust node type: ", bust_node)

		#@ Step 4 - Remove actor’s data from bust_node_data:
		if bust_node_data.has(actor):
			bust_node_data.erase(actor)

		#@ Step 5 - Reset flips (only valid for 2D visuals):
		if "flip_h" in bust_node:
			bust_node.flip_h = false
			bust_node.flip_v = false

		#@ Step 6 - Remove from active animations list:
		for i in range(caller.active_bust_animations.size() - 1, -1, -1):
			var anim_data = caller.active_bust_animations[i]
			if anim_data.has("actor") and anim_data["actor"] == actor:
				caller.active_bust_animations.remove_at(i)


#* Flip_H or Flip_V on a bust:
func mirror_bust(bust_ref, axis):
	#@ Step 1 - Find the correct bust node:
	var bust_node = busts_container.get_node_or_null(bust_ref)
	if bust_node == null:
		printerr("Bust node not found: ", bust_ref)
		return

	print(bust_ref, axis)
	#@ Step 2 - Flip axis based on node type:
	if (axis.to_lower() == "h flip" or axis.to_lower() == "both") and "flip_h" in bust_node:
		bust_node.flip_h = not bust_node.flip_h
	if (axis.to_lower() == "v flip" or axis.to_lower() == "both") and "flip_v" in bust_node:
		bust_node.flip_v = not bust_node.flip_v
	if axis.to_lower() == "reset" and "flip_h" in bust_node:	#/ Nodes always have both flip_h and flip_v
		bust_node.flip_h = false
		bust_node.flip_v = false

	if not "flip_h" in bust_node:
		printerr("Unsupported bust node type: ", bust_node)


#* Play JML effects:
func _on_play_jml(event: String, actor: String, bust_node_new: Node, bust_node_old: Node) -> void:
	var jml_method = ""
	var jml_value = ""

	#@ Get actor's JML data:
	match event:
		"Join":
			if candy_de.actors.has(actor) and candy_de.actors[actor].has("VNJoinEffect"):
				jml_method = candy_de.actors[actor]["VNJoin Effect"][0]
				jml_value = candy_de.actors[actor]["VNJoinEffect"][1]
			if jml_method == "":
				jml_method = vn_join_effect[0]
				jml_value = vn_join_effect[1]
			if jml_method == "":
				jml_method = caller.vn_join_effect[0]
				jml_value = caller.vn_join_effect[1]

		"Move_From":
			if candy_de.actors.has(actor) and candy_de.actors[actor].has("VNMoveFromEffect"):
				jml_method = candy_de.actors[actor]["VNMoveFromEffect"][0]
				jml_value = candy_de.actors[actor]["VNMoveFromEffect"][1]
			if jml_method == "":
				jml_method = vn_move_from_effect[0]
				jml_value = vn_move_from_effect[1]
			if jml_method == "":
				jml_method = caller.vn_move_from_effect[0]
				jml_value = caller.vn_move_from_effect[1]

		"Move_To":
			if candy_de.actors.has(actor) and candy_de.actors[actor].has("VNMoveToEffect"):
				jml_method = candy_de.actors[actor]["VNMoveToEffect"][0]
				jml_value = candy_de.actors[actor]["VNMoveToEffect"][1]
			if jml_method == "":
				jml_method = vn_move_to_effect[0]
				jml_value = vn_move_to_effect[1]
			if jml_method == "":
				jml_method = caller.vn_move_to_effect[0]
				jml_value = caller.vn_move_to_effect[1]

		"Leave":
			if candy_de.actors.has(actor) and candy_de.actors[actor].has("VNLeaveEffect"):
				jml_method = candy_de.actors[actor]["VNLeaveEffect"][0]
				jml_value = candy_de.actors[actor]["VNLeaveEffect"][1]
			if jml_method == "":
				jml_method = vn_leave_effect[0]
				jml_value = vn_leave_effect[1]
			if jml_method == "":
				jml_method = caller.vn_leave_effect[0]
				jml_value = caller.vn_leave_effect[1]

	if jml_method == "":
		return

	#@ Use correct logic for the method:
	match jml_method:
		#TODO: Add your own custom methods if desired.
		#% Play an animation with the JML AnimationPlayer:
		"Animation":
			match event:
				"Join", "Move_To":
					var jml_player = bust_node_new.get_node("JML")
					jml_player.play(jml_value)
					await jml_player.animation_finished

				"Move_From", "Leave":
					var jml_player = bust_node_old.get_node("JML")
					jml_player.play(jml_value)
					await jml_player.animation_finished

		#% Play a tween animation:
		"Tween":
			#TODO: Write your own custom code for tween animations.
			pass

		_:
			print("Error: unknown JML method")
			return

#* Play one or more AnimationPlayer-based effects on one or more Busts:
func play_bust_effects(actors: Array, library: String, effects: Array, loop_target: int = 0, wait_target: int = -1, time_target: float = 0.0) -> void:
	#@ Step 1 - Resolve target actors:
	var actors_to_play: Array = []

	if actors.is_empty():
		#% Prefer registered actors in bust_positions:
		if not caller.bust_positions.is_empty():
			actors_to_play = caller.bust_positions.keys()
		else:
			#% Fallback to all direct children of busts_container:
			for child in busts_container.get_children():
				if child is Node:
					actors_to_play.append(child.name)
	else:
		for actor in actors:
			if caller.bust_positions.has(actor):
				actors_to_play.append(actor)

	if actors_to_play.is_empty():
		return

	#@ Step 2 - Process each actor:
	for actor in actors_to_play:
		var bust_ref: String
		if caller.bust_positions.has(actor):
			bust_ref = caller.bust_positions[actor]["pos"]
		else:
			bust_ref = actor	#/ Fallback for nodes not tracked in bust_positions

		var bust_node = busts_container.get_node_or_null(bust_ref)
		if bust_node == null:
			printerr("play_bust_effects: Bust node not found: ", bust_ref)
			continue

		var lib_path = candy_de.busts_folder.path_join(actor).path_join("Animation_Libraries").path_join(library)
		if not lib_path.ends_with(".tres") and not lib_path.ends_with(".res"):
			lib_path = lib_path + default_effect_extension
		if not ResourceLoader.exists(lib_path):
			printerr("Missing Bust Animation Library: ", lib_path)
			continue

		var anim_lib := load(lib_path)
		if not (anim_lib is AnimationLibrary):
			printerr("Invalid Bust AnimationLibrary: ", lib_path)
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
					printerr("Effect not found in library: ", e)

		#@ Step 4 - Start all effects asynchronously:
		for effect_name in effects_to_play:
			_play_single_bust_effect(bust_node, actor, anim_lib, library, effect_name, loop_target, wait_target, time_target)


#* Internal helper: play one animation effect asynchronously:
func _play_single_bust_effect(bust_node: Node, actor: String, anim_lib: AnimationLibrary, library: String, effect_name: String, loop_target: int, wait_target: int, time_target: float) -> void:
	var anim: Animation = anim_lib.get_animation(effect_name)
	if anim == null:
		printerr("Bust effect animation is null: ", effect_name)
		return

	#@ Step 1 - Find or create AnimationPlayer:
	var player: AnimationPlayer = null
	for child in bust_node.get_children():
		if child is AnimationPlayer:
			#% Skip reserved JML player:
			if child.name == jml_player_name:
				continue
			#% Use a free player:
			if not child.is_playing():
				player = child
				break

	#% If no free player found, create one:
	if player == null:
		player = AnimationPlayer.new()
		player.root_node = ".."
		bust_node.add_child(player)

	#@ Step 2 - Register animation library:
	if not player.has_animation_library(library):
		#% Remove default empty library if present to avoid conflicts:
		if player.has_animation_library(""):
			player.remove_animation_library("")
		player.add_animation_library(library, anim_lib)

	#@ Step 3 - Prepare runtime data:
	if not bust_node_data.has(actor):
		bust_node_data[actor] = {}
	var actor_data = bust_node_data[actor]
	if not actor_data.has("effects"):
		actor_data["effects"] = {}

	actor_data["effects"][effect_name] = {
		"loop_target": loop_target,
		"loops_played": 0,
		"wait_target": wait_target,
		"time_target": time_target,
		"duration": anim.length,
		"elapsed_time": 0.0,
		"player": player,
	}
	var effect_data = actor_data["effects"][effect_name]
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


#* Stop one or more AnimationPlayer-based effects on one or more Busts:
func stop_bust_effects(actors: Array, effects: Array) -> void:
	#@ Step 1 - Resolve which actors to process:
	var actors_to_stop: Array = []

	if actors.is_empty():
		#% Prefer actors tracked in bust_positions:
		if not caller.bust_positions.is_empty():
			actors_to_stop = caller.bust_positions.keys()
		else:
			#% Fallback to all direct bust nodes:
			for child in busts_container.get_children():
				if child is Node:
					actors_to_stop.append(child.name)
	else:
		for actor in actors:
			if caller.bust_positions.has(actor):
				actors_to_stop.append(actor)

	if actors_to_stop.is_empty():
		return

	#@ Step 2 - Process each actor individually:
	for actor in actors_to_stop:
		var bust_ref: String
		if caller.bust_positions.has(actor):
			bust_ref = caller.bust_positions[actor]["pos"]
		else:
			bust_ref = actor   #/ fallback for nodes not registered in bust_positions

		var bust_node = busts_container.get_node_or_null(bust_ref)
		if bust_node == null:
			printerr("stop_bust_effects: Bust node not found: ", bust_ref)
			continue

		#@ Step 3 - Stop effects on all AnimationPlayers:
		for child in bust_node.get_children():
			if not (child is AnimationPlayer):
				continue

			#% Skip reserved JML player:
			if child.name == jml_player_name:
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
		if bust_node_data.has(actor) and bust_node_data[actor].has("effects"):
			var eff_dict = bust_node_data[actor]["effects"]
			if effects.is_empty():
				eff_dict.clear()
			else:
				for e in effects:
					eff_dict.erase(e)


#* Scale Sprite2D or Sprite3D busts to match target dimensions:
func _scale_bust_to_size(bust_node: Node, bust_ref: String) -> void:
	if not bust_sizes.has(bust_ref):
		return

	var target_size: Array = bust_sizes[bust_ref]
	if target_size.size() < 2:
		return

	var target_h = float(target_size[0])
	var target_w = float(target_size[1])

	#% Determine texture size:
	if bust_node is Sprite2D or bust_node is Sprite3D:
		var tex: Texture2D = bust_node.texture
		if tex == null:
			return
		var tex_size = tex.get_size()
		if tex_size.x == 0 or tex_size.y == 0:
			return

		#@ Calculate scale ratio:
		var scale_x = target_w / tex_size.x
		var scale_y = target_h / tex_size.y
		bust_node.scale = Vector2(scale_x, scale_y)
