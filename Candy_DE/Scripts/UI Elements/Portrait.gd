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

@onready var portrait_node = get_node("Image")		#/ Required

@onready var portrait_bg = get_node("BG")			#/ Optional
@onready var portrait_fg = get_node("FG")			#/ Optional
@onready var portrait_effect_player = get_node("PortraitEffectPlayer")	#/ Optional

@export var default_image_extension = ".png"				#/ TextureRect, NinePatchRect, TextureButton
@export var default_sprite_extension = ".png"				#/ Sprite2D, Sprite3D
@export var default_animated_sprite_extension = ".tres"		#/ AnimatedSprite2D, AnimatedSprite3D
@export var default_video_extension = ".ogv"				#/ VideoStreamPlayer

@export var sprite_fps = 8.0
@export var portrait_h = 256
@export var portrait_w = 256

@export var default_z = 100

var caller: Node


func _ready():
	self.z_index = default_z


#* Receive and display a portrait based on node type and portrait data:
func receive_portrait(character_ref: String, portrait_raw: String, play_portrait: String) -> void:
	self.visible = true

	#@ Step 1 - Reset all portrait modes:
	no_portrait()
	self.visible = true

	#@ Step 2 - Determine what portrait_raw represents:
	var portrait_file := ""
	var resolved := portrait_raw

	#@ Step 3 - Handle variable-style references (£, $, €, etc.):
	if typeof(portrait_raw) == TYPE_STRING and (portrait_raw.begins_with(candy_de.vardict_symbol)
	or portrait_raw.begins_with(candy_de.node_symbol)
	or portrait_raw.begins_with(candy_de.singleton_symbol)
	or portrait_raw.begins_with(candy_de.role_symbol)):
		var decoded = caller.decode_variable_name(portrait_raw)
		var resolved_var = caller.get_variable_value(decoded)
		if resolved_var != null:
			resolved = str(resolved_var).strip_edges()

	#@ Step 4 - If node is AnimatedSprite, load SpriteFrames resource instead of file:
	if portrait_node is AnimatedSprite2D or portrait_node is AnimatedSprite3D:
		var character_frames := ""
		var animation := ""
		#% Character sheet path (each character has one sheet resource)
		character_frames = candy_de.portraits_folder.path_join(character_ref).path_join("Sprite Frames").path_join(character_ref).path_join(".tres")
		animation = resolved
		if ResourceLoader.exists(character_frames):
			animatedsprite_portrait(character_frames, animation, play_portrait)
		else:
			printerr("Missing SpriteFrames sheet for character: ", character_ref)
		return

	#@ Step 5 - For other portrait types, determine file path:
	var default_ext := ""
	if portrait_node is TextureRect or portrait_node is NinePatchRect or portrait_node is TextureButton:
		default_ext = default_image_extension
	elif portrait_node is Sprite2D or portrait_node is Sprite3D:
		default_ext = default_sprite_extension
	elif portrait_node is VideoStreamPlayer:
		default_ext = default_video_extension

	if typeof(resolved) == TYPE_STRING and resolved.begins_with("res://"):
		portrait_file = resolved if resolved.find(".") != -1 else resolved + default_ext
	else:
		var file_name = resolved
		if file_name == "":
			file_name = "Default"
		if file_name.find(".") == -1:
			file_name += default_ext
		portrait_file = candy_de.portraits_folder.path_join(character_ref).path_join(file_name)

	#@ Step 5b - Fallback if file doesn't exist:
	if not ResourceLoader.exists(portrait_file):
		printerr("receive_portrait: Missing file: ", portrait_file, " → trying Default with same extension")
		var ext = portrait_file.get_extension()
		var base_folder = candy_de.portraits_folder.path_join(character_ref)
		var fallback_same_ext = base_folder.path_join("Default." + ext)

		if ResourceLoader.exists(fallback_same_ext):
			portrait_file = fallback_same_ext
		else:
			printerr("receive_portrait: Missing file: ", fallback_same_ext, " → trying Default with default extension")
			var fallback_default_ext = base_folder.path_join("Default" + default_ext)

			if ResourceLoader.exists(fallback_default_ext):
				portrait_file = fallback_default_ext
			else:
				printerr("receive_portrait: Missing file: ", fallback_default_ext, " → no fallback found, aborting")
				return

	#@ Step 6 - Dispatch based on node type:
	if portrait_node is TextureRect or portrait_node is NinePatchRect:
		texturerect_portrait(portrait_file)
	elif portrait_node is TextureButton:
		texturebutton_portrait(portrait_file)
	elif portrait_node is Sprite2D or portrait_node is Sprite3D:
		sprite_portrait(portrait_file, play_portrait)
	elif portrait_node is VideoStreamPlayer:
		video_portrait(portrait_file, play_portrait)
	else:
		printerr("Unsupported portrait node type: ", portrait_node)


