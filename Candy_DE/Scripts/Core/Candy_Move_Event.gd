#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyMoveEvent
extends RefCounted


#* Move the node:
#+ Return "Continue", "Return" (unwind one level) or "END" (end the dialogue).
#+ Can use await.
#+ Return without awaiting for a movement the dialogue shouldn't wait for.
#+ Find a node "Data" names (e.g. a marker) like targets:
#+   var marker := CandyCutscene.get_shared().resolve_target(engine, self, data, "CS_Move")
#+ Check engine.killswitch after each await to stop at dialogue end.
func handle(_engine: CandyEngine, _node: Node, _data: Variant, _ctx: CandyContext, _custom_data: Array) -> String:
	push_error("CandyMoveEvent: " + str(get_script().resource_path) + " does not override handle().")
	return "Continue"
