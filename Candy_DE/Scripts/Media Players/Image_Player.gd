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


extends TextureRect

@onready var image_player = self

var pause_count = 0
var pause_mode = "speech"
var pause_re_wait = false

#^ Loop / wait tracking:
var loop_target: int = -1
var wait_target: int = -1
var loops_played: int = 0

#^ Animation / timing state:
var frames: Array[Texture2D] = []
var fps: float = 0.0
var frame_index: int = 0
var animated: bool = false
var static_duration: float = 0.0

#^ Default file extension for static images:
@export var default_image_extension = ".png"

@export var default_z = 120

var caller: Node



func _ready():
	self.z_index = default_z


#* Setup static image:
func setup_static(path: String, duration: float, loop) -> void:
	reset_internal()
	loop_target = loop
	animated = false
	static_duration = max(duration, 0.0)
	image_player.texture = load(path)


#* Setup animated image from Anim subfolder:
func setup_animation(anim_folder: String, fps_value: float, loop) -> void:
	reset_internal()
	loop_target = loop
	animated = true
	fps = max(fps_value, 0.001)
	frames.clear()

	if not DirAccess.dir_exists_absolute(anim_folder):
		printerr("Image animation folder not found → ", anim_folder)
		return

	var dir = DirAccess.open(anim_folder)
	dir.list_dir_begin()
	var file = dir.get_next()

	while file != "":
		if not dir.current_is_dir():
			if not file.ends_with(".import"):
				var loaded_resource = load(anim_folder.path_join(file))
				if loaded_resource != null:
					frames.append(loaded_resource)
		file = dir.get_next()

	dir.list_dir_end()
	frames.sort_custom(func(a, b): return a.resource_path < b.resource_path)

	if frames.size() > 0:
		image_player.texture = frames[0]


#* Start playback:
func start():
	if animated:
		start_frame_timer()
	else:
		start_static_timer()


#* Static image timer (one loop):
func start_static_timer():
	var t := $"Timer"
	t.stop()
	t.wait_time = static_duration
	t.start()


#* Frame timer (animated):
func start_frame_timer():
	var t := $"Timer"
	t.stop()
	t.wait_time = 1.0 / fps
	t.start()


func _on_timer_timeout():
	if animated:
		frame_index += 1
		if frame_index >= frames.size():
			frame_index = 0
			on_cycle_finished()
			return
		image_player.texture = frames[frame_index]
		start_frame_timer()
	else:
		on_cycle_finished()


#* On display / animation cycle finished:
func on_cycle_finished():
	loops_played += 1
	print("Cycle finished! loops_played=", loops_played, " loop_target=", loop_target)
	if loop_target == 0 or (loop_target > 0 and loops_played < loop_target):
		print("  → Restarting loop")
		if animated:
			frame_index = 0
			image_player.texture = frames[0]
			start_frame_timer()
		else:
			start_static_timer()
		return
	print("  → Ending playback")
	reset()

	if wait_target == -1 or loops_played >= wait_target:
		caller.active_media_players.erase(self)


func unpause():
	$"Timer".paused = false
	pause_count = 0
	pause_mode = "speech"
	pause_re_wait = false


func reset():
	reset_internal()
	caller.active_media_players.erase(self)


func reset_internal():
	$"Timer".stop()
	frames.clear()
	frame_index = 0
	fps = 0.0
	static_duration = 0.0
	animated = false
	loops_played = 0
	loop_target = -1
	wait_target = -1
	image_player.texture = null
	visible = false
