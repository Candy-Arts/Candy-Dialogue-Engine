#!###########################################################################################
#!																							#
#!         THIS SCRIPT CONTAINS CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS        #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                 Any unauthorized use constitutes copyright infringement.                 #
#!																							#
#!   This disclaimer must be featured at the top of any script featuring Candy Arts code,   #
#!                            and may not be removed or modified.                           #
#!																							#
#!###########################################################################################


extends "res://First_Install/Scripts/User_Data/Candy_Database.gd"


#& GAME STATE INTEGRATION:
#? If your game uses a variable to track game state (e.g. exploration, combat, dialogue...),
#? this function changes the value to the 'dialogue' state when dialogue is initiated, and back to the previous state when dialogue ends.

#? This function uses two PLACEHOLDER variables: 'global.game_state' and 'global.previous_state'.
#? 'global.game_state' represents the current game state.
#? 'global.previous_state' represents a variable that memorizes which game state to return to after dialogue ends or after other momentary game state changes.

#% For example, when the player opens the inventory during combat or exploration, the game state would switch to "inventory";
#% Since the game will return to the previous state once  the inventory is closed, 'global.previous_state' would store the value "combat" or "explore".
#% Once the inventory is closed, 'global.game_state' = 'global.previous_state' i.e. 'global.game_state' = "combat" or "explore".

#TODO: Instructions:
#TODO: 1) Set 'use_game_state' to true to enable the function.
#TODO: 2) Replace 'global.game_state' and 'global.previous_state' everywhere in the function to whatever variables you use in your game.
#TODO: 3) Change the VALUE of dialogue_state_value to match the value you want to use in your game for the 'dialogue' state!
#TODO: 4) If the default function code doesn't fit your game state implementation, modify as needed.

#+ The function has no effect on Candy DE's functioning, it only needs to set game state correctly in your own game code.
#+ i.e. there is no need to consider Candy DE's code, nothing you change here will break Candy DE.

#* Change Game State value when dialogue starts:
func change_game_state(caller, method):		#/ 'method' indicates whether the function was called when dialogue started or ended
	var game_state		#/ Placeholder: replace with your own (e.g. global.game_state)
	var previous_state	#/ Placeholder: replace with your own (e.g. global.previous_state)

	#@ Setup:
	#%	Does your game use a game state tracker variable?
	var use_game_state = false		#TODO: Switch to true.

	#% Exit the function if game doesn't use game state tracker:
	if use_game_state == false:
		return

	#% Only change state if called by the main Candy_UI:
	if caller.engine_mode != "UI":
		return

	#% What value represents "dialogue" in your game state tracker?
	var dialogue_state_value = "dialogue"	#TODO: assign the value you want to use for the dialogue state.

	#@ If your game uses a game state tracker:
	if use_game_state == true:
		#% When dialogue starts:
		if method == "start":
			#% Store previous game state before dialogue starts:
			@warning_ignore("unassigned_variable")
			previous_state = game_state	#TODO: replace both variables with your own.

			#% Change game_state value to indicate dialogue state:
			game_state = dialogue_state_value	#TODO: replace global.game_state with your own.

		#% When dialogue ends:
		if method == "end":
			#% Revert to previous game state value:
			game_state = previous_state	#TODO: replace both variables with your own.

			#? If you don't want to revert to the previous state when dialogue ends,
			#? change global.previous_state accordingly before the end of the dialogue,
			#? e.g. with the §Call function during dialogue,
			#? or modify the "end" code above.


#& DIALOGUE HISTORY
#? Two functions are provided for displaying dialogue history:
#? 1) One to diplay a specific dialogue engine instance's history - e.g. candy_ui.
#? 2) Another to display the general dialogue history.
#TODO You must setup methods to call these functions in your game:
#TODO e.g. key press, button click, signal...

#* Dialogue engine instance history:
#% Make sure the correct dialogue engine instance is passed as 'caller' when the function is called.
func open_instance_history(caller):
	var history_ui = get_node(caller.history_display_path)
	history_ui.caller = caller
	history_ui.show_history()

#* General history:
#% Call this from anywhere.
func open_general_history():
	var history_ui = get_node("")	#TODO: Add the path to your scene that displays the general history
	history_ui.caller = null
	history_ui.show_history()


#& LEXICON
#* When Lexicon keyword clicked:
#? Called when a lexicon keyword is clicked, if made clickable with the BBCode [url] tag.
#? Determines what happens when a Lexicon keyword is clicked.
#TODO: Write your own code to define the desired behavior.
#TODO: Possibly use the 'suspend dialogue' features to pause dialogue, media, animations, etc.
#TODO: while the click behavior is ongoing. See the Lexicon guide for details on that feature.
@warning_ignore("unused_parameter")
func _on_lexicon_clicked(data, caller, ui):
	@warning_ignore("unused_variable")
	var keyword = data["keyword"]
	@warning_ignore("unused_variable")
	var keyword_data = data["keyword_click_data"]
	@warning_ignore("unused_variable")
	var keyword_variant = data["keyword_variant"]
	pass


