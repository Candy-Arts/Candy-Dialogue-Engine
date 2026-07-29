#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Control


## REQUIRED: The Chat_Channels this box lays out.[br][br]
## The box is displayed while at least one of them is visible. A channel left out of this list
## doesn't show or hide the box.
@export var channels: Array[Control] = []


func _ready():
	if get_channels().is_empty():
		printerr("Chat_Box: '", self.name, "' has no channels assigned.")
	#Ł Follow the channels' visibility:
	#? A hidden box hides its channels.
	for channel in get_channels():
		if not channel.visibility_changed.is_connected(_update_visibility):
			channel.visibility_changed.connect(_update_visibility)
	_update_visibility()


#* Show while any channel is visible:
func _update_visibility() -> void:
	var any_visible := false
	for channel in get_channels():
		if channel.visible:
			any_visible = true
	self.visible = any_visible


#* The assigned Chat_Channels, without empty slots:
func get_channels() -> Array:
	var assigned: Array = []
	for channel in channels:
		if is_instance_valid(channel):
			assigned.append(channel)
	return assigned
