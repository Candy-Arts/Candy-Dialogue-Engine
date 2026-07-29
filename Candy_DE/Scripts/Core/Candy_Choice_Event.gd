#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyChoiceEvent
extends RefCounted


#* Handle the event:
#? category, choice, sender: the signal's 'category', 'choice' and 'source' ("timer" sends the timer name as 'choice').
#+ Return "Wait" (keep the menu open), "Continue", "Return" (unwind one level) or "END" (end the dialogue).
#+ Close the menu before leaving:
#+   await CandyChoices.get_shared().close_menu(engine, self, depth, menu)
#+ To unwind several levels, close the menu, then run Return and pass on its result:
#+   return await engine.commands("Return", {"Levels": 2}, ctx)
#+ Can use await.
func handle(_engine: CandyEngine, _menu: Node, _depth: int, _category: Variant, _choice: Variant, _sender: Object, _ctx: CandyContext) -> String:
	push_error("CandyChoiceEvent: " + str(get_script().resource_path) + " does not override handle().")
	return "Wait"
