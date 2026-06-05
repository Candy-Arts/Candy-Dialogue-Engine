@tool
extends EditorScript


#° ─── Direct folder renames ────────────────────────────────────────────────────
#? These are renamed exactly as specified. Deeper paths must come first so that
#? we don't rename a parent before we've processed its children.
const FOLDER_RENAMES = [
	#% Scripts:
	["res://Candy_DE/Scripts/UI Elements",       "res://Candy_DE/Scripts/UI_Elements"],
	["res://Candy_DE/Scripts/Actor Nodes",       "res://Candy_DE/Scripts/Actor_Nodes"],
	["res://Candy_DE/Scripts/Media Players",     "res://Candy_DE/Scripts/Media_Players"],
	#% Scenes:
	["res://Candy_DE/Scenes/Background Scenes",  "res://Candy_DE/Scenes/Background_Scenes"],
	["res://Candy_DE/Scenes/Chat Boxes",         "res://Candy_DE/Scenes/Chat_Boxes"],
	["res://Candy_DE/Scenes/Choice Buttons",     "res://Candy_DE/Scenes/Choice_Buttons"],
	["res://Candy_DE/Scenes/Choice Categories",  "res://Candy_DE/Scenes/Choice_Categories"],
	["res://Candy_DE/Scenes/Choice Menus",       "res://Candy_DE/Scenes/Choice_Menus"],
	["res://Candy_DE/Scenes/Dialogue Boxes",     "res://Candy_DE/Scenes/Dialogue_Boxes"],
	["res://Candy_DE/Scenes/History Menus",      "res://Candy_DE/Scenes/History_Menus"],
	["res://Candy_DE/Scenes/Image Players",      "res://Candy_DE/Scenes/Image_Players"],
	["res://Candy_DE/Scenes/Input Menus",        "res://Candy_DE/Scenes/Input_Menus"],
	["res://Candy_DE/Scenes/Portrait Areas",     "res://Candy_DE/Scenes/Portrait_Areas"],
	["res://Candy_DE/Scenes/Speech Bubbles 2D",  "res://Candy_DE/Scenes/Speech_Bubbles_2D"],
	["res://Candy_DE/Scenes/Speech Bubbles 3D",  "res://Candy_DE/Scenes/Speech_Bubbles_3D"],
	["res://Candy_DE/Scenes/Subtitles",          "res://Candy_DE/Scenes/Subtitles"],
	["res://Candy_DE/Scenes/VN Scenes",          "res://Candy_DE/Scenes/VN_Scenes"],
]

#° ─── Folders whose direct subfolders need specific child renames ──────────────
#? For each path listed here, we scan its immediate subfolders and rename any
#? children matching the names in MEDIA_SUBFOLDER_RENAMES.
const MEDIA_PARENT_FOLDERS = [
	"res://Candy_DE/Media/General/Backgrounds",
	"res://Candy_DE/Media/General/Images",
	"res://Candy_DE/Media/Characters/Busts",
	"res://Candy_DE/Media/Characters/Portraits",
	"res://Candy_DE/Media/Characters/Sprites",
]

#° The specific folder names to look for and rename inside each of the above.
const MEDIA_SUBFOLDER_RENAMES = {
	"Sprite Frames":      "Sprite_Frames",
	"Animation Libraries":"Animation_Libraries",
	"Button Textures":    "Button_Textures",
}

#° ─── File moves ───────────────────────────────────────────────────────────────
#? The destination folder will be created automatically if it doesn't exist.
#? .uid files are moved alongside their .gd counterparts.
const FILE_MOVES = [
	["res://Candy_DE/Scripts/Candy_Properties.gd",    "res://Candy_DE/Scripts/User_Data/Candy_Properties.gd"],
	["res://Candy_DE/Scripts/Candy_Properties.gd.uid","res://Candy_DE/Scripts/User_Data/Candy_Properties.gd.uid"],
	["res://Candy_DE/Scripts/Candy_Database.gd",      "res://Candy_DE/Scripts/User_Data/Candy_Database.gd"],
	["res://Candy_DE/Scripts/Candy_Database.gd.uid",  "res://Candy_DE/Scripts/User_Data/Candy_Database.gd.uid"],
	["res://Candy_DE/Scripts/Candy_Localizations.gd", "res://Candy_DE/Scripts/User_Data/Candy_Localizations.gd"],
	["res://Candy_DE/Scripts/Candy_Localizations.gd.uid","res://Candy_DE/Scripts/User_Data/Candy_Localizations.gd.uid"],
	["res://Candy_DE/Scripts/Candy_Functions.gd",     "res://Candy_DE/Scripts/User_Data/Candy_Functions.gd"],
	["res://Candy_DE/Scripts/Candy_Functions.gd.uid", "res://Candy_DE/Scripts/User_Data/Candy_Functions.gd.uid"],
	#% Scene rename:
	["res://Candy_DE/Scenes/Testing Scene.tscn",      "res://Candy_DE/Scenes/Testing_Scene.tscn"],
	["res://Candy_DE/Scenes/Testing Scene.tscn.uid",  "res://Candy_DE/Scenes/Testing_Scene.tscn.uid"],
]

