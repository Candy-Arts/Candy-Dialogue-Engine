#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends RefCounted
class_name CandyRef


#?##############################################################################
#&  SYMBOLS:
#?##########
#%  The expression symbol ("¢") is passed by each add-on. Doubling it escapes:
#%    "¢globals.hp + 1"      ->  evaluated
#%    "¢¢not an expression"  ->  "¢not an expression"


#% Node lookup, relative to source:
#%   "¢$UI/Box/Label"       ->  self.get_node_or_null("UI/Box/Label")
#%   "¢$%Unique"            ->  scene-unique name, also valid as "¢$Sub/%Unique"
#%   "¢%Unique"             ->  the same, GDScript's own shorthand
#%   "¢$\"Node 1/Node 2\""  ->  quoted form
const NODE_SYMBOL := "$"

#% Shortcut symbols - symbol + name reads that key from a target expression:
#%   {"€": "candy_de.vardict"}
#%   "¢€score"       ->  candy_de.vardict["score"]
#%   "¢€\"my key\""  ->  quoted key
var shortcut_symbols: Dictionary = {}

#% Lookup symbols - the name alone reads "keys"; followed by '[' or '.', the result indexes "entries":
#%   {"°": {"keys": "candy_de.roles", "entries": "candy_de.actors"}}
#%   "¢°npc1"          ->  candy_de.roles["npc1"]                    (the actor)
#%   "¢°npc1[\"Age\"]"  ->  candy_de.actors[candy_de.roles["npc1"]]["Age"]
#%   "¢°npc1.Age"      ->  the same, with dot access
#%   "¢(°npc1).length()"  ->  parentheses keep the first meaning before a '.'
var lookup_symbols: Dictionary = {}


#?##############################################################################
#&  PUBLIC API:
#?#############

static var _shared: CandyRef = null


#* Shared CandyRef instance:
#+ Add-ons register their symbols and functions on it: symbols must not clash.
static func get_shared() -> CandyRef:
	if _shared == null:
		_shared = CandyRef.new()
	return _shared


#^ The user's own symbols:
const USER_SHORTCUTS_PATH := "res://Candy_DE/Scripts/User_Data/CandyRef_Shortcuts.gd"


#* Load CandyRef_Shortcuts.gd symbols:
func _init() -> void:
	var user_file: String = USER_SHORTCUTS_PATH
	#% The file may be missing - loaded, not preloaded:
	if not ResourceLoader.exists(user_file):
		return
	var user_script = load(user_file)
	if not _is_live_object(user_script) or not (user_script is Script):
		return
	var user_constants: Dictionary = (user_script as Script).get_script_constant_map()
	shortcut_symbols.merge(user_constants.get("SHORTCUT_SYMBOLS", {}), true)
	lookup_symbols.merge(user_constants.get("LOOKUP_SYMBOLS", {}), true)


#* Resolve a value if it is an expression, otherwise return it unchanged:
func resolve_value(source: Node, caller: Node, input_value: Variant, candy_ref_symbol: String) -> Variant:
	_start_literal_generation()
	_result_rule = null
	_symbol_stack.append(candy_ref_symbol)
	var result = _resolve_value(source, caller, input_value)
	_symbol_stack.pop_back()
	last_literal = _result_rule
	return _report(result)		#/ null on failure (error printed)


#% True if the last resolve_value(), resolve_candy_ref() or resolve_target() failed:
#? A valid expression can return null too: check this when it matters.
var last_failed: bool = false


#* Resolve a CandyRef (symbol stripped) into a value:
func resolve_candy_ref(source: Node, caller: Node, candy_ref: String, candy_ref_symbol: String) -> Variant:
	#? Stored strings are only evaluated when they start with candy_ref_symbol.
	_start_literal_generation()
	_result_rule = null
	_symbol_stack.append(candy_ref_symbol)
	var result = _resolve(source, caller, candy_ref)
	_symbol_stack.pop_back()
	last_literal = _result_rule
	return _report(result)		#/ null on failure (error printed)


#* Find the variable a target names, for writing:
#? Returns {"ok", "container", "key", "members", "base_call", "error"}.
#? members: steps into a copied value (Vector2, Color...): change them on container[key], then write it back.
#? base_call: {"name", "args", "value"} of the call the chain starts at (e.g. file_var()), so the caller can save the file.
func resolve_target(source: Node, caller: Node, target: Variant, candy_ref_symbol: String) -> Dictionary:
	_symbol_stack.append(candy_ref_symbol)
	var result = _resolve_target(source, caller, target)
	_symbol_stack.pop_back()

	if _is_err(result):
		_report(result)
		return {"ok": false, "container": null, "key": null, "members": [], "base_call": {}, "error": (result as EvalError).message}		#/ Failure (error printed)
	last_failed = false
	return result


#?##############################################################################
#&  LITERAL VARIABLES:
#?#####################
#% Variables whose value is read as written: a stored "¢…" in them is never resolved.
#% literal_rules_source returns the rules, an Array of entries:
#%   "globals.player_name"                          ->  literal
#%   ["globals.player_motto", ["substitutions"]]    ->  literal, except the names the Array allows
#% Each key of a rule is a key, a pattern or a filter:
#%   ["Player_1"]        ->  that key
#%   ["Player_*"]        ->  keys matching the pattern (String.match(): * and ?)
#%   [String]            ->  keys of that type
#%   [globals.slot]      ->  the key the expression gives, evaluated once per expression
#% A read from a listed variable sets last_literal to its rule's allowed names, for callers to
#% escape what CandyRef doesn't read (spoken text syntax); null otherwise.
#! Variables are matched by where they're stored (the object or collection, and the key), so every
#! spelling of a reference matches. The rules are located once per expression.

#^ The allowed name that lets CandyRef resolve a stored "¢…" in a literal variable:
const LITERAL_EXPRESSIONS := "expressions"

#^ Returns the rules (an Array), or anything else for none:
var literal_rules_source: Callable = Callable()

#% The last resolve_value() or resolve_candy_ref() gave a literal variable's value as it is:
#? Its rule's allowed names (an Array, maybe empty), or null.
var last_literal: Variant = null

var _literal_generation: int = 0
var _literal_slots: Array = []				#/ {"container", "mode", "key", "allowed"} per located variable
var _literal_slots_generation: int = -1
var _locating_literals: bool = false
var _last_read_rule: Variant = null			#/ The latest variable read's rule
var _result_rule: Variant = null			#/ The rule of the value the expression gave
#^ An expression that read a literal variable - what it computes comes from that value:
var _taint_rule: Variant = null			#/ The allowed names every literal read shares
var _taint_blocks_resolve: bool = false		#/ A literal read didn't allow "expressions"
var _reported_literal_rules: Dictionary = {}


#* The rule of a variable, given where it's stored - its allowed names, or null if it isn't literal:
#? For code that reads a variable itself (an actor's name...).
func literal_rule(source: Node, caller: Node, container: Variant, key: Variant, candy_ref_symbol: String) -> Variant:
	_start_literal_generation()
	_symbol_stack.append(candy_ref_symbol)
	var rule = _literal_rule(source, caller, container, key)
	_symbol_stack.pop_back()
	return rule


#* A new expression: the rules are located again, as variables may have changed:
func _start_literal_generation() -> void:
	if _resolve_depth == 0 and not _locating_literals:
		_literal_generation += 1
		_taint_rule = null
		_taint_blocks_resolve = false


#* A variable's value as read - resolved, unless the variable is literal:
func _read_variable(source: Node, caller: Node, container: Variant, key: Variant, value: Variant) -> Variant:
	var rule = _literal_rule(source, caller, container, key)
	_last_read_rule = rule
	if rule == null:
		return _resolve_value(source, caller, value)		#/ Not _resolve_read(): a stored reference still resolves
	_taint(rule as Array)
	if not (rule as Array).has(LITERAL_EXPRESSIONS):
		return value
	return _resolve_value(source, caller, value)


#* Note a literal read: what the expression computes from now on comes from that value:
#? Its allowed names narrow to what every literal read so far allows.
func _taint(allowed: Array) -> void:
	if not allowed.has(LITERAL_EXPRESSIONS):
		_taint_blocks_resolve = true
	if _taint_rule == null:
		_taint_rule = allowed.duplicate()
		return
	var shared: Array = []
	for allowed_name in _taint_rule:
		if allowed.has(allowed_name):
			shared.append(allowed_name)
	_taint_rule = shared


func _literal_rule(source: Node, caller: Node, container: Variant, key: Variant) -> Variant:
	if _locating_literals or not literal_rules_source.is_valid():
		return null
	if not typeof(container) in [TYPE_OBJECT, TYPE_DICTIONARY, TYPE_ARRAY]:
		return null
	if _literal_slots_generation != _literal_generation:
		_locate_literal_slots(source, caller)
	for slot in _literal_slots:
		if is_same(slot["container"], container) and _literal_key_matches(slot, key):
			return slot["allowed"]
	return null


#* Find where every rule's variables are stored:
func _locate_literal_slots(source: Node, caller: Node) -> void:
	_literal_slots_generation = _literal_generation
	_literal_slots = []
	var rules = literal_rules_source.call()
	if not rules is Array or (rules as Array).is_empty():
		return

	#? Reads made while locating don't check the rules (no loop), and don't count as the expression's.
	_locating_literals = true
	var saved_failed := last_failed
	var saved_read = _last_read_rule
	for rule in rules:
		var rule_reference := ""
		var allowed: Array = []
		if rule is String or rule is StringName:
			rule_reference = str(rule)
		elif rule is Array and rule.size() == 2 and (rule[0] is String or rule[0] is StringName) and rule[1] is Array:
			rule_reference = str(rule[0])
			allowed = rule[1]
		else:
			continue		#/ Reported by the add-on (Candy DE: CandySanitizer.check_literal_variables())

		rule_reference = rule_reference.strip_edges()
		var symbol := _current_symbol()
		if symbol != "" and rule_reference.begins_with(symbol):
			rule_reference = rule_reference.substr(symbol.length())
		var parsed := parse_candy_ref(source, caller, rule_reference)
		if not parsed["ok"]:
			_report_literal_rule(str(rule), parsed["error"])
			continue
		for slot in _pattern_slots(source, caller, parsed["ast"], str(rule)):
			slot["allowed"] = allowed
			_literal_slots.append(slot)
	_last_read_rule = saved_read
	last_failed = saved_failed
	_locating_literals = false


#* Report a rule's problem once:
func _report_literal_rule(rule: String, problem: String) -> void:
	if _reported_literal_rules.has(rule):
		return
	_reported_literal_rules[rule] = true
	push_error("CandyRef: literal variable rule %s can't be used: %s" % [rule, problem])


#* Where a rule's variables are stored - [{"container", "mode", "key"}]:
func _pattern_slots(source: Node, caller: Node, ast: Dictionary, rule: String) -> Array:
	var slots: Array = []
	match ast["type"]:
		"attribute":
			for owner in _pattern_values(source, caller, ast["object"]):
				slots.append({"container": owner, "mode": "exact", "key": ast["name"]})
		"index":
			var key_test := _pattern_key(source, caller, ast["key"])
			if key_test.is_empty():
				return slots
			for owner in _pattern_values(source, caller, ast["object"]):
				var slot: Dictionary = key_test.duplicate()
				slot["container"] = owner
				slots.append(slot)
		"name":
			var found = _name_target(source, caller, ast["name"])
			if not _is_err(found):
				slots.append({"container": found["container"], "mode": "exact", "key": found["key"]})
		_:
			_report_literal_rule(rule, "it must name a variable (a.b or a[b]), not an expression")
	return slots


#* The values a rule's path reaches, patterns and filters followed:
func _pattern_values(source: Node, caller: Node, node: Dictionary) -> Array:
	var values: Array = []
	match node["type"]:
		"attribute":
			for owner in _pattern_values(source, caller, node["object"]):
				values.append_array(_pattern_members(owner, {"mode": "exact", "key": node["name"]}))
		"index":
			var key_test := _pattern_key(source, caller, node["key"])
			if key_test.is_empty():
				return values
			for owner in _pattern_values(source, caller, node["object"]):
				values.append_array(_pattern_members(owner, key_test))
		_:
			var value = evaluate_node(source, caller, node)
			if not _is_err(value):
				values.append(value)
	return values


