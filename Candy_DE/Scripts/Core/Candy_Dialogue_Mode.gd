#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyDialogueMode
extends RefCounted


#* Mode name (its file name):
func mode_name() -> String:
	return get_script().resource_path.get_file().get_basename()

#* Prefix of the mode's engine and actor settings:
func settings_prefix() -> String:
	return mode_name().to_lower()

#* Whether the mode can display lines, without reporting:
#? An unavailable line or actor mode falls through to the next level's.
func is_available(_engine: CandyEngine) -> bool:
	return true

#* Get a line ready, or hand it to another mode:
#+ Store what display_node() needs in 'speech'.
func prepare(_engine: CandyEngine, _speech: CandySpeech) -> String:
	return mode_name()	#/ Or another mode's (Bubbles → VN_Bubbles), or "" for the bubbles exempt mode

#* The node whose display() shows the line:
func display_node(_engine: CandyEngine, _speech: CandySpeech) -> Node:
	return null	#/ None: Spoken_Line reports it

#* Called as a line in this mode starts, after the previous mode cleared:
func start_line(_engine: CandyEngine, _speech: CandySpeech) -> void:
	pass

#* Clear this mode's line as the next line starts:
#? next_mode may be this mode.
func clear_line(_engine: CandyEngine, _previous_speaker: String, _next_mode: String) -> void:
	pass
