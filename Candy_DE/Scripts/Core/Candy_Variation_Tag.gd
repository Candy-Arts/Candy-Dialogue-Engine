#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyVariationTag
extends RefCounted


#* The tag's value now, compared by the default matches():
#? speaker: the speaking actor's reference, roles resolved.
#+ Can use await.
func current_value(_engine: CandyEngine, _speaker: String, _ctx: CandyContext) -> String:
	push_error("CandyVariationTag: " + str(get_script().resource_path) + " overrides neither current_value() nor matches().")
	return ""


#* Whether a variation with this tag at 'value' can be picked:
#+ Can use await.
func matches(engine: CandyEngine, value: String, speaker: String, ctx: CandyContext) -> bool:
	@warning_ignore("redundant_await")
	var current: String = await current_value(engine, speaker, ctx)
	return current == value