#* A rule's key - {"mode": "exact" | "pattern" | "type", "key"}, or {} if it can't be evaluated:
func _pattern_key(source: Node, caller: Node, key_node: Dictionary) -> Dictionary:
	if key_node["type"] == "literal" and _is_text(key_node["value"]):
		var text := str(key_node["value"])
		if text.contains("*") or text.contains("?"):
			return {"mode": "pattern", "key": text}
	if key_node["type"] == "name" and _variant_type_id(key_node["name"]) >= 0:
		return {"mode": "type", "key": _variant_type_id(key_node["name"])}
	var key = evaluate_node(source, caller, key_node)
	if _is_err(key):
		return {}
	return {"mode": "exact", "key": key}


#* The members of a value a key test matches:
func _pattern_members(owner: Variant, key_test: Dictionary) -> Array:
	var members: Array = []
	match typeof(owner):
		TYPE_DICTIONARY:
			for key in owner:
				if _literal_key_matches(key_test, key):
					members.append(owner[key])
		TYPE_ARRAY:
			for i in (owner as Array).size():
				if _literal_key_matches(key_test, i):
					members.append(owner[i])
		TYPE_OBJECT:
			#? Objects only by name: their properties can't be listed by a pattern or a type.
			if key_test["mode"] == "exact" and _is_text(key_test["key"]) and is_instance_valid(owner) and str(key_test["key"]) in owner:
				members.append(owner.get(str(key_test["key"])))
	return members


#* Whether a key passes a key test:
func _literal_key_matches(key_test: Dictionary, key: Variant) -> bool:
	match key_test["mode"]:
		"pattern":
			return str(key).match(str(key_test["key"]))
		"type":
			#? String and StringName count as one type.
			if key_test["key"] == TYPE_STRING or key_test["key"] == TYPE_STRING_NAME:
				return _is_text(key)
			return typeof(key) == key_test["key"]
	var expected = key_test["key"]
	if _is_text(expected) and _is_text(key):
		return str(expected) == str(key)
	return typeof(expected) == typeof(key) and expected == key


#* Symbol of the call being evaluated:
func _current_symbol() -> String:
	if _symbol_stack.is_empty():
		return ""
	return _symbol_stack.back()


#* Whether a String starts with the symbol:
func _is_expression(text: String) -> bool:
	var symbol := _current_symbol()
	return symbol != "" and text.begins_with(symbol)


#* Print an EvalError and return null:
func _report(result: Variant) -> Variant:
	last_failed = _is_err(result)
	if not last_failed:
		return result

	var error := result as EvalError
	var lines := ["CandyRef failed: " + error.message]

	#Ł Long chains - keep both ends:
	var chain := error.chain
	for index in chain.size():
		var is_middle := index >= 4 and index < chain.size() - 4
		if not is_middle:
			lines.append("  in: " + chain[index])
		elif index == 4:
			lines.append("  ... (%d more)" % (chain.size() - 8))

	push_error("\n".join(lines))
	return null


#* resolve_value() without reporting - value or EvalError:
func _resolve_value(source: Node, caller: Node, input_value: Variant) -> Variant:
	#¦ 1. Non-Strings pass through:
	if typeof(input_value) != TYPE_STRING:
		return input_value

	var text: String = input_value

	#¦ 2. Plain text:
	if not _is_expression(text):
		return text

	var symbol := _current_symbol()
	var body := text.substr(symbol.length())

	#¦ 3. Escaped ("¢¢...") - strip one symbol:
	if body.begins_with(symbol):
		return body

	#¦ 4. Expression - strip the symbol:
	return _resolve(source, caller, body)


#* resolve_candy_ref() without reporting - value or EvalError:
func _resolve(source: Node, caller: Node, candy_ref: String) -> Variant:
	#% Circular ref guard:
	if _resolve_depth >= max_resolve_depth:
		var depth_error := _err("Exceeded max_resolve_depth (%d). Circular reference?" % max_resolve_depth)
		depth_error.chain.append(candy_ref)
		return depth_error

	var parsed = parse_candy_ref(source, caller, candy_ref)

	if not parsed["ok"]:
		return _err("Parse error: " + parsed["error"])

	_resolve_depth += 1
	var value = evaluate_node(source, caller, parsed["ast"])
	_resolve_depth -= 1

	#% The value of a variable, read as it is - its literal rule, if any:
	#? Computed from one (name + "!"): the rule every literal read shares.
	if parsed["ast"]["type"] in ["name", "attribute", "index"] and _last_read_rule != null:
		_result_rule = _last_read_rule
	else:
		_result_rule = _taint_rule

	if _is_err(value):
		var error := value as EvalError
		#Ł Now a real failure, so an outer scope search won't skip it:
		error.not_found = false
		#Ł Add this level to the chain:
		error.chain.append(candy_ref)
		return error

	return value


#* True if the string is syntactically a valid CandyRef expression:
func is_valid_candy_ref(source: Node, caller: Node, candy_ref: String) -> bool:
	return parse_candy_ref(source, caller, candy_ref)["ok"]


#* Parse a CandyRef string:
func parse_candy_ref(source: Node, caller: Node, candy_ref: String) -> Dictionary:
	#Ł Cached trees (a symbol change clears them):
	_refresh_symbols()
	if _ast_cache.has(candy_ref):
		return _ast_cache[candy_ref]

	var lexed = tokenize(source, caller, candy_ref)

	if not lexed["ok"]:
		return _cache_ast(candy_ref, {
			"ok": false,
			"ast": null,
			"error": _format_error(candy_ref, lexed["error"], lexed["error_pos"]),
		})

	var parser = Parser.new(self, source, caller, lexed["tokens"])
	var result = parser.parse()

	if not result["ok"]:
		return _cache_ast(candy_ref, {
			"ok": false,
			"ast": null,
			"error": _format_error(candy_ref, result["error"], result["error_pos"]),
		})

	return _cache_ast(candy_ref, {"ok": true, "ast": result["ast"], "error": ""})


#* Clear the AST cache:
func clear_cache() -> void:
	_ast_cache.clear()


#* Parse a symbol's target expression:
func _parse_symbol_target(target: String) -> Dictionary:
	#% Self-referencing target:
	if _expanding_targets.has(target):
		return {"ok": false, "ast": null, "error": "Symbol target \"%s\" refers back to itself" % target}
	_expanding_targets[target] = true
	var parsed := parse_candy_ref(null, null, target)
	_expanding_targets.erase(target)
	return parsed


#! ASTs are returned by reference: never mutate one.
func _cache_ast(key: String, result: Dictionary) -> Dictionary:
	if max_ast_cache >= 0 and _ast_cache.size() >= max_ast_cache:
		#? Full clear rather than LRU: dialogues reuse few expressions.
		_ast_cache.clear()
	_ast_cache[key] = result
	return result


#* Debug - print the AST of a CandyRef:
func debug_print_ast(source: Node, caller: Node, candy_ref: String) -> void:
	var parsed = parse_candy_ref(source, caller, candy_ref)
	if parsed["ok"]:
		print(JSON.stringify(parsed["ast"], "\t"))
	else:
		print(parsed["error"])


#?##############################################################################
#&  TOKENIZER
#?##############################################################################
#%	Turns "globals.hp * (3 + 5)" into a flat list of tokens:
#%		NAME(globals) OP(.) NAME(hp) OP(*) OP(() NUMBER(3) OP(+) NUMBER(5) OP()) EOF
#%
#%	Token shape: { "type": String, "value": Variant, "pos": int }
#%	Types: "NUMBER", "STRING", "NAME", "OP", "SIGIL", "EOF"
#%
#%	SIGIL tokens also carry "name": an identifier (€ °) or a node path ($).

const _DIGITS := "0123456789"
const _HEX_DIGITS := "0123456789abcdefABCDEF"

#? Longest first, so "==" isn't read as "=" "=".
const _OPERATORS := [
	"**", "==", "!=", "<=", ">=", "&&", "||", "<<", ">>",
	"+", "-", "*", "/", "%",
	"<", ">", "!", "&", "|", "^", "~",
	"(", ")", "[", "]", "{", "}",
	",", ".", ":", "=",
]


#* Split a CandyRef string into tokens:
@warning_ignore("unused_parameter")
func tokenize(source: Node, caller: Node, text: String) -> Dictionary:
	#Ł Refresh symbols if changed:
	_refresh_symbols()

	var tokens: Array = []
	var i := 0
	var n := text.length()

	while i < n:
		var c := text[i]

		#¦ 1. Whitespace:
		if c == " " or c == "\t" or c == "\n" or c == "\r":
			i += 1
			continue

		#¦ 2. Numbers:
		if _is_digit(c) or (c == "." and i + 1 < n and _is_digit(text[i + 1])):
			var start := i

			#¦ 1. Hexadecimal and binary, underscores allowed (0xFF_FF, 0b1010_0101):
			if c == "0" and i + 1 < n and "xXbB".contains(text[i + 1]):
				var is_hex := "xX".contains(text[i + 1])
				var valid_digits := "01"
				if is_hex:
					valid_digits = _HEX_DIGITS
				i += 2
				while i < n and (valid_digits.contains(text[i]) or text[i] == "_"):
					i += 1
				var digits := text.substr(start + 2, i - start - 2).replace("_", "")
				if digits == "":
					if is_hex:
						return _lex_error("Malformed hexadecimal number", start)
					return _lex_error("Malformed binary number", start)
				if is_hex:
					tokens.append(_make_token("NUMBER", digits.hex_to_int(), start))
				else:
					tokens.append(_make_token("NUMBER", digits.bin_to_int(), start))
				continue

			#¦ 2. Decimal:
			var is_float := false
			while i < n and (_is_digit(text[i]) or text[i] == "_"):
				i += 1
			if i < n and text[i] == ".":
				if i + 1 < n and _is_digit(text[i + 1]):
					is_float = true
					i += 1
					while i < n and (_is_digit(text[i]) or text[i] == "_"):
						i += 1
				elif i + 1 >= n or not (_is_ident_start(text[i + 1]) or text[i + 1] == "."):
					#? Bare trailing dot ("1.") is a float; "1.abs()" stays an int + method call.
					is_float = true
					i += 1
			if i < n and (text[i] == "e" or text[i] == "E"):
				var j := i + 1
				if j < n and (text[j] == "+" or text[j] == "-"):
					j += 1
				if j < n and _is_digit(text[j]):
					is_float = true
					i = j
					while i < n and _is_digit(text[i]):
						i += 1

			var literal := text.substr(start, i - start).replace("_", "")
			if is_float:
				tokens.append(_make_token("NUMBER", float(literal), start))
			else:
				tokens.append(_make_token("NUMBER", int(literal), start))
			continue

		#¦ 3. Strings, StringName (&"name") and NodePath (^"path"):
		#? & and ^ only prefix when a quote follows; otherwise bitwise.
		var is_quote := c == "\"" or c == "'"
		var has_prefix := (c == "&" or c == "^") and i + 1 < n and (text[i + 1] == "\"" or text[i + 1] == "'")
		if is_quote or has_prefix:
			var start_str := i
			var quote_pos := i
			if has_prefix:
				quote_pos = i + 1

			var scanned_str := _scan_string(text, quote_pos)
			if not scanned_str["ok"]:
				return _lex_error(scanned_str["error"], scanned_str["error_pos"])

			var literal_value: Variant = scanned_str["value"]
			if c == "&":
				literal_value = StringName(scanned_str["value"])
			elif c == "^":
				literal_value = NodePath(scanned_str["value"])

			tokens.append(_make_token("STRING", literal_value, start_str))
			i = scanned_str["end"]
			continue

		#¦ 4. Sigils (€score, °npc1, $UI/Box/Label, $"Node 1/Node 2"):
		var sigil := _match_sigil(text, i)
		if sigil != "":
			var name_start := i + sigil.length()
			var scanned := ""
			var name_end := name_start

			var quoted_name := name_start < n and (text[name_start] == "\"" or text[name_start] == "'")

			if sigil == NODE_SYMBOL and quoted_name:
				#¦ 1. Quoted path:
				var quoted := _scan_quoted_path(text, name_start)
				if not quoted["ok"]:
					return _lex_error(quoted["error"], name_start)
				scanned = quoted["name"]
				name_end = quoted["end"]
			elif quoted_name:
				#¦ 2. Quoted key for a shortcut or lookup symbol (€"my key"):
				var quoted_key := _scan_string(text, name_start)
				if not quoted_key["ok"]:
					return _lex_error(quoted_key["error"], quoted_key["error_pos"])
				scanned = quoted_key["value"]
				name_end = quoted_key["end"]
				if scanned == "":
					return _lex_error("Empty key after '%s'" % sigil, i)
			elif sigil == NODE_SYMBOL:
				scanned = _scan_node_path(text, name_start)
				name_end = name_start + scanned.length()
			else:
				scanned = _scan_identifier(text, name_start)
				name_end = name_start + scanned.length()

			if scanned == "":
				return _lex_error("Expected a name after '%s'" % sigil, i)

			var sigil_token := _make_token("SIGIL", sigil, i)
			sigil_token["name"] = scanned
			tokens.append(sigil_token)
			i = name_end
			continue

		#¦ 5. Identifiers and keywords:
		if _is_ident_start(c):
			var start_name := i
			while i < n and _is_ident_char(text[i]):
				i += 1
			tokens.append(_make_token("NAME", text.substr(start_name, i - start_name), start_name))
			continue

		#¦ 6. Operators and punctuation:
		var matched := ""
		for op in _OPERATORS:
			if text.substr(i, op.length()) == op:
				matched = op
				break
		if matched != "":
			tokens.append(_make_token("OP", matched, i))
			i += matched.length()
			continue

		#¦ 7. Anything else is invalid:
		return _lex_error("Unexpected character '%s'" % c, i)

	tokens.append(_make_token("EOF", "", n))
	return {"ok": true, "tokens": tokens, "error": "", "error_pos": -1}


