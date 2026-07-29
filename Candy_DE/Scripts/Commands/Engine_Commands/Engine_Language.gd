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


const KEYS := {
	"Language": ["engine_language", ""],
	"Voice_Language": ["voice_language", ""],
}


func execute(engine: CandyEngine, command_value: Variant, _ctx: CandyContext) -> String:
	CandyEngineSettings.get_shared().apply_keys(engine, self, command_value, KEYS, "Engine_Language")
	return "Continue"
