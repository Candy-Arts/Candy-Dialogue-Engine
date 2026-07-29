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

## REQUIRED: Parent for category scenes.
@export var category_list: Node
## REQUIRED: Parent for choice timers.
@export var timer_list: Node
## OPTIONAL: Shield for blocking clicks and masking the menu when choice is selected or timer expires.
@export var shield: Node
## OPTIONAL: Node for displaying the menu title.
@export var title_node: Node
## OPTIONAL: Node for displaying the menu prompt.
@export var prompt_node: Node
## Set to true if the menu should not be hidden by nested choice lists.
@export var never_hide = false

var caller: Node
var nesting_depth


#^ Menu data:
var title = ""

var prompt = ""

var tags = ""



#* READY:
func _ready() -> void:
	pass


#* Setup:
@warning_ignore("unused_parameter")
func setup(custom_data: Array = []) -> void:
	_set_general_title()
	_set_general_prompt()


#* Display the menu title:
func _set_general_title():
	if title_node != null:
		#Ł Translate:
		title_node.text = CandyWriting.get_shared().translate(caller, self, str(title), "choice_menu_titles")
		#Ł Hidden when empty, so it leaves no gap:
		title_node.visible = title_node.text != ""


#* Display the menu prompt:
func _set_general_prompt():
	if prompt_node != null:
		#Ł Translate:
		prompt_node.text = CandyWriting.get_shared().translate(caller, self, str(prompt), "choice_menu_prompts")
		#Ł Hidden when empty, so it leaves no gap:
		prompt_node.visible = prompt_node.text != ""


#* Redisplay texts in the current language, here and in every category:
func refresh_language():
	_set_general_title()
	_set_general_prompt()

	if category_list != null:
		for category in category_list.get_children():
			if category.has_method("refresh_language"):
				category.refresh_language()


#* A timer expired:
func _on_timer_timeout(timer_name):
	caller.choice_list_event.emit(nesting_depth, "Timer", null, timer_name, null)


#* Deactivate this menu when bridging:
#+ Can use await.
#! End with 'visible' false, or Choice_List deactivates it again.
@warning_ignore("unused_parameter")
func deactivate(custom_data: Array = []):
	#? never_hide menus only get here through a Hide_Menu transition.
	self.visible = false
	#TODO: Edit function for desired behavior.


#* Reactivate this menu when returning from a bridge:
#+ Can use await.
#! Not called when the dialogue is stopped: the menu is freed.
@warning_ignore("unused_parameter")
func reactivate(custom_data: Array = []):
	self.visible = true
	#TODO: Edit function for desired behavior.


#* Hook - menu set up:
@warning_ignore("unused_parameter")
func x_initialization_finished(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hook - a choice is closing this menu:
#+ Can use await (e.g. a closing animation).
#! Not called when the menu is freed at once (dialogue stopped or ended, "Continue" or Timeout).
@warning_ignore("unused_parameter")
func x_menu_closing(candy_args: Dictionary, user_args: Array, custom_data: Array):
	pass


#* Hide older choice menus:
#+ Not called by default: e.g. call it in x_initialization_finished().
func hide_old_menus():
	if caller == null or not caller.ui_elements_paths.has("choices_path"):
		return

	var choices_root = caller.get_node_or_null(caller.ui_element_path("choices_path"))
	if choices_root == null:
		return

	#Ł This engine's menus:
	for child in choices_root.get_children():
		#¦ 1. Skip self and other engines' menus:
		if child == self or child.get("caller") != caller:
			continue
		#¦ 2. Hide unless never_hide:
		elif child.get("never_hide") != true:
			if child.has_method("deactivate"):
				child.deactivate()
				#child.visible = false		#/ Alternative to child_deactivate() - use either one of them.