func _make_token(type: String, value: Variant, pos: int) -> Dictionary:
	return {"type": type, "value": value, "pos": pos}


func _lex_error(message: String, pos: int) -> Dictionary:
	return {"ok": false, "tokens": [], "error": message, "error_pos": pos}


func _is_digit(c: String) -> bool:
	return _DIGITS.contains(c)


#* Scan a quoted string, decoding escapes:
func _scan_string(text: String, start: int) -> Dictionary:
	var quote := text[start]
	var n := text.length()
	var i := start + 1
	var built := ""

	while i < n:
		var ch := text[i]

		#¦ 1. Closing quote:
		if ch == quote:
			return {"ok": true, "value": built, "end": i + 1, "error": "", "error_pos": -1}

		if ch != "\\":
			built += ch
			i += 1
			continue

		#¦ 2. Escape sequence:
		if i + 1 >= n:
			return {"ok": false, "error": "Unterminated escape sequence", "error_pos": i}
		var esc := text[i + 1]

		#% \uXXXX and \UXXXXXX, joining UTF-16 surrogate pairs:
		if esc == "u" or esc == "U":
			var width := 4
			if esc == "U":
				width = 6
			var code := _read_hex_escape(text, i + 2, width)
			if code < 0:
				return {"ok": false, "error": "Invalid \\%s escape, expected %d hex digits" % [esc, width], "error_pos": i}
			i += 2 + width

			if code >= 0xD800 and code <= 0xDBFF:
				var low := -1
				if text.substr(i, 2) == "\\u":
					low = _read_hex_escape(text, i + 2, 4)
				if low < 0xDC00 or low > 0xDFFF:
					return {"ok": false, "error": "Unpaired UTF-16 surrogate in escape", "error_pos": i}
				code = 0x10000 + ((code - 0xD800) << 10) + (low - 0xDC00)
				i += 6
			elif code >= 0xDC00 and code <= 0xDFFF:
				return {"ok": false, "error": "Unpaired UTF-16 surrogate in escape", "error_pos": i}

			built += String.chr(code)
			continue

		match esc:
			"n": built += "\n"
			"t": built += "\t"
			"r": built += "\r"
			"a": built += String.chr(7)
			"b": built += String.chr(8)
			"f": built += String.chr(12)
			"v": built += String.chr(11)
			"0": built += String.chr(0)
			"\\": built += "\\"
			"\"": built += "\""
			"'": built += "'"
			_: built += esc
		i += 2

	return {"ok": false, "error": "Unterminated string literal", "error_pos": start}


#* Value of `width` hex digits at `start`, or -1:
func _read_hex_escape(text: String, start: int, width: int) -> int:
	if start + width > text.length():
		return -1
	var digits := text.substr(start, width)
	for index in width:
		if not _HEX_DIGITS.contains(digits[index]):
			return -1
	return digits.hex_to_int()


#* Rebuild the sigil list and the characters barred from identifiers:
func _refresh_symbols() -> void:
	var fingerprint := "%d|%d" % [shortcut_symbols.hash(), lookup_symbols.hash()]
	if fingerprint == _symbol_fingerprint:
		return
	_symbol_fingerprint = fingerprint

	#@ Step 1 - Sigils, longest first (a longer symbol wins over its prefix):
	#? The expression symbol isn't one: it's stripped before parsing.
	var symbols: Array[String] = [NODE_SYMBOL]
	for symbol in shortcut_symbols.keys() + lookup_symbols.keys():
		if typeof(symbol) == TYPE_STRING and symbol != "" and not symbols.has(symbol):
			symbols.append(symbol)
	symbols.sort_custom(func(a, b): return a.length() > b.length())
	_sigils = symbols

	#@ Step 2 - Symbol characters can't be in names:
	_symbol_chars.clear()
	for symbol in symbols:
		for index in symbol.length():
			_symbol_chars[symbol[index]] = true

	#@ Step 3 - Clear cached expansions:
	clear_cache()


#* Longest matching sigil at position i, or "" if there is none:
func _match_sigil(text: String, i: int) -> String:
	for sigil in _sigils:
		if text.substr(i, sigil.length()) == sigil:
			return sigil
	return ""


func _scan_identifier(text: String, start: int) -> String:
	var i := start
	if i >= text.length() or not _is_ident_start(text[i]):
		return ""
	while i < text.length() and _is_ident_char(text[i]):
		i += 1
	return text.substr(start, i - start)


#* Scan a node path ('/' allowed):
func _scan_node_path(text: String, start: int) -> String:
	var i := start
	while i < text.length():
		var c := text[i]

		if _is_ident_char(c) or c == "/":
			i += 1
			continue

		#¦ 1. '%' at a segment start is a unique name; elsewhere modulo ("$Node%2"):
		if c == "%" and (i == start or text[i - 1] == "/"):
			i += 1
			continue

		#¦ 2. Stop at whitespace, so "$Node / 2" still divides:
		break

	return text.substr(start, i - start)


#* Scan a quoted node path ($"Node 1/Node 2"):
func _scan_quoted_path(text: String, start: int) -> Dictionary:
	var quote := text[start]
	var i := start + 1
	var built := ""

	while i < text.length():
		if text[i] == quote:
			return {"ok": true, "name": built, "end": i + 1, "error": ""}
		built += text[i]
		i += 1

	return {"ok": false, "name": "", "end": start, "error": "Unterminated node path"}


