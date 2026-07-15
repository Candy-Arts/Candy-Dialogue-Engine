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

var pause_count = 0
var pause_mode = "speech"
var pause_re_wait = false

var caller: Node


func _on_animation_finished(_anim_name: StringName) -> void:
	reset()


func unpause():
	self.paused = false


func reset():
	pause_count = 0
	pause_mode = "speech"
	pause_re_wait = false
	caller.active_media_players.erase(self)	
	