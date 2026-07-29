#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFrameStream
extends RefCounted


#^ Defaults for missing or invalid settings:
const DEFAULT_CACHE_MB := 256.0
const DEFAULT_STREAM := 8
#^ Bytes per pixel (RGBA):
const BYTES_PER_PIXEL := 4

#^ Frame file paths, in order:
var _paths: Array[String] = []
#^ Streaming (passed frames freed):
var _streaming: bool = false
#^ Frames loaded ahead / at once:
var _ahead: int = DEFAULT_STREAM
#^ Frames this stream holds, by index:
var _loaded: Dictionary = {}
#^ Frames this stream asked the shared loader for, by index:
var _requested: Dictionary = {}
#^ Background loading started:
var _started: bool = false
#^ TextureButton state folders (slot → CandyFrameStream):
var _states: Dictionary = {}
#^ TextureButton click mask, or null:
var _mask: BitMap = null


#& SHARED LOADER:
#^ Loads in progress or done, by path:
#? {"kind": "resource" | "image", "task": WorkerThreadPool task id (images), "done": bool,
#?  "texture": Texture2D or null, "wanted": how many streams want it}.
static var _loads: Dictionary = {}
#^ Images decoded by worker threads, by path:
static var _decoded: Dictionary = {}
static var _decoded_mutex: Mutex = Mutex.new()
#^ _poll_loads() running:
static var _polling: bool = false


#& OPENING:
#* Open a frame folder and load its first frame:
#? Settings: -1 inherits.
static func open(source: CandyEngine, caller: Object, folder: String, cache_setting: Variant = -1,
		stream_setting: Variant = -1, for_node: Node = null) -> CandyFrameStream:
	var stream := CandyFrameStream.new()
	for file_name in CandyMedia.list_frame_files(folder):
		stream._paths.append(folder.path_join(file_name))
	if stream._paths.is_empty():
		return stream

	stream._ahead = resolve_stream(source, caller, stream_setting, folder)

	#Ł First frame, and size estimate:
	var first := stream.frame_now(0)
	if first != null:
		var bytes := float(first.get_width()) * float(first.get_height()) * BYTES_PER_PIXEL * stream._paths.size()
		stream._streaming = bytes > resolve_cache(source, caller, cache_setting, folder) * 1024.0 * 1024.0		#/ Budget 0: always streams

	if for_node is TextureButton:
		stream._open_states(source, caller, folder, cache_setting, stream_setting)
	return stream

#* Open TextureButton state folders:
func _open_states(source: CandyEngine, caller: Object, folder: String, cache_setting: Variant, stream_setting: Variant) -> void:
	for sub_folder in DirAccess.get_directories_at(folder):
		#Ł Slot the folder is named after:
		var slot := ""
		for candidate in CandyUI.BUTTON_TEXTURE_SLOTS:
			if sub_folder.to_lower() in CandyUI.BUTTON_TEXTURE_SLOTS[candidate]:
				slot = candidate
				break
		if slot == "":
			continue

		var state_folder := folder.path_join(sub_folder)
		if slot == "texture_click_mask":
			_open_mask(state_folder)
			continue
		if _states.has(slot):
			printerr("Frame folder: two folders for one button state, '", sub_folder, "' is not used → ", folder)
			continue

		var state_stream := CandyFrameStream.open(source, caller, state_folder, cache_setting, stream_setting)
		if state_stream.count() == 0:
			printerr("Frame folder: no frames in the button state folder → ", state_folder)
			continue
		if state_stream.count() != 1 and state_stream.count() != count():
			printerr("Frame folder: the button state folder has ", state_stream.count(), " frames, the animation ", count(),
				" - it wraps around → ", state_folder)
		_states[slot] = state_stream

#* Load a TextureButton's click mask ("mask" folder):
func _open_mask(mask_folder: String) -> void:
	var files := CandyMedia.list_frame_files(mask_folder)
	if files.is_empty():
		printerr("Frame folder: no file in the button's mask folder → ", mask_folder)
		return
	if files.size() > 1:
		printerr("Frame folder: a click mask can't be animated - using '", files[0], "' → ", mask_folder)
	_mask = CandyMedia.load_bitmap(mask_folder.path_join(files[0]))
	if _mask == null:
		printerr("Frame folder: the click mask isn't a BitMap (import the image as BitMap) → ", mask_folder.path_join(files[0]))

#* The number of frames:
func count() -> int:
	return _paths.size()

#* Whether streaming:
func is_streaming() -> bool:
	return _streaming


#& FRAMES:
#* A frame for playback, or null if not loaded yet:
func frame(index: int) -> Texture2D:
	if _paths.is_empty():
		return null
	index = posmod(index, _paths.size())
	_started = true
	_collect()
	_fill(index)		#/ Moves the loading window to 'index'
	return _loaded.get(index)

#* A frame now, loaded on the spot if needed:
func frame_now(index: int) -> Texture2D:
	if _paths.is_empty():
		return null
	index = posmod(index, _paths.size())
	_collect()
	if not _loaded.has(index):
		var tex := CandyMedia.load_texture(_paths[index])
		if tex == null:
			return null
		_loaded[index] = tex
	return _loaded[index]

#* Show a frame on 'node', for playback (skipped if not loaded):
func show_frame(node: Node, index: int) -> void:
	var tex := frame(index)
	if tex != null:
		node.set(_texture_property(node), tex)
	for slot in _states:
		var state_tex: Texture2D = _states[slot].frame(index)
		if state_tex != null:
			node.set(slot, state_tex)
	_show_mask(node)

#* Show a frame on 'node' now:
func show_frame_now(node: Node, index: int) -> void:
	var tex := frame_now(index)
	if tex != null:
		node.set(_texture_property(node), tex)
	for slot in _states:
		var state_tex: Texture2D = _states[slot].frame_now(index)
		if state_tex != null:
			node.set(slot, state_tex)
	_show_mask(node)

#* Texture property of a node:
static func _texture_property(node: Node) -> String:
	if node is TextureButton:
		return "texture_normal"
	return "texture"

#* Set a TextureButton's click mask:
func _show_mask(node: Node) -> void:
	if _mask != null and node is TextureButton and node.texture_click_mask != _mask:
		node.texture_click_mask = _mask

#* Release every frame:
func close() -> void:
	for index in _requested:
		_release(_paths[index])
	_requested.clear()
	_loaded.clear()
	_started = false
	for slot in _states:
		_states[slot].close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for index in _requested:
			_release(_paths[index])

#* Collect finished loads:
func _collect() -> void:
	for index in _requested.keys():
		var load_state: Dictionary = _loads.get(_paths[index], {})
		if load_state.is_empty() or bool(load_state["done"]):
			if not load_state.is_empty() and load_state["texture"] != null:
				_loaded[index] = load_state["texture"]
			_release(_paths[index])
			_requested.erase(index)

#* Request the window's frames; release the rest while streaming:
func _fill(index: int) -> void:
	var total := _paths.size()
	var wanted := {0: true}
	var in_flight := _requested.size()

	#@ Step 1 - Frames ahead (wrapping):
	var reach := total
	if _streaming:
		reach = mini(_ahead + 1, total)
	for step in reach:
		var target := (index + step) % total
		wanted[target] = true
		if _loaded.has(target) or _requested.has(target):
			continue
		#% At most _ahead requests at once:
		if in_flight >= _ahead:
			continue
		_request(_paths[target])
		_requested[target] = true
		in_flight += 1

	#@ Step 2 - Release frames behind while streaming:
	if _streaming:
		for loaded_index in _loaded.keys():
			if not wanted.has(loaded_index):
				_loaded.erase(loaded_index)
		for requested_index in _requested.keys():
			if not wanted.has(requested_index):
				_release(_paths[requested_index])
				_requested.erase(requested_index)


