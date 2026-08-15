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



@tool
extends EditorScript


const FIRST_INSTALL_PATH = "res://First_Install"
const CANDY_DE_PATH      = "res://Candy_DE"

const AUTOLOADS = [
	{ "name": "candy_de", "path": "res://Candy_DE/Scripts/User_Data/Candy_Functions.gd" },
	{ "name": "candy_ui", "path": "res://Candy_DE/Scenes/Candy_UI.tscn" },
]

const INPUT_ACTIONS = [
	"Dialogue_Advance",
	"Dialogue_Skip",
	"Dialogue_Speed",
	"Dialogue_Slow",
]

const STRING_PATCHES = {
	"res://Candy_DE/Scripts/User_Data/Candy_Properties.gd": [
		["extends \"res://First_Install/Scripts/User_Data/Candy_Localizations.gd\"",
		"extends \"res://Candy_DE/Scripts/User_Data/Candy_Localizations.gd\""],
	],
	"res://Candy_DE/Scripts/User_Data/Candy_Database.gd": [
		["extends \"res://First_Install/Scripts/User_Data/Candy_Properties.gd\"",
		"extends \"res://Candy_DE/Scripts/User_Data/Candy_Properties.gd\""],
	],
	"res://Candy_DE/Scripts/User_Data/Candy_Functions.gd": [
		["extends \"res://First_Install/Scripts/User_Data/Candy_Database.gd\"",
		"extends \"res://Candy_DE/Scripts/User_Data/Candy_Database.gd\""],
	],
}


#* Run the patcher:
func _run():
	_move_all_files(FIRST_INSTALL_PATH, CANDY_DE_PATH)
	_delete_dir_recursive(FIRST_INSTALL_PATH)
	_apply_string_patches()
	_add_autoloads()
	_add_input_actions()

	EditorInterface.get_resource_filesystem().scan()
	print("Installation complete!")


#* Move files and folders from First_Install to Candy_DE:
func _move_all_files(from_path: String, to_path: String):
	var dir = DirAccess.open(from_path)
	dir.include_hidden = true
	if dir == null:
		push_error("Could not open source directory: " + from_path)
		return

	#% Ensure destination exists.
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(to_path)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(to_path))

	dir.list_dir_begin()
	var entry = dir.get_next()

	while entry != "":
		#% Skip hidden entries like .godot internals.
		if not entry.begins_with(".") or entry == ".gitkeep" or entry == ".Instructions.txt" or entry == ".Disclaimer.txt":
			var src = from_path + "/" + entry
			var dst = to_path  + "/" + entry

			if dir.current_is_dir():
				_move_all_files(src, dst)
			else:
				var dest_dir_access = DirAccess.open(to_path)
				if dest_dir_access == null:
					push_error("Could not open destination directory: " + to_path)
				else:
					var err = dest_dir_access.rename(
						ProjectSettings.globalize_path(src),
						ProjectSettings.globalize_path(dst)
					)
					if err != OK:
						push_error("Failed to move: " + src + " → " + dst + " (error " + str(err) + ")")
					else:
						print("Moved: ", src, " → ", dst)

		entry = dir.get_next()

	dir.list_dir_end()


#* Update 'extends: ...' in the User_Data scripts, from First_Install to Candy_DE:
func _apply_string_patches():
	for file_path in STRING_PATCHES:
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			push_error("Could not open file for patching: " + file_path)
			continue
		
		var text = file.get_as_text()
		file.close()
		
		var patched = text
		for substitution in STRING_PATCHES[file_path]:
			patched = patched.replace(substitution[0], substitution[1])

		if patched != text:
			file = FileAccess.open(file_path, FileAccess.WRITE)
			file.store_string(patched)
			file.close()
			print("Patched: ", file_path)
		else:
			#% If nothing changed, it likely means the find string didn't match.
			#% This could mean the file was already patched, or the path is wrong.
			print("No changes made to: ", file_path)

#* Add autoloads:
func _add_autoloads():
	for entry in AUTOLOADS:
		#% ProjectSettings stores autoloads under "autoload/<name>".
		#% The value must be prefixed with "*" for enabled autoloads.
		var key = "autoload/" + entry["name"]
		if not ProjectSettings.has_setting(key):
			ProjectSettings.set_setting(key, "*" + entry["path"])
			print("Added autoload: ", entry["name"], " → ", entry["path"])
		else:
			print("Autoload already exists, skipping: ", entry["name"])

	ProjectSettings.save()


#* Add input actions:
func _add_input_actions():
	for action in INPUT_ACTIONS:
		var key = "input/" + action
		if not ProjectSettings.has_setting(key):
			ProjectSettings.set_setting(key, { "deadzone": 0.5, "events": [] })
			InputMap.add_action(action)
			print("Added input action: ", action)
		else:
			print("Input action already exists, skipping: ", action)

	ProjectSettings.save()


#* Delete First_Install when finished:
func _delete_dir_recursive(path: String):
	var dir = DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry = dir.get_next()

	while entry != "":
		if entry != "." and entry != "..":
			var full_path = path + "/" + entry
			if dir.current_is_dir():
				_delete_dir_recursive(full_path)
			else:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(full_path))
		entry = dir.get_next()

	dir.list_dir_end()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))