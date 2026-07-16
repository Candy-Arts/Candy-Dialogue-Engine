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


extends AnimationPlayer


## Required
@export var effect_player = self

var pause_count = 0
var pause_mode = "speech"
var pause_re_wait = false

#^ Loop / wait tracking:
var loop_target: int = -1
var wait_target: int = -1
var loops_played: int = 0
var duration: float = 0.0

var caller: Node



func _on_animation_finished(_anim_name: StringName) -> void:
	loops_played += 1

	#@ Replay logic:
	if loop_target == 0 or (loop_target > 0 and loops_played < loop_target):
		effect_player.play(_anim_name)
		return

	#@ Playback done:
	effect_player.seek(duration, true)

	#@ Release dialogue block if needed:
	if wait_target == -1 or loops_played >= wait_target:
		caller.active_media_players.erase(self)

	#@ Reset loop state:
	loops_played = 0
	loop_target = -1
	wait_target = -1

func unpause():
	effect_player.play()
	pause_count = 0
	pause_mode = "speech"
	pause_re_wait = false

func reset():
	pause_count = 0
	pause_mode = "speech"
	pause_re_wait = false
	loops_played = 0
	loop_target = -1
	wait_target = -1
	effect_player.stop()
	caller.active_media_players.erase(self)