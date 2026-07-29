#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends RefCounted
class_name CandyMedia


#^ Extensions Image.load() can parse at runtime:
#+ Add formats you ship in user://.
const RAW_IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "bmp", "tga", "webp", "svg", "ktx"]

#^ Extensions load_audio() can parse at runtime:
const RAW_AUDIO_EXTENSIONS := ["ogg", "oga", "mp3", "wav"]

#^ Extensions load_video() can parse at runtime:
const RAW_VIDEO_EXTENSIONS := ["ogv"]

#^ Files that are never animation frames:
const FRAME_SKIP_EXTENSIONS := ["import", "txt", "md5", "cfg"]

#^ Media folder settings file (read_folder_config()):
const FOLDER_CONFIG := "config.txt"
#^ config.txt keys, top level and per Files entry:
const FOLDER_CONFIG_KEYS := ["extension", "fps", "cache", "stream"]
const FOLDER_CONFIG_FILE_KEYS := ["fps", "cache", "stream"]

#^ Parsed config.txt files, by path:
#? {"text": file text, "config": parsed result}. Reparsed when the text changes.
static var _folder_configs: Dictionary = {}



#?##############################
#& PATH HELPERS:
#?##############
#region - Path Helpers
#* Whether text is a res:// or user:// path:
static func is_resource_path(text: String) -> bool:
	return text.begins_with("res://") or text.begins_with("user://")


#* Whether a path is a user:// file:
static func is_runtime_path(text: String) -> bool:
	return text.begins_with("user://")


#* Media value as a path:
#! A runtime Resource gives "": check for in-memory streams first.
static func to_path(value: Variant) -> String:
	#? 'is' errors on a freed instance.
	if typeof(value) == TYPE_OBJECT and is_instance_valid(value) and value is Resource:
		return str(value.resource_path).strip_edges()
	if typeof(value) == TYPE_STRING:
		return value.strip_edges()
	return str(value).strip_edges()


#* Whether a media file exists:
static func exists(path: String) -> bool:
	if path == "":
		return false
	if ResourceLoader.exists(path):
		return true
	#% FileAccess only for user:// (res:// source files aren't exported):
	if is_runtime_path(path):
		return FileAccess.file_exists(path)
	return false


#* Resolve a media reference into a path:
static func resolve_path(ref: String, folder: String, default_ext: String) -> String:
	var file_name := ref.strip_edges()

	#¦ 1. Absolute path:
	#% Never extend a frame folder:
	if is_resource_path(file_name):
		if file_name.get_extension() == "" and not DirAccess.dir_exists_absolute(file_name):
			file_name += extension_in(file_name.get_base_dir(), default_ext)
		return file_name

	#¦ 2. Relative name:
	if file_name == "":
		file_name = "Default"

	var joined := folder.path_join(file_name)
	if file_name.get_extension() == "" and not DirAccess.dir_exists_absolute(joined):
		joined += extension_in(joined.get_base_dir(), default_ext)
	return joined

#* Extension for a name without one in 'folder':
static func extension_in(folder: String, default_ext: String) -> String:
	var folder_ext := folder_extension(folder)
	if folder_ext != "":
		return folder_ext
	return default_ext


