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
	return CandyUI.get_shared().get_element(engine, self, "subtitles_path") != null

func display_node(engine: CandyEngine, _speech: CandySpeech) -> Node:
	return CandyUI.get_shared().get_element(engine, self, "subtitles_path", "Spoken_Line")

#* Clear the subtitles when the next line is in another mode:
func clear_line(engine: CandyEngine, _previous_speaker: String, next_mode: String) -> void:
	if next_mode == mode_name():
		return
	CandyWriting.get_shared().clear_text_ui(engine, self, "subtitles_path", true, true, false)
