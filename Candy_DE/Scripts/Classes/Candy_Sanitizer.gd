#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySanitizer
extends RefCounted


#& Neutralizes Candy DE syntax in a value that didn't come from a dialogue (a player's input...).
#? Candy DE reads a stored value like any text: "¤¢globals.gold¤" is evaluated when a text variable
#? displays it (values are rescanned for text variables), "•he¦Alice•" is substituted, "[b]" formats it, "‡boom‡" runs an event, a lexicon keyword is formatted, and
#? "¢globals.gold" is evaluated wherever the value is read as an expression.
#? Each function handles one kind of syntax, and can be called on its own: CandySanitizer.bbcode(text).
#? sanitize() calls them all, in the order they must run, each one switched by its argument.
#! The symbols added stay in the value: Candy DE removes them in spoken text, other displays show them.


#* Every sanitization, in order - each argument switches one:
static func sanitize(text: String, escape_text_variables: bool = true, escape_text_events: bool = true, escape_substitutions: bool = true,
		escape_bbcode: bool = true, escape_references: bool = true, escape_lexicon: bool = true, escape_expressions: bool = true) -> String:
	if escape_text_variables:
		text = CandySanitizer.text_variables(text)
	if escape_text_events:
		text = CandySanitizer.text_events(text)
	if escape_substitutions:
		text = CandySanitizer.substitutions(text)
	if escape_bbcode:
		text = CandySanitizer.bbcode(text)
	#? Before lexicon(): its start symbol would hide a leading reference symbol.
	if escape_references:
		text = CandySanitizer.references(text)
	#? Before expressions(): an escaped value doesn't start with the expression symbol, so it's never
	#? evaluated, and a doubled symbol inside the escape would be displayed doubled.
	if escape_lexicon:
		text = CandySanitizer.lexicon(text)
	if escape_expressions:
		text = CandySanitizer.expressions(text)
	return text


#* Text variables - doubles their symbols: displayed as written, nothing in them is evaluated:
#! Without it, "¤¢some.call()¤" in a value is evaluated when a text variable displays the value.
static func text_variables(text: String) -> String:
	return _double(text, _setting("text_var_start_symbol"), _setting("text_var_end_symbol"))


#* Text events - doubles the marker symbols: displayed as written, no event runs:
static func text_events(text: String) -> String:
	return _double(text, _setting("text_event_start_symbol"), _setting("text_event_end_symbol"))


#* Word substitutions - doubles the substitution symbols: displayed as written:
static func substitutions(text: String) -> String:
	return _double(text, _setting("substitution_start_symbol"), _setting("substitution_end_symbol"))


#* BBCode - "[" becomes "[lb]": tags are displayed as written:
#! A plain Label, outside Candy DE, displays "[lb]" itself.
static func bbcode(text: String) -> String:
	return text.replace("[", "[lb]")


#* Reference symbols - removes the ones the value starts with (€, °, $, and any registered with CandyRef):
#? A value read as a reference (a speaker, a substitution's actor) isn't taken for a role or a variable.
static func references(text: String) -> String:
	var symbols: Array = [_setting("vardict_symbol"), _setting("role_symbol"), CandyRef.NODE_SYMBOL]
	var candy_ref := CandyRef.get_shared()
	symbols += candy_ref.shortcut_symbols.keys() + candy_ref.lookup_symbols.keys()
	var stripped := true
	while stripped:
		stripped = false
		for symbol in symbols:
			var value := str(symbol)
			if value != "" and text.begins_with(value):
				text = text.substr(value.length())
				stripped = true
	return text


#* Lexicon - doubles the escape symbols, then escapes the whole value: never formatted by the lexicon:
#? "Alice" becomes "¬Alice¬", displayed "Alice" in spoken text. An empty value stays empty.
static func lexicon(text: String) -> String:
	var start_symbol := _setting("lexicon_escape_start_symbol")
	var end_symbol := _setting("lexicon_escape_end_symbol")
	if text == "" or start_symbol == "" or end_symbol == "":
		return text
	return start_symbol + _double(text, start_symbol, end_symbol) + end_symbol


#* Expressions - doubles a leading expression symbol: read as text, never evaluated:
static func expressions(text: String) -> String:
	var symbol := _setting("candy_ref_symbol")
	if symbol != "" and text.begins_with(symbol):
		return symbol + text
	return text


