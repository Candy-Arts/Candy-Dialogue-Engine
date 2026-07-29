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

## REQUIRED: The node that displays the label for the choice.
@export var choice_label: Node
## REQUIRED: The node that displays the tooltip for the choice.
@export var choice_tooltip: Node
## REQUIRED: The node that selects the choice when interacted (e.g. the actual button node to click).
@export var choice_button: Node

var caller: Node

var parent_category
var parent_menu

var category_name
var choice_name

var tags = ""

var label = ""
var tooltip = ""

var choice_enabled = 1
var choice_active = 1
var choice_invisible = 0



#* Setup (by Choice_List or Choice_Status, once in the tree with its data assigned):
@warning_ignore("unused_parameter")
func setup(custom_data: Array = []) -> void:
	await _set_label()
	await _set_tooltip()
	await _toggle_enabled()
	await _toggle_active()
	await _toggle_invisible()


#* Redisplay texts in the current language (category's refresh_language()):
func refresh_language():
	_set_label()
	_set_tooltip()


#* Change label text:
func _set_label():
	#Ł Translate:
	choice_label.text = CandyWriting.get_shared().translate(caller, self, str(label), "choice_button_labels")


#* Change tooltip text:
func _set_tooltip():
	#Ł Translate:
	choice_tooltip.tooltip_text = CandyWriting.get_shared().translate(caller, self, str(tooltip), "choice_button_tooltips")


#* Enabled status changed:
#+ e.g. change the button's look.
func _toggle_enabled():
	match choice_enabled:
		0:		#/ Inactive buttons still call _choice_selected(), with no effect
			pass
		1:
			pass


#* Active status changed:
#+ e.g. change the button's look.
func _toggle_active():
	match choice_active:
		0:		#/ Inactive buttons still call _choice_selected(), with no effect
			pass
		1:
			pass


#* Show or hide per choice_invisible:
func _toggle_invisible():
	match choice_invisible:
		0:
			self.visible = true
		1:
			self.visible = false


#* Choice selected:
func _choice_selected():
	if caller == null or not is_instance_valid(caller):
		printerr("Choice_Button: no caller assigned - selection '%s' was not sent." % str(choice_name))
		return

	#% Suspended:
	if caller.dialogue_suspended == true:
		return

	#Ł Release focus, so Dialogue_Advance can't press it again:
	if choice_button != null and is_instance_valid(choice_button) and choice_button.has_method("release_focus"):
		choice_button.release_focus()
	else:
		push_warning("Candy DE: choice '%s' has no 'choice_button' assigned - focus was not released." % str(choice_name))

	if parent_menu == null or not is_instance_valid(parent_menu):
		printerr("Choice_Button: no parent menu for '%s' - selection was not sent." % str(choice_name))
		return

	caller.choice_list_event.emit(parent_menu.nesting_depth, "Choice", category_name, choice_name, self)