func _is_ident_start(c: String) -> bool:
	#% Symbol characters are never identifiers:
	#! Without this, '°' and '€' (above code point 127) would pass the non-latin test.
	if _symbol_chars.has(c):
		return false
	if c == "_":
		return true
	var code := c.unicode_at(0)
	if (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
		return true
	return code > 127 # Allow accented / non-latin identifiers.


func _is_ident_char(c: String) -> bool:
	return _is_ident_start(c) or _is_digit(c)


#* Error message with a caret at pos:
func _format_error(text: String, message: String, pos: int) -> String:
	if pos < 0:
		return message
	var caret := " ".repeat(maxi(pos, 0))
	return "%s\n  %s\n  %s^" % [message, text, caret]


#==============================================================================
#  PARSER
#==============================================================================
#  Recursive descent: one function per precedence level, loosest first.
#
#    ternary  ->  or  ->  xor  ->  and  ->  not  ->  comparison
#             ->  |  ->  ^  ->  &  ->  << >>  ->  + -  ->  * / %
#             ->  unary  ->  **  ->  postfix ( . [] () )  ->  primary
#
#  AST node shapes:
#    {"type": "literal",   "value": Variant}
#    {"type": "name",      "name": String}
#    {"type": "attribute", "object": Node, "name": String}
#    {"type": "index",     "object": Node, "key": Node}
#    {"type": "call",      "callee": Node, "args": Array}
#    {"type": "unary",     "op": String, "operand": Node}
#    {"type": "binary",    "op": String, "left": Node, "right": Node}
#    {"type": "compare",   "op": String, "left": Node, "right": Node}
#    {"type": "logic",     "op": String, "left": Node, "right": Node}
#    {"type": "ternary",   "cond": Node, "then": Node, "otherwise": Node}
#    {"type": "array",     "elements": Array}
#    {"type": "dict",      "pairs": Array}   # each pair: {"key": Node, "value": Node}
#    {"type": "typecheck", "value": Node, "type_name": String, "negated": bool}
#    {"type": "typecast",  "value": Node, "type_name": String}
#
#  Sigils expand into the shapes above: the evaluator never sees them.

class Parser extends RefCounted:

	const COMPARE_OPS := ["==", "!=", "<=", ">=", "<", ">"]
	const RESERVED := ["if", "else", "and", "or", "not", "in", "xor", "is", "as"]

	var owner: Variant #% Owning CandyRef, for symbol config
	var source: Node
	var caller: Node
	var tokens: Array
	var index: int = 0
	var error: String = ""
	var error_pos: int = -1


	func _init(p_owner: Variant, p_source: Node, p_caller: Node, p_tokens: Array) -> void:
		owner = p_owner
		source = p_source
		caller = p_caller
		tokens = p_tokens


	#* Entry point, returns { "ok", "ast", "error", "error_pos" }:
	func parse() -> Dictionary:
		var node = _parse_expression()

		if node == null:
			if error.is_empty():
				_set_error("Could not parse expression")
			return {"ok": false, "ast": null, "error": error, "error_pos": error_pos}

		if _peek()["type"] != "EOF":
			_set_error("Unexpected trailing input")
			return {"ok": false, "ast": null, "error": error, "error_pos": error_pos}

		return {"ok": true, "ast": node, "error": "", "error_pos": -1}


	#--------------------------------------------------------------- helpers

	func _peek() -> Dictionary:
		return tokens[index]


	func _peek_ahead(offset: int) -> Dictionary:
		var i := index + offset
		if i >= tokens.size():
			return tokens[tokens.size() - 1]
		return tokens[i]


	func _at_op(op: String) -> bool:
		var t = _peek()
		return t["type"] == "OP" and t["value"] == op


	func _at_name(word: String) -> bool:
		var t = _peek()
		return t["type"] == "NAME" and t["value"] == word


	func _accept_op(op: String) -> bool:
		if _at_op(op):
			index += 1
			return true
		return false


	func _accept_name(word: String) -> bool:
		if _at_name(word):
			index += 1
			return true
		return false


	func _expect_op(op: String) -> bool:
		if _accept_op(op):
			return true
		_set_error("Expected '%s'" % op)
		return false


	#* Set an error without the ", but found ..." suffix:
	func _set_plain_error(message: String) -> void:
		if not error.is_empty():
			return
		error = message
		error_pos = _peek()["pos"]


	func _set_error(message: String) -> void:
		#% Keep the first error:
		if not error.is_empty():
			return
		var t = _peek()
		if t["type"] == "EOF":
			error = "%s, but the expression ended" % message
		else:
			error = "%s, but found '%s'" % [message, str(t["value"])]
		error_pos = t["pos"]


	#--------------------------------------------------------------- grammar

	func _parse_expression() -> Variant:
		var node = _parse_ternary()
		if node == null:
			return null

		#? 'as' binds looser than everything else, including the ternary.
		while _at_name("as"):
			index += 1
			var type_name := _parse_type_name()
			if type_name == "":
				return null
			node = {"type": "typecast", "value": node, "type_name": type_name}

		return node


	#* Type name for 'is' / 'as' (RESERVED doesn't apply):
	func _parse_type_name() -> String:
		var t = _peek()
		if t["type"] != "NAME":
			_set_error("Expected a type name")
			return ""
		index += 1
		return t["value"]


	#* value if condition else other_value:
	func _parse_ternary() -> Variant:
		var node = _parse_or()
		if node == null:
			return null

		if _at_name("if"):
			index += 1
			var condition = _parse_or()
			if condition == null:
				return null
			if not _accept_name("else"):
				_set_error("Expected 'else' to complete the ternary expression")
				return null
			var otherwise = _parse_ternary()
			if otherwise == null:
				return null
			return {"type": "ternary", "cond": condition, "then": node, "otherwise": otherwise}

		return node


	func _parse_or() -> Variant:
		var node = _parse_xor()
		if node == null:
			return null
		while _at_name("or") or _at_op("||"):
			index += 1
			var right = _parse_xor()
			if right == null:
				return null
			node = {"type": "logic", "op": "or", "left": node, "right": right}
		return node


	func _parse_xor() -> Variant:
		var node = _parse_and()
		if node == null:
			return null
		while _at_name("xor"):
			index += 1
			var right = _parse_and()
			if right == null:
				return null
			node = {"type": "logic", "op": "xor", "left": node, "right": right}
		return node


	func _parse_and() -> Variant:
		var node = _parse_not()
		if node == null:
			return null
		while _at_name("and") or _at_op("&&"):
			index += 1
			var right = _parse_not()
			if right == null:
				return null
			node = {"type": "logic", "op": "and", "left": node, "right": right}
		return node


	func _parse_not() -> Variant:
		if _at_name("not") or _at_op("!"):
			index += 1
			var operand = _parse_not()
			if operand == null:
				return null
			return {"type": "unary", "op": "not", "operand": operand}
		return _parse_comparison()


	func _parse_comparison() -> Variant:
		var node = _parse_bit_or()
		if node == null:
			return null

		while true:
			var op := ""
			var t = _peek()

			if t["type"] == "OP" and COMPARE_OPS.has(t["value"]):
				op = t["value"]
				index += 1
			elif _at_name("in"):
				op = "in"
				index += 1
			elif _at_name("not") and _peek_ahead(1)["type"] == "NAME" and _peek_ahead(1)["value"] == "in":
				op = "not in"
				index += 2
			else:
				break

			var right = _parse_bit_or()
			if right == null:
				return null
			node = {"type": "compare", "op": op, "left": node, "right": right}

		return node


	func _parse_bit_or() -> Variant:
		var node = _parse_bit_xor()
		if node == null:
			return null
		while _at_op("|"):
			index += 1
			var right = _parse_bit_xor()
			if right == null:
				return null
			node = {"type": "binary", "op": "|", "left": node, "right": right}
		return node


	func _parse_bit_xor() -> Variant:
		var node = _parse_bit_and()
		if node == null:
			return null
		while _at_op("^"):
			index += 1
			var right = _parse_bit_and()
			if right == null:
				return null
			node = {"type": "binary", "op": "^", "left": node, "right": right}
		return node


	func _parse_bit_and() -> Variant:
		var node = _parse_shift()
		if node == null:
			return null
		while _at_op("&"):
			index += 1
			var right = _parse_shift()
			if right == null:
				return null
			node = {"type": "binary", "op": "&", "left": node, "right": right}
		return node


	func _parse_shift() -> Variant:
		var node = _parse_additive()
		if node == null:
			return null
		while _at_op("<<") or _at_op(">>"):
			var op = _peek()["value"]
			index += 1
			var right = _parse_additive()
			if right == null:
				return null
			node = {"type": "binary", "op": op, "left": node, "right": right}
		return node


	func _parse_additive() -> Variant:
		var node = _parse_multiplicative()
		if node == null:
			return null
		while _at_op("+") or _at_op("-"):
			var op = _peek()["value"]
			index += 1
			var right = _parse_multiplicative()
			if right == null:
				return null
			node = {"type": "binary", "op": op, "left": node, "right": right}
		return node


	func _parse_multiplicative() -> Variant:
		var node = _parse_unary()
		if node == null:
			return null
		while _at_op("*") or _at_op("/") or _at_op("%"):
			var op = _peek()["value"]
			index += 1
			var right = _parse_unary()
			if right == null:
				return null
			node = {"type": "binary", "op": op, "left": node, "right": right}
		return node


	func _parse_unary() -> Variant:
		if _at_op("-") or _at_op("+") or _at_op("~"):
			var op = _peek()["value"]
			index += 1
			var operand = _parse_unary()
			if operand == null:
				return null
			return {"type": "unary", "op": op, "operand": operand}
		return _parse_is()


	#* x is Type / x is not Type, binding tighter than unary as in GDScript:
	func _parse_is() -> Variant:
		var node = _parse_power()
		if node == null:
			return null

		while _at_name("is"):
			index += 1
			var negated := _accept_name("not")
			var type_name := _parse_type_name()
			if type_name == "":
				return null
			node = {
				"type": "typecheck",
				"value": node,
				"type_name": type_name,
				"negated": negated,
			}

		return node


	#* '**', as in GDScript (-2 ** 2 == -4, 2 ** 2 ** 3 == (2 ** 2) ** 3):
	func _parse_power() -> Variant:
		var node = _parse_postfix()
		if node == null:
			return null
		while _at_op("**"):
			index += 1
			var right = _parse_power_operand()
			if right == null:
				return null
			node = {"type": "binary", "op": "**", "left": node, "right": right}
		return node


	#* Right side of '**' - a leading sign covers only the operand (2 ** -1):
	func _parse_power_operand() -> Variant:
		if _at_op("-") or _at_op("+") or _at_op("~"):
			var op = _peek()["value"]
			index += 1
			var operand = _parse_power_operand()
			if operand == null:
				return null
			return {"type": "unary", "op": op, "operand": operand}
		return _parse_postfix()


	#* Property access, indexing and calls, chained left to right:
	func _parse_postfix() -> Variant:
		var node = _parse_primary()
		if node == null:
			return null

		while true:
			#¦ 1. .property or .method:
			if _accept_op("."):
				var t = _peek()
				if t["type"] != "NAME":
					_set_error("Expected a property or method name after '.'")
					return null
				index += 1
				node = {"type": "attribute", "object": node, "name": t["value"]}
				continue

			#¦ 2. [key]:
			if _accept_op("["):
				var key = _parse_expression()
				if key == null:
					return null
				if not _expect_op("]"):
					return null
				node = {"type": "index", "object": node, "key": key}
				continue

			#¦ 3. (args):
			if _accept_op("("):
				var args := []
				if not _at_op(")"):
					while true:
						var arg = _parse_expression()
						if arg == null:
							return null
						args.append(arg)
						if _accept_op(","):
							#% Allow a trailing comma before ')':
							if _at_op(")"):
								break
							continue
						break
				if not _expect_op(")"):
					return null
				node = {"type": "call", "callee": node, "args": args}
				continue

			break

		return node


	func _parse_primary() -> Variant:
		var t = _peek()

		match t["type"]:
			"SIGIL":
				return _parse_sigil(t)

			"NUMBER":
				index += 1
				return {"type": "literal", "value": t["value"]}

			"STRING":
				index += 1
				return {"type": "literal", "value": t["value"]}

			"NAME":
				var word: String = t["value"]
				if word == "true":
					index += 1
					return {"type": "literal", "value": true}
				if word == "false":
					index += 1
					return {"type": "literal", "value": false}
				if word == "null":
					index += 1
					return {"type": "literal", "value": null}
				if RESERVED.has(word):
					_set_plain_error("Unexpected keyword '%s'" % word)
					return null
				index += 1
				return {"type": "name", "name": word}

			"OP":
				#¦ 1. Grouping:
				if t["value"] == "(":
					index += 1
					var inner = _parse_expression()
					if inner == null:
						return null
					if not _expect_op(")"):
						return null
					return inner

				#¦ 2. Array literal:
				if t["value"] == "[":
					index += 1
					return _parse_array_literal()

				#¦ 3. Dictionary literal:
				if t["value"] == "{":
					index += 1
					return _parse_dict_literal()

				#¦ 4. %Unique  ->  self.get_node_or_null("%Unique"):
				#? Not modulo: a value is expected here.
				if t["value"] == "%" and _peek_ahead(1)["type"] == "NAME":
					var unique_name: String = _peek_ahead(1)["value"]
					index += 2
					return _node_lookup("%" + unique_name)

		_set_error("Expected a value")
		return null


	#* self.get_node_or_null(path):
	func _node_lookup(path: String) -> Dictionary:
		return {
			"type": "call",
			"callee": {
				"type": "attribute",
				"object": {"type": "name", "name": "self"},
				"name": "get_node_or_null",
			},
			"args": [{"type": "literal", "value": path}],
		}


	#* Expand a sigil into ordinary syntax (€a[0], °npc1["X"].to_upper(), $UI/Label.text + "!"):
	func _parse_sigil(t: Dictionary) -> Variant:
		index += 1
		var symbol: String = t["value"]
		var scanned: String = t["name"]

		#¦ 1. $UI/Box/Label  ->  self.get_node_or_null("UI/Box/Label"):
		if symbol == owner.NODE_SYMBOL:
			return _node_lookup(scanned)

		var name_key := {"type": "literal", "value": scanned}

		#¦ 2. Shortcut - €score  ->  <target>["score"]:
		if owner.shortcut_symbols.has(symbol):
			var shortcut_target = _symbol_target(symbol, owner.shortcut_symbols[symbol])
			if shortcut_target == null:
				return null
			return {"type": "index", "object": shortcut_target, "key": name_key}

		#¦ 3. Lookup - °npc1  ->  <keys>["npc1"]:
		#?         °npc1[ or °npc1.  ->  <entries>[<keys>["npc1"]]  (into the entry)
		if owner.lookup_symbols.has(symbol):
			var entry = owner.lookup_symbols[symbol]
			if typeof(entry) != TYPE_DICTIONARY or not entry.has("keys") or not entry.has("entries"):
				_set_plain_error("Lookup symbol '%s' needs a Dictionary with \"keys\" and \"entries\"" % symbol)
				return null
			var keys_target = _symbol_target(symbol, entry["keys"])
			if keys_target == null:
				return null
			var key_lookup := {"type": "index", "object": keys_target, "key": name_key}
			if _at_op("[") or _at_op("."):
				var entries_target = _symbol_target(symbol, entry["entries"])
				if entries_target == null:
					return null
				return {"type": "index", "object": entries_target, "key": key_lookup}
			return key_lookup

		_set_error("Unknown sigil '%s'" % symbol)
		return null


	#* The parsed tree of a symbol's target expression (e.g. "candy_de.vardict"):
	func _symbol_target(symbol: String, target: Variant) -> Variant:
		if typeof(target) != TYPE_STRING or target == "":
			_set_plain_error("Symbol '%s' needs a target expression (a String)" % symbol)
			return null
		var parsed: Dictionary = owner._parse_symbol_target(target)
		if not parsed["ok"]:
			var reason: String = parsed["error"]
			#% Errors already about a symbol pass on unwrapped:
			if reason.begins_with("Symbol ") or reason.begins_with("Lookup symbol '"):
				_set_plain_error(reason)
			else:
				_set_plain_error("Symbol '%s' points to \"%s\", which is not a valid expression: %s" % [symbol, target, reason])
			return null
		return parsed["ast"]


	#* [ a, b, c ]  — the opening '[' is already consumed:
	func _parse_array_literal() -> Variant:
		var elements := []
		if not _at_op("]"):
			while true:
				var element = _parse_expression()
				if element == null:
					return null
				elements.append(element)
				if _accept_op(","):
					if _at_op("]"):
						break
					continue
				break
		if not _expect_op("]"):
			return null
		return {"type": "array", "elements": elements}


	#* { "a": 1, b = 2 }  — the opening '{' is already consumed:
	func _parse_dict_literal() -> Variant:
		var pairs := []
		if not _at_op("}"):
			while true:
				var key = null

				#¦ 1. Lua-style key - identifier followed by '=':
				if _peek()["type"] == "NAME" and _peek_ahead(1)["type"] == "OP" and _peek_ahead(1)["value"] == "=":
					key = {"type": "literal", "value": _peek()["value"]}
					index += 2
				#¦ 2. Standard key - expression followed by ':':
				else:
					key = _parse_expression()
					if key == null:
						return null
					if not _expect_op(":"):
						return null

				var value = _parse_expression()
				if value == null:
					return null
				pairs.append({"key": key, "value": value})

				if _accept_op(","):
					if _at_op("}"):
						break
					continue
				break

		if not _expect_op("}"):
			return null
		return {"type": "dict", "pairs": pairs}


#?##############################################################################
#&  EVALUATOR:
#?############
#? Walks the AST produced by the parser and returns a real value.
#? Errors are returned, not thrown: _eval_* returns a value or an EvalError (_is_err()).


#% Names found before every other scope:
#%	candy.constants["PLAYER_MAX_HP"] = 100
#% candy.constants["roll"] = Callable(self, "roll_dice")
var constants: Dictionary = {}

#% Bare name lookup order (any of LOOKUP_SCOPES; others are skipped with a warning):
var name_lookup_order: Array[String] = ["constants", "caller", "source", "autoload", "engine_singleton"]

#^ The scopes name_lookup_order can list:
const LOOKUP_SCOPES: Array[String] = ["constants", "caller", "source", "autoload", "engine_singleton"]

#% Limit for refs resolving into refs:
var max_resolve_depth: int = 32

#% Max cached syntax trees (-1 = no limit), for expressions built at runtime:
var max_ast_cache: int = 512

var _resolve_depth: int = 0
var _symbol_stack: Array[String] = []		#/ A stack: a method called from an expression may start its own evaluation
var _expanding_targets: Dictionary = {}
var _shim_cache: Dictionary = {}
var _ast_cache: Dictionary = {}
var _sigils: Array[String] = []
var _symbol_chars: Dictionary = {}
var _symbol_fingerprint: String = ""
var _variant_type_names: Dictionary = {}
var _global_classes: Dictionary = {}
var _type_member_cache: Dictionary = {}
var _builtin_static_cache: Dictionary = {}
var _signature_cache: Dictionary = {}
var _checked_lookup_order: int = 0		#/ hash() of the name_lookup_order last checked


#* Error carrier, never a legal value:
#? not_found: a lookup miss (keep searching), not a real failure.
#? chain: refs it passed through, innermost first.
class EvalError extends RefCounted:
	var message: String
	var not_found: bool
	var chain: Array[String] = []
	func _init(p_message: String, p_not_found: bool = false) -> void:
		message = p_message
		not_found = p_not_found


#* A type name's value - Vector2, Node, or a class_name script:
#? For Vector2.ZERO, Color.from_hsv(...), Node.new(), MyClass.CONSTANT...
class CandyType extends RefCounted:
	const KIND_BUILTIN := 0 #% Variant types: Vector2, Color, String, ...
	const KIND_NATIVE := 1  #% ClassDB classes: Node, Sprite2D, ...
	const KIND_SCRIPT := 2  #% Global class_name scripts.

	var kind: int
	var type_name: String
	var script_resource: Script

	func _init(p_kind: int, p_type_name: String, p_script: Script = null) -> void:
		kind = p_kind
		type_name = p_type_name
		script_resource = p_script


func _err(message: String) -> EvalError:
	return EvalError.new(message)


func _is_err(value: Variant) -> bool:
	return _is_live_object(value) and value is EvalError


#* Whether value is a live Object:
#! `is` errors on a freed instance: check this first.
func _is_live_object(value: Variant) -> bool:
	return typeof(value) == TYPE_OBJECT and is_instance_valid(value)


#* A lookup miss (callers may search elsewhere):
func _not_found(message: String) -> EvalError:
	return EvalError.new(message, true)


func _is_not_found(value: Variant) -> bool:
	return _is_err(value) and (value as EvalError).not_found


#* Dispatch one AST node:
func evaluate_node(source: Node, caller: Node, node: Dictionary) -> Variant:
	match node["type"]:
		"literal":
			return node["value"]
		"name":
			return _eval_name(source, caller, node)
		"attribute":
			return _eval_attribute(source, caller, node)
		"index":
			return _eval_index(source, caller, node)
		"call":
			return _eval_call(source, caller, node)
		"unary":
			return _eval_unary(source, caller, node)
		"binary":
			return _eval_binary(source, caller, node)
		"compare":
			return _eval_compare(source, caller, node)
		"logic":
			return _eval_logic(source, caller, node)
		"ternary":
			return _eval_ternary(source, caller, node)
		"array":
			return _eval_array(source, caller, node)
		"dict":
			return _eval_dict(source, caller, node)
		"typecheck":
			return _eval_typecheck(source, caller, node)
		"typecast":
			return _eval_typecast(source, caller, node)

	return _err("Unknown AST node type '%s'" % node["type"])


#--------------------------------------------------------------- read values

#* Resolve a value read along the way, so a stored "¢other.ref" resolves too:
func _resolve_read(source: Node, caller: Node, value: Variant) -> Variant:
	#% After a literal variable's read, a computed "¢…" may hold its text: never resolved:
	if _taint_blocks_resolve:
		return value
	return _resolve_value(source, caller, value)		#/ A failure fails the whole expression


#--------------------------------------------------------------- name lookup

func _eval_name(source: Node, caller: Node, node: Dictionary) -> Variant:
	var key: String = node["name"]
	_last_read_rule = null

	#% Built-in type names can't be shadowed - skip the scope search:
	if _variant_type_id(key) >= 0:
		return CandyType.new(CandyType.KIND_BUILTIN, key)

	var found = _lookup_name(source, caller, key)
	if not _is_not_found(found):
		return found

	#@ Step 1 - Engine globals (PI, TAU, INF...):
	var global_value = _shim_global_name(source, caller, key)
	if not _is_err(global_value):
		return global_value

	#@ Step 2 - Type name (Vector2.ZERO, Node.new()...):
	var type_ref = _find_type(key)
	if type_ref != null:
		return type_ref

	#@ Step 3 - Global enum constants (KEY_A...), UPPER_CASE names only:
	if key == key.to_upper() and _is_ident_start(key[0]):
		if _type_member_cache.has(key):
			return _type_member_cache[key]
		var compiled := _compile_builtin_access(key, "static func run():\n\treturn %s\n" % key)
		if compiled != null:
			var constant_value = compiled.call("run")
			_type_member_cache[key] = constant_value
			return constant_value

	return _err("Unknown identifier '%s'" % key)


#* Scope lookup - a miss gives a not_found EvalError, other EvalErrors are real failures:
func _lookup_name(source: Node, caller: Node, key: String) -> Variant:
	#Ł "self" and "caller" first, so a UI script's own "caller" property can't shadow them:
	if key == "self":
		return source
	if key == "caller":
		return caller

	_check_lookup_order()
	for scope in name_lookup_order:
		match scope:
			"constants":
				if constants.has(key):
					return _resolve_read(source, caller, constants[key])

			"caller":
				var from_caller = _get_object_member(source, caller, caller, key)
				if not _is_not_found(from_caller):
					return from_caller

			"source":
				var from_source = _get_object_member(source, caller, source, key)
				if not _is_not_found(from_source):
					return from_source

			"autoload":
				var autoload_node = _find_autoload(source, caller, key)
				if autoload_node != null:
					return autoload_node

			"engine_singleton":
				if Engine.has_singleton(key):
					return Engine.get_singleton(key)

	return _not_found("'%s' not found in any scope" % key)


#* Warn once about each name_lookup_order entry that isn't a scope:
func _check_lookup_order() -> void:
	var fingerprint := name_lookup_order.hash()
	if fingerprint == _checked_lookup_order:
		return
	_checked_lookup_order = fingerprint
	for scope in name_lookup_order:
		if not scope in LOOKUP_SCOPES:
			push_warning("CandyRef: name_lookup_order has \"%s\", which isn't a scope, so it's skipped. Scopes: %s." % [scope, ", ".join(LOOKUP_SCOPES)])


#* Why an engine singleton can't be used as one, or "":
func _singleton_hint(type_name: String) -> String:
	if Engine.has_singleton(type_name) and not "engine_singleton" in name_lookup_order:
		return " (%s is an engine singleton, but \"engine_singleton\" isn't in name_lookup_order, so only its constants and static methods can be reached)" % type_name
	return ""


#* Property first, then method (returned as a Callable), then signal:
func _get_object_member(source: Node, caller: Node, obj: Object, key: String) -> Variant:
	if obj == null or not is_instance_valid(obj):
		return _not_found("Object is null or freed")

	if key in obj:
		return _read_variable(source, caller, obj, key, obj.get(key))

	if obj.has_method(key):
		return Callable(obj, key)

	#? Script and user signals only answer has_signal().
	if obj.has_signal(key):
		return Signal(obj, key)

	return _not_found("Object has no member '%s'" % key)


func _find_autoload(source: Node, caller: Node, key: String) -> Node:
	var root: Node = null

	if caller != null and is_instance_valid(caller) and caller.is_inside_tree():
		root = caller.get_tree().root
	elif source != null and is_instance_valid(source) and source.is_inside_tree():
		root = source.get_tree().root
	else:
		var loop := Engine.get_main_loop()
		if loop is SceneTree:
			root = (loop as SceneTree).root

	if root == null:
		return null

	return root.get_node_or_null(NodePath(key))


#--------------------------------------------------------------- member access

func _eval_attribute(source: Node, caller: Node, node: Dictionary) -> Variant:
	var object_value = evaluate_node(source, caller, node["object"])
	if _is_err(object_value):
		return object_value

	var key: String = node["name"]
	_last_read_rule = null		#/ Only the final read counts

	match typeof(object_value):
		TYPE_NIL:
			return _err("Cannot read '%s' on a null value" % key)

		TYPE_OBJECT:
			if not is_instance_valid(object_value):
				return _err("Cannot read '%s' on a null or freed object" % key)
			if object_value is CandyType:
				return _get_type_member(source, caller, object_value, key)
			#% A Script value acts like its type name:
			if object_value is Script:
				return _get_type_member(source, caller, _type_for_script(object_value), key)
			var member = _get_object_member(source, caller, object_value, key)
			if _is_not_found(member):
				return _err("%s has no property or method '%s'" % [_describe(object_value), key])
			return member

		#¦ 1. Dot access on Dictionaries (not GDScript; remove for strict parity):
		TYPE_DICTIONARY:
			if (object_value as Dictionary).has(key):
				return _read_variable(source, caller, object_value, key, object_value[key])
			return _err("Dictionary has no key '%s'" % key)

	#¦ 2. Built-in members (Vector2.x, Color.r, Rect2.size...):
	return _shim_member(source, caller, object_value, key)


func _eval_index(source: Node, caller: Node, node: Dictionary) -> Variant:
	var object_value = evaluate_node(source, caller, node["object"])
	if _is_err(object_value):
		return object_value

	var key = evaluate_node(source, caller, node["key"])
	if _is_err(key):
		return key
	_last_read_rule = null		#/ Only the final read counts

	match typeof(object_value):
		TYPE_NIL:
			return _err("Cannot index a null value")

		TYPE_DICTIONARY:
			if (object_value as Dictionary).has(key):
				return _read_variable(source, caller, object_value, key, object_value[key])
			return _err("Dictionary has no key '%s'" % str(key))

		TYPE_OBJECT:
			if not is_instance_valid(object_value):
				return _err("Cannot index a null or freed object")
			if not _is_text(key):
				return _err("Objects can only be indexed by property name")
			var member = _get_object_member(source, caller, object_value, str(key))
			if _is_not_found(member):
				return _err("%s has no property '%s'" % [_describe(object_value), key])
			return member

		TYPE_STRING, TYPE_STRING_NAME, TYPE_ARRAY, \
		TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, \
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY, \
		TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY, \
		TYPE_PACKED_VECTOR4_ARRAY:
			if typeof(key) != TYPE_INT:
				return _err("%s must be indexed by an integer, got %s" % [_describe(object_value), str(key)])
			#% StringName has no subscript of its own - index its String form:
			if typeof(object_value) == TYPE_STRING_NAME:
				object_value = String(object_value)
			#? len(), as String has no size().
			var count: int = len(object_value)
			var i: int = key
			if i < 0:
				i += count #% Python-style negative indexing, same as GDScript.
			if i < 0 or i >= count:
				return _err("Index %d out of range (size %d)" % [key, count])
			if typeof(object_value) == TYPE_ARRAY:
				return _read_variable(source, caller, object_value, i, object_value[i])
			return _resolve_read(source, caller, object_value[i])

	#% Built-in indexing (Vector2[0], Transform2D[1]...):
	return _shim_index(source, caller, object_value, key)


#--------------------------------------------------------------- type operators

#* Variant type name → TYPE_* id, or -1:
func _variant_type_id(type_name: String) -> int:
	#% Built on first use:
	if _variant_type_names.is_empty():
		for i in range(TYPE_MAX):
			_variant_type_names[type_string(i)] = i
	if _variant_type_names.has(type_name):
		return _variant_type_names[type_name]
	return -1


func _eval_typecheck(source: Node, caller: Node, node: Dictionary) -> Variant:
	var value = evaluate_node(source, caller, node["value"])
	if _is_err(value):
		return value

	var type_ref := _find_type(node["type_name"])
	if type_ref == null:
		return _err("Unknown type '%s'" % node["type_name"])

	var result := _matches_type(value, type_ref)
	if node["negated"]:
		return not result
	return result


#* `value is type_ref`, shared by 'is', 'as' and is_instance_of():
func _matches_type(value: Variant, type_ref: CandyType) -> bool:
	match type_ref.kind:
		CandyType.KIND_BUILTIN:
			var variant_id := _variant_type_id(type_ref.type_name)
			if variant_id == TYPE_OBJECT:
				#% Freed instances aren't Objects:
				return _is_live_object(value)
			return typeof(value) == variant_id
		CandyType.KIND_NATIVE:
			return _is_live_object(value) and (value as Object).is_class(type_ref.type_name)
		CandyType.KIND_SCRIPT:
			return _inherits_script(value, type_ref.script_resource)
	return false


#* True if value is an instance of script, or of a script extending it:
func _inherits_script(value: Variant, class_script: Script) -> bool:
	if not _is_live_object(value):
		return false
	var current = (value as Object).get_script()
	while current != null:
		if current == class_script:
			return true
		current = (current as Script).get_base_script()
	return false


func _eval_typecast(source: Node, caller: Node, node: Dictionary) -> Variant:
	var value = evaluate_node(source, caller, node["value"])
	if _is_err(value):
		return value

	var type_ref := _find_type(node["type_name"])
	if type_ref == null:
		return _err("Unknown type '%s'" % node["type_name"])

	if type_ref.kind == CandyType.KIND_BUILTIN:
		return type_convert(value, _variant_type_id(type_ref.type_name))

	if _matches_type(value, type_ref):
		return value
	#? A failed object cast yields null in GDScript, not an error.
	return null


#--------------------------------------------------------------- type names

#* A CandyType for a type name, or null if the name is not a type:
func _find_type(type_name: String) -> CandyType:
	if _variant_type_id(type_name) >= 0:
		return CandyType.new(CandyType.KIND_BUILTIN, type_name)
	if ClassDB.class_exists(type_name):
		return CandyType.new(CandyType.KIND_NATIVE, type_name)
	var class_script := _find_global_class(type_name)
	if class_script != null:
		return CandyType.new(CandyType.KIND_SCRIPT, type_name, class_script)
	return null


#* Script registered under a class_name, or null:
func _find_global_class(type_name: String) -> Script:
	#% A miss rebuilds the class list, for classes added at runtime:
	if not _global_classes.has(type_name):
		_global_classes.clear()
		for info in ProjectSettings.get_global_class_list():
			_global_classes[str(info["class"])] = info["path"]
		if not _global_classes.has(type_name):
			return null

	var class_script = load(_global_classes[type_name])
	if _is_live_object(class_script) and class_script is Script:
		return class_script
	return null


#* Type members (Vector2.ZERO, Node.NOTIFICATION_READY, MyClass.CONSTANT, MyClass.Enum):
func _get_type_member(source: Node, caller: Node, type_ref: CandyType, key: String) -> Variant:
	match type_ref.kind:
		CandyType.KIND_BUILTIN:
			#Ł Constants - compiled and read once:
			var cache_key := "%s.%s" % [type_ref.type_name, key]
			if _type_member_cache.has(cache_key):
				return _type_member_cache[cache_key]
			var compiled := _compile_builtin_access(cache_key, "static func run():\n\treturn %s.%s\n" % [type_ref.type_name, key])
			if compiled == null:
				return _err("%s has no constant '%s'" % [type_ref.type_name, key])
			var value = compiled.call("run")
			_type_member_cache[cache_key] = value
			return value

		CandyType.KIND_NATIVE:
			if ClassDB.class_has_integer_constant(type_ref.type_name, key):
				return ClassDB.class_get_integer_constant(type_ref.type_name, key)
			if ClassDB.class_has_method(type_ref.type_name, key):
				return _err("%s.%s is a method and must be called" % [type_ref.type_name, key])
			return _err("%s has no constant '%s'%s" % [type_ref.type_name, key, _singleton_hint(type_ref.type_name)])

		CandyType.KIND_SCRIPT:
			var class_script := type_ref.script_resource
			var constant_map := class_script.get_script_constant_map()
			if constant_map.has(key):
				return _resolve_read(source, caller, constant_map[key])
			#¦ 1. Static variables, and the Script's own properties (resource_path):
			if key in class_script:
				return _resolve_read(source, caller, class_script.get(key))
			#¦ 2. A static function named without a call, as a Callable:
			var signature := _script_method_signature(class_script, key)
			if not signature.is_empty() and signature["static"]:
				return Callable(class_script, key)
			#% Godot shows nothing of a C# class's constants, enums and static fields or properties:
			if class_script.get_class() == "CSharpScript":
				return _err("%s has nothing named '%s' that Godot can see. A C# class's constants, enums and static fields and properties are hidden from Godot: read them through a static method" % [type_ref.type_name, key])
			return _err("%s has no constant or static variable '%s'" % [type_ref.type_name, key])

	return _err("Unknown type kind")


#* CandyType for a Script value:
func _type_for_script(class_script: Script) -> CandyType:
	var label := String(class_script.get_global_name())
	if label == "":
		label = class_script.resource_path.get_file()
	if label == "":
		label = "Script"
	return CandyType.new(CandyType.KIND_SCRIPT, label, class_script)


#* Type method calls (Color.from_hsv(...), Node.new(), MyClass.new(...), MyClass.static_func(...)):
func _call_type_method(source: Node, caller: Node, type_ref: CandyType, method: String, args: Array) -> Variant:
	match type_ref.kind:
		CandyType.KIND_BUILTIN:
			#Ł Built-ins have no static reflection - compile one function per method and arg count:
			var placeholders := []
			for i in args.size():
				placeholders.append("a%d" % i)
			var joined := ", ".join(placeholders)
			var cache_key := "%s.%s/%d" % [type_ref.type_name, method, args.size()]
			var source_code := "static func run(%s):\n\treturn %s.%s(%s)\n" % [joined, type_ref.type_name, method, joined]
			var compiled := _compile_builtin_access(cache_key, source_code)
			if compiled == null:
				return _err("%s has no static method '%s' taking %d argument(s)" % [type_ref.type_name, method, args.size()])
			return _resolve_read(source, caller, compiled.callv("run", args))

		CandyType.KIND_NATIVE:
			if method == "new":
				if not args.is_empty():
					return _err("%s.new() takes no arguments" % type_ref.type_name)
				if not ClassDB.can_instantiate(type_ref.type_name):
					return _err("%s cannot be instantiated" % type_ref.type_name)
				return ClassDB.instantiate(type_ref.type_name)
			var native_signature := _native_method_signature(type_ref.type_name, method)
			if native_signature.is_empty():
				return _err("%s has no method '%s'" % [type_ref.type_name, method])
			if not native_signature["static"]:
				return _err("%s.%s() is not static, so it needs an instance%s" % [type_ref.type_name, method, _singleton_hint(type_ref.type_name)])
			var native_error = _check_signature(native_signature, type_ref.type_name, method, args.size())
			if native_error != null:
				return native_error
			var call_args := [type_ref.type_name, method]
			call_args.append_array(args)
			return _resolve_read(source, caller, ClassDB.callv("class_call_static", call_args))

		CandyType.KIND_SCRIPT:
			var class_script := type_ref.script_resource
			if method == "new":
				if not class_script.can_instantiate():
					return _err("%s cannot be instantiated" % type_ref.type_name)
				#% No _init in the chain - new() takes no arguments:
				var init_signature := _script_method_signature(class_script, "_init")
				if init_signature.is_empty():
					init_signature = {"min": 0, "max": 0, "static": false}
				var init_error = _check_signature(init_signature, type_ref.type_name, "new", args.size())
				if init_error != null:
					return init_error
				return class_script.callv("new", args)

			#¦ 1. Script's get_method_list() describes the resource - use its script method list:
			var script_signature := _script_method_signature(class_script, method)
			if not script_signature.is_empty():
				if not script_signature["static"]:
					return _err("%s.%s() is not static, so it needs an instance" % [type_ref.type_name, method])
				var script_error = _check_signature(script_signature, type_ref.type_name, method, args.size())
				if script_error != null:
					return script_error
				return _resolve_read(source, caller, class_script.callv(method, args))

			#¦ 2. Methods of the Script resource itself, e.g. get_global_name():
			if class_script.has_method(method):
				var resource_error = _check_arg_count(class_script, method, args.size())
				if resource_error != null:
					return resource_error
				return _resolve_read(source, caller, class_script.callv(method, args))

			return _err("%s has no static method '%s'" % [type_ref.type_name, method])

	return _err("Unknown type kind")


#* Compile a one-function GDScript for built-in type access, or null:
#! Only insert a Variant type name and a tokenized identifier, so the code can't be escaped.
func _compile_builtin_access(cache_key: String, source_code: String) -> GDScript:
	if _builtin_static_cache.has(cache_key):
		return _builtin_static_cache[cache_key]

	var compiled := GDScript.new()
	compiled.source_code = source_code
	if compiled.reload() != OK:
		#Ł Cache failures too:
		_builtin_static_cache[cache_key] = null
		return null

	_builtin_static_cache[cache_key] = compiled
	return compiled


#--------------------------------------------------------------- calls

func _eval_call(source: Node, caller: Node, node: Dictionary) -> Variant:
	var callee: Dictionary = node["callee"]
	var callee_type: String = callee["type"]

	#Ł GDScript order - callee/receiver first, then arguments left to right:
	var target = null
	if callee_type == "attribute":
		target = evaluate_node(source, caller, callee["object"])
		if _is_err(target):
			return target
	elif callee_type == "name":
		target = _lookup_name(source, caller, callee["name"])
		if _is_err(target) and not _is_not_found(target):
			return target
	else:
		target = evaluate_node(source, caller, callee)
		if _is_err(target):
			return target

	var args := []
	for arg_node in node["args"]:
		var arg_value = evaluate_node(source, caller, arg_node)
		if _is_err(arg_value):
			return arg_value
		args.append(arg_value)

	#¦ 1. Method call - receiver.method(...):
	if callee_type == "attribute":
		return _call_method(source, caller, target, callee["name"], args)

	#¦ 2. Bare call - name(...):
	if callee_type == "name":
		var key: String = callee["name"]
		if not _is_err(target):
			if typeof(target) == TYPE_CALLABLE:
				return _finish_call(source, caller, target, args)
			return _err("'%s' is not callable (it is %s)" % [key, _describe(target)])

		#% Not in any scope - GDScript global (max(), str(), Vector2()...):
		return _shim_global_call(source, caller, key, args)

	#¦ 3. Anything else has to produce a Callable (e.g. globals.handlers[0]()):
	if typeof(target) == TYPE_CALLABLE:
		return _finish_call(source, caller, target, args)
	return _err("Expression is not callable (it is %s)" % _describe(target))


func _call_method(source: Node, caller: Node, receiver: Variant, method: String, args: Array) -> Variant:
	match typeof(receiver):
		TYPE_NIL:
			return _err("Cannot call '%s' on a null value" % method)

		TYPE_OBJECT:
			if not is_instance_valid(receiver):
				return _err("Cannot call '%s' on a null or freed object" % method)
			if receiver is CandyType:
				return _call_type_method(source, caller, receiver, method, args)
			#¦ 1. Script value - calls like its type name:
			if receiver is Script:
				return _call_type_method(source, caller, _type_for_script(receiver), method, args)
			if (receiver as Object).has_method(method):
				var arg_error = _check_arg_count(receiver, method, args.size())
				if arg_error != null:
					return arg_error
				return _resolve_read(source, caller, (receiver as Object).callv(method, args))
			#¦ 2. A property holding a Callable is callable too:
			if method in receiver and typeof(receiver.get(method)) == TYPE_CALLABLE:
				return _finish_call(source, caller, receiver.get(method), args)
			return _err("%s has no method '%s'" % [_describe(receiver), method])

		TYPE_DICTIONARY:
			if (receiver as Dictionary).has(method) and typeof(receiver[method]) == TYPE_CALLABLE:
				return _finish_call(source, caller, receiver[method], args)

	#% Built-in types ("  hi ".strip_edges(), [1,2].size(), Vector2().length()):
	return _shim_method(source, caller, receiver, method, args)


func _finish_call(source: Node, caller: Node, target: Callable, args: Array) -> Variant:
	if not target.is_valid():
		return _err("Callable is not valid (object freed or method missing)")

	#Ł Check argument count, so a bad call is a CandyRef error:
	if target.is_standard():
		#¦ 1. Callable(object, "method"), possibly with bound arguments:
		var total := args.size() + target.get_bound_arguments_count()
		var arg_error = _check_arg_count(target.get_object(), target.get_method(), total)
		if arg_error != null:
			return arg_error
	elif args.size() > target.get_argument_count():
		#¦ 2. Lambdas - defaults unknown, only too many is caught:
		return _err("Callable takes at most %d argument(s), got %d" % [target.get_argument_count(), args.size()])

	return _resolve_read(source, caller, target.callv(args))


#* Returns null when the count fits (or the signature is unknown), else an EvalError:
func _check_arg_count(obj: Object, method: String, count: int) -> Variant:
	return _check_signature(_get_method_signature(obj, method), _describe(obj), method, count)


#* Same check against a signature already looked up (an empty signature passes):
func _check_signature(signature: Dictionary, owner_name: String, method: String, count: int) -> Variant:
	if signature.is_empty():
		return null

	var max_count: int = signature["max"]
	var min_count: int = signature["min"]

	if count < min_count:
		return _err("%s.%s() needs at least %d argument(s), got %d" % [owner_name, method, min_count, count])
	if max_count >= 0 and count > max_count:
		return _err("%s.%s() takes at most %d argument(s), got %d" % [owner_name, method, max_count, count])
	return null


#* { "min": int, "max": int } for a method (max -1 when vararg), empty if unknown:
func _get_method_signature(obj: Object, method: String) -> Dictionary:
	var script_key := ""
	var obj_script = obj.get_script()
	if obj_script != null:
		script_key = str((obj_script as Script).get_instance_id())
	var cache_key := "%s|%s|%s" % [obj.get_class(), script_key, method]

	#% Cached (get_method_list() is slow):
	if not _signature_cache.has(cache_key):
		_signature_cache[cache_key] = _signature_from_list(obj.get_method_list(), method)
	return _signature_cache[cache_key]


#* Signature of a function declared in a script, static ones included:
func _script_method_signature(class_script: Script, method: String) -> Dictionary:
	var cache_key := "script|%d|%s" % [class_script.get_instance_id(), method]
	if not _signature_cache.has(cache_key):
		_signature_cache[cache_key] = _signature_from_list(class_script.get_script_method_list(), method)
	return _signature_cache[cache_key]


#* Signature of an engine class method, inherited ones included:
func _native_method_signature(type_name: String, method: String) -> Dictionary:
	var cache_key := "native|%s|%s" % [type_name, method]
	if not _signature_cache.has(cache_key):
		_signature_cache[cache_key] = _signature_from_list(ClassDB.class_get_method_list(type_name), method)
	return _signature_cache[cache_key]


#* { "min", "max", "static" } from a method list, or {} if the method is absent:
func _signature_from_list(method_list: Array, method: String) -> Dictionary:
	var signature := {}
	for info in method_list:
		if info["name"] != method:
			continue
		var flags: int = info["flags"]
		var arg_count: int = info["args"].size()
		signature["min"] = arg_count - info["default_args"].size()
		if flags & METHOD_FLAG_VARARG:
			signature["max"] = -1
		else:
			signature["max"] = arg_count
		signature["static"] = (flags & METHOD_FLAG_STATIC) != 0
		break
	return signature


#--------------------------------------------------------------- operators

const _NUMERIC_UNARY := [TYPE_INT, TYPE_FLOAT, TYPE_VECTOR2, TYPE_VECTOR2I,
	TYPE_VECTOR3, TYPE_VECTOR3I, TYPE_VECTOR4, TYPE_VECTOR4I,
	TYPE_COLOR, TYPE_QUATERNION, TYPE_PLANE]

const _BITWISE_OPS := ["&", "|", "^", "<<", ">>"]


func _eval_unary(source: Node, caller: Node, node: Dictionary) -> Variant:
	var value = evaluate_node(source, caller, node["operand"])
	if _is_err(value):
		return value

	match node["op"]:
		"not":
			return not _is_truthy(value)

		"+":
			if not _NUMERIC_UNARY.has(typeof(value)):
				return _err("Unary '+' needs a number, got %s" % _describe(value))
			return value

		"-":
			if not _NUMERIC_UNARY.has(typeof(value)):
				return _err("Unary '-' needs a number, got %s" % _describe(value))
			return -value

		"~":
			if typeof(value) != TYPE_INT:
				return _err("Operator '~' needs an integer, got %s" % _describe(value))
			return ~(value as int)

	return _err("Unknown unary operator '%s'" % node["op"])


func _eval_binary(source: Node, caller: Node, node: Dictionary) -> Variant:
	var left = evaluate_node(source, caller, node["left"])
	if _is_err(left):
		return left

	var right = evaluate_node(source, caller, node["right"])
	if _is_err(right):
		return right

	var op: String = node["op"]

	#¦ 1. Bitwise and shifts are integers only:
	if _BITWISE_OPS.has(op):
		if typeof(left) != TYPE_INT or typeof(right) != TYPE_INT:
			return _err("Operator '%s' needs two integers, got %s and %s" % [op, _describe(left), _describe(right)])
		var a: int = left
		var b: int = right
		match op:
			"&": return a & b
			"|": return a | b
			"^": return a ^ b
			"<<":
				if b < 0 or b > 63:
					return _err("Shift amount %d out of range" % b)
				return a << b
			">>":
				if b < 0 or b > 63:
					return _err("Shift amount %d out of range" % b)
				return a >> b

	#¦ 2. Fast path for plain numbers:
	if _is_number(left) and _is_number(right):
		var both_int := typeof(left) == TYPE_INT and typeof(right) == TYPE_INT

		match op:
			"+": return left + right
			"-": return left - right
			"*": return left * right

			"/":
				if both_int:
					if right == 0:
						return _err("Integer division by zero")
					@warning_ignore("integer_division")
					return (left as int) / (right as int)
				return float(left) / float(right)

			"%":
				if both_int:
					if right == 0:
						return _err("Modulo by zero")
					return (left as int) % (right as int)
				#% Floats - fmod (GDScript rejects %):
				return fmod(float(left), float(right))

			"**":
				if both_int and right >= 0:
					return _int_pow(left, right) #% Matches GDScript: 2 ** 3 is int 8
				return pow(float(left), float(right))

	#¦ 3. Other types - GDScript semantics:
	return _shim_binary(source, caller, op, left, right)


func _eval_compare(source: Node, caller: Node, node: Dictionary) -> Variant:
	var left = evaluate_node(source, caller, node["left"])
	if _is_err(left):
		return left

	var right = evaluate_node(source, caller, node["right"])
	if _is_err(right):
		return right

	var op: String = node["op"]

	#¦ 1. Equality. Mismatched types (1 == "a") are unequal instead of a script error:
	if op == "==" or op == "!=":
		var equal := false
		if _can_test_equality(left, right):
			equal = left == right
		if op == "!=":
			return not equal
		return equal

	#¦ 2. Membership:
	if op == "in" or op == "not in":
		var contained = _eval_contains(left, right)
		if _is_err(contained):
			return contained
		if op == "not in":
			return not contained
		return contained

	#¦ 3. Ordering, for things that are actually ordered:
	var comparable := (_is_number(left) and _is_number(right)) \
		or (_is_text(left) and _is_text(right))

	if comparable:
		match op:
			"<": return left < right
			">": return left > right
			"<=": return left <= right
			">=": return left >= right

	return _shim_binary(source, caller, op, left, right)


func _eval_contains(needle: Variant, haystack: Variant) -> Variant:
	match typeof(haystack):
		TYPE_NIL:
			return _err("'in' cannot search a null value")

		TYPE_DICTIONARY:
			return (haystack as Dictionary).has(needle)

		TYPE_STRING, TYPE_STRING_NAME:
			if not _is_text(needle):
				return _err("'in' on a String needs a String on the left")
			return (haystack as String).contains(str(needle))

		TYPE_OBJECT:
			if not is_instance_valid(haystack):
				return _err("'in' cannot search a null or freed object")
			if not _is_text(needle):
				return _err("'in' on an Object needs a property name on the left")
			return str(needle) in haystack

		TYPE_ARRAY:
			#% Typed Array has() errors on a wrong type - only untyped ones are searched directly:
			if not (haystack as Array).is_typed():
				return (haystack as Array).has(needle)

	#% Typed/packed arrays and the rest - Expression, which fails cleanly on a type mismatch:
	var expression := _shim("lhs in rhs", PackedStringArray(["lhs", "rhs"]))
	if expression != null:
		var result = expression.execute([needle, haystack], null, false)
		if not expression.has_execute_failed():
			return result
	return _err("'in' does not support %s on the right" % _describe(haystack))


#* and / or short-circuit like GDScript, and return bools:
func _eval_logic(source: Node, caller: Node, node: Dictionary) -> Variant:
	var left = evaluate_node(source, caller, node["left"])
	if _is_err(left):
		return left

	var left_truth := _is_truthy(left)

	match node["op"]:
		"or":
			if left_truth:
				return true
			var right_or = evaluate_node(source, caller, node["right"])
			if _is_err(right_or):
				return right_or
			return _is_truthy(right_or)

		"and":
			if not left_truth:
				return false
			var right_and = evaluate_node(source, caller, node["right"])
			if _is_err(right_and):
				return right_and
			return _is_truthy(right_and)

		"xor":
			var right_xor = evaluate_node(source, caller, node["right"])
			if _is_err(right_xor):
				return right_xor
			return left_truth != _is_truthy(right_xor)

	return _err("Unknown logic operator '%s'" % node["op"])


#* Only the taken branch is evaluated:
func _eval_ternary(source: Node, caller: Node, node: Dictionary) -> Variant:
	var condition = evaluate_node(source, caller, node["cond"])
	if _is_err(condition):
		return condition

	if _is_truthy(condition):
		return evaluate_node(source, caller, node["then"])
	return evaluate_node(source, caller, node["otherwise"])


func _eval_array(source: Node, caller: Node, node: Dictionary) -> Variant:
	var result := []
	for element_node in node["elements"]:
		var element = evaluate_node(source, caller, element_node)
		if _is_err(element):
			return element
		result.append(element)
	return result


func _eval_dict(source: Node, caller: Node, node: Dictionary) -> Variant:
	var result := {}
	for pair in node["pairs"]:
		var key = evaluate_node(source, caller, pair["key"])
		if _is_err(key):
			return key
		var value = evaluate_node(source, caller, pair["value"])
		if _is_err(value):
			return value
		result[key] = value
	return result


#==============================================================================
#  DYNAMIC DISPATCH SHIM
#==============================================================================
#  Built-in Variants can't call methods or read properties by name at runtime.
#
#  So each operation is a cached one-operation Expression template, values passed as inputs.
#
#  Optional: without them, built-in methods, properties and GDScript globals are lost.

#% GDScript global functions Expression can't call:
#? No preload(): it needs a constant path.
const _GDSCRIPT_FUNCTIONS := [
	"Color8", "char", "convert", "dict_to_inst", "inst_to_dict", "is_instance_of",
	"len", "load", "ord", "range", "type_exists",
]


func _shim(text: String, input_names: PackedStringArray) -> Expression:
	if _shim_cache.has(text):
		return _shim_cache[text]

	var expression := Expression.new()
	if expression.parse(text, input_names) != OK:
		#Ł Cache failures too (every Vector2.ZERO asks whether "Vector2" is a global):
		_shim_cache[text] = null
		return null

	_shim_cache[text] = expression
	return expression


#* "  hi ".strip_edges() and friends:
func _shim_method(source: Node, caller: Node, receiver: Variant, method: String, args: Array) -> Variant:
	var names := PackedStringArray(["target"])
	var placeholders := []
	for i in args.size():
		names.append("a%d" % i)
		placeholders.append("a%d" % i)

	var text := "target.%s(%s)" % [method, ", ".join(placeholders)]
	var expression := _shim(text, names)
	if expression == null:
		return _err("Invalid method name '%s'" % method)

	var inputs := [receiver]
	inputs.append_array(args)

	var result = expression.execute(inputs, null, false)
	if expression.has_execute_failed():
		return _err("%s has no method '%s' taking %d argument(s)" % [_describe(receiver), method, args.size()])

	return _resolve_read(source, caller, result)


#* Built-in members (Vector2.x, Color.r, Rect2.size...):
func _shim_member(source: Node, caller: Node, receiver: Variant, key: String) -> Variant:
	var expression := _shim("target.%s" % key, PackedStringArray(["target"]))
	if expression == null:
		return _err("Invalid member name '%s'" % key)

	var result = expression.execute([receiver], null, false)
	if expression.has_execute_failed():
		return _err("%s has no member '%s'" % [_describe(receiver), key])

	return _resolve_read(source, caller, result)


#* Built-in indexing (Vector2[0], Transform2D[1]...):
func _shim_index(source: Node, caller: Node, receiver: Variant, key: Variant) -> Variant:
	var expression := _shim("target[subscript]", PackedStringArray(["target", "subscript"]))
	if expression == null:
		return _err("Could not build index dispatch")

	var result = expression.execute([receiver, key], null, false)
	if expression.has_execute_failed():
		return _err("%s cannot be indexed by %s" % [_describe(receiver), str(key)])

	return _resolve_read(source, caller, result)


#* Built-in operators ("abc" + "def", [1] + [2], Vector2 * 2, Transform2D * Vector2...):
func _shim_binary(source: Node, caller: Node, op: String, left: Variant, right: Variant) -> Variant:
	var expression := _shim("lhs %s rhs" % op, PackedStringArray(["lhs", "rhs"]))
	if expression == null:
		return _err("Unknown operator '%s'" % op)

	var result = expression.execute([left, right], null, false)
	if expression.has_execute_failed():
		return _err("Operator '%s' does not accept %s and %s" % [op, _describe(left), _describe(right)])

	return _resolve_read(source, caller, result)


#* Global constants (PI, TAU, INF, NAN...):
func _shim_global_name(source: Node, caller: Node, key: String) -> Variant:
	var expression := _shim(key, PackedStringArray())
	if expression == null:
		return _err("Unknown identifier '%s'" % key)

	var result = expression.execute([], null, false)
	if expression.has_execute_failed():
		return _err("Unknown identifier '%s'" % key)

	return _resolve_read(source, caller, result)


#* Global functions and constructors (max(1, 2), str(x), Vector2(1, 2), deg_to_rad(90)...):
func _shim_global_call(source: Node, caller: Node, function_name: String, args: Array) -> Variant:
	var names := PackedStringArray()
	var placeholders := []
	for i in args.size():
		names.append("a%d" % i)
		placeholders.append("a%d" % i)

	var joined := ", ".join(placeholders)

	#¦ 1. is_instance_of(x, Type) - answered like 'is' (CandyType args):
	if function_name == "is_instance_of" and args.size() == 2 \
			and _is_live_object(args[1]) and args[1] is CandyType:
		return _matches_type(args[0], args[1])

	#¦ 2. GDScript-only functions (range, len, load...) - compiled wrapper:
	if _GDSCRIPT_FUNCTIONS.has(function_name):
		var cache_key := "call:%s/%d" % [function_name, args.size()]
		var source_code := "static func run(%s):\n\treturn %s(%s)\n" % [joined, function_name, joined]
		var compiled := _compile_builtin_access(cache_key, source_code)
		if compiled == null:
			return _err("%s() does not take %d argument(s)" % [function_name, args.size()])
		return _resolve_read(source, caller, compiled.callv("run", args))

	var text := "%s(%s)" % [function_name, joined]
	var expression := _shim(text, names)
	if expression == null:
		return _err("Unknown function '%s'" % function_name)

	var result = expression.execute(args, null, false)
	if expression.has_execute_failed():
		return _err("Unknown function '%s' taking %d argument(s)" % [function_name, args.size()])

	return _resolve_read(source, caller, result)


#==============================================================================
#  WRITE TARGETS
#==============================================================================
#  resolve_target() evaluates all but a target's last step, returned as container and key.

func _resolve_target(source: Node, caller: Node, target: Variant) -> Variant:
	if not _is_text(target):
		return _err("A write target must be a String, got %s" % _describe(target))
	var text := str(target)

	#% With the symbol, evaluate first - the result names the variable:
	if _is_expression(text):
		var named = _resolve_value(source, caller, text)
		if _is_err(named):
			return named
		if not _is_text(named):
			return _err("Target %s must give a variable name (a String), got %s" % [text, _describe(named)])
		text = str(named)

	var parsed := parse_candy_ref(source, caller, text)
	if not parsed["ok"]:
		return _err("Parse error: " + parsed["error"])

	var ast: Dictionary = parsed["ast"]

	#% Chain starting at a call - call it once, so the write lands on that data:
	var base_call := {}
	var base_node = _base_call_node(ast)
	if base_node != null:
		var args := []
		for arg_node in base_node["args"]:
			var arg_value = evaluate_node(source, caller, arg_node)
			if _is_err(arg_value):
				return _with_chain(arg_value, text)
			args.append(arg_value)
		#Ł Reuse evaluated arguments:
		var literal_call: Dictionary = base_node.duplicate(false)
		literal_call["args"] = args.map(func(value): return {"type": "literal", "value": value})
		var base_value = evaluate_node(source, caller, literal_call)
		if _is_err(base_value):
			return _with_chain(base_value, text)
		base_call = {"name": base_node["callee"]["name"], "args": args, "value": base_value}
		ast = _replace_node(ast, base_node, {"type": "literal", "value": base_value})

	var found = _target_of(source, caller, ast)
	if _is_err(found):
		return _with_chain(found, text)

	found["base_call"] = base_call
	return found


func _with_chain(error: EvalError, text: String) -> EvalError:
	error.not_found = false
	error.chain.append(text)
	return error


#* The container and key named by the last step of a target:
func _target_of(source: Node, caller: Node, node: Dictionary) -> Variant:
	match node["type"]:
		"name":
			return _name_target(source, caller, node["name"])

		"attribute", "index":
			var step_owner = evaluate_node(source, caller, node["object"])
			if _is_err(step_owner):
				return step_owner

			var key = null
			if node["type"] == "attribute":
				key = node["name"]
			else:
				key = evaluate_node(source, caller, node["key"])
				if _is_err(key):
					return key

			#% Copied value - write through its holder:
			if _is_copied_value(step_owner):
				#Ł Read it first, so a bad member ("position.q") fails here:
				var current = evaluate_node(source, caller, node)
				if _is_err(current):
					return current
				var holder = _target_of(source, caller, node["object"])
				if _is_err(holder):
					return holder
				holder["members"].append(key)
				return holder

			return _container_target(step_owner, key)

	return _err("This is not a variable that can be written to")


#* True for values that are copied when read, so can't be written in place:
func _is_copied_value(value: Variant) -> bool:
	return not (typeof(value) in [TYPE_NIL, TYPE_DICTIONARY, TYPE_ARRAY, TYPE_OBJECT])


#* A bare name - the first scope that has it, in name_lookup_order:
func _name_target(source: Node, caller: Node, key: String) -> Variant:
	if key == "self" or key == "caller":
		return _err("'%s' cannot be written to" % key)

	#? Autoloads and singletons can't be replaced, only written into.
	_check_lookup_order()
	for scope in name_lookup_order:
		match scope:
			"constants":
				if constants.has(key):
					return _target_found(constants, key)
			"caller":
				if _is_live_object(caller) and key in caller:
					return _target_found(caller, key)
			"source":
				if _is_live_object(source) and key in source:
					return _target_found(source, key)

	return _err("No variable named '%s' to write to" % key)


#* Check a container can take a write at key:
func _container_target(container: Variant, key: Variant) -> Variant:
	match typeof(container):
		TYPE_NIL:
			return _err("Cannot write '%s' into a null value" % str(key))

		TYPE_DICTIONARY:
			return _target_found(container, key)

		TYPE_ARRAY:
			if typeof(key) != TYPE_INT:
				return _err("Array must be indexed by an integer, got %s" % str(key))
			var count: int = (container as Array).size()
			if key < -count or key >= count:
				return _err("Index %d out of range (size %d)" % [key, count])
			return _target_found(container, key)

		TYPE_OBJECT:
			if not is_instance_valid(container):
				return _err("Cannot write '%s' into a null or freed object" % str(key))
			if not _is_text(key):
				return _err("Objects can only be written to by property name")
			if not (str(key) in container):
				return _err("%s has no property '%s'" % [_describe(container), key])
			return _target_found(container, str(key))

	#% Copied values (Vector2, packed arrays) - write the whole value instead:
	return _err("Cannot write into %s here: it is not held by a variable" % _describe(container))


func _target_found(container: Variant, key: Variant) -> Dictionary:
	return {"ok": true, "container": container, "key": key, "members": [], "base_call": {}, "error": ""}


#* The bare function call a target's chain starts from, or null:
func _base_call_node(node: Dictionary) -> Variant:
	#Ł Walk to the leftmost step - file_var("a.json").stats.hp  ->  file_var("a.json"):
	var current := node
	while true:
		match current["type"]:
			"attribute", "index":
				current = current["object"]
			"call":
				var callee: Dictionary = current["callee"]
				if callee["type"] == "attribute":
					current = callee["object"]
					continue
				if callee["type"] == "name":
					return current
				return null
			_:
				return null
	return null


#* Copy a tree with one node swapped (only its path, as cached trees are read-only):
func _replace_node(node: Dictionary, old_node: Dictionary, new_node: Dictionary) -> Dictionary:
	if is_same(node, old_node):
		return new_node
	var copy := node.duplicate(false)
	match node["type"]:
		"attribute", "index":
			copy["object"] = _replace_node(node["object"], old_node, new_node)
		"call":
			copy["callee"] = _replace_node(node["callee"], old_node, new_node)
	return copy


#==============================================================================
#  SMALL HELPERS
#==============================================================================

func _is_number(value: Variant) -> bool:
	var t := typeof(value)
	return t == TYPE_INT or t == TYPE_FLOAT


func _is_text(value: Variant) -> bool:
	var t := typeof(value)
	return t == TYPE_STRING or t == TYPE_STRING_NAME


#* Whether == can compare the two without a script error:
func _can_test_equality(left: Variant, right: Variant) -> bool:
	var left_type := typeof(left)
	var right_type := typeof(right)
	if left_type == right_type:
		return true
	if left_type == TYPE_NIL or right_type == TYPE_NIL:
		return true
	if _is_number(left) and _is_number(right):
		return true
	return _is_text(left) and _is_text(right)


#* Integer power, by squaring:
func _int_pow(base_value: int, exponent: int) -> int:
	var result := 1
	var factor := base_value
	var remaining := exponent
	while remaining > 0:
		if remaining & 1:
			result *= factor
		factor *= factor
		remaining >>= 1
	return result


#* GDScript truthiness for any type, as in an `if`:
func _is_truthy(value: Variant) -> bool:
	#% Freed objects are false:
	if typeof(value) == TYPE_OBJECT:
		return is_instance_valid(value)
	if value:
		return true
	return false


#* Readable type name for error messages:
func _describe(value: Variant) -> String:
	if typeof(value) == TYPE_OBJECT:
		if not is_instance_valid(value):
			return "<freed object>"
		if value is CandyType:
			return (value as CandyType).type_name
		if value.has_method("get_class"):
			return (value as Object).get_class()
	return type_string(typeof(value))