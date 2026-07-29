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
	"Writing_Speed": ["writing_speed", ""],
	"Continue_Fast_Speed": ["continue_fast_speed", ""],
	"Continue_Slow_Speed": ["continue_slow_speed", ""],
	"Auto_Advance": ["auto_advance", ""],
	"Auto_Advance_Per_Character": ["auto_advance_per_character", ""],
	"Sync_Write_Speed_Voice": ["sync_write_speed_voice", ""],
	"Await_Voice_Playback": ["await_voice_playback", ""],
}


func execute(engine: CandyEngine, command_value: Variant, _ctx: CandyContext) -> String:
	CandyEngineSettings.get_shared().apply_keys(engine, self, command_value, KEYS, "Engine_Writing")
	return "Continue"
