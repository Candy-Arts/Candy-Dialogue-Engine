#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends CandyCommand


func execute(engine: CandyEngine, command_value: Variant, _ctx: CandyContext) -> String:
	var cr: CandyRef = engine.candy_ref
	var sym: String = candy_de.candy_ref_symbol

	var actor_ref: String	= str(CandyActors.get_shared().actor_from_role(engine, self, cr.resolve_value(engine, engine, command_value.get("Reference", ""), sym), "Disposition", cr.last_literal))
	var new_disp: String	= str(cr.resolve_value(engine, engine, command_value.get("Disposition", ""), sym))

	#Ł Apply change:
	if candy_de.actors.has(actor_ref):
		candy_de.actors[actor_ref]["Disposition"] = new_disp
	else:
		printerr("Disposition: actor not found → ", actor_ref)

	return "Continue"
