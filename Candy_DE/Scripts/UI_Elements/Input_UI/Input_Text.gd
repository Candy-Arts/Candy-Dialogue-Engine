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


## REQUIRED: LineEdit or TextEdit for typing text.
@export var input_line_path: Node
## REQUIRED: RichTextLabel for displaying instructions.
@export var input_instructions_node: Node
## REQUIRED: RichTextLabel for displaying error messages.
@export var input_error_node: Node
## REQUIRED: Button or TextureButton for cancelling and closing the menu.
@export var input_cancel_button: Node
## REQUIRED: Button or TextureButton for submitting input.
@export var input_confirm_button: Node

## Default Z-order.
@export var default_z = 90

var caller: Node
var depth


#^ Input validity:
var input_valid = true 

var save_variable
var config_mode = ""
var submit_mode = ""
var cancel_mode = ""

#^ Character and word limits:
var char_min = -1
var char_max = -1
var word_min = -1
var word_max = -1

#^ Use blacklist or whitelist:
#? Whitelist wins if both are set.
var blacklist = {}		#/ Reject inputs containing blacklisted strings.
var whitelist = {}		#/ Reject inputs containing strings not in whitelist.
var _entry_patterns := {}	#/ Blacklist and whitelist entry -> its compiled RegEx (_word_matches())

var regex = ""

var allow_uppercase = true
var allow_lowercase = true

var allow_numbers = true
var allow_decimals = true

var allow_punctuation = true
var allow_special = true
var allow_spaces = true

#^ Show error messages:
var show_errors = true

#^ Effect of the Enter key:
#% "submit": submits the input text.
#% "break": inserts a line break.
var enter_behavior = "submit"

#^ Sanitization, applied by sanitize() when the input is stored (CandySanitizer):
#? Candy DE reads a stored value like any text: "¤¢globals.gold¤" is evaluated when a text
#? variable displays it, "•he¦Alice•" is substituted, "[b]" formats it, a lexicon keyword is formatted, and "¢globals.gold"
#? is evaluated where the value is read as an expression. Each option neutralizes one kind of syntax.
var sanitize_text_variables = true		#/ Doubles the text variable symbols: displayed as written, never evaluated.
var sanitize_substitutions = true		#/ Doubles the word substitution symbols: displayed as written.
var sanitize_bbcode = true				#/ "[" becomes "[lb]": tags are displayed as written (as "[lb]" by a plain Label).
var sanitize_expressions = true			#/ Doubles a leading expression symbol: read as text, never evaluated.
var sanitize_text_events = true			#/ Doubles the text event symbols: displayed as written.
var sanitize_candy_ref_symbols = true	#/ Removes leading reference symbols (€, °, $ and any registered with CandyRef).
var sanitize_lexicon = true				#/ Escapes the whole input ("¬Alice¬"): never formatted by the lexicon.

#^ List the variable in literal_variables (Data_Tables/Literal_Variables.gd), when the input is stored:
#? Its value is then read as written: never evaluated, and escaped where it's displayed.
var record_literal = false
#^ The syntax the listed value may keep (CandySanitizer.LITERAL_ALLOWED: "substitutions", "bbcode"...):
var literal_allowed = []

var suspended: bool = false

#^ Untranslated texts, for refresh_language():
var instructions_source = ""
var placeholder_source = ""
var default_text_source = ""
var shown_default_text = ""		#/ The default text as displayed, to tell whether the player typed over it



func _ready():
	self.z_index = default_z
	input_line_path.text_changed.connect(_on_input_changed)
	await get_tree().process_frame
	check_input()


#* Setup:
#+ REQUIRED: Called by the Input command. Modify freely.
@warning_ignore("unused_parameter")
func setup(save, mode, instructions, default_text, placeholder, custom_data: Array = []):
	self.visible = true
	input_error_node.text = ""

	#% The template's modes - they differ in config():
	#% "Default": the input is stored sanitized.
	#% "Default_NS": the input is stored as typed, unprotected (No Sanitization).
	#% "Default_L": the input is stored as typed, and its variable listed in literal_variables (Literal).
	#+ Add your own modes here and in config(), submit() and cancel().
	match mode:
		"Default", "Default_NS", "Default_L":
			save_variable = save
			config_mode = mode
			submit_mode = mode
			cancel_mode = mode
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
		"Default", "Default_NS", "Default_L":
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

			#% Default sanitizes; Default_NS and Default_L store the input as typed:
			var sanitized: bool = config_mode == "Default"
			sanitize_text_variables = sanitized
			sanitize_substitutions = sanitized
			sanitize_bbcode = sanitized
			sanitize_expressions = sanitized
			sanitize_text_events = sanitized
			sanitize_candy_ref_symbols = sanitized
			sanitize_lexicon = sanitized

			record_literal = config_mode == "Default_L"
			literal_allowed = []


#* Display the instructions:
func _set_instructions(instructions):
	instructions_source = instructions

	#Ł Translate:
	input_instructions_node.text = CandyWriting.get_shared().translate(caller, self, str(instructions), "input_instructions")


