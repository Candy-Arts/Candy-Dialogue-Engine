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


#* Query LLM:
#! Return a String: anything else keeps the line's original text.
@warning_ignore("unused_parameter")
func llm_query(candy_args: Dictionary, user_args: Array, custom_data: Array) -> String:
	@warning_ignore_start("unused_variable")
	var caller = candy_args["caller"]
	var actor_ref: String = candy_args["actor_ref"]
	var actor_name: String = candy_args["actor_name"]
	var actor_disps: Array = candy_args["actor_disps"]
	var text: String = candy_args["text"]
	var chosen_variation_name: String = candy_args["variation"]
	var dialogue: String = candy_args["dialogue"]
	var conversation: String = candy_args["conversation"]
	var block: String = candy_args["block"]
	var line_index: int = candy_args["line_index"]
	var line_data: Dictionary = candy_args["line_data"]
	@warning_ignore_restore("unused_variable")

	#TODO Write the query behavior:
	#+ Craft a prompt based on argument values.
	#+ Query an LLM through an API connected to the game.
	#+ (Optional) Use logic to edit or clean up the LLM output.
	#+ Return the LLM output to Candy DE.

	#? Tip: For previous lines or player choices in the prompt, use:
	#? A. candy_ui.dialogue_history (candy_ui.write_dialogue_history must be 'true'),
	#? B. the current Block in the dialogue,
	#? C. your own history, built from hooks on each line.

	#? Tip: Use Lexicon entries, or prompt fragments / example speech in candy_de.actors.

	#? Tip: Add a fallback for when no LLM is connected (pre-written line, error message, retry...).

	#+ Example prompt assembly:
	#+ llm_prompt =
	#+     actor_name + " " + candy_de.actors[actor_ref]["LLM_Prompt"] + ". " \
	#+   + actor_name + " " + text + ". " \
	#+   + actor_name + " generally " + actor_disps[0] + "s the player. " \
	#+   + global.general_llm_instruction
	#+
	#+ Resulting prompt (one string, split here for display):
	#+ "Alice is a kind, friendly, 20-year-old biology student. "
	#+ "Alice is happy because the player just gave her a birthday gift. "
	#+ "Alice generally Likes the player. "
	#+ "Write what Alice might say in 2 or 3 sentences."

	@warning_ignore("unused_variable")
	var llm_prompt = ""
	var llm_response = ""
	return llm_response
