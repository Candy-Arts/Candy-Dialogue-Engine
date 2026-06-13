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


extends AudioStreamPlayer3D

## Required
@export var audio_player = self

var pause_count = 0
var pause_mode = "speech"
var pause_re_wait = false

#^ Loop / wait tracking:
var loop_target: int = -1        #/ -1 = no loop, 0 = infinite, >0 = finite
var wait_target: int = -1        #/ -1 = no wait, >0 = wait n loops
var loops_played: int = 0        #/ completed loops

#^ Default extension for audio files:
@export var default_audio_extension = ".ogg"

var caller: Node



func _on_finished() -> void:
	loops_played += 1

	#@ Replay logic:
	if loop_target == 0 or (loop_target > 0 and loops_played < loop_target):
		audio_player.play()
		return

	#@ Playback done:
	audio_player.stop()
	audio_player.stream = null

	#@ Release dialogue block if needed:
	if wait_target == -1 or loops_played >= wait_target:
		caller.active_media_players.erase(self)

	#@ Reset loop state:
	loops_played = 0
	loop_target = -1
	wait_target = -1


func unpause():
	audio_player.stream_paused = false
	pause_count = 0
	pause_mode = "speech"
	pause_re_wait = false


func reset():
	pause_count = 0
	pause_mode = "speech"
	pause_re_wait = false

	#% Reset loop / wait state:
	loops_played = 0
	loop_target = -1
	wait_target = -1

	audio_player.stop()
	audio_player.stream = null

	caller.active_media_players.erase(self)