#& SETTINGS:
#* A frame folder's memory budget, in MB:
@warning_ignore("unused_parameter")
static func resolve_cache(source: CandyEngine, caller: Object, element_value: Variant, folder: String) -> float:
	var config_value = CandyMedia.file_config_value(folder, "cache")
	if config_value != null:
		return float(config_value)
	if element_value != null and float(element_value) >= 0.0:		#/ Below 0 inherits
		return float(element_value)
	if source != null and "animation_folder_cache" in source and float(source.animation_folder_cache) >= 0.0:
		return float(source.animation_folder_cache)
	var property = candy_de.get("animation_folder_cache")
	if property != null and float(property) >= 0.0:
		return float(property)
	printerr("Candy_Properties.gd: 'animation_folder_cache' is missing or below 0. Using ", DEFAULT_CACHE_MB, " MB.")
	return DEFAULT_CACHE_MB

#* Frames loaded ahead while streaming:
@warning_ignore("unused_parameter")
static func resolve_stream(source: CandyEngine, caller: Object, element_value: Variant, folder: String) -> int:
	var config_value = CandyMedia.file_config_value(folder, "stream")
	if config_value != null:
		return int(config_value)
	if element_value != null and int(element_value) >= 1:		#/ Below 1 inherits
		return int(element_value)
	if source != null and "animation_folder_stream" in source and int(source.animation_folder_stream) >= 1:
		return int(source.animation_folder_stream)
	var property = candy_de.get("animation_folder_stream")
	if property != null and int(property) >= 1:
		return int(property)
	printerr("Candy_Properties.gd: 'animation_folder_stream' is missing or below 1. Using ", DEFAULT_STREAM, ".")
	return DEFAULT_STREAM


#& SHARED LOADER:
#* Request a background load:
static func _request(path: String) -> void:
	if _loads.has(path):
		_loads[path]["wanted"] = int(_loads[path]["wanted"]) + 1
		return

	var load_state := {"kind": "resource", "task": -1, "done": false, "texture": null, "wanted": 1}

	#¦ 1. Resources - threaded loading:
	if not CandyMedia.is_runtime_path(path) or ResourceLoader.exists(path):
		if ResourceLoader.load_threaded_request(path) != OK:
			load_state["done"] = true
	#¦ 2. Runtime images - worker thread:
	else:
		load_state["kind"] = "image"
		load_state["task"] = WorkerThreadPool.add_task(func() -> void: _decode(path))

	_loads[path] = load_state
	_start_polling()

#* Release a requested file:
static func _release(path: String) -> void:
	if not _loads.has(path):
		return
	var load_state: Dictionary = _loads[path]
	load_state["wanted"] = int(load_state["wanted"]) - 1
	if int(load_state["wanted"]) <= 0 and bool(load_state["done"]):
		_loads.erase(path)

#* Decode a raw image, on a worker thread:
static func _decode(path: String) -> void:
	var image := Image.new()
	if image.load(path) != OK:
		image = null
	_decoded_mutex.lock()
	_decoded[path] = image
	_decoded_mutex.unlock()

#* Run _poll_loads() every frame:
static func _start_polling() -> void:
	if _polling:
		return
	var tree := Engine.get_main_loop()
	if not (tree is SceneTree):
		return
	_polling = true
	tree.process_frame.connect(func() -> void: _poll_loads())

#* Finish done loads, on the main thread:
static func _poll_loads() -> void:
	for path in _loads.keys():
		var load_state: Dictionary = _loads[path]
		if bool(load_state["done"]):
			continue

		if str(load_state["kind"]) == "resource":
			var status := ResourceLoader.load_threaded_get_status(path)
			if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				continue
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				var resource := ResourceLoader.load_threaded_get(path)
				if resource is Texture2D:
					load_state["texture"] = resource
			if load_state["texture"] == null:
				printerr("Frame folder: not a texture → ", path)
		else:
			var task: int = load_state["task"]
			if not WorkerThreadPool.is_task_completed(task):
				continue
			WorkerThreadPool.wait_for_task_completion(task)
			_decoded_mutex.lock()
			var image = _decoded.get(path)
			_decoded.erase(path)
			_decoded_mutex.unlock()
			if image is Image and not image.is_empty():
				load_state["texture"] = ImageTexture.create_from_image(image)
			else:
				printerr("Frame folder: file could not be read as an image → ", path)

		load_state["done"] = true
		#% No longer wanted:
		if int(load_state["wanted"]) <= 0:
			_loads.erase(path)