#° ─── String patches ───────────────────────────────────────────────────────────
#? Each entry is a file path (using the *new* location after the move),
#? mapped to a list of [find, replace] pairs to apply in that file.
const STRING_PATCHES = {
	"res://Candy_DE/Scripts/User_Data/Candy_Properties.gd": [
		["extends \"res://Candy_DE/Scripts/Candy_Localizations.gd\"",
		"extends \"res://Candy_DE/Scripts/User_Data/Candy_Localizations.gd\""],
		["\"res://Candy_DE/Scenes/VN Scenes\"",          "\"res://Candy_DE/Scenes/VN_Scenes\""],
		["\"res://Candy_DE/Scenes/Background Scenes\"",  "\"res://Candy_DE/Scenes/Background_Scenes\""],
		["\"res://Candy_DE/Scenes/Input Menus\"",        "\"res://Candy_DE/Scenes/Input_Menus\""],
		["\"res://Candy_DE/Scenes/Choice Menus\"",       "\"res://Candy_DE/Scenes/Choice_Menus\""],
		["\"res://Candy_DE/Scenes/Choice Categories\"",  "\"res://Candy_DE/Scenes/Choice_Categories\""],
		["\"res://Candy_DE/Scenes/Choice Buttons\"",     "\"res://Candy_DE/Scenes/Choice_Buttons\""],
	],
	"res://Candy_DE/Scripts/User_Data/Candy_Database.gd": [
		["extends \"res://Candy_DE/Scripts/Candy_Properties.gd\"",
		"extends \"res://Candy_DE/Scripts/User_Data/Candy_Properties.gd\""],
		["\"Bubble Exempt\": false,",		"\"BubblesOverride\": 0,"],
		["\"Bubble Exempt\": true,",		"\"BubblesOverride\": -1,"],
		["\"Portrait\":",					"\"PortraitOverride\":"],
		["\"Short Name\":",					"\"ShortName\":"],
		["\"Display Name\":",				"\"DisplayName\":"],
		["\"Speaker BBCode\":",				"\"SpeakerBBCode\":"],
		["\"VN Join Effect\":",				"\"VNJoinEffect\":"],
		["\"VN Move From Effect\":",		"\"VNMoveFromEffect\":"],
		["\"VN Move To Effect\":",			"\"VNMoveToEffect\":"],
		["\"VN Leave Effect\":",			"\"VNLeaveEffect\":"],
		["\"Box Text Color\":",				"\"BoxTextColor\":"],
		["\"Bubble Text Color\":",			"\"BubbleTextColor\":"],
		["\"Subtitle Text Color\":",		"\"SubtitleTextColor\":"],
		["\"Chat Text Color\":",			"\"ChatTextColor\":"],
		["\"Chat Speaker Color\":",			"\"ChatSpeakerColor\":"],
		["\"Bark Text Color\":",			"\"BarkTextColor\":"],
		["\"Box Speaker Color\":",			"\"BoxSpeakerColor\":"],
		["\"Subtitle Speaker Color\":",		"\"SubtitleSpeakerColor\":"],
	],
	"res://Candy_DE/Scripts/User_Data/Candy_Functions.gd": [
		["extends \"res://Candy_DE/Scripts/Candy_Database.gd\"",
		"extends \"res://Candy_DE/Scripts/User_Data/Candy_Database.gd\""],
	],
	"res://project.godot": [
		["res://Candy_DE/Scripts/Candy_Functions.gd",
		"res://Candy_DE/Scripts/User_Data/Candy_Functions.gd"],
	],
}


#* Run the patcher:
func _run():
	_rename_folders()
	_rename_media_subfolders()
	_move_files()
	_apply_string_patches()
	
	#% Trigger a full rescan so Godot reconciles its internal state with everything we've just changed on disk.
	get_editor_interface().get_resource_filesystem().scan()
	print("Migration complete!")