#* Display a portrait using an AnimatedSprite2D or AnimatedSprite3D node:
func animatedsprite_portrait(spriteframes_path: String, portrait_name: String, play_portrait: String) -> void:
	#@ Ensure the node exists and is an AnimatedSprite2D or AnimatedSprite2D:
	if portrait_node == null or not ( portrait_node is AnimatedSprite2D or portrait_node is AnimatedSprite3D):
		return

	#@ Reset node:
	portrait_node.stop()
	portrait_node.visible = false

	#@ Validate and load SpriteFrames resource:
	if not ResourceLoader.exists(spriteframes_path):
		printerr("SpriteFrames not found: ", spriteframes_path)
		return

	var frames := load(spriteframes_path)
	if not (frames is SpriteFrames):
		printerr("Invalid SpriteFrames resource: ", spriteframes_path)
		return

	#@ Apply SpriteFrames and play animation:
	portrait_node.sprite_frames = frames
	portrait_node.visible = true

	if play_portrait == "1":
		if frames.has_animation(portrait_name):
			frames.set_animation_speed(portrait_name, sprite_fps)
			portrait_node.play(portrait_name)
		else:
			printerr("Animation not found in %s: '%s'" % [spriteframes_path, portrait_name])
			if frames.has_animation("default"):
				portrait_node.play("default")


#* Display a portrait using a TextureRect or NinePatchRect node (static image):
func texturerect_portrait(portrait_file: String) -> void:
	#@ Ensure the node exists and is a TextureRect or NinePatchRect:
	if portrait_node == null or not (portrait_node is TextureRect or portrait_node is NinePatchRect):
		return

	#@ Reset and hide while loading:
	portrait_node.visible = false
	portrait_node.texture = null

	#@ Verify texture path:
	if not ResourceLoader.exists(portrait_file):
		printerr("Portrait file not found: ", portrait_file)
		return

	var tex := load(portrait_file)
	if not (tex is Texture2D):
		printerr("Invalid portrait texture: ", portrait_file)
		return

	#@ Apply texture:
	portrait_node.texture = tex
	portrait_node.visible = true

#	#@ Scale to fixed display size if defined:
#	if portrait_w > 0 and portrait_h > 0:
#		var tex_size = tex.get_size()
#		var target_size := Vector2(portrait_w, portrait_h)
#		portrait_node.scale = target_size / tex_size


#* Display a portrait using a TextureButton node:
func texturebutton_portrait(portrait_file: String) -> void:
	#@ Ensure the node exists and is a TextureButton:
	if portrait_node == null or not (portrait_node is TextureButton):
		return

	portrait_node.visible = false
	portrait_node.texture_normal = null

	if not ResourceLoader.exists(portrait_file):
		printerr("Portrait file not found: ", portrait_file)
		return

	var tex := load(portrait_file)
	if not (tex is Texture2D):
		printerr("Invalid portrait texture: ", portrait_file)
		return

	portrait_node.texture_normal = tex
	portrait_node.visible = true

	#@ Search for optional texture slot folder:
	var base_folder = portrait_file.get_base_dir()
	var file_ext = portrait_file.get_extension().to_upper()
	var file_base = portrait_file.get_file().get_basename()
	var folder_with_ext = base_folder.path_join("TB_" + file_base + "_" + file_ext)
	var folder_without_ext = base_folder.path_join("TB_" + file_base)

	var button_folder = ""
	if DirAccess.dir_exists_absolute(folder_with_ext):
		button_folder = folder_with_ext
	elif DirAccess.dir_exists_absolute(folder_with_ext.to_lower()):
		button_folder = folder_with_ext.to_lower()
	elif DirAccess.dir_exists_absolute(folder_without_ext):
		button_folder = folder_without_ext
	elif DirAccess.dir_exists_absolute(folder_without_ext.to_lower()):
		button_folder = folder_without_ext.to_lower()

	if button_folder != "":
		var texture_slots = [
			"texture_pressed",
			"texture_hover",
			"texture_disabled",
			"texture_focused",
			"texture_click_mask",
		]
		for slot in texture_slots:
			var dir = DirAccess.open(button_folder)
			if dir:
				dir.list_dir_begin()
				var fname = dir.get_next()
				while fname != "":
					if fname.get_basename().to_lower().ends_with(slot):
						var slot_tex := load(button_folder.path_join(fname))
						if slot_tex is Texture2D:
							portrait_node.set(slot, slot_tex)
						break
					fname = dir.get_next()
				dir.list_dir_end()

#	#@ Scale to fixed display size if defined:
#	if portrait_w > 0 and portrait_h > 0:
#		var tex_size = tex.get_size()
#		var target_size := Vector2(portrait_w, portrait_h)
#		portrait_node.scale = target_size / tex_size


