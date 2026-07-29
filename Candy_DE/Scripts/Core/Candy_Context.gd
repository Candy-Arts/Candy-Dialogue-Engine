#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandyContext
extends RefCounted


#^ Position in the dialogue:
var conversation = ""
var block = ""
var line_index = 0

#^ Full line dictionary (every command's keys):
var line_data: Dictionary = {}

#^ Part of the main dialogue run:
var main: bool = true

#^ Synthetic line (If/For/While bodies, choices...):
var nested: bool = false

#^ Spoken_Line outcome:
#? "Displayed": the line was shown.
#? "Counted": skipped, but counts for Media_Pause.
#? "Skipped": skipped, doesn't count.
var speech_outcome: String = ""
