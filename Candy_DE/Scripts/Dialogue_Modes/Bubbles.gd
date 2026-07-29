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


#* Hand the line to VN_Bubbles in VN mode, else find the speaker's bubble:
func prepare(engine: CandyEngine, speech: CandySpeech) -> String:
	var bust_scene = CandyUI.get_shared().get_element(engine, self, "busts_path")
	if engine.vn_mode == true and bust_scene != null:
		return "VN_Bubbles"

	#Ł Find the speaker's actor node:
	var speaker_node = null
	if speech.speaker_ref in candy_de.player_refs:
		speaker_node = engine.get_node_or_null(str(engine.bubbles_player_path.path_join(speech.speaker_ref)))
	else:
		speaker_node = engine.get_node_or_null(str(engine.bubbles_npc_path.path_join(speech.speaker_ref)))

	#% No actor node, or no speech bubble on it → exempt mode:
	#? Per speaker, so checked here, not in is_available().
	if speaker_node == null or speaker_node.get("internal_node_dict") == null \
			or not speaker_node.internal_node_dict.has("Speech_Bubble") \
			or speaker_node.internal_node_dict["Speech_Bubble"] == null:
		return ""

	speech.speaker_node = speaker_node
	return mode_name()

func display_node(_engine: CandyEngine, speech: CandySpeech) -> Node:
	if speech.speaker_node == null:
		return null
	return speech.speaker_node.internal_node_dict["Speech_Bubble"]

#* Clear every actor's bubble:
func start_line(engine: CandyEngine, _speech: CandySpeech) -> void:
	for actors_root in [engine.get_node_or_null(engine.bubbles_npc_path), engine.get_node_or_null(engine.bubbles_player_path)]:
		if actors_root == null:
			continue
		for actor in actors_root.get_children():
			CandyWriting.get_shared().clear_actor_bubble(engine, self, actor)

#* Clear the previous speaker's bubble:
func clear_line(engine: CandyEngine, previous_speaker: String, _next_mode: String) -> void:
	var npc_path_node := engine.get_node_or_null(engine.bubbles_npc_path)
	if npc_path_node:
		CandyWriting.get_shared().clear_actor_bubble(engine, self, npc_path_node.get_node_or_null(previous_speaker))

	var player_path_node := engine.get_node_or_null(engine.bubbles_player_path)
	if player_path_node and player_path_node != npc_path_node:
		CandyWriting.get_shared().clear_actor_bubble(engine, self, player_path_node.get_node_or_null(previous_speaker))
