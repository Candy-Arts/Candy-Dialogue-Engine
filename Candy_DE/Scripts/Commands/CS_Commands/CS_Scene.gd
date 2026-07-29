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
	var cutscene := CandyCutscene.get_shared()

	for target in cutscene.get_targets(engine, self, command_value, "Targets", "CS_Scene"):
		var parent: Node = target[0]
		var instances: Variant = target[1].get("Instances")
		if typeof(instances) != TYPE_DICTIONARY:
			printerr("CS_Scene: 'Instances' of ", target[2], " must be a Dictionary of instances → ", instances)
			continue

		for instance_ref in instances:
			var instance_settings: Variant = instances[instance_ref]
			if typeof(instance_settings) != TYPE_DICTIONARY:
				printerr("CS_Scene: settings for instance '", instance_ref, "' of ", target[2], " must be a Dictionary → ", instance_settings)
				continue
			var settings := cutscene.resolve_settings(engine, self, instance_settings)

			#@ Step 1 - Load the scene:
			#? Untyped, so a non-scene resource reaches the check.
			var packed_scene = settings.get("Scene", "")
			if typeof(packed_scene) == TYPE_STRING:
				var scene_path: String = packed_scene.strip_edges()
				packed_scene = null
				if scene_path != "" and CandyMedia.exists(scene_path):
					packed_scene = load(scene_path)
			if not (packed_scene is PackedScene):
				printerr("CS_Scene: could not load Scene for instance '", instance_ref, "' of ", target[2], " → ", settings.get("Scene", ""))
				continue

			#@ Step 2 - Instance it under the parent:
			var instance: Node = packed_scene.instantiate()
			var instance_name := str(engine.candy_ref.resolve_value(engine, engine, instance_ref, candy_de.candy_ref_symbol)).strip_edges()
			if instance_name != "":
				instance.name = instance_name
			parent.add_child(instance)

	return "Continue"
