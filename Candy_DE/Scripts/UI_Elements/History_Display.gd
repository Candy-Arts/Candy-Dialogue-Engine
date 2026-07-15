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


extends PanelContainer


## Required: Displays history text
@export var log_node: Node

@export var default_z = 100

var caller: Node

func _ready() -> void:
	self.z_index = default_z

func show_history() -> void:
	self.visible = true
	update_history_display()

#* Display formatted dialogue history:
func update_history_display() -> void:
	#@ Collect all formatted lines into a single string:
	var history_log
	var out := ""

	if caller == null:
		history_log = candy_de.general_dialogue_history
	else:
		history_log = caller.dialogue_history

	#@ Process the history log:
	for entry in history_log:
		for key in entry.keys():
			var value = entry[key]

			#@ Case 1 - Spoken dialogue line:
			if key == "Speech":
				var display_name: String = value.get("display_name", "")
				var speech: String = value.get("speech", "")

				#% Format: Name: "Speech":
				out += str(display_name + ': ' + '"' + speech + '"' + '\n')

			#@ Case 2 - Transition markers:
			else:
				#% §End - display a horizontal line:
				if key == "End":
					out += "\n*****\n\n"

				#% §Jump / §Bridge - display a horizontal line only if conversation changed:
				elif key in ["Jump", "Bridge"]:
					var changed_conv := bool(value.get("changed_conv", false))
					if changed_conv:
						out += "[hr]\n"

	#@ Apply to the RichTextLabel:
	log_node.text = out


#* Close the dialogue history:
func close_history():
	self.visible = false
	log_node.text = ""
