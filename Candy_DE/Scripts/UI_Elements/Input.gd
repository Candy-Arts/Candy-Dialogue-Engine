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


extends Control


@onready var input_line_path = get_node("VBox/Input")

@onready var input_instructions_node = get_node("VBox/Instructions")
@onready var input_error_node = get_node("VBox/Error")
@onready var input_cancel_button = get_node("VBox/HBox/Cancel")
@onready var input_confirm_button = get_node("VBox/HBox/Confirm")

@export var default_z = 90

var caller: Node
var depth


#^ Check if the input is valid:
var input_valid = true 


var save_variable
var config_mode = ""
var submit_mode = ""
var cancel_mode = ""


#^ Minimum/maximum amount of characters or words required/allowed for input:
var char_min = -1
var char_max = -1
var word_min = -1
var word_max = -1

#^ Use blacklist or whitelist:
#? Uses whitelist if both arrays have data.
var blacklist = {}		#/ Reject inputs containing blacklisted strings.
var whitelist = {}		#/ Reject inputs containing strings not in whitelist.

var regex = ""

var allow_uppercase = true
var allow_lowercase = true

var allow_numbers = true
var allow_decimals = true

var allow_punctuation = true
var allow_special = true
var allow_spaces = true

#^ Display error messages if input is invalid:
var show_errors = true

#^ Effect of the Enter key:
#% "submit": submits the input text.
#% "break": inserts a line break.
var enter_behavior = "submit"



func _ready():
	self.z_index = default_z
	input_line_path.text_changed.connect(_on_input_changed)
	await get_tree().process_frame
	check_input()


#* Initial setup:
#+ REQUIRED: Called by the §Input command, but can be modified freely.
func setup(save, mode, instructions, default_text, placeholder, _custom_1, _custom_2, _custom_3, _custom_4, _custom_5):
	self.visible = true
	input_error_node.text = ""

	match mode:
		"Default":
			save_variable = save
			config_mode = "Default"
			submit_mode = "Default"
			cancel_mode = "Default"
			_set_instructions(instructions)
			_set_placeholder_text(placeholder)
			_set_default_text(default_text)
			input_cancel_button.visible = true
			input_confirm_button.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			config()


#* Configure variables:
func config():
	match config_mode:
		"Default":
			char_min = -1
			char_max = -1
			word_min = -1
			word_max = -1

			blacklist = candy_de.input_blacklists["void"]	#/ Fetch and use the "void" blacklist
			whitelist = candy_de.input_whitelists["void"]	#/ Fetch and use the "void" whitelist

			regex = ""

			allow_uppercase = true
			allow_lowercase = true

			allow_numbers = true
			allow_decimals = true

			allow_punctuation = true
			allow_special = true
			allow_spaces = true
			
			show_errors = true
			enter_behavior = "submit"



func _set_instructions(instructions):
	var language = candy_de.language
	
	if candy_de.input_instructions.has(instructions) and candy_de.input_instructions[instructions].has(language):
		input_instructions_node.text = candy_de.input_instructions[instructions][language]

	#% If translation missing from the localizations dictionary, use default value instead:
	else:
		input_instructions_node.text = instructions


func _set_placeholder_text(placeholder):
	var language = candy_de.language
	
	if candy_de.input_placeholder_texts.has(placeholder) and candy_de.input_placeholder_texts[placeholder].has(language):
		input_line_path.placeholder_text = candy_de.input_placeholder_texts[placeholder][language]

	#% If translation missing from the localizations dictionary, use default value instead:
	else:
		input_line_path.placeholder_text = placeholder


func _set_default_text(default_text):
	var language = candy_de.language
	
	if candy_de.input_default_texts.has(default_text) and candy_de.input_default_texts[default_text].has(language):
		input_line_path.text = candy_de.input_default_texts[default_text][language]

	#% If translation missing from the localizations dictionary, use default value instead:
	else:
		input_line_path.text = default_text


#* On input submitted:
func submit():
	var delete_menu = false		#/ Set to 'true' through the match statement if desired

	#% Special behavior:
	match submit_mode:
	#TODO: Add modes where special behavior must occur.
		_:
			pass		

	#% Exit input menu:
	if input_valid == true:	
		await store_to_variable()
		caller.input_received.emit(depth, "finish", null)
		if delete_menu == true:
			self.queue_free()
		else:
			self.visible = false

#* On input cancelled:
func cancel():
	var delete_menu = false		#/ Set to 'true' through the match statement if desired
	var cancel_valid = true		#/ Set to 'false' through the match statement as required

	#% Special behavior:
	match cancel_mode:
	#TODO: Add modes where cancelling shouldn't be possible and set valid = false
		_:
			pass


	#% Exit input menu:
	if cancel_valid == true:	
		caller.input_received.emit(depth, "finish", null)
		if delete_menu == true:
			self.queue_free()
		else:
			self.visible = false


func _on_input_changed(_new_text: String):
	check_input()