#* Resolve a media reference for a player or UI element:
#!  Never prints: on found == false, the caller reports and aborts.
static func resolve_media(ref: Variant, folder: String, default_ext: String,
		frames_subfolder: String = "", allow_default_fallback: bool = true) -> Dictionary:

	var result := {"resource": null, "path": "", "is_folder": false, "found": false}

	#@ Step 1 - A Resource is used as is:
	#? A runtime Resource has no path to resolve.
	if typeof(ref) == TYPE_OBJECT and is_instance_valid(ref) and ref is Resource:
		result["resource"] = ref
		result["path"] = str(ref.resource_path).strip_edges()
		result["found"] = true
		return result

	#@ Step 2 - Reduce to a name:
	var file_name := to_path(ref)
	if file_name == "":
		file_name = "Default"

	#@ Step 3 - Absolute path, no Default fallback:
	if is_resource_path(file_name):
		if DirAccess.dir_exists_absolute(file_name):
			result["path"] = file_name
			result["is_folder"] = true
			result["found"] = true
			return result

		if file_name.get_extension() == "":
			file_name += extension_in(file_name.get_base_dir(), default_ext)

		result["path"] = file_name
		result["found"] = exists(file_name)
		return result

	#@ Step 4 - Frame folder:
	#? In "Animated/<name>" or "<name>".
	for candidate in [folder.path_join("Animated").path_join(file_name), folder.path_join(file_name)]:
		if DirAccess.dir_exists_absolute(candidate):
			result["path"] = candidate
			result["is_folder"] = true
			result["found"] = true
			return result

	#@ Step 5 - File in the folder:
	#? 'frames_subfolder': e.g. "Sprite_Frames" for AnimatedSprite2D/3D.
	var base_folder := folder
	if frames_subfolder != "":
		base_folder = folder.path_join(frames_subfolder)

	var named := file_name
	if named.get_extension() == "":
		named += extension_in(base_folder.path_join(file_name).get_base_dir(), default_ext)

	var file_path := base_folder.path_join(named)
	if exists(file_path):
		result["path"] = file_path
		result["found"] = true
		return result

	#@ Step 6 - "Default" fallback, requested extension then default:
	if allow_default_fallback:
		for fallback in ["Default." + named.get_extension(), "Default" + extension_in(base_folder, default_ext)]:
			var fallback_path := base_folder.path_join(fallback)
			if exists(fallback_path):
				result["path"] = fallback_path
				result["found"] = true
				return result

	#% Not found - return the path tried:
	result["path"] = file_path
	return result


#* A frame folder's own config.txt fps, or -1.0:
static func read_config_fps(folder: String) -> float:
	var config_fps = read_folder_config(folder).get("fps")
	if config_fps == null:
		return -1.0
	return float(config_fps)

#* A media folder's config.txt settings:
#! Not an imported resource: only exported if the export filters include it.
static func read_folder_config(folder: String) -> Dictionary:
	var empty := {"files": {}}
	if folder == "":
		return empty
	var config_path := folder.path_join(FOLDER_CONFIG)
	if not FileAccess.file_exists(config_path):
		return empty

	#% Cached and unchanged:
	#? By text: modified time only counts whole seconds.
	var text := FileAccess.get_file_as_string(config_path)
	var cached = _folder_configs.get(config_path)
	if cached is Dictionary and str(cached["text"]) == text:
		return cached["config"]

	var config := _parse_folder_config(text, config_path)
	_folder_configs[config_path] = {"text": text, "config": config}
	return config

#* config.txt extension of 'folder', or "":
static func folder_extension(folder: String) -> String:
	return str(read_folder_config(folder).get("extension", ""))

#* config.txt setting for 'path', or null:
static func file_config_value(path: String, key: String) -> Variant:
	var target := path.trim_suffix("/")
	if target == "" or not is_resource_path(target):
		return null
	var config := read_folder_config(target.get_base_dir())
	#Ł Its "Files" entry first, then the folder's:
	var entry = config["files"].get(target.get_file())
	if entry is Dictionary and entry.has(key):
		return entry[key]
	return config.get(key)

#* config.txt fps for 'path', or -1.0:
static func file_config_fps(path: String) -> float:
	var value = file_config_value(path, "fps")
	if value == null:
		return -1.0
	return float(value)

#* Parse a config.txt:
static func _parse_folder_config(text: String, config_path: String) -> Dictionary:
	var config := {"files": {}}
	var in_files := false
	var entry_regex := RegEx.create_from_string("^(.+?)\\s*:\\s*\\{(.*)\\}$")
	var files_regex := RegEx.create_from_string("(?i)^files\\s*:\\s*\\{\\s*(\\}?)$")
	var line_number := 0

	for raw_line in text.split("\n"):
		line_number += 1
		var line := raw_line.strip_edges()
		if line == "" or line.begins_with("#"):
			continue

		#¦ 1. Files entry:
		#? e.g. sprite_sheet_4x2-1.png: {fps = 8}, by file or frame folder name.
		if in_files:
			if line == "}":
				in_files = false
				continue
			var entry := entry_regex.search(line)
			if entry == null:
				_config_error(config_path, line_number, "expected '<file name>: {setting = value, ...}' or '}' → " + line)
				continue
			var settings := {}
			for pair in entry.get_string(2).split(",", false):
				_read_config_pair(settings, pair, FOLDER_CONFIG_FILE_KEYS, config_path, line_number)
			config["files"][_unquote(entry.get_string(1))] = settings
			continue

		#¦ 2. "Files: {":
		var files := files_regex.search(line)
		if files != null:
			in_files = files.get_string(1) == ""
			continue

		#¦ 3. "key = value":
		_read_config_pair(config, line, FOLDER_CONFIG_KEYS, config_path, line_number)

	if in_files:
		_config_error(config_path, line_number, "'Files: {' is never closed with '}'.")
	return config

#* Read one "key = value" into 'settings':
static func _read_config_pair(settings: Dictionary, pair: String, keys: Array, config_path: String, line_number: int) -> void:
	var equals := pair.find("=")
	if equals < 0:
		_config_error(config_path, line_number, "expected 'key = value' → " + pair.strip_edges())
		return
	var key := pair.substr(0, equals).strip_edges().to_lower()
	var value := _unquote(pair.substr(equals + 1))
	if not (key in keys):
		_config_error(config_path, line_number, "unknown setting '" + key + "' (accepted: " + ", ".join(keys) + ").")
		return

	match key:
		"extension":
			if value != "" and not value.begins_with("."):
				value = "." + value
			settings["extension"] = value
		"fps":
			if not value.is_valid_float() or float(value) <= 0.0:
				_config_error(config_path, line_number, "fps must be a number above 0 → " + value)
				return
			settings["fps"] = float(value)
		"cache":
			#¦ 1. Frame folders - memory budget (MB) to keep every frame:
			if not value.is_valid_float() or float(value) < 0.0:
				_config_error(config_path, line_number, "cache must be a number of MB, 0 or more → " + value)
				return
			settings["cache"] = float(value)
		"stream":
			#¦ 2. Frame folders - frames loaded ahead while streaming:
			if not value.is_valid_int() or int(value) < 1:
				_config_error(config_path, line_number, "stream must be a whole number of frames, 1 or more → " + value)
				return
			settings["stream"] = int(value)

#* Unquote a config.txt value:
static func _unquote(value: String) -> String:
	var text := value.strip_edges()
	if text.length() >= 2 and ((text.begins_with("\"") and text.ends_with("\"")) or (text.begins_with("'") and text.ends_with("'"))):
		text = text.substr(1, text.length() - 2).strip_edges()
	return text

#* Report a bad config.txt line:
static func _config_error(config_path: String, line_number: int, message: String) -> void:
	printerr(config_path, ", line ", line_number, ": ", message)

#endregion - Path Helpers


