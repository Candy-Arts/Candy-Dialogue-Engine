#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyInputEvent
extends RefCounted


#* Handle the event:
#? parameters: what the scene sent with the event.
#+ Return "Wait" (keep waiting for events), "Continue", "Return" (unwind one level) or "END" (end the dialogue).
#+ To unwind several levels, run Return and pass on its result ({"Levels": parameters} lets the scene choose):
#+   return await engine.commands("Return", {"Levels": 2}, ctx)
#+ Can use await.
func handle(_engine: CandyEngine, _input_ui: Node, _depth: int, _parameters: Variant, _ctx: CandyContext) -> String:
	push_error("CandyInputEvent: " + str(get_script().resource_path) + " does not override handle().")
	return "Continue"
