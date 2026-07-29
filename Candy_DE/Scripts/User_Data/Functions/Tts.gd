#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends CandyFunction


#& TTS INTEGRATION
#* Use Text-To-Speech for a line:
#? Only for voiced lines whose TTS mode isn't "Off".
@warning_ignore("unused_parameter")
func tts(candy_args: Dictionary, user_args: Array, custom_data: Array):
	var mode: String = candy_args["mode"]		#/ Already picked (tts_advanced_fallback if no "_TTS" variation)
	@warning_ignore("unused_variable")
	var text: String = candy_args["text"]
	var output = null

	match mode:
		"Simple":
			#TODO: Hook to your TTS implementation: read 'text', and put the audio in 'output'.
			pass

		"Advanced":
			#? 'text' is the "_TTS" variation, which may hold markup for your TTS engine (e.g. SSML).
			#TODO: Hook to your TTS implementation: read 'text', and put the audio in 'output'.
			pass

		#% Add a case for each TTS mode of your own:
		_:
			printerr("Tts.gd: unknown TTS mode '", mode, "' - add it to tts().")

	return output		#/ AudioStream, audio file path (res:// or user://), or null: the voice file plays instead
