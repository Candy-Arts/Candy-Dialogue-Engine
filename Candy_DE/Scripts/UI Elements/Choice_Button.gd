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

extends Node

@onready var choice_label = get_node("Button")
@onready var choice_tooltip = get_node("Button")

var caller: Node

var parent_category
var parent_menu

var category_name
var choice_name

var general_custom = ""
var category_custom = ""
var choice_custom = ""

var tags = ""

var label = ""
var tooltip = ""

var choice_enabled = 1
var choice_active = 1
var choice_invisible = 0



#* Setup
func setup() -> void:
	await _set_label()
	await _set_tooltip()
	await _toggle_enabled()
	await _toggle_active()
	await _toggle_invisible()


#* Change label text:
func _set_label():
	var language = candy_de.language
	
	if candy_de.choice_button_labels.has(label) and candy_de.choice_button_labels[label].has(language):
		choice_label.text = candy_de.choice_button_labels[label][language]

	#% If translation missing from the localizations dictionary, use default value instead:
	else:
		choice_label.text = label


#* Change tooltip text:
func _set_tooltip():
	var language = candy_de.language
	
	if candy_de.choice_button_tooltips.has(tooltip) and candy_de.choice_button_tooltips[tooltip].has(language):
		choice_tooltip.tooltip_text = candy_de.choice_button_tooltips[tooltip][language]

	#% If translation missing from the localizations dictionary, use default value instead:
	else:
		choice_tooltip.tooltip_text = tooltip


#* Apply custom effects when enabled status is changed:
#% e.g. used for changing the button appearance.
#% Inactive buttons still call _choice_selected(),
#% but the choice_list_event signal has no effect.
func _toggle_enabled():
	match choice_enabled:
		0:
			pass
		1:
			pass


#* Apply custom effects when active status is changed:
#% e.g. used for changing the button appearance.
#% Inactive buttons still call _choice_selected(),
#% but the choice_list_event signal has no effect.
func _toggle_active():
	match choice_active:
		0:
			pass
		1:
			pass


#* Hide or show button based on invisible value:
func _toggle_invisible():
	match choice_invisible:
		0:
			self.visible = true
		1:
			self.visible = false


#* Called when choice is selected:
func _choice_selected():
	if choice_active == 1:
		caller.choice_list_event.emit(parent_menu.nesting_depth, "Choice", category_name, choice_name, self)