#& CLEAR VN BUSTS:
#* Clear VN busts when dialogue isn't running:
#% Call to clear busts outside of dialogues when using persistent busts.
func clear_busts_ood(caller):
	var busts_root := get_node_or_null(caller.busts_path)
	if busts_root:
		busts_root.visible = false
		busts_root.clear_bust_nodes([])

	#% Clear dictionary that tracks bust positions:
	caller.bust_positions.clear()


#& CLEAR BG LAYERS:
#* Clear BG layers when dialogue isn't running:
#% Call to clear BG layers outside of dialogues when using persistent busts.
func clear_bg_layers_ood(caller):
	var bg_root := get_node_or_null(caller.backgrounds_path)
	if bg_root:
		bg_root.visible = false
		bg_root.clear_bg_nodes([])


#& TTS INTEGRATION
#* Use Text-To-Speech for a line:
func tts(caller, mode, _speaker_ref, raw_dialogue, line_data, variant):
	var tts_variant = ""
	@warning_ignore("unused_variable")
	var tts_text = ""
	var output

	#@ If "Advanced", check that a TTS variant exists, otherwise fallback to "Simple":
	if caller.text_to_speech == caller.TtsModes.Advanced:
		tts_variant = variant + "_TTS"
		if not line_data["Spoken Line"]["Variants"].has(tts_variant):
			mode = caller.tts_advanced_fallback

	match mode:
		caller.TtsModes.Off:
			return

		caller.TtsModes.Simple:
			tts_text = caller.bbcode_strip_tags(raw_dialogue)
			#TODO: Hook to your TTS implementation.
			@warning_ignore("unassigned_variable")
			return output

		caller.TtsModes.Advanced:
			tts_text = line_data["Spoken Line"]["Variants"][tts_variant]
			#TODO: Hook to your TTS implementation.
			@warning_ignore("unassigned_variable")
			return output


#& LLM INTEGRATION
#? This function is called when a speaker key contains the llm symbol (default "&"), unless var use_llm = false.
#? This function is intended to send a query to an LLM, and to return the LLM's response so it can be displayed as speech on screen.
#* Query LLM:
@warning_ignore("unused_parameter")
func llm_query(caller, actor_ref: String, actor_name: String, actor_disps: Array, line: String, chosen_variant_name: String) -> String:
	#TODO Write the query behavior:
	#% 1. Craft a prompt based on argument values.
	#% 2. Query an LLM through an API connected to the game.
	#% 3. (Optional) Use logic to edit or clean up the LLM output.
	#% 4. Return the LLM output to Candy DE.

	#? Tip: To use previous dialogue lines or player choices as part of prompt:
	#? A. refer to candy_ui.dialogue_history (candy_ui.write_dialogue_history must be 'true'),
	#? B. refer to current Block in dialogue script,
	#? C. use externalized functions each dialogue line to build your own history database

	#? Tip: You can use Lexicon entries as part of the prompt, assign custom prompt fragments
	#? or example speech to characters in the candy_de.actors dictionary, etc.

	#? Tip: Consider adding a fallback if llm_mode = true but no LLM is connected.
	#? E.g. a pre-written basic line, an error message, automatic query retry, etc.

	#+ Example prompt assembly:
	#+ llm_prompt =
	#+     actor_name + " " + candy_de.actors[actor_name]["LLM Prompt"] + ". " \
	#+   + actor_name + " " + line + ". " \
	#+   + actor_name + " generally " + actor_disps[0] + "s the player. " \
	#+   + global.general_llm_instruction
	#+
	#+ Resulting prompt (line breaks added for display - actual result is a single line and string):
	#+ "Alice is a kind, friendly, 20-year-old biology student. "
	#+ "Alice is happy because the player just gave her a birthday gift. "
	#+ "Alice generally Likes the player. "
	#+ "Write what Alice might say in 2 or 3 sentences."

	@warning_ignore("unused_variable")
	var llm_prompt = ""
	var llm_response = ""
	return llm_response


#& HOOK FUNCTIONS:
#? The functions below are called at various steps in the dialogue engine.
#? These functions are intended to let you run custom code at each step, if desired.
#? Be sure you understand when each function is called, otherwise you'll encounter unexpected results.
#TODO: You may add arguments to functions by finding where the engine calls them and adding the variables you need.
#TODO: The function calls can be moved almost anywhere in the engine logic, or more functions/calls can be added.

#* Called when a new line is processed:
@warning_ignore("unused_parameter")
func x_new_line(caller, line_data):
	pass

#* Called when a new command is processed:
@warning_ignore("unused_parameter")
func x_command_start(caller, line_data):
	pass

#* Called when a new spoken line is processed:
@warning_ignore("unused_parameter")
func x_new_speech_start(caller, line_data):
	pass

#* Called at the start of the line_display() function:
@warning_ignore("unused_parameter")
func x_new_speech_display(caller, line_data):
	pass

#* Called when dialogue ends:
@warning_ignore("unused_parameter")
func x_dialogue_end(caller):
	pass

#* Called by the §Flag command when a flag value is changed:
#? Can be used if you need flag changes to automatically trigger further effects.
@warning_ignore("unused_parameter")
func x_flag_changed(caller, flag, value):
	pass