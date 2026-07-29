#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyAwaitEvent
extends RefCounted


#* Handle the signal:
#? Returns "Wait" (wait for the signal again), "Continue", "Return" (unwind one level) or "END".
#+ To unwind several levels: return await engine.commands("Return", {"Levels": 2}, ctx)
#+ Can use await.
func handle(_engine: CandyEngine, _emitter: Object, _arguments: Array, _ctx: CandyContext) -> String:
	push_error("CandyAwaitEvent: " + str(get_script().resource_path) + " does not override handle().")
	return "Continue"
