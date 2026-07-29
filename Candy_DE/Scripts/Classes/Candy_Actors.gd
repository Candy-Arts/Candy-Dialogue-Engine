#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyActors
extends RefCounted


#^ Shared instance:
static var _shared: CandyActors = null

#* Get the shared instance:
static func get_shared() -> CandyActors:
	if _shared == null:
		_shared = CandyActors.new()
	return _shared


#? Unused 'caller' parameters:
@warning_ignore_start("unused_parameter")

#* Role name of a role reference ("°npc1" -> "npc1"), or "":
func role_name(source: CandyEngine, caller: Object, ref: Variant) -> String:
	if typeof(ref) != TYPE_STRING and typeof(ref) != TYPE_STRING_NAME:
		return ""
	var text := str(ref).strip_edges()
	var sym: String = candy_de.role_symbol
	if sym == "" or not text.begins_with(sym):
		return ""
	return text.substr(sym.length())


#* Actor a role reference points at ("°npc1" -> candy_de.roles["npc1"]):
#? literal: CandyRef's last_literal when ref was just resolved - a literal variable's value is
#? only read as a role when its rule allows "references".
func actor_from_role(source: CandyEngine, caller: Object, ref: Variant, context: String = "", literal: Variant = null) -> Variant:
	if not CandySanitizer.literal_allows(literal, "references"):
		return ref		#/ A literal value, never a role
	var key := role_name(source, caller, ref)
	if key == "":
		return ref		#/ Not a role
	if candy_de.roles.has(key):
		return candy_de.roles[key]
	printerr(context, ": unknown role → ", str(ref))
	return ref


#* Command parameter → Array of names:
func to_name_array(source: CandyEngine, caller: Object, raw: Variant, resolve_entries: bool = false) -> Array:
	var result: Array = []
	var parts: Array = []

	if raw is String:
		parts = Array(raw.split(",", false))
	elif raw is Array:
		parts = raw
	else:
		return result

	for part in parts:
		var entry: Variant = str(part).strip_edges()
		if resolve_entries:
			entry = source.candy_ref.resolve_value(source, source, entry, candy_de.candy_ref_symbol)
		if str(entry) != "":
			result.append(entry)

	return result


#* Actor's displayed name, translated:
func display_name(source: CandyEngine, caller: Object, actor_ref: String) -> String:
	return _translated_name(source, caller, actor_ref, ["DisplayName"])		#/ Else the actor reference


#* Actor's name in text (¤Alice¤), translated:
func text_name(source: CandyEngine, caller: Object, actor_ref: String) -> String:
	return _translated_name(source, caller, actor_ref, ["ShortName", "DisplayName"])		#/ Else the actor reference


#* The literal rule of the field display_name() reads (CandyRef.literal_rule()), or null:
func display_name_rule(source: CandyEngine, caller: Object, actor_ref: String) -> Variant:
	return _name_rule(source, caller, actor_ref, ["DisplayName"])


#* The literal rule of the field text_name() reads (CandyRef.literal_rule()), or null:
func text_name_rule(source: CandyEngine, caller: Object, actor_ref: String) -> Variant:
	return _name_rule(source, caller, actor_ref, ["ShortName", "DisplayName"])


#* The literal rule of the first non-empty 'name_keys' field, or null (none, or the actor reference shown):
func _name_rule(source: CandyEngine, caller: Object, actor_ref: String, name_keys: Array) -> Variant:
	var entry = candy_de.actors.get(actor_ref)
	if typeof(entry) != TYPE_DICTIONARY:
		return null
	for name_key in name_keys:
		var name_val = entry.get(name_key, null)
		if name_val != null and str(name_val).strip_edges() != "":
			return source.candy_ref.literal_rule(source, source, entry, name_key, candy_de.candy_ref_symbol)		#/ CandyRef's caller must be a Node
	return null


#* First non-empty 'name_keys' value, else actor_ref, translated through display_names:
func _translated_name(source: CandyEngine, caller: Object, actor_ref: String, name_keys: Array) -> String:
	var shown := actor_ref
	var entry = candy_de.actors.get(actor_ref)
	if typeof(entry) == TYPE_DICTIONARY:
		for name_key in name_keys:
			var name_val = entry.get(name_key, null)
			if name_val != null and str(name_val).strip_edges() != "":
				shown = str(name_val)
				break
	return CandyWriting.get_shared().translate(source, caller, shown, "display_names")

@warning_ignore_restore("unused_parameter")