#* Display the placeholder text:
func _set_placeholder_text(placeholder):
	placeholder_source = placeholder

	#Ł Translate:
	input_line_path.placeholder_text = CandyWriting.get_shared().translate(caller, self, str(placeholder), "input_placeholder_texts")


#* Display the default text:
func _set_default_text(default_text):
	#Ł Translate:
	input_line_path.text = CandyWriting.get_shared().translate(caller, self, str(default_text), "input_default_texts")

	default_text_source = default_text
	shown_default_text = input_line_path.text


#* Redisplay texts in the current language:
func refresh_language():
	_set_instructions(instructions_source)
	_set_placeholder_text(placeholder_source)
	#% Keep typed text:
	if input_line_path.text == shown_default_text:
		_set_default_text(default_text_source)
	check_input()


#* On input submitted:
func submit():
	if suspended == true:
		return

	var delete_menu = false		#/ Set to 'true' through the match statement if desired

	#@ Step 1 - Special behavior:
	match submit_mode:
	#TODO: Add modes where special behavior must occur.
		_:
			pass		

	#@ Step 2 - Exit input menu:
	if input_valid == true:	
		await store_to_variable()
		caller.input_received.emit(depth, "finish", null)
		if delete_menu == true:
			self.queue_free()
		else:
			self.visible = false


#* On input cancelled:
func cancel():
	if suspended == true:
		return
	
	var delete_menu = false		#/ Set to 'true' through the match statement if desired
	var cancel_valid = true		#/ Set to 'false' through the match statement as required

	#@ Step 1 - Special behavior:
	match cancel_mode:
	#TODO: Add modes where cancelling shouldn't be possible and set valid = false
		_:
			pass

	#@ Step 2 - Exit input menu:
	if cancel_valid == true:	
		caller.input_received.emit(depth, "finish", null)
		if delete_menu == true:
			self.queue_free()
		else:
			self.visible = false


#* Input changed:
func _on_input_changed(_new_text: String):
	check_input()


#* Store the input in save_variable:
func store_to_variable():
	if typeof(save_variable) != TYPE_STRING or save_variable.is_empty():
		printerr("store_to_variable(): no variable to store the input in → ", save_variable)
		return

	#@ Step 1 - Find the variable:
	#? Written like Set's Variable (e.g. "globals.name").
	var found: Dictionary = caller.candy_ref.resolve_target(caller, self, save_variable, candy_de.candy_ref_symbol)
	if not found["ok"]:
		printerr("store_to_variable(): invalid variable reference → ", save_variable)
		return

	#@ Step 2 - Value (always a String), sanitized:
	var value_to_store: String = sanitize(input_line_path.text)

	#@ Step 3 - Write it as Set does:
	if not CandyTargets.get_shared().write_target(caller, self, found, value_to_store, "=", "Input"):
		printerr("store_to_variable(): failed to write → ", save_variable)
		return

	#@ Step 4 - List the variable in literal_variables:
	if record_literal:
		record_literal_variable()


#* List save_variable in literal_variables, as text variables name it:
#? A Save written with the expression symbol is evaluated first: its result names the variable.
func record_literal_variable():
	var variable_name: String = save_variable.strip_edges()
	var sym: String = candy_de.candy_ref_symbol
	if sym != "" and variable_name.begins_with(sym) and not variable_name.begins_with(sym + sym):
		var named = caller.candy_ref.resolve_value(caller, self, variable_name, sym)
		if caller.candy_ref.last_failed:
			return		#/ Error printed by CandyRef
		variable_name = str(named)
	CandySanitizer.add_literal_variable(variable_name, literal_allowed)


#* Neutralize Candy DE syntax in the input, as the sanitize_ options say (see CandySanitizer):
func sanitize(text: String) -> String:
	return CandySanitizer.sanitize(text, sanitize_text_variables, sanitize_text_events, sanitize_substitutions,
		sanitize_bbcode, sanitize_candy_ref_symbols, sanitize_lexicon, sanitize_expressions)


#* Whether a word matches a blacklist or whitelist entry - "*" stands for any characters, "**" for a "*":
#? "mean*" matches "meanie", "*mean" "notmean", "m*n" "mean".
#? entry: a String (case-sensitive), or [String, case_sensitive] (["mean*", false] matches "Meanie").
func _word_matches(word: String, entry: Variant) -> bool:
	var text := ""
	var case_sensitive := true
	if entry is Array:
		if entry.is_empty():
			return false
		text = str(entry[0])
		if entry.size() > 1:
			case_sensitive = bool(entry[1])
	else:
		text = str(entry)

	var cache_key := text + "\n" + str(case_sensitive)
	if not _entry_patterns.has(cache_key):
		var pattern := "(?s)^"		#/ (?s): "*" crosses line breaks too
		if not case_sensitive:
			pattern = "(?is)^"
		var i := 0
		while i < text.length():
			var ch := text[i]
			if ch == "*" and i + 1 < text.length() and text[i + 1] == "*":
				pattern += "\\*"
				i += 2
				continue
			if ch == "*":
				pattern += ".*"
			elif "\\^$.|?+()[]{}".contains(ch):
				pattern += "\\" + ch
			else:
				pattern += ch
			i += 1
		var entry_regex := RegEx.new()
		entry_regex.compile(pattern + "$")
		_entry_patterns[cache_key] = entry_regex
	return _entry_patterns[cache_key].search(word) != null


