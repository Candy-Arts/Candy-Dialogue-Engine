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


func execute(engine: CandyEngine, command_value: Variant, ctx: CandyContext) -> String:
	var cr: CandyRef = engine.candy_ref
	var sym: String = candy_de.candy_ref_symbol

	var signal_raw	= command_value.get("Signal", "")
	var store_var	= command_value.get("Variable", "")

	#% Validate:
	if typeof(signal_raw) == TYPE_STRING and signal_raw.strip_edges() == "":
		push_error("Await: \"Signal\" is an empty string.")
		return "Continue"

	#@ Step 1 - Find the signal:
	#? "globals.my_signal", "$UI/Box.pressed" or an engine signal. With the symbol: evaluated to get it.
	var target = CandyTargets.get_shared().resolve_named(engine, self, signal_raw)
	if cr.last_failed or typeof(target) != TYPE_SIGNAL:
		printerr("Await: not a signal → ", signal_raw)
		return "Continue"

	var sig: Signal = target
	var signal_target: Object = sig.get_object()
	var sig_str := str(sig.get_name())
	if not is_instance_valid(signal_target):
		printerr("Await: the signal's object no longer exists → ", signal_raw)
		return "Continue"

	#Ł Event script:
	var event_script: CandyAwaitEvent = null
	if engine.await_event_registry.has(sig_str.to_lower()):
		event_script = engine.await_event_registry[sig_str.to_lower()]

	#¬ Repeat while the event script returns "Wait":
	while true:
		#@ Step 2 - Await the signal, killswitch or emitter deletion:
		var woken: Array = await _wait_for(engine, sig, signal_target)

		if woken[0] == "killswitch" or engine.killswitch == true:
			return "END"

		if woken[0] == "deleted":
			printerr("Await: the signal's object was deleted before emitting it → ", signal_raw)
			return "Continue"

		var args: Array = woken[1]

		#@ Step 3 - Store arguments:
		if not (typeof(store_var) == TYPE_STRING and store_var.strip_edges() == ""):
			var store_value
			if args.size() == 0:
				store_value = null
			elif args.size() == 1:
				store_value = args[0]
			else:
				store_value = args

			var found := cr.resolve_target(engine, engine, store_var, sym)
			if not found["ok"] or not CandyTargets.get_shared().write_target(engine, self, found, store_value, "=", "Await"):
				printerr("Await: failed to store result in → ", store_var)

		if OS.is_debug_build() and engine.debug_prints == true:
			print("[DEBUG] Await completed → ", sig_str)

		#@ Step 4 - Run the event script:
		if event_script == null:
			return "Continue"

		@warning_ignore("redundant_await")
		var outcome: String = await event_script.handle(engine, signal_target, args, ctx)

		if engine.killswitch == true or outcome == "END":
			return "END"

		if outcome == "Continue" or outcome == "Return":
			return outcome

		if outcome != "Wait":
			push_warning("Candy DE: Await event '%s' returned '%s' - expected \"Wait\", \"Continue\", \"Return\" or \"END\". Leaving the Await." % [sig_str, outcome])
			return "Continue"

		#% "Wait" - emitter may be gone:
		if not is_instance_valid(signal_target):
			printerr("Await: the signal's object no longer exists → ", signal_raw)
			return "Continue"

	return "Continue"


#* Wait for the signal, the killswitch or the emitter's deletion:
func _wait_for(engine: CandyEngine, sig: Signal, emitter: Object) -> Array:
	#@ Step 1 - All three relay to one "finished" signal (await takes one signal):
	var relay := RefCounted.new()
	relay.add_user_signal("finished")

	var on_signal := func(...args: Array) -> void:
		relay.emit_signal("finished", ["signal", args])
	var on_killswitch := func() -> void:
		relay.emit_signal("finished", ["killswitch", []])

	#@ Step 2 - Leaving the tree may just be a move - check a moment later:
	#? By instance ID: a lambda capturing a deleted node errors.
	var emitter_id := emitter.get_instance_id()
	var check_deleted := func() -> void:
		if not is_instance_id_valid(emitter_id):
			relay.emit_signal("finished", ["deleted", []])
	var on_tree_exiting := func() -> void:
		check_deleted.call_deferred()

	sig.connect(on_signal, CONNECT_ONE_SHOT)
	engine.killswitch_raised.connect(on_killswitch, CONNECT_ONE_SHOT)
	#! Only a Node's deletion is noticed: a deleted plain Object keeps it waiting.
	if emitter is Node:
		emitter.tree_exiting.connect(on_tree_exiting)

	var result: Array = await Signal(relay, "finished")

	#@ Step 3 - Disconnect:
	if engine.killswitch_raised.is_connected(on_killswitch):
		engine.killswitch_raised.disconnect(on_killswitch)
	if is_instance_valid(emitter):
		if sig.is_connected(on_signal):
			sig.disconnect(on_signal)
		if emitter is Node and emitter.tree_exiting.is_connected(on_tree_exiting):
			emitter.tree_exiting.disconnect(on_tree_exiting)

	return result		#/ [what came first ("signal", "killswitch" or "deleted"), the signal's arguments]
