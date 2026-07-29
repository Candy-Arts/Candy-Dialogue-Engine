#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends CandyDialogueMode


func is_available(engine: CandyEngine) -> bool:
	return CandyVoice.get_shared().get_player(engine, self) != null

func display_node(engine: CandyEngine, _speech: CandySpeech) -> Node:
	return CandyVoice.get_shared().get_player(engine, self)
