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


func execute(engine: CandyEngine, command_value: Variant, _ctx: CandyContext) -> String:
	var clear_dialogue_box: int		= int(engine.candy_ref.resolve_value(engine, engine, command_value.get("Box", "1"), candy_de.candy_ref_symbol))
	var clear_bubbles: int			= int(engine.candy_ref.resolve_value(engine, engine, command_value.get("Bubbles", "1"), candy_de.candy_ref_symbol))
	var clear_subtitles: int		= int(engine.candy_ref.resolve_value(engine, engine, command_value.get("Subtitles", "1"), candy_de.candy_ref_symbol))
	var clear_portraits: int		= int(engine.candy_ref.resolve_value(engine, engine, command_value.get("Portraits", "1"), candy_de.candy_ref_symbol))
	var clear_bg: int				= int(engine.candy_ref.resolve_value(engine, engine, command_value.get("Backgrounds", "1"), candy_de.candy_ref_symbol))
	var clear_busts: int			= int(engine.candy_ref.resolve_value(engine, engine, command_value.get("Busts", "1"), candy_de.candy_ref_symbol))

	var custom_data: Array = CandyCustomData.levels([command_value])

	#@ Step 1 - Clear dialogue box:
	if clear_dialogue_box == 1:
		CandyWriting.get_shared().clear_text_ui(engine, self, "dialogue_box_path", true, true, true, custom_data)

	#@ Step 2 - Clear actor and VN bust bubbles:
	#? 0 = don't clear, 1 = this engine's last bubbles, 2 = every bubble.
	if clear_bubbles != 0 and clear_bubbles != 1 and clear_bubbles != 2:
		printerr("UI_Clear: invalid 'Bubbles' value (%s) - expected 0, 1 or 2. Treated as 0." % str(clear_bubbles))
		clear_bubbles = 0

	if clear_bubbles != 0:
		var master: bool = clear_bubbles == 2
		for root in [engine.get_node_or_null(engine.bubbles_npc_path), engine.get_node_or_null(engine.bubbles_player_path)]:
			if root == null:
				continue
			for actor in root.get_children():
				CandyWriting.get_shared().clear_actor_bubble(engine, self, actor, custom_data, master)
		CandyWriting.get_shared().clear_vn_bubbles(engine, self, custom_data, master)

	#@ Step 3 - Clear subtitles:
	if clear_subtitles == 1:
		CandyWriting.get_shared().clear_text_ui(engine, self, "subtitles_path", true, true, true, custom_data)

	#@ Step 4 - Clear portraits:
	#? Through the dialogue box.
	if clear_portraits == 1:
		var portrait := CandyUI.get_shared().get_element(engine, self, "dialogue_box_path")
		if portrait:
			if portrait.has_method("no_portrait"):
				portrait.no_portrait(custom_data)
			elif "portrait_node" in portrait and portrait.portrait_node != null \
			and "texture" in portrait.portrait_node:
				portrait.portrait_node.visible = false
				portrait.portrait_node.texture = null

	#@ Step 5 - Clear VN busts:
	#? 0 = don't clear, 1 = clear, 2 = play each actor's Leave effect first.
	if clear_busts != 0 and clear_busts != 1 and clear_busts != 2:
		printerr("UI_Clear: invalid 'Busts' value (%s) - expected 0, 1 or 2. Treated as 0." % str(clear_busts))
		clear_busts = 0

	#% If the bust scene admits it:
	if clear_busts != 0:
		var busts_root := CandyUI.get_shared().get_element(engine, self, "busts_path")
		if busts_root and CandyPlayback.get_shared().admit(engine, self, busts_root, "busts_path", "", "UI_Clear"):
			await busts_root.clear_busts({"caller": engine}, clear_busts == 2, custom_data)

	#@ Step 6 - Clear backgrounds:
	#% If the background scene admits it:
	if clear_bg == 1:
		var bg_scene := CandyUI.get_shared().get_element(engine, self, "backgrounds_path")
		if bg_scene and CandyPlayback.get_shared().admit(engine, self, bg_scene, "backgrounds_path", "", "UI_Clear"):
			bg_scene.clear_layers(custom_data)

	#@ Step 7 - Clear barks:
	#? Always cleared.
	CandyWriting.get_shared().clear_text_ui(engine, self, "barks_path", true, true, true, custom_data)

	return "Continue"
