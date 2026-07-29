#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyCustomData
extends RefCounted


const META_KEY := "Meta"
const CUSTOM_KEY := "Custom_Data"
const ENTRY_PREFIX := "Custom_"


#* One level's values, Custom_1 first, or []:
static func level(data: Variant) -> Array:
	if typeof(data) != TYPE_DICTIONARY:
		return []
	var meta: Variant = data.get(META_KEY)
	if typeof(meta) != TYPE_DICTIONARY:
		return []
	var custom: Variant = meta.get(CUSTOM_KEY)
	if typeof(custom) != TYPE_DICTIONARY:
		return []

	var numbered: Array = []		#/ [number, value]
	for key in custom:
		var number := str(key).trim_prefix(ENTRY_PREFIX)
		if str(key).begins_with(ENTRY_PREFIX) and number.is_valid_int():
			numbered.append([int(number), custom[key]])
	numbered.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])

	var values: Array = []
	for entry in numbered:
		values.append(entry[1])
	return values


#* Levels of a chain of Dictionaries, command first:
static func levels(chain: Array) -> Array:
	var result: Array = []
	for data in chain:
		result.append(level(data))
	return result


#* Parent's levels plus one level ('parent' is left unchanged):
static func extend(parent: Array, data: Variant) -> Array:
	var result: Array = parent.duplicate()
	result.append(level(data))
	return result


#* Levels of a line, {"Command_Name" = {...}}:
static func of_line(line_data: Variant) -> Array:
	if typeof(line_data) != TYPE_DICTIONARY or line_data.size() != 1:
		return []
	return levels([line_data.values()[0]])
