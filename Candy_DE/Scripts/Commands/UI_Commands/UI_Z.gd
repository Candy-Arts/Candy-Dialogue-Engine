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
	if typeof(command_value) != TYPE_DICTIONARY:
		printerr("UI_Z: expected a Dictionary → ", command_value)
		return "Continue"
	var nodes: Variant = command_value.get("Nodes")
	if typeof(nodes) != TYPE_DICTIONARY:
		printerr("UI_Z: 'Nodes' must be a Dictionary of nodes → ", nodes)
		return "Continue"

	for node_ref in nodes:
		var settings: Variant = nodes[node_ref]
		if typeof(settings) != TYPE_DICTIONARY:
			printerr("UI_Z: settings for '", node_ref, "' must be a Dictionary → ", settings)
			continue

		#@ Step 1 - Find the node:
		var node_key: Variant = engine.candy_ref.resolve_value(engine, engine, node_ref, candy_de.candy_ref_symbol)
		var node: Node = CandyUI.get_shared().find_node(engine, self, node_key)
		if node == null:
			printerr("UI_Z: node not found → ", node_ref)
			continue
		if not (node is CanvasItem):
			printerr("UI_Z: '", node_ref, "' has no z index (it isn't a CanvasItem) → ", node.name)
			continue

		#@ Step 2 - Find the "Relative_To" node:
		var relative_ref: Variant = engine.candy_ref.resolve_value(engine, engine, settings.get("Relative_To", ""), candy_de.candy_ref_symbol)
		var relative_node: Node = CandyUI.get_shared().find_node(engine, self, relative_ref, "UI_Z")

		#@ Step 3 - Move the node:
		var z_value: Variant = engine.candy_ref.resolve_value(engine, engine, settings.get("Z_Index", "Reset"), candy_de.candy_ref_symbol)
		var z_order: Variant = CandyPlayback.get_shared().read_z_value(engine, self, relative_node, z_value, "Z_Index", "UI_Z")
		if z_order == null or z_order.is_empty():
			continue

		if z_order.has("reset"):
			if "default_z" in node:
				node.z_index = node.default_z
			else:
				printerr("UI_Z: can't Reset '", node_ref, "': it has no default_z → ", node.name)
		else:
			node.z_index = z_order["z"]

	return "Continue"