func _rename_folders():
	#% FOLDER_RENAMES is already ordered deepest-first, so we just iterate.
	for pair in FOLDER_RENAMES:
		var dir = DirAccess.open(pair[0].get_base_dir())
		if dir == null:
			push_error("Could not open parent directory of: " + pair[0])
			continue
		
		#% DirAccess.rename() takes bare names, not full paths, when called on a DirAccess opened at the parent directory.
		var old_name = pair[0].get_file()	#/ "get_file()" returns the last path component, whether it's a file or a folder.
		var new_name = pair[1].get_file()
		
		var err = dir.rename(old_name, new_name)
		if err != OK:
			push_error("Failed to rename: " + pair[0] + " (error " + str(err) + ")")
		else:
			print("Renamed: ", old_name, " → ", new_name)


func _rename_media_subfolders():
	for parent_path in MEDIA_PARENT_FOLDERS:
		var parent_dir = DirAccess.open(parent_path)
		if parent_dir == null:
			push_error("Could not open media folder: " + parent_path)
			continue
		
		#% Iterate the direct subfolders of Busts/Portraits/etc.
		#% These can be named anything — a character name, an ID, whatever.
		parent_dir.list_dir_begin()
		var character_folder = parent_dir.get_next()
		
		while character_folder != "":
			if parent_dir.current_is_dir() and character_folder != "." and character_folder != "..":
				var character_path = parent_path + "/" + character_folder
				var char_dir = DirAccess.open(character_path)
				
				if char_dir != null:
					#% Now we're inside e.g. Busts/Alice/ — look for the target folders here.
					char_dir.list_dir_begin()
					var entry = char_dir.get_next()
					
					while entry != "":
						if char_dir.current_is_dir() and MEDIA_SUBFOLDER_RENAMES.has(entry):
							var new_name = MEDIA_SUBFOLDER_RENAMES[entry]
							var err = char_dir.rename(entry, new_name)
							if err != OK:
								push_error("Failed to rename: " + character_path + "/" + entry)
							else:
								print("Renamed: ", character_path + "/" + entry, " → ", new_name)
						entry = char_dir.get_next()
					
					char_dir.list_dir_end()
			
			character_folder = parent_dir.get_next()
		
		parent_dir.list_dir_end()


func _move_files():
	for pair in FILE_MOVES:
		var dest_dir = pair[1].get_base_dir()
		
		#@ Create the destination folder if it doesn't exist yet:
		#% This is what creates User_Data/ before we try to move files into it.
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dest_dir)):
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dest_dir))
		
		var dir = DirAccess.open(pair[0].get_base_dir())
		if dir == null:
			push_error("Could not open source directory for: " + pair[0])
			continue
		
		#@ Check the .uid file actually exists before trying to move it — older Godot versions may not have generated them:
		if not FileAccess.file_exists(pair[0]):
			#% Skip silently for .uid files, warn for anything else:
			if not pair[0].ends_with(".uid"):
				push_error("Source file not found: " + pair[0])
			continue
		
		var err = dir.rename(pair[0].get_file(), ProjectSettings.globalize_path(pair[1]))
		if err != OK:
			push_error("Failed to move: " + pair[0] + " (error " + str(err) + ")")
		else:
			print("Moved: ", pair[0].get_file(), " → ", pair[1])


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

		if file_path == "res://Candy_DE/Scripts/User_Data/Candy_Properties.gd":
			if not patched.contains("var file_var_symbol"):
				patched = _insert_after_separator_symbol_line(patched)

		if patched != text:
			file = FileAccess.open(file_path, FileAccess.WRITE)
			file.store_string(patched)
			file.close()
			print("Patched: ", file_path)
		else:
			#% If nothing changed, it likely means the find string didn't match.
			#% This could mean the file was already patched, or the path is wrong.
			print("No changes made to: ", file_path)


func _insert_after_separator_symbol_line(text: String) -> String:
	var marker = "var separator_symbol ="
	var idx = text.find(marker)
	if idx == -1:
		push_error("Could not find 'var separator_symbol =' in Candy_Properties.gd")
		return text
	
	var line_end = text.find("\n", idx)
	if line_end == -1:
		line_end = text.length()
	
	var insert = "\nvar file_var_symbol = \"¬\""
	return text.substr(0, line_end) + insert + text.substr(line_end)