#?##############################
#& MEDIA LOADERS:
#?###############
#region - Media Loaders
#* Load a texture, or null:
static func load_texture(path: String) -> Texture2D:
	if path == "":
		return null

	#¦ 1. Runtime files (user://):
	if is_runtime_path(path):
		#¦ 1. Saved resource:
		if ResourceLoader.exists(path):
			var saved := ResourceLoader.load(path)
			if saved is Texture2D:
				return saved

		#¦ 2. Raw image:
		if not FileAccess.file_exists(path):
			return null

		var ext := path.get_extension().to_lower()
		if not (ext in RAW_IMAGE_EXTENSIONS):
			printerr("CandyMedia.load_texture(): unsupported format (%s) → %s" % [ext, path])
			return null

		var img := Image.new()
		if img.load(path) != OK:
			printerr("CandyMedia.load_texture(): file could not be read as an image → ", path)
			return null

		return ImageTexture.create_from_image(img)

	#¦ 2. Project files (res://):
	#! Never Image.load(): the source isn't exported.
	if not ResourceLoader.exists(path):
		return null

	var resource := ResourceLoader.load(path)
	if resource is Texture2D:
		return resource

	printerr("CandyMedia.load_texture(): file is not a valid texture → ", path)
	return null


#* Load an audio stream, or null:
static func load_audio(path: String) -> AudioStream:
	if path == "":
		return null

	#¦ 1. Runtime files (user://):
	if is_runtime_path(path):
		#¦ 1. Saved resource:
		if ResourceLoader.exists(path):
			var saved := ResourceLoader.load(path)
			if saved is AudioStream:
				return saved

		#¦ 2. Raw audio:
		if not FileAccess.file_exists(path):
			return null

		var runtime_stream: AudioStream = null
		#+ Add formats here:
		match path.get_extension().to_lower():
			"ogg", "oga":
				runtime_stream = AudioStreamOggVorbis.load_from_file(path)
			"mp3":
				runtime_stream = AudioStreamMP3.load_from_file(path)
			"wav":
				runtime_stream = AudioStreamWAV.load_from_file(path)
			_:
				printerr("CandyMedia.load_audio(): unsupported format (use .ogg, .mp3 or .wav) → ", path)
				return null

		if runtime_stream == null:
			printerr("CandyMedia.load_audio(): file could not be read as audio → ", path)
		return runtime_stream

	#¦ 2. Project files (res://):
	if not ResourceLoader.exists(path):
		return null

	var resource := ResourceLoader.load(path)
	if resource is AudioStream:
		return resource

	printerr("CandyMedia.load_audio(): file is not a valid stream → ", path)
	return null


#* Load a video stream, or null:
static func load_video(path: String) -> VideoStream:
	if path == "":
		return null

	#% ResourceLoader reads user:// .ogv too:
	if ResourceLoader.exists(path):
		var resource := ResourceLoader.load(path)
		if resource is VideoStream:
			return resource

	#% Runtime files (user://):
	#? Files ResourceLoader declines.
	if is_runtime_path(path):
		if not FileAccess.file_exists(path):
			return null

		var ext := path.get_extension().to_lower()
		if not (ext in RAW_VIDEO_EXTENSIONS):
			printerr("CandyMedia.load_video(): unsupported format (use .ogv) → ", path)
			return null

		var runtime_stream := VideoStreamTheora.new()
		runtime_stream.file = path
		return runtime_stream

	return null


#* Load a SpriteFrames, or null:
#! One referencing raw user:// images loads empty: use build_sprite_frames().
static func load_sprite_frames(path: String) -> SpriteFrames:
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		return null

	var resource := ResourceLoader.load(path)
	if resource is SpriteFrames:
		return resource

	printerr("CandyMedia.load_sprite_frames(): file is not a valid SpriteFrames → ", path)
	return null


#* Load an AnimationLibrary, or null:
static func load_animation_library(path: String) -> AnimationLibrary:
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		return null

	var resource := ResourceLoader.load(path)
	if resource is AnimationLibrary:
		return resource

	printerr("CandyMedia.load_animation_library(): file is not a valid AnimationLibrary → ", path)
	return null


#* Load a BitMap (click masks), or build one from a raw image:
static func load_bitmap(path: String) -> BitMap:
	if path == "":
		return null

	if ResourceLoader.exists(path):
		var resource := ResourceLoader.load(path)
		if resource is BitMap:
			return resource

	#% Runtime files (user://) - from the image's alpha:
	if is_runtime_path(path) and FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) != OK:
			return null
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(img)
		return bitmap

	return null


