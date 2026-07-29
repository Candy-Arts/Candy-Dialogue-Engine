#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyFlow
extends RefCounted


#^ Shared instance:
static var _shared: CandyFlow = null

#* Get the shared instance:
static func get_shared() -> CandyFlow:
	if _shared == null:
		_shared = CandyFlow.new()
	return _shared


#? Unused 'caller' parameters:
@warning_ignore_start("unused_parameter")

#* Clear Return state:
func reset_return_state(source: CandyEngine, caller: Object) -> void:
	source.return_levels = 0
	source.return_end_on_overshoot = false

#* Resolve a Jump / Bridge target into a Conversation, Block and line index:
func resolve_transition_target(source: CandyEngine, caller: Object, command_name: String, command_value, current_conversation, current_block, line_index) -> Dictionary:
	var new_conversation: String	= str(source.candy_ref.resolve_value(source, source, str(command_value.get("Conversation", "")), candy_de.candy_ref_symbol))
	var new_block: String			= str(source.candy_ref.resolve_value(source, source, str(command_value.get("Block", "")), candy_de.candy_ref_symbol))
	var line_ref: Variant			= source.candy_ref.resolve_value(source, source, command_value.get("Line", "0"), candy_de.candy_ref_symbol)

	#@ Step 1 - Fallback to current Conversation or Block:
	if new_conversation.strip_edges() == "":
		new_conversation = current_conversation
	if new_block.strip_edges() == "":
		new_block = current_block

	var result := { "ok": false, "conversation": new_conversation, "block": new_block, "line": 0 }

	#@ Step 2 - Validate the target:
	var target_valid = source.running_dialogue.has(new_conversation) \
		and source.running_dialogue[new_conversation].has(new_block) \
		and source.running_dialogue[new_conversation][new_block].has("Text")

	#% Target not found:
	if not target_valid:
		var msg := "%s: target not found → %s > %s (called from %s > %s, line %s)" % [
			command_name, new_conversation, new_block, current_conversation, current_block, str(line_index)
		]
		push_error(msg)
		assert(target_valid, msg)

		return result

	#@ Step 3 - Numeric strings to int:
	if line_ref == null:
		line_ref = 0
	if typeof(line_ref) == TYPE_STRING:
		if line_ref == "":
			line_ref = 0
		elif line_ref.is_valid_int():
			line_ref = int(line_ref)

	#@ Step 4 - Resolve target line (index or LM tag):
	var target_line: int = 0
	if typeof(line_ref) == TYPE_INT:
		target_line = line_ref

	elif typeof(line_ref) == TYPE_STRING:
		var text_array = source.running_dialogue[new_conversation][new_block]["Text"]
		target_line = _find_line_mark(source, caller, text_array, line_ref)
		var lm_found := target_line != -1

		#% Line Mark not found:
		if not lm_found:
			var msg := "%s: Line Mark '%s' not found in %s > %s (called from %s > %s, line %s)" % [
				command_name, str(line_ref), new_conversation, new_block, current_conversation, current_block, str(line_index)
			]
			push_error(msg)
			assert(lm_found, msg)

			return result

	result["ok"] = true
	result["line"] = target_line
	return result

#* Index of the LM line with Reference 'ref', or -1:
func _find_line_mark(source: CandyEngine, caller: Object, text_array: Variant, ref: String) -> int:
	if typeof(text_array) != TYPE_ARRAY:
		return -1

	var lm_key := source.normalize_command_name("LM")

	for i in range(text_array.size()):
		var ld = text_array[i]
		if typeof(ld) != TYPE_DICTIONARY:
			continue

		for key in ld.keys():
			if typeof(key) != TYPE_STRING:
				continue
			if source.normalize_command_name(key) != lm_key:
				continue

			var lm_data = ld[key]
			if typeof(lm_data) == TYPE_DICTIONARY and str(lm_data.get("Reference", "")) == ref:
				return i

	return -1

#* Build a 'fake' line from a command's "Commands":
func commands_to_line(source: CandyEngine, caller: Object, dialogue_commands: Dictionary) -> Array:
	var line: Array = []
	for cmd_key in dialogue_commands.keys():
		line.append({ cmd_key: dialogue_commands[cmd_key] })
	return line

#* Build a 'fake' transition command (Jump, Bridge, Return or End):
func transition_line(source: CandyEngine, caller: Object, command_name: String, convo: String, block: String, line_ref: String, levels: String = "") -> Array:
	var parameters: Dictionary = {
		"Conversation": convo,
		"Block": block,
		"Line": line_ref,
	}

	if levels != "":
		parameters["Levels"] = levels

	return [ { command_name: parameters } ]

#* Run a 'fake' line from a command and handle nesting count:
func run_nested_line(source: CandyEngine, caller: Object, line, current_conversation, current_block):
	source.nesting_depth += 1
	var feedback = await source.run_dialogue(current_conversation, current_block, 0, line, false, true)
	source.nesting_depth = max(0, source.nesting_depth - 1)

	#Ł Clear leftover If states from deeper levels:
	if source.if_array.size() > source.nesting_depth + 1:
		source.if_array.resize(source.nesting_depth + 1)

	return feedback

#* Append a transition marker to the dialogue history:
func log_transition(source: CandyEngine, caller: Object, command_name: String, new_conversation: String = "", current_conversation = "") -> void:
	if source.write_dialogue_history == false:
		return

	#¦ 1. End and Return:
	if command_name == "End" or command_name == "Return":
		source.dialogue_history.append({ command_name: "" })
		candy_de.general_dialogue_history.append({ command_name: "" })
		return

	#¦ 2. Jump and Bridge:
	var same_conv = (new_conversation == "" or new_conversation == str(current_conversation))
	source.dialogue_history.append({ command_name: { "changed_conv": not same_conv } })
	candy_de.general_dialogue_history.append({ command_name: { "changed_conv": not same_conv } })

@warning_ignore_restore("unused_parameter")
