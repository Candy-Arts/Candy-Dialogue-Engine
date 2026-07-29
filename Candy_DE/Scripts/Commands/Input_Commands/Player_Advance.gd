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


func execute(engine: CandyEngine, _command_value: Variant, _ctx: CandyContext) -> String:
	if OS.is_debug_build() and engine.debug_prints == true:
		print("Player_Advance: waiting for input.")

	await CandyWriting.get_shared().wait_for_player_advance(engine, self, null, true)

	#% Killswitch:
	if engine.killswitch == true:
		return "END"

	return "Continue"