#* Playable frame count of a spritesheet:
static func sheet_frame_count(sprite_node: Node) -> int:
	if not ("hframes" in sprite_node and "vframes" in sprite_node):
		return 0

	var grid_total: int = max(int(sprite_node.hframes) * int(sprite_node.vframes), 1)

	var tex: Texture2D = sprite_node.texture
	if tex == null or tex.resource_path == "":
		return grid_total	#/ No path: full grid

	#Ł "<name>_<H>x<V>[-<empty>].<ext>" ("Fire_4x3-2.png" = 10 playable frames):
	var regex := RegEx.new()
	regex.compile("(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")
	var result := regex.search(tex.resource_path.get_file())
	if result == null or result.get_string(3) == "":
		return grid_total

	return clamp(grid_total - int(result.get_string(3)), 1, grid_total)

#endregion - Media Loaders


#?##############################
#& FOLDER ANIMATIONS:
#?###################
#region - Folder Animations
#* Frame number at the end of a name, or -1:
static func trailing_number(text: String) -> int:
	var digits := ""
	for i in range(text.length() - 1, -1, -1):
		if text[i] >= "0" and text[i] <= "9":
			digits = text[i] + digits
		else:
			break

	if digits != "":
		return int(digits)
	else:
		return -1


#* Sort frame names by number, else natural order:
static func frame_name_sort(a: String, b: String) -> bool:
	var na := trailing_number(a.get_basename())
	var nb := trailing_number(b.get_basename())
	if na >= 0 and nb >= 0 and na != nb:
		return na < nb
	return a.naturalcasecmp_to(b) < 0


#* List loadable file names in a folder (export-safe):
static func list_files(folder: String) -> Array[String]:
	var names: Array[String] = []

	if not DirAccess.dir_exists_absolute(folder):
		return names

	#? DirAccess, not ResourceLoader.list_directory() (Godot 4.4+).
	var dir := DirAccess.open(folder)
	if dir == null:
		printerr("CandyMedia.list_files(): could not open folder → ", folder)
		return names

	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir():
			#Ł Strip .import / .remap (exports only have those):
			if file.ends_with(".import"):
				file = file.trim_suffix(".import")
			elif file.ends_with(".remap"):
				file = file.trim_suffix(".remap")

			if file != "" and not (file in names):
				names.append(file)
		file = dir.get_next()
	dir.list_dir_end()

	return names


#* List a frame folder's file names, in playback order:
static func list_frame_files(folder: String) -> Array[String]:
	var names: Array[String] = []

	for file in list_files(folder):
		if not (file.get_extension().to_lower() in FRAME_SKIP_EXTENSIONS):
			names.append(file)

	#Ł By name (user:// textures have no resource_path):
	names.sort_custom(frame_name_sort)
	return names


#* Load a frame folder's frames, in order:
static func load_frames(folder: String) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []

	for file_name in list_frame_files(folder):
		var tex := load_texture(folder.path_join(file_name))
		if tex != null:
			frames.append(tex)

	return frames


#* Build a SpriteFrames from a frame folder:
#? For user:// frames, which a saved .tres can't reference.
static func build_sprite_frames(folder: String, animation: String = "default", fps: float = 10.0, loop: bool = true) -> SpriteFrames:
	var frames := load_frames(folder)
	if frames.is_empty():
		return null

	var sprite_frames := SpriteFrames.new()
	if not sprite_frames.has_animation(animation):
		sprite_frames.add_animation(animation)
	sprite_frames.set_animation_speed(animation, max(fps, 0.001))
	sprite_frames.set_animation_loop(animation, loop)

	for tex in frames:
		sprite_frames.add_frame(animation, tex)

	return sprite_frames

#endregion - Folder Animations
