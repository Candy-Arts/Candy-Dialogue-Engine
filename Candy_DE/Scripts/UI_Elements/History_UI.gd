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


## REQUIRED: Displays history text
@export var log_node: Node

## The string displayed where dialogue ended.
@export_multiline var end_marker: String = "\n*****\n\n"

## The string displayed where dialogue Jumped.
@export_multiline var jump_marker: String = "[hr]\n"		

## The string displayed where dialogue Bridged.
@export_multiline var bridge_marker: String = "[hr]\n"		

## The string displayed where dialogue Returned.
@export_multiline var return_marker: String = "[hr]\n"	

## Default Z-order.
@export var default_z = 100

var caller: Node

func _ready() -> void:
	self.z_index = default_z
	if log_node != null:
		log_node.bbcode_enabled = true


#* Show the history:
#+ Call through open_instance_history() or open_general_history().
func show_history() -> void:
	self.visible = true
	update_history_display()


#* Display the history:
func update_history_display() -> void:
	if log_node == null:
		return

	#@ Step 1 - Get the log:
	var history_log
	var out := ""

	if caller == null:
		history_log = candy_de.general_dialogue_history
	else:
		history_log = caller.dialogue_history

	#@ Step 2 - Format entries:
	for entry in history_log:
		for key in entry.keys():
			var value = entry[key]

			#¦ 1. Spoken line:
			if key == "Speech":
				var display_name: String = value.get("display_name", "")
				var speech: String = value.get("speech", "")

				#Ł Format -`Name: "Speech"`:
				out += str(display_name + ': ' + '"' + speech + '"' + '\n')

			#¦ 2. Transition markers:
			else:
				#¦ 1. End:
				if key == "End":
					out += end_marker

				#¦ 2. Jump, if the conversation changed:
				elif key == "Jump":
					var changed_conv := bool(value.get("changed_conv", false))
					if changed_conv:
						out += jump_marker

				#¦ 3. Bridge, if the conversation changed:
				elif key == "Bridge":
					var changed_conv := bool(value.get("changed_conv", false))
					if changed_conv:
						out += bridge_marker

				#¦ 4. Return:
				elif key == "Return":
					out += return_marker

	#@ Step 3 - Display:
	log_node.text = out


#* Close the dialogue history:
func close_history():
	self.visible = false
	if log_node != null:
		log_node.text = ""
