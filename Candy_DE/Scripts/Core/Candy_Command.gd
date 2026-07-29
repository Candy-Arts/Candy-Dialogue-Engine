#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyCommand
extends RefCounted


#* Run the command:
#+ Return "Continue", "Return" (unwind) or "END" (end the dialogue).
#+ Can use await.
func execute(_engine: CandyEngine, _command_value: Variant, _ctx: CandyContext) -> String:
	push_error("CandyCommand: " + str(get_script().resource_path) + " does not override execute().")
	return "Continue"