#* Validate the input:
func check_input():
	input_valid = true
	var text: String = input_line_path.text

	var language := _display_language()

	#@ Step 1 - Clear previous error:
	if show_errors:
		input_error_node.text = ""

	#@ Step 2 - Split into words:
	var separators := [" ", "-", "_"]
	var words: Array[String] = [text]
	for sep in separators:
		var temp: Array[String] = []
		for w in words:
			temp.append_array(w.split(sep))
		words = temp

	#@ Step 3 - Remove empty entries:
	var filtered_words: Array[String] = []
	for w in words:
		if w.strip_edges() != "":
			filtered_words.append(w)
	words = filtered_words

	#@ Step 4 - Character length limits:
	if char_min > -1 and text.length() < char_min:
		return _fail(_tr_error("Minimum ") + str(char_min) + _tr_error(" characters required."))

	if char_max > -1 and text.length() > char_max:
		return _fail(_tr_error("Maximum ") + str(char_max) + _tr_error(" characters allowed."))

	#@ Step 5 - Word count limits:
	if word_min > -1 and words.size() < word_min:
		return _fail(_tr_error("Minimum ") + str(word_min) + _tr_error(" words required."))

	if word_max > -1 and words.size() > word_max:
		return _fail(_tr_error("Maximum ") + str(word_max) + _tr_error(" words allowed."))

	#@ Step 6 - Whitelist / blacklist:
	if whitelist.has(language) and whitelist[language].size() > 0:
		for w in words:
			var allowed := false
			for white in whitelist[language]:
				if _word_matches(w, white):
					allowed = true
					break
			if not allowed:
				return _fail(_tr_error("Word not allowed: '") + w + _tr_error("'."))

	elif blacklist.has(language) and blacklist[language].size() > 0:
		for w in words:
			for black in blacklist[language]:
				if _word_matches(w, black):
					return _fail(_tr_error("Forbidden word: '") + w + _tr_error("'."))

	#@ Step 7 - Check each character:
	var regex_letter := RegEx.new()
	regex_letter.compile("^[\\p{L}]$")

	for i in text.length():
		var ch := text.substr(i, 1)
		var code := text.unicode_at(i)
		if ch == "":
			continue

		#% Spaces:
		if ch == " " and not allow_spaces:
			return _fail(_tr_error("Spaces are not allowed."))

		#% Letters:
		if regex_letter.search(ch):
			if not allow_uppercase and ch == ch.to_upper() and ch != ch.to_lower():
				return _fail(_tr_error("Uppercase letters are not allowed."))
			elif not allow_lowercase and ch == ch.to_lower() and ch != ch.to_upper():
				return _fail(_tr_error("Lowercase letters are not allowed."))
			continue

		#% Numbers:
		if code >= 0x30 and code <= 0x39:
			if not allow_numbers:
				return _fail(_tr_error("Numbers are not allowed."))
			continue

		#% Decimal point (only if between digits):
		if ch == ".":
			var prev_is_digit := (i > 0 and text.unicode_at(i - 1) >= 0x30 and text.unicode_at(i - 1) <= 0x39)
			var next_is_digit := (i < text.length() - 1 and text.unicode_at(i + 1) >= 0x30 and text.unicode_at(i + 1) <= 0x39)
			if prev_is_digit and next_is_digit:
				if not allow_decimals:
					return _fail(_tr_error("Decimal numbers are not allowed."))
			else:
				if not allow_punctuation:
					return _fail(_tr_error("Punctuation is not allowed."))
			continue

		#% Punctuation:
		if ch in [",", ";", ":", "?", "!", "'", "\"", "(", ")", "[", "]", "{", "}", "—", "-", "_"]:
			if not allow_punctuation:
				return _fail(_tr_error("Punctuation is not allowed."))
			continue

		#% Special characters:
		if not allow_special:
			return _fail(_tr_error("Special characters are not allowed."))

	#@ Step 8 - Valid:
	input_valid = true
	return true


#* Dialogue suspended (called by Input):
#TODO: Your logic, e.g. disable buttons, show a pause notice.
func suspend_on():
	suspended = true


#* Dialogue resumed (called by Input):
#TODO: Write logic that reverts suspend_on().
func suspend_off():
	suspended = false


#* Dialogue ended:
#TODO: Write custom code as needed (e.g. close or delete the Input UI).
func dialogue_ended():
	pass


#& Helpers:
#* Translate an error fragment:
func _tr_error(raw: String) -> String:
	return CandyWriting.get_shared().translate(caller, self, raw, "input_error_messages")


#* Mark the input invalid, showing why:
func _fail(message: String) -> bool:
	input_valid = false
	if show_errors:
		input_error_node.text = "[color=red]" + message + "[/color]"
	return false


#* Display language (engine → candy_de → "Default"):
func _display_language() -> String:
	var language := ""
	if caller != null:
		language = str(caller.use_language)
	if language == "":
		language = str(candy_de.language)
	if language == "":
		language = "Default"
	return language