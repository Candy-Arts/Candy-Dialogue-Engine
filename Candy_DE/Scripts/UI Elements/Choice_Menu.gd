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

@onready var category_list = get_node("Categories")
@onready var timer_list = get_node("Timers")

@export var never_hide = false

var caller: Node
var nesting_depth


#^ Timer dictionary:
var title = ""

var prompt = ""

var custom = ""

var tags = ""



#* READY:
func _ready() -> void:
	_set_general_title()
	_set_general_prompt()


#* Display the list's general title:
func _set_general_title():
	var language = candy_de.language
	var title_node = get_node_or_null("title_node") #TODO: replace with the actual path to the node that displays the title
	
	if title_node != null:
		if candy_de.choice_menu_titles.has(title) and candy_de.choice_menu_titles[title].has(language):
			title_node.text = candy_de.choice_menu_titles[title][language]

		#% If translation missing from the localizations dictionary, use default value instead:
		else:
			title_node.text = title


#* Display the general prompt for the list:
func _set_general_prompt():
	var language = candy_de.language
	var prompt_node = get_node_or_null("prompt_node") #TODO: replace with the actual path to the node that displays the prompt
	
	if prompt_node != null:
		if candy_de.choice_menu_prompts.has(prompt) and candy_de.choice_menu_prompts[prompt].has(language):
			prompt_node.text = candy_de.choice_menu_prompts[prompt][language]

		#% If translation missing from the localizations dictionary, use default value instead:	
		else:
			prompt_node.text = prompt


#* Called when any timer expires:
func _on_timer_timeout(timer_name):
	caller.choice_list_event.emit(nesting_depth, "Timer", null, timer_name, null)


#* Deactivate this menu when bridging:
#? Used for hiding the menu when a choice or timer opens another choice menu.
#TODO: Not called automatically: call must be setup in code or in dialogue script.
func deactivate():
	self.visible = false
	#TODO: Edit function for desired behavior.


#* Reactivate this menu when returning from a bridge:
#? Used for showing the menu again when returning to the same nesting depth.
#? Called automatically by §Bridge, after returning, if the nesting depth matches.
#+ Can also be called manually, in order to re-display sooner.
#+ e.g. menu is at depth 1, descendent is at depth 4 → call manually to reactivate at depth 3,
#+ or wait for automatic call upon return to depth 1.
func reactivate():
	self.visible = true
	#TODO: Edit function for desired behavior.


#* Run custom logic once menu is set up:
#% Called by §Choice_List once the menu, categories and buttons
#% are finished spawning and have run their Setup transitions.
#% Basically a hook to inject custom logic.
func x_initialization_finished():
	pass


#* Hide older choice menus:
#% Optional. Not called anywhere by default.
#% E.g. call it in x_initialization_finished().
func hide_old_menus():
	#% Iterate through all choice menus:
	for child in get_node(caller.ui_elements_paths["choices_path"]):
		#% Skip self:
		if child == self:
			continue
		#% Hide older menus, unless immune:
		elif child.never_hide == false:
			child.deactivate()
			#child.visible = false		#/ Alternative to child_deactivate() - use either one of them.