#* Store the input text into the variable referenced by save_variable
func store_to_variable():
	if typeof(save_variable) != TYPE_STRING or save_variable.is_empty():
		printerr("store_to_variable(): decode aborted, invalid variable reference → ", save_variable)
		return

	#% Decode the variable reference
	var decoded = caller.decode_variable_name(save_variable)
	if decoded.is_empty() or decoded["base"] == null:
		printerr("store_to_variable(): decode failed, invalid variable reference → ", save_variable)
		return

	#% Value to store (always string input from player)
	var value_to_store: String = input_line_path.text

	#% Assign the value using the same system §Set uses
	caller.set_variable_value(decoded, value_to_store)

	print("[DEBUG] store_to_variable →", save_variable, "=", value_to_store)

#* Verify the input conforms with all conditions:
func check_input():
	input_valid = true
	var text: String = input_line_path.text
	var language = candy_de.language

	#@ Clear previous error text if applicable
	if show_errors:
		input_error_node.text = ""

	#@ Prepare separators for word splitting
	var separators := [" ", "-", "_"]
	var words: Array[String] = [text]
	for sep in separators:
		var temp: Array[String] = []
		for w in words:
			temp.append_array(w.split(sep))
		words = temp

	#@ Remove empty entries
	var filtered_words: Array[String] = []
	for w in words:
		if w.strip_edges() != "":
			filtered_words.append(w)
	words = filtered_words

	#@ Character length limits
	if char_min > -1 and text.length() < char_min:
		var raw_error_1 = "Minimum "
		var raw_error_2 = " characters required."
		var error_1 = raw_error_1
		var error_2 = raw_error_2
		if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
			error_1 = candy_de.input_error_messages[raw_error_1][language]
		if candy_de.input_error_messages.has(raw_error_2) and candy_de.input_error_messages[raw_error_2].has(language):
			error_2 = candy_de.input_error_messages[raw_error_2][language]

		input_valid = false
		input_error_node.text = "[color=red]" + error_1 + char_min + error_2 + "[/color]"
		return false
	if char_max > -1 and text.length() > char_max:
		var raw_error_1 = "Maximum "
		var raw_error_2 = " characters allowed."
		var error_1 = raw_error_1
		var error_2 = raw_error_2
		if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
			error_1 = candy_de.input_error_messages[raw_error_1][language]
		if candy_de.input_error_messages.has(raw_error_2) and candy_de.input_error_messages[raw_error_2].has(language):
			error_2 = candy_de.input_error_messages[raw_error_2][language]

		input_valid = false
		input_error_node.text = "[color=red]" + error_1 + char_max + error_2 + "[/color]"
		return false

	#@ Word count limits
	if word_min > -1 and words.size() < word_min:
		var raw_error_1 = "Minimum "
		var raw_error_2 = " words required."
		var error_1 = raw_error_1
		var error_2 = raw_error_2
		if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
			error_1 = candy_de.input_error_messages[raw_error_1][language]
		if candy_de.input_error_messages.has(raw_error_2) and candy_de.input_error_messages[raw_error_2].has(language):
			error_2 = candy_de.input_error_messages[raw_error_2][language]

		input_valid = false
		input_error_node.text = "[color=red]" + error_1 + word_min + error_2 + "[/color]"
		return false
	if word_max > -1 and words.size() > word_max:
		var raw_error_1 = "Maximum "
		var raw_error_2 = " words allowed."
		var error_1 = raw_error_1
		var error_2 = raw_error_2
		if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
			error_1 = candy_de.input_error_messages[raw_error_1][language]
		if candy_de.input_error_messages.has(raw_error_2) and candy_de.input_error_messages[raw_error_2].has(language):
			error_2 = candy_de.input_error_messages[raw_error_2][language]

		input_valid = false
		input_error_node.text = "[color=red]" + error_1 + word_max + error_2 + "[/color]"
		return false

	#@ Whitelist / Blacklist logic
	if whitelist.has(language) and whitelist[language].size() > 0:
		for w in words:
			var allowed := false
			for white in whitelist[language]:
				if white.ends_with("*"):
					var prefix = white.substr(0, white.length() - 1)
					if w.begins_with(prefix):
						allowed = true
						break
				elif w == white:
					allowed = true
					break
			if not allowed:
				var raw_error_1 = "Word not allowed: '"
				var raw_error_2 = "'."
				var error_1 = raw_error_1
				var error_2 = raw_error_2
				if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
					error_1 = candy_de.input_error_messages[raw_error_1][language]
				if candy_de.input_error_messages.has(raw_error_2) and candy_de.input_error_messages[raw_error_2].has(language):
					error_2 = candy_de.input_error_messages[raw_error_2][language]

				input_valid = false
				input_error_node.text = "[color=red]" + error_1 + w + error_2 + "[/color]"
				return false

	elif blacklist.has(language) and blacklist[language].size() > 0:
		for w in words:
			for black in blacklist[language]:
				if black.ends_with("*"):
					var prefix = black.substr(0, black.length() - 1)
					if w.begins_with(prefix):
						var raw_error_1 = "Forbidden word: '"
						var raw_error_2 = "'."
						var error_1 = raw_error_1
						var error_2 = raw_error_2
						if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
							error_1 = candy_de.input_error_messages[raw_error_1][language]
						if candy_de.input_error_messages.has(raw_error_2) and candy_de.input_error_messages[raw_error_2].has(language):
							error_2 = candy_de.input_error_messages[raw_error_2][language]

						input_valid = false
						input_error_node.text = "[color=red]" + error_1 + w + error_2 + "[/color]"
						return false
				elif w == black:
					var raw_error_1 = "Forbidden word: '"
					var raw_error_2 = "'."
					var error_1 = raw_error_1
					var error_2 = raw_error_2
					if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
						error_1 = candy_de.input_error_messages[raw_error_1][language]
					if candy_de.input_error_messages.has(raw_error_2) and candy_de.input_error_messages[raw_error_2].has(language):
						error_2 = candy_de.input_error_messages[raw_error_2][language]

					input_valid = false
					input_error_node.text = "[color=red]" + error_1 + w + error_2 + "[/color]"
					return false

	#@ Per-character validation
	var regex_letter := RegEx.new()
	regex_letter.compile("^[\\p{L}]$")

	for i in text.length():
		var ch := text.substr(i, 1)
		var code := text.unicode_at(i)
		if ch == "":
			continue

		#% Check spaces
		if ch == " " and not allow_spaces:
			var raw_error_1 = "Spaces are not allowed."
			var error_1 = raw_error_1
			if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
				error_1 = candy_de.input_error_messages[raw_error_1][language]

			input_valid = false
			input_error_node.text = "[color=red]" + error_1 + "[/color]"
			return false

		#% Letters
		if regex_letter.search(ch):
			if not allow_uppercase and ch == ch.to_upper() and ch != ch.to_lower():
				var raw_error_1 = "Uppercase letters are not allowed."
				var error_1 = raw_error_1
				if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
					error_1 = candy_de.input_error_messages[raw_error_1][language]

				input_valid = false
				input_error_node.text = "[color=red]" + error_1 + "[/color]"
				return false
			elif not allow_lowercase and ch == ch.to_lower() and ch != ch.to_upper():
				var raw_error_1 = "Lowercase letters are not allowed."
				var error_1 = raw_error_1
				if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
					error_1 = candy_de.input_error_messages[raw_error_1][language]

				input_valid = false
				input_error_node.text = "[color=red]" + error_1 + "[/color]"
				return false
			continue

		#% Numbers
		if code >= 0x30 and code <= 0x39:
			if not allow_numbers:
				var raw_error_1 = "Numbers are not allowed."
				var error_1 = raw_error_1
				if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
					error_1 = candy_de.input_error_messages[raw_error_1][language]

				input_valid = false
				input_error_node.text = "[color=red]" + error_1 + "[/color]"
				return false
			continue

		#% Decimal point (only if between digits)
		if ch == ".":
			var prev_is_digit := (i > 0 and text.unicode_at(i - 1) >= 0x30 and text.unicode_at(i - 1) <= 0x39)
			var next_is_digit := (i < text.length() - 1 and text.unicode_at(i + 1) >= 0x30 and text.unicode_at(i + 1) <= 0x39)
			if prev_is_digit and next_is_digit:
				if not allow_decimals:
					var raw_error_1 = "Decimal numbers are not allowed."
					var error_1 = raw_error_1
					if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
						error_1 = candy_de.input_error_messages[raw_error_1][language]

					input_valid = false
					input_error_node.text = "[color=red]" + error_1 + "[/color]"
					return false
			else:
				if not allow_punctuation:
					var raw_error_1 = "Punctuation is not allowed."
					var error_1 = raw_error_1
					if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
						error_1 = candy_de.input_error_messages[raw_error_1][language]

					input_valid = false
					input_error_node.text = "[color=red]" + error_1 + "[/color]"
					return false
			continue

		#% Punctuation
		if ch in [",", ";", ":", "?", "!", "'", "\"", "(", ")", "[", "]", "{", "}", "—", "-", "_"]:
			if not allow_punctuation:
				var raw_error_1 = "Punctuation is not allowed."
				var error_1 = raw_error_1
				if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
					error_1 = candy_de.input_error_messages[raw_error_1][language]

				input_valid = false
				input_error_node.text = "[color=red]" + error_1 + "[/color]"
				return false
			continue

		#% Special characters
		if not allow_special:
			var raw_error_1 = "Special characters are not allowed."
			var error_1 = raw_error_1
			if candy_de.input_error_messages.has(raw_error_1) and candy_de.input_error_messages[raw_error_1].has(language):
				error_1 = candy_de.input_error_messages[raw_error_1][language]

			input_valid = false
			input_error_node.text = "[color=red]" + error_1 + "[/color]"
			return false

	#@ If no errors
	input_valid = true
	return true