#* Display a portrait using a Sprite2D or Sprite3D node, with automatic frame animation and scaling:
func sprite_portrait(portrait_file: String, play_portrait: String) -> void:
	#@ Ensure the node exists and is a Sprite2D or Sprite3D:
	if portrait_node == null or not (portrait_node is Sprite2D or portrait_node is Sprite3D):
		return

	#@ Reset visibility and texture:
	portrait_node.visible = false
	portrait_node.texture = null

	#@ Defaults:
	var hframes := 1
	var vframes := 1
	var missing := 0

	#@ Parse filename suffix (e.g., 4x5 or 4x5-2):
	var filename := portrait_file.get_file()
	var regex := RegEx.new()
	regex.compile("(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")
	var result := regex.search(filename)

	if result:
		hframes = int(result.get_string(1))
		vframes = int(result.get_string(2))
		if result.get_string(3) != "":
			missing = int(result.get_string(3))

	#@ Sanitize frame values:
	hframes = max(abs(hframes), 1)
	vframes = max(abs(vframes), 1)
	missing = max(abs(missing), 0)

	#@ Load texture:
	if not ResourceLoader.exists(portrait_file):
		printerr("Portrait file not found: ", portrait_file)
		return

	var tex := load(portrait_file)
	if not (tex is Texture2D):
		printerr("Invalid portrait texture: ", portrait_file)
		return

	#@ Apply texture and frame data:
	portrait_node.texture = tex
	portrait_node.hframes = hframes
	portrait_node.vframes = vframes
	portrait_node.frame = 0
	portrait_node.visible = true

	#@ Scale to fixed display size:
	if portrait_w > 0 and portrait_h > 0:
		var frame_size = tex.get_size() / Vector2(hframes, vframes)
		var target_size := Vector2(portrait_w, portrait_h)
		portrait_node.scale = target_size / frame_size

	#@ Determine total valid frames:
	var total_frames = max(hframes * vframes - missing, 1)
	portrait_node.set_meta("total_frames", total_frames)

	#@ Stop old timer if any:
	var old_timer := get_node_or_null("SpriteAnimTimer")
	if old_timer:
		old_timer.stop()
		old_timer.queue_free()

	#@ Animate if multiple frames:
	if play_portrait == "1":
		if total_frames > 1:
			var timer := Timer.new()
			timer.name = "SpriteAnimTimer"
			timer.wait_time = 1.0 / sprite_fps
			timer.one_shot = false
			timer.autostart = true
			add_child(timer)

			timer.timeout.connect(func():
				portrait_node.frame = (portrait_node.frame + 1) % total_frames
			)


#* Display a portrait using a VideoStreamPlayer node:
func video_portrait(portrait_file: String, play_portrait: String) -> void:
	#@ Ensure the node exists and is a VideoStreamPlayer:
	if portrait_node == null or not (portrait_node is VideoStreamPlayer):
		return

	#@ Reset and hide while loading:
	portrait_node.stop()
	portrait_node.visible = false

	#@ Validate file path:
	if not ResourceLoader.exists(portrait_file):
		printerr("Portrait video not found: ", portrait_file)
		return

	var stream := load(portrait_file)
	if not (stream is VideoStream):
		printerr("Invalid video stream: ", portrait_file)
		return

	#@ Apply and play:
	portrait_node.stream = stream
	portrait_node.visible = true
	portrait_node.play()
	if play_portrait == "0":
		portrait_node.pause()
		portrait_node.stream_position = 0

#	#@ Scale video to target display size if set:
#	if portrait_w > 0 and portrait_h > 0:
#		var video_size = portrait_node.get_video_texture().get_size() if portrait_node.get_video_texture() else Vector2(portrait_w, portrait_h)
#		var target_size := Vector2(portrait_w, portrait_h)
#		portrait_node.scale = target_size / video_size


#* Remove/hide portraits:
func no_portrait():
	self.visible = false

	if portrait_node is TextureRect or portrait_node is NinePatchRect:
		portrait_node.texture = null

	elif portrait_node is TextureButton:
		portrait_node.texture_normal = null
		portrait_node.texture_pressed = null
		portrait_node.texture_hover = null
		portrait_node.texture_disabled = null
		portrait_node.texture_focused = null
		portrait_node.texture_click_mask = null

	elif portrait_node is Sprite2D or portrait_node is Sprite3D:
		portrait_node.texture = null

	elif portrait_node is AnimatedSprite2D or portrait_node is AnimatedSprite3D:
		portrait_node.stop()
		portrait_node.visible = false

	elif portrait_node is VideoStreamPlayer:
		portrait_node.stop()
		portrait_node.visible = false


#* Hook function, called when writing begins:
func x_write_begun():
	pass


#* Hook function, called when writing finishes:
func x_write_finished():
	pass
