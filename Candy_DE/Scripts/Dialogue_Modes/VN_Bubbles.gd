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


#* Use the Bubbles settings:
func settings_prefix() -> String:
	return "bubbles"

#* Find the bubble on the speaker's bust:
func prepare(engine: CandyEngine, speech: CandySpeech) -> String:
	var bust_scene = CandyUI.get_shared().get_element(engine, self, "busts_path")
	if bust_scene == null:
		return ""

	var busts_container = null
	if "busts_container" in bust_scene:
		busts_container = bust_scene.busts_container

	var bust_node = null
	if busts_container != null and CandyUI.get_shared().has_bust(engine, self, speech.speaker_ref):
		bust_node = CandyUI.get_shared().actor_bust(engine, self, speech.speaker_ref)

	var vn_bubble_node = null
	var vn_bubble_text_node = null
	if bust_node != null and bust_node.has_node(bust_scene.speech_bubbles_name):
		vn_bubble_node = bust_node.get_node(bust_scene.speech_bubbles_name)
		#Ł Get bubble's text node:
		if "label" in vn_bubble_node:
			vn_bubble_text_node = vn_bubble_node.label
		if vn_bubble_text_node == null:
			printerr("Spoken_Line: VN speech bubble is missing its label node - falling back to the bubbles exempt mode.")

	#% No bust or usable bubble → exempt mode:
	if vn_bubble_node == null or vn_bubble_text_node == null:
		return ""

	speech.vn_bubble_node = vn_bubble_node
	speech.vn_bubble_text_node = vn_bubble_text_node
	return mode_name()

func display_node(_engine: CandyEngine, speech: CandySpeech) -> Node:
	return speech.vn_bubble_node

#* Clear the bust bubbles:
func clear_line(engine: CandyEngine, _previous_speaker: String, _next_mode: String) -> void:
	CandyWriting.get_shared().clear_vn_bubbles(engine, self)
