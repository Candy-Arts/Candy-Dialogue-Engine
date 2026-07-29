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
	var mode: String = str(engine.candy_ref.resolve_value(engine, engine, str(command_value.get("Mouse_Mode", "")), candy_de.candy_ref_symbol))

	match mode.to_lower():
		"visible":
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		"hidden":
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		"captured":
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		"confined":
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		"confined_hidden":
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		"dialogue_start":
			match engine.mouse_mode_start:
				CandyEngine.MouseModes.None:
					if OS.is_debug_build() and engine.debug_prints == true:
						print("[DEBUG] Mouse: mouse_mode_start is None; mouse mode left unchanged.")
				CandyEngine.MouseModes.Visible:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				CandyEngine.MouseModes.Hidden:
					Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
				CandyEngine.MouseModes.Captured:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				CandyEngine.MouseModes.Confined:
					Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
				CandyEngine.MouseModes.Confined_Hidden:
					Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		"dialogue_end":
			match engine.mouse_mode_end:
				CandyEngine.MouseModes.None:
					if OS.is_debug_build() and engine.debug_prints == true:
						print("[DEBUG] Mouse: mouse_mode_end is None; mouse mode left unchanged.")
				CandyEngine.MouseModes.Visible:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				CandyEngine.MouseModes.Hidden:
					Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
				CandyEngine.MouseModes.Captured:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				CandyEngine.MouseModes.Confined:
					Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
				CandyEngine.MouseModes.Confined_Hidden:
					Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		"choice":
			match engine.mouse_mode_choice:
				CandyEngine.MouseModes.None:
					if OS.is_debug_build() and engine.debug_prints == true:
						print("[DEBUG] Mouse: mouse_mode_choice is None; mouse mode left unchanged.")
				CandyEngine.MouseModes.Visible:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				CandyEngine.MouseModes.Hidden:
					Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
				CandyEngine.MouseModes.Captured:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				CandyEngine.MouseModes.Confined:
					Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
				CandyEngine.MouseModes.Confined_Hidden:
					Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		_:
			if OS.is_debug_build() and engine.debug_prints == true:
				print("[DEBUG] Mouse: Unknown Mouse_Mode '%s'; keeping current mode." % mode)

	return "Continue"