#==============================================================================
#  LITERAL VARIABLES
#==============================================================================
#? The variables of literal_variables (Data_Tables/Literal_Variables.gd) keep their value as stored:
#? CandyRef never resolves a stored "¢…" in them, and their value is sanitized only where it's
#? displayed. An entry allows syntax by name (LITERAL_ALLOWED): ["globals.motto", ["substitutions"]].

#^ What an entry can allow:
const LITERAL_ALLOWED := ["expressions", "text_variables", "substitutions", "text_events", "lexicon", "bbcode", "references"]

static var _checked_literal_variables: int = 0		#/ Hash of the list last checked


#* A literal variable's value, inserted into spoken text - the syntax its rule doesn't allow, escaped:
#? allowed: CandyRef's last_literal (the rule's allowed names).
static func literal(text: String, allowed: Array) -> String:
	return CandySanitizer.sanitize(text,
		not allowed.has("text_variables"),
		not allowed.has("text_events"),
		not allowed.has("substitutions"),
		not allowed.has("bbcode"),
		false,			#/ References: only read where a value names an actor (CandyActors.actor_from_role())
		not allowed.has("lexicon"),
		false)			#/ Expressions: CandyRef already read the value as written


#* Whether a rule lets a literal variable's value be read a way (an allowed name). Not literal: always:
static func literal_allows(rule: Variant, allowed_name: String) -> bool:
	if not rule is Array:
		return true
	return (rule as Array).has(allowed_name)


#* Add a variable to literal_variables, unless an entry already names it the same way:
#? allowed: the syntax its value may keep (LITERAL_ALLOWED). Empty: a plain entry, everything escaped.
static func add_literal_variable(variable_reference: String, allowed: Array = []) -> void:
	var listed = candy_de.get("literal_variables")
	if not listed is Array:
		printerr("Candy DE: literal_variables (Data_Tables/Literal_Variables.gd) isn't an Array → ", variable_reference, " isn't listed.")
		return
	var name_text := variable_reference.strip_edges()
	for entry in listed:
		var entry_name = entry
		if entry is Array and not entry.is_empty():
			entry_name = entry[0]
		if str(entry_name).strip_edges() == name_text:
			return
	if allowed.is_empty():
		listed.append(name_text)
	else:
		listed.append([name_text, allowed.duplicate()])


#* Report the entries of literal_variables that can't be read, once per version of the list:
#? Rules CandyRef can't parse are reported by CandyRef, when it first locates them.
static func check_literal_variables() -> void:
	var listed = candy_de.get("literal_variables")
	if listed == null:
		return		#/ Reported as a missing table
	var fingerprint := hash(listed)
	if fingerprint == _checked_literal_variables:
		return
	_checked_literal_variables = fingerprint
	if not listed is Array:
		push_error("Candy DE: literal_variables (Data_Tables/Literal_Variables.gd) must be an Array.")
		return
	for entry in listed:
		if entry is String or entry is StringName:
			continue
		if not (entry is Array and entry.size() == 2 and (entry[0] is String or entry[0] is StringName) and entry[1] is Array):
			push_error("Candy DE: literal_variables entry %s must be a variable, or [variable, [allowed names]]: it's ignored." % var_to_str(entry))
			continue
		for allowed_name in entry[1]:
			if not str(allowed_name) in LITERAL_ALLOWED:
				push_error("Candy DE: literal_variables entry %s allows \"%s\", which isn't one of: %s." % [var_to_str(entry), allowed_name, ", ".join(LITERAL_ALLOWED)])


#* Lexicon escape symbols removed, for a display that isn't spoken text (the game's own UI):
#? "¬Alice¬" → "Alice", "¬¬" → "¬".
static func remove_lexicon_escapes(text: String) -> String:
	return CandyWriting.get_shared().remove_lexicon_escapes(null, null, text)


#==============================================================================
#  HELPERS
#==============================================================================

#* Double each symbol (the end one too, when it differs):
static func _double(text: String, start_symbol: String, end_symbol: String) -> String:
	if start_symbol != "":
		text = text.replace(start_symbol, start_symbol + start_symbol)
	if end_symbol != "" and end_symbol != start_symbol:
		text = text.replace(end_symbol, end_symbol + end_symbol)
	return text


#* A symbol of Candy_Properties.gd, "" if it has none (an older file):
static func _setting(variable: String) -> String:
	var value = candy_de.get(variable)
	if typeof(value) == TYPE_STRING:
		return value
	return ""
