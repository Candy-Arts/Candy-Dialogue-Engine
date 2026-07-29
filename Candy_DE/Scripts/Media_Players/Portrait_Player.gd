#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends AnimationPlayer

var pause_count = 0
var pause_mode = "speech"

var caller: Node


func _on_animation_finished(_anim_name: StringName) -> void:
	reset()


func unpause():
	self.paused = false
	pause_count = 0
	pause_mode = "speech"


func reset():
	pause_count = 0
	pause_mode = "speech"
