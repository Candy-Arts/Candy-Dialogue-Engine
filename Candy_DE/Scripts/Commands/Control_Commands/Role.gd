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
	var cr: CandyRef = engine.candy_ref
	var sym: String = candy_de.candy_ref_symbol

	var raw_role		= command_value.get("Role", "")
	#? A role copies its actor ("°guard" → guard's actor).
	var actor_ref		= CandyActors.get_shared().actor_from_role(engine, self, cr.resolve_value(engine, engine, command_value.get("Reference", ""), sym), "Role", cr.last_literal)

	#@ Step 1 - Resolve the Role name:
	#? "°guard" or "guard". With the symbol: evaluated to get it.
	var role_value = cr.resolve_value(engine, engine, raw_role, sym)
	if cr.last_failed or role_value == null:
		printerr("Role: could not resolve Role → ", raw_role)
		return "Continue"

	#@ Step 2 - Normalize the role key:
	var role_key := str(role_value).strip_edges()
	if role_key == "":
		printerr("Role: Role resolved to an empty name → ", raw_role)
		return "Continue"

	#Ł Strip role_symbol:
	if role_key.begins_with(candy_de.role_symbol):
		role_key = role_key.substr(candy_de.role_symbol.length()).strip_edges()
	if role_key == "":
		printerr("Role: Role has no name after the role symbol → ", raw_role)
		return "Continue"

	#@ Step 3 - Empty actor reference:
	if actor_ref == null or str(actor_ref) == "":
		print_debug("Role: [CAUTION] A Role Reference is provided for assignment, but has no Actor assigned. Target Role will be cleared.")

	#@ Step 4 - Assign to candy_de.roles:
	candy_de.roles[role_key] = actor_ref

	return "Continue"
