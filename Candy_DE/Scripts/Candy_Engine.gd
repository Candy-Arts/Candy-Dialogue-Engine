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


extends Node


#°#########################################################################################
#^
#^										DIALOGUES
#^
#°#########################################################################################
#region

#& Loaded Dialogues
#^ Running Dialogues:
#? This contains the dialogue that the engine runs.
#? A dialogue must be loaded manually (copy/paste) or through code at runtime.
#? The load_scripted_dialogue() function can be called to load a dialogue from an external .txt file.
#? Otherwise, you must write code to determine when and which dialogues to load.
var running_dialogue = {}

#endregion



#°#########################################################################################
#^
#^										 SETTINGS
#^
#°#########################################################################################
#region

#? Customize the variables and functions below to fit your project and needs.
#? Please read carefully, make sure you configure everything properly
#? Refer to the documentation for details.
#? TIP: The variables in this script can be changed during gameplay through your game code or through dialogues (use the "§Set" command)
#? TIP: You may also let the player change some of these settings through an option menu.

@export_group("Identity")
# An arbitrary value, that can be used to indicate the purpose of an engine instance when needed.[br]
# Used only in change_game_state() (for now), can also be used in your own custom code.[br][br]
# "UI" is assigned to Candy UI by default. For future-proofing purposes, we recommend not assigning "UI" to any other instances.[br]
# "Bark" is assigned to NPC bark engine instances. You can assign that value to custom instances also used for NPC barks.
@export var engine_mode: String = ""

@export_group("Dialogue Display")
#& DIALOGUE DISPLAY
#^ Dialogue mode:
#? How the dialogue is displayed on screen.
#% "Box": Classic RPG box, one line displayed at a time.
#% "Bubbles": Comic book style speech bubbles above characters.
#% "Subtitles": Wide and thin area of text at the bottom of the screen.
#% "Chat": Chatbox style dialogue display, with vertically stacked lines.
#% "Voice": Voice playback only, no text, speaker labels, or portraits.
#+ Add custom modes in display_line() in Candy_Engine.gd
## How the dialogue is displayed on screen.[br]
## "Box": Classic RPG box, one line displayed at a time.[br]
## "Bubbles": Comic book style speech bubbles above characters.[br]
## "Subtitles": Wide and thin area of text at the bottom of the screen.[br]
## "Chat": Chatbox style dialogue display, with vertically stacked lines.[br]
## "Voice": Voice playback only, no text, speaker labels, or portraits.
enum DialogueModes {Box, Subtitles, Chat, Bubbles, VN_Bubbles, Barks, Voice}
## Dialogue Mode to use.[br]
## Note: 'Bubbles' defaults to 'VN_Bubbles' automatically when VN Mode is enabled.
@export var dialogue_mode: DialogueModes = DialogueModes.Box


#& ACTOR DISPLAY
#^ Portrait display:
#? Whether to display speaker portraits in "Box" mode.
#? Typically disabled when character meshes, sprites or VN busts convey expressions.
#% "Off" = Don't display any portraits ever.
#% "All" = Display portraits for all characters.
#% "Player" = Display only a portrait for the player (identified with player_ref array in Candy_Dialogues.gd).
#% "NPC" = Never display a portrait for the player.
#% "VN" = Don't display portraits if the speaker has a VN bust node assigned.
## Whether to display speaker portraits in "Box" mode.[br]
## Typically disabled when character meshes, sprites or VN busts convey expressions.[br]
## "Off" = Don't display any portraits ever.[br]
## "All" = Display portraits for all characters.[br]
## "Player" = Display only a portrait for the player (identified with player_ref array in Candy_Dialogues.gd).[br]
## "NPC" = Never display a portrait for the player.[br]
## "VN" = Don't display portraits if the speaker has a VN bust node assigned.
enum PortraitModes {Off, All, Player, NPC, VN}
@export var portrait_mode: PortraitModes = PortraitModes.All

#& VOICED DIALOGUES
@export_group("Voice")
#^ Allow voice:
#? Enable or disable voice playback for spoken lines:
## Enable voice playback for spoken lines.
@export var enable_voice: bool = true

#^ Default voice file extension:
#? Used when playing voiced dialogues
## Default extension for voice files, if no extension specified.
@export var default_voice_extension: String = ".ogg"


#& TEXT-TO-SPEECH (TTS)
#^ TTS mode:
#? Enable TTS / Which TTS mode to use.
#% "Off": no TTS.
#% "Simple": TTS reads the spoken line.
#% "Advanced": TTS reads a special variant, with formatting to aid pronunciation and tone.
#+ The name of the advanced variant must the same as the displayed variant, with the added "_TTS" suffix.
#+ E.g. "English_TTS"
## Use Text-To_Speech.[br]
## "Off": no TTS.[br]
## "Simple": TTS reads the spoken line.[br]
## "Advanced": TTS reads a special variant, with formatting to aid pronunciation and tone.
enum TtsModes {Off, Simple, Advanced}
@export var text_to_speech: TtsModes = TtsModes.Off

#^ TTS fallback:
#? The TTS mode to use if no advanced variant exists.
#% Can be set to "Off" or "Simple", or to your own custom TTS mode if you've made any.
## TTS mode to use if no "Advanced" line variant exists.[br]
## Can be set to "Off" or "Simple", or to your own custom TTS mode if you made any.
@export var tts_advanced_fallback: TtsModes = TtsModes.Simple

## "Box" dialogue mode.
@export_group("Box Mode")

## "Subtitles" dialogue mode.
@export_group("Subtitles Mode")

## "Chat" dialogue mode.
@export_group("Chat Mode")


#& TEXT COLOR
#^ Text color:
#? Default colors to use for spoken text and speaker names.
#? These settings are overruled by those of the UI elements, the actor dictionary and BBCode tags inside spoken text.
## Default colors to use for spoken text and speaker names.
@export_group("Box Mode")
@export var enable_box_font_color: bool = false
@export var box_font_color: Color 					#/ Spoken text in the dialogue box
@export var enable_box_speaker_color: bool = false
@export var box_speaker_color:Color					#/ Speaker name in the dialogue box

@export_group("Subtitles Mode")
@export var enable_subtitle_font_color: bool = false
@export var subtitle_font_color:Color				#/ Spoken text in subtitle mode
@export var enable_subtitle_speaker_color: bool = false
@export var subtitle_speaker_color:Color			#/ Speaker name in subtitle mode

@export_group("Chat Mode")
@export var enable_chat_font_color: bool = false
@export var chat_font_color:Color					#/ Speaker name in the chat box
@export var enable_chat_speaker_color: bool = false
@export var chat_speaker_color:Color				#/ Speaker name in the chat box

@export_group("Speech Bubbles")
@export var enable_bubble_font_color: bool = false
@export var bubble_font_color:Color					#/ Spoken text in bubbles

@export_group("Barks")
@export var enable_bark_font_color: bool = false
@export var bark_font_color:Color					#/ Spoken text in barks


#^ Speaker name in spoken text:
#? Used for showing speaker names when no dedicated speaker text node exists.
#? E.g. 'Alice: Hi there!'
#+ Works with BBCode tags if the text node supports BBCode.
## Options for displaying speaker name inside spoken text strings.
@export_group("Subtitles Mode")
## Enable speaker in text for "Subtitles" dialogue mode.
@export var subtitles_show_speaker: bool = true
## Character string to add before speaker name.
@export var subtitles_speaker_prefix: String = "("			#/ Optional string before the speaker name
## Character string to add after speaker name.
@export var subtitles_speaker_suffix: String = ")"			#/ Optional string after the speaker name

@export_group("Chat Mode")
## Enable speaker in text for "Chat" dialogue mode.
@export var chat_show_speaker: bool = true
## Character string to add before speaker name.
@export var chat_speaker_prefix: String = ""				#/ Optional string before the speaker name
## Character string to add after speaker name.
@export var chat_speaker_suffix: String = ":"				#/ Optional string after the speaker name


#^ End of line character/string:
#? Display a special character or string of character at the end of spoken lines.
#? Sometimes used to hint that player input is awaited (e.g. blinking arrow).
#+ Works with BBCode tags if the text node supports BBCode.
#% Set an empty string ("") to deactivate this feature.
@export_group("Box Mode")
## Custom string to display at the end of a line in "Box" dialogue mode. Supports BBCode.
@export var box_end_of_line_string: String = "[pulse freq=1.5 color=black ease=-5.0] ▼[/pulse]"		#/ Dialogue box

@export_group("Speech Bubbles")
## Custom string to display at the end of a line in "Bubbles" dialogue mode. Supports BBCode.
@export var bubbles_end_of_line_string: String = ""													#/ Speech Bubbles

@export_group("Subtitles Mode")
## Custom string to display at the end of a line in "Subtitles" dialogue mode. Supports BBCode.
@export var subtitles_end_of_line_string: String = ""												#/ Subtitles

@export_group("Chat Mode")
## Custom string to display at the end of a line in "Chat" dialogue mode. Supports BBCode.
@export var chat_end_of_line_string: String = ""													#/ Chat Box

@export_group("Barks")
## Custom string to display at the end of a line in "Bark" dialogue mode. Supports BBCode.
@export var barks_end_of_line_string: String = ""													#/ Barks

#& CHAT MODE:
#^ Persistent chat:
#? Keep chatbox visible even if the dialogue mode changes:
## Keep chatbox visible even if the dialogue mode changes between spoken lines.
@export_group("Chat Mode")
@export var persistent_chat: bool = true

#^ Clear chatbox:
#? Clear the text in the chatbox when dialogue ends.
## Clear chatbox contents when dialogue ends.
@export var chat_clear_on_end: bool = true

#^ Hide chatbox:
#? Hide the chatbox when dialogue ends.
## Hide chatbox when dialogue ends.
@export var chat_hide_on_end: bool = true


#& BUBBLES MODE:
#^ Bubble alt mode:
#? In Bubbles mode, which mode to use when text can't/shouldn't be displayed in speech bubbles:
@export_group("Speech Bubbles")
## Dialogue mode to default to if speaker has no speech bubble or speaker not present on screen.
@export var bubble_exempt_mode: DialogueModes = DialogueModes.Box


@export_group("Writing")
#^ Writing speed:
#? The speed at which spoken text is written on screen (typewriter effect).
#+ Value represents characters written per second
#% 0 = instant display
## Typewriter effect speed.
@export var writing_speed: int = 30


#^ Manual speed:
#? Change the spoken text writing speed with the Dialogue_Advance input.
#? Note that if sync_write_speed_voice = true, this will desynchronize voice and writing;
#? this is not a major problem, writing or voice will just finish before the other.
#+ Value represents characters written per second
#% 0 = not possible, defaults to 30
#% 1+ = write faster
#% -1 = instant display
#% -2 = can't skip
## Typewriter speed when input_speed_dialogue is pressed.
@export var continue_skip_speed: int = 60
## Typewriter speed when input_slow_dialogue is pressed.
@export var continue_slow_speed: int = 15

#^ Auto-advance:
#? When spoken text is fully displayed, automatically continue to the next line after a set amount of time.
#? Can be more comfortable than having to click after each line.
#% Wait time in seconds. Set to -1 to disable.
## Time (in seconds) to wait before automatically advancing to the next line.[br]
## -1 to disable (manual advance only).
@export var auto_advance: float = -1.0			#/ Wait time in seconds before advancing to next line

#^ Synchronize writing speed to voice:
#? Adjust the writing speed to be timed with voice playback (for voiced lines).
#+ Only works if writing_speed > 0.
#% true = synchronize writing speed to voice
#% false = don't synchronize
## Synchronize typewriter speed to match voice playback duration.[br]
## Synchronization will break if player speeds, slows or skips the typewriter effect.
@export var sync_write_speed_voice: bool = false

#^ Wait on voice playback:
#? Prevents the player from skipping voice playback, even if the line has finished writing.
#% true = prevent skipping voice
#% false = allow skipping voice
## Prevent manual advance until voice playback has finished.
@export var await_voice_playback: bool = false

@export_group("Choice Menus")
#^ Hide choice lists by default:
## If false, nested choice menus never hide older menus automatically.
@export var hide_choice_lists = true


#& VN MODE
#^ VN Mode enable:
#? Visual novel mode. Enables VN commands for displaying actors busts.
#? Does not affect portrait display if true. See 'portrait_mode' to configure portrait display.
@export_group("Visual Novel Mode")
## Enable VN mode.
@export var vn_mode: bool = false

#^ Persistent busts:
#? Whether VN busts should be cleared or remain on screen when dialogue ends.
#? Generally safe to enable for standard Visual Novels, but may require careful implementation for
#? more complex games, such as hybrids of VN and other genres.
#% false: busts are cleared when dialogue ends.
#% true: busts persist on screen when dialogue end.
#+ To clear busts outside of dialogue, call the candy_de.clear_busts_ood() function in Candy_Functions.gd
## Keep VN busts on screen when dialogue ends.
@export var persistent_busts_on_end: bool = false

#^ Join/Move/Leave effects:
#? Visual effects to automatically play on bust nodes when an actor joins, moves or leaves.
#? Can be overridden by the VN scene settings and actors dictionary settings.
#% Write the name of the animations to play.
#+ The animation must exist in the bust node's child animation player.
## Default JML effect when an actor joins (§VN_Bust command).
@export var vn_join_effect = ["", ""]
## Default JML effect when an actor moves from a bust node (§VN_Move command).
@export var vn_move_from_effect = ["", ""]
## Default JML effect when an actor moves to a bust node (§VN_Move command).
@export var vn_move_to_effect = ["", ""]
## Default JML effect when an actor leaves (§VN_Remove command).
@export var vn_leave_effect = ["", ""]


#& BACKGROUNDS
#^ Persistent backgrounds:
#? Whether background layers should be cleared or remain on screen when dialogue ends.
#% false: layers are cleared when dialogue ends.
#% true: layers persist on screen when dialogue end.
#+ To clear BG layers outside of dialogue, call the candy_de.clear_bg_layers_ood() function in Candy_Functions.gd
@export_group("Backgrounds")
## Keep Backgrounds on screen when dialogue ends.
@export var persistent_bg_on_end: bool = true


#& LEXICON
#? The Lexicon adds a special format to keywords featured in the lexicon dictionary.
#? See Candy_Database.gd

#^ Lexicon:
#? Enable Lexicon formatting for specific dialogue modes:
@export_group("Lexicon")
## Enable Lexicon in "Box" dialogue mode.
@export var lexicon_box_mode: bool = true
## Enable Lexicon in "Bubbls" dialogue mode.
@export var lexicon_bubbles_mode: bool = true
## Enable Lexicon in "Subtitles" dialogue mode.
@export var lexicon_subtitles_mode: bool = true
## Enable Lexicon in "Chat" dialogue mode.
@export var lexicon_chat_mode: bool = true
## Enable Lexicon in "Bark" dialogue mode.
@export var lexicon_bark_mode: bool = true


#& HISTORY LOG
#^ History log:
#? Enable or disable saving of dialogue history.
#? Recommended that you keep enabled, even if you don't intend to display past dialogue history in game.
#+ Can be helpful for debugging or to provide extra context for LLM mode.
@export_group("History")
## Log dialogue history.[br]
## Enable recommended, even if you don't expect to use the log.
@export var write_dialogue_history: bool = true





#& LLM (AI-GENERATED SPEECH)
#^ LLM query:
#? Query a connected LLM each spoken line?
#+ Requires implementing a connection from your game to an LLM API,
#+ and writing the llm_query() function in Candy_Functions.gd
@export_group("LLM Speech")
## Enable LLM mode.
@export var llm_mode: bool = false


#& MOUSE MODE
#^ Mouse mode variables:
#? Change mouse mode at various points during dialogue.
#% Hidden, Visible, Captured, Confined, Confined_Hidden
@export_group("Mouse Mode")
enum MouseModes {None = -1, Visible, Hidden, Captured, Confined, Confined_Hidden}
## Set Mouse Mode when dialogue starts.[br]
## Set to "NONE" to disable.
@export var mouse_mode_start: MouseModes = MouseModes.None		#/ Mouse Mode when dialogue starts
## Set Mouse Mode when dialogue ends.[br]
## Set to "NONE" to disable.
@export var mouse_mode_end: MouseModes = MouseModes.None			#/ Mouse Mode when dialogue exits


#& VARIANTS
#^ Automatic Variant Selection:
#? Automatically switch to special variants based on gender,
#? or randomly select among multiple variations of a same variant.
@export_group("Variants")
## Use variants based on player's gender.
@export var player_gender_variants: bool = false	#/ Select variants based on player_gender
## Player's gender, as used by gendered variants. Can be modified at runtime as appropriate.
@export var player_gender: String = ""				#/ Gender of the player character. Update dynamically if player character/gender changes during the game
## Use variants based on speaker's gender.
@export var speaker_gender_variants: bool = false	#/ Select variants based on speaker gender as specified in actors dictionary
## Use random variants.
@export var random_variants: bool = true			#/ Select random variants if they exist


#& DIALOGUE SUSPEND
@export_group("Suspend Dialogue")
#^ Suspend dialogue:
#? Effectively pauses dialogue if true.
## Suspend dialogue by default if 'true'.[br]
## Dialogue suspension requires that you write code to toggle this value.
@export var dialogue_suspended = false

#^ Suspend dialogue elements:
#? Set to false for things you don't want to be paused when dialogue_suspended = true.
## Suspend portrait animations.
@export var suspend_portraits: bool = true			#/ Suspend portrait animations
## Suspend voice playback for spoken lines.
@export var suspend_voice: bool = true				#/ Suspend voice playback for spoken lines

## Suspend background animations and effects.
@export var suspend_backgrounds: bool = true		#/ Suspend background animations and effects
## Suspend background animations.
@export var suspend_bg_animations: bool = true		#/ Suspend background animations
## Suspend background effects.
@export var suspend_bg_effects: bool = true			#/ Suspend background effects

## Suspend VN bust animations and effects.
@export var suspend_vn_busts: bool = true			#/ Suspend VN bust animations and effects
## Suspend VN bust animations
@export var suspend_bust_animations: bool = true	#/ Suspend VN bust animations
## Suspend VN bust effects
@export var suspend_bust_effects: bool = true		#/ Suspend VN bust effects

## Suspend all media (§Audio, §Video, §Image, §Effect commands).
@export var suspend_media: bool = true				#/ Suspend all media (§Audio, §Video, §Image, §Effect commands)
## Suspend audio media (§Audio command).
@export var suspend_audio: bool = true				#/ Suspend audio media (§Audio command)
## Suspend video media (§Video command).
@export var suspend_video: bool = true				#/ Suspend video media (§Video command)
## Suspend image media (§Image command).
@export var suspend_images: bool = true				#/ Suspend image media (§Image command)
## Suspend visual effects (§Effect command).
@export var suspend_animations: bool = true			#/ Suspend visual effects (§Effect command)

#? Media players exempt from being suspended.
#? Write their key from media_players_locations in the array.
## Media players exempt from being suspended.[br]
## Add their key from media_players_locations in the array -- e.g. "Music"
@export var media_suspend_immune: Array[String] = []	#/ e.g. ["Ambient", "Music"]


#& INPUT
@export_group("Input")
#? Allow input keys to affect this engine instance:
## Enable or disable input.
## Determines if this dialogue engine instance reacts to the inputs above.[br]
## Does not affect dialogue suspension inputs, as these are handled by your own code, unless your code is designed to read this variable.
@export var input_enabled: bool = true

#? Input required to make dialogue advance manually:
## Name of the input for manually advancing to the next line
@export var input_advance_dialogue = "Dialogue_Advance"		#/ Advance to next line
## Name of the input for speeding up the typewriter.
@export var input_speed_dialogue = "Dialogue_Speed"			#/ Speed up writing
## Name of the input for slowing down the typewriter.
@export var input_slow_dialogue = "Dialogue_Slow"			#/ Slow down writing
## Name of the input for skipping the typewriter (instant text display).
@export var input_skip_dialogue = "Dialogue_Skip"			#/ Skip writing



#endregion



#°#########################################################################################
#^
#^										  PATHS
#^
#°#########################################################################################
#region

@export_group("Paths")
#^ UI node paths:
#TODO: Edit paths as needed.
## Paths to dialogue UI elements.[br]
## Edit paths or remove keys to match your dialogue UI scene;[br]
## Add keys/UI Elements as needed for your custom commands or custom dialogue modes.[br]
## NOTE: Media players are added to media_and effect players_locations.
@export var ui_elements_paths = {
	"backgrounds_path" = "Backgrounds",
	"busts_path" = "Busts",
	"dialogue_box_path" = "DialogueBox",
	"subtitles_path" = "Subtitles",
	"chat_path" = "ChatBox",
	"portrait_path" = "Portrait",
	"history_display_path" = "History",
	"choices_path" = "Choices",
	"input_node_path" = "Input",
	"barks_path" = "BarkBubble"
}

#^ Media Player paths:
#TODO: Edit paths and add media player path keys as needed.
## Paths to media and effect players used by various commands.[br]
## Edit paths or remove keys to match your dialogue UI scene, or add keys for your custom media/effect players.[br]
## WARNING: Do not rename the "Voice" key (changing its path is OK).
@export var media_players_locations = {
	"Voice": "VoicePlayer",									#/ For Spoken Line voice files
															#/ Don't change "Voice" key name: referenced in various functions for voiced dialogue
	"PEffect": "Portrait/PortraitEffectPlayer",				#/ AnimationPlayer for portrait effects
	"Effect": "MediaPlayers/EffectPlayer",					#/ AnimationPlayer for UI effects
	"Image": "MediaPlayers/ImagePlayer",
	"Splash": "MediaPlayers/SplashPlayer",
	"Video": "MediaPlayers/VideoPlayer",
	"Sound": "MediaPlayers/SoundPlayer",
	"Ambient": "MediaPlayers/AmbientPlayer",
	"Music": "MediaPlayers/MusicPlayer",
	"Speech": "MediaPlayers/SpeechPlayer",					#/ For speech outside of Spoken Lines, triggered by §Audio command
}


#^ Actor paths:
#? If actor nodes change paths during the course of your game, update dynamicaly.
#? E.g. make your game update these paths during combat, exploration, cutscenes, etc.
## Paths to NPC nodes for "Bubbles" dialogue mode.
@export var bubbles_npc_path = "/root/Game/Actors"		#/ Path to NPC actor nodes, for speech bubbles.
## Paths to player nodes for "Bubbles" dialogue mode.
@export var bubbles_player_path = "/root/Game/Actors"	#/ Path to Player actor node, for speech bubbles.


#^ Cutscene Commands paths:
#TODO: Edit paths to fit your game structure, add path keys as needed.
## Paths to nodes used by Cutscene (§CS_) commands:
@export var cs_locations = {
		"Player": "/root/Game/Actors",
		"Actors": "/root/Game/Actors",
		"Vehicles": "",
		"Objects": "",
		"Cameras": "/root/Game/Cameras",
		"Markers": "/root/Game/Pins",
		"WP": "/root/Game/Waypoints",
		"Lights": "/root/Game/Lights",
}



#endregion



#°#########################################################################################
#^
#^										VARIABLES
#^
#°#########################################################################################
#region

#! DO NOT MODIFY VARIABLES IN THIS SECTION

#^ Dialogue running:
var dialogue_running = false

#^ Dialogue progression tracking variables:
var conversation_tracker = ""
var block_tracker = ""
var line_tracker = ""

#^ The symbol that identifies commands for Candy DE:
var command_symbol = "§"

#^ Symbol for empty values:
var empty_symbol = "_"

#^ Last dialogue mode used:
var previous_mode = ""

#^ Last speaker's reference:
var previous_speaker = ""

#^ List of actors and positions for bust display:
var bust_positions = {}

#^ List of bust animations with wait = 0 or 1:
var active_bust_animations = []

#^ List of bg animations with wait = 0 or 1:
var active_bg_animations = []

#^ Dialogue advance:
#? Wait for player input before continuing to the next line:
var waiting_for_input

#^ Media player tracking:
#? Media players paused with the Dialogue Suspend feature.
var suspended_media_players = []
var suspended_bg_nodes = []
var suspended_bg_animplayers = []
var suspended_bust_nodes = []
var suspended_bust_animplayers = []
var suspended_portrait_nodes = []
var suspended_portrait_animplayers = []

#? Media players currently playing media:
var active_media_players = []

#^ History storage:
var dialogue_history = []

#^ Nesting, conditions and choices:
var nesting_depth := 0
var if_array: Array = []

var killswitch = false
signal killswitch_off

var greenlight = true

var skip_wait = false	#/ Skip §Wait timers by setting them to 0 instantly.

var for_ = {}

#^ Stores command_value for all opened choice lists, for each depth.
var choice_list_data = {
#/	 "0": {
#/		"§Choice_List": {...},
#/		}
}

#^ References to all opened choice lists.
var choice_lists = {
#/	 "0": {
#/		"Menu": node reference,
#/		"Title": "title",
#/		"Tags": "tags",
#/		"Category Nodes": {
#/			"Category_1": {
#/				"Node": node reference,
#/				"Tags": "tags"
#/			},
#/		},
#/		"Last Choice": {
#/			"Choice_1": [category_name, choice_name, choice button node reference]
#/		}
#/	}
}

#^ Signal emitted by choices to communicated with §Choice_List command:
signal choice_list_event(depth: int, event: String, category: String, choice: String, source)

#^ Signal emitted by input menus to communicate with §Input command:
signal input_received(depth, event, parameters)

#endregion



#°#########################################################################################
#^
#^										 COMMANDS
#^
#°#########################################################################################
#region

#?##############################
#& COMMANDS:
#?##########
#* All §commands:
func commands(command_key, command_value, current_conversation, current_block, _line_index):
	#@ Killswitch check:
	if killswitch == true:
		return "END"

	#@ Suspended Dialogue:
	if dialogue_suspended == true:
		while dialogue_suspended == true:
			await get_tree().process_frame

	#@ Normalize command name:
	var cmd = normalize_command_name(command_key)

	#@ Command behavior:
	match cmd:

		#&########################################
		#&										##
		#&           CONTROL COMMANDS           ##
		#&										##
		#region - Control Commands
		#* §Call - invoke a method on a singleton, node, or vardict object:
		"§call":
			var func_name: String 		= command_value.get("Function", "")
			var args_raw: Variant 		= command_value.get("Arguments", "")
			var store_var: String		= command_value.get("Variable", "").strip_edges()
			var await_call: Variant 	= resolve_value(command_value.get("Await", true))

			#% Validate:
			if func_name == "":
				return "Continue"

			if func_name.begins_with(candy_de.super_singleton_symbol):
				func_name = resolve_value(candy_de.singleton_symbol + func_name.substr(1))
			elif func_name.begins_with(candy_de.super_node_symbol):
				func_name = resolve_value(candy_de.node_symbol + func_name.substr(1))
			elif func_name.begins_with(candy_de.super_vardict_symbol):
				func_name = resolve_value(candy_de.vardict_symbol + func_name.substr(1))

			if typeof(args_raw) == TYPE_STRING:
				if args_raw.begins_with(candy_de.super_singleton_symbol):
					args_raw = resolve_value(candy_de.singleton_symbol + args_raw.substr(1))
				elif args_raw.begins_with(candy_de.super_node_symbol):
					args_raw = resolve_value(candy_de.node_symbol + args_raw.substr(1))
				elif args_raw.begins_with(candy_de.super_vardict_symbol):
					args_raw = resolve_value(candy_de.vardict_symbol + args_raw.substr(1))

			#@ Step 1 - Prepare arguments:
			var args: Array = []
			#% Already a typed array, use directly:
			if typeof(args_raw) == TYPE_ARRAY:
				args = args_raw

			#% Otherwise, use Expression to interpret the argument string:
			elif typeof(args_raw) == TYPE_STRING and args_raw != "":
				var replaced := _replace_with_values(args_raw)
				var expression := Expression.new()
				if expression.parse("[" + replaced + "]") != OK:
					push_error("§Call: failed to parse arguments → " + replaced)
					return "Continue"

				var result = expression.execute()
				if expression.has_execute_failed():
					push_error("§Call: runtime error while evaluating arguments → " + replaced)
					return "Continue"

				if typeof(result) != TYPE_ARRAY:
					push_error("§Call: arguments did not evaluate to an Array → " + replaced)
					return "Continue"

				args = result

			#@ Step 2 - Execute the function:
			var result_2
			if func_name.begins_with(candy_de.singleton_symbol):
				print("Function begins with singleton symbol")
				#% Autoload or engine singleton call:
				var parts = func_name.substr(1).split(".", false)
				if parts.size() >= 2:
					print(parts)
					var autoload = parts[0]
					var method = parts[1]
					var target = null

					#% Try to find either a true engine singleton or a GDScript autoload:
					if Engine.has_singleton(autoload):
						target = Engine.get_singleton(autoload)
					elif has_node("/root/" + autoload):
						target = get_node("/root/" + autoload)
						print("Target: ")
						print(target)

					#% Call the method if found:
					if target and target.has_method(method):
						if await_call == true:
							result_2 = await target.callv(method, args)
						else:
							result_2 = target.callv(method, args)
					else:
						if not target:
							print("Unable to call function: autoload not found.")
						elif not target.has_method(method):
							print("Unable to call function: function not found in autoload.")

			#% Node path call:
			elif func_name.begins_with(candy_de.node_symbol):
				var path_and_func = func_name.substr(1).split(".", false)
				if path_and_func.size() >= 2:
					var path = path_and_func[0]
					var method = path_and_func[1]
					var node = get_node_or_null(path)
					if node and node.has_method(method):
						if await_call == true:
							result_2 = await node.callv(method, args)
						else:
							result_2 = node.callv(method, args)

			#% Local call (within the current script):
			else:
				if has_method(func_name):
					if await_call == true:
						result_2 = await callv(func_name, args)
					else:
						result_2 = callv(func_name, args)

			#% Store the returned value:
			if store_var != "":
				var decoded = decode_variable_name(store_var)
				if decoded["base"] != null:
					set_variable_value(decoded, result_2)

			return "Continue"


		#* §Emit - emit a signal on a singleton, node, or local object:
		"§emit":
			var signal_name: String		= command_value.get("Signal", "")
			var args_raw: Variant		= command_value.get("Arguments", "")

			#% Validate:
			if signal_name == "":
				return "Continue"

			if signal_name.begins_with(candy_de.super_singleton_symbol):
				signal_name = resolve_value(candy_de.singleton_symbol + signal_name.substr(1))
			elif signal_name.begins_with(candy_de.super_node_symbol):
				signal_name = resolve_value(candy_de.node_symbol + signal_name.substr(1))
			elif signal_name.begins_with(candy_de.super_vardict_symbol):
				signal_name = resolve_value(candy_de.vardict_symbol + signal_name.substr(1))

			if typeof(args_raw) == TYPE_STRING:
				if args_raw.begins_with(candy_de.super_singleton_symbol):
					args_raw = resolve_value(candy_de.singleton_symbol + args_raw.substr(1))
				elif args_raw.begins_with(candy_de.super_node_symbol):
					args_raw = resolve_value(candy_de.node_symbol + args_raw.substr(1))
				elif args_raw.begins_with(candy_de.super_vardict_symbol):
					args_raw = resolve_value(candy_de.vardict_symbol + args_raw.substr(1))

			#@ Step 1 - Prepare arguments:
			var args: Array = []
			#% Already a typed array, use directly:
			if typeof(args_raw) == TYPE_ARRAY:
				args = args_raw

			#% Otherwise, use Expression to interpret the argument string:
			elif typeof(args_raw) == TYPE_STRING and args_raw != "":
				var replaced := _replace_with_values(args_raw)
				var expression := Expression.new()
				if expression.parse("[" + replaced + "]") != OK:
					push_error("§Emit: failed to parse arguments → " + replaced)
					return "Continue"
				var result = expression.execute()
				if expression.has_execute_failed():
					push_error("§Emit: runtime error while evaluating arguments → " + replaced)
					return "Continue"
				if typeof(result) != TYPE_ARRAY:
					push_error("§Emit: arguments did not evaluate to an Array → " + replaced)
					return "Continue"
				args = result

			#@ Step 2 - Emit the signal:
			#% Autoload or engine singleton signal:
			if signal_name.begins_with(candy_de.singleton_symbol):
				var parts = signal_name.substr(1).split(".", false)
				if parts.size() >= 2:
					var autoload = parts[0]
					var sig = parts[1]
					var target = null

					#% Try both engine and GDScript autoloads:
					if Engine.has_singleton(autoload):
						target = Engine.get_singleton(autoload)
					elif has_node("/root/" + autoload):
						target = get_node("/root/" + autoload)

					#% Emit signal if found:
					if target and target.has_signal(sig):
						target.callv("emit_signal", [sig] + args)
					else:
						if not target:
							push_error("§Emit: autoload not found → " + autoload)
						else:
							push_error("§Emit: signal not found on " + autoload + " → " + sig)

			#% Node path signal:
			elif signal_name.begins_with(candy_de.node_symbol):
				var path_and_sig = signal_name.substr(1).split(".", false)
				if path_and_sig.size() >= 2:
					var path = path_and_sig[0]
					var sig = path_and_sig[1]
					var node = get_node_or_null(path)
					if node and node.has_signal(sig):
						node.callv("emit_signal", [sig] + args)
					else:
						if not node:
							push_error("§Emit: node not found → " + path)
						else:
							push_error("§Emit: signal not found on node " + path + " → " + sig)

			#% Local signal:
			else:
				if has_signal(signal_name):
					callv("emit_signal", [signal_name] + args)
				else:
					push_error("§Emit: local signal not found → " + signal_name)

			return "Continue"


		#* §Await - await on a signal:
		"§await":
			var signal_name: String		= command_value.get("Signal", "")
			var store_var: String		= command_value.get("Variable", "").strip_edges()

			#% Validate:
			if signal_name == "":
				return "Continue"

			#% Resolve super variables:
			if signal_name.begins_with(candy_de.super_singleton_symbol):
				signal_name = resolve_value(candy_de.singleton_symbol + signal_name.substr(1))
			elif signal_name.begins_with(candy_de.super_node_symbol):
				signal_name = resolve_value(candy_de.node_symbol + signal_name.substr(1))
			elif signal_name.begins_with(candy_de.super_vardict_symbol):
				signal_name = resolve_value(candy_de.vardict_symbol + signal_name.substr(1))

			#@ Step 1 - Expect format: "target.signal_name"
			var signal_parts := signal_name.split(".", false)

			if signal_parts.size() != 2:
				printerr("§Await: Invalid signal format → ", signal_name)
				return "Continue"

			var path_str := signal_parts[0]
			var sig_str  := signal_parts[1]

			#@ Step 2 - Resolve signal target:
			var signal_target: Object = null

			if path_str.begins_with(candy_de.singleton_symbol) or path_str.begins_with(candy_de.node_symbol) or path_str.begins_with(candy_de.vardict_symbol):
				var decoded = decode_variable_name(path_str)
				signal_target = get_variable_value(decoded)
			else:
				signal_target = get_node_or_null(path_str)

			if signal_target == null:
				printerr("§Await: Target not found → ", path_str)
				return "Continue"

			if not signal_target.has_signal(sig_str):
				printerr("§Await: Unknown signal → ", sig_str)
				return "Continue"

			#@ Step 3 - Await signal:
			var result = await Signal(signal_target, sig_str)

			#@ Step 4 - Normalize arguments (safe for 0/1/many):
			var args: Array = []
			if result is Array:
				args = result
			elif result != null:
				args = [result]

			#@ Step 5 - Store signal arguments if requested:
			if store_var != "":
				var decoded = decode_variable_name(store_var)
				if decoded["base"] != null:
					#% Store single value directly, array if multiple, null if none:
					if args.size() == 0:
						set_variable_value(decoded, null)
					elif args.size() == 1:
						set_variable_value(decoded, args[0])
					else:
						set_variable_value(decoded, args)

			print("[DEBUG] §Await completed → ", sig_str)

			#@ Step 6 - Handle signal-specific logic:
			match sig_str:
				#TODO: Add custom cases for signals.
				_:
					return "Continue"


		#* §Set - Modify a variable:
		"§set":
			var lhs_var: String		= command_value.get("Variable", "")
			var operator: String	= resolve_value(command_value.get("Operator", "="))
			var expr_line: String	= command_value.get("Expression", "")

			if expr_line.is_empty():
				printerr("§Set: empty expression")
				return "Continue"

			#@ Resolve super symbols at the start:
			if lhs_var.begins_with(candy_de.super_singleton_symbol):
				lhs_var = resolve_value(candy_de.singleton_symbol + lhs_var.substr(1))
			elif lhs_var.begins_with(candy_de.super_node_symbol):
				lhs_var = resolve_value(candy_de.node_symbol + lhs_var.substr(1))
			elif lhs_var.begins_with(candy_de.super_vardict_symbol):
				lhs_var = resolve_value(candy_de.vardict_symbol + lhs_var.substr(1))

			if expr_line.begins_with(candy_de.super_singleton_symbol):
				expr_line = resolve_value(candy_de.singleton_symbol + expr_line.substr(1))
			elif expr_line.begins_with(candy_de.super_node_symbol):
				expr_line = resolve_value(candy_de.node_symbol + expr_line.substr(1))
			elif expr_line.begins_with(candy_de.super_vardict_symbol):
				expr_line = resolve_value(candy_de.vardict_symbol + expr_line.substr(1))

			#@ Decode LHS variable reference:
			var decoded = decode_variable_name(lhs_var)
			if decoded.is_empty() or decoded["base"] == null:
				printerr("§Set: invalid variable reference → ", lhs_var)
				return "Continue"

			#@ Determine RHS value:
			var rhs_value
			if (expr_line.begins_with("'") and expr_line.ends_with("'")) or (expr_line.begins_with("\"") and expr_line.ends_with("\"")):
				#% Literal string → strip quotes:
				rhs_value = expr_line.substr(1, expr_line.length() - 2)
			else:
				#% Replace variable symbols with actual values:
				var replaced_expr = _replace_with_values(expr_line)
				replaced_expr = replaced_expr.replace("'", "\"")	#/ Make quotes safe for Expression
				var expression = Expression.new()
				if expression.parse(replaced_expr) != OK:
					printerr("§Set: failed to parse → ", replaced_expr)
					return "Continue"
				rhs_value = expression.execute()
				if expression.has_execute_failed():
					printerr("§Set: runtime error → ", replaced_expr)
					return "Continue"

			#@ Apply operator:
			var final_value = calculate_variable_value(decoded, rhs_value, operator)

			#@ Assign value:
			set_variable_value(decoded, final_value)

			print("[DEBUG] §Set →", lhs_var, operator, expr_line, "=", final_value)
			return "Continue"


		#* §Flag - Modify entries in the candy_de.flags dictionary:
		"§flag":
			var flag_expr: String	= resolve_value(command_value.get("Flag", "").strip_edges())
			var operator: String	= resolve_value(command_value.get("Operator", "="))
			var expr_line: String	= command_value.get("Expression", "")

			if flag_expr == "":
				return "Continue"

			#@ Resolve super symbols at the start:
			if expr_line.begins_with(candy_de.super_singleton_symbol):
				expr_line = resolve_value(candy_de.singleton_symbol + expr_line.substr(1))
			elif expr_line.begins_with(candy_de.super_node_symbol):
				expr_line = resolve_value(candy_de.node_symbol + expr_line.substr(1))
			elif expr_line.begins_with(candy_de.super_vardict_symbol):
				expr_line = resolve_value(candy_de.vardict_symbol + expr_line.substr(1))

			#@ Decode reference directly into candy_de.flags[flag_expr]:
			var decoded = {
				"base": candy_de.flags,
				"path": [flag_expr]
			}

			#@ Evaluate RHS using Expression:
			var rhs_value: Variant
			if (typeof(expr_line) == TYPE_STRING) and ((expr_line.begins_with("'") and expr_line.ends_with("'")) or (expr_line.begins_with("\"") and expr_line.ends_with("\""))):
				#% Literal string → strip quotes:
				rhs_value = expr_line.substr(1, expr_line.length() - 2)
			else:
				#% Replace variable symbols with actual values:
				var replaced_expr = _replace_with_values(str(expr_line))
				replaced_expr = replaced_expr.replace("'", "\"")	#/ Make quotes safe for Expression
				var expression = Expression.new()
				if expression.parse(replaced_expr) != OK:
					printerr("§Flag: failed to parse → ", replaced_expr)
					return "Continue"
				rhs_value = expression.execute()
				if expression.has_execute_failed():
					printerr("§Flag: runtime error → ", replaced_expr)
					return "Continue"

			#@ Apply operator:
			var final_value = calculate_variable_value(decoded, rhs_value, operator)

			#@ Assign value:
			candy_de.flags[flag_expr] = final_value

			print("[DEBUG] §Flag →", flag_expr, operator, expr_line, "=", final_value)
			return "Continue"


		#* §Name - Change a character's display name:
		"§name":
			var actor_ref: String	= resolve_value(command_value.get("Reference", ""))
			var new_name: String	= resolve_value(command_value.get("Name", ""))
			var table_raw: String	= command_value.get("Table", "£candy_de.display_names")
			var key_raw: String		= resolve_value(command_value.get("Actor_Key", "Display Name"))		#/ Ensures compatibility

			#@ Step 1 - Resolve super symbols at the start:
			if table_raw.begins_with(candy_de.super_singleton_symbol):
				table_raw = resolve_value(candy_de.singleton_symbol + table_raw.substr(1))
			elif table_raw.begins_with(candy_de.super_node_symbol):
				table_raw = resolve_value(candy_de.node_symbol + table_raw.substr(1))
			elif table_raw.begins_with(candy_de.super_vardict_symbol):
				table_raw = resolve_value(candy_de.vardict_symbol + table_raw.substr(1))

			#@ Step 2 - Resolve Actor_Key if empty:
			if key_raw == "":
				key_raw = "Display Name"

			#@ Step 3 - Resolve Table if empty:
			if key_raw == "Display Name" and table_raw == "":
				table_raw = "display_names"

			#@ Step 4 - Translate the name (translate() handles table resolution internally):
			new_name = translate(new_name, table_raw)

			#@ Step 5 - Apply the change:
			if candy_de.actors.has(actor_ref):
				candy_de.actors[actor_ref][key_raw] = new_name

			return "Continue"


		#* §Disposition - change a character's disposition:
		"§disposition":
			var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))
			var new_disp: String 	= resolve_value(command_value.get("Disposition", ""))

			#@ Step 1 - Apply change:
			if candy_de.actors.has(actor_ref):
				candy_de.actors[actor_ref]["Disposition"] = new_disp

			return "Continue"


		#* §Role - Change or assign a role mapping in candy_de.roles:
		"§role":
			var role_key: String	= resolve_value(command_value.get("Role", ""))
			var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))

			#@ Step 1 - Resolve actor role if needed:
			if actor_ref == "":
				print_debug("§Role: [CAUTION] A Role Reference is provided for assignment, but has no Actor assigned. Target Role will be cleared.")

			#@ Step 2 - Assign to candy_de.roles:
			candy_de.roles[role_key] = actor_ref

			return "Continue"


		#* §Export - Export variable values to file:
		"§export":
			var export_format: String = resolve_value(command_value.get("Format", "json")).to_lower()
			var data_str: String = command_value.get("Data", "")
			var file_name: String = resolve_value(command_value.get("File", "Export"))
			var custom_path: String = resolve_value(command_value.get("Path", ""))
			var method: String = resolve_value(command_value.get("Method", "Overwrite")).capitalize()

			#% Resolve if Data itself is a variable reference:
			if data_str.begins_with(candy_de.super_singleton_symbol):
				data_str = resolve_value(candy_de.singleton_symbol + data_str.substr(1))
			elif data_str.begins_with(candy_de.super_node_symbol):
				data_str = resolve_value(candy_de.node_symbol + data_str.substr(1))
			elif data_str.begins_with(candy_de.super_vardict_symbol):
				data_str = resolve_value(candy_de.vardict_symbol + data_str.substr(1))

			if data_str.is_empty():
				printerr("§Export: missing Data parameter.")
				return "Continue"

			#@ Split Data string into variable entries:
			var var_entries: Array = data_str.split(",", false)
			var export_dict := {}

			for entry in var_entries:
				entry = entry.strip_edges()
				if entry.is_empty():
					continue

				#@ Resolve symbol and store:
				var value = resolve_value(entry)
				if value == null:
					printerr("§Export: Unresolved variable → ", entry)
					continue
				export_dict[entry] = value

			#@ Determine export folder:
			var export_folder = candy_de.export_folder
			if custom_path.strip_edges() != "":
				export_folder = custom_path

			#@ Ensure export folder exists if local:
			if export_folder.begins_with("res://") or export_folder.begins_with("user://"):
				if not DirAccess.dir_exists_absolute(export_folder):
					DirAccess.make_dir_recursive_absolute(export_folder)

			#@ Sanitize filename and extension:
			var invalid_chars := ['<', '>', ':', '"', '/', '\\', '|', '?', '*']
			for ch in invalid_chars:
				file_name = file_name.replace(ch, "_")

			var fmt := export_format
			if fmt.begins_with("."):
				fmt = fmt.substr(1)

			var full_path := "%s/%s.%s" % [export_folder, file_name, fmt]

			#@ Handle existing file according to Method:
			if FileAccess.file_exists(full_path):
				match method:
					"Overwrite":
						pass
					"Skip":
						print("[DEBUG] §Export: File already exists, skipping → %s" % full_path)
						return "Continue"
					"Duplicate":
						var base_name := file_name
						var counter := 1
						while FileAccess.file_exists("%s/%s(%d).%s" % [export_folder, base_name, counter, fmt]):
							counter += 1
						full_path = "%s/%s(%d).%s" % [export_folder, base_name, counter, fmt]
					"Timestamp":
						var dt = Time.get_datetime_string_from_system(true, true)
						full_path = "%s/%s_%s.%s" % [export_folder, file_name, dt, fmt]
					_:
						printerr("§Export: Unknown Method '%s'." % method)
						return "Continue"

			#@ Export data depending on format:
			match export_format:
				"json", ".json":
					var serialized := {}
					for k in export_dict.keys():
						serialized[k] = var_to_str(export_dict[k])
					var json_str = JSON.stringify(serialized, "\t")
					var file = FileAccess.open(full_path, FileAccess.WRITE)
					file.store_string(json_str)
					file.close()
					print("[DEBUG] §Export: Wrote %d entries to %s" % [export_dict.size(), full_path])

				"txt", ".txt":
					var txt := ""
					for k in export_dict.keys():
						var v = export_dict[k]
						txt += "%s = %s\n" % [k, var_to_str(v)]
					var file = FileAccess.open(full_path, FileAccess.WRITE)
					file.store_string(txt)
					file.close()
					print("[DEBUG] §Export: Wrote %d entries to %s" % [export_dict.size(), full_path])

				"csv", ".csv":
					var file = FileAccess.open(full_path, FileAccess.WRITE)
					for k in export_dict.keys():
						file.store_csv_line([k, str(export_dict[k])])
					file.close()
					print("[DEBUG] §Export: Wrote %d entries to %s" % [export_dict.size(), full_path])

				"cfg", "ini", ".cfg", ".ini":
					var cfg = ConfigFile.new()
					for k in export_dict.keys():
						cfg.set_value("Export", k, export_dict[k])
					cfg.save(full_path)
					print("[DEBUG] §Export: Wrote %d entries to %s" % [export_dict.size(), full_path])

				"bin", ".bin":
					var file = FileAccess.open(full_path, FileAccess.WRITE)
					file.store_var(export_dict, true)	#/ Compressed
					file.close()
					print("[DEBUG] §Export: Wrote %d entries (compressed) to %s" % [export_dict.size(), full_path])

				"b64", "base64":
					var encoded = Marshalls.variant_to_base64(export_dict)
					var file = FileAccess.open(full_path, FileAccess.WRITE)
					file.store_string(encoded)
					file.close()
					print("[DEBUG] §Export: Wrote %d entries (Base64) to %s" % [export_dict.size(), full_path])

				"tres", "res", ".tres", ".res":
					var res := Resource.new()
					for k in export_dict.keys():
						res.set(k, export_dict[k])
					var err = ResourceSaver.save(res, full_path)
					if err == OK:
						print("[DEBUG] §Export: Wrote %d entries to %s" % [export_dict.size(), full_path])
					else:
						printerr("§Export: Failed to save Resource (%s)." % full_path)

				_:
					printerr("§Export: Unknown format '%s'." % export_format)

			return "Continue"


		#* §Import - Import variable values from file:
		"§import":
			var import_format: String = resolve_value(command_value.get("Format", "")).to_lower()
			var file_name: String = resolve_value(command_value.get("File", "Export"))
			var custom_path: String = resolve_value(command_value.get("Path", ""))
			var dict_ref: String = command_value.get("Dictionary", "")

			#% Resolve super-symbols for Dictionary reference:
			if dict_ref.begins_with(candy_de.super_singleton_symbol):
				dict_ref = resolve_value(candy_de.singleton_symbol + dict_ref.substr(1))
			elif dict_ref.begins_with(candy_de.super_node_symbol):
				dict_ref = resolve_value(candy_de.node_symbol + dict_ref.substr(1))
			elif dict_ref.begins_with(candy_de.super_vardict_symbol):
				dict_ref = resolve_value(candy_de.vardict_symbol + dict_ref.substr(1))

			#@ Determine folder:
			var import_folder = candy_de.export_folder
			if custom_path.strip_edges() != "":
				import_folder = custom_path

			#@ Sanitize filename and detect format:
			file_name = file_name.replace("/", "_").replace("\\", "_").replace(":", "_")
			if import_format == "" and file_name.rfind(".") != -1:
				import_format = file_name.get_extension().to_lower()
			var fmt := import_format
			if fmt.begins_with("."):
				fmt = fmt.substr(1)
			var full_path := "%s/%s.%s" % [import_folder, file_name, fmt]

			#@ Check file existence:
			if not FileAccess.file_exists(full_path):
				printerr("§Import: File not found → %s" % full_path)
				return "Continue"

			#@ Read file contents:
			var file = FileAccess.open(full_path, FileAccess.READ)
			var content: String = file.get_as_text()
			file.close()

			#@ Decode depending on format:
			var imported_data := {}
			match import_format:
				"json", ".json":
					var parsed = JSON.parse_string(content)
					if typeof(parsed) == TYPE_DICTIONARY:
						#% Each value was serialized with var_to_str() on export, so we use
						#% str_to_var() to reconstruct the original Godot Variant type.
						#% If str_to_var() returns null and the value isn't literally "null",
						#% we keep it as a plain string — this handles files exported by other
						#% tools that don't use var_to_str() serialization:
						for k in parsed.keys():
							var raw = parsed[k]
							if typeof(raw) == TYPE_STRING:
								var reconstructed = str_to_var(raw)
								if reconstructed != null or raw.strip_edges().to_lower() == "null":
									imported_data[k] = reconstructed
								else:
									imported_data[k] = raw
							else:
								imported_data[k] = raw
					else:
						printerr("§Import: Invalid JSON data in '%s'." % full_path)
						return "Continue"

				"txt", ".txt":
					var joined := ""
					var depth := 0
					for ch in content:
						if ch == "{" or ch == "[":
							depth += 1
						elif ch == "}" or ch == "]":
							depth -= 1
						#% Replace newlines with spaces when inside a nested structure:
						if ch == "\n" and depth > 0:
							joined += " "
						else:
							joined += ch

					var lines = joined.split("\n", false)
					for line in lines:
						line = line.strip_edges()
						if line == "" or not line.contains("="):
							continue
						var eq_pos = line.find("=")
						var key = line.substr(0, eq_pos).strip_edges()
						var raw_val = line.substr(eq_pos + 1).strip_edges()

						var reconstructed = str_to_var(raw_val)
						if reconstructed != null or raw_val.strip_edges().to_lower() == "null":
							imported_data[key] = reconstructed
						else:
							imported_data[key] = raw_val

				"csv", ".csv":
					#% Safer CSV import using get_csv_line():
					while not file.eof_reached():
						var cols = file.get_csv_line()
						if cols.size() >= 2:
							imported_data[cols[0].strip_edges()] = cols[1].strip_edges()
					file.close()

				"cfg", "ini", ".cfg", ".ini":
					var cfg = ConfigFile.new()
					if cfg.load(full_path) == OK:
						var keys = cfg.get_section_keys("Export")
						for k in keys:
							imported_data[k] = cfg.get_value("Export", k)

				"bin", ".bin":
					var f = FileAccess.open(full_path, FileAccess.READ)
					imported_data = f.get_var()
					f.close()

				"b64", "base64":
					imported_data = Marshalls.base64_to_variant(content)

				"tres", "res", ".tres", ".res":
					var res = ResourceLoader.load(full_path)
					if res:
						var prop_list = res.get_property_list()
						for p in prop_list:
							var res_name = p.name
							imported_data[res_name] = res.get(res_name)
					else:
						printerr("§Import: Failed to load Resource (%s)." % full_path)
						return "Continue"

				_:
					printerr("§Import: Unknown format '%s'." % import_format)
					return "Continue"

			#@ Handle target dictionary:
			if dict_ref.strip_edges() != "":
				var target_dict = resolve_value(dict_ref)
				if typeof(target_dict) != TYPE_DICTIONARY:
					printerr("§Import: Target reference is not a dictionary → %s" % dict_ref)
					return "Continue"

				for k in imported_data.keys():
					target_dict[k] = imported_data[k]
				print("[DEBUG] §Import: Copied %d entries into %s" % [imported_data.size(), dict_ref])

			else:
				for path_key in imported_data.keys():
					var value = imported_data[path_key]
					set_variable_value(decode_variable_name(path_key), value)
					print("[DEBUG] §Import: Set %s = %s" % [path_key, str(value)])

			return "Continue"


		#* §Comment - comments in dialogue script:
		"§comment":
			return "Continue"
		#endregion - control commands


		#&########################################
		#&										##
		#&          CONDITION COMMANDS          ##
		#&										##
		#region - Condition Commands
		#* §If - Conditional branch:
		"§if":
			var condition_expr: String		= str(command_value.get("Condition", ""))
			var result: String				= resolve_value(str(command_value.get("Result", "Transition")))
			var transition_type: String		= resolve_value(str(command_value.get("Transition", "Bridge")))
			var convo: String				= resolve_value(str(command_value.get("Conversation", "")).strip_edges())
			var block: String				= resolve_value(str(command_value.get("Block", "")).strip_edges())
			var line_ref: String			= resolve_value(str(command_value.get("Line", "")).strip_edges())

			if condition_expr == "":
				return "Continue"

			#@ Handle super-symbols at start
			if condition_expr.begins_with(candy_de.super_singleton_symbol):
				condition_expr = resolve_value(candy_de.singleton_symbol + condition_expr.substr(1))
			elif condition_expr.begins_with(candy_de.super_node_symbol):
				condition_expr = resolve_value(candy_de.node_symbol + condition_expr.substr(1))
			elif condition_expr.begins_with(candy_de.super_vardict_symbol):
				condition_expr = resolve_value(candy_de.vardict_symbol + condition_expr.substr(1))

			#@ Replace Candy variable references in the condition
			var expr_line = _replace_with_values(condition_expr)
			expr_line = expr_line.replace("'", "\"")	#/ Make quotes safe for Expression

			#@ Evaluate the condition
			var expression = Expression.new()
			if expression.parse(expr_line) != OK:
				printerr("§If: failed to parse → ", expr_line)
				if_array.insert(nesting_depth, 0)
				return "Continue"

			var cond_result = expression.execute()
			if expression.has_execute_failed():
				printerr("§If: runtime error → ", expr_line)
				if_array.insert(nesting_depth, 0)
				return "Continue"

			#% Remove any existing chain at this depth
			if if_array.size() > nesting_depth:
				if_array.remove_at(nesting_depth)

			#% Create new open chain (0 = false, 1 = true)
			if_array.insert(nesting_depth, 1 if cond_result else 0)
			print("[DEBUG] §If chain at depth %d → if_array=%s" % [nesting_depth, str(if_array)])
			if cond_result:
				print("[DEBUG] §If condition TRUE at depth %d" % nesting_depth)

				#% Handle depending on result type:
				match result.to_lower():
					"transition":
						#% Transition logic (Bridge, Jump, etc.):
						match transition_type.to_lower():
							"bridge", "jump":
								var cmd_to_run := "§Bridge" if transition_type.to_lower() == "bridge" else "§Jump"

								#% Prepare fake transition line (simulating old Text array with one command):
								var fake_line := [
									{
										cmd_to_run: {
											"Conversation": convo,
											"Block": block,
											"Line": line_ref,
										}
									}
								]

								#% Run that command like a nested block:
								nesting_depth += 1
								var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
								nesting_depth -= 1
								print("[DEBUG] Exiting §If body at depth %d → if_array=%s" % [nesting_depth, str(if_array)])

								if feedback == "END":
									return "END"

							"return":
								print("[DEBUG] §If → §Return triggered at depth %d" % nesting_depth)
								return "Return"

							"end":
								print("[DEBUG] §If → §End triggered at depth %d" % nesting_depth)
								end_dialogue()
								return "END"

							_:
								print("[DEBUG] Unknown §If transition type: %s" % transition_type)

					"set":
						var lhs_var: String			= command_value.get("Variable", "")
						var operator: String		= resolve_value(command_value.get("Operator", "="))
						var set_expr_line: String	= command_value.get("Expression", "")

						if set_expr_line.is_empty():
							printerr("§Set: empty expression")
							return "Continue"

						if set_expr_line.begins_with(candy_de.super_singleton_symbol):
							set_expr_line = resolve_value(candy_de.singleton_symbol + set_expr_line.substr(1))
						elif set_expr_line.begins_with(candy_de.super_node_symbol):
							set_expr_line = resolve_value(candy_de.node_symbol + set_expr_line.substr(1))
						elif set_expr_line.begins_with(candy_de.super_vardict_symbol):
							set_expr_line = resolve_value(candy_de.vardict_symbol + set_expr_line.substr(1))

						var fake_line := [
							{
								"§Set": {
									"Variable": lhs_var,
									"Operator": operator,
									"Expression": set_expr_line
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Set at depth %d" % nesting_depth)
						return feedback

					"call":
						var func_name: String 		= command_value.get("Function", "")
						var args_raw: Variant 		= command_value.get("Arguments", "")
						var store_var: String		= command_value.get("Variable", "").strip_edges()
						var await_call: Variant 	= resolve_value(command_value.get("Await", true))

						if func_name.begins_with(candy_de.super_singleton_symbol):
							func_name = resolve_value(candy_de.singleton_symbol + func_name.substr(1))
						elif func_name.begins_with(candy_de.super_node_symbol):
							func_name = resolve_value(candy_de.node_symbol + func_name.substr(1))
						elif func_name.begins_with(candy_de.super_vardict_symbol):
							func_name = resolve_value(candy_de.vardict_symbol + func_name.substr(1))

						if typeof(args_raw) == TYPE_STRING:
							if args_raw.begins_with(candy_de.super_singleton_symbol):
								args_raw = resolve_value(candy_de.singleton_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_node_symbol):
								args_raw = resolve_value(candy_de.node_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_vardict_symbol):
								args_raw = resolve_value(candy_de.vardict_symbol + args_raw.substr(1))

						var fake_line := [
							{
								"§Call": {
									"Function": func_name,
									"Arguments": args_raw,
									"Variable": store_var,
									"Await": await_call,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Call at depth %d" % nesting_depth)
						return feedback

					"emit":
						var signal_name: String	= command_value.get("Signal", "")
						var args_raw: Variant 	= command_value.get("Arguments", "")

						#% Validate:
						if signal_name == "":
							return "Continue"

						if signal_name.begins_with(candy_de.super_singleton_symbol):
							signal_name = resolve_value(candy_de.singleton_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_node_symbol):
							signal_name = resolve_value(candy_de.node_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_vardict_symbol):
							signal_name = resolve_value(candy_de.vardict_symbol + signal_name.substr(1))

						if typeof(args_raw) == TYPE_STRING:
							if args_raw.begins_with(candy_de.super_singleton_symbol):
								args_raw = resolve_value(candy_de.singleton_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_node_symbol):
								args_raw = resolve_value(candy_de.node_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_vardict_symbol):
								args_raw = resolve_value(candy_de.vardict_symbol + args_raw.substr(1))

						var fake_line := [
							{
								"§Emit": {
									"Signal": signal_name,
									"Arguments": args_raw
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Emit at depth %d" % nesting_depth)
						return feedback

					"await":
						var signal_name: String = command_value.get("Signal", "")
						var store_var: String   = command_value.get("Variable", "").strip_edges()

						if signal_name == "":
							return "Continue"

						if signal_name.begins_with(candy_de.super_singleton_symbol):
							signal_name = resolve_value(candy_de.singleton_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_node_symbol):
							signal_name = resolve_value(candy_de.node_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_vardict_symbol):
							signal_name = resolve_value(candy_de.vardict_symbol + signal_name.substr(1))

						var fake_line := [
							{
								"§Await": {
									"Signal": signal_name,
									"Variable": store_var,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Await at depth %d" % nesting_depth)
						return feedback

					"flag":
						var flag_name: String		= resolve_value(command_value.get("Flag", "").strip_edges())
						var operator: String		= resolve_value(command_value.get("Operator", "="))
						var flag_expr_line: String	= command_value.get("Expression", "")

						if flag_expr_line.begins_with(candy_de.super_singleton_symbol):
							flag_expr_line = resolve_value(candy_de.singleton_symbol + flag_expr_line.substr(1))
						elif flag_expr_line.begins_with(candy_de.super_node_symbol):
							flag_expr_line = resolve_value(candy_de.node_symbol + flag_expr_line.substr(1))
						elif flag_expr_line.begins_with(candy_de.super_vardict_symbol):
							flag_expr_line = resolve_value(candy_de.vardict_symbol + flag_expr_line.substr(1))

						var fake_line := [
							{
								"§Flag": {
									"Flag": flag_name,
									"Operator": operator,
									"Expression": flag_expr_line,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Flag at depth %d" % nesting_depth)
						return feedback

					"name":
						var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))
						var new_name: String 	= resolve_value(command_value.get("Name", ""))
						var table_raw: String 	= command_value.get("Table", "£candy_de.display_names")
						var key_raw: String 	= resolve_value(command_value.get("Actor_Key", "Display Name"))

						var fake_line := [
							{
								"§Name": {
									"Reference": actor_ref,
									"Name": new_name,
									"Table": table_raw,
									"Actor_Key": key_raw,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Name at depth %d" % nesting_depth)
						return feedback

					"disposition":
						var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))
						var new_disp: String 	= resolve_value(command_value.get("Disposition", ""))

						var fake_line := [
							{
								"§Disposition": {
									"Reference": actor_ref,
									"Disposition": new_disp,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Disposition at depth %d" % nesting_depth)
						return feedback

					"role":
						var role_key: String	= resolve_value(command_value.get("Role", ""))
						var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))

						var fake_line := [
							{
								"§Role": {
									"Role": role_key,
									"Reference": actor_ref,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Role at depth %d" % nesting_depth)
						return feedback

					_:
						#% Failsafe
						print("[DEBUG] §If condition TRUE but result type '%s' not handled yet." % result)

			else:
				print("[DEBUG] §If condition FALSE at depth %d" % nesting_depth)

			return "Continue"


		#* §Elif - Continue the same conditional chain:
		"§elif":
			var condition_expr: String		= str(command_value.get("Condition", ""))
			var result: String				= resolve_value(str(command_value.get("Result", "Transition")))
			var transition_type: String		= resolve_value(str(command_value.get("Transition", "Bridge")))
			var convo: String				= resolve_value(str(command_value.get("Conversation", "")).strip_edges())
			var block: String				= resolve_value(str(command_value.get("Block", "")).strip_edges())
			var line_ref: String			= resolve_value(str(command_value.get("Line", "")).strip_edges())

			#@ Resolve super symbols at start:
			if condition_expr.begins_with(candy_de.super_singleton_symbol):
				condition_expr = resolve_value(candy_de.singleton_symbol + condition_expr.substr(1))
			elif condition_expr.begins_with(candy_de.super_node_symbol):
				condition_expr = resolve_value(candy_de.node_symbol + condition_expr.substr(1))
			elif condition_expr.begins_with(candy_de.super_vardict_symbol):
				condition_expr = resolve_value(candy_de.vardict_symbol + condition_expr.substr(1))

			#@ Skip if chain already executed at this depth:
			if if_array.size() > nesting_depth and if_array[nesting_depth] == 1:
				return "Continue"

			#@ Replace Candy variable references in the condition
			var expr_line = _replace_with_values(condition_expr)
			expr_line = expr_line.replace("'", "\"")	#/ Make quotes safe for Expression

			#@ Evaluate condition with Expression:
			var expr = Expression.new()
			if expr.parse(expr_line) != OK:
				printerr("§Elif: failed to parse condition → ", expr_line)
				return "Continue"

			var cond_result = expr.execute()
			if expr.has_execute_failed():
				printerr("§Elif: runtime error → ", expr_line)
				return "Continue"

			#@ Insert TRUE/FALSE into the chain:
			if if_array.size() <= nesting_depth:
				if_array.append(1 if cond_result else 0)
			else:
				if_array[nesting_depth] = 1 if cond_result else 0

			print("[DEBUG] §Elif condition at depth %d → %s" % [nesting_depth, str(cond_result)])

			#@ Handle depending on result type:
			if cond_result:
				match result.to_lower():
					"transition":
						#% Transition logic (Bridge, Jump, etc.):
						match transition_type.to_lower():
							"bridge", "jump":
								var cmd_to_run := "§Bridge" if transition_type.to_lower() == "bridge" else "§Jump"

								#% Build fake single-line transition command:
								var fake_line := [
									{
										cmd_to_run: {
											"Conversation": convo,
											"Block": block,
											"Line": line_ref,
										}
									}
								]

								nesting_depth += 1
								var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
								nesting_depth -= 1
								print("[DEBUG] Exiting §Elif body at depth %d → if_array=%s" % [nesting_depth, str(if_array)])

								if feedback == "END":
									return "END"

							"return":
								print("[DEBUG] §Elif → §Return triggered at depth %d" % nesting_depth)
								return "Return"

							"end":
								print("[DEBUG] §Elif → §End triggered at depth %d" % nesting_depth)
								end_dialogue()
								return "END"

							_:
								print("[DEBUG] Unknown §Elif transition type: %s" % transition_type)

					"set":
						var lhs_var: String = command_value.get("Variable", "")
						var operator: String = resolve_value(command_value.get("Operator", "="))
						var set_expr_line: String = command_value.get("Expression", "")

						if set_expr_line.is_empty():
							printerr("§Set: empty expression")
							return "Continue"

						if set_expr_line.begins_with(candy_de.super_singleton_symbol):
							set_expr_line = resolve_value(candy_de.singleton_symbol + set_expr_line.substr(1))
						elif set_expr_line.begins_with(candy_de.super_node_symbol):
							set_expr_line = resolve_value(candy_de.node_symbol + set_expr_line.substr(1))
						elif set_expr_line.begins_with(candy_de.super_vardict_symbol):
							set_expr_line = resolve_value(candy_de.vardict_symbol + set_expr_line.substr(1))

						var fake_line := [
							{
								"§Set": {
									"Variable": lhs_var,
									"Operator": operator,
									"Expression": set_expr_line
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Set at depth %d" % nesting_depth)
						return feedback

					"call":
						var func_name: String 		= command_value.get("Function", "")
						var args_raw: Variant 		= command_value.get("Arguments", "")
						var store_var: String		= command_value.get("Variable", "").strip_edges()
						var await_call: Variant 	= resolve_value(command_value.get("Await", true))

						if func_name.begins_with(candy_de.super_singleton_symbol):
							func_name = resolve_value(candy_de.singleton_symbol + func_name.substr(1))
						elif func_name.begins_with(candy_de.super_node_symbol):
							func_name = resolve_value(candy_de.node_symbol + func_name.substr(1))
						elif func_name.begins_with(candy_de.super_vardict_symbol):
							func_name = resolve_value(candy_de.vardict_symbol + func_name.substr(1))

						if typeof(args_raw) == TYPE_STRING:
							if args_raw.begins_with(candy_de.super_singleton_symbol):
								args_raw = resolve_value(candy_de.singleton_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_node_symbol):
								args_raw = resolve_value(candy_de.node_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_vardict_symbol):
								args_raw = resolve_value(candy_de.vardict_symbol + args_raw.substr(1))

						var fake_line := [
							{
								"§Call": {
									"Function": func_name,
									"Arguments": args_raw,
									"Variable": store_var,
									"Await": await_call,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Call at depth %d" % nesting_depth)
						return feedback

					"emit":
						var signal_name: String	= command_value.get("Signal", "")
						var args_raw: Variant 	= command_value.get("Arguments", "")

						#% Validate:
						if signal_name == "":
							return "Continue"

						if signal_name.begins_with(candy_de.super_singleton_symbol):
							signal_name = resolve_value(candy_de.singleton_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_node_symbol):
							signal_name = resolve_value(candy_de.node_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_vardict_symbol):
							signal_name = resolve_value(candy_de.vardict_symbol + signal_name.substr(1))

						if typeof(args_raw) == TYPE_STRING:
							if args_raw.begins_with(candy_de.super_singleton_symbol):
								args_raw = resolve_value(candy_de.singleton_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_node_symbol):
								args_raw = resolve_value(candy_de.node_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_vardict_symbol):
								args_raw = resolve_value(candy_de.vardict_symbol + args_raw.substr(1))

						var fake_line := [
							{
								"§Emit": {
									"Signal": signal_name,
									"Arguments": args_raw
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Emit at depth %d" % nesting_depth)
						return feedback

					"await":
						var signal_name: String = command_value.get("Signal", "")
						var store_var: String   = command_value.get("Variable", "").strip_edges()

						if signal_name == "":
							return "Continue"

						if signal_name.begins_with(candy_de.super_singleton_symbol):
							signal_name = resolve_value(candy_de.singleton_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_node_symbol):
							signal_name = resolve_value(candy_de.node_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_vardict_symbol):
							signal_name = resolve_value(candy_de.vardict_symbol + signal_name.substr(1))

						var fake_line := [
							{
								"§Await": {
									"Signal": signal_name,
									"Variable": store_var,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Await at depth %d" % nesting_depth)
						return feedback

					"flag":
						var flag_name: String		= resolve_value(command_value.get("Flag", "").strip_edges())
						var operator: String		= resolve_value(command_value.get("Operator", "="))
						var flag_expr_line: String	= command_value.get("Expression", "")

						if flag_expr_line.begins_with(candy_de.super_singleton_symbol):
							flag_expr_line = resolve_value(candy_de.singleton_symbol + flag_expr_line.substr(1))
						elif flag_expr_line.begins_with(candy_de.super_node_symbol):
							flag_expr_line = resolve_value(candy_de.node_symbol + flag_expr_line.substr(1))
						elif flag_expr_line.begins_with(candy_de.super_vardict_symbol):
							flag_expr_line = resolve_value(candy_de.vardict_symbol + flag_expr_line.substr(1))

						var fake_line := [
							{
								"§Flag": {
									"Flag": flag_name,
									"Operator": operator,
									"Expression": flag_expr_line,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Flag at depth %d" % nesting_depth)
						return feedback

					"name":
						var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))
						var new_name: String 	= resolve_value(command_value.get("Name", ""))
						var table_raw: String 	= command_value.get("Table", "£candy_de.display_names")
						var key_raw: String 	= resolve_value(command_value.get("Actor_Key", "Display Name"))

						var fake_line := [
							{
								"§Name": {
									"Reference": actor_ref,
									"Name": new_name,
									"Table": table_raw,
									"Actor_Key": key_raw,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Name at depth %d" % nesting_depth)
						return feedback

					"disposition":
						var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))
						var new_disp: String 	= resolve_value(command_value.get("Disposition", ""))

						var fake_line := [
							{
								"§Disposition": {
									"Reference": actor_ref,
									"Disposition": new_disp,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Disposition at depth %d" % nesting_depth)
						return feedback

					"role":
						var role_key: String	= resolve_value(command_value.get("Role", ""))
						var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))

						var fake_line := [
							{
								"§Role": {
									"Role": role_key,
									"Reference": actor_ref,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Role at depth %d" % nesting_depth)
						return feedback

					_:
						#% Failsafe
						print("[DEBUG] §If condition TRUE but result type '%s' not handled yet." % result)

			return "Continue"


		#* §Else - Fallback for the chain:
		"§else":
			var result: String				= resolve_value(str(command_value.get("Result", "Transition")))
			var transition_type: String		= resolve_value(str(command_value.get("Transition", "Bridge")))
			var convo: String				= resolve_value(str(command_value.get("Conversation", "")).strip_edges())
			var block: String				= resolve_value(str(command_value.get("Block", "")).strip_edges())
			var line_ref: String			= resolve_value(str(command_value.get("Line", "")).strip_edges())

			#@ Only run if no previous condition succeeded at this depth:
			if if_array.size() > nesting_depth:
				if if_array[nesting_depth] == 0:
					if_array[nesting_depth] = 1
					print("[DEBUG] §Else taken at depth %d" % nesting_depth)

					#% Handle depending on result type:
					match result.to_lower():
						"transition":
							#% Transition logic (Bridge, Jump, etc.):
							match transition_type.to_lower():
								"bridge", "jump":
									var cmd_to_run := "§Bridge" if transition_type.to_lower() == "bridge" else "§Jump"

									#% Build fake transition dictionary:
									var fake_line := [
										{
											cmd_to_run: {
												"Conversation": convo,
												"Block": block,
												"Line": line_ref,
											}
										}
									]

									#@ Execute nested body
									nesting_depth += 1
									var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
									nesting_depth -= 1
									print("[DEBUG] Exiting §Else body at depth %d → if_array=%s" % [nesting_depth, str(if_array)])

									if feedback == "END":
										return "END"

								"return":
									print("[DEBUG] §Else → §Return triggered at depth %d" % nesting_depth)
									return "Return"

								"end":
									print("[DEBUG] §Else → §End triggered at depth %d" % nesting_depth)
									end_dialogue()
									return "END"

								_:
									print("[DEBUG] Unknown §Else transition type: %s" % transition_type)

						"set":
							var lhs_var: String = command_value.get("Variable", "")
							var operator: String = resolve_value(command_value.get("Operator", "="))
							var set_expr_line: String = command_value.get("Expression", "")

							if set_expr_line.is_empty():
								printerr("§Set: empty expression")
								return "Continue"

							if set_expr_line.begins_with(candy_de.super_singleton_symbol):
								set_expr_line = resolve_value(candy_de.singleton_symbol + set_expr_line.substr(1))
							elif set_expr_line.begins_with(candy_de.super_node_symbol):
								set_expr_line = resolve_value(candy_de.node_symbol + set_expr_line.substr(1))
							elif set_expr_line.begins_with(candy_de.super_vardict_symbol):
								set_expr_line = resolve_value(candy_de.vardict_symbol + set_expr_line.substr(1))

							var fake_line := [
								{
									"§Set": {
										"Variable": lhs_var,
										"Operator": operator,
										"Expression": set_expr_line
									}
								}
							]
							nesting_depth += 1
							var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
							nesting_depth -= 1
							print("[DEBUG] Exiting §If Set at depth %d" % nesting_depth)
							return feedback

						"call":
							var func_name: String 		= command_value.get("Function", "")
							var args_raw: Variant 		= command_value.get("Arguments", "")
							var store_var: String		= command_value.get("Variable", "").strip_edges()
							var await_call: Variant 	= resolve_value(command_value.get("Await", true))

							if func_name.begins_with(candy_de.super_singleton_symbol):
								func_name = resolve_value(candy_de.singleton_symbol + func_name.substr(1))
							elif func_name.begins_with(candy_de.super_node_symbol):
								func_name = resolve_value(candy_de.node_symbol + func_name.substr(1))
							elif func_name.begins_with(candy_de.super_vardict_symbol):
								func_name = resolve_value(candy_de.vardict_symbol + func_name.substr(1))

							if typeof(args_raw) == TYPE_STRING:
								if args_raw.begins_with(candy_de.super_singleton_symbol):
									args_raw = resolve_value(candy_de.singleton_symbol + args_raw.substr(1))
								elif args_raw.begins_with(candy_de.super_node_symbol):
									args_raw = resolve_value(candy_de.node_symbol + args_raw.substr(1))
								elif args_raw.begins_with(candy_de.super_vardict_symbol):
									args_raw = resolve_value(candy_de.vardict_symbol + args_raw.substr(1))

							var fake_line := [
								{
									"§Call": {
										"Function": func_name,
										"Arguments": args_raw,
										"Variable": store_var,
										"Await": await_call,
									}
								}
							]
							nesting_depth += 1
							var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
							nesting_depth -= 1
							print("[DEBUG] Exiting §If Call at depth %d" % nesting_depth)
							return feedback

						"emit":
							var signal_name: String	= command_value.get("Signal", "")
							var args_raw: Variant 	= command_value.get("Arguments", "")

							#% Validate:
							if signal_name == "":
								return "Continue"

							if signal_name.begins_with(candy_de.super_singleton_symbol):
								signal_name = resolve_value(candy_de.singleton_symbol + signal_name.substr(1))
							elif signal_name.begins_with(candy_de.super_node_symbol):
								signal_name = resolve_value(candy_de.node_symbol + signal_name.substr(1))
							elif signal_name.begins_with(candy_de.super_vardict_symbol):
								signal_name = resolve_value(candy_de.vardict_symbol + signal_name.substr(1))

							if typeof(args_raw) == TYPE_STRING:
								if args_raw.begins_with(candy_de.super_singleton_symbol):
									args_raw = resolve_value(candy_de.singleton_symbol + args_raw.substr(1))
								elif args_raw.begins_with(candy_de.super_node_symbol):
									args_raw = resolve_value(candy_de.node_symbol + args_raw.substr(1))
								elif args_raw.begins_with(candy_de.super_vardict_symbol):
									args_raw = resolve_value(candy_de.vardict_symbol + args_raw.substr(1))

							var fake_line := [
								{
									"§Emit": {
										"Signal": signal_name,
										"Arguments": args_raw
									}
								}
							]
							nesting_depth += 1
							var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
							nesting_depth -= 1
							print("[DEBUG] Exiting §If Emit at depth %d" % nesting_depth)
							return feedback

						"await":
							var signal_name: String = command_value.get("Signal", "")
							var store_var: String   = command_value.get("Variable", "").strip_edges()

							if signal_name == "":
								return "Continue"

							if signal_name.begins_with(candy_de.super_singleton_symbol):
								signal_name = resolve_value(candy_de.singleton_symbol + signal_name.substr(1))
							elif signal_name.begins_with(candy_de.super_node_symbol):
								signal_name = resolve_value(candy_de.node_symbol + signal_name.substr(1))
							elif signal_name.begins_with(candy_de.super_vardict_symbol):
								signal_name = resolve_value(candy_de.vardict_symbol + signal_name.substr(1))

							var fake_line := [
								{
									"§Await": {
										"Signal": signal_name,
										"Variable": store_var,
									}
								}
							]
							nesting_depth += 1
							var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
							nesting_depth -= 1
							print("[DEBUG] Exiting §If Await at depth %d" % nesting_depth)
							return feedback

						"flag":
							var flag_name: String		= resolve_value(command_value.get("Flag", "").strip_edges())
							var operator: String		= resolve_value(command_value.get("Operator", "="))
							var flag_expr_line: String	= command_value.get("Expression", "")

							if flag_expr_line.begins_with(candy_de.super_singleton_symbol):
								flag_expr_line = resolve_value(candy_de.singleton_symbol + flag_expr_line.substr(1))
							elif flag_expr_line.begins_with(candy_de.super_node_symbol):
								flag_expr_line = resolve_value(candy_de.node_symbol + flag_expr_line.substr(1))
							elif flag_expr_line.begins_with(candy_de.super_vardict_symbol):
								flag_expr_line = resolve_value(candy_de.vardict_symbol + flag_expr_line.substr(1))

							var fake_line := [
								{
									"§Flag": {
										"Flag": flag_name,
										"Operator": operator,
										"Expression": flag_expr_line,
									}
								}
							]
							nesting_depth += 1
							var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
							nesting_depth -= 1
							print("[DEBUG] Exiting §If Flag at depth %d" % nesting_depth)
							return feedback

						"name":
							var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))
							var new_name: String 	= resolve_value(command_value.get("Name", ""))
							var table_raw: String 	= command_value.get("Table", "£candy_de.display_names")
							var key_raw: String 	= resolve_value(command_value.get("Actor_Key", "Display Name"))

							var fake_line := [
								{
									"§Name": {
										"Reference": actor_ref,
										"Name": new_name,
										"Table": table_raw,
										"Actor_Key": key_raw,
									}
								}
							]
							nesting_depth += 1
							var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
							nesting_depth -= 1
							print("[DEBUG] Exiting §If Name at depth %d" % nesting_depth)
							return feedback

						"disposition":
							var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))
							var new_disp: String 	= resolve_value(command_value.get("Disposition", ""))

							var fake_line := [
								{
									"§Disposition": {
										"Reference": actor_ref,
										"Disposition": new_disp,
									}
								}
							]
							nesting_depth += 1
							var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
							nesting_depth -= 1
							print("[DEBUG] Exiting §If Disposition at depth %d" % nesting_depth)
							return feedback

						"role":
							var role_key: String	= resolve_value(command_value.get("Role", ""))
							var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))

							var fake_line := [
								{
									"§Role": {
										"Role": role_key,
										"Reference": actor_ref,
									}
								}
							]
							nesting_depth += 1
							var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
							nesting_depth -= 1
							print("[DEBUG] Exiting §If Role at depth %d" % nesting_depth)
							return feedback

						_:
							#% Failsafe
							print("[DEBUG] §If condition TRUE but result type '%s' not handled yet." % result)

				else:
					print("[DEBUG] §Else skipped (chain already closed) at depth %d" % nesting_depth)

			return "Continue"


		#* §For - Iterate over a condition-based sequence:
		"§for":
			var condition_expr: String = str(command_value.get("Condition", "")).strip_edges()
			var result: String = resolve_value(str(command_value.get("Result", "Transition")))
			var transition_type: String = resolve_value(str(command_value.get("Transition", "Bridge")))
			var convo: String = resolve_value(str(command_value.get("Conversation", "")).strip_edges())
			var block: String = resolve_value(str(command_value.get("Block", "")).strip_edges())
			var line_ref: String = resolve_value(str(command_value.get("Line", "")).strip_edges())

			#@ Resolve super symbols:
			if condition_expr.begins_with(candy_de.super_singleton_symbol):
				condition_expr = resolve_value(candy_de.singleton_symbol + condition_expr.substr(1))
			elif condition_expr.begins_with(candy_de.super_node_symbol):
				condition_expr = resolve_value(candy_de.node_symbol + condition_expr.substr(1))
			elif condition_expr.begins_with(candy_de.super_vardict_symbol):
				condition_expr = resolve_value(candy_de.vardict_symbol + condition_expr.substr(1))

			#@ Resolve Candy references in the entire condition before parsing:
			condition_expr = _replace_with_values(condition_expr)

			#@ Step 1 - Parse "<var> in <iterable>":
			if condition_expr.find(" in ") == -1:
				push_error("§For: invalid condition syntax → " + condition_expr)
				return "Continue"

			var parts = condition_expr.split(" in ", false, 2)
			var loop_var = parts[0].strip_edges()
			var iterable_expr = parts[1].strip_edges()

			#@ Step 2 - Evaluate iterable using Expression:
			var iterable: Array = []

			#% Extract RHS of "<var> in <iterable>":
			var rhs_text = iterable_expr.replace("'", "\"")		#/ Make quotes safe for Expression

			#% Special case: range():
			if rhs_text.begins_with("range("):
				var args_str = rhs_text.substr(6, rhs_text.length() - 7).strip_edges()
				var args = args_str.split(",", false)
				var start = 0
				var end = 0
				var step = 1

				if args.size() == 1:
					end = int(args[0])
				elif args.size() == 2:
					start = int(args[0])
					end = int(args[1])
				elif args.size() == 3:
					start = int(args[0])
					end = int(args[1])
					step = int(args[2])
				else:
					push_error("§For: invalid range() syntax → " + rhs_text)
					return "Continue"

				iterable = range(start, end, step)

			#% Evaluate as general Expression:
			else:
				var expr = Expression.new()
				if expr.parse(rhs_text) != OK:
					push_error("§For: failed to parse iterable → " + rhs_text)
					return "Continue"

				var eval_result = expr.execute()
				if expr.has_execute_failed():
					push_error("§For: runtime error → " + rhs_text)
					return "Continue"

				if typeof(eval_result) == TYPE_ARRAY:
					iterable = eval_result
				elif typeof(eval_result) == TYPE_DICTIONARY:
					iterable = eval_result.keys()
				else:
					push_error("§For: RHS is not iterable → " + str(eval_result))
					return "Continue"

			#@ Step 3 - Ensure tracking slot for variable exists:
			if not for_.has(loop_var):
				for_[loop_var] = null

			#@ Step 4 - Helper - run the body for each iteration:
			var run_body := func() -> Variant:
				match result.to_lower():
					"transition":
						match transition_type.to_lower():
							"bridge", "jump":
								var cmd_to_run := "§Bridge" if transition_type.to_lower() == "bridge" else "§Jump"
								var fake_line := [
									{
										cmd_to_run: {
											"Conversation": convo,
											"Block": block,
											"Line": line_ref,
										}
									}
								]

								nesting_depth += 1
								var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
								nesting_depth -= 1
								return feedback

							"return":
								print("[DEBUG] §For → §Return triggered")
								return "Return"

							"end":
								print("[DEBUG] §For → §End triggered")
								end_dialogue()
								return "END"

							_:
								print("[DEBUG] Unknown §For transition type: %s" % transition_type)
								return "Continue"

					"set":
						var lhs_var: String = command_value.get("Variable", "")
						var operator: String = resolve_value(command_value.get("Operator", "="))
						var set_expr_line: String = command_value.get("Expression", "")

						if set_expr_line.is_empty():
							printerr("§Set: empty expression")
							return "Continue"

						if set_expr_line.begins_with(candy_de.super_singleton_symbol):
							set_expr_line = resolve_value(candy_de.singleton_symbol + set_expr_line.substr(1))
						elif set_expr_line.begins_with(candy_de.super_node_symbol):
							set_expr_line = resolve_value(candy_de.node_symbol + set_expr_line.substr(1))
						elif set_expr_line.begins_with(candy_de.super_vardict_symbol):
							set_expr_line = resolve_value(candy_de.vardict_symbol + set_expr_line.substr(1))

						var fake_line := [
							{
								"§Set": {
									"Variable": lhs_var,
									"Operator": operator,
									"Expression": set_expr_line
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Set at depth %d" % nesting_depth)
						return feedback

					"call":
						var func_name: String 		= command_value.get("Function", "")
						var args_raw: Variant 		= command_value.get("Arguments", "")
						var store_var: String		= command_value.get("Variable", "").strip_edges()
						var await_call: Variant 	= resolve_value(command_value.get("Await", true))

						if func_name.begins_with(candy_de.super_singleton_symbol):
							func_name = resolve_value(candy_de.singleton_symbol + func_name.substr(1))
						elif func_name.begins_with(candy_de.super_node_symbol):
							func_name = resolve_value(candy_de.node_symbol + func_name.substr(1))
						elif func_name.begins_with(candy_de.super_vardict_symbol):
							func_name = resolve_value(candy_de.vardict_symbol + func_name.substr(1))

						if typeof(args_raw) == TYPE_STRING:
							if args_raw.begins_with(candy_de.super_singleton_symbol):
								args_raw = resolve_value(candy_de.singleton_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_node_symbol):
								args_raw = resolve_value(candy_de.node_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_vardict_symbol):
								args_raw = resolve_value(candy_de.vardict_symbol + args_raw.substr(1))

						var fake_line := [
							{
								"§Call": {
									"Function": func_name,
									"Arguments": args_raw,
									"Variable": store_var,
									"Await": await_call,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Call at depth %d" % nesting_depth)
						return feedback

					"emit":
						var signal_name: String	= command_value.get("Signal", "")
						var args_raw: Variant 	= command_value.get("Arguments", "")

						#% Validate:
						if signal_name == "":
							return "Continue"

						if signal_name.begins_with(candy_de.super_singleton_symbol):
							signal_name = resolve_value(candy_de.singleton_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_node_symbol):
							signal_name = resolve_value(candy_de.node_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_vardict_symbol):
							signal_name = resolve_value(candy_de.vardict_symbol + signal_name.substr(1))

						if typeof(args_raw) == TYPE_STRING:
							if args_raw.begins_with(candy_de.super_singleton_symbol):
								args_raw = resolve_value(candy_de.singleton_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_node_symbol):
								args_raw = resolve_value(candy_de.node_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_vardict_symbol):
								args_raw = resolve_value(candy_de.vardict_symbol + args_raw.substr(1))

						var fake_line := [
							{
								"§Emit": {
									"Signal": signal_name,
									"Arguments": args_raw
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Emit at depth %d" % nesting_depth)
						return feedback

					"await":
						var signal_name: String = command_value.get("Signal", "")
						var store_var: String   = command_value.get("Variable", "").strip_edges()

						if signal_name == "":
							return "Continue"

						if signal_name.begins_with(candy_de.super_singleton_symbol):
							signal_name = resolve_value(candy_de.singleton_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_node_symbol):
							signal_name = resolve_value(candy_de.node_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_vardict_symbol):
							signal_name = resolve_value(candy_de.vardict_symbol + signal_name.substr(1))

						var fake_line := [
							{
								"§Await": {
									"Signal": signal_name,
									"Variable": store_var,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Await at depth %d" % nesting_depth)
						return feedback

					"flag":
						var flag_name: String		= resolve_value(command_value.get("Flag", "").strip_edges())
						var operator: String		= resolve_value(command_value.get("Operator", "="))
						var flag_expr_line: String	= command_value.get("Expression", "")

						if flag_expr_line.begins_with(candy_de.super_singleton_symbol):
							flag_expr_line = resolve_value(candy_de.singleton_symbol + flag_expr_line.substr(1))
						elif flag_expr_line.begins_with(candy_de.super_node_symbol):
							flag_expr_line = resolve_value(candy_de.node_symbol + flag_expr_line.substr(1))
						elif flag_expr_line.begins_with(candy_de.super_vardict_symbol):
							flag_expr_line = resolve_value(candy_de.vardict_symbol + flag_expr_line.substr(1))

						var fake_line := [
							{
								"§Flag": {
									"Flag": flag_name,
									"Operator": operator,
									"Expression": flag_expr_line,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Flag at depth %d" % nesting_depth)
						return feedback

					"name":
						var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))
						var new_name: String 	= resolve_value(command_value.get("Name", ""))
						var table_raw: String 	= command_value.get("Table", "£candy_de.display_names")
						var key_raw: String 	= resolve_value(command_value.get("Actor_Key", "Display Name"))

						var fake_line := [
							{
								"§Name": {
									"Reference": actor_ref,
									"Name": new_name,
									"Table": table_raw,
									"Actor_Key": key_raw,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Name at depth %d" % nesting_depth)
						return feedback

					"disposition":
						var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))
						var new_disp: String 	= resolve_value(command_value.get("Disposition", ""))

						var fake_line := [
							{
								"§Disposition": {
									"Reference": actor_ref,
									"Disposition": new_disp,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Disposition at depth %d" % nesting_depth)
						return feedback

					"role":
						var role_key: String	= resolve_value(command_value.get("Role", ""))
						var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))

						var fake_line := [
							{
								"§Role": {
									"Role": role_key,
									"Reference": actor_ref,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Role at depth %d" % nesting_depth)
						return feedback

					_:
						#% Failsafe
						print("[DEBUG] §If condition TRUE but result type '%s' not handled yet." % result)
						return "Continue"

			#@ Step 5 - Execute loop:
			for val in iterable:
				for_[loop_var] = val
				var feedback = await run_body.call()
				if feedback == "END":
					return "END"
				elif feedback == "Return":
					return "Return"

			return "Continue"


		#* §While - repeat body while condition is true:
		"§while":
			var condition_expr: String		= str(command_value.get("Condition", ""))
			var result: String				= resolve_value(str(command_value.get("Result", "Transition")))
			var transition_type: String		= resolve_value(str(command_value.get("Transition", "Bridge")))
			var convo: String				= resolve_value(str(command_value.get("Conversation", "")).strip_edges())
			var block: String				= resolve_value(str(command_value.get("Block", "")).strip_edges())
			var line_ref: String			= resolve_value(str(command_value.get("Line", "")).strip_edges())

			var safety_counter := 0

			#@ Resolve super symbols:
			if condition_expr.begins_with(candy_de.super_singleton_symbol):
				condition_expr = resolve_value(candy_de.singleton_symbol + condition_expr.substr(1))
			elif condition_expr.begins_with(candy_de.super_node_symbol):
				condition_expr = resolve_value(candy_de.node_symbol + condition_expr.substr(1))
			elif condition_expr.begins_with(candy_de.super_vardict_symbol):
				condition_expr = resolve_value(candy_de.vardict_symbol + condition_expr.substr(1))

			#@ Replace Candy variable references in the condition:
			var expr_line = _replace_with_values(condition_expr)
			expr_line = expr_line.replace("'", "\"")	#/ Make quotes safe for Expression

			#@ Prepare Expression for the condition:
			var expr := Expression.new()
			if expr.parse(expr_line) != OK:
				push_error("§While: failed to parse condition → " + expr_line)
				return "Continue"

			#@ Helper: simulate single-line transition body or execute direct control:
			var run_body := func() -> Variant:
				match result.to_lower():
					"transition":
						match transition_type.to_lower():
							"bridge", "jump":
								var cmd_to_run := "§Bridge" if transition_type.to_lower() == "bridge" else "§Jump"

								var fake_line := [
									{
										cmd_to_run: {
											"Conversation": convo,
											"Block": block,
											"Line": line_ref,
										}
									}
								]

								nesting_depth += 1
								var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
								nesting_depth -= 1
								return feedback

							"return":
								print("[DEBUG] §While → §Return triggered")
								return "Return"

							"end":
								print("[DEBUG] §While → §End triggered")
								end_dialogue()
								return "END"

							_:
								print("[DEBUG] Unknown §While transition type: %s" % transition_type)
								return "Continue"

					"set":
						var lhs_var: String = command_value.get("Variable", "")
						var operator: String = resolve_value(command_value.get("Operator", "="))
						var set_expr_line: String = command_value.get("Expression", "")

						if set_expr_line.is_empty():
							printerr("§Set: empty expression")
							return "Continue"

						if set_expr_line.begins_with(candy_de.super_singleton_symbol):
							set_expr_line = resolve_value(candy_de.singleton_symbol + set_expr_line.substr(1))
						elif set_expr_line.begins_with(candy_de.super_node_symbol):
							set_expr_line = resolve_value(candy_de.node_symbol + set_expr_line.substr(1))
						elif set_expr_line.begins_with(candy_de.super_vardict_symbol):
							set_expr_line = resolve_value(candy_de.vardict_symbol + set_expr_line.substr(1))

						var fake_line := [
							{
								"§Set": {
									"Variable": lhs_var,
									"Operator": operator,
									"Expression": set_expr_line
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Set at depth %d" % nesting_depth)
						return feedback

					"call":
						var func_name: String 		= command_value.get("Function", "")
						var args_raw: Variant 		= command_value.get("Arguments", "")
						var store_var: String		= command_value.get("Variable", "").strip_edges()
						var await_call: Variant 	= resolve_value(command_value.get("Await", true))

						if func_name.begins_with(candy_de.super_singleton_symbol):
							func_name = resolve_value(candy_de.singleton_symbol + func_name.substr(1))
						elif func_name.begins_with(candy_de.super_node_symbol):
							func_name = resolve_value(candy_de.node_symbol + func_name.substr(1))
						elif func_name.begins_with(candy_de.super_vardict_symbol):
							func_name = resolve_value(candy_de.vardict_symbol + func_name.substr(1))

						if typeof(args_raw) == TYPE_STRING:
							if args_raw.begins_with(candy_de.super_singleton_symbol):
								args_raw = resolve_value(candy_de.singleton_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_node_symbol):
								args_raw = resolve_value(candy_de.node_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_vardict_symbol):
								args_raw = resolve_value(candy_de.vardict_symbol + args_raw.substr(1))

						var fake_line := [
							{
								"§Call": {
									"Function": func_name,
									"Arguments": args_raw,
									"Variable": store_var,
									"Await": await_call,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Call at depth %d" % nesting_depth)
						return feedback

					"emit":
						var signal_name: String	= command_value.get("Signal", "")
						var args_raw: Variant 	= command_value.get("Arguments", "")

						#% Validate:
						if signal_name == "":
							return "Continue"

						if signal_name.begins_with(candy_de.super_singleton_symbol):
							signal_name = resolve_value(candy_de.singleton_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_node_symbol):
							signal_name = resolve_value(candy_de.node_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_vardict_symbol):
							signal_name = resolve_value(candy_de.vardict_symbol + signal_name.substr(1))

						if typeof(args_raw) == TYPE_STRING:
							if args_raw.begins_with(candy_de.super_singleton_symbol):
								args_raw = resolve_value(candy_de.singleton_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_node_symbol):
								args_raw = resolve_value(candy_de.node_symbol + args_raw.substr(1))
							elif args_raw.begins_with(candy_de.super_vardict_symbol):
								args_raw = resolve_value(candy_de.vardict_symbol + args_raw.substr(1))

						var fake_line := [
							{
								"§Emit": {
									"Signal": signal_name,
									"Arguments": args_raw
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Emit at depth %d" % nesting_depth)
						return feedback

					"await":
						var signal_name: String = command_value.get("Signal", "")
						var store_var: String   = command_value.get("Variable", "").strip_edges()

						if signal_name == "":
							return "Continue"

						if signal_name.begins_with(candy_de.super_singleton_symbol):
							signal_name = resolve_value(candy_de.singleton_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_node_symbol):
							signal_name = resolve_value(candy_de.node_symbol + signal_name.substr(1))
						elif signal_name.begins_with(candy_de.super_vardict_symbol):
							signal_name = resolve_value(candy_de.vardict_symbol + signal_name.substr(1))

						var fake_line := [
							{
								"§Await": {
									"Signal": signal_name,
									"Variable": store_var,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Await at depth %d" % nesting_depth)
						return feedback

					"flag":
						var flag_name: String		= resolve_value(command_value.get("Flag", "").strip_edges())
						var operator: String		= resolve_value(command_value.get("Operator", "="))
						var flag_expr_line: String	= command_value.get("Expression", "")

						if flag_expr_line.begins_with(candy_de.super_singleton_symbol):
							flag_expr_line = resolve_value(candy_de.singleton_symbol + flag_expr_line.substr(1))
						elif flag_expr_line.begins_with(candy_de.super_node_symbol):
							flag_expr_line = resolve_value(candy_de.node_symbol + flag_expr_line.substr(1))
						elif flag_expr_line.begins_with(candy_de.super_vardict_symbol):
							flag_expr_line = resolve_value(candy_de.vardict_symbol + flag_expr_line.substr(1))

						var fake_line := [
							{
								"§Flag": {
									"Flag": flag_name,
									"Operator": operator,
									"Expression": flag_expr_line,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Flag at depth %d" % nesting_depth)
						return feedback

					"name":
						var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))
						var new_name: String 	= resolve_value(command_value.get("Name", ""))
						var table_raw: String 	= command_value.get("Table", "£candy_de.display_names")
						var key_raw: String 	= resolve_value(command_value.get("Actor_Key", "Display Name"))

						var fake_line := [
							{
								"§Name": {
									"Reference": actor_ref,
									"Name": new_name,
									"Table": table_raw,
									"Actor_Key": key_raw,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Name at depth %d" % nesting_depth)
						return feedback

					"disposition":
						var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))
						var new_disp: String 	= resolve_value(command_value.get("Disposition", ""))

						var fake_line := [
							{
								"§Disposition": {
									"Reference": actor_ref,
									"Disposition": new_disp,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Disposition at depth %d" % nesting_depth)
						return feedback

					"role":
						var role_key: String	= resolve_value(command_value.get("Role", ""))
						var actor_ref: String 	= resolve_value(command_value.get("Reference", ""))

						var fake_line := [
							{
								"§Role": {
									"Role": role_key,
									"Reference": actor_ref,
								}
							}
						]
						nesting_depth += 1
						var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
						nesting_depth -= 1
						print("[DEBUG] Exiting §If Role at depth %d" % nesting_depth)
						return feedback

					_:
						#% Failsafe
						print("[DEBUG] §If condition TRUE but result type '%s' not handled yet." % result)
						return "Continue"

			#@ Loop:
			while true:
				if candy_de.while_safety_break > 0 and safety_counter >= candy_de.while_safety_break:
					push_error("§While: safety break reached (" + str(candy_de.while_safety_break) + " iterations). This limit can be modified or disabled in Candy_Properties.gd.")
					break
				safety_counter += 1

				#% Re-resolve the condition expression each iteration:
				expr_line = _replace_with_values(condition_expr)
				expr_line = expr_line.replace("'", "\"")

				expr = Expression.new()
				if expr.parse(expr_line) != OK:
					push_error("§While: failed to parse condition → " + expr_line)
					break

				var cond_val = expr.execute()
				if expr.has_execute_failed() or not bool(cond_val):
					break

				var feedback = await run_body.call()
				if feedback == "END":
					return "END"
				elif feedback == "Return":
					return "Return"

			return "Continue"
		#endregion - condition commands


		#&########################################
		#&										##
		#&         TRANSITION COMMANDS          ##
		#&										##
		#region - Flow Commands
		#* §LM - Line Marker for transitions:
		"§lm":
			return "Continue"


		#* §Jump - switch to another block/conversation at a line reference:
		"§jump":
			killswitch = true

			var new_conversation: String 	= resolve_value(str(command_value.get("Conversation", "")))
			var new_block: String 			= resolve_value(str(command_value.get("Block", "")))
			var line_ref: Variant 			= resolve_value(command_value.get("Line", 0))

			#@ Step 1 - Fallbacks for empty conversation or block:
			if new_conversation.strip_edges() == "":
				new_conversation = current_conversation
			if new_block.strip_edges() == "":
				new_block = current_block

			#@ Step 2 - Resolve variable references:
			if new_conversation.begins_with(candy_de.singleton_symbol) or new_conversation.begins_with(candy_de.node_symbol) or new_conversation.begins_with(candy_de.vardict_symbol):
				var decoded_conv = decode_variable_name(new_conversation)
				var resolved_conv = get_variable_value(decoded_conv)
				if resolved_conv != null:
					new_conversation = str(resolved_conv)

			if new_block.begins_with(candy_de.singleton_symbol) or new_block.begins_with(candy_de.node_symbol) or new_block.begins_with(candy_de.vardict_symbol):
				var decoded_block = decode_variable_name(new_block)
				var resolved_block = get_variable_value(decoded_block)
				if resolved_block != null:
					new_block = str(resolved_block)

			if typeof(line_ref) == TYPE_STRING:
				if line_ref.begins_with(candy_de.singleton_symbol) or line_ref.begins_with(candy_de.node_symbol) or line_ref.begins_with(candy_de.vardict_symbol):
					var decoded_line = decode_variable_name(line_ref)
					var resolved_line = get_variable_value(decoded_line)
					if resolved_line != null:
						line_ref = resolved_line

			#@ Step 3 - Convert numeric strings to integers:
			if typeof(line_ref) == TYPE_STRING:
				if line_ref.is_valid_int():
					line_ref = int(line_ref)

			#@ Step 4 - Resolve target line (number or §LM tag):
			var target_line: int = 0
			if line_ref == "":
				line_ref = 0
			if typeof(line_ref) == TYPE_INT:

				target_line = line_ref
			elif typeof(line_ref) == TYPE_STRING:
				var text_array = running_dialogue[new_conversation][new_block]["Text"]
				for i in text_array.size():
					var ld = text_array[i]
					if ld.has("§LM") and str(ld["§LM"]["Reference"]) == line_ref:
						target_line = i
						break

			#@ Step 5 - Run the target Block like new dialogue:
			#% Cleanup:
			nesting_depth = 0
			choice_lists.clear()
			choice_list_data.clear()
			var input_elements_path = get_node_or_null(ui_elements_paths["input_node_path"])
			if input_elements_path:
				for child in input_elements_path.get_children():
					child.queue_free()
			await get_tree().process_frame

			#% Disable greenlight:
			greenlight = false

			#% Jump:
			jump_start_dialogue(new_conversation, new_block, target_line)
			print("§Jump: returning 'END'")
			return "END"


		#* §Bridge - bridge to another block/conversation at a line reference (don’t kill ongoing RSDs):
		"§bridge":
			var new_conversation: String 	= resolve_value(str(command_value.get("Conversation", "")))
			var new_block: String 			= resolve_value(str(command_value.get("Block", "")))
			var line_ref: Variant 			= resolve_value(command_value.get("Line", 0))

			#@ Step 1 - Fallback to current conversation or block:
			if new_conversation.strip_edges() == "":
				new_conversation = current_conversation
			if new_block.strip_edges() == "":
				new_block = current_block

			#@ Step 2 - Resolve variable references:
			if new_conversation.begins_with(candy_de.singleton_symbol) or new_conversation.begins_with(candy_de.node_symbol) or new_conversation.begins_with(candy_de.vardict_symbol):
				var decoded_conv = decode_variable_name(new_conversation)
				var resolved_conv = get_variable_value(decoded_conv)
				if resolved_conv != null:
					new_conversation = str(resolved_conv)

			if new_block.begins_with(candy_de.singleton_symbol) or new_block.begins_with(candy_de.node_symbol) or new_block.begins_with(candy_de.vardict_symbol):
				var decoded_block = decode_variable_name(new_block)
				var resolved_block = get_variable_value(decoded_block)
				if resolved_block != null:
					new_block = str(resolved_block)

			if typeof(line_ref) == TYPE_STRING:
				if line_ref.begins_with(candy_de.singleton_symbol) or line_ref.begins_with(candy_de.node_symbol) or line_ref.begins_with(candy_de.vardict_symbol):
					var decoded_line = decode_variable_name(line_ref)
					var resolved_line = get_variable_value(decoded_line)
					if resolved_line != null:
						line_ref = resolved_line

			#@ Step 3 - Convert numeric strings to integers:
			if typeof(line_ref) == TYPE_STRING:
				if line_ref.is_valid_int():
					line_ref = int(line_ref)

			#@ Step 4 - Resolve target line (index or §LM tag):
			var target_line: int = 0
			if typeof(line_ref) == TYPE_STRING and line_ref == "":
				line_ref = 0
			if typeof(line_ref) == TYPE_INT:
				target_line = line_ref
			elif typeof(line_ref) == TYPE_STRING:
				var text_array = running_dialogue[new_conversation][new_block]["Text"]
				for i in text_array.size():
					var ld = text_array[i]
					if ld.has("§LM") and str(ld["§LM"]["Reference"]) == line_ref:
						target_line = i
						break

			#@ Step 5 - Run the new Block:
			nesting_depth += 1
			print(target_line)
			await run_dialogue(new_conversation, new_block, target_line, "Text", false)
			nesting_depth -= 1

			#@ Step 6 - Reactivate the current depth's choice menu if exists:
			if choice_lists.has(str(nesting_depth)):
				var previous_menu = choice_lists[str(nesting_depth)]["Menu"]
				previous_menu.reactivate()

			return "Continue"


		#* §Return - End the Block prematurely and return to the previous block (if bridged):
		"§return":
			return "Return"


		#* §End - End the dialogue:
		"§end":
			end_dialogue()
			return "END"
		#endregion - flow commands


		#&########################################
		#&										##
		#&            INPUT COMMANDS            ##
		#&										##
		#region - Input Commands
		#* §Mouse - change mouse mode:
		"§mouse":
			var mode: String 	= resolve_value(str(command_value.get("Mouse Mode", "")))

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

			return "Continue"


		#* §Input - advanced player input (always blocking, multi-line):
		"§input":
			var input_ui: String			= resolve_value(str(command_value.get("File", "")))
			var input_variable: String		= str(command_value.get("Variable", ""))
			var setup_mode: String			= str(command_value.get("Mode", ""))
			var input_instructions: String	= str(command_value.get("Instructions", ""))
			var input_placeholder: String	= str(command_value.get("Placeholder", ""))
			var input_default_text: String	= str(command_value.get("Text", ""))

			#@ Step 1 - Resolve super variables:
			if input_variable.begins_with(candy_de.super_singleton_symbol):
				input_variable = resolve_value(candy_de.singleton_symbol + input_variable.substr(1))
			elif input_variable.begins_with(candy_de.super_node_symbol):
				input_variable = resolve_value(candy_de.node_symbol + input_variable.substr(1))
			elif input_variable.begins_with(candy_de.super_vardict_symbol):
				input_variable = resolve_value(candy_de.vardict_symbol + input_variable.substr(1))

			if setup_mode.begins_with(candy_de.super_singleton_symbol):
				setup_mode = resolve_value(candy_de.singleton_symbol + setup_mode.substr(1))
			elif setup_mode.begins_with(candy_de.super_node_symbol):
				setup_mode = resolve_value(candy_de.node_symbol + setup_mode.substr(1))
			elif setup_mode.begins_with(candy_de.super_vardict_symbol):
				setup_mode = resolve_value(candy_de.vardict_symbol + setup_mode.substr(1))

			if input_instructions.begins_with(candy_de.super_singleton_symbol):
				input_instructions = resolve_value(candy_de.singleton_symbol + input_instructions.substr(1))
			elif input_instructions.begins_with(candy_de.super_node_symbol):
				input_instructions = resolve_value(candy_de.node_symbol + input_instructions.substr(1))
			elif input_instructions.begins_with(candy_de.super_vardict_symbol):
				input_instructions = resolve_value(candy_de.vardict_symbol + input_instructions.substr(1))

			if input_placeholder.begins_with(candy_de.super_singleton_symbol):
				input_placeholder = resolve_value(candy_de.singleton_symbol + input_placeholder.substr(1))
			elif input_placeholder.begins_with(candy_de.super_node_symbol):
				input_placeholder = resolve_value(candy_de.node_symbol + input_placeholder.substr(1))
			elif input_placeholder.begins_with(candy_de.super_vardict_symbol):
				input_placeholder = resolve_value(candy_de.vardict_symbol + input_placeholder.substr(1))

			if input_default_text.begins_with(candy_de.super_singleton_symbol):
				input_default_text = resolve_value(candy_de.singleton_symbol + input_default_text.substr(1))
			elif input_default_text.begins_with(candy_de.super_node_symbol):
				input_default_text = resolve_value(candy_de.node_symbol + input_default_text.substr(1))
			elif input_default_text.begins_with(candy_de.super_vardict_symbol):
				input_default_text = resolve_value(candy_de.vardict_symbol + input_default_text.substr(1))

			#@ Step 2 - Configure instance name for consistency:
			if not input_ui.ends_with(".tscn"):
				input_ui += ".tscn"

			var input_ui_name: String = input_ui.trim_suffix(".tscn")	#/ Scene name minus '.tscn'

			#@ Step 3 - Store command depth:
			var this_depth = nesting_depth

			#@ Step 4 - Resolve or instantiate input menu:
			var input_parent := get_node(ui_elements_paths["input_node_path"])
			var input_instance: Node = null

			#@ Step 5 - Reuse existing node if present:
			if input_parent.has_node(input_ui_name):
				input_instance = input_parent.get_node(input_ui_name)

			#@ Step 6 - Instantiate input menu from scene if menu not present:
			else:
				var input_scene: PackedScene = load(candy_de.input_menus_folder.path_join(input_ui))
				input_instance = input_scene.instantiate()
				input_instance.name = input_ui_name		#/ Name the instance the same as scene file, minus '.tscn'
				input_instance.caller = self
				input_instance.depth = this_depth
				input_parent.add_child(input_instance)

			#@ Step 7 - Setup input menu:
			if input_instance.has_method("setup"):
				input_instance.setup(input_variable, setup_mode, input_instructions, input_placeholder, input_default_text)
			else:
				push_warning("[NOTICE] §Input: setup() function missing in Input UI script.")

			#@ Step 8 - Wait for input_received events until "finish":
			var sig
			while true:
				sig = await input_received

				#% Ensure depth matches:
				if sig[0] != this_depth:
					continue

				var event_type: String = str(sig[1]).to_lower()
				var parameters = sig[2] if sig.size() >= 3 else {}

				match event_type:
					"finish":
						print("[DEBUG] §Input (Depth %s): Event: %s (%s)." % [str(this_depth), event_type, parameters])
						break

					_:
						print("[DEBUG] §Input (Depth %s): Unknown event: %s (%s)." % [str(this_depth), event_type, parameters])
						break

			#@ Step 9 - Return mouse_mode to default for dialogues:
			if mouse_mode_start != MouseModes.None:
				Input.set_mouse_mode(mouse_mode_start as Input.MouseMode)

			return "Continue"
 		#endregion - input commands


		#&########################################
		#&										##
		#&           CHOICE COMMANDS            ##
		#&										##
		#region - Choice Commands
		#* §Choice List - Display a list of choices:
		"§choice_list":
			var this_depth = nesting_depth
			choice_list_data[this_depth] = command_value.duplicate(true)

			#@ Step 0 - Visibility:
			#% Make choice menu parent container visible as precaution:
			get_node(ui_elements_paths["choices_path"]).visible = true

			#% Hide older menus (if any):
			if hide_choice_lists == true:
				for child in get_node(ui_elements_paths["choices_path"]).get_children():
					if child.never_hide == false:
						child.deactivate()

			#@ Step 1 - Run general Setup transition:
			var setup_dict: Dictionary = choice_list_data[this_depth].get("Setup", {})
			if not setup_dict.is_empty():
				var convo: String = resolve_value(setup_dict.get("Conversation", "")).strip_edges()
				var block: String = resolve_value(setup_dict.get("Block", "")).strip_edges()
				var line_ref: String = resolve_value(setup_dict.get("Line", "")).strip_edges()
				var trans_type: String = resolve_value(setup_dict.get("Type", "Bridge")).to_lower()

				if not (convo == "" and block == "" and line_ref == ""):
					match trans_type:
						"bridge":
							var cmd_to_run := "§Bridge"
							var fake_line := [ { cmd_to_run: { "Conversation": convo, "Block": block, "Line": line_ref } } ]
							nesting_depth += 1
							var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
							nesting_depth -= 1
							if feedback in ["END", "Return"]:
								return feedback
						_:
							print("[DEBUG] Unknown transition type in §Choice_List.Setup: %s" % trans_type)

			#@ Step 2 - Run category Setup transitions:
			var categories_array: Array = choice_list_data[this_depth].get("Categories", [])

			for category_entry in categories_array:
				for cat_key in category_entry.keys():
					var cat_data: Dictionary = category_entry[cat_key]
					var cat_setup: Dictionary = cat_data.get("Setup", {})
					if cat_setup.is_empty():
						continue

					var convo: String = resolve_value(cat_setup.get("Conversation", "")).strip_edges()
					var block: String = resolve_value(cat_setup.get("Block", "")).strip_edges()
					var line_ref: String = resolve_value(cat_setup.get("Line", "")).strip_edges()
					var trans_type: String = resolve_value(cat_setup.get("Type", "Bridge")).to_lower()

					if convo == "" and block == "" and line_ref == "":
						continue

					match trans_type:
						"bridge":
							var cmd_to_run := "§Bridge"
							var fake_line := [
								{
									cmd_to_run: {
										"Conversation": convo,
										"Block": block,
										"Line": line_ref,
									}
								}
							]
							nesting_depth += 1
							var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
							nesting_depth -= 1
							if feedback in ["END", "Return"]:
								return feedback
						_:
							print("[DEBUG] Unknown transition type in §Choice_List.Category.Setup: %s" % trans_type)

			#@ Step 3 - Run choice Setup transitions:
			categories_array = choice_list_data[this_depth].get("Categories", [])

			for category_entry in categories_array:

				for cat_key in category_entry.keys():

					var cat_data: Dictionary = category_entry[cat_key]
					if not cat_data.has("Choices"):
						continue

					var choices_array: Array = cat_data.get("Choices", [])

					for choice_entry in choices_array:

						for choice_key in choice_entry.keys():

							var choice_data: Dictionary = choice_entry[choice_key]
							var choice_setup: Dictionary = choice_data.get("Setup", {})

							if choice_setup.is_empty():
								continue

							var convo: String = resolve_value(choice_setup.get("Conversation", "")).strip_edges()
							var block: String = resolve_value(choice_setup.get("Block", "")).strip_edges()
							var line_ref: String = resolve_value(choice_setup.get("Line", "")).strip_edges()
							var trans_type: String = resolve_value(choice_setup.get("Type", "Bridge")).to_lower()

							if convo == "" and block == "" and line_ref == "":
								continue

							match trans_type:
								"bridge":
									var cmd_to_run := "§Bridge"
									var fake_line := [
										{
											cmd_to_run: {
												"Conversation": convo,
												"Block": block,
												"Line": line_ref,
											}
										}
									]

									nesting_depth += 1
									var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
									nesting_depth -= 1

									if feedback in ["END", "Return"]:
										return feedback

								_:
									print("[DEBUG] Unknown transition type in §Choice_List.Choice.Setup: %s" % trans_type)

			#@ Step 4 - Run timer Setup transitions:
			for timer_entry in choice_list_data[this_depth].get("Timers", []):
				#% Each timer_entry is a one-key dictionary: { "Timer_1": {...} }
				for timer_key in timer_entry.keys():
					var timer_data: Dictionary = timer_entry[timer_key]
					if timer_data.is_empty():
						continue

					var timer_setup: Dictionary = timer_data.get("Setup", {})
					if timer_setup.is_empty():
						continue

					var convo: String = resolve_value(timer_setup.get("Conversation", "")).strip_edges()
					var block: String = resolve_value(timer_setup.get("Block", "")).strip_edges()
					var line_ref: String = resolve_value(timer_setup.get("Line", "")).strip_edges()
					var trans_type: String = resolve_value(timer_setup.get("Type", "Bridge")).to_lower()

					#% Skip timers with no valid transition:
					if convo == "" and block == "" and line_ref == "":
						continue

					match trans_type:
						"bridge":
							#% Perform timer setup transition via §Bridge:
							var cmd_to_run := "§Bridge"
							var fake_line := [
								{
									cmd_to_run: {
										"Conversation": convo,
										"Block": block,
										"Line": line_ref,
									}
								}
							]

							nesting_depth += 1
							var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
							nesting_depth -= 1

							if feedback in ["END", "Return"]:
								return feedback

							print("[DEBUG] §Choice_List: Timer '%s' executed Setup transition (%s → %s:%s)."
								% [timer_key, trans_type, convo, block])

						_:
							print("[DEBUG] §Choice_List: Unknown transition type '%s' in Timer '%s'."
								% [trans_type, timer_key])
							continue

			#@ Step 5 - Create root menu scene for this command:
			var parent_node = get_node(ui_elements_paths["choices_path"])

			#% Get menu scene name from command data:
			var menu_scene: String = resolve_value(choice_list_data[this_depth].get("Menu Scene", "Default.tscn")).strip_edges()
			if menu_scene == "":
				menu_scene = "Default.tscn"
				print("§Choice_List: Missing 'Menu Scene', defaulting to 'Default.tscn'.")

			if not menu_scene.ends_with(".tscn"):
				menu_scene += ".tscn"
			var full_menu_path: String = candy_de.choice_menus_folder.path_join(menu_scene)

			if not ResourceLoader.exists(full_menu_path):
				printerr("§Choice_List: Invalid or missing menu scene → %s" % full_menu_path)
				return "Continue"

			var menu_scene_res: PackedScene = load(full_menu_path)
			if menu_scene_res == null:
				printerr("§Choice_List: Failed to load menu scene at → %s" % full_menu_path)
				return "Continue"

			var menu_node = menu_scene_res.instantiate()
			menu_node.caller = self
			menu_node.nesting_depth = nesting_depth

			#% Hide previous nested choice menus (if any):
			for child in parent_node.get_children():
				child.visible = false

			#% Add new menu to container:
			parent_node.add_child(menu_node)
			print("[DEBUG] §Choice_List: Loaded main menu scene '%s' from '%s'" % [menu_scene, full_menu_path])

			#% Resolve and store metadata fields:
			var menu_title: String		= resolve_value(choice_list_data[this_depth].get("Title", "")).strip_edges()
			var menu_tags: String		= resolve_value(choice_list_data[this_depth].get("Tags", "")).strip_edges()
			var menu_prompt: String		= resolve_value(choice_list_data[this_depth].get("Prompt", "")).strip_edges()
			var menu_custom: String		= resolve_value(choice_list_data[this_depth].get("Custom", "")).strip_edges()

			menu_node.title = menu_title
			menu_node.tags = menu_tags
			menu_node.prompt = menu_prompt
			menu_node.custom = menu_custom

			#% Record this menu node, title, and tags in choice_lists for this depth:
			if not choice_lists.has(nesting_depth):
				choice_lists[nesting_depth] = {}

			choice_lists[nesting_depth]["Menu"] = menu_node
			choice_lists[nesting_depth]["Title"] = menu_title
			choice_lists[nesting_depth]["Tags"] = menu_tags

			print("[DEBUG] §Choice_List: Registered menu (Title='%s', Tags='%s') for depth %s"
				% [menu_title, menu_tags, str(nesting_depth)])

			#@ Step 6 - Instantiate one category scene per category:
			var main_category = resolve_value(choice_list_data[this_depth].get("Main", "")).strip_edges()
			var general_category_scene: String = resolve_value(choice_list_data[this_depth].get("Category Scene", "Default.tscn")).strip_edges()
			if general_category_scene == "":
				general_category_scene = "Default.tscn"

			elif general_category_scene != "":
				if not general_category_scene.ends_with(".tscn"):
					general_category_scene += ".tscn"
			general_category_scene = candy_de.choice_categories_folder.path_join(general_category_scene)

			var category_list: Node = menu_node.get_node_or_null("Categories")
			if category_list == null:
				print("§Choice_List: Menu scene is missing a 'Categories' node.")
				return "Continue"

			#% Ensure category dictionary exists in choice_lists for this depth:
			if not choice_lists.has(nesting_depth):
				choice_lists[nesting_depth] = {}
			if not choice_lists[nesting_depth].has("Category Nodes"):
				choice_lists[nesting_depth]["Category Nodes"] = {}

			#% Always re-fetch live category data each iteration:
			categories_array = choice_list_data[this_depth].get("Categories", [])

			for category_entry in categories_array:
				for cat_key in category_entry.keys():
					var cat_data: Dictionary = category_entry[cat_key]
					var cat_scene_name: String = resolve_value(cat_data.get("Category Scene", "")).strip_edges()

					if cat_scene_name == "":
						cat_scene_name = general_category_scene
					else:
						if not cat_scene_name.ends_with(".tscn"):
							cat_scene_name += ".tscn"
						cat_scene_name = candy_de.choice_categories_folder.path_join(cat_scene_name)

					if cat_scene_name == "" or not ResourceLoader.exists(cat_scene_name):
						printerr("§Choice_List: Invalid category scene → %s" % cat_scene_name)
						continue

					var cat_scene: PackedScene = load(cat_scene_name)
					if cat_scene == null:
						printerr("§Choice_List: Failed to load category scene → %s" % cat_scene_name)
						continue

					var category_instance = cat_scene.instantiate()

					var cat_tags: String = resolve_value(cat_data.get("Tags", "")).strip_edges()

					category_instance.parent_menu = menu_node
					category_instance.caller = self

					category_instance.general_custom = resolve_value(choice_list_data[this_depth].get("Custom", ""))
					category_instance.category_custom = resolve_value(cat_data.get("Custom", ""))
					category_instance.general_title = resolve_value(choice_list_data[this_depth].get("Title", ""))
					category_instance.category_title = resolve_value(cat_data.get("Title", ""))
					category_instance.general_prompt = resolve_value(choice_list_data[this_depth].get("Prompt", ""))
					category_instance.category_prompt = resolve_value(cat_data.get("Prompt", ""))
					category_instance.tags = cat_tags

					category_instance.name = cat_key

					category_list.add_child(category_instance)

					if cat_key != main_category:
						category_instance.visible = false

					#% Record reference and tags:
					choice_lists[nesting_depth]["Category Nodes"][cat_key] = {
						"Node": category_instance,
						"Tags": cat_tags
					}

					print("[DEBUG] §Choice_List: Spawned category '%s' (Tags='%s') under menu (depth %s)"
						% [cat_key, cat_tags, str(nesting_depth)])

			#@ Step 7 - Spawn one button per enabled choice:
			var general_button_scene: String = resolve_value(choice_list_data[this_depth].get("Button Scene", "Default.tscn")).strip_edges()
			if general_button_scene == "":
				general_button_scene = "Default.tscn"
			else:
				if not general_button_scene.ends_with(".tscn"):
					general_button_scene += ".tscn"
			general_button_scene = candy_de.choice_buttons_folder.path_join(general_button_scene)

			#% Always re-fetch live categories before iterating:
			categories_array = choice_list_data[this_depth].get("Categories", [])

			for category_entry in categories_array:
				for cat_key in category_entry.keys():
					var cat_data: Dictionary = category_entry[cat_key]
					var category_instance = menu_node.category_list.get_node_or_null(cat_key)
					var button_list = category_instance.button_list
					if category_instance == null:
						continue

					var category_button_scene: String = resolve_value(cat_data.get("Button Scene", "")).strip_edges()
					if category_button_scene == "":
						category_button_scene = general_button_scene
					else:
						if not category_button_scene.ends_with(".tscn"):
							category_button_scene += ".tscn"
						category_button_scene = candy_de.choice_buttons_folder.path_join(category_button_scene)

					if not cat_data.has("Choices"):
						continue

					var choices_array: Array = cat_data.get("Choices", [])
					for choice_entry in choices_array:
						for choice_key in choice_entry.keys():
							var choice_data: Dictionary = choice_entry[choice_key]

							#% Don't create button if choice is disabled:
							if int(resolve_value(choice_data.get("Enabled", "1"))) == 0:
								continue

							var choice_scene_name: String = resolve_value(choice_data.get("Button Scene", "")).strip_edges()
							var final_scene_path: String = ""
							if choice_scene_name == "":
								final_scene_path = category_button_scene
							else:
								if not choice_scene_name.ends_with(".tscn"):
									choice_scene_name += ".tscn"
								final_scene_path = candy_de.choice_buttons_folder.path_join(choice_scene_name)

							if final_scene_path == "":
								final_scene_path = category_button_scene

							if final_scene_path == "" or not ResourceLoader.exists(final_scene_path):
								printerr("§Choice_List: Invalid button scene for choice '%s' in category '%s' → %s"
									% [choice_key, cat_key, final_scene_path])
								continue

							var scene_res: PackedScene = load(final_scene_path)
							if scene_res == null:
								printerr("§Choice_List: Failed to load button scene at → %s" % final_scene_path)
								continue

							var button_instance = scene_res.instantiate()
							button_instance.name = choice_key
							button_instance.parent_category = category_instance
							button_instance.parent_menu = menu_node
							button_instance.caller = self
							button_instance.choice_name = choice_key
							button_instance.category_name = cat_key

							var choice_label = resolve_value(choice_data.get("Label", ""))
							if choice_label == "":
								choice_label = choice_key
							button_instance.label = choice_label
							button_instance.tooltip = resolve_value(choice_data.get("Tooltip", ""))
							button_instance.general_custom = resolve_value(choice_list_data[this_depth].get("Custom", ""))
							button_instance.category_custom = resolve_value(cat_data.get("Custom", ""))
							button_instance.choice_custom = resolve_value(choice_data.get("Custom", ""))
							button_instance.tags = resolve_value(choice_data.get("Tags", "")).strip_edges()

							button_instance.choice_enabled = int(resolve_value(choice_data.get("Enabled", "1")))
							button_instance.choice_active = int(resolve_value(choice_data.get("Active", "1")))
							button_instance.choice_invisible = int(resolve_value(choice_data.get("Invisible", "1")))

							button_list.add_child(button_instance)
							button_instance.setup()
							print("[DEBUG] §Choice_List: Spawned button '%s' under category '%s' using '%s'"
								% [choice_key, cat_key, final_scene_path])

			#@ Step 8 - Set Mouse_Mode for the main category:
			var general_mouse_mode: String = resolve_value(choice_list_data[this_depth].get("Mouse", "Default")).strip_edges()

			#% Re-fetch main category data live from the array of dictionaries:
			var main_cat_data: Dictionary = {}
			categories_array = choice_list_data[this_depth].get("Categories", [])
			for category_entry in categories_array:
				for cat_key in category_entry.keys():
					if cat_key == main_category:
						main_cat_data = category_entry[cat_key]
						break
				if not main_cat_data.size() > 0:
					continue

			var cat_mouse_mode: String = resolve_value(main_cat_data.get("Mouse", "Default")).strip_edges()

			var final_mouse_mode: String = cat_mouse_mode
			if final_mouse_mode == "Default":
				final_mouse_mode = general_mouse_mode

			#% Apply to engine mouse mode:
			match final_mouse_mode.to_lower():
				"default", "visible":
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					print("[DEBUG] §Choice_List: Mouse_Mode set to Visible (Default).")
				"hidden":
					Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
					print("[DEBUG] §Choice_List: Mouse_Mode set to Hidden.")
				"captured", "locked":
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					print("[DEBUG] §Choice_List: Mouse_Mode set to Captured (Locked).")
				"confined":
					Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
					print("[DEBUG] §Choice_List: Mouse_Mode set to Confined.")
				"confined_hidden":
					Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
					print("[DEBUG] §Choice_List: Mouse_Mode set to Confined Hidden.")
				_:
					print("[DEBUG] §Choice_List: Unknown Mouse_Mode '%s'; keeping current mode." % final_mouse_mode)

			print("[DEBUG] §Choice_List: Mouse_Mode directive resolved as '%s' (main category '%s')."
				% [final_mouse_mode, main_category])

			#@ Step 9 - Create Timers:
			var timers_array: Array = choice_list_data[this_depth].get("Timers", [])
			if timers_array.is_empty():
				print("[DEBUG] §Choice_List: No timers found at depth %s." % str(this_depth))
			else:
				print("[DEBUG] §Choice_List: Initializing %d timer(s) at depth %s."
					% [timers_array.size(), str(this_depth)])

			for timer_entry in timers_array:
				#% Each timer_entry is a single-key dictionary → { "Timer_1": {...} }
				for timer_key in timer_entry.keys():
					var timer_data: Dictionary = timer_entry[timer_key]
					if timer_data.is_empty():
						continue

					#% Resolve timer parameters:
					var time_val: float = float(resolve_value(timer_data.get("Time", "0")))
					var auto_mode: String = resolve_value(timer_data.get("Auto", "Start")).strip_edges()
					var loop_val: int = int(resolve_value(timer_data.get("Loop", "0")))
					var tags: String = resolve_value(timer_data.get("Tags", "")).strip_edges()

					#% Add or reset Status field in the command data:
					timer_data["Status"] = "Hold"

					#% Create a Timer node dynamically inside the menu scene:
					var timer_node: Timer = Timer.new()
					timer_node.name = timer_key
					timer_node.wait_time = time_val
					timer_node.one_shot = true
					timer_node.autostart = false
					menu_node.timer_list.add_child(timer_node)

					#% Connect timeout → _on_timer_timeout(timer_name) in menu script:
					timer_node.timeout.connect(
						func(key = timer_key):
							if menu_node.has_method("_on_timer_timeout"):
								menu_node._on_timer_timeout(key)
							else:
								printerr("§Choice_List: Menu missing _on_timer_timeout() while running timer '%s'." % timer_key)
					)

					#% Start timer automatically if Auto = "Start":
					if auto_mode == "Start":
						timer_node.start()
						timer_data["Status"] = "Run"
						print("[DEBUG] §Choice_List: Started timer '%s' (time=%.2f, loop=%s, tags='%s')."
							% [timer_key, time_val, str(loop_val), tags])
					else:
						print("[DEBUG] §Choice_List: Created timer '%s' (Auto=Hold, time=%.2f, loop=%s, tags='%s')."
							% [timer_key, time_val, str(loop_val), tags])

			print("[DEBUG] §Choice_List: Finished initializing timers for depth %s." % str(this_depth))

			#@ Step 10 - Run custom logic:
			#. Hook call:
			if menu_node.has_method("x_initialization_finished"):
				await menu_node.x_initialization_finished()

			#@ Step 11 - Wait choice_list_event signal:
			var sig
			while true:
				sig = await choice_list_event

				#% Process only events from this depth:
				if sig[0] != this_depth:
					continue

				var event_type: String = str(sig[1]).to_lower()

				match event_type:
					"choice":
						var category_name: String = sig[2]
						var choice_name: String = sig[3]
						var source_ref = sig[4]

						if source_ref.choice_active == 0:
							print("[DEBUG] §Choice_List: Ignored inactive choice '%s' (category '%s')."
								% [choice_name, category_name])
							continue

						#@ Step 11-A - Pause all active timers during choice processing:
						timers_array = choice_list_data[this_depth].get("Timers", [])
						for timer_entry in timers_array:
							for timer_key in timer_entry.keys():
								var t_data: Dictionary = timer_entry[timer_key]
								if t_data.get("Status", "") == "Run":
									var t_node: Timer = menu_node.timer_list.get_node_or_null(timer_key)
									if t_node:
										t_node.set_paused(true)
										t_data["Status"] = "Signal Pause"
										print("[DEBUG] §Choice_List: Timer '%s' paused (Signal Pause)." % timer_key)

						#% Record event:
						choice_lists[this_depth]["Last Choice"] = { "Choice": [category_name, choice_name, source_ref] }
						print("[DEBUG] §Choice_List: Registered selection '%s' in category '%s' (depth %s)"
							% [choice_name, category_name, str(this_depth)])

						#% Always re-fetch live data before resolving choice:
						categories_array = choice_list_data[this_depth].get("Categories", [])
						var cat_data: Dictionary = {}
						for entry in categories_array:
							if entry.has(category_name):
								cat_data = entry[category_name]
								break

						if cat_data.size() == 0:
							printerr("§Choice_List: Missing data for category '%s'." % category_name)
							return "Continue"

						#% Find the choice inside this category:
						var choice_data: Dictionary = {}
						if cat_data.has("Choices"):
							for choice_entry in cat_data["Choices"]:
								if choice_entry.has(choice_name):
									choice_data = choice_entry[choice_name]
									break

						if choice_data.size() == 0:
							printerr("§Choice_List: Missing data for selected choice '%s' (category '%s')."
								% [choice_name, category_name])
							return "Continue"

						#% Re-fetch Finish data live as well:
						var finish_data: Dictionary = {}
						if cat_data.has("Choices"):
							for choice_entry in cat_data["Choices"]:
								if choice_entry.has(choice_name):
									finish_data = choice_entry[choice_name].get("Finish", {})
									break

						var convo: String = resolve_value(finish_data.get("Conversation", "")).strip_edges()
						var block: String = resolve_value(finish_data.get("Block", "")).strip_edges()
						var line_ref: String = resolve_value(finish_data.get("Line", "")).strip_edges()

						#% Navigation:
						var nav_target: String = resolve_value(choice_data.get("Navigate", "")).strip_edges()
						if nav_target != "":
							var cat_dict = choice_lists.get(this_depth, {}).get("Category Nodes", {})
							if cat_dict.has(category_name):
								var current_cat = cat_dict[category_name]
								if current_cat:
									current_cat["Node"].visible = false
							if cat_dict.has(nav_target):
								var target_cat = cat_dict[nav_target]
								if target_cat:
									target_cat["Node"].visible = true
							print("[DEBUG] §Choice_List: Navigated from '%s' → '%s'." %
								[category_name, nav_target])

						#% If navigation only (no finish transition), resume timers immediately:
						if nav_target != "" and convo == "" and block == "" and line_ref == "":
							for timer_entry in timers_array:
								for timer_key in timer_entry.keys():
									var t_data: Dictionary = timer_entry[timer_key]
									if t_data.get("Status", "") == "Signal Pause":
										var t_node: Timer = menu_node.timer_list.get_node_or_null(timer_key)
										if t_node:
											if t_data.has("Pending Restart"):
												t_node.set_paused(false)
												t_node.wait_time = float(t_data["Pending Restart"])
												t_node.start()
												t_data.erase("Pending Restart")
												print("[DEBUG] §Choice_List: Timer '%s' restarted with new time (%.2fs) after navigation." % [timer_key, t_node.wait_time])
											else:
												t_node.set_paused(false)
											t_data["Status"] = "Run"
											print("[DEBUG] §Choice_List: Timer '%s' resumed after navigation." % timer_key)

						#% Finish transition:
						if convo != "" or block != "" or line_ref != "":
							var trans_type: String = resolve_value(finish_data.get("Type", "Bridge")).to_lower()

							match trans_type:
								"continue":
									var cmd_to_run := "§Bridge"
									var fake_line := [
										{ cmd_to_run: { "Conversation": convo, "Block": block, "Line": line_ref } }
									]
									nesting_depth += 1
									var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
									nesting_depth -= 1
									if feedback in ["END", "Return"]:
										return feedback

									#% Resume timers after choice if menu remains open:
									for timer_entry in timers_array:
										for timer_key in timer_entry.keys():
											var t_data: Dictionary = timer_entry[timer_key]
											if t_data.get("Status", "") == "Signal Pause":
												var t_node: Timer = menu_node.timer_list.get_node_or_null(timer_key)
												if t_node:
													if t_data.has("Pending Restart"):
														t_node.set_paused(false)
														t_node.wait_time = float(t_data["Pending Restart"])
														t_node.start()
														t_data.erase("Pending Restart")
														print("[DEBUG] §Choice_List: Timer '%s' restarted with new time (%.2fs) after Continue." % [timer_key, t_node.wait_time])
													else:
														t_node.set_paused(false)
													t_data["Status"] = "Run"
													print("[DEBUG] §Choice_List: Timer '%s' resumed after Continue." % timer_key)
									continue

								"bridge", "jump", "return", "end":
									var cmd_to_run := "§Bridge" if trans_type == "bridge" else (
										"§Jump" if trans_type == "jump" else (
										"§Return" if trans_type == "return" else "§End"))
									var fake_line := [
										{ cmd_to_run: { "Conversation": convo, "Block": block, "Line": line_ref } }
									]

									menu_node.visible = false

									nesting_depth += 1
									var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
									nesting_depth -= 1

									#% Clean up choice_lists for current and higher depths:
									for d in choice_lists.keys():
										if int(d) >= this_depth:
											choice_lists.erase(d)

									menu_node.queue_free()
									print("[DEBUG] §Choice_List: Closed menu after '%s' transition and cleared data (depth ≥ %s)." %
										[trans_type, str(this_depth)])

									return feedback

								"close":
									for d in choice_lists.keys():
										if int(d) >= this_depth:
											choice_lists.erase(d)
									menu_node.queue_free()
									print("[DEBUG] §Choice_List: Closed menu after 'Close' directive; cleared data (depth ≥ %s)." %
										str(this_depth))
									return "Continue"

								_:
									print("[DEBUG] Unknown Finish transition type '%s' in choice '%s' (category '%s')."
										% [trans_type, choice_name, category_name])
									continue

					"timer":
						var timer_name: String = str(sig[3])
						print("[DEBUG] §Choice_List: Received 'timer' event → %s (depth %s)."
							% [timer_name, str(this_depth)])

						#@ Step 11A - Locate timer data:
						timers_array = choice_list_data[this_depth].get("Timers", [])
						var timer_data: Dictionary = {}
						for timer_entry in timers_array:
							if timer_entry.has(timer_name):
								timer_data = timer_entry[timer_name]
								break
						if timer_data.is_empty():
							printerr("§Choice_List: Timer '%s' not found in data (depth %s)." %
								[timer_name, str(this_depth)])
							continue

						#@ Step 11B - Update timer statuses:
						timer_data["Status"] = "Timeout"	#/ Mark current timer
						choice_lists[this_depth]["Last Timer"] = timer_name		#/ Record for §Timer_Status "Last" mode
						var t_node: Timer = menu_node.timer_list.get_node_or_null(timer_name)

						#% Pause all other running timers:
						for t_entry in timers_array:
							for t_key in t_entry.keys():
								if t_key == timer_name:
									continue
								var t_data: Dictionary = t_entry[t_key]
								if t_data.get("Status", "") == "Run":
									var other_node: Timer = menu_node.timer_list.get_node_or_null(t_key)
									if other_node:
										other_node.set_paused(true)
										t_data["Status"] = "Signal Pause"
										print("[DEBUG] §Choice_List: Timer '%s' paused (Signal Pause)." % t_key)

						#@ Step 11C - Execute Timeout transition (always Bridge):
						var timeout_data: Dictionary = timer_data.get("Timeout", {})
						if timeout_data.is_empty():
							print("[DEBUG] §Choice_List: Timer '%s' has no Timeout transition defined." % timer_name)
							continue

						var convo: String = resolve_value(timeout_data.get("Conversation", "")).strip_edges()
						var block: String = resolve_value(timeout_data.get("Block", "")).strip_edges()
						var line_ref: String = resolve_value(timeout_data.get("Line", "")).strip_edges()
						if convo != "" or block != "" or line_ref != "":
							var cmd_to_run := "§Bridge"
							var fake_line := [
								{ cmd_to_run: { "Conversation": convo, "Block": block, "Line": line_ref } }
							]
							nesting_depth += 1
							var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
							nesting_depth -= 1
							if feedback in ["END", "Return"]:
								return feedback

							print("[DEBUG] §Choice_List: Timer '%s' executed Timeout Bridge → %s:%s:%s (feedback=%s)."
								% [timer_name, convo, block, line_ref, str(feedback)])

						#@ Step 11D - Handle looping for triggered timer:
						timers_array = choice_list_data[this_depth].get("Timers", [])
						timer_data = {}
						for timer_entry in timers_array:
							if timer_entry.has(timer_name):
								timer_data = timer_entry[timer_name]
								break

						if timer_data.is_empty():
							printerr("§Choice_List: Timer '%s' not found after Timeout transition (depth %s)." %
								[timer_name, str(this_depth)])
							continue

						var loop_val: int = int(resolve_value(timer_data.get("Loop", "0")))
						print("[DEBUG] §Choice_List: Timer '%s' loop_val at timeout = %s, full timer_data = %s" % [timer_name, str(loop_val), str(timer_data)])
						t_node = menu_node.timer_list.get_node_or_null(timer_name)
						#% Infinite loops:
						if loop_val == -1:
							if t_node:
								t_node.set_paused(false)
								t_node.wait_time = float(timer_data.get("Time", "0"))
								t_node.start()
								t_node.set_paused(true)
								timer_data["Status"] = "Signal Pause"
								print("[DEBUG] §Choice_List: Timer '%s' restarted (∞ loop, paused)." % timer_name)

						#% Finite loops remaining:
						elif loop_val > 1:
							timer_data["Loop"] = loop_val - 1
							if t_node:
								t_node.set_paused(false)
								t_node.wait_time = float(timer_data.get("Time", "0"))
								t_node.start()
								t_node.set_paused(true)
								timer_data["Status"] = "Signal Pause"
								print("[DEBUG] §Choice_List: Timer '%s' restarted paused (loops remaining=%d)." %
									[timer_name, timer_data["Loop"]])

						else:
							timer_data["Status"] = "Hold"
							print("[DEBUG] §Choice_List: Timer '%s' completed all loops (Status=Hold)." % timer_name)

						#@ Step 11-E - Trigger one or more choices if defined in timer data:
						var choice_trigger: String = resolve_value(timer_data.get("Timer Choices", "")).strip_edges()

						if choice_trigger != "":
							var parts: Array = candy_to_array(choice_trigger)
							if parts.size() >= 2:
								var cat_name: String = str(parts[0]).strip_edges()
								var choice_name: String = str(parts[1]).strip_edges()
								if cat_name == "" or choice_name == "":
									print("[DEBUG] §Choice_List: Timer '%s' skipped invalid trigger (cat='%s', choice='%s')."
										% [timer_name, cat_name, choice_name])
								else:
									print("[DEBUG] §Choice_List: Timer '%s' triggering choice '%s' in category '%s'."
										% [timer_name, choice_name, cat_name])
									var cat_nodes: Dictionary = choice_lists[this_depth].get("Category Nodes", {})
									if cat_nodes.has(cat_name):
										var cat_node = cat_nodes[cat_name].get("Node", null)
										if cat_node and cat_node.button_list.has_node(choice_name):
											var choice_button: Node = cat_node.button_list.get_node(choice_name)
											if choice_button.choice_enabled == 0:
												print("[DEBUG] §Choice_List: Timer '%s' skipped disabled choice '%s/%s'."
													% [timer_name, cat_name, choice_name])
											elif choice_button.has_method("_choice_selected"):
												choice_button.call_deferred("_choice_selected")
												print("[DEBUG] §Choice_List: Timer '%s' called _choice_selected() for '%s/%s'."
													% [timer_name, cat_name, choice_name])
											else:
												printerr("§Choice_List: Choice node '%s/%s' missing _choice_selected()."
													% [cat_name, choice_name])
										else:
											printerr("§Choice_List: Could not find choice button '%s' in category '%s'."
												% [choice_name, cat_name])
									else:
										printerr("§Choice_List: Could not find category '%s' for timer-triggered choice."
											% cat_name)
							else:
								printerr("§Choice_List: Timer '%s' 'Timer Choices' must follow format '[Category, Choice]'." % timer_name)

						#@ Step 11-F - Resume paused timers:
						print("timer data: " + str(timer_data))
						for t_entry in timers_array:
							for t_key in t_entry.keys():
								var t_data: Dictionary = t_entry[t_key]
								if t_data.get("Status", "") == "Signal Pause":
									var resume_node: Timer = menu_node.timer_list.get_node_or_null(t_key)
									if resume_node:
										if t_data.has("Pending Restart"):
											resume_node.set_paused(false)
											resume_node.wait_time = float(t_data["Pending Restart"])
											resume_node.start()
											t_data.erase("Pending Restart")
											print("[DEBUG] §Choice_List: Timer '%s' restarted with new time (%.2fs) after timeout." % [t_key, resume_node.wait_time])
										else:
											resume_node.set_paused(false)
										t_data["Status"] = "Run"
										print("[DEBUG] §Choice_List: Timer '%s' resumed (Status=Run)." % t_key)

			push_warning("§Choice_List broke the 'while' loop.")
			return "Continue"	#/ Safety precaution - Need to root out all causes of 'while' loop breaking.


		#* §Choice_Status - Modify enabled, active, invisible, label, or tooltip fields of choices:
		"§choice_status":
			var choice_mode: String			= resolve_value(command_value.get("Choice Mode", "Last")).capitalize()
			var choice_tags_raw: String		= resolve_value(command_value.get("Choice Tags", "")).strip_edges()
			var category_mode: String		= resolve_value(command_value.get("Category Mode", "Last")).capitalize()
			var category_tags_raw: String	= resolve_value(command_value.get("Category Tags", "")).strip_edges()
			var menu_mode: String			= resolve_value(command_value.get("Menu Mode", "Last")).capitalize()
			var menu_tags_raw: String		= resolve_value(command_value.get("Menu Tags", "")).strip_edges()

			var enable_mode: String			= resolve_value(command_value.get("Enable", "-")).capitalize()
			var active_mode: String			= resolve_value(command_value.get("Activate", "-")).capitalize()
			var show_mode: String			= resolve_value(command_value.get("Show", "-")).capitalize()
			var label_val: String			= resolve_value(command_value.get("Label", "")).strip_edges()
			var tooltip_val: String			= resolve_value(command_value.get("Tooltip", "")).strip_edges()

			#% Split tag strings into arrays:
			var choice_tags = choice_tags_raw.split(",", false)
			var category_tags = category_tags_raw.split(",", false)
			var menu_tags = menu_tags_raw.split(",", false)

			#@ Determine target depths (menus/lists):
			var target_depths: Array = []

			print("§Choice_Status started...")
			if menu_mode == "Last":
				if choice_list_data.size() > 0:
					var max_depth = choice_list_data.keys().max()
					target_depths = [max_depth]
			elif menu_mode == "Tags":
				for depth in choice_list_data.keys():
					var tags = choice_lists.get(depth, {}).get("Tags", choice_list_data.get(depth, {}).get("Tags", ""))
					for tag in menu_tags:
						if tag.strip_edges() != "" and tags.find(tag.strip_edges()) != -1:
							target_depths.append(depth)
							break
			elif menu_mode == "All":
				target_depths = choice_list_data.keys()

			#@ Loop through selected menus/lists:
			for depth in target_depths:
				var cat_nodes: Dictionary = choice_lists.get(depth, {}).get("Category Nodes", {})
				
				var categories_array: Array = choice_list_data.get(depth, {}).get("Categories", [])
				if categories_array.is_empty():
					continue

				print("[DEBUG] choice_list_data keys: %s" % str(choice_list_data.keys()))
				print("[DEBUG] depth value: %s" % str(depth))
				print("[DEBUG] choice_list_data has depth: %s" % str(choice_list_data.has(depth)))
				if choice_list_data.has(depth):
					print("[DEBUG] Categories for depth: %s" % str(choice_list_data[depth].get("Categories", "MISSING")))

				for category_entry in categories_array:
					for cat_key in category_entry.keys():
						var cat_data: Dictionary = category_entry[cat_key]
						var cat_tags: String = resolve_value(cat_data.get("Tags", "")).strip_edges()
						var cat_node = cat_nodes.get(cat_key, {}).get("Node", null)

						#% Check if category matches filter:
						var include_category := true
						match category_mode:
							"Last":
								if not choice_lists.has(depth) or not choice_lists[depth].has("Last Choice"):
									include_category = false
								else:
									var last_cat = choice_lists[depth]["Last Choice"]["Choice"][0]
									include_category = (last_cat == cat_key)
							"Tags":
								include_category = false
								for tag in category_tags:
									if tag.strip_edges() != "" and cat_tags.find(tag.strip_edges()) != -1:
										include_category = true
										break
							"All":
								if category_tags_raw != "":
									for tag in category_tags:
										if tag.strip_edges() != "" and cat_tags.find(tag.strip_edges()) != -1:
											include_category = false
											break
						if not include_category:
							continue

						#% Get choices from live choice_list_data for this category:
						var choices_array: Array = cat_data.get("Choices", [])

						print("[DEBUG] cat_data for '%s': %s" % [cat_key, str(cat_data)])
						print("[DEBUG] choices_array size: %d" % choices_array.size())

						for choice_entry in choices_array:
							for choice_key in choice_entry.keys():
								var choice_data: Dictionary = choice_entry[choice_key]
								var choice_tags_str: String = resolve_value(choice_data.get("Tags", "")).strip_edges()
								print("[DEBUG] §Choice_Status: Checking choice '%s'" % choice_key)

								#% Choice filter:
								var include_choice := true
								match choice_mode:
									"Last":
										if not choice_lists.has(depth) or not choice_lists[depth].has("Last Choice"):
											include_choice = false
										else:
											var last_choice = choice_lists[depth]["Last Choice"]["Choice"][1]
											include_choice = (last_choice == choice_key)
									"Tags":
										include_choice = false
										for tag in choice_tags:
											if tag.strip_edges() != "" and choice_tags_str.find(tag.strip_edges()) != -1:
												include_choice = true
												break
									"All":
										if choice_tags_raw != "":
											for tag in choice_tags:
												if tag.strip_edges() != "" and choice_tags_str.find(tag.strip_edges()) != -1:
													include_choice = false
													break

								print("[DEBUG] §Choice_Status: include_choice=%s for '%s'" % [str(include_choice), choice_key])
								if not include_choice:
									continue

								#@ Safeguard for redundancy (switch mode to "-" if choice_data already matches):
								var effective_enable_mode := enable_mode
								var effective_active_mode := active_mode
								var effective_show_mode := show_mode

								match effective_enable_mode:
									"Enable":
										if choice_data["Enabled"] == "1":
											effective_enable_mode = "-"
									"Disable":
										if choice_data["Enabled"] == "0":
											effective_enable_mode = "-"
									_:
										pass

								match effective_active_mode:
									"Activate":
										if choice_data["Active"] == "1":
											effective_active_mode = "-"
									"Deactivate":
										if choice_data["Active"] == "0":
											effective_active_mode = "-"
									_:
										pass

								match effective_show_mode:
									"Show":
										if choice_data["Invisible"] == "0":
											effective_show_mode = "-"
									"Hide":
										if choice_data["Invisible"] == "1":
											effective_show_mode = "-"
									_:
										pass

								print("[DEBUG] §Choice_Status: effective_show_mode='%s' for '%s'" % [effective_show_mode, choice_key])

								#@ Apply effects (string modes):
								match effective_enable_mode:
									"Enable":
										choice_data["Enabled"] = "1"
									"Disable":
										choice_data["Enabled"] = "0"
									"Toggle":
										if choice_data["Enabled"] == "0":
											choice_data["Enabled"] = "1"
										elif choice_data["Enabled"] == "1":
											choice_data["Enabled"] = "0"
									"-":
										pass

								match effective_active_mode:
									"Activate":
										choice_data["Active"] = "1"
									"Deactivate":
										choice_data["Active"] = "0"
									"Toggle":
										if choice_data["Active"] == "0":
											choice_data["Active"] = "1"
										elif choice_data["Active"] == "1":
											choice_data["Active"] = "0"
									"-":
										pass

								match effective_show_mode:
									"Show":
										choice_data["Invisible"] = "0"
									"Hide":
										choice_data["Invisible"] = "1"
									"Toggle":
										if choice_data["Invisible"] == "0":
											choice_data["Invisible"] = "1"
										elif choice_data["Invisible"] == "1":
											choice_data["Invisible"] = "0"
									"-":
										pass

								print("[DEBUG] §Choice_Status: choice_data after apply = %s" % str(choice_data))

								#@ Label and tooltip text updates:
								if label_val != "":
									choice_data["Label"] = label_val
								if tooltip_val != "":
									choice_data["Tooltip"] = tooltip_val

								#@ Update live data:
								for entry in choice_list_data[depth].get("Categories", []):
									if entry.has(cat_key):
										for choice_entry_2 in entry[cat_key].get("Choices", []):
											if choice_entry_2.has(choice_key):
												choice_entry_2[choice_key] = choice_data
										break

								#@ Update button data and visuals if available:
								print("[DEBUG] §Choice_Status: cat_node=%s, has_node=%s" % [str(cat_node), str(cat_node.has_node(choice_key) if cat_node else false)])
								if cat_node:
									var button_node
									var button_list = cat_node.button_list
									#% If a button exists:
									if button_list and button_list.has_node(choice_key):
										button_node = button_list.get_node_or_null(choice_key)
										if button_node:
											var old_label = button_node.label
											var old_tooltip = button_node.tooltip

											#% Sync internal state directly from choice_data:
											button_node.choice_enabled = int(choice_data.get("Enabled", "1"))
											button_node.choice_active = int(choice_data.get("Active", "1"))
											button_node.choice_invisible = int(choice_data.get("Invisible", "0"))
											button_node.label = choice_data.get("Label", "")
											button_node.tooltip = choice_data.get("Tooltip", "")

											#% Delete button if enabled = 0:
											if effective_enable_mode == "Disable" or (effective_enable_mode == "Toggle" and choice_data["Enabled"] == "0"):
												await button_node._toggle_enabled()
												button_node.queue_free()
												await get_tree().process_frame
												print("[DEBUG] §Choice_Status: Deleted choice button for '%s' in category '%s' (depth %s)"
													% [choice_key, cat_key, str(depth)])

											#% If don't delete button:
											else:
												if effective_active_mode != "-":						#/ Don't do this if Active hasn't changed
													await button_node._toggle_active()
												if effective_show_mode != "-":							#/ Don't do this if Invisible hasn't changed
													await button_node._toggle_invisible()

												if label_val != "" and label_val != old_label:			#/ Don't do this if Label hasn't changed
													await button_node._set_label()
												if tooltip_val != "" and tooltip_val != old_tooltip:	#/ Don't do this if Tooltip hasn't changed
													await button_node._set_tooltip()
												print("[DEBUG] §Choice_Status: Updated choice '%s' in category '%s' (depth %s)"
													% [choice_key, cat_key, str(depth)])

									#% If a button doesn't exist, create one:
									else:
										if effective_enable_mode == "Enable" or (effective_enable_mode == "Toggle" and choice_data["Enabled"] == "1"):
											#@ Step 1 - Run choice Setup transition (if any):
											var choice_setup: Dictionary = choice_data.get("Setup", {})
											if not choice_setup.is_empty():
												var convo: String = resolve_value(choice_setup.get("Conversation", "")).strip_edges()
												var block: String = resolve_value(choice_setup.get("Block", "")).strip_edges()
												var line_ref: String = resolve_value(choice_setup.get("Line", "")).strip_edges()
												var trans_type: String = resolve_value(choice_setup.get("Type", "Bridge")).to_lower()

												if not (convo == "" and block == "" and line_ref == ""):
													match trans_type:
														"bridge":
															var cmd_to_run := "§Bridge"
															var fake_line := [
																{
																	cmd_to_run: {
																		"Conversation": convo,
																		"Block": block,
																		"Line": line_ref,
																	}
																}
															]
															nesting_depth += 1
															var feedback = await run_dialogue(current_conversation, current_block, 0, fake_line, false)
															nesting_depth -= 1
															if feedback in ["END", "Return"]:
																return feedback
														_:
															print("[DEBUG] Unknown transition type in §Choice_Status.Setup: %s" % trans_type)

											#@ Step 2 - Re-fetch live choice data in case Setup mutated it:
											#? Setup might run another §Choice_Status command, which would modify the choice data again.

											#% Get the freshest data:
											choice_data = {}
											for entry in choice_list_data[depth].get("Categories", []):
												if entry.has(cat_key):
													for choice_entry_3 in entry[cat_key].get("Choices", []):
														if choice_entry_3.has(choice_key):
															choice_data = choice_entry_3[choice_key]
													break

											#% End §Choice_Status here if choice was disabled during Setup:
											if choice_data.get("Enabled", "0") == "0":
												print("[DEBUG] §Choice_Status: Spawn aborted for '%s' (disabled during Setup)."
													% choice_key)
												continue

											#@ Step 3 - Spawn button (mirrors §Choice_List Step 7):
											if button_list and button_list.has_node(choice_key):
												button_node = button_list.get_node_or_null(choice_key)
												if button_node:
													print("[DEBUG] §Choice_Status: Spawn skipped for '%s' (already exists after Setup)."
														% choice_key)
												else:
													button_node = null

											if button_node == null:
												var category_instance = cat_node
												if category_instance == null:
													continue
												if button_list == null:
													continue

												#% Determine button scene path (choice > category > general):
												var general_button_scene: String = resolve_value(choice_list_data[depth].get("Button Scene", "Default.tscn")).strip_edges()
												if general_button_scene == "":
													general_button_scene = "Default.tscn"
												elif not general_button_scene.ends_with(".tscn"):
													general_button_scene += ".tscn"
												general_button_scene = candy_de.choice_buttons_folder.path_join(general_button_scene)

												var category_data: Dictionary = {}
												for entry in choice_list_data[depth].get("Categories", []):
													if entry.has(cat_key):
														category_data = entry[cat_key]
														break

												var category_button_scene: String = resolve_value(category_data.get("Button Scene", "")).strip_edges()
												if category_button_scene == "":
													category_button_scene = general_button_scene
												else:
													if not category_button_scene.ends_with(".tscn"):
														category_button_scene += ".tscn"
													category_button_scene = candy_de.choice_buttons_folder.path_join(category_button_scene)

												var choice_scene_name: String = resolve_value(choice_data.get("Button Scene", "")).strip_edges()
												var final_scene_path: String = ""
												if choice_scene_name == "":
													final_scene_path = category_button_scene
												else:
													if not choice_scene_name.ends_with(".tscn"):
														choice_scene_name += ".tscn"
													final_scene_path = candy_de.choice_buttons_folder.path_join(choice_scene_name)

												if final_scene_path == "" or not ResourceLoader.exists(final_scene_path):
													printerr("§Choice_Status: Invalid button scene for choice '%s' → %s"
														% [choice_key, final_scene_path])
													continue

												var scene_res: PackedScene = load(final_scene_path)
												if scene_res == null:
													printerr("§Choice_Status: Failed to load button scene at → %s" % final_scene_path)
													continue

												var button_instance = scene_res.instantiate()
												button_instance.name = choice_key
												button_instance.parent_category = category_instance
												button_instance.parent_menu = choice_lists[depth]["Menu"]
												button_instance.caller = self
												button_instance.choice_name = choice_key
												button_instance.category_name = cat_key

												var choice_label = resolve_value(choice_data.get("Label", ""))
												if choice_label == "":
													choice_label = choice_key

												button_instance.label = choice_label
												button_instance.tooltip = resolve_value(choice_data.get("Tooltip", ""))
												button_instance.general_custom = resolve_value(choice_list_data[depth].get("Custom", ""))
												button_instance.category_custom = resolve_value(category_data.get("Custom", ""))
												button_instance.choice_custom = resolve_value(choice_data.get("Custom", ""))
												button_instance.tags = resolve_value(choice_data.get("Tags", "")).strip_edges()
												button_instance.choice_enabled = 1
												button_instance.choice_active = int(choice_data.get("Active", "1"))
												button_instance.choice_invisible = int(choice_data.get("Invisible", "0"))
												button_list.add_child(button_instance)

												#/ Enable this if you need the button to be fully ready before calling setup():
												#await get_tree().process_frame

												var correct_index := 0
												var found := false
												for ce in choices_array:
													for ck in ce.keys():
														if ck == choice_key:
															found = true
															break
														if button_list.has_node(ck):
															correct_index += 1
													if found:
														break

												button_list.move_child(button_instance, correct_index)
												button_instance.setup()		#TODO: Add 'await' if setup() should finish before the next choice is handled.

												print("[DEBUG] §Choice_Status: Spawned choice '%s' under category '%s' (depth %s)"
													% [choice_key, cat_key, str(depth)])

			return "Continue"


		#* §Timer_Status - Modify active timers:
		"§timer_status":
			var timer_mode: String		= resolve_value(command_value.get("Timer Mode", "Last")).capitalize()
			var timer_tags_raw: String	= resolve_value(command_value.get("Timer Tags", "")).strip_edges()
			var menu_mode: String		= resolve_value(command_value.get("Menu Mode", "Last")).capitalize()
			var menu_tags_raw: String	= resolve_value(command_value.get("Menu Tags", "")).strip_edges()

			#% Modification fields:
			var time_val_str: String	= resolve_value(command_value.get("Time", "")).strip_edges()
			var node_mode: String		= resolve_value(command_value.get("Timer Node", "Ignore")).capitalize()
			var loop_val_str: String	= resolve_value(command_value.get("Loop", "")).strip_edges()
			var status_val: String		= resolve_value(command_value.get("Status", "")).strip_edges()

			#% Split tag strings into arrays:
			var timer_tags = timer_tags_raw.split(",", false)
			var menu_tags = menu_tags_raw.split(",", false)

			#@ Determine target depths (menus/lists):
			var target_depths: Array = []

			if menu_mode == "Last":
				if choice_list_data.size() > 0:
					var max_depth = choice_list_data.keys().max()
					target_depths = [max_depth]
			elif menu_mode == "Tags":
				for depth in choice_list_data.keys():
					var tags = choice_lists.get(depth, {}).get("Tags", choice_list_data.get(depth, {}).get("Tags", ""))
					for tag in menu_tags:
						if tag.strip_edges() != "" and tags.find(tag.strip_edges()) != -1:
							target_depths.append(depth)
							break
			elif menu_mode == "All":
				target_depths = choice_list_data.keys()

			#@ Loop through selected menus/lists:
			for depth in target_depths:
				var timers_array: Array = choice_list_data.get(depth, {}).get("Timers", [])
				if timers_array.is_empty():
					continue

				#% Get menu node reference for this depth:
				var menu_node = choice_lists.get(depth, {}).get("Menu", null)

				for timer_entry in timers_array:
					for timer_name in timer_entry.keys():
						var timer_data: Dictionary = timer_entry[timer_name]
						if timer_data.is_empty():
							continue

						var tags_str: String = resolve_value(timer_data.get("Tags", "")).strip_edges()

						#% Determine if this timer matches the filter:
						var include_timer := true
						match timer_mode:
							"Last":
								if not choice_lists.has(depth) or not choice_lists[depth].has("Last Timer"):
									include_timer = false
								else:
									var last_timer = choice_lists[depth]["Last Timer"]
									include_timer = (last_timer == timer_name)
							"Tags":
								include_timer = false
								for tag in timer_tags:
									if tag.strip_edges() != "" and tags_str.find(tag.strip_edges()) != -1:
										include_timer = true
										break
							"All":
								if timer_tags_raw != "":
									for tag in timer_tags:
										if tag.strip_edges() != "" and tags_str.find(tag.strip_edges()) != -1:
											include_timer = false
											break

						if not include_timer:
							continue

						var timer_node: Timer = menu_node.timer_list.get_node_or_null(timer_name) if menu_node else null

						#@ Time modification:
						if time_val_str != "":
							var old_time: float = float(timer_data.get("Time", "0"))
							var new_time: float = old_time

							if time_val_str.begins_with("+"):
								new_time += float(time_val_str.substr(1))
							elif time_val_str.begins_with("-"):
								new_time -= float(time_val_str.substr(1))
							elif time_val_str.begins_with("*"):
								new_time *= float(time_val_str.substr(1))
							elif time_val_str.begins_with("/"):
								var divisor = float(time_val_str.substr(1))
								if divisor != 0.0:
									new_time /= divisor
							else:
								new_time = float(time_val_str)

							new_time = max(new_time, 0.0)
							timer_data["Time"] = str(new_time)

							if timer_node:
								match node_mode:
									"Restart":
										timer_data["Pending Restart"] = new_time
										print("[DEBUG] §Timer_Status: Timer '%s' flagged for restart (%.2fs)." % [timer_name, new_time])
									"Update":
										var remaining: float = timer_node.time_left
										if new_time < remaining:
											timer_data["Pending Restart"] = new_time
											print("[DEBUG] §Timer_Status: Timer '%s' flagged for update (%.2fs < %.2fs remaining)." % [timer_name, new_time, remaining])
										else:
											print("[DEBUG] §Timer_Status: Timer '%s' not updated (%.2fs >= %.2fs remaining)." % [timer_name, new_time, remaining])
									"Ignore":
										pass

						#@ Loop modification:
						if loop_val_str != "":
							var old_loop: int = int(timer_data.get("Loop", "0"))
							var new_loop: int = old_loop

							var loop_str = loop_val_str.to_lower()
							if loop_str in ["inf", "!", "0"]:
								new_loop = -1
							elif loop_str.begins_with("+"):
								new_loop += int(loop_str.substr(1))
							elif loop_str.begins_with("-"):
								new_loop -= int(loop_str.substr(1))
							elif loop_str.begins_with("*"):
								new_loop = roundi(float(old_loop) * float(loop_str.substr(1)))
							elif loop_str.begins_with("/"):
								var divisor = int(float(loop_str.substr(1)))
								if divisor != 0:
									new_loop = roundi(float(old_loop) / divisor)
							else:
								new_loop = int(loop_str)

							timer_data["Loop"] = str(max(new_loop, -1))
							print("[DEBUG] §Timer_Status: Timer '%s' loop count set to %s." % [timer_name, str(new_loop)])

						#@ Status modification:
						if status_val != "":
							match status_val:
								"Pause":
									if timer_node:
										timer_node.set_paused(true)
									timer_data["Status"] = "Pause"
									print("[DEBUG] §Timer_Status: Timer '%s' paused." % timer_name)

								"Start/Resume":
									if timer_node:
										if timer_data.has("Pending Restart"):
											timer_node.set_paused(false)
											timer_node.wait_time = float(timer_data["Pending Restart"])
											timer_node.start()
											timer_data.erase("Pending Restart")
											print("[DEBUG] §Timer_Status: Timer '%s' started with new time (%.2fs)." % [timer_name, timer_node.wait_time])
										#% Timer paused:
										elif timer_node.is_paused():
											timer_node.set_paused(false)
											print("[DEBUG] §Timer_Status: Timer '%s' unpaused." % timer_name)
										#% Timer was never started (Hold) or was stopped — start it fresh:
										else:
											timer_node.wait_time = float(timer_data.get("Time", "0"))
											timer_node.start()
											print("[DEBUG] §Timer_Status: Timer '%s' started fresh (%.2fs)." % [timer_name, timer_node.wait_time])
									timer_data["Status"] = "Run"
									print("[DEBUG] §Timer_Status: Timer '%s' resumed." % timer_name)

								"Stop":
									if timer_node:
										timer_node.stop()
									timer_data.erase("Pending Restart")
									timer_data["Status"] = "Stopped"
									print("[DEBUG] §Timer_Status: Timer '%s' stopped." % timer_name)

								"-":
									print("[DEBUG] §Timer_Status: Timer '%s' unchanged." % timer_name)

						#@ Save modified timer data back into the entry:
						timer_entry[timer_name] = timer_data

						print("[DEBUG] §Timer_Status: Updated timer '%s' (depth %s, tags='%s')."
							% [timer_name, str(depth), tags_str])

			return "Continue"

		#endregion - choice commands


		#&########################################
		#&										##
		#&             BG COMMANDS              ##
		#&										##
		#region - BG Commands
		#* §BG_Scene - Replace the current background scene with a new one:
		"§bg_scene":
			var scene_name: String		= resolve_value(str(command_value.get("Scene", "")).strip_edges())

			#@ Step 1 - Remove existing Backgrounds node if present:
			var old_bgs = get_node_or_null(ui_elements_paths["backgrounds_path"])
			if old_bgs:
				old_bgs.queue_free()
				await get_tree().process_frame

			#@ Step 2 - Clear background state:
			active_bg_animations.clear()

			#@ Step 3 - Resolve scene path (variable, autoload, or direct):
			var scene_path: String = scene_name

			if scene_name.begins_with("res://"):
				scene_path = scene_name
			else:
				scene_path = candy_de.bg_scenes_folder.path_join(scene_name)

			if not scene_path.ends_with(".tscn"):
				scene_path = scene_path + ".tscn"

			#@ Step 4 - Load and instantiate the new scene:
			if not ResourceLoader.exists(scene_path):
				printerr("§BGScene: Missing background scene: ", scene_path)
				return

			var scene_res = load(scene_path)
			if scene_res == null:
				printerr("§BGScene: Could not load scene: ", scene_path)
				return

			var scene_instance = scene_res.instantiate()
			scene_instance.name = "Backgrounds"
			scene_instance.caller = self
			scene_instance.visible = true
			add_child(scene_instance)

			return "Continue"


		#* §BG - Assign or animate a background layer:
		"§bg":
			var layer: String		= resolve_value(command_value.get("Layers", "")).strip_edges()
			var file_ref: String	= resolve_value(command_value.get("File", "")).strip_edges()
			var anim_name: String	= resolve_value(command_value.get("Animation", "")).strip_edges()
			var loop: int			= int(resolve_value(command_value.get("Loop", "1")))
			var wait: int			= int(resolve_value(command_value.get("Wait", "0")))
			var time_raw: Variant	= resolve_value(command_value.get("Time", "0"))

			if layer == "":
				printerr("§BG: Missing layer name.")
				return "Continue"

			#@ Parse Time value (can be HH:MM:SS.xx or f=frames):
			var time_target: float = 0.0
			var default_fps: float = 30.0
			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s == "":
					time_target = 0.0
				elif s.begins_with("f=") or s.begins_with("F="):
					var frame_val = float(s.substr(2, s.length()))
					time_target = frame_val / default_fps
				else:
					var parts = s.split(":")
					match parts.size():
						3:
							time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
						2:
							time_target = int(parts[0]) * 60 + float(parts[1])
						1:
							time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Call assign_bg and await completion:
			var bg_scene = get_node(ui_elements_paths["backgrounds_path"])
			bg_scene.caller = self
			await bg_scene.assign_bg(layer, file_ref, anim_name, loop, wait, time_target)

			return "Continue"


		#* §BG_Stop - Stop one or more background animations:
		"§bg_stop":
			var layers_raw: Variant		= resolve_value(command_value.get("Layers", ""))
			var use_default: Variant	= resolve_value(command_value.get("Default", 0))

			#@ Step 1 - Convert to array:
			var layers_array: Array = []
			if layers_raw is String:
				for part in layers_raw.split(",", false):
					var effect_name = part.strip_edges()
					if effect_name != "":
						layers_array.append(effect_name)
			elif layers_raw is Array:
				layers_array = layers_raw.duplicate()

			#@ Step 2 - Stop animations:
			var bg_scene = get_node(ui_elements_paths["backgrounds_path"])
			bg_scene.caller = self
			bg_scene.stop_bg_animation(layers_array, use_default)

			return "Continue"


		#* §BG_Wait - Pause dialogue until background layers reach a target loop/time or finish playback:
		"§bg_wait":
			var layers_raw: Variant     = resolve_value(command_value.get("Layers", ""))
			var wait_raw: Variant       = resolve_value(command_value.get("Wait", "0"))
			var time_raw: Variant       = resolve_value(command_value.get("Time", "0"))

			#@ Step 1 - Parse layer list:
			var layers_array: Array = []
			if layers_raw is String:
				for part in layers_raw.split(",", false):
					var layer_name = part.strip_edges()
					if layer_name != "":
						layers_array.append(layer_name)
			elif layers_raw is Array:
				layers_array = layers_raw.duplicate()

			#@ Step 2 - Parse Wait and Time:
			var wait_target: int = 0
			var time_target: float = 0.0
			var default_fps: float = 30.0

			if str(wait_raw).strip_edges() != "":
				wait_target = int(wait_raw)

			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					if s.begins_with("f=") or s.begins_with("F="):
						var frame_val = float(s.substr(2, s.length()))
						time_target = frame_val / default_fps
					else:
						var parts = s.split(":")
						match parts.size():
							3:
								time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
							2:
								time_target = int(parts[0]) * 60 + float(parts[1])
							1:
								time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 3 - Resolve which layers to wait for:
			var bg_scene = get_node(ui_elements_paths["backgrounds_path"])
			bg_scene.caller = self
			var bg_data: Dictionary = bg_scene.bg_layer_data
			var target_layers: Array = []

			if layers_array.is_empty():
				target_layers = bg_data.keys()
			else:
				for layer_name in layers_array:
					if bg_data.has(layer_name):
						target_layers.append(layer_name)

			if target_layers.is_empty():
				return "Continue"

			#@ Step 4 - Wait for each layer:
			var done_layers: Array = []
			while done_layers.size() < target_layers.size():
				for layer_name in target_layers:
					if layer_name in done_layers:
						continue

					var data = bg_data.get(layer_name, null)
					if data == null:
						done_layers.append(layer_name)
						continue

					var loop_target: int    = int(data.get("loop_target", 0))
					var loops_played: int   = int(data.get("loops_played", 0))
					var duration: float     = float(data.get("duration", 0.0))
					var resume_at: float    = (wait_target * duration) + time_target

					#% Compute elapsed with mid-loop precision where possible:
					var bg_node = data.get("node", null)
					var elapsed: float = loops_played * duration
					print("[DEBUG] §BGWait: loop_target=%d, loops_played=%d, duration=%.2f, elapsed=%.2f, resume_at=%.2f, wait_target=%d, time_target=%.2f" % [loop_target, loops_played, duration, elapsed, resume_at, wait_target, time_target])
					if bg_node:
						if (bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D) and bg_node.is_playing():
							var frame_count = bg_node.sprite_frames.get_frame_count(bg_node.animation) if bg_node.sprite_frames else 1
							var frame_duration = duration / max(frame_count, 1)
							elapsed += bg_node.frame * frame_duration
						elif bg_node is VideoStreamPlayer and bg_node.is_playing():
							elapsed += bg_node.stream_position
						else:
							#% Sprite2D uses elapsed_time which is already updated per-frame:
							elapsed = float(data.get("elapsed_time", 0.0))
					else:
						elapsed = float(data.get("elapsed_time", 0.0))

					#% Case 1 - Infinite loop & no wait/time → ignore:
					if loop_target == -1 and wait_target == 0 and time_target <= 0.0:
						done_layers.append(layer_name)
						continue

					#% Case 2 - Finished required loops/time:
					if wait_target != -1 or time_target > 0.0:
						if elapsed >= resume_at:
							done_layers.append(layer_name)
							continue
					else:
						#% No wait/time: wait for all loops to finish:
						if loop_target > 0 and loops_played >= loop_target:
							done_layers.append(layer_name)
							continue

				await get_tree().process_frame

			return "Continue"


		#* §BG_Remove - Remove images and animations from one or more BG layer nodes:
		"§bg_remove":
			var layers_raw: Variant	= resolve_value(command_value.get("Layers", ""))

			#@ Step 1 - Convert to array (handles string or array input):
			var refs_array: Array = []
			if layers_raw is String:
				for part in layers_raw.split(",", false):
					var ref_name = part.strip_edges()
					if ref_name != "":
						refs_array.append(ref_name)
			elif layers_raw is Array:
				refs_array = layers_raw.duplicate()

			#@ Step 2 - Clear visuals for the resolved list:
			var bg_scene = get_node(ui_elements_paths["backgrounds_path"])
			bg_scene.caller = self
			bg_scene.clear_bg_nodes(refs_array)

			return "Continue"


		#* §BG_Mirror - Flip one or more background layers horizontally, vertically, or both:
		"§bg_mirror":
			var layers_raw: Variant		= resolve_value(command_value.get("Layers", ""))
			var axis: String			= resolve_value(command_value.get("Axis", "Reset")).strip_edges().to_lower()

			#@ Step 1 - Parse layer list (comma-separated or array):
			var layers_array: Array = []
			if layers_raw is String:
				for part in layers_raw.split(",", false):
					var layer_name = part.strip_edges()
					if layer_name != "":
						layers_array.append(layer_name)
			elif layers_raw is Array:
				layers_array = layers_raw.duplicate()

			#@ Step 2 - Apply mirror operation:
			var bg_scene = get_node(ui_elements_paths["backgrounds_path"])
			bg_scene.caller = self

			#% If no layers provided → mirror all visible background nodes:
			if layers_array.is_empty():
				for child in bg_scene.bg_container.get_children():
					if child is Node:
						bg_scene.mirror_bg(child.name, axis)
			else:
				for layer_name in layers_array:
					bg_scene.mirror_bg(layer_name, axis)

			return "Continue"


		#* §BG_Effect - Play one or more AnimationPlayer effects on background layers:
		"§bg_effect":
			var layers_raw: Variant		= resolve_value(command_value.get("Layers", ""))
			var lib_name: String		= resolve_value(command_value.get("Library", "")).strip_edges()
			var effects_raw: Variant	= resolve_value(command_value.get("Effects", ""))
			var loop_raw: Variant		= resolve_value(command_value.get("Loop", "0"))
			var wait_raw: Variant		= resolve_value(command_value.get("Wait", "0"))
			var time_raw: Variant		= resolve_value(command_value.get("Time", "1"))

			#@ Step 1 - Convert Layer and Effect lists:
			var layers_array: Array = []
			if layers_raw is String:
				for part in layers_raw.split(",", false):
					var layer_name = part.strip_edges()
					if layer_name != "":
						layers_array.append(layer_name)
			elif layers_raw is Array:
				layers_array = layers_raw.duplicate()

			var effects_array: Array = []
			if effects_raw is String:
				for part in effects_raw.split(",", false):
					var eff_name = part.strip_edges()
					if eff_name != "":
						effects_array.append(eff_name)
			elif effects_raw is Array:
				effects_array = effects_raw.duplicate()

			#@ Step 2 - Parse Loop / Wait / Time:
			var loop_target: int = int(loop_raw)
			var wait_target: int = int(wait_raw)
			var time_target: float = 0.0
			var default_fps: float = 30.0

			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					if s.begins_with("f=") or s.begins_with("F="):
						var frame_val = float(s.substr(2, s.length()))
						time_target = frame_val / default_fps
					else:
						var parts = s.split(":")
						match parts.size():
							3:
								time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
							2:
								time_target = int(parts[0]) * 60 + float(parts[1])
							1:
								time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 3 - Play effects:
			var bg_scene = get_node(ui_elements_paths["backgrounds_path"])
			bg_scene.caller = self
			bg_scene.play_bg_effects(layers_array, lib_name, effects_array, loop_target, wait_target, time_target)

			#@ Step 4 - Wait until resume_at is reached:
			var resume_at: float = 0.0
			if wait_target > 0 or time_target > 0.0:
				var first_layer = layers_array[0] if not layers_array.is_empty() else ""
				if first_layer == "":
					for child in bg_scene.bg_container.get_children():
						first_layer = child.name
						break

				var first_effect = effects_array[0] if not effects_array.is_empty() else ""
				if bg_scene.bg_layer_data.has(first_layer) and \
				bg_scene.bg_layer_data[first_layer].has("effects") and \
				bg_scene.bg_layer_data[first_layer]["effects"].has(first_effect):
					var effect_data = bg_scene.bg_layer_data[first_layer]["effects"][first_effect]
					var duration = effect_data["duration"]
					resume_at = (wait_target * duration) + time_target

					while true:
						await get_tree().process_frame
						var elapsed = effect_data["loops_played"] * duration + effect_data["player"].current_animation_position
						if elapsed >= resume_at:
							break
						if not effect_data["player"].is_playing() and loop_target > 0 and effect_data["loops_played"] >= loop_target:
							break


		#* §BG_Effect_Stop - Stop one or more background AnimationPlayer effects:
		"§bg_effect_stop":
			var layers_raw: Variant		= resolve_value(command_value.get("Layers", ""))
			var effects_raw: Variant	= resolve_value(command_value.get("Effects", ""))

			#@ Step 1 - Convert to arrays:
			var layers_array: Array = []
			if layers_raw is String:
				for part in layers_raw.split(",", false):
					var layer_name = part.strip_edges()
					if layer_name != "":
						layers_array.append(layer_name)
			elif layers_raw is Array:
				layers_array = layers_raw.duplicate()

			var effects_array: Array = []
			if effects_raw is String:
				for part in effects_raw.split(",", false):
					var layer_name = part.strip_edges()
					if layer_name != "":
						effects_array.append(layer_name)
			elif effects_raw is Array:
				effects_array = effects_raw.duplicate()

			#@ Step 2 - Stop effects:
			var bg_scene = get_node(ui_elements_paths["backgrounds_path"])
			bg_scene.caller = self
			bg_scene.stop_bg_effects(layers_array, effects_array)

			return "Continue"


		#* §BG_Effect_Wait - Pause dialogue until background layer effects reach a target loop/time or finish playback:
		"§bg_effect_wait":
			var layers_raw: Variant		= resolve_value(command_value.get("Layers", ""))
			var effects_raw: Variant	= resolve_value(command_value.get("Effects", ""))
			var wait_raw: Variant		= resolve_value(command_value.get("Wait", "0"))
			var time_raw: Variant		= resolve_value(command_value.get("Time", "0"))

			#@ Step 1 - Parse layer and effect lists:
			var layers_array: Array = []
			if layers_raw is String:
				for part in layers_raw.split(",", false):
					var layer_name = part.strip_edges()
					if layer_name != "":
						layers_array.append(layer_name)
			elif layers_raw is Array:
				layers_array = layers_raw.duplicate()

			var effects_array: Array = []
			if effects_raw is String:
				for part in effects_raw.split(",", false):
					var eff = part.strip_edges()
					if eff != "":
						effects_array.append(eff)
			elif effects_raw is Array:
				effects_array = effects_raw.duplicate()

			#@ Step 2 - Parse Wait and Time:
			var wait_target: int = -1
			var time_target: float = 0.0
			var default_fps: float = 30.0

			if str(wait_raw).strip_edges() == "":
				wait_raw = "0"		

			wait_target = int(wait_raw)

			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					if s.begins_with("f=") or s.begins_with("F="):
						var frame_val = float(s.substr(2, s.length()))
						time_target = frame_val / default_fps
					else:
						var parts = s.split(":")
						match parts.size():
							3:
								time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
							2:
								time_target = int(parts[0]) * 60 + float(parts[1])
							1:
								time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 3 - Resolve layers and effects to wait for:
			var bg_scene = get_node(ui_elements_paths["backgrounds_path"])
			bg_scene.caller = self
			var bg_data: Dictionary = bg_scene.bg_layer_data
			var target_pairs: Array = []	#/ array of [layer, effect_name] pairs

			if layers_array.is_empty():
				#% All layers that have active effects:
				for layer_name in bg_data.keys():
					var effects_dict = bg_data[layer_name].get("effects", {})
					if effects_array.is_empty():
						for e in effects_dict.keys():
							target_pairs.append([layer_name, e])
					else:
						for e in effects_array:
							if effects_dict.has(e):
								target_pairs.append([layer_name, e])
			else:
				for layer_name in layers_array:
					if not bg_data.has(layer_name):
						continue
					var effects_dict = bg_data[layer_name].get("effects", {})
					if effects_array.is_empty():
						for e in effects_dict.keys():
							target_pairs.append([layer_name, e])
					else:
						for e in effects_array:
							if effects_dict.has(e):
								target_pairs.append([layer_name, e])

			if target_pairs.is_empty():
				return "Continue"

			#@ Step 4 - Wait until each effect meets the condition:
			var done_pairs: Array = []
			while done_pairs.size() < target_pairs.size():
				for pair in target_pairs:
					if pair in done_pairs:
						continue

					var layer_name = pair[0]
					var effect_name = pair[1]

					if not bg_data.has(layer_name):
						done_pairs.append(pair)
						continue
					var effects_dict = bg_data[layer_name].get("effects", {})
					if not effects_dict.has(effect_name):
						done_pairs.append(pair)
						continue

					var data = effects_dict[effect_name]
					var loop_target: int = int(data.get("loop_target", 0))
					var loops_played: int = int(data.get("loops_played", 0))
					var duration: float = float(data.get("duration", 0.0))
					var player: AnimationPlayer = data.get("player", null)
					var elapsed: float = loops_played * duration
					if player and player.is_playing():
						elapsed += player.current_animation_position
					var resume_at: float = (wait_target * duration) + time_target

					#% Case 1 - Infinite loop & no wait/time → ignore:
					if loop_target == 0 and wait_target == -1 and time_target <= 0.0:
						done_pairs.append(pair)
						continue

					#% Case 2 - Finished required loops/time:
					if wait_target != -1 or time_target > 0.0:
						if elapsed >= resume_at:
							done_pairs.append(pair)
							continue
					else:
						#% No wait/time → wait until all loops done:
						if loop_target > 0 and loops_played >= loop_target:
							done_pairs.append(pair)
							continue

				await get_tree().process_frame

			return "Continue"
		#endregion - bg commands


		#&########################################
		#&										##
		#&            EFFECT COMMANDS           ##
		#&										##
		#region - VFX Commands
		#* §Effect - play a visual effect animation clip:
		"§effect":
			var node_name: Variant		= resolve_value(command_value.get("Node", "Effect"))
			var anim_name: String		= str(resolve_value(command_value.get("Animation", ""))).strip_edges()
			var loop_raw: Variant		= resolve_value(command_value.get("Loop", "1"))
			var wait_raw: Variant		= resolve_value(command_value.get("Wait", ""))
			var time_raw: Variant		= resolve_value(command_value.get("Time", ""))
			var loop_target: int		= 1
			var wait_target: int		= -1
			var time_target: float		= 0.0
			var default_fps: float		= 30.0

			if str(loop_raw).strip_edges() != "":
				loop_target = int(loop_raw)

			if str(wait_raw).strip_edges() != "":
				wait_target = int(wait_raw)

			#@ Step 1 - Parse Time value:
			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					if s.begins_with("f=") or s.begins_with("F="):
						var frame_val = float(s.substr(2, s.length()))
						time_target = frame_val / default_fps
					else:
						var parts = s.split(":")
						match parts.size():
							3: time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
							2: time_target = int(parts[0]) * 60 + float(parts[1])
							1: time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 2 - Get target node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node_or_null(media_players_locations.get(str(node_name), ""))

			if not player_node or not (player_node.effect_player is AnimationPlayer):
				printerr("§Effect: target node invalid or not AnimationPlayer → ", node_name)
				return "Continue"

			if not player_node.effect_player.has_animation(anim_name):
				printerr("§Effect: animation not found → ", anim_name)
				return "Continue"

			#@ Step 3 - Compute animation timing:
			var anim: Animation = player_node.effect_player.get_animation(anim_name)
			if anim == null:
				printerr("§Effect: invalid animation data → ", anim_name)
				return "Continue"

			var duration: float = anim.length
			var resume_at: float = 0.0

			if wait_target >= 0:
				resume_at = (wait_target * duration) + time_target
			elif time_target > 0.0:
				resume_at = time_target

			#@ Step 4 - Configure node and start playing:
			player_node.loop_target		= loop_target
			player_node.wait_target		= wait_target
			player_node.loops_played	= 0
			player_node.duration		= duration
			player_node.caller			= self
			player_node.effect_player.play(anim_name)

			#% No wait required - continue immediately:
			if resume_at <= 0.0:
				return "Continue"

			#@ Step 5 - Wait until resume_at is reached:
			while true:
				await get_tree().process_frame

				if not player_node.effect_player.is_playing():
					if loop_target > 0 and player_node.loops_played >= loop_target:
						return "Continue"
					await get_tree().process_frame
					continue

				var elapsed = player_node.loops_played * duration + player_node.effect_player.current_animation_position
				if elapsed >= resume_at:
					return "Continue"

			return "Continue"


		#* §Effect_Wait - pause dialogue until a visual effect animation reaches a loop/time target:
		"§effect_wait":
			var node_name: Variant		= resolve_value(command_value.get("Node", "Effect"))
			var wait_raw: Variant		= resolve_value(command_value.get("Wait", ""))
			var time_raw: Variant		= resolve_value(command_value.get("Time", ""))

			var wait_target: int = -1
			var time_target: float = 0.0
			var default_fps: float = 30.0

			if str(wait_raw).strip_edges() != "":
				wait_target = int(wait_raw)

			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					if s.begins_with("f=") or s.begins_with("F="):
						var frame_val = float(s.substr(2, s.length()))
						time_target = frame_val / default_fps
					else:
						var parts = s.split(":")
						match parts.size():
							3: time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
							2: time_target = int(parts[0]) * 60 + float(parts[1])
							1: time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 1 - Resolve node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node_or_null(media_players_locations.get(str(node_name), ""))

			if not player_node or not (player_node.effect_player is AnimationPlayer):
				printerr("§EffectWait: invalid or missing AnimationPlayer → ", node_name)
				return "Continue"

			var anim_name: String = player_node.effect_player.current_animation
			if anim_name == "":
				return "Continue"

			var anim: Animation = player_node.effect_player.get_animation(anim_name)
			if anim == null:
				printerr("§EffectWait: current animation invalid → ", anim_name)
				return "Continue"

			var duration: float = player_node.duration
			var resume_at: float = 0.0

			if wait_target >= 0:
				resume_at = (wait_target * duration) + time_target
			elif time_target > 0.0:
				resume_at = time_target

			if resume_at <= 0.0:
				return "Continue"

			#@ Step 2 - Wait for the animation progress:
			while true:
				if not player_node.effect_player.is_playing():
					if player_node.loop_target > 0 and player_node.loops_played >= player_node.loop_target:
						return "Continue"
					await get_tree().process_frame
					continue

				var elapsed = player_node.loops_played * duration + player_node.effect_player.current_animation_position
				if elapsed >= resume_at:
					return "Continue"

				await get_tree().process_frame


		#* §Effect_Stop - stop a currently playing effect animation:
		"§effect_stop":
			var node_name: Variant		= resolve_value(command_value.get("Node", "Effect"))

			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node_or_null(media_players_locations.get(str(node_name), ""))

			if not player_node:
				printerr("§EffectStop: animation player node not found → ", node_name)
				return "Continue"

			if player_node.effect_player is AnimationPlayer:
				player_node.effect_player.stop()
			else:
				printerr("§EffectStop: target node is not an AnimationPlayer → ", node_name)

			return "Continue"


		#* §Wait - pause dialogue processing for a set duration:
		"§wait":
			var time_raw: Variant		= resolve_value(command_value.get("Time", 0.0))

			var duration := 0.0

			if typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				duration = float(time_raw)
			elif typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					var parts = s.split(":")
					match parts.size():
						3:
							duration = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
						2:
							duration = int(parts[0]) * 60 + float(parts[1])
						1:
							duration = float(parts[0])

			#@ Step 2 - Wait loop:
			if duration > 0:
				var start_time := Time.get_ticks_msec() / 1000.0
				while true:
					await get_tree().process_frame

					#% Safety: killswitch cancels wait immediately:
					if killswitch:
						return "END"

					#% Skip check: instantly end wait:
					if skip_wait:
						skip_wait = false
						break

					var elapsed := (Time.get_ticks_msec() / 1000.0) - start_time
					if elapsed >= duration:
						break

			return "Continue"


		#* §Hide - Reset Dialogue Box / Portrait z_index to defaults:
		"§hide":
			var reset_box: Variant			= resolve_value(command_value.get("Box", "1"))
			var reset_portrait: Variant		= resolve_value(command_value.get("Portrait", "1"))

			#@ Apply resets safely:
			if reset_box == 1:
				if has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
				if has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
				if has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z
				if has_node(ui_elements_paths["barks_path"]):
					get_node(ui_elements_paths["barks_path"]).z_index = get_node(ui_elements_paths["barks_path"]).default_z

			if reset_portrait == 1:
				if has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			return "Continue"


		#* §Clear - Clear the dialogue UI (text, speaker name, portrait, busts, background):
		"§clear":
			var clear_dialogue_box: Variant		= resolve_value(command_value.get("Box", "1"))
			var clear_bubbles: Variant			= resolve_value(command_value.get("Bubbles", "1"))
			var clear_subtitles: Variant		= resolve_value(command_value.get("Subtitles", "1"))
			var clear_portraits: Variant		= resolve_value(command_value.get("Portraits", "1"))
			var clear_bg: Variant				= resolve_value(command_value.get("Backgrounds", "1"))
			var clear_busts: Variant			= resolve_value(command_value.get("Busts", "1"))

			#@ Step 1 - Clear dialogue box:
			if clear_dialogue_box == "1" and ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
				var box = get_node(ui_elements_paths["dialogue_box_path"])
				box.visible = false
				if "speaker_node" in box: box.speaker_node.text = ""
				if "dialogue_node" in box: box.dialogue_node.text = ""
				if "default_z" in box: box.z_index = box.default_z

			#@ Step 2 - Clear speech bubbles:
			if clear_bubbles == "1":
				var npc_bubbles = get_node_or_null(bubbles_npc_path)
				var player_bubbles = get_node_or_null(bubbles_player_path)
				if npc_bubbles:
					for actor in npc_bubbles.get_children():
						if "Speech_Bubble" in actor.internal_node_dict:
							actor.internal_node_dict["Speech_Bubble"].clear()
				if player_bubbles:
					for actor in player_bubbles.get_children():
						if "Speech_Bubble" in actor.internal_node_dict:
							actor.internal_node_dict["Speech_Bubble"].clear()

			#@ Step 3 - Clear subtitles:
			if clear_subtitles == "1" and ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
				var subs = get_node(ui_elements_paths["subtitles_path"])
				subs.visible = false
				if "dialogue_node" in subs:
					subs.dialogue_node.text = ""
				if "default_z" in subs:
					subs.z_index = subs.default_z

			#@ Step 4 - Clear portraits:
			if clear_portraits == "1" and ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
				var portrait = get_node(ui_elements_paths["portrait_path"])
				portrait.visible = false
				if "portrait_node" in portrait:
					portrait.portrait_node.texture = null
				if "default_z" in portrait:
					portrait.z_index = portrait.default_z

			#@ Step 5 - Clear VN busts:
			if clear_busts == "1" and ui_elements_paths.has("busts_path"):
				var busts_root = get_node_or_null(ui_elements_paths["busts_path"])
				if busts_root and "busts" in busts_root:
					var busts = busts_root.busts
					for child in busts.get_children():
						child.visible = false
						if "texture_normal" in child:
							child.texture_normal = null
						elif "texture" in child:
							child.texture = null
						if "flip_h" in child:
							child.flip_h = false
					#% Clear bust positions:
					bust_positions.clear()

			#@ Step 6 - Clear backgrounds:
			if clear_bg == "1" and ui_elements_paths.has("backgrounds_path"):
				var bg_scene = get_node_or_null(ui_elements_paths["backgrounds_path"])
				if bg_scene and "backgrounds" in bg_scene:
					var bg_parent = bg_scene.bg_container
					var bg_tree = bg_scene.get("animation_tree") if bg_scene.has_method("get") else null
					var bg_player = bg_scene.get("animation_player") if bg_scene.has_method("get") else null

					if bg_tree:
						bg_tree.active = false
						for child in bg_tree.get_children():
							if child is AnimationPlayer:
								child.stop()

					if bg_player:
						bg_player.stop()

					for bg in bg_parent.get_children():
						for child in bg.get_children():
							if child is AnimationPlayer:
								child.stop()
						if "texture" in bg:
							bg.texture = null
						if "sprite_frames" in bg:
							bg.stop()
							bg.sprite_frames = null

			#@ Step 7 - Clear barks:
			#? Always cleared.
			if ui_elements_paths.has("barks_path") and has_node(ui_elements_paths["barks_path"]):
				var bark_node = get_node(ui_elements_paths["barks_path"])
				bark_node.visible = false
				if "dialogue_node" in bark_node:
					bark_node.dialogue_node.text = ""
				if "default_z" in bark_node:
					bark_node.z_index = bark_node.default_z

			return "Continue"
		#endregion - vfx commands


		#&########################################
		#&										##
		#&            IMAGE COMMANDS            ##
		#&										##
		#region - Image Commands
		#* §Image - display a static or animated image:
		"§image":
			var node_name: Variant		= resolve_value(command_value.get("Node", "Image"))
			var image: Variant			= resolve_value(command_value.get("File", ""))
			var animated: Variant		= resolve_value(command_value.get("Animated", 0))
			var duration: Variant		= int(resolve_value(command_value.get("Duration", 0.0)))
			var time_raw: Variant		= resolve_value(command_value.get("Time", "0"))
			var wait: Variant			= int(resolve_value(command_value.get("Wait", "0")))
			var loop: Variant			= int(resolve_value(command_value.get("Loop", "1")))
			var show_box: Variant		= resolve_value(command_value.get("Box", -1))
			var show_portrait: Variant	= resolve_value(command_value.get("Portrait", -1))

			#@ Step 1 - Resolve image player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])
			if not player_node:
				printerr("§Image: invalid image node → ", node_name)
				return "Continue"

			#@ Step 2 - Configure image / animation:
			if animated == 1:
				var animation_path = candy_de.image_folder.path_join(node_name).path_join("Animated").path_join(image)
				var fps_value: float = candy_de.animated_image_fps
				if duration > 0:
					fps_value = float(duration)
				player_node.setup_animation(str(animation_path), fps_value, loop)
			elif animated == 0:
				var image_path = candy_de.image_folder.path_join(node_name).path_join(image).path_join(player_node.default_image_extension)
				player_node.setup_static(str(image_path), float(duration), loop)
			player_node.visible = true

			#@ Step 3 - Adjust z-index:
			if show_box == 1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = player_node.z_index + 1
			elif show_box == -1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z

			if show_portrait == 1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = player_node.z_index + 1
			elif show_portrait == -1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			#@ Step 4 - Start playback:
			active_media_players.append(player_node)
			player_node.start()

			#@ Step 5 - Optional blocking wait (Time + Wait):
			if wait != -1 or time_raw != "":
				var target_seconds: float = 0.0
				if typeof(time_raw) == TYPE_STRING:
					var s = time_raw.strip_edges()
					if s != "":
						var parts = s.split(":")
						match parts.size():
							3:
								target_seconds = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
							2:
								target_seconds = int(parts[0]) * 60 + float(parts[1])
							1:
								target_seconds = float(parts[0])
				elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
					target_seconds = float(time_raw)

				#% Calculate duration per loop:
				var media_length: float = player_node.static_duration
				if player_node.animated and player_node.fps > 0:
					media_length = float(player_node.frames.size()) / player_node.fps
				if media_length <= 0.0:
					media_length = 1.0

				var total_seconds = target_seconds
				var loop_offset = int(total_seconds / media_length)
				var offset_time = total_seconds - (loop_offset * media_length)
				var target_loop = loop_offset
				if wait > 0:
					target_loop += int(wait)

				var elapsed := 0.0
				while player_node in active_media_players:
					if loop > 0 and player_node.loops_played >= loop:
						break
					if player_node.loops_played > target_loop:
						break
					if player_node.loops_played == target_loop and elapsed >= offset_time:
						break
					await get_tree().process_frame
					elapsed += get_process_delta_time()

			return "Continue"


		#* §I_Wait - Pause dialogue until image has displayed for a given time or loops:
		"§i_wait":
			#@ Step 1 - Resolve parameters:
			var node_name: Variant		= resolve_value(command_value.get("Node", "Image"))
			var time_raw: Variant		= resolve_value(command_value.get("Time", "0"))
			var wait: Variant			= int(resolve_value(command_value.get("Wait", "0")))
			var show_box: Variant		= resolve_value(command_value.get("Box", -1))
			var show_portrait: Variant	= resolve_value(command_value.get("Portrait", -1))

			#@ Step 2 - Get image player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])
			if not player_node:
				printerr("§I_Wait: invalid image node → ", node_name)
				return "Continue"

			#@ Step 3 - Parse target time:
			var target_seconds: float = 0.0
			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					var parts = s.split(":")
					match parts.size():
						3:
							target_seconds = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
						2:
							target_seconds = int(parts[0]) * 60 + float(parts[1])
						1:
							target_seconds = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				target_seconds = float(time_raw)

			#@ Step 4 - Determine per-loop duration:
			var media_length: float = player_node.static_duration
			if player_node.animated and player_node.fps > 0:
				media_length = float(player_node.frames.size()) / player_node.fps
			if media_length <= 0.0:
				media_length = 1.0

			var total_seconds = target_seconds
			var loop_offset = int(total_seconds / media_length)
			var offset_time = total_seconds - (loop_offset * media_length)
			var target_loop = loop_offset
			if wait > 0:
				target_loop += int(wait)

			#@ Step 5 - Wait until elapsed time and loop reached:
			var elapsed := 0.0
			while player_node in active_media_players:
				if player_node.loop_target > 0 and player_node.loops_played >= player_node.loop_target:
					break
				if player_node.loops_played > target_loop:
					break
				if player_node.loops_played == target_loop and elapsed >= offset_time:
					break
				await get_tree().process_frame
				elapsed += get_process_delta_time()

			#@ Step 6 - Overlay reset:
			if show_box == 1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = player_node.z_index + 1
			elif show_box == -1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z

			if show_portrait == 1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = player_node.z_index + 1
			elif show_portrait == -1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			return "Continue"


		#* §I_Pause - Pause image timer for a given number of lines:
		"§i_pause":
			#@ Step 1 - Resolve parameters:
			var line_count: Variant		= resolve_value(command_value.get("Lines", -1))
			var count_all: Variant		= resolve_value(command_value.get("All", 0))
			var show_box: Variant		= resolve_value(command_value.get("Box", -1))
			var show_portrait: Variant	= resolve_value(command_value.get("Portrait", -1))
			var node_name: Variant		= resolve_value(command_value.get("Node", "Image"))

			#@ Step 2 - Get target image node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])
			if not player_node or not player_node.has_node("Timer"):
				printerr("§IPause: invalid image node → ", node_name)
				return "Continue"

			#@ Step 3 - Pause image timer:
			var timer_node = player_node.get_node("Timer")
			timer_node.paused = true

			#@ Step 4 - Store pause info:
			player_node.pause_count = int(line_count)
			if int(line_count) > 0:
				if count_all == 0:
					player_node.pause_mode = "speech"
					player_node.pause_count = int(line_count)
				elif count_all == 1:
					player_node.pause_mode = "all"
					player_node.pause_count = int(line_count) + 1	#/ This command will decrement by 1 → add 1 to compensate.

			#@ Step 5 - Adjust z-index:
			if show_box == 1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = player_node.z_index + 1
			elif show_box == -1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z

			if show_portrait == 1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = player_node.z_index + 1
			elif show_portrait == -1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			return "Continue"


		#* §I_Resume - Resume image timer immediately, cancel any active §IPause:
		"§i_resume":
			#@ Step 1 - Resolve parameters:
			var show_box: Variant		= resolve_value(command_value.get("Box", -1))
			var show_portrait: Variant	= resolve_value(command_value.get("Portrait", -1))
			var node_name: Variant		= resolve_value(command_value.get("Node", "Image"))

			#@ Step 2 - Get target image node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])
			if not player_node:
				printerr("§I_Resume: invalid image node → ", node_name)
				return "Continue"

			#@ Step 3 - Resume timer:
			if player_node.has_method("unpause"):
				player_node.unpause()
			elif player_node.has_node("Timer"):
				player_node.get_node("Timer").paused = false

			#@ Step 4 - Reset pause parameters:
			player_node.pause_count = 0
			player_node.pause_mode = "speech"
			player_node.pause_re_wait = false

			#@ Step 5 - Adjust overlay Z:
			if show_box == 1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = player_node.z_index + 1
			elif show_box == -1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z

			if show_portrait == 1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = player_node.z_index + 1
			elif show_portrait == -1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			return "Continue"


		#* §I_Stop - Stop and hide the image immediately:
		"§i_stop":
			#@ Step 1 - Resolve target node:
			var node_name: Variant		= resolve_value(command_value.get("Node", "Image"))

			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			if not player_node:
				printerr("§I_Stop: invalid image node → ", node_name)
				return "Continue"

			#@ Step 2 - Force stop and reset:
			if player_node.has_method("reset"):
				player_node.reset()
			else:
				if player_node.has_node("Timer"):
					player_node.get_node("Timer").stop()
				if "texture" in player_node:
					player_node.image_player.texture = null
				elif "texture_normal" in player_node:
					player_node.image_player.texture_normal = null
				player_node.visible = false
				active_media_players.erase(player_node)

			#@ Step 3 - Reset overlays to default Z:
			if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
				get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
			if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
				get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
			if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
				get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z
			if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
				get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			return "Continue"


		#* §I_Show - Raise Dialogue Box / Portrait above the image:
		"§i_show":
			#@ Step 1 - Resolve parameters:
			var show_box: Variant		= resolve_value(command_value.get("Box", -1))
			var show_portrait: Variant	= resolve_value(command_value.get("Portrait", -1))
			var node_name: Variant		= resolve_value(command_value.get("Node", "Image"))

			#@ Step 2 - Get the target display node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			#@ Step 3 - Apply z-index adjustments:
			if show_box == 1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = player_node.z_index + 1
			elif show_box == -1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z

			if show_portrait == 1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = player_node.z_index + 1
			elif show_portrait == -1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			return "Continue"
		#endregion - image commands


		#&########################################
		#&										##
		#&            AUDIO COMMANDS            ##
		#&										##
		#region - audio Commands
		#* §Audio - Play a audio file and optionally wait for a specific time and loop:
		"§audio":
			var file_raw: Variant	= resolve_value(command_value.get("File", ""))
			var time_raw: Variant	= resolve_value(command_value.get("Time", "0"))
			var wait: Variant		= int(resolve_value(command_value.get("Wait", "0")))
			var loop: Variant		= int(resolve_value(command_value.get("Loop", "1")))
			var node_name: Variant	= resolve_value(command_value.get("Node", "Sound"))

			#@ Step 1 - Resolve player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			if not player_node:
				printerr("§Audio: missing or invalid player node → ", node_name)
				return "Continue"

			#@ Step 2 - Get the audio stream:
			var stream
			if file_raw is AudioStream:
				#% Already resolved and loaded by resolve_value():
				stream = file_raw
			else:
				#% Construct path from string:
				var path: String
				if str(file_raw).begins_with("res://"):
					path = str(file_raw) if str(file_raw).find(".") != -1 else str(file_raw) + player_node.default_audio_extension
				else:
					var base_name = str(file_raw).strip_edges()
					if base_name.find(".") == -1:
						path = candy_de.audio_folder.path_join(str(node_name)).path_join(base_name + player_node.default_audio_extension)
					else:
						path = candy_de.audio_folder.path_join(str(node_name)).path_join(base_name)

				if not ResourceLoader.exists(path):
					printerr("§Audio: missing or invalid path → ", path)
					return "Continue"

				stream = load(path)

			if stream == null:
				printerr("§Audio: failed to load stream → ", file_raw)
				return "Continue"

			player_node.audio_player.stream = stream

			#@ Step 3 - Assign loop tracking:
			player_node.loop_target = loop
			player_node.wait_target = -1
			player_node.loops_played = 0

			#@ Step 4 - Parse time input (HH:MM:SS.xx):
			var target_seconds: float = 0.0
			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					var parts = s.split(":")
					match parts.size():
						3:
							target_seconds = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
						2:
							target_seconds = int(parts[0]) * 60 + float(parts[1])
						1:
							target_seconds = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				target_seconds = float(time_raw)

			#@ Step 5 - Start playback:
			player_node.audio_player.play()
			active_media_players.append(player_node)

			#@ Step 6 - Optional blocking wait until time/loop reached:
			if wait != -1 or time_raw != "":
				var media_length: float = stream.get_length()
				if media_length <= 0.0:
					media_length = 1.0

				var total_seconds = target_seconds
				var loop_offset = int(total_seconds / media_length)
				var offset_time = total_seconds - (loop_offset * media_length)
				var target_loop = loop_offset
				if wait > 0:
					target_loop += int(wait)

				while player_node in active_media_players:
					if loop > 0 and player_node.loops_played >= loop:
						break
					if player_node.loops_played > target_loop:
						break
					if player_node.loops_played == target_loop and player_node.audio_player.get_playback_position() >= offset_time:
						break
					await get_tree().process_frame

			return "Continue"


		#* §A_Wait - Block dialogue until audio reaches a timestamp or loop (with carryover):
		"§a_wait":
			var time_raw: Variant	= resolve_value(command_value.get("Time","0.0"))
			var wait: Variant		= int(resolve_value(command_value.get("Wait", "1")))
			var node_name: Variant	= resolve_value(command_value.get("Node", "Sound"))

			#@ Step 1 - Get the target audio node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			if not player_node or not ("stream" in player_node.audio_player) or player_node.audio_player.stream == null:
				printerr("§A_Wait: invalid or missing audio node → ", node_name)
				return "Continue"

			var audio_stream = player_node.audio_player.stream

			#@ Step 2 - Parse time (HH:MM:SS.xx):
			var target_seconds: float = 0.0
			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					var parts = s.split(":")
					match parts.size():
						3:
							target_seconds = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
						2:
							target_seconds = int(parts[0]) * 60 + float(parts[1])
						1:
							target_seconds = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				target_seconds = float(time_raw)

			#@ Step 3 - Compute loop carryover:
			var media_length: float = audio_stream.get_length()
			if media_length <= 0.0:
				media_length = 1.0

			var total_seconds = target_seconds
			var loop_offset = int(total_seconds / media_length)
			var offset_time = total_seconds - (loop_offset * media_length)
			var target_loop = loop_offset
			if wait > 0:
				target_loop += int(wait)

			#@ Step 4 - Wait until target loop/time or until playback ends:
			while player_node.audio_player.stream:
				if player_node.loop_target > 0 and player_node.loops_played >= player_node.loop_target:
					break
				if player_node.loops_played > target_loop:
					break
				if player_node.loops_played == target_loop and player_node.audio_player.get_playback_position() >= offset_time:
					break
				await get_tree().process_frame

			return "Continue"


		#* §A_Volume - Adjust volume of a audio player:
		"§a_volume":
			var value: Variant     = resolve_value(command_value.get("Volume", "0.0"))
			var node_name: Variant = resolve_value(command_value.get("Node", "Sound"))
			var time: Variant      = resolve_value(command_value.get("Time", "0.0"))

			#@ Step 1 - Determine modification method (absolute or relative):
			var modifier = ""
			if value.begins_with("+") or value.begins_with("-"):
				modifier = "relative"
			else:
				modifier = "absolute"

			#@ Step 2 - Get the target audio player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			#@ Step 3 - Parse time value and check for "!" blocking prefix:
			var blocking = false
			var time_str = str(time)
			if time_str.begins_with("!"):
				blocking = true
				time_str = time_str.substr(1)
			var time_value = float(time_str)

			#@ Step 4 - Apply volume change:
			if player_node and "volume_db" in player_node.audio_player:
				var target_volume: float
				if modifier == "absolute":
					target_volume = float(value)
				elif modifier == "relative":
					target_volume = player_node.audio_player.volume_db + float(value)
				else:
					printerr("§A_Volume: invalid modifier")
					return "Continue"

				#% Progressive volume change via tween:
				if time_value > 0.0:
					var tween = player_node.create_tween()
					tween.tween_property(player_node.audio_player, "volume_db", target_volume, time_value)
					if blocking:
						await tween.finished
				else:
					#% Instant volume change:
					player_node.audio_player.volume_db = target_volume
			else:
				printerr("§A_Volume: invalid or missing player node → ", node_name)

			return "Continue"


		#* §A_Pause - pause audio playback for a given number of lines:
		"§a_pause":
			var line_count: Variant		= resolve_value(command_value.get("Lines", -1))
			var count_all: Variant		= resolve_value(command_value.get("All", 0))
			var node_name: Variant		= resolve_value(command_value.get("Node", "Sound"))

			#@ Step 1 - Get the target audio player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])
			if not player_node:
				printerr("§A_Pause: audio node not found → ", node_name)
				return "Continue"

			#@ Step 2 - Pause playback:
			if "stream_paused" in player_node.audio_player:
				player_node.audio_player.stream_paused = true
			else:
				printerr("§A_Pause: node type does not support pausing → ", node_name)
				return "Continue"

			#@ Step 3 - Store pause parameters:
			player_node.pause_count = int(line_count)
			if int(line_count) > 0:
				if count_all == 0:
					player_node.pause_mode = "speech"
					player_node.pause_count = int(line_count)
				elif count_all == 1:
					player_node.pause_mode = "all"
					player_node.pause_count = int(line_count) + 1	#/ This command will decrement by 1 → add 1 to compensate.

			return "Continue"


		#* §A_Resume - resume paused audio immediately:
		"§a_resume":
			var node_name: Variant	= resolve_value(command_value.get("Node", "Sound"))

			#@ Step 1 - Get the target audio player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])
			if not player_node:
				printerr("§A_Resume: audio node not found → ", node_name)
				return "Continue"

			#@ Step 2 - Resume playback:
			if "stream_paused" in player_node.audio_player:
				player_node.audio_player.stream_paused = false
			elif "unpause" in player_node:
				player_node.unpause()
			else:
				printerr("§A_Resume: node type does not support resuming → ", node_name)
				return "Continue"

			#@ Step 3 - Reset pause parameters:
			player_node.pause_count = 0
			player_node.pause_mode = "speech"
			player_node.pause_re_wait = false

			return "Continue"


		#* §A_Skip - Jump to a specific timestamp:
		"§a_skip":
			var time_raw: Variant	= resolve_value(command_value.get("Time", 0.0))
			var node_name: Variant	= resolve_value(command_value.get("Node", "Sound"))

			#@ Step 1 - Get the target audio player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			#@ Step 2 - Validate node and stream:
			if not player_node or not ("stream" in player_node.audio_player) or player_node.audio_player.stream == null:
				printerr("§A_Skip: invalid or inactive audio node → ", node_name)
				return "Continue"

			#@ Step 3 - Convert time input to seconds:
			var target_time: float = 0.0
			var relative := false
			var direction := 1

			if typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				target_time = float(time_raw)
			elif typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s.begins_with("+"):
					relative = true
					direction = 1
					s = s.substr(1).strip_edges()
				elif s.begins_with("-"):
					relative = true
					direction = -1
					s = s.substr(1).strip_edges()

				if s != "":
					var parts = s.split(":")
					match parts.size():
						3:
							target_time = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
						2:
							target_time = int(parts[0]) * 60 + float(parts[1])
						1:
							target_time = float(parts[0])

				if relative:
					var current_pos: float = player_node.audio_player.get_playback_position()
					target_time = max(0.0, current_pos + direction * target_time)

			#@ Step 4 - Seek to target position (if supported):
			if "seek" in player_node.audio_player:
				player_node.audio_player.seek(target_time)
			elif "set_playback_position" in player_node.audio_player:
				player_node.audio_player.set_playback_position(target_time)
			else:
				printerr("§A_Skip: node type does not support seeking → ", node_name)

			return "Continue"


		#* §A_Stop - Stop audio immediately and clear related waits:
		"§a_stop":
			var node_name: Variant	= resolve_value(command_value.get("Node", "Sound"))

			#@ Step 1 - Get the target audio player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			if not player_node:
				printerr("§A_Stop: audio node not found → ", node_name)
				return "Continue"

			#@ Step 2 - Force-stop and reset player:
			if "reset" in player_node:
				player_node.reset()
			elif "stop" in player_node.audio_player:
				player_node.audio_player.stop()
			else:
				printerr("§A_Stop: node type does not support stop/reset → ", node_name)

			#@ Step 3 - Ensure dialogue is unblocked:
			active_media_players.erase(player_node)

			return "Continue"
		#endregion - audio commands


		#&########################################
		#&										##
		#&            VIDEO COMMANDS            ##
		#&										##
		#region - Video Commands
		#* §Video - Play a video file and optionally wait for a specific time and loop:
		"§video":
			var video_name: Variant		= resolve_value(command_value.get("File", ""))
			var time_raw: Variant		= resolve_value(command_value.get("Time", ""))
			var wait: Variant			= int(resolve_value(command_value.get("Wait", "0")))
			var loop: Variant			= int(resolve_value(command_value.get("Loop", "1")))
			var show_box: Variant		= resolve_value(command_value.get("Box", -1))
			var show_portrait: Variant	= resolve_value(command_value.get("Portrait", -1))
			var node_name: Variant		= resolve_value(command_value.get("Node", "Video"))

			var default_fps: float = 30.0

			#@ Step 1 - Resolve the video player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			if not player_node:
				printerr("§Video: missing or invalid player node → ", node_name)
				return "Continue"

			player_node.visible = true

			#@ Step 2 - Get the video stream:
			var stream
			if video_name is VideoStream:
				#% Already resolved by resolve_value():
				stream = video_name
			else:
				#% Construct path from string:
				var path: String
				if str(video_name).begins_with("res://"):
					path = str(video_name) if str(video_name).find(".") != -1 else str(video_name) + player_node.default_video_extension
				else:
					var file_name = str(video_name)
					if file_name.find(".") == -1:
						path = candy_de.video_folder.path_join(str(node_name)).path_join(file_name + player_node.default_video_extension)
					else:
						path = candy_de.video_folder.path_join(str(node_name)).path_join(file_name)

				stream = load(path)

			if not (stream is VideoStream):
				printerr("§Video: invalid or missing video stream → ", video_name)
				return "Continue"

			player_node.video_player.stream = stream

			#@ Step 3 - Assign loop tracking:
			player_node.loop_target = loop
			player_node.wait_target = -1
			player_node.loops_played = 0

			#@ Step 4 - Parse the time or frame input:
			var target_seconds: float = 0.0
			if typeof(time_raw) == TYPE_STRING and (time_raw.begins_with("f=") or time_raw.begins_with("F=")):
				var frame_val = float(time_raw.substr(2, time_raw.length()))
				var fps = stream.fps if "fps" in stream and stream.fps > 0 else default_fps
				target_seconds = frame_val / fps
			elif typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					var parts = s.split(":")
					match parts.size():
						3:
							target_seconds = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
						2:
							target_seconds = int(parts[0]) * 60 + float(parts[1])
						1:
							target_seconds = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				target_seconds = float(time_raw)

			#@ Step 5 - Adjust z-index overlays:
			if show_box == 1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = player_node.z_index + 1
			elif show_box == -1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z

			if show_portrait == 1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = player_node.z_index + 1
			elif show_portrait == -1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			#@ Step 6 - Start playback:
			player_node.video_player.play()
			active_media_players.append(player_node)

			#@ Step 7 - Optional wait until time / loop:
			if wait != -1 or time_raw != "":
				#% Video streams don’t expose duration - track manually:
				var fallback_max := 600.0	#/ assume max 10 min if unknown (safety net)

				#% We’ll estimate total_seconds directly from parsed time:
				var total_seconds = target_seconds
				var target_loop = max(loop - 1, 0) if loop > 0 else 0
				var offset_time = total_seconds

				#% Wait until target loop/time:
				while player_node in active_media_players:
					#% Stop waiting if it’s stopped:
					if not player_node.video_player.is_playing():
						break

					#% Simulate loop tracking (you probably increment loops_played elsewhere):
					if loop > 0 and player_node.loops_played >= loop:
						break

					#% Check elapsed time manually:
					if player_node.loops_played == target_loop and player_node.video_player.stream_position >= offset_time:
						break

					#% Emergency cutoff (in case duration unknown):
					if player_node.video_player.stream_position > fallback_max:
						break

					await get_tree().process_frame

			return "Continue"


		#* §V_Volume - Adjust volume of a video player:
		"§v_volume":
			var value: Variant     = resolve_value(command_value.get("Volume", "0.0"))
			var node_name: Variant = resolve_value(command_value.get("Node", "Video"))
			var time: Variant      = resolve_value(command_value.get("Time", "0.0"))

			#@ Step 1 - Determine modification method (absolute or relative):
			var modifier = ""
			if value.begins_with("+") or value.begins_with("-"):
				modifier = "relative"
			else:
				modifier = "absolute"

			#@ Step 2 - Get the target audio player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			#@ Step 3 - Parse time value and check for "!" blocking prefix:
			var blocking = false
			var time_str = str(time)
			if time_str.begins_with("!"):
				blocking = true
				time_str = time_str.substr(1)
			var time_value = float(time_str)

			#@ Step 4 - Apply volume change:
			if player_node and "volume_db" in player_node.video_player:
				var target_volume: float
				if modifier == "absolute":
					target_volume = float(value)
				elif modifier == "relative":
					target_volume = player_node.video_player.volume_db + float(value)
				else:
					printerr("§V_Volume: invalid modifier")
					return "Continue"

				#% Progressive volume change via tween:
				if time_value > 0.0:
					var tween = player_node.create_tween()
					tween.tween_property(player_node.video_player, "volume_db", target_volume, time_value)
					if blocking:
						await tween.finished
				else:
					#% Instant volume change:
					player_node.video_player.volume_db = target_volume
			else:
				printerr("§V_Volume: invalid or missing player node → ", node_name)

			return "Continue"


		#* §V_Wait - Block dialogue until a specific timestamp or frame (with loop carryover):
		"§v_wait":
			var node_name: Variant		= resolve_value(command_value.get("Node", "Video"))
			var time_raw: Variant		= resolve_value(command_value.get("Time", "0.0"))
			var wait: Variant			= int(resolve_value(command_value.get("Wait", "0")))
			var show_box: Variant		= resolve_value(command_value.get("Box", -1))
			var show_portrait: Variant	= resolve_value(command_value.get("Portrait", -1))

			var default_fps: float = 30.0

			#@ Step 1 - Get target nodev:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			if not player_node or not ("stream" in player_node.video_player) or player_node.video_player.stream == null:
				printerr("§V_Wait: invalid or missing video node → ", node_name)
				return "Continue"

			var stream = player_node.video_player.stream

			#@ Step 2 - Parse time or frame input:
			var target_seconds: float = 0.0
			if typeof(time_raw) == TYPE_STRING and (time_raw.begins_with("f=") or time_raw.begins_with("F=")):
				var frame_val = float(time_raw.substr(2, time_raw.length()))
				var fps = stream.fps if "fps" in stream and stream.fps > 0 else default_fps
				target_seconds = frame_val / fps
			elif typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					var parts = s.split(":")
					match parts.size():
						3:
							target_seconds = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
						2:
							target_seconds = int(parts[0]) * 60 + float(parts[1])
						1:
							target_seconds = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				target_seconds = float(time_raw)

			#@ Step 3 - Compute loop carryover:
			var media_length: float = stream.get_length()
			if media_length <= 0.0:
				media_length = 1.0

			var total_seconds = target_seconds
			var loop_offset = int(total_seconds / media_length)
			var offset_time = total_seconds - (loop_offset * media_length)
			var target_loop = loop_offset
			if wait > 0:
				target_loop += int(wait)

			#@ Step 4 - Wait until target loop/time or until playback ends:
			while player_node.video_player.stream:
				if player_node.loop_target > 0 and player_node.loops_played >= player_node.loop_target:
					break
				if player_node.loops_played > target_loop:
					break
				if player_node.loops_played == target_loop and player_node.video_player.stream_position >= offset_time:
					break
				await get_tree().process_frame

			#@ Step 5 - Overlay z_index restoration:
			if show_box == 1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = player_node.z_index + 1
			elif show_box == -1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z

			if show_portrait == 1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = player_node.z_index + 1
			elif show_portrait == -1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			return "Continue"


		#* §V_Pause - Pause video playback for a given number of lines:
		"§v_pause":
			var line_count: Variant		= resolve_value(command_value.get("Lines", -1))
			var count_all: Variant		= resolve_value(command_value.get("All", 0))
			var show_box: Variant		= resolve_value(command_value.get("Box", -1))
			var show_portrait: Variant	= resolve_value(command_value.get("Portrait", -1))
			var node_name: Variant		= resolve_value(command_value.get("Node", "Video"))

			#@ Step 1 - Get the target video player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])
			if not player_node:
				printerr("§VPause: video node not found → ", node_name)
				return "Continue"

			#@ Step 2 - Pause playback:
			if "paused" in player_node.video_player:
				player_node.video_player.paused = true
			else:
				printerr("§VPause: node type does not support pausing → ", node_name)
				return "Continue"

			#@ Step 3 - Store pause parameters:
			player_node.pause_count = int(line_count)
			if int(line_count) > 0:
				if count_all == 0:
					player_node.pause_mode = "speech"
					player_node.pause_count = int(line_count)
				elif count_all == 1:
					player_node.pause_mode = "all"
					player_node.pause_count = int(line_count) + 1	#/ This command will decrement by 1 → add 1 to compensate.

			#@ Step 4 - Adjust overlays (z_index):
			if show_box == 1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = player_node.z_index + 1
			elif show_box == -1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z

			if show_portrait == 1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = player_node.z_index + 1
			elif show_portrait == -1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			return "Continue"


		#* §V_Resume - Resume paused video immediately:
		"§v_resume":
			var node_name: Variant		= resolve_value(command_value.get("Node", "Video"))
			var show_box: Variant		= resolve_value(command_value.get("Box", -1))
			var show_portrait: Variant	= resolve_value(command_value.get("Portrait", -1))

			#@ Step 1 - Get the target video player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])
			if not player_node:
				printerr("§V_Resume: video node not found → ", node_name)
				return "Continue"

			#@ Step 2 - Resume playback:
			if "paused" in player_node.video_player:
				player_node.video_player.paused = false
			elif "unpause" in player_node:
				player_node.unpause()
			else:
				printerr("§V_Resume: node type does not support pausing → ", node_name)
				return "Continue"

			#@ Step 3 - Reset pause parameters:
			player_node.pause_count = 0
			player_node.pause_mode = "speech"
			player_node.pause_re_wait = false

			#@ Step 4 - Adjust overlays (z_index):
			if show_box == 1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = player_node.z_index + 1
			elif show_box == -1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z

			if show_portrait == 1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = player_node.z_index + 1
			elif show_portrait == -1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			return "Continue"


		#* §V_Skip - Jump video to a specific timestamp or frame (supports f= syntax):
		"§v_skip":
			var node_name: Variant	= resolve_value(command_value.get("Node", "Video"))
			var time_raw: Variant	= resolve_value(command_value.get("Time", 0.0))

			var target_time: float = 0.0
			var default_fps: float = 30.0	#/ fallback if fps unavailable

			#@ Step 1 - Get the target video player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			if not player_node or not ("stream" in player_node.video_player) or player_node.video_player.stream == null:
				printerr("§V_Skip: invalid or missing video node → ", node_name)
				return "Continue"

			#@ Step 2 - Parse Time value (HH:MM:SS.xx or f=frames):
			var relative := false
			var direction := 1

			if typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				target_time = float(time_raw)
			elif typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()

				if s.begins_with("+"):
					relative = true
					direction = 1
					s = s.substr(1).strip_edges()
				elif s.begins_with("-"):
					relative = true
					direction = -1
					s = s.substr(1).strip_edges()

				if s == "":
					target_time = 0.0
				elif s.begins_with("f=") or s.begins_with("F="):
					var frame_val = float(s.substr(2))
					var fps := default_fps
					if "fps" in player_node.video_player.stream and player_node.video_player.stream.fps > 0:
						fps = player_node.video_player.stream.fps
					target_time = frame_val / fps
				else:
					var parts = s.split(":")
					match parts.size():
						3:
							target_time = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
						2:
							target_time = int(parts[0]) * 60 + float(parts[1])
						1:
							target_time = float(parts[0])

				if relative:
					var current_pos: float = 0.0
					if "stream_position" in player_node.video_player:
						current_pos = player_node.video_player.stream_position
					elif "get_playback_position" in player_node.video_player:
						current_pos = player_node.video_player.get_playback_position()
					target_time = max(0.0, current_pos + direction * target_time)

			#@ Step 3 - Perform seek if valid:
			if "stream_position" in player_node.video_player:
				player_node.video_player.stream_position = target_time
			elif "seek" in player_node.video_player:
				player_node.video_player.seek(target_time)
			else:
				printerr("§V_Skip: node type does not support seeking → ", node_name)

			return "Continue"


		#* §V_Stop - Stop the current video immediately and clear related waits:
		"§v_stop":
			var node_name: Variant	= resolve_value(command_value.get("Node", "Video"))

			#@ Step 1 - Get the target video player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			if not player_node:
				printerr("§V_Stop: video node not found → ", node_name)
				return "Continue"

			#@ Step 2 - Force-stop and reset player:
			if "reset" in player_node:
				player_node.reset()
			elif "stop" in player_node.video_player:
				player_node.video_player.stop()
			else:
				printerr("§V_Stop: node type does not support stop/reset → ", node_name)

			#@ Step 3 - Ensure dialogue is unblocked:
			active_media_players.erase(player_node)

			#@ Step 4 - Reset overlays to defaults:
			if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
				get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
			if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
				get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
			if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
				get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z
			if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
				get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			return "Continue"


		#* §V_Show - Raise Dialogue Box / Portrait above the video:
		"§v_show":
			var show_box: Variant		= resolve_value(command_value.get("Box", -1))
			var show_portrait: Variant	= resolve_value(command_value.get("Portrait", -1))
			var node_name: Variant		= resolve_value(command_value.get("Node", "Video"))

			#@ Step 1 - Get the target video player node:
			var player_node
			if node_name is Node:
				player_node = node_name
			else:
				player_node = get_node(media_players_locations[str(node_name)])

			if not player_node:
				printerr("§V_Show: video node not found → ", node_name)
				return "Continue"

			#@ Step 2 - Apply z_index adjustments:
			if show_box == 1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = player_node.z_index + 1
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = player_node.z_index + 1
			elif show_box == -1:
				if ui_elements_paths.has("dialogue_box_path") and has_node(ui_elements_paths["dialogue_box_path"]):
					get_node(ui_elements_paths["dialogue_box_path"]).z_index = get_node(ui_elements_paths["dialogue_box_path"]).default_z
				if ui_elements_paths.has("subtitles_path") and has_node(ui_elements_paths["subtitles_path"]):
					get_node(ui_elements_paths["subtitles_path"]).z_index = get_node(ui_elements_paths["subtitles_path"]).default_z
				if ui_elements_paths.has("chat_path") and has_node(ui_elements_paths["chat_path"]):
					get_node(ui_elements_paths["chat_path"]).z_index = get_node(ui_elements_paths["chat_path"]).default_z

			if show_portrait == 1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = player_node.z_index + 1
			elif show_portrait == -1:
				if ui_elements_paths.has("portrait_path") and has_node(ui_elements_paths["portrait_path"]):
					get_node(ui_elements_paths["portrait_path"]).z_index = get_node(ui_elements_paths["portrait_path"]).default_z

			return "Continue"
		#endregion - video commands


		#&########################################
		#&										##
		#&             VN COMMANDS              ##
		#&										##
		#region - VN Commands
		#* §VN_Scene - Replace the current VN bust scene with a new one:
		"§vn_scene":
			if vn_mode != true:
				return "Continue"

			var scene_name: String	= resolve_value(str(command_value.get("Scene", "")).strip_edges())

			#@ Step 1 - remove existing Busts scene if present:
			var old_busts = get_node_or_null(ui_elements_paths["busts_path"])
			if old_busts:
				old_busts.queue_free()
				await get_tree().process_frame

			#@ Step 2 - Clear VN state:
			bust_positions.clear()
			active_bust_animations.clear()

			#@ Step 3 - resolve scene path (variable, autoload, or direct):
			var scene_path: String = scene_name

			if scene_name.begins_with("res://"):
				scene_path = scene_name
			else:
				scene_path = candy_de.bust_scenes_folder.path_join(scene_name)

			if not scene_path.ends_with(".tscn"):
				scene_path = scene_path + ".tscn"

			#@ Step 4 - load and instantiate the new scene:
			if not ResourceLoader.exists(scene_path):
				return

			var scene_res = load(scene_path)
			if scene_res == null:
				return

			var scene_instance = scene_res.instantiate()
			scene_instance.name = "Busts"
			scene_instance.caller = self
			scene_instance.visible = true
			add_child(scene_instance)

			return "Continue"


		#* §VN_Bust - Assign an actor and image/animation to a bust node:
		"§vn_bust":
			if not vn_mode:
				return

			var bust_name: String	= resolve_value(command_value.get("Bust", "")).strip_edges()
			var actor_ref: String	= resolve_value(command_value.get("Reference", "")).strip_edges()
			var file_ref: String	= resolve_value(command_value.get("File", "Default")).strip_edges()
			var anim_name: String	= resolve_value(command_value.get("Animation", "")).strip_edges()
			var loop_raw: Variant	= resolve_value(command_value.get("Loop", "1"))
			var wait_raw: Variant	= resolve_value(command_value.get("Wait", "0"))
			var time_raw: Variant	= resolve_value(command_value.get("Time", "0"))

			#@ Step 1 - Convert to numbers:
			var loop: int	= int(loop_raw)
			var wait: int	= int(wait_raw)

			#@ Step 2 - Parse Time (same as BG command):
			var time_target: float = 0.0
			var default_fps: float = 30.0
			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s == "":
					time_target = 0.0
				elif s.begins_with("f=") or s.begins_with("F="):
					var frame_val = float(s.substr(2, s.length()))
					time_target = frame_val / default_fps
				else:
					var parts = s.split(":")
					match parts.size():
						3:
							time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
						2:
							time_target = int(parts[0]) * 60 + float(parts[1])
						1:
							time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 3 - Resolve actor role if needed:
			if actor_ref.begins_with(candy_de.role_symbol) and candy_de.roles.has(actor_ref):
				actor_ref = candy_de.roles[actor_ref]

			#@ Step 4 - Determine which bust node to use:
			if bust_name == "":
				if bust_positions.has(actor_ref):
					bust_name = bust_positions[actor_ref]["pos"]
				else:
					printerr("§VNBust: Missing Bust name and no previous bust position for actor: ", actor_ref)
					return "Continue"

			#@ Step 5 - Hide and clear the old bust node if actor was already assigned elsewhere:
			var bust_scene = get_node(ui_elements_paths["busts_path"])
			bust_scene.caller = self

			if bust_positions.has(actor_ref):
				var old_bust_name: String = bust_positions[actor_ref]["pos"]
				var bust_node_old: Node = bust_scene.busts_container.get_node_or_null(old_bust_name)
				if bust_node_old and old_bust_name != bust_name:
					bust_scene.clear_old_bust_nodes(bust_node_old)

			#@ Step 6 - Register / update the actor’s bust position:
			bust_positions[actor_ref] = {"pos": bust_name}

			#@ Step 7 - Apply bust setup (assign + optional playback):
			await bust_scene.set_bust(actor_ref, bust_name, file_ref, anim_name, loop, wait, time_target)

			return "Continue"


		#* §VN_Move - Move an actor to a different bust node and preserve animation state:
		"§vn_move":
			if not vn_mode:
				return

			var bust_name: String	= resolve_value(command_value.get("Bust", "")).strip_edges()
			var actor_ref: String	= resolve_value(command_value.get("Reference", "")).strip_edges()

			#@ Step 1 - Resolve actor role if needed:
			if actor_ref.begins_with(candy_de.role_symbol) and candy_de.roles.has(actor_ref):
				actor_ref = candy_de.roles[actor_ref]

			#@ Step 2 - Verify the actor is assigned:
			if not bust_positions.has(actor_ref):
				printerr("§VNMove: Actor ", actor_ref, " is not assigned to any bust node. Move aborted.")
				return "Continue"

			#@ Step 3 - Get the old bust reference:
			var old_bust: String = bust_positions[actor_ref]["pos"]

			#@ Step 4 - Update assignment:
			bust_positions[actor_ref]["pos"] = bust_name

			#@ Step 5 - Move the bust and preserve state:
			var bust_scene = get_node(ui_elements_paths["busts_path"])
			bust_scene.caller = self
			await bust_scene.move_bust(actor_ref, old_bust, bust_name)

			return "Continue"


		#* §VN_Bust_Wait - Pause dialogue until bust animations reach a target loop/time or finish playback:
		"§vn_bust_wait":
			if not vn_mode:
				return

			var actors_raw: Variant		= resolve_value(command_value.get("Actors", ""))
			var wait_raw: Variant		= resolve_value(command_value.get("Wait", "0"))
			var time_raw: Variant		= resolve_value(command_value.get("Time", "0"))

			#@ Step 1 - Parse Actors list:
			var actors_array: Array = []
			if actors_raw is String:
				for part in actors_raw.split(",", false):
					var ref = part.strip_edges()
					if ref != "":
						actors_array.append(ref)
			elif actors_raw is Array:
				actors_array = actors_raw.duplicate()

			#@ Step 2 - Parse Wait and Time values:
			var wait_target: int = 0
			var time_target: float = 0.0
			var default_fps: float = 30.0

			if str(wait_raw).strip_edges() != "":
				wait_target = int(wait_raw)

			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					if s.begins_with("f=") or s.begins_with("F="):
						var frame_val = float(s.substr(2, s.length()))
						time_target = frame_val / default_fps
					else:
						var parts = s.split(":")
						match parts.size():
							3:
								time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
							2:
								time_target = int(parts[0]) * 60 + float(parts[1])
							1:
								time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 3 - Determine which actors to wait for:
			var bust_scene = get_node(ui_elements_paths["busts_path"])
			bust_scene.caller = self
			var bust_data: Dictionary = bust_scene.bust_node_data
			var target_actors: Array = []

			if actors_array.is_empty():
				target_actors = bust_data.keys()
			else:
				for actor in actors_array:
					if bust_data.has(actor):
						target_actors.append(actor)

			if target_actors.is_empty():
				return "Continue"

			#@ Step 4 - Wait until all target actors meet the condition:
			var done_actors: Array = []
			while done_actors.size() < target_actors.size():
				for actor in target_actors:
					if actor in done_actors:
						continue

					var data = bust_data.get(actor, null)
					if data == null:
						done_actors.append(actor)
						continue

					var loop_target: int    = int(data.get("loop_target", 0))
					var loops_played: int   = int(data.get("loops_played", 0))
					var duration: float     = float(data.get("duration", 0.0))
					var resume_at: float    = (wait_target * duration) + time_target

					#% Compute elapsed with mid-loop precision where possible:
					var bust_node = data.get("node", null)
					var elapsed: float = loops_played * duration
					if bust_node:
						if (bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D) and bust_node.is_playing():
							var frame_count = bust_node.sprite_frames.get_frame_count(bust_node.animation) if bust_node.sprite_frames else 1
							var frame_duration = duration / max(frame_count, 1)
							elapsed += bust_node.frame * frame_duration
						elif bust_node is VideoStreamPlayer and bust_node.is_playing():
							elapsed += bust_node.stream_position
						else:
							elapsed = float(data.get("elapsed_time", 0.0))
					else:
						elapsed = float(data.get("elapsed_time", 0.0))

					#% Case 1 - Infinite loop & no wait/time → skip:
					if loop_target == -1 and wait_target == 0 and time_target <= 0.0:
						done_actors.append(actor)
						continue

					#% Case 2 - Wait/time condition satisfied:
					if wait_target > 0 or time_target > 0.0:
						if elapsed >= resume_at:
							done_actors.append(actor)
							continue
					else:
						#% Case 3 - No wait/time → just wait until loops done:
						if loop_target > 0 and loops_played >= loop_target:
							done_actors.append(actor)
							continue

				await get_tree().process_frame

			return "Continue"


		#* §VN_Stop - Stop one or more bust animations:
		"§vn_bust_stop":
			if vn_mode != true:
				return "Continue"

			var refs_raw: Variant	= command_value.get("Actors", "")
			var use_default: bool	= resolve_value(command_value.get("Default", 0))

			#@ Step 1 - Convert to array (handles string or array input):
			var refs_array: Array = []
			if refs_raw is String:
				for part in refs_raw.split(",", false):
					var ref_name = part.strip_edges()
					if ref_name != "":
						refs_array.append(ref_name)
			elif refs_raw is Array:
				refs_array = refs_raw.duplicate()

			#@ Step 2 - Resolve each value and handle role → actor conversion:
			for i in range(refs_array.size()):
				var value = resolve_value(refs_array[i]).strip_edges()

				#% If it's a role (starts with *), map it to an actor:
				if value.begins_with(candy_de.role_symbol):
					var role_name = value
					if candy_de.roles.has(role_name):
						value = candy_de.roles[role_name]
					else:
						printerr("§VNStop: Unknown role: ", role_name)

				refs_array[i] = value

			#@ Step 3 - Stop animations for the resulting actor list:
			var bust_scene = get_node(ui_elements_paths["busts_path"])
			bust_scene.caller = self
			bust_scene.stop_bust_animation(refs_array, use_default)

			return "Continue"


		#* §VN_Mirror - Toggle horizontal or vertical flip on one or more busts:
		"§vn_mirror":
			if vn_mode != true:
				return "Continue"

			var actors_raw: Variant	= resolve_value(command_value.get("Actors", ""))
			var axis: String		= resolve_value(command_value.get("Axis", "Reset")).strip_edges()

			#@ Step 1 - Parse actors list:
			var actors_array: Array = []
			if actors_raw is String:
				for part in actors_raw.split(",", false):
					var actor_name = part.strip_edges()
					if actor_name != "":
						actors_array.append(actor_name)
			elif actors_raw is Array:
				actors_array = actors_raw.duplicate()

			#@ Step 2 - Resolve roles if needed:
			for i in range(actors_array.size()):
				var value = resolve_value(actors_array[i]).strip_edges()
				if value.begins_with(candy_de.role_symbol):
					var role_name = value
					if candy_de.roles.has(role_name):
						value = candy_de.roles[role_name]
					else:
						printerr("§VNMirror: Unknown role: ", role_name)
				actors_array[i] = value

			#@ Step 3 - Mirror each actor’s bust:
			for actor_ref in actors_array:
				if bust_positions.has(actor_ref):
					var bust_ref = bust_positions[actor_ref]["pos"]
					var bust_scene = get_node(ui_elements_paths["busts_path"])
					bust_scene.caller = self
					bust_scene.mirror_bust(bust_ref, axis)
				else:
					printerr("§VNMirror: Actor not found in bust_positions → ", actor_ref)

			return "Continue"


		#* §VN_Remove - Remove images and animations from one or more VN bust nodes:
		"§vn_remove":
			if vn_mode != true:
				return "Continue"

			var refs_raw: Variant = command_value.get("Actors", "")

			#@ Step 1 - Convert to array (handles string or array input):
			var refs_array: Array = []
			if refs_raw is String:
				for part in refs_raw.split(",", false):
					var ref_name = part.strip_edges()
					if ref_name != "":
						refs_array.append(ref_name)
			elif refs_raw is Array:
				refs_array = refs_raw.duplicate()

			#@ Step 2 - Resolve values and map roles to actors:
			for i in range(refs_array.size()):
				var value = resolve_value(refs_array[i]).strip_edges()
				if value.begins_with(candy_de.role_symbol):
					var role_name = value
					if candy_de.roles.has(role_name):
						value = candy_de.roles[role_name]
					else:
						printerr("§VNRemove: Unknown role: ", role_name)

				refs_array[i] = value

			#@ Step 3 - Clear visuals for the resolved actor list:
			var bust_scene = get_node(ui_elements_paths["busts_path"])
			bust_scene.caller = self
			await bust_scene.clear_bust_nodes(refs_array)

			#@ Step 4 - Remove cleared actors from bust_positions:
			for actor in refs_array:
				if bust_positions.has(actor):
					bust_positions.erase(actor)

			return "Continue"


		#* §VN_Effect - Play one or more AnimationPlayer-based effects on VN busts:
		"§vn_effect":
			if vn_mode != true:
				return "Continue"

			var refs_raw: Variant		= command_value.get("Actors", "")
			var library: String			= resolve_value(command_value.get("Library", ""))
			var effects_raw: Variant	= command_value.get("Effects", [])
			var loop_raw: Variant		= resolve_value(command_value.get("Loop", "0"))
			var wait_raw: Variant		= resolve_value(command_value.get("Wait", "0"))
			var time_raw: Variant		= resolve_value(command_value.get("Time", "0"))

			#@ Step 1 - Convert actor list:
			var refs_array: Array = []
			if refs_raw is String:
				for part in refs_raw.split(",", false):
					var ref_name = part.strip_edges()
					if ref_name != "":
						refs_array.append(ref_name)
			elif refs_raw is Array:
				refs_array = refs_raw.duplicate()

			#@ Step 2 - Resolve actors (variables + roles):
			for i in range(refs_array.size()):
				var value = resolve_value(refs_array[i]).strip_edges()
				if value.begins_with(candy_de.role_symbol):
					var role_name = value
					if candy_de.roles.has(role_name):
						value = candy_de.roles[role_name]
					else:
						printerr("§VNEffect: Unknown role: ", role_name)
				refs_array[i] = value

			#@ Step 3 - Convert and resolve effects list:
			var effects_array: Array = []
			if effects_raw is String:
				for part in effects_raw.split(",", false):
					var eff_name = resolve_value(part.strip_edges())
					effects_array.append(eff_name)
			elif effects_raw is Array:
				for part in effects_raw:
					var eff_name = resolve_value(str(part).strip_edges())
					effects_array.append(eff_name)

			#@ Step 4 - Parse Loop / Wait / Time:
			var loop_target: int = int(loop_raw)
			var wait_target: int = int(wait_raw)
			var time_target: float = 0.0
			var default_fps: float = 30.0

			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					if s.begins_with("f=") or s.begins_with("F="):
						var frame_val = float(s.substr(2, s.length()))
						time_target = frame_val / default_fps
					else:
						var parts = s.split(":")
						match parts.size():
							3:
								time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
							2:
								time_target = int(parts[0]) * 60 + float(parts[1])
							1:
								time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 5 - Play effects:
			var bust_scene = get_node(ui_elements_paths["busts_path"])
			bust_scene.caller = self
			bust_scene.play_bust_effects(refs_array, library, effects_array, loop_target, wait_target, time_target)

			#@ Step 6 - Wait until resume_at is reached across all actors:
			var resume_at: float = 0.0
			if wait_target > 0 or time_target > 0.0:
				#% Get duration from first resolved actor/effect to calculate resume_at:
				var first_actor = refs_array[0] if not refs_array.is_empty() else ""
				if first_actor == "" and not bust_scene.bust_node_data.is_empty():
					first_actor = bust_scene.bust_node_data.keys()[0]

				if bust_scene.bust_node_data.has(first_actor) and \
				bust_scene.bust_node_data[first_actor].has("effects") and \
				bust_scene.bust_node_data[first_actor]["effects"].has(effects_array[0] if not effects_array.is_empty() else ""):
					var effect_key = effects_array[0] if not effects_array.is_empty() else ""
					var effect_data = bust_scene.bust_node_data[first_actor]["effects"][effect_key]
					var duration = effect_data["duration"]
					resume_at = (wait_target * duration) + time_target

					while true:
						await get_tree().process_frame
						var elapsed = effect_data["loops_played"] * effect_data["duration"] + effect_data["player"].current_animation_position
						if elapsed >= resume_at:
							break
						if not effect_data["player"].is_playing() and loop_target > 0 and effect_data["loops_played"] >= loop_target:
							break

			return "Continue"


		#* §VN_Effect_Wait - Pause dialogue until bust effects reach a target loop/time or finish playback:
		"§vn_effect_wait":
			if vn_mode != true:
				return "Continue"

			var actors_raw: Variant		= resolve_value(command_value.get("Actors", ""))
			var effects_raw: Variant	= resolve_value(command_value.get("Effects", ""))
			var wait_raw: Variant		= resolve_value(command_value.get("Wait", ""))
			var time_raw: Variant		= resolve_value(command_value.get("Time", ""))

			#@ Step 1 - Parse actor and effect lists:
			var actors_array: Array = []
			if actors_raw is String:
				for part in actors_raw.split(",", false):
					var actor_name = part.strip_edges()
					if actor_name != "":
						actors_array.append(actor_name)
			elif actors_raw is Array:
				actors_array = actors_raw.duplicate()

			var effects_array: Array = []
			if effects_raw is String:
				for part in effects_raw.split(",", false):
					var eff = part.strip_edges()
					if eff != "":
						effects_array.append(eff)
			elif effects_raw is Array:
				effects_array = effects_raw.duplicate()

			#@ Step 2 - Parse Wait and Time:
			var wait_target: int = -1
			var time_target: float = 0.0
			var default_fps: float = 30.0

			if str(wait_raw).strip_edges() == "":
				wait_raw = "0"

			wait_target = int(wait_raw)

			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					if s.begins_with("f=") or s.begins_with("F="):
						var frame_val = float(s.substr(2, s.length()))
						time_target = frame_val / default_fps
					else:
						var parts = s.split(":")
						match parts.size():
							3:
								time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
							2:
								time_target = int(parts[0]) * 60 + float(parts[1])
							1:
								time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 3 - Resolve actors and effects to wait for:
			var bust_scene = get_node(ui_elements_paths["busts_path"])
			bust_scene.caller = self
			var bust_data: Dictionary = bust_scene.bust_node_data
			var target_pairs: Array = []

			if actors_array.is_empty():
				#% All actors that have active effects:
				for actor_name in bust_data.keys():
					var effects_dict = bust_data[actor_name].get("effects", {})
					if effects_array.is_empty():
						for e in effects_dict.keys():
							target_pairs.append([actor_name, e])
					else:
						for e in effects_array:
							if effects_dict.has(e):
								target_pairs.append([actor_name, e])
			else:
				for actor_name in actors_array:
					if not bust_data.has(actor_name):
						continue
					var effects_dict = bust_data[actor_name].get("effects", {})
					if effects_array.is_empty():
						for e in effects_dict.keys():
							target_pairs.append([actor_name, e])
					else:
						for e in effects_array:
							if effects_dict.has(e):
								target_pairs.append([actor_name, e])

			if target_pairs.is_empty():
				return "Continue"

			#@ Step 4 - Wait until each effect meets the condition:
			var done_pairs: Array = []
			while done_pairs.size() < target_pairs.size():
				for pair in target_pairs:
					if pair in done_pairs:
						continue

					var actor_name = pair[0]
					var effect_name = pair[1]

					if not bust_data.has(actor_name):
						done_pairs.append(pair)
						continue
					var effects_dict = bust_data[actor_name].get("effects", {})
					if not effects_dict.has(effect_name):
						done_pairs.append(pair)
						continue

					var data = effects_dict[effect_name]
					var loop_target: int = int(data.get("loop_target", 0))
					var loops_played: int = int(data.get("loops_played", 0))
					var duration: float = float(data.get("duration", 0.0))
					var resume_at: float = (wait_target * duration) + time_target
					var player: AnimationPlayer = data.get("player", null)
					var elapsed: float = loops_played * duration
					if player and player.is_playing():
						elapsed += player.current_animation_position

					#% Case 1 - Infinite loop & no wait/time → ignore:
					if loop_target == 0 and wait_target == -1 and time_target <= 0.0:
						done_pairs.append(pair)
						continue

					#% Case 2 - Finished required loops/time:
					if wait_target != -1 or time_target > 0.0:
						if elapsed >= resume_at:
							done_pairs.append(pair)
							continue
					else:
						#% No wait/time → wait until all loops done:
						if loop_target > 0 and loops_played >= loop_target:
							done_pairs.append(pair)
							continue

				await get_tree().process_frame

			return "Continue"


		#* §VN_Effect_Stop - Stop one or more AnimationPlayer-based effects on VN busts:
		"§vn_effect_stop":
			if vn_mode != true:
				return "Continue"

			var refs_raw: Variant		= command_value.get("Actors", "")
			var effects_raw: Variant	= command_value.get("Effects", [])

			#@ Step 1 - Convert actor list:
			var refs_array: Array = []
			if refs_raw is String:
				for part in refs_raw.split(",", false):
					var ref_name = part.strip_edges()
					if ref_name != "":
						refs_array.append(ref_name)
			elif refs_raw is Array:
				refs_array = refs_raw.duplicate()

			#@ Step 2 - Resolve actors (variables + roles):
			for i in range(refs_array.size()):
				var value = resolve_value(refs_array[i]).strip_edges()
				if value.begins_with(candy_de.role_symbol):
					var role_name = value
					if candy_de.roles.has(role_name):
						value = candy_de.roles[role_name]
					else:
						printerr("§VNEffectStop: Unknown role: ", role_name)

				refs_array[i] = value

			#@ Step 3 - Convert and resolve effects list:
			var effects_array: Array = []
			if effects_raw is String:
				for part in effects_raw.split(",", false):
					var eff_name = resolve_value(part.strip_edges())
					effects_array.append(eff_name)
			elif effects_raw is Array:
				for part in effects_raw:
					var eff_name = resolve_value(str(part).strip_edges())
					effects_array.append(eff_name)

			#@ Step 4 - Stop effects:
			var bust_scene = get_node(ui_elements_paths["busts_path"])
			bust_scene.caller = self
			bust_scene.stop_bust_effects(refs_array, effects_array)

			return "Continue"


		#endregion - vn commands


		#&########################################
		#&										##
		#&          CUTSCENE COMMANDS           ##
		#&										##
		#region - Cutscene Commands
		#* §CS_Scene - Instantiate a scene as a child of one or more target nodes:
		"§cs_scene":
			var path_1: Variant			= resolve_value(command_value.get("Path 1", ""))
			var targets_raw: Variant	= resolve_value(command_value.get("Targets", ""))
			var scene_raw: Variant		= resolve_value(command_value.get("Scene", ""))

			#@ Step 1 - Parse target list (comma-separated or array):
			var targets: Array = []
			if targets_raw is String:
				for part in targets_raw.split(",", false):
					var t = part.strip_edges()
					if t != "":
						targets.append(t)
			elif targets_raw is Array:
				targets = targets_raw.duplicate()

			if targets.is_empty():
				printerr("§CSScene: No Targets provided.")
				return "Continue"

			#@ Step 2 - Load scene:
			var scene_path: String = str(scene_raw).strip_edges()
			if scene_path == "":
				printerr("§CSScene: Missing Scene path.")
				return "Continue"

			var packed_scene: PackedScene = load(scene_path)
			if packed_scene == null:
				printerr("§CSScene: Failed to load scene at → ", scene_path)
				return "Continue"

			#@ Step 3 - Locate Path 1 container:
			var container = get_node_or_null(cs_locations.get(path_1, ""))
			if not container:
				printerr("§CSScene: Invalid Path 1 → ", path_1)
				return "Continue"

			#@ Step 4 - Instantiate scene for each target:
			for target_name in targets:
				#% Resolve role alias if needed:
				if typeof(target_name) == TYPE_STRING and target_name.begins_with(candy_de.role_symbol):
					var role_name = target_name
					if candy_de.roles.has(role_name):
						target_name = candy_de.roles[role_name]
					else:
						printerr("§CSScene: Unknown role target → ", role_name)
						continue

				var parent: Node = container.get_node_or_null(NodePath(target_name))
				if parent == null:
					printerr("§CSScene: Could not find parent node at ", path_1, "/", target_name)
					continue

				#@ Step 5 - Instantiate and attach:
				var instance: Node = packed_scene.instantiate()
				parent.add_child(instance)

			return "Continue"


		#* §CS_Loc - Move one or more Cutscene objects to marker positions, with optional rotation sync:
		"§cs_loc":
			var path_1: Variant			= resolve_value(command_value.get("Path 1", ""))
			var path_2: Variant			= resolve_value(command_value.get("Path 2", ""))
			var targets_raw: Variant	= resolve_value(command_value.get("Targets", ""))
			var markers_raw: Variant	= resolve_value(command_value.get("Markers", ""))
			var rotate_raw: Variant		= resolve_value(command_value.get("Rotate", "1"))

			var rotate: bool = int(rotate_raw) == 1

			#@ Step 1 - Parse Targets and Markers into arrays:
			var targets: Array = []
			if targets_raw is String:
				for part in targets_raw.split(",", false):
					var t = part.strip_edges()
					if t != "":
						targets.append(t)
			elif targets_raw is Array:
				targets = targets_raw.duplicate()

			var markers: Array = []
			if markers_raw is String:
				for part in markers_raw.split(",", false):
					var m = part.strip_edges()
					if m != "":
						markers.append(m)
			elif markers_raw is Array:
				markers = markers_raw.duplicate()

			if targets.is_empty() or markers.is_empty():
				printerr("§CSLoc: Missing Targets or Markers.")
				return "Continue"

			#@ Step 2 - Locate containers for both sets:
			var targets_container = get_node_or_null(cs_locations.get(path_1, ""))
			var markers_container = get_node_or_null(cs_locations.get(path_2, ""))

			if not targets_container:
				printerr("§CSLoc: Invalid Path 1 → ", path_1)
				return "Continue"
			if not markers_container:
				printerr("§CSLoc: Invalid Path 2 → ", path_2)
				return "Continue"

			#@ Step 3 - Iterate and match each target to its marker:
			var pair_count = min(targets.size(), markers.size())
			for i in range(pair_count):
				var target_name = targets[i]
				var marker_name = markers[i]

				#% Resolve roles (for both targets and markers):
				if typeof(target_name) == TYPE_STRING and target_name.begins_with(candy_de.role_symbol):
					var role_name = target_name
					if candy_de.roles.has(role_name):
						target_name = candy_de.roles[role_name]
					else:
						printerr("§CSLoc: Unknown role target → ", role_name)

				if typeof(marker_name) == TYPE_STRING and marker_name.begins_with(candy_de.role_symbol):
					var role_name = marker_name
					if candy_de.roles.has(role_name):
						marker_name = candy_de.roles[role_name]
					else:
						printerr("§CSLoc: Unknown role marker → ", role_name)

				var target: Node = targets_container.get_node_or_null(NodePath(target_name))
				var marker: Node = markers_container.get_node_or_null(NodePath(marker_name))

				if not target:
					printerr("§CSLoc: Target not found → ", target_name)
					continue
				if not marker:
					printerr("§CSLoc: Marker not found → ", marker_name)
					continue

				#@ Step 4 - Move target to marker position:
				if target.has_method("set_global_position") and marker.has_method("get_global_position"):
					target.global_position = marker.global_position
				elif target.has_method("set_global_transform") and marker.has_method("get_global_transform"):
					var t = target.global_transform
					t.origin = marker.global_transform.origin
					target.global_transform = t
				else:
					printerr("§CSLoc: Unsupported node type for → ", target.name)
					continue

				#@ Step 5 - Optional rotation sync:
				if rotate:
					if target.has_method("set_global_rotation") and marker.has_method("get_global_rotation"):
						target.global_rotation = marker.global_rotation
					elif target.has_method("set_global_transform") and marker.has_method("get_global_transform"):
						var t = target.global_transform
						t.basis = marker.global_transform.basis
						target.global_transform = t
					else:
						printerr("§CSLoc: Rotation not supported for → ", target.name)

			#% Done
			return "Continue"


		#* §CS_Move - Move a node towards a marker:
		"§cs_move":
			return "Continue"


		#* §CS_Anim - Play one or more animations on one or more nodes with Loop/Wait/Time and Play logic:
		"§cs_anim":
			var path_1: Variant			= resolve_value(command_value.get("Path 1", ""))
			var path_2: Variant			= resolve_value(command_value.get("Path 2", ""))
			var targets_raw: Variant	= resolve_value(command_value.get("Targets", ""))
			var anim_raw: Variant		= resolve_value(command_value.get("Animation", ""))
			var loop_raw: Variant		= resolve_value(command_value.get("Loop", "1"))
			var wait_raw: Variant		= resolve_value(command_value.get("Wait", "0"))
			var time_raw: Variant		= resolve_value(command_value.get("Time", "0"))
			var play_raw: Variant		= resolve_value(command_value.get("Play", "1"))

			var loop: int = int(loop_raw)
			var wait: int = int(wait_raw)
			var play: int = int(play_raw)

			#@ Step 1 - Parse Time value (HH:MM:SS.xx or f=frames):
			var time_target: float = 0.0
			var default_fps: float = 30.0
			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s == "":
					time_target = 0.0
				elif s.begins_with("f=") or s.begins_with("F="):
					var frame_val = float(s.substr(2, s.length()))
					time_target = frame_val / default_fps
				else:
					var parts = s.split(":")
					match parts.size():
						3:
							time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
						2:
							time_target = int(parts[0]) * 60 + float(parts[1])
						1:
							time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 2 - Parse Targets list:
			var targets: Array = []
			if targets_raw is String:
				for part in targets_raw.split(",", false):
					var t = part.strip_edges()
					if t != "":
						targets.append(t)
			elif targets_raw is Array:
				targets = targets_raw.duplicate()

			if targets.is_empty():
				printerr("§CSAnim: No Targets specified.")
				return "Continue"

			#@ Step 3 - Locate the container for targets:
			var container = get_node_or_null(cs_locations.get(path_1, ""))
			if not container:
				printerr("§CSAnim: Invalid Path 1 → ", path_1)
				return "Continue"

			var active_nodes: Array = []

			#@ Step 4 - Process each target node:
			for target_name in targets:
				var target_node: Node = container.get_node_or_null(NodePath(target_name))
				if not target_node:
					printerr("§CSAnim: Target not found under Path 1 → ", target_name)
					continue

				#@ Step 5 - Resolve animation node:
				var anim_node: Node = null
				if path_2 != "":
					if "internal_node_dict" in target_node and target_node.internal_node_dict.has(path_2):
						anim_node = target_node.internal_node_dict[path_2]
					else:
						anim_node = target_node.get_node_or_null(path_2)
				else:
					anim_node = target_node.get_node_or_null("AnimationPlayer")
					if not anim_node:
						anim_node = target_node.get_node_or_null("AnimationTree")

				if not anim_node:
					printerr("§CSAnim: No AnimationPlayer/Tree found for ", target_name)
					continue

				#@ Step 6 - Resolve animation name:
				var anim_name := str(anim_raw).strip_edges()
				if anim_name == "":
					printerr("§CSAnim: No animation specified for ", target_name)
					continue

				#@ Step 7 - Initialize cs_loop_data for this target:
				if not target_node.has_meta("cs_loop_data"):
					target_node.set_meta("cs_loop_data", {})
				var cs_loop_data: Dictionary = target_node.get_meta("cs_loop_data")
				if not cs_loop_data.has(path_2):
					cs_loop_data[path_2] = {}

				var data = cs_loop_data[path_2]
				data["loop_target"] = loop
				data["loops_played"] = 0
				data["wait_target"] = wait
				data["time_target"] = time_target
				data["elapsed_time"] = 0.0
				data["duration"] = 0.0
				data["anim_name"] = anim_name
				data["paused"] = (play == 0)

				#@ Step 8 - Handle Play = 0 case:
				if play == 0:
					if anim_node is AnimationPlayer:
						anim_node.stop()
						anim_node.seek(0.0, true)
					elif anim_node is AnimationTree:
						anim_node.active = false
					continue

				#@ Step 9 - Start animation:
				if anim_node is AnimationPlayer:
					if not anim_node.has_animation(anim_name):
						printerr("§CSAnim: animation not found → ", anim_name, " in ", target_name)
						continue

					var duration = anim_node.get_animation(anim_name).length
					data["duration"] = duration

					var _anim_loop := func():
						while true:
							anim_node.play(anim_name)
							await anim_node.animation_finished
							data["loops_played"] += 1
							if loop == 0 or data["loops_played"] < loop:
								continue
							else:
								anim_node.stop()
								return
					_anim_loop.call_deferred()

				elif anim_node is AnimationTree:
					var playback: AnimationNodeStateMachinePlayback = anim_node.get("parameters/playback")
					if not playback:
						printerr("§CSAnim: AnimationTree missing playback for ", target_name)
						continue

					anim_node.active = true
					playback.travel(anim_name)

					var duration: float = 1.0	#/ Unknown duration fallback
					data["duration"] = duration

					var _tree_loop := func():
						while true:
							await get_tree().process_frame
							data["elapsed_time"] += get_process_delta_time()
							if not anim_node.active:
								break
							if loop > 0 and data["loops_played"] >= loop:
								break
							if playback.get_current_node() != anim_name:
								data["loops_played"] += 1
								if loop == 0 or data["loops_played"] < loop:
									playback.travel(anim_name)
								else:
									break
					_tree_loop.call_deferred()

				else:
					printerr("§CSAnim: Unsupported animation node type → ", anim_node)
					continue

				active_nodes.append(target_node)

			#@ Step 10 - Simultaneous continuous waiting:
			if wait > 0 or time_target > 0.0:
				while true:
					var all_done := true
					for node in active_nodes:
						if not node.has_meta("cs_loop_data"):
							continue
						var cs_loop_data: Dictionary = node.get_meta("cs_loop_data")
						if not cs_loop_data.has(path_2):
							continue

						var d = cs_loop_data[path_2]
						d["elapsed_time"] += get_process_delta_time()

						var duration: float = float(d.get("duration", 0.0))
						var loop_target: int = int(d.get("loop_target", 0))
						var loops_played: int = int(d.get("loops_played", 0))
						var resume_at: float = (max(wait, 0) * duration) + max(time_target, 0.0)

						if loop_target > 0 and loops_played < loop_target:
							all_done = false
							break
						elif d["elapsed_time"] < resume_at:
							all_done = false
							break
					if all_done:
						break
					await get_tree().process_frame

			return "Continue"


		#* §CS_Anim_Wait - Pause dialogue until one or more animations reach their loop/time targets:
		"§cs_anim_wait":
			var path_1: Variant			= resolve_value(command_value.get("Path 1", ""))
			var path_2: Variant			= resolve_value(command_value.get("Path 2", ""))
			var targets_raw: Variant	= resolve_value(command_value.get("Targets", ""))
			var wait_raw: Variant		= resolve_value(command_value.get("Wait", ""))
			var time_raw: Variant		= resolve_value(command_value.get("Time", ""))

			#@ Step 1 - Parse Wait and Time values:
			var wait_target: int = -1
			var time_target: float = 0.0
			var default_fps: float = 30.0

			if str(wait_raw).strip_edges() != "":
				wait_target = int(wait_raw)

			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					if s.begins_with("f=") or s.begins_with("F="):
						var frame_val = float(s.substr(2, s.length()))
						time_target = frame_val / default_fps
					else:
						var parts = s.split(":")
						match parts.size():
							3:
								time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
							2:
								time_target = int(parts[0]) * 60 + float(parts[1])
							1:
								time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 2 - Parse Targets list:
			var targets: Array = []
			if targets_raw is String:
				for part in targets_raw.split(",", false):
					var t = part.strip_edges()
					if t != "":
						targets.append(t)
			elif targets_raw is Array:
				targets = targets_raw.duplicate()

			if targets.is_empty():
				printerr("§CSAnimWait: No Targets specified.")
				return "Continue"

			#@ Step 3 - Locate container:
			var container = get_node_or_null(cs_locations.get(path_1, ""))
			if not container:
				printerr("§CSAnimWait: Invalid Path 1 → ", path_1)
				return "Continue"

			#@ Step 4 - Collect valid nodes with loop data:
			var active_nodes: Array = []
			for target_name in targets:
				var node = container.get_node_or_null(NodePath(target_name))
				if node and node.has_meta("cs_loop_data"):
					var cs_loop_data: Dictionary = node.get_meta("cs_loop_data")
					if cs_loop_data.has(path_2):
						active_nodes.append(node)
					else:
						printerr("§CSAnimWait: Missing loop data for Path 2 → ", path_2, " in ", target_name)
				else:
					printerr("§CSAnimWait: No metadata found for target → ", target_name)

			if active_nodes.is_empty():
				printerr("§CSAnimWait: No valid nodes to monitor.")
				return "Continue"

			#@ Step 5 - Simultaneous waiting with continuous updates:
			var done_nodes: Array = []
			while done_nodes.size() < active_nodes.size():
				for node in active_nodes:
					if node in done_nodes:
						continue

					if not node.has_meta("cs_loop_data"):
						done_nodes.append(node)
						continue

					var cs_loop_data: Dictionary = node.get_meta("cs_loop_data")
					if not cs_loop_data.has(path_2):
						done_nodes.append(node)
						continue

					var data = cs_loop_data[path_2]
					data["elapsed_time"] += get_process_delta_time()

					var loop_target: int = int(data.get("loop_target", 0))
					var loops_played: int = int(data.get("loops_played", 0))
					var elapsed: float = float(data.get("elapsed_time", 0.0))
					var duration: float = float(data.get("duration", 0.0))
					var resume_at: float = (max(wait_target, 0) * duration) + max(time_target, 0.0)

					#% Skip if nothing to wait for:
					if loop_target == 0 and wait_target == -1 and time_target <= 0.0:
						done_nodes.append(node)
						continue

					#% Finished required loops/time:
					if elapsed >= resume_at or (loop_target > 0 and loops_played >= loop_target):
						done_nodes.append(node)
						continue

				await get_tree().process_frame

			return "Continue"


		#* §CS_Anim_Stop - Stop ongoing animations on one or more nodes:
		"§cs_anim_stop":
			var path_1: Variant			= resolve_value(command_value.get("Path 1", ""))
			var path_2: Variant			= resolve_value(command_value.get("Path 2", ""))
			var targets_raw: Variant	= resolve_value(command_value.get("Targets", ""))
			var reset_raw: Variant		= resolve_value(command_value.get("Default", "0"))

			var reset_to_first := int(reset_raw) == 1

			#@ Step 1 - Parse Targets list:
			var targets: Array = []
			if targets_raw is String:
				for part in targets_raw.split(",", false):
					var t = part.strip_edges()
					if t != "":
						targets.append(t)
			elif targets_raw is Array:
				targets = targets_raw.duplicate()

			if targets.is_empty():
				printerr("§CSAnimStop: No Targets specified.")
				return "Continue"

			#@ Step 2 - Locate container:
			var container = get_node_or_null(cs_locations.get(path_1, ""))
			if not container:
				printerr("§CSAnimStop: Invalid Path 1 → ", path_1)
				return "Continue"

			#@ Step 3 - Process all targets:
			for target_name in targets:
				var node = container.get_node_or_null(NodePath(target_name))
				if not node:
					printerr("§CSAnimStop: Target not found → ", target_name)
					continue

				#@ Step 4 - Find animation node:
				var anim_node: Node = null
				if path_2 != "":
					if "internal_node_dict" in node and node.internal_node_dict.has(path_2):
						anim_node = node.internal_node_dict[path_2]
					else:
						anim_node = node.get_node_or_null(path_2)
				else:
					anim_node = node.get_node_or_null("AnimationPlayer")
					if not anim_node:
						anim_node = node.get_node_or_null("AnimationTree")

				if not anim_node:
					printerr("§CSAnimStop: No valid animation node for ", target_name)
					continue

				#@ Step 5 - Stop animation based on type:
				if anim_node is AnimationPlayer:
					anim_node.stop()
					if reset_to_first:
						anim_node.seek(0.0, true)

				elif anim_node is AnimationTree:
					if reset_to_first:
						var playback: AnimationNodeStateMachinePlayback = anim_node.get("parameters/playback")
						if playback and playback.has_method("travel"):
							playback.travel("Idle")
					anim_node.active = false

				else:
					printerr("§CSAnimStop: Unsupported animation node → ", anim_node)
					continue

				#@ Step 6 - Cleanup cs_loop_data entry:
				if node.has_meta("cs_loop_data"):
					var cs_loop_data: Dictionary = node.get_meta("cs_loop_data")
					cs_loop_data.erase(path_2)

			return "Continue"


		#* §CS_Sprite - Assign and animate one or more Sprite2D/3D or AnimatedSprite2D/3D nodes in the game world:
		"§cs_sprite":
			var path_1: Variant			= resolve_value(command_value.get("Path 1", ""))
			var path_2: Variant			= resolve_value(command_value.get("Path 2", ""))
			var targets_raw: Variant	= resolve_value(command_value.get("Targets", ""))
			var file_ref: String		= str(resolve_value(command_value.get("File", ""))).strip_edges()
			var anim_name: String		= str(resolve_value(command_value.get("Animation", ""))).strip_edges()
			var loop_raw: Variant		= resolve_value(command_value.get("Loop", "1"))
			var wait_raw: Variant		= resolve_value(command_value.get("Wait", "0"))
			var time_raw: Variant		= resolve_value(command_value.get("Time", "0"))
			var play_raw: Variant		= resolve_value(command_value.get("Play", "1"))

			var loop: int = int(loop_raw)
			var wait: int = int(wait_raw)
			var play: int = int(play_raw)

			#@ Step 1 - Parse Time (HH:MM:SS.xx or f=frames):
			var time_target: float = 0.0
			var default_fps: float = 30.0
			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s == "":
					time_target = 0.0
				elif s.begins_with("f=") or s.begins_with("F="):
					var frame_val = float(s.substr(2, s.length()))
					time_target = frame_val / default_fps
				else:
					var parts = s.split(":")
					match parts.size():
						3:
							time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
						2:
							time_target = int(parts[0]) * 60 + float(parts[1])
						1:
							time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 2 - Parse Targets list:
			var targets: Array = []
			if targets_raw is String:
				for part in targets_raw.split(",", false):
					var t = part.strip_edges()
					if t != "":
						targets.append(t)
			elif targets_raw is Array:
				targets = targets_raw.duplicate()

			if targets.is_empty():
				printerr("§CSSprite: No Targets specified.")
				return "Continue"

			#@ Step 3 - Locate container for targets:
			var container = get_node_or_null(cs_locations.get(path_1, ""))
			if not container:
				printerr("§CSSprite: Invalid Path 1 → ", path_1)
				return "Continue"

			var active_nodes: Array = []

			#@ Step 4 - Process each target:
			for target_name in targets:
				#% Resolve roles:
				if typeof(target_name) == TYPE_STRING and target_name.begins_with(candy_de.role_symbol):
					var role_name = target_name
					if candy_de.roles.has(role_name):
						target_name = candy_de.roles[role_name]
					else:
						printerr("§CSSprite: Unknown role target → ", role_name)
						continue

				var target_node = container.get_node_or_null(NodePath(target_name))
				if not target_node:
					printerr("§CSSprite: Target node not found → ", target_name)
					continue

				#@ Step 5 - Resolve sprite node (via Path 2 or fallbacks):
				var sprite_node: Node = null
				if path_2 != "":
					if "internal_node_dict" in target_node and target_node.internal_node_dict.has(path_2):
						sprite_node = target_node.internal_node_dict[path_2]
					else:
						sprite_node = target_node.get_node_or_null(path_2)
				else:
					sprite_node = target_node.get_node_or_null("Sprite2D")
					if not sprite_node:
						sprite_node = target_node.get_node_or_null("Sprite3D")
					if not sprite_node:
						sprite_node = target_node.get_node_or_null("AnimatedSprite2D")
					if not sprite_node:
						sprite_node = target_node.get_node_or_null("AnimatedSprite3D")

				if not sprite_node:
					printerr("§CSSprite: No compatible sprite node found in → ", target_name)
					continue

				#@ Step 6 - Determine resource path:
				var folder = candy_de.sprite_folder.path_join(target_name)
				var file_name := file_ref if file_ref != "" else "Default"

				if file_name.find(".") == -1:
					if sprite_node is Sprite2D or sprite_node is Sprite3D:
						file_name += candy_de.default_sprite_extension
					elif sprite_node is AnimatedSprite2D or sprite_node is AnimatedSprite3D:
						file_name += candy_de.default_animated_sprite_extension

				var file_path: String
				if sprite_node is AnimatedSprite2D or sprite_node is AnimatedSprite3D:
					file_path = folder.path_join("Sprite Frames").path_join(file_name)
				else:
					file_path = folder.path_join(file_name)

				if not ResourceLoader.exists(file_path):
					printerr("§CSSprite: Missing resource → ", file_path)
					continue

				#@ Step 7 - Initialize cs_loop_data tracking:
				if not target_node.has_meta("cs_loop_data"):
					target_node.set_meta("cs_loop_data", {})
				var cs_loop_data: Dictionary = target_node.get_meta("cs_loop_data")
				cs_loop_data[path_2] = {
					"loop_target": loop,
					"loops_played": 0,
					"wait_target": wait,
					"time_target": time_target,
					"elapsed_time": 0.0,
					"duration": 0.0,
					"paused": (play == 0)
				}

				var data = cs_loop_data[path_2]
				var duration := 0.0

				#@ Step 8 - Stop previous timers or animation:
				var timer := sprite_node.get_node_or_null("CSSpriteTimer")
				if timer:
					timer.stop()
					timer.queue_free()
				if sprite_node is AnimatedSprite2D or sprite_node is AnimatedSprite3D:
					sprite_node.stop()

				#@ Step 9 - Load and apply sprite resource:
				if sprite_node is Sprite2D or sprite_node is Sprite3D:
					var tex := load(file_path)
					if not (tex is Texture2D):
						printerr("§CSSprite: Invalid texture: ", file_path)
						continue

					#% Parse HxV(-C) pattern for frame layout:
					var regex := RegEx.new()
					regex.compile("(\\d+)x(\\d+)(?:-(\\d+))?(?=\\.[^.]+$)")
					var result := regex.search(file_path.get_file())

					var hframes = 1
					var vframes = 1
					var missing = 0
					if result:
						hframes = int(result.get_string(1))
						vframes = int(result.get_string(2))
						if result.get_string(3) != "":
							missing = int(result.get_string(3))

					sprite_node.texture = tex
					sprite_node.hframes = hframes
					sprite_node.vframes = vframes
					sprite_node.frame = 0
					sprite_node.visible = true

					var total_frames = max(hframes * vframes - missing, 1)
					duration = total_frames / candy_de.cs_sprite_fps
					data["duration"] = duration

					if play == 0 or total_frames <= 1:
						continue

					var new_timer = Timer.new()
					new_timer.name = "CSSpriteTimer"
					new_timer.wait_time = 1.0 / candy_de.cs_sprite_fps
					new_timer.autostart = true
					sprite_node.add_child(new_timer)

					var _animate := func():
						while true:
							await new_timer.timeout
							data["elapsed_time"] += 1.0 / candy_de.cs_sprite_fps
							var next_frame = sprite_node.frame + 1
							if next_frame >= total_frames:
								data["loops_played"] += 1
								next_frame = 0
								if loop > 0 and data["loops_played"] >= loop:
									new_timer.stop()
									new_timer.queue_free()
									return
							sprite_node.frame = next_frame
					_animate.call_deferred()

				elif sprite_node is AnimatedSprite2D or sprite_node is AnimatedSprite3D:
					var frames := load(file_path)
					if not (frames is SpriteFrames):
						printerr("§CSSprite: Invalid SpriteFrames resource: ", file_path)
						continue

					sprite_node.sprite_frames = frames
					sprite_node.visible = true

					var anim = anim_name if anim_name != "" and frames.has_animation(anim_name) else (
						file_ref if frames.has_animation(file_ref) else (
							frames.get_animation_names()[0] if frames.get_animation_names().size() > 0 else ""
						)
					)
					if anim == "":
						printerr("§CSSprite: No valid animation found in resource: ", file_path)
						continue

					duration = frames.get_frame_count(anim) / candy_de.cs_sprite_fps
					data["duration"] = duration

					if play == 0:
						sprite_node.frame = 0
						sprite_node.stop()
						continue

					var _anim_loop := func():
						while true:
							sprite_node.play(anim)
							await sprite_node.animation_finished
							data["loops_played"] += 1
							if loop == 0 or data["loops_played"] < loop:
								continue
							else:
								sprite_node.stop()
								return
					_anim_loop.call_deferred()

				else:
					printerr("§CSSprite: Unsupported sprite node type: ", sprite_node)
					continue

				active_nodes.append(target_node)

			#@ Step 10 - Continuous simultaneous wait (if Wait/Time are set):
			if wait > 0 or time_target > 0.0:
				while true:
					var all_done := true
					for node in active_nodes:
						if not node.has_meta("cs_loop_data"):
							continue
						var cs_loop_data: Dictionary = node.get_meta("cs_loop_data")
						if not cs_loop_data.has(path_2):
							continue
						var d = cs_loop_data[path_2]

						d["elapsed_time"] += get_process_delta_time()

						var duration: float = float(d.get("duration", 0.0))
						var loop_target: int = int(d.get("loop_target", 0))
						var loops_played: int = int(d.get("loops_played", 0))
						var resume_at: float = (max(wait, 0) * duration) + max(time_target, 0.0)

						if loop_target > 0 and loops_played < loop_target:
							all_done = false
							break
						elif d["elapsed_time"] < resume_at:
							all_done = false
							break
					if all_done:
						break
					await get_tree().process_frame

			return "Continue"


		#* §CS_Sprite_Wait - Pause dialogue until sprite animations reach a target loop/time or finish playback:
		"§cs_sprite_wait":
			var path_1: Variant			= resolve_value(command_value.get("Path 1", ""))
			var path_2: Variant			= resolve_value(command_value.get("Path 2", ""))
			var targets_raw: Variant	= resolve_value(command_value.get("Targets", ""))
			var wait_raw: Variant		= resolve_value(command_value.get("Wait", ""))
			var time_raw: Variant		= resolve_value(command_value.get("Time", ""))

			#@ Step 1 - Parse target list (comma-separated or array):
			var targets: Array = []
			if targets_raw is String:
				for part in targets_raw.split(",", false):
					var t = part.strip_edges()
					if t != "":
						targets.append(t)
			elif targets_raw is Array:
				targets = targets_raw.duplicate()

			if targets.is_empty():
				printerr("§CSSpriteWait: No Targets provided.")
				return "Continue"

			#@ Step 2 - Parse Wait and Time values:
			var wait_target: int = -1
			var time_target: float = 0.0
			var default_fps: float = 30.0

			if str(wait_raw).strip_edges() != "":
				wait_target = int(wait_raw)

			if typeof(time_raw) == TYPE_STRING:
				var s = time_raw.strip_edges()
				if s != "":
					if s.begins_with("f=") or s.begins_with("F="):
						var frame_val = float(s.substr(2, s.length()))
						time_target = frame_val / default_fps
					else:
						var parts = s.split(":")
						match parts.size():
							3:
								time_target = int(parts[0]) * 3600 + int(parts[1]) * 60 + float(parts[2])
							2:
								time_target = int(parts[0]) * 60 + float(parts[1])
							1:
								time_target = float(parts[0])
			elif typeof(time_raw) in [TYPE_FLOAT, TYPE_INT]:
				time_target = float(time_raw)

			#@ Step 3 - Locate container from Path 1:
			var container = get_node_or_null(cs_locations.get(path_1, ""))
			if not container:
				printerr("§CSSpriteWait: Invalid Path 1 → ", path_1)
				return "Continue"

			#@ Step 4 - Build list of valid tracked targets:
			var tracked_nodes: Array = []
			for target_name in targets:
				#% Resolve role if needed:
				if typeof(target_name) == TYPE_STRING and target_name.begins_with(candy_de.role_symbol):
					var role_name = target_name
					if candy_de.roles.has(role_name):
						target_name = candy_de.roles[role_name]
					else:
						printerr("§CSSpriteWait: Unknown role target → ", role_name)
						continue

				var node = container.get_node_or_null(NodePath(target_name))
				if not node:
					printerr("§CSSpriteWait: Target node not found → ", target_name)
					continue

				if node.has_meta("cs_loop_data") and node.get_meta("cs_loop_data").has(path_2):
					tracked_nodes.append(node)
				else:
					printerr("§CSSpriteWait: Missing cs_loop_data for ", target_name, " (", path_2, ")")

			if tracked_nodes.is_empty():
				printerr("§CSSpriteWait: No active targets to monitor.")
				return "Continue"

			#@ Step 5 - Continuous, simultaneous waiting:
			var done_nodes: Array = []
			while done_nodes.size() < tracked_nodes.size():
				for node in tracked_nodes:
					if node in done_nodes:
						continue

					var cs_loop_data: Dictionary = node.get_meta("cs_loop_data")
					var d = cs_loop_data[path_2]
					d["elapsed_time"] += get_process_delta_time()

					var duration: float = float(d.get("duration", 0.0))
					var loop_target: int = int(d.get("loop_target", 0))
					var loops_played: int = int(d.get("loops_played", 0))
					var elapsed: float = float(d.get("elapsed_time", 0.0))
					var resume_at: float = (max(wait_target, 0) * duration) + max(time_target, 0.0)

					#% Case 1: nothing to wait for:
					if loop_target == 0 and wait_target == -1 and time_target <= 0.0:
						done_nodes.append(node)
						continue

					#% Case 2: target time reached:
					if elapsed >= resume_at:
						done_nodes.append(node)
						continue

					#% Case 3: finished all loops:
					if loop_target > 0 and loops_played >= loop_target:
						done_nodes.append(node)
						continue

				await get_tree().process_frame

			return "Continue"


		#* §CS_Sprite_Stop - Stop sprite animations on one or more target nodes:
		"§cs_sprite_stop":
			var path_1: Variant			= resolve_value(command_value.get("Path 1", ""))
			var path_2: Variant			= resolve_value(command_value.get("Path 2", ""))
			var targets_raw: Variant	= resolve_value(command_value.get("Targets", ""))
			var default_raw: Variant	= resolve_value(command_value.get("Default", "1"))

			var reset_to_first: bool = int(default_raw) == 1

			#@ Step 1 - Parse target list:
			var targets: Array = []
			if targets_raw is String:
				for part in targets_raw.split(",", false):
					var t = part.strip_edges()
					if t != "":
						targets.append(t)
			elif targets_raw is Array:
				targets = targets_raw.duplicate()

			if targets.is_empty():
				printerr("§CSSpriteStop: No Targets provided.")
				return "Continue"

			#@ Step 2 - Locate Path 1 container:
			var container = get_node_or_null(cs_locations.get(path_1, ""))
			if not container:
				printerr("§CSSpriteStop: Invalid Path 1 → ", path_1)
				return "Continue"

			#@ Step 3 - Process each target:
			for target_name in targets:
				#% Resolve role alias:
				if typeof(target_name) == TYPE_STRING and target_name.begins_with(candy_de.role_symbol):
					var role_name = target_name
					if candy_de.roles.has(role_name):
						target_name = candy_de.roles[role_name]
					else:
						printerr("§CSSpriteStop: Unknown role target → ", role_name)
						continue

				var target_node = container.get_node_or_null(NodePath(target_name))
				if not target_node:
					printerr("§CSSpriteStop: Target node not found → ", target_name)
					continue

				#@ Step 4 - Identify sprite node:
				var sprite_node: Node = null
				if path_2 != "":
					if "internal_node_dict" in target_node and target_node.internal_node_dict.has(path_2):
						sprite_node = target_node.internal_node_dict[path_2]
					else:
						sprite_node = target_node.get_node_or_null(path_2)
				else:
					sprite_node = target_node.get_node_or_null("Sprite2D")
					if not sprite_node:
						sprite_node = target_node.get_node_or_null("Sprite3D")
					if not sprite_node:
						sprite_node = target_node.get_node_or_null("AnimatedSprite2D")
					if not sprite_node:
						sprite_node = target_node.get_node_or_null("AnimatedSprite3D")

				if not sprite_node:
					printerr("§CSSpriteStop: No compatible Sprite node found in → ", target_name)
					continue

				#@ Step 5 - Stop playback depending on node type:
				if sprite_node is AnimatedSprite2D or sprite_node is AnimatedSprite3D:
					sprite_node.stop()
					if reset_to_first:
						sprite_node.frame = 0
				elif sprite_node is Sprite2D or sprite_node is Sprite3D:
					var timer := sprite_node.get_node_or_null("CSSpriteTimer")
					if timer:
						timer.stop()
						timer.queue_free()
					if reset_to_first and "frame" in sprite_node:
						sprite_node.frame = 0
				else:
					printerr("§CSSpriteStop: Unsupported node type → ", sprite_node)
					continue

				#@ Step 6 - Clean cs_loop_data metadata:
				if target_node.has_meta("cs_loop_data"):
					var cs_loop_data: Dictionary = target_node.get_meta("cs_loop_data")
					cs_loop_data.erase(path_2)		#/ remove entry completely for clean restart

			return "Continue"


		#* §CS_Visible - Change or toggle visibility on one or more nodes:
		"§cs_visible":
			var path_1: Variant			= resolve_value(command_value.get("Path 1", ""))
			var targets_raw: Variant	= resolve_value(command_value.get("Targets", ""))
			var status: Variant			= resolve_value(command_value.get("Status", ""))

			#@ Step 1 - Locate Path 1 container:
			var container = get_node_or_null(cs_locations.get(path_1, ""))
			if not container:
				printerr("§CSVisible: Invalid Path 1 → ", path_1)
				return "Continue"

			#@ Step 2 - Parse Targets list (comma-separated or array):
			var targets: Array = []
			if targets_raw is String:
				for part in targets_raw.split(",", false):
					var t = part.strip_edges()
					if t != "":
						targets.append(t)
			elif targets_raw is Array:
				targets = targets_raw.duplicate()

			if targets.is_empty():
				printerr("§CSVisible: No Targets specified.")
				return "Continue"

			#@ Step 3 - Resolve role aliases and collect valid nodes:
			var target_nodes: Array = []
			for ref in targets:
				#% Handle role alias:
				if typeof(ref) == TYPE_STRING and ref.begins_with(candy_de.role_symbol):
					var role_name = ref
					if candy_de.roles.has(role_name):
						ref = candy_de.roles[role_name]
					else:
						printerr("§CSVisible: Unknown role target → ", role_name)
						continue

				#% Resolve node:
				var node: Node = null
				if ref is Node:
					node = ref
				elif typeof(ref) == TYPE_STRING:
					node = container.get_node_or_null(NodePath(ref))

				if node:
					target_nodes.append(node)
				else:
					printerr("§CSVisible: Target node not found → ", ref)

			if target_nodes.is_empty():
				printerr("§CSVisible: No valid target nodes found.")
				return "Continue"

			#@ Step 4 - Change visibility:
			var status_str := str(status).strip_edges().to_lower()

			for node in target_nodes:
				match status_str:
					"true", "1", "on", "show", "visible":
						node.visible = true
					"false", "0", "off", "hide", "hidden":
						node.visible = false
					"toggle":
						node.visible = not node.visible
					_:
						printerr("§CSVisible: Unknown status value → ", status_str, " (Node: ", node.name, ")")

			return "Continue"


		#* §CS_Toggle - Toggle or set properties on one or more nodes in the game world:
		"§cs_toggle":
			var path_1: Variant				= resolve_value(command_value.get("Path 1", ""))
			var targets_raw: Variant		= resolve_value(command_value.get("Targets", ""))
			var toggle_method: Variant		= resolve_value(command_value.get("Method", ""))
			var toggle_properties: Variant	= resolve_value(command_value.get("Properties", ""))
			var toggle_value: Variant		= resolve_value(command_value.get("Value", ""))

			#@ Step 1 - Locate Path 1 container:
			var container = get_node_or_null(cs_locations.get(path_1, ""))
			if not container:
				printerr("§CSToggle: Invalid Path 1 → ", path_1)
				return "Continue"

			#@ Step 2 - Parse Targets list (comma-separated or array):
			var targets: Array = []
			if targets_raw is String:
				for part in targets_raw.split(",", false):
					var t = part.strip_edges()
					if t != "":
						targets.append(t)
			elif targets_raw is Array:
				targets = targets_raw.duplicate()

			if targets.is_empty():
				printerr("§CSToggle: No Targets provided.")
				return "Continue"

			#@ Step 3 - Resolve nodes and role aliases:
			var target_nodes: Array = []
			for ref in targets:
				#% Role resolution:
				if typeof(ref) == TYPE_STRING and ref.begins_with(candy_de.role_symbol):
					var role_name = ref
					if candy_de.roles.has(role_name):
						ref = candy_de.roles[role_name]
					else:
						printerr("§CSToggle: Unknown role target → ", role_name)
						continue

				#% Node lookup:
				var node: Node = null
				if ref is Node:
					node = ref
				elif typeof(ref) == TYPE_STRING:
					node = container.get_node_or_null(NodePath(ref))

				if node:
					target_nodes.append(node)
				else:
					printerr("§CSToggle: Target node not found → ", ref)

			if target_nodes.is_empty():
				printerr("§CSToggle: No valid target nodes found.")
				return "Continue"

			#@ Step 4 - Apply toggles:
			for n in target_nodes:
				if n.has_method("candy_toggle"):
					n.candy_toggle(toggle_method, toggle_properties, toggle_value)
				else:
					printerr("§CSToggle: Node lacks candy_toggle() → ", n.name)

			return "Continue"


		#* §CS_Cam - Switch the active camera:
		"§cs_cam":
			var path_1: Variant	= resolve_value(command_value.get("Path 1", ""))
			var camera: Variant	= resolve_value(command_value.get("Targets", ""))

			#@ Step 1 - Identify camera node:
			var cam = null

			if camera is Camera3D or camera is Camera2D:
				#% Direct node reference (resolved_value() already returned the node):
				cam = camera
			elif typeof(camera) == TYPE_STRING:
				#% Fallback: lookup in cs_locations[path_1]:
				var cameras_container = get_node_or_null(cs_locations.get(path_1, ""))
				if cameras_container:
					cam = cameras_container.get_node_or_null(NodePath(camera))

			#@ Step 2 - Activate camera:
			if cam:
				cam.current = true
			else:
				printerr("§CSCam: camera not found → ", camera)

			return "Continue"


		#* §CS_Light - Change color and/or energy of one or more Light2D/Light3D nodes:
		"§cs_light":
			var path_1: Variant			= resolve_value(command_value.get("Path 1", ""))
			var targets_raw: Variant	= resolve_value(command_value.get("Targets", ""))
			var op: Variant				= resolve_value(command_value.get("Operator", "="))
			var color_val: Variant		= resolve_value(command_value.get("Color", null))
			var energy_val: Variant		= resolve_value(command_value.get("Energy", null))

			#@ Step 1 - Parse Targets list (comma-separated or array):
			var targets: Array = []
			if targets_raw is String:
				for part in targets_raw.split(",", false):
					var t = part.strip_edges()
					if t != "":
						targets.append(t)
			elif targets_raw is Array:
				targets = targets_raw.duplicate()

			if targets.is_empty():
				printerr("§CSLight: No Targets specified.")
				return "Continue"

			#@ Step 2 - Locate Path 1 container:
			var container = get_node_or_null(cs_locations.get(path_1, ""))
			if not container:
				printerr("§CSLight: Invalid Path 1 → ", path_1)
				return "Continue"

			#@ Step 3 - Iterate over each target light:
			for target_name in targets:
				#% Resolve role aliases if needed:
				if typeof(target_name) == TYPE_STRING and target_name.begins_with(candy_de.role_symbol):
					var role_name = target_name
					if candy_de.roles.has(role_name):
						target_name = candy_de.roles[role_name]
					else:
						printerr("§CSLight: Unknown role target → ", role_name)
						continue

				var light = container.get_node_or_null(NodePath(target_name))
				if not light or not (light is Light2D or light is Light3D):
					printerr("§CSLight: Light node not found or incompatible → ", target_name)
					continue

				#@ Step 4 - If Color provided, resolve and apply:
				if color_val != null and color_val != "":
					var color_obj: Color = Color(1, 1, 1)

					if color_val is Color:
						color_obj = color_val

					elif typeof(color_val) == TYPE_STRING:
						var s = color_val.strip_edges()
						if s.begins_with("#"):
							color_obj = Color(s)
						elif s.begins_with("(") and s.ends_with(")"):
							var stripped = s.substr(1, s.length() - 2)
							var nums = stripped.split(",")
							match nums.size():
								3:
									color_obj = Color(float(nums[0]), float(nums[1]), float(nums[2]))
								4:
									color_obj = Color(float(nums[0]), float(nums[1]), float(nums[2]), float(nums[3]))
						else:
							color_obj = Color(s)

					elif typeof(color_val) == TYPE_ARRAY and color_val.size() >= 3:
						color_obj = Color(float(color_val[0]), float(color_val[1]), float(color_val[2]))
					elif typeof(color_val) == TYPE_DICTIONARY:
						color_obj = Color(
							float(color_val.get("r", 1)),
							float(color_val.get("g", 1)),
							float(color_val.get("b", 1)),
							float(color_val.get("a", 1))
						)

					light.light_color = color_obj
					print("§CSLight (color) →", light.name, "=", color_obj)

				#@ Step 5 - If Energy provided, resolve and apply:
				if energy_val != null and energy_val != "":
					var value: float = 0.0
					if typeof(energy_val) in [TYPE_INT, TYPE_FLOAT]:
						value = float(energy_val)
					elif typeof(energy_val) == TYPE_STRING:
						if energy_val.is_valid_float() or energy_val.is_valid_int():
							value = float(energy_val)
						else:
							printerr("§CSLight: invalid numeric value → ", energy_val)
							continue
					else:
						printerr("§CSLight: unsupported energy value type → ", typeof(energy_val))
						continue

					var current_energy = light.light_energy
					var new_energy = current_energy

					match op:
						"=":
							new_energy = value
						"+":
							new_energy = current_energy + value
						"-":
							new_energy = current_energy - value
						"*":
							new_energy = current_energy * value
						"/":
							if value != 0:
								new_energy = current_energy / value
							else:
								printerr("§CSLight: attempted division by zero")

					light.light_energy = new_energy
					print("§CSLight (energy) →", light.name, "=", new_energy)

			return "Continue"
		#endregion - cutscene commands


		#&########################################
		#&										##
		#&			 CUSTOM COMMANDS			##
		#&										##
		#? You may add your own custom commands here, either standalone or as part of the §Custom command.
		#region - Custom Commands
		"§custom":
			var command: Variant	= resolve_value(command_value.get("Command", ""))
			var data: Variant		= command_value.get("Data", "")

			if data.begins_with(candy_de.super_singleton_symbol):
				data = resolve_value(candy_de.singleton_symbol + data.substr(1))
			elif data.begins_with(candy_de.super_node_symbol):
				data = resolve_value(candy_de.node_symbol + data.substr(1))
			elif data.begins_with(candy_de.super_vardict_symbol):
				data = resolve_value(candy_de.vardict_symbol + data.substr(1))

			match command:
				#TODO: Add your own commands

				_:
					pass

		#endregion - custom commands


#* Lets the engine read command names even if they contain uppercase, lowercase, underscores and dashes:
func normalize_command_name(raw_key: String) -> String:
	#% Temporarily remove the command symbol (§):
	var command_name = raw_key.substr(command_symbol.length())

	#% Normalize the command name:
	command_name = command_name.to_lower()
	command_name = command_name.replace("-", "")

	return command_symbol + command_name
#endregion



#°#########################################################################################
#^
#^										  ENGINE
#^
#°#########################################################################################
#region

#?##############################
#& ENGINE CORE:
#?#############
#region

func _ready() -> void:
	#@ Assign self as caller to child UI elements:
	for path in ui_elements_paths:
		var node = get_node_or_null(ui_elements_paths[path])
		if node and node.has_method("caller"):
			node.caller = self

	for path in media_players_locations:
		var node = get_node_or_null(media_players_locations[path])
		if node and node.has_method("caller"):
			node.caller = self


#* Load dialogue script from .txt file into running_dialogue:
#? Looks for .txt files in the dialogues folder.
#? Provide the file name as an argument.
func load_scripted_dialogue(file_name: String) -> void:
	var path = candy_de.dialogues_folder.path_join(file_name + ".txt")

	#@ Step 1 - Open the file:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Candy DE: Could not open dialogue file: " + path)
		return

	var text_data := file.get_as_text()
	file.close()

	#@ Step 2 - Clean and normalize exported syntax:
	#% Replace <null> placeholders with proper GDScript null:
	text_data = text_data.replace("<null>", "null")
	text_data = text_data.replace("<Null>", "null")

	#% Remove ONLY trailing commas directly before } or ]:
	var regex_trailing := RegEx.new()
	regex_trailing.compile(",(\\s*[}\\]])")
	text_data = regex_trailing.sub(text_data, "$1", true)

	#% Trim whitespace and stray commas at file start/end:
	text_data = text_data.strip_edges()
	if text_data.ends_with(","):
		text_data = text_data.substr(0, text_data.length() - 1)

	#@ Step 3 - Parse safely with Expression:
	var expr := Expression.new()

	if expr.parse(text_data) != OK:
		push_error("Candy DE: Failed to parse .txt dialogue file: " + path)
		return

	var result = expr.execute()

	if expr.has_execute_failed():
		push_error("Candy DE: Runtime error while evaluating .txt dialogue file: " + path)
		return

	if typeof(result) != TYPE_DICTIONARY:
		push_error("Candy DE: Dialogue file root must be a Dictionary: " + path)
		return

	#@ Step 4 - Validate new export format:
	if not result.has("Dialogue"):
		push_error("Candy DE: Invalid dialogue format (missing 'Dialogue' section): " + path)
		return

	if typeof(result["Dialogue"]) != TYPE_DICTIONARY:
		push_error("Candy DE: 'Dialogue' section must be a Dictionary: " + path)
		return

	#@ Step 5 - Store successfully loaded dialogue only:
	running_dialogue = result["Dialogue"]

	print("Candy DE: Loaded dialogue file:", path)

#* Initiate dialogue:
#? Call this to start a dialogues.
func start_dialogue(conversation, start_block, start_line):
	#@ Change game state to indicate dialogue is running:
	candy_de.change_game_state(self, "start")

	#@ Make UI visible:
	self.visible = true

	#@ Set Mouse Mode:
	if mouse_mode_start != MouseModes.None:
		Input.set_mouse_mode(mouse_mode_start as Input.MouseMode)

	#@ Note that a dialogue is running:
	dialogue_running = true

	#@ Call RSD:
	run_dialogue(conversation, start_block, start_line, "Text", true)


#* Used by §Jump to start a new run_dialogue():
func jump_start_dialogue(new_conversation, new_block, target_line):
	print("Jump-starting dialogue.")
	while greenlight == false:
		await get_tree().process_frame

	print("Jump-start: Greenlight true")
	run_dialogue(new_conversation, new_block, target_line, "Text", true)


#* Process dialogue lines in order:
func run_dialogue(current_conversation, current_block, line_index, source, main):
	print("Run_dialogue()")
	print(current_conversation)
	print(current_block)
	print(line_index)
	#@ Step 0 - Update progress trackers, check killswitch and dialogue suspension:
	#% Update progress trackers:
	conversation_tracker = current_conversation
	block_tracker = current_block
	line_tracker = line_index

	#% Killswitch:
	if killswitch == true:
		if main == false:
			return "END"
		elif main == true:
			await killswitch_off

	#% Suspended Dialogue:
	if dialogue_suspended == true:
		while dialogue_suspended == true:
			await get_tree().process_frame

	#@ Step 1 - Determine text array:
	var text_array
	if typeof(source) == TYPE_STRING and source == "Text":
		text_array = running_dialogue[current_conversation][current_block]["Text"]
	else:
		text_array = source

	#@ Step 2 - Resolve LM reference if line_index is a string:
	if typeof(line_index) == TYPE_STRING:
		var target_index := 0
		for i in range(text_array.size()):
			var ld = text_array[i]
			if ld.has("§LM") and str(ld["§LM"]) == line_index:
				target_index = i
				break
		line_index = target_index

	#@ Step 3 - Loop through all lines in sequence:
	var index = line_index
	while index < text_array.size():
		var feedback = await process_lines(current_conversation, current_block, index, source, main)

		#@ Step 4 - Interpret feedback:
		match feedback:
			"END":
				if main == false:
					print("run_dialogue() - Step 4: main = false, return 'END'.")
					return "END"
				if main == true:
					print("run_dialogue() - Step 4: main = true, call end_dialogue().")
					break

			"Return":
				print("run_dialogue() - Step 4: feedback = 'Return', break.")
				break

			"Continue":
				#% Normal dialogue progression:
				index += 1
				print("run_dialogue() - Step 4: feedback = 'Continue', continue to next line.")

	#@ Step 5 - Dialogue finished:
	if main == false:
		print("run_dialogue() - Step 5: main = false, return 'Continue'.")
		return "Continue"
	elif main == true:
		print("run_dialogue() - Step 5: main = true, call end_dialogue().")
		end_dialogue()


#* Process lines:
func process_lines(current_conversation, current_block, line_index, source, main) -> String:
	var feedback = "Continue"

	#@ Check killswitch and dialogue suspension:
	#% Killswitch:
	if killswitch == true:
		if main == false:
			return "END"
		elif main == true:
			await killswitch_off

	#% Suspended Dialogue:
	if dialogue_suspended == true:
		while dialogue_suspended == true:
			await get_tree().process_frame

	#@ Retrieve text array:
	var text_array
	if typeof(source) == TYPE_STRING and source == "Text":
		text_array = running_dialogue[current_conversation][current_block]["Text"]
	else:
		text_array = source

	#% End early if index is out of range:
	if line_index >= text_array.size():
		return "END"

	#@ Prepare line data:
	var line_data = text_array[line_index]

	#@ Skip §LM and §Comment lines:
	var command_name = line_data.keys()[0]
	if command_name in ["§LM", "§Comment"]:
		return "Continue"

	var last_cmd := ""

	#. Hook call:
	if candy_de.has_method("x_new_line"):
		await candy_de.x_new_line(self, line_data)

	#@ Process line keys:
	for raw_key in line_data.keys():
		var value = line_data[raw_key]

		#@ §Commands:
		if raw_key.begins_with(command_symbol):
			#. Hook call:
			if candy_de.has_method("x_command_start"):
				await candy_de.x_command_start(self, line_data)

			feedback = await commands(raw_key, value, current_conversation, current_block, line_index)
			last_cmd = normalize_command_name(raw_key)

			#% Feedback + Killswitch check:
			if feedback == "END" or killswitch == true:
				if main == false:
					print("AAA")
					return "END"
				elif main == true:
					print("BBB")
					killswitch = false
					emit_signal("killswitch_off")
					return "END"

			#% Suspended Dialogue:
			if dialogue_suspended == true:
				while dialogue_suspended == true:
					await get_tree().process_frame

		#@ Spoken lines:
		elif raw_key == "Spoken Line":
			#% Killswitch check:
			if killswitch == true:
				if main == false:
					return "END"
				elif main == true:
					killswitch = false
					emit_signal("killswitch_off")
					return "END"

			#% Suspended Dialogue:
			if dialogue_suspended == true:
				while dialogue_suspended == true:
					await get_tree().process_frame

			#. Hook call:
			if candy_de.has_method("x_new_speech_start"):
				await candy_de.x_new_speech_start(self, line_data)

			#@ Step 1 - Validate format:
			if typeof(value) != TYPE_DICTIONARY:
				continue

			var speech_data: Dictionary = value

			#@ Step 2 - Resolve speaker reference:
			var speaker_ref = resolve_value(speech_data.get("Reference", ""))

			#@ Step 3A - Resolve disposition condition:
			var disposition_raw = speech_data.get("Disposition", "")
			var disposition_cond = str(disposition_raw)

			if typeof(disposition_raw) == TYPE_STRING:
				#% Find and replace all embedded variable references:
				var token_regex := RegEx.new()
				token_regex.compile(r"(?:[%s%s%s])[A-Za-z0-9_.]+" % [
					candy_de.vardict_symbol,
					candy_de.node_symbol,
					candy_de.singleton_symbol
				])

				var matches := token_regex.search_all(disposition_cond)
				for m in matches:
					var token := m.get_string()
					var decoded := decode_variable_name(token)
					var resolved = get_variable_value(decoded)
					if resolved != null:
						disposition_cond = disposition_cond.replace(token, str(resolved))

			disposition_cond = disposition_cond.strip_edges()

			#@ Step 3B - Retrieve actor’s dispositions:
			if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("Disposition"):
				var actor_disp_raw: String = str(candy_de.actors[speaker_ref]["Disposition"]).strip_edges()
				var actor_disps: Array = actor_disp_raw.split(",", false)
				actor_disps = actor_disps.map(func(x): return x.strip_edges())

				#@ Step 3C - Parse disposition condition:
				var prefix := ""
				var match_count := -1	#/ Default means no numeric condition
				var is_negated := false

				#% Extract prefix characters before first alphanumeric or '(':
				for i in disposition_cond.length():
					var ch = disposition_cond[i]
					if ch.is_valid_identifier() or ch == "(":
						prefix = disposition_cond.substr(0, i)
						disposition_cond = disposition_cond.substr(i).strip_edges()
						break

				#% Detect numeric pattern like (n):
				var numeric_regex := RegEx.new()
				numeric_regex.compile(r"^\((\d+)\)")
				var match := numeric_regex.search(disposition_cond)
				if match:
					match_count = int(match.get_string(1))
					disposition_cond = disposition_cond.substr(match.get_end(0)).strip_edges()

				#% Clean up prefix and detect flags:
				is_negated = prefix.find("!") != -1
				var has_plus = prefix.find("+") != -1
				var has_minus = prefix.find("-") != -1
				var has_equal = prefix.find("=") != -1

				#@ Step 3D - Split disposition list:
				var cond_disps: Array = []
				if disposition_cond != "":
					disposition_cond = disposition_cond.trim_suffix(",").strip_edges()
					cond_disps = disposition_cond.split(",", false)
					if cond_disps.size() == 1:
						cond_disps = disposition_cond.split(".", false)
					cond_disps = cond_disps.map(func(x): return x.strip_edges())

				#@ Step 3E - Evaluate numeric-based matching:
				var overlap_count = actor_disps.filter(func(d): return cond_disps.has(d)).size()
				var passes := false

				#% If numeric form exists:
				if match_count >= 0:
					if is_negated:
						if has_plus:
							passes = ((cond_disps.size() - overlap_count) >= match_count)	#/ n or more must NOT match
						elif has_minus:
							passes = ((cond_disps.size() - overlap_count) < match_count)	#/ less than n must NOT match
						else:
							#% Exactly n must NOT match:
							passes = ((cond_disps.size() - overlap_count) == match_count)
							#% Strict mode (=!) → actor cannot have extra dispositions:
							if has_equal and passes:
								passes = actor_disps.all(func(d): return cond_disps.has(d))

					else:
						if has_plus:
							passes = (overlap_count >= match_count)							#/ n or more must match
						elif has_minus:
							passes = (overlap_count < match_count)							#/ less than n must match
						else:
							#% Exactly n must match:
							passes = (overlap_count == match_count)
							#% Strict mode (=) → actor cannot have extra dispositions:
							if has_equal and passes:
								passes = actor_disps.all(func(d): return cond_disps.has(d))

				#% Otherwise symbolic or plain form:
				else:
					if is_negated:
						passes = cond_disps.all(func(d): return not actor_disps.has(d))		#/ none must match
					elif has_equal:
						passes = (actor_disps.size() == cond_disps.size()) and actor_disps.all(func(d): return cond_disps.has(d))
					elif has_plus:
						passes = cond_disps.all(func(d): return actor_disps.has(d))			#/ all listed must match
					elif has_minus:
						passes = actor_disps.all(func(d): return cond_disps.has(d))			#/ all actor’s must match
					else:
						passes = cond_disps.any(func(d): return actor_disps.has(d))			#/ at least one must match

				if disposition_raw == "":
					passes = true

				#@ Step 3F - Skip line if condition fails:
				if not passes:
					continue

			#@ Step 4 - Variant selection:
			var chosen_variant: String = candy_de.language	#/ Start from the language
			var variants: Array = speech_data.get("Variants", [])

			#? You may add more variant options here - e.g. moral alignment, character class, etc.
			#? The order doesn't matter as long as it matches the tag order in your variant names, except Random should be last.
			#?
			#? Tags are optional. If variants don't exist for a tag, the tag is ignored.
			#? In other words, the engine can never end up trying to display a variant that doesn't exist.
			#?
			#? If adding your own criteria, the logic should be:
			#? 	1) check if a variant matching chosen_variant + tag' exists;
			#? 	2) if so, append tag to chosen_variant.

			#@ Player gender variant:
			if player_gender_variants:
				var gender_tag = str(player_gender)
				var test_variant = chosen_variant + "_P:" + gender_tag		#/ "_P:M", "_P:F", or any other gender value you choose
				#% Check if variant exists (any form):
				for entry in variants:
					if entry.has(test_variant):
						chosen_variant = test_variant
						print("Variant - player gender: " + str(chosen_variant))
						break

			#@ Speaker gender variant:
			if speaker_gender_variants and candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("Gender"):
				var speaker_gender = str(candy_de.actors[speaker_ref]["Gender"])
				var test_variant = chosen_variant + "_S:" + speaker_gender	#/ "_S:M", "_S:F", or any other gender value you choose
				for entry in variants:
					if entry.has(test_variant):
						chosen_variant = test_variant
						print("Variant - speaker gender: " + str(chosen_variant))
						break

			#@ Random variant (always last step):
			#? Looks for variant names ending in "_#int" but will also include chosen_variant without "_#int" if it exists.
			var chosen_text := ""
			var text_direction := ""
			var pool: Array = []
			var pool_names: Array = []	#/ Array for variant names
			var pool_directions: Array = []

			for entry in variants:
				for variant_name in entry.keys():
					var weight := 1
					var raw_weight = entry[variant_name].get("Weight", "1")
					if typeof(raw_weight) == TYPE_STRING and raw_weight.strip_edges().is_valid_int():
						weight = max(1, int(raw_weight.strip_edges()))

					#% Always add the exact variant if it exists:
					if variant_name == chosen_variant:
						for _i in range(weight):
							pool.append(entry[variant_name].get("Text", ""))
							pool_names.append(variant_name)
							pool_directions.append(entry[variant_name].get("Direction", ""))

					#% Add numbered sub-variants only if randomization is enabled:
					elif random_variants and \
					variant_name.begins_with(chosen_variant + "_%s" % "\u0023") and \
					variant_name.substr(chosen_variant.length() + 2).is_valid_int():
						for _i in range(weight):
							pool.append(entry[variant_name].get("Text", ""))
							pool_names.append(variant_name)
							pool_directions.append(entry[variant_name].get("Direction", ""))

			#% Select variant:
			if pool.size() > 0:
				if random_variants:
					var index := randi() % pool.size()		#/ Random pick if multiple options
					chosen_text = pool[index]
					chosen_variant = pool_names[index]
					text_direction = pool_directions[index]
					print("Variant - random: " + str(chosen_variant))
				else:
					chosen_text = pool[0]					#/ Deterministic: use first found
					chosen_variant = pool_names[0]
					text_direction = pool_directions[0]

			#% Skip line if no variant matches:
			if chosen_text == "":
				continue

			var line_str = chosen_text

			#@ Step 5 - Variable substitution in spoken text:
			var start_tag = candy_de.text_var_symbol_start
			var end_tag = candy_de.text_var_symbol_end

			var changed = true
			while changed:
				changed = false
				var pos = 0

				while true:
					var start_idx = line_str.find(start_tag, pos)
					if start_idx == -1:
						break
					var end_idx = line_str.find(end_tag, start_idx + start_tag.length())
					if end_idx == -1:
						break

					var var_name = line_str.substr(
						start_idx + start_tag.length(),
						end_idx - (start_idx + start_tag.length())
					)
					var replacement := ""

					#% Handle prefixed variable decoding (€, $, £, °):
					if var_name.begins_with(candy_de.vardict_symbol) \
					or var_name.begins_with(candy_de.singleton_symbol) \
					or var_name.begins_with(candy_de.node_symbol) \
					or var_name.begins_with(candy_de.role_symbol):
						var resolved = resolve_value(var_name)
						if resolved != null:
							replacement = str(resolved)

					#% Unprefixed variable → lookup in actors (supports nested keys):
					else:
						var regex = RegEx.new()
						regex.compile(r'([^\[\"]+)(?:\[(?:\"|\')([^\"\']+)(?:\"|\')\])*')

						var actor_name = var_name
						var key_path: Array = []

						var match = regex.search(var_name)
						if match:
							actor_name = match.get_string(1).strip_edges()

							#% Find all keys inside brackets: e.g. Alice["Age"]["Subkey"]:
							var key_regex = RegEx.new()
							key_regex.compile(r'\[(?:\"|\')([^\"\']+)(?:\"|\')\]')
							var key_matches = key_regex.search_all(var_name)
							for m in key_matches:
								key_path.append(m.get_string(1).strip_edges())

						#% Start from actor dictionary:
						if candy_de.actors.has(actor_name):
							var current = candy_de.actors[actor_name]

							#% If no nested keys/indexes, display "Short Name":
							if key_path.size() == 0:
								if typeof(current) == TYPE_DICTIONARY and current.has("Short Name"):
									current = current["Short Name"]
								#TODO: If the actor doesn't have the "Short Name" key, the actor reference is displayed;
								#TODO: Re-activate the code below to display the actor's full dictionary:
								#else:
									#current = null

							#% If nested keys/indexes, display their value:
							else:
								#% Traverse nested keys if present:
								for key in key_path:
									if typeof(current) == TYPE_DICTIONARY and current.has(key):
										current = current[key]
									else:
										#TODO: If the actor doesn't have one of the keys, the actor reference is displayed;
										#TODO: Re-activate the code below to display the actor's full dictionary:
										#current = null
										break

							if current != null:
								replacement = str(current)

					#% Replace variable in text:
					line_str = line_str.substr(0, start_idx) + replacement + line_str.substr(end_idx + end_tag.length())
					pos = start_idx + replacement.length()
					changed = true

			#@ Step 6 - Category-based word substitution:
			#% Look for tokens like •word¦actor or •word¦actor¦property•:
			if candy_de.substitution_table != null:
				var gsym = candy_de.substitution_symbol
				var gsep = candy_de.separator_symbol
				var search_pos := 0
				var chosen_variant_lc := chosen_variant.to_lower()

				#@ Helper: Get nested dictionary or array value ("stats.Age" or "stats.0.Name"):
				var _get_nested_property = func(data: Variant, path: String) -> Variant:
					var parts = path.split(".", false)
					var current = data
					for part in parts:
						if typeof(current) == TYPE_DICTIONARY:
							if not current.has(part):
								return null
							current = current[part]
						elif typeof(current) == TYPE_ARRAY:
							if not part.is_valid_int():
								return null
							var idx = int(part)
							if idx < 0 or idx >= current.size():
								return null
							current = current[idx]
						else:
							return null
					return current

				while true:
					var start_idx := line_str.find(gsym, search_pos)

					if start_idx == -1:
						break

					var end_idx := line_str.find(gsym, start_idx + gsym.length())
					if end_idx == -1:
						break

					#% Extract internal section: "word¦actor" or "word¦actor¦property":
					var token := line_str.substr(
						start_idx + gsym.length(),
						end_idx - (start_idx + gsym.length())
					)

					var parts := token.split(gsep, false)
					if parts.size() < 2:
						search_pos = end_idx + gsym.length()
						continue

					var source_word_raw := parts[0]
					var source_word := parts[0].strip_edges()
					var actor_ref2 := parts[1].strip_edges()

					#% Variable resolution for keyword (left side):
					if source_word.begins_with(candy_de.vardict_symbol) \
					or source_word.begins_with(candy_de.singleton_symbol) \
					or source_word.begins_with(candy_de.node_symbol) \
					or source_word.begins_with(candy_de.role_symbol):
						var resolved_word = resolve_value(source_word)
						if resolved_word != null:
							source_word = str(resolved_word).strip_edges()
							source_word_raw = source_word

					#% Variable resolution (supports £, •, or $ references):
					if actor_ref2.begins_with(candy_de.vardict_symbol) \
					or actor_ref2.begins_with(candy_de.singleton_symbol) \
					or actor_ref2.begins_with(candy_de.node_symbol) \
					or actor_ref2.begins_with(candy_de.role_symbol):
						var resolved = resolve_value(actor_ref2)
						if resolved != null:
							actor_ref2 = str(resolved).strip_edges()

					var category_override := ""
					if parts.size() >= 3:
						category_override = parts[2].strip_edges()

						#% Variable resolution for property/category override (third argument):
						if category_override.begins_with(candy_de.vardict_symbol) \
						or category_override.begins_with(candy_de.singleton_symbol) \
						or category_override.begins_with(candy_de.node_symbol) \
						or category_override.begins_with(candy_de.role_symbol):
							var resolved_cat = resolve_value(category_override)
							if resolved_cat != null:
								category_override = str(resolved_cat).strip_edges()

					if not candy_de.actors.has(actor_ref2):
						search_pos = end_idx + gsym.length()
						continue

					var base := source_word.to_lower()
					var replacement_base := ""
					var matched := false
					var case_rule := "auto"

					#@ Variant matching (select closest match):
					var variant_matches_array: Array = []
					var exact_matches: Array = []

					for variant_key in candy_de.substitution_table.keys():
						var vk = variant_key.to_lower()
						if vk == "*":
							variant_matches_array.append(variant_key)
						elif vk.ends_with("*"):
							var prefix = vk.substr(0, vk.length() - 1)
							if chosen_variant_lc.begins_with(prefix):
								variant_matches_array.append(variant_key)
						elif vk == chosen_variant_lc:
							variant_matches_array.append(variant_key)
							exact_matches.append(variant_key)

					#@ Filter variants that actually contain the base word:
					var word_table: Dictionary
					var viable_variants: Array = []

					for variant_key in variant_matches_array:
						word_table = candy_de.substitution_table[variant_key]
						for key in word_table.keys():
							var options: Array = key.split(",", false)
							options = options.map(func(x): return x.strip_edges().to_lower())
							if options.has(base):
								viable_variants.append(variant_key)
								break

					if viable_variants.size() == 0:
						search_pos = end_idx + gsym.length()
						continue

					#@ Sort alphabetically:
					viable_variants.sort()

					#@ Move exact matches to end (highest priority):
					for ex in exact_matches:
						if viable_variants.has(ex):
							viable_variants.erase(ex)
							viable_variants.append(ex)

					var best_variant_key = viable_variants.back()
					word_table = candy_de.substitution_table[best_variant_key]

					#% Iterate word groups ("he, she", "class", etc.):
					for key in word_table.keys():
						var options: Array = key.split(",", false)
						options = options.map(func(x): return x.strip_edges().to_lower())
						if not options.has(base):
							continue

						var category_list = word_table[key]

						#% Determine case rule (optional first element):
						var entry_start_index := 0
						if category_list.size() > 0 and typeof(category_list[0]) == TYPE_STRING:
							case_rule = category_list[0]
							entry_start_index = 1
						else:
							case_rule = "auto"

						#% Numeric override → specific array index:
						var specific_entry_index := -1
						if category_override.is_valid_int():
							specific_entry_index = clamp(int(category_override) - 1, 0, category_list.size() - 1)

						#% Multi-category search:
						var i_start := entry_start_index
						var i_end = category_list.size()
						if specific_entry_index >= 0:
							i_start = specific_entry_index
							i_end = specific_entry_index + 1

						for i in range(i_start, i_end):
							var entry = category_list[i]
							for category_key in entry.keys():
								if category_override != "" and not category_override.is_valid_int() and category_key != category_override:
									continue

								var cat_names: Array = category_key.split(",", false)
								cat_names = cat_names.map(func(x): return x.strip_edges())

								var actor_values := []
								var valid_group := true
								for cname in cat_names:
									var val = _get_nested_property.call(candy_de.actors[actor_ref2], cname)
									if val == null:
										valid_group = false
										break
									actor_values.append(str(val).strip_edges())
								if not valid_group:
									continue
								var value_map = entry[category_key]

								#@ Operator / Type-aware matching:
								for vk_rule in value_map.keys():
									var rules: Array = vk_rule.split(",", false)
									rules = rules.map(func(x): return x.strip_edges())
									var all_match := true
									for r_i in range(rules.size()):
										if r_i >= actor_values.size():
											continue
										var rule = rules[r_i].strip_edges()

										#% Skip marker → user-defined (default "_"):
										if rule == empty_symbol:
											continue

										var prop_value = actor_values[r_i]

										#% Normalize property value:
										match typeof(prop_value):
											TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
												prop_value = str(prop_value)
											TYPE_ARRAY, TYPE_DICTIONARY:
												prop_value = JSON.stringify(prop_value)
											TYPE_STRING:
												prop_value = prop_value.strip_edges()
											_:
												prop_value = str(prop_value)

										#@ Unified rule parser:
										var op_part := ""
										var value_part = rule
										var type_hint := ""
										var type_compare := false
										var parts_rule = rule.split(gsep, false)
										if parts_rule.size() == 3:
											#% operator¦value¦type:
											op_part = parts_rule[0].strip_edges()
											value_part = parts_rule[1].strip_edges()
											type_hint = parts_rule[2].strip_edges().to_lower()
										elif parts_rule.size() == 2:
											var left = parts_rule[0].strip_edges()
											var right = parts_rule[1].strip_edges().to_lower()
											var is_operator = left in [">", "<", ">=", "<="]
											var is_number = right.is_valid_float() or right.is_valid_int()
											var is_known_type = right in ["int", "float", "bool", "string", "array", "dict", "dictionary"]
											var is_type_compare = right == "type" and left in is_known_type

											if is_operator and is_number:
												op_part = left
												value_part = right
											elif is_known_type:
												value_part = left
												type_hint = right
											elif is_type_compare:
												type_compare = true
												value_part = left
											else:
												value_part = rule
										else:
											value_part = rule
										#% Type comparison rule (int¦type, etc.):
										if type_compare:
											var type_map := {
												"int": TYPE_INT,
												"float": TYPE_FLOAT,
												"bool": TYPE_BOOL,
												"string": TYPE_STRING,
												"array": TYPE_ARRAY,
												"dict": TYPE_DICTIONARY,
												"dictionary": TYPE_DICTIONARY,
											}
											var nested_val = _get_nested_property.call(candy_de.actors[actor_ref2], cat_names[r_i])
											if nested_val == null or typeof(nested_val) != type_map.get(value_part, -1):
												all_match = false
											continue
										#% Apply type hint if any:
										match type_hint:
											"int":
												value_part = int(value_part)
												prop_value = int(prop_value)
											"float":
												value_part = float(value_part)
												prop_value = float(prop_value)
											"bool":
												value_part = (value_part.to_lower() in ["true", "1", "yes"])
												prop_value = str(prop_value).to_lower() in ["true", "1", "yes"]
											"array":
												var parsed_value = JSON.parse_string(value_part)
												var parsed_prop = JSON.parse_string(prop_value)
												if typeof(parsed_value) == TYPE_ARRAY and typeof(parsed_prop) == TYPE_ARRAY:
													value_part = parsed_value
													prop_value = parsed_prop
											"dict", "dictionary":
												var parsed_value = JSON.parse_string(value_part)
												var parsed_prop = JSON.parse_string(prop_value)
												if typeof(parsed_value) == TYPE_DICTIONARY and typeof(parsed_prop) == TYPE_DICTIONARY:
													value_part = parsed_value
													prop_value = parsed_prop
											_:
												pass
										#% Apply operator or equality:
										if op_part != "":
											var num_prop := float(prop_value)
											var num_val := float(value_part)
											match op_part:
												">": if not num_prop > num_val: all_match = false
												"<": if not num_prop < num_val: all_match = false
												">=": if not num_prop >= num_val: all_match = false
												"<=": if not num_prop <= num_val: all_match = false
										else:
											if prop_value != value_part:
												all_match = false

										if not all_match:
											break

									if all_match:
										replacement_base = str(value_map[vk_rule])
										matched = true
										break

								if matched:
									break
							if matched:
								break
						if matched:
							break

					#% No valid substitution:
					if not matched or replacement_base == "":
						search_pos = end_idx + gsym.length()
						continue

					#% Case formatting:
					var final_word := ""
					match case_rule.to_lower():
						"custom", "x":
							final_word = replacement_base
						"lower", "low", "l":
							final_word = replacement_base.to_lower()
						"upper", "up", "u":
							final_word = replacement_base.to_upper()
						"capitalized", "cap", "c":
							final_word = replacement_base.capitalize()
						"auto", "a", "", _:
							if source_word_raw == source_word_raw.to_upper():
								final_word = replacement_base.to_upper()
							elif source_word_raw == source_word_raw.to_lower():
								final_word = replacement_base.to_lower()
							elif source_word_raw == source_word_raw.capitalize():
								final_word = replacement_base.capitalize()
							else:
								final_word = replacement_base.to_lower()

					#% Replace token:
					line_str = line_str.substr(0, start_idx) \
							+ final_word \
							+ line_str.substr(end_idx + gsym.length())

					search_pos = start_idx + final_word.length()

			#@ Step 7 - LLM handling:
			var ai_mode = int(speech_data.get("AI", 0))
			var use_llm = llm_mode

			#+ You can swap the order of the Line Override and Actor Override code blocks to change the priority:
			#% Line Override:
			if ai_mode == 1:
				use_llm = true
			elif ai_mode == -1:
				use_llm = false

			#% Actor Override:
			if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("LLM"):
				if candy_de.actors[speaker_ref]["LLM"] == 1:
					use_llm = true
				elif candy_de.actors[speaker_ref]["LLM"] == -1:
					use_llm = false

			#% If use LLM, call the externalized LLM query function:
			if use_llm:
				var display_name = speaker_ref
				if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("Display Name"):
					display_name = str(candy_de.actors[speaker_ref]["Display Name"])

				#% Pass all dispositions instead of a single one:
				var actor_disps_array: Array = []
				if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("Disposition"):
					var raw_disp = str(candy_de.actors[speaker_ref]["Disposition"]).strip_edges()
					actor_disps_array = raw_disp.split(",", false)
					actor_disps_array = actor_disps_array.map(func(x): return x.strip_edges())

				line_str = candy_de.llm_query(self, speaker_ref, display_name, actor_disps_array, line_str, chosen_variant)

			#@ Step 8 - Display the line:
			await display_line(current_conversation, current_block, speech_data, line_str, line_data, chosen_variant, text_direction)
			feedback = "Continue"
			last_cmd = ""

		#@ Step 9 - Decrement media pauses:
		for mp in active_media_players:
			if mp.pause_count > 0:
				if mp.pause_mode == "speech" and raw_key == "Spoken Line":
					mp.pause_count -= 1
				elif mp.pause_mode == "all":
					mp.pause_count -= 1

			if mp.pause_count == 0:
				mp.unpause()

		for mp in active_media_players:
			if mp.pause_re_wait == true:
				while mp in active_media_players:
					await get_tree().process_frame

	#@ Step 10 - Dialogue history logging:
	if write_dialogue_history == true:
		if last_cmd in [command_symbol + "jump", command_symbol + "bridge", command_symbol + "end", command_symbol + "return"]:
			var clean_name = last_cmd.substr(command_symbol.length()).capitalize()

			if clean_name == "End":
				dialogue_history.append({"End": ""})
				candy_de.general_dialogue_history.append({"End": ""})
			else:
				var new_conv: String = str(line_data.get("Conversation", "")).strip_edges()
				var same_conv = (new_conv == "" or new_conv == current_conversation)
				dialogue_history.append({clean_name: { "changed_conv": not same_conv }})
				candy_de.general_dialogue_history.append({clean_name: { "changed_conv": not same_conv }})

	#@ Step 11 - Cleanup if nesting depth changed:
	if not (last_cmd.begins_with(command_symbol + "elif")
		or last_cmd.begins_with(command_symbol + "else")
		or last_cmd.begins_with(command_symbol + "if")):
		if if_array.size() > nesting_depth:
			if_array.remove_at(nesting_depth)

	#@ Step 12 - Final killswitch and Suspended checks:
	#% Killswitch:
	if killswitch == true:
		if main == false:
			return "END"
		elif main == true:
			killswitch = false
			emit_signal("killswitch_off")
			return "END"

	#% Suspended Dialogue:
	if dialogue_suspended == true:
		while dialogue_suspended == true:
			await get_tree().process_frame

	#@ Step 13 - Finished processing this line:
	if feedback == null or feedback == "":
		feedback = "Continue"
		push_warning("process_lines() ended with feedback = '" + feedback + "'. This should never happen. Defaulting to 'Continue' as precaution. May cause errors. Good luck.")
	return feedback


#* Display text on screen with support for parsed speaker tags:
func display_line(current_conversation, current_block, speech_data: Dictionary, dialogue_text: String, line_data, chosen_variant: String, text_direction: String) -> void:
	#@ Unpack spoken data:
	var speaker_ref: String			= resolve_value(speech_data.get("Reference", ""))
	var portrait_raw: String		= speech_data.get("Portrait", "")
	var play_portrait: String		= resolve_value(speech_data.get("PortraitPlay", "1"))
	var disposition: String			= resolve_value(speech_data.get("Disposition", ""))
	var voice_raw: String			= speech_data.get("Voice", "")
	var speech_bubble_exempt: bool	= resolve_value(speech_data.get("BubbleExempt", false))
	var force_portrait: String		= resolve_value(speech_data.get("ForcePortrait", "0"))
	var tts: int					= resolve_value(speech_data.get("TTS", 0))
	var direction					= resolve_value(text_direction)

	#@ Set role flag:
	var role_flag := false
	if speaker_ref.begins_with(candy_de.role_symbol):
		role_flag = true

	#. Hook call:
	if candy_de.has_method("x_new_speech_display"):
		await candy_de.x_new_speech_display(self, line_data)

	#@ Role resolution:
	if role_flag and candy_de.roles.has(speaker_ref):
		speaker_ref = candy_de.roles[speaker_ref]

	#@ Resolve audio variable and path:
	var audio = voice_raw
	if typeof(voice_raw) == TYPE_STRING and (voice_raw.begins_with(candy_de.vardict_symbol)
			or voice_raw.begins_with(candy_de.node_symbol)
			or voice_raw.begins_with(candy_de.singleton_symbol)
			or voice_raw.begins_with(candy_de.role_symbol)):
		var decoded_audio = decode_variable_name(voice_raw)
		var resolved_audio = get_variable_value(decoded_audio)
		if resolved_audio != null:
			audio = str(resolved_audio).strip_edges()

	#@ Build final audio path:
	var voice_file := ""
	if typeof(audio) == TYPE_STRING and audio.begins_with("res://"):
		#% Absolute project path:
		voice_file = audio if audio.find(".") != -1 else audio + default_voice_extension
	else:
		#% Relative file name → Voices/Speaker/Conversation/Block/[Variant/]filename:
		var file_name = audio
		if file_name == "":
			file_name = "Default"
		if file_name.find(".") == -1:
			file_name += default_voice_extension

		voice_file = candy_de.voice_folder.path_join(speaker_ref)
		voice_file = voice_file.path_join(current_conversation)
		voice_file = voice_file.path_join(current_block)
		if chosen_variant != "Default":
			voice_file = voice_file.path_join(chosen_variant)
		voice_file = voice_file.path_join(file_name)

	#@ Resolve display name from candy_de.actors table:
	var speaker_display: String = speaker_ref
	if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("Display Name"):
		speaker_display = str(candy_de.actors[speaker_ref]["Display Name"])
		if candy_de.actors[speaker_ref].has("Speaker BBCode"):
			var bbcode_l = candy_de.actors[speaker_ref]["Speaker BBCode"][0]
			var bbcode_r = candy_de.actors[speaker_ref]["Speaker BBCode"][1]
			speaker_display = bbcode_l + speaker_display + bbcode_r

	var style = DialogueModes.keys()[dialogue_mode]

	print(style)

	#@ Alternate to VN_Bubbles:
	if style == "Bubbles" and vn_mode == true:
		style = "VN_Bubbles"
		print(style)

	#@ Pre-resolve bust bubble node if using VN_Bubbles:
	var vn_bubble_node = null
	var vn_bubble_text_node = null
	var bust_node = null

	if style == "VN_Bubbles":
		#% Check that a bust exists for this speaker:
		var bust_scene = get_node_or_null(ui_elements_paths["busts_path"])
		var busts_container = bust_scene.busts_container
		if bust_positions.has(speaker_ref):
			var bust_slot = bust_positions[speaker_ref]["pos"]
			bust_node = busts_container.get_node_or_null(bust_slot)
			if bust_node != null and bust_node.has_node("SpeechBubble"):
				vn_bubble_node = bust_node.get_node("SpeechBubble")
				#% Get Bubble's text node:
				vn_bubble_text_node = vn_bubble_node.label
			else:
				#% No Speech Bubble → switch to Exempt mode:
				style = DialogueModes.keys()[bubble_exempt_mode]
		else:
			#% Speaker not registered in bust_positions → switch to Exempt mode:
			style = DialogueModes.keys()[bubble_exempt_mode]

	#@ If speech bubble mode, check that the line and speaker aren't exempt, and that the speaker has an actor node in the scene:
	var speaker_node
	if style == "Bubbles" or "VN_Bubbles":
		#% Check if speaker is bubble exempt:
		if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("Bubble Exempt") and candy_de.actors[speaker_ref]["Bubble Exempt"] == true:
			style = DialogueModes.keys()[bubble_exempt_mode]

		#% Check if line is bubble exempt:
		elif speech_bubble_exempt == true:
			style = DialogueModes.keys()[bubble_exempt_mode]

	if style == "Bubbles":
		#% Check the speaker node is present:
		if speaker_ref in candy_de.player_refs:
			speaker_node = get_node_or_null(str(bubbles_player_path.path_join(speaker_ref)))
		else:
			speaker_node = get_node_or_null(str(bubbles_npc_path.path_join(speaker_ref)))

		#% Default to alternative style:
		if speaker_node == null:
			style = DialogueModes.keys()[bubble_exempt_mode]

	print(style)

	#@ Clear previous dialogue:
	#? This allows dialogue to persist after a line (e.g. while player makes a choice),
	#? but ensures all previous dialogue is cleared when a new line is displayed.
	await clear_previous_dialogue(style, speaker_ref)
	previous_mode = style
	previous_speaker = speaker_ref

	#@ Dialogue Mode:
	match style:
		"Box":
			var dialogue_box = get_node(ui_elements_paths["dialogue_box_path"])

			dialogue_box.visible = true

			#@ Speaker label shows Display Name:
			dialogue_box.speaker_node.text = speaker_display
			dialogue_text = dialogue_text + box_end_of_line_string

			#@ Determine speaker name color (priority: Actor → Global → Node default):
			var speaker_label = dialogue_box.speaker_node
			var final_speaker_color
			var has_speaker_override = false

			#% 1. Actor-specific color:
			if candy_de.actors.has(speaker_ref):
				if candy_de.actors[speaker_ref].has("Box Speaker Color") and candy_de.actors[speaker_ref]["Box Speaker Color"] != null:
					final_speaker_color = candy_de.actors[speaker_ref]["Box Speaker Color"]
					has_speaker_override = true
					print("Override speaker color with actor color.")

			#% 2. UI override color:
			if has_speaker_override != true and "enable_speaker_color" in dialogue_box and dialogue_box.enable_speaker_color == true:
				final_speaker_color = dialogue_box.speaker_color
				has_speaker_override = true
				print("Override speaker color with UI color.")

			#% 3. Global override color:
			if has_speaker_override != true and enable_box_speaker_color == true:
				final_speaker_color = box_speaker_color
				has_speaker_override = true
				print("Override speaker color with general color.")

			#% 4. Apply override if any:
			if has_speaker_override:
				if speaker_label is RichTextLabel:
					speaker_label.add_theme_color_override("default_color", final_speaker_color)
				elif speaker_label is Label:
					speaker_label.add_theme_color_override("font_color", final_speaker_color)

			#@ Dialogue text:
			var dialogue_text_node = dialogue_box.dialogue_node
			dialogue_text_node.text = ""

			#@ Variant layout:
			dialogue_text_node.text_direction = TextServer.DIRECTION_LTR
			dialogue_text_node.layout_direction = Control.LAYOUT_DIRECTION_LTR

			if direction == "rtl":
				dialogue_text_node.text_direction = TextServer.DIRECTION_RTL
				dialogue_text_node.layout_direction = Control.LAYOUT_DIRECTION_RTL

			#@ Determine text color (priority: Actor → Global → Node default):
			var final_font_color
			var has_override = false

			#% 1. Actor-specific color:
			if candy_de.actors.has(speaker_ref):
				if candy_de.actors[speaker_ref].has("Box Text Color") and candy_de.actors[speaker_ref]["Box Text Color"] != null:
					final_font_color = candy_de.actors[speaker_ref]["Box Text Color"]
					has_override = true
					print("Override text color with actor color.")

			#% 2. UI override color:
			if has_override != true and "enable_text_color" in dialogue_box and dialogue_box.enable_text_color == true:
				final_font_color = dialogue_box.text_color
				has_override = true
				print("Override text color with UI color.")

			#% 3. Global override color:
			if has_override != true and enable_box_font_color == true:
				final_font_color = box_font_color
				has_override = true
				print("Override text color with general color.")

			#% 4. Apply override if any:
			if has_override:
				if dialogue_text_node is RichTextLabel:
					dialogue_text_node.add_theme_color_override("default_color", final_font_color)
				elif dialogue_text_node is Label:
					dialogue_text_node.add_theme_color_override("font_color", final_font_color)

			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).highlight_speaker(speaker_ref, style)

			#@ Portrait handling with portrait_mode:
			var portrait_node = get_node(ui_elements_paths["portrait_path"])
			portrait_node.caller = self

			#% Portrait if line forces portrait:
			if force_portrait == "1":
				portrait_node.receive_portrait(speaker_ref, portrait_raw, play_portrait)

			#% No portrait if line forbids portrait:
			elif force_portrait == "-1":
				portrait_node.no_portrait()

			#% If no line rule and actor forces portrait:
			elif speaker_ref in candy_de.actors and "Portrait" in candy_de.actors[speaker_ref] and candy_de.actors[speaker_ref]["Portrait"] == 1:
				portrait_node.receive_portrait(speaker_ref, portrait_raw, play_portrait)

			#% If no line rule and actor forbids portraits:
			elif speaker_ref in candy_de.actors and "Portrait" in candy_de.actors[speaker_ref] and candy_de.actors[speaker_ref]["Portrait"] == -1:
				portrait_node.no_portrait()

			#% Portrait if no actor/line rule and portrait mode = All:
			elif portrait_mode == PortraitModes.All:
				portrait_node.receive_portrait(speaker_ref, portrait_raw, play_portrait)

			#% Portrait if no actor/line rule and portrait mode = Player:
			elif portrait_mode == PortraitModes.Player and speaker_ref in candy_de.player_refs :
				portrait_node.receive_portrait(speaker_ref, portrait_raw, play_portrait)

			#% Portrait if no actor/line rule and portrait mode = NPC:
			elif portrait_mode == PortraitModes.NPC and speaker_ref not in candy_de.player_refs :
				portrait_node.receive_portrait(speaker_ref, portrait_raw, play_portrait)

			#% Portrait if VN Mode:
			elif vn_mode == true and portrait_mode == PortraitModes.VN and not bust_positions.has(speaker_ref) :
				portrait_node.receive_portrait(speaker_ref, portrait_raw, play_portrait)

			#% Portraite Mode = "Off" or any other case, treat as "no portrait":
			else:
				portrait_node.no_portrait()

			#@ Audio handling
			var voice_player = get_node(media_players_locations["Voice"])

			var use_tts := false
			var tts_mode = text_to_speech
			var tts_output

			#% 1. Check if using TTS:
			#% Default settings:
			if text_to_speech != TtsModes.Off:
				use_tts = true

			#% Actor override:
			if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("TTS"):
				var actor_tts = candy_de.actors[speaker_ref]["TTS"]
				if actor_tts == -1:
					use_tts = false
				elif actor_tts == 1:
					use_tts = true

			#% Line Override:
			if tts == -1:
				use_tts = false
			elif tts == 1:
				use_tts = true

			#% 2. Call TTS query:
			if use_tts:
				tts_output = candy_de.tts(self, tts_mode, speaker_ref, dialogue_text, line_data, chosen_variant)
				if tts_output == null:
					use_tts = false

			#% 3. Use the output:
			if use_tts == true:
				if tts_output is AudioStream:
					voice_player.stream = tts_output
				elif typeof(tts_output) == TYPE_STRING and ResourceLoader.exists(tts_output):
					var stream = load(tts_output)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("TTS output is not a valid AudioStream: ", tts_output)
				else:
					#% TTS failed to provide usable data → fallback:
					use_tts = false

			#% 4. If TTS failed or disabled, try pre-recorded file:
			if use_tts == false:
				if voice_file != "" and ResourceLoader.exists(voice_file):
					var stream = load(voice_file)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("Audio file is not a valid stream: ", voice_file)

				#% 5. No valid file found → stop or clear:
				else:
					if voice_player.playing:
						voice_player.stop()
					voice_player.stream = null

			#@ Apply lexicon tags to dialogue text (if BBCode enabled):
			var bbcode_text = dialogue_text
			if lexicon_box_mode == true:
				if dialogue_text_node is RichTextLabel and dialogue_text_node.bbcode_enabled and candy_de.lexicon != null:
					bbcode_text = apply_lexicon_tags(dialogue_text, candy_de.lexicon, chosen_variant)

			#@ Start voice file playback:
			if enable_voice and voice_player.stream != null:
				voice_player.play()

			#@ Dialogue writing speed logic:
			var total_visible = bbcode_strip_tags(bbcode_text).length()
			dialogue_box.caller = self

			#% 1. Instant writing (no typewriter):
			if writing_speed <= 0:
				dialogue_text_node.text = bbcode_text
				await wait_for_player_advance()
				if vn_mode == true and bust_positions.has(speaker_ref):
					get_node(ui_elements_paths["busts_path"]).end_highlight_speaker(speaker_ref, style)
				dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})
				candy_de.general_dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})

			#% 2. Typewriter writing:
			elif writing_speed > 0:
				var effective_speed = writing_speed
				var i := 0
				var char_progress = 0.0
				var last_time = Time.get_ticks_msec() / 1000.0

				#% Set full text immediately for correct word wrapping:
				dialogue_text_node.text = bbcode_text
				dialogue_text_node.visible_characters = 0

				#% Synchronize writing speed with voice playback:
				if sync_write_speed_voice == true:
					if enable_voice and voice_player.stream != null:
						var voice_length = voice_player.stream.get_length()	#/ Duration in seconds
						if voice_length > 0.1 and total_visible > 0:
							effective_speed = float(total_visible) / voice_length

				#. Hook Call:
				if dialogue_box.has_method("x_write_begun"):
					await dialogue_box.x_write_begun()
				if portrait_node.has_method("x_write_begun"):
					await portrait_node.x_write_begun()

				#% Write text:
				while i < total_visible:
					#@ 0. Suspension check:
					#% If dialogue is suspended, stop progressing and pause all media:
					if dialogue_suspended == true:
						while dialogue_suspended == true:
							await get_tree().process_frame
						last_time = Time.get_ticks_msec() / 1000.0		#/ Reset timer to prevent jumps
						continue

					#@ 1. Skip/Slow/Skip:
					#% 1A. Speed writing:
					if Input.is_action_just_pressed(input_speed_dialogue) and input_enabled == true:
						if continue_skip_speed < 0:
							pass
						elif continue_skip_speed == 0:
							dialogue_text_node.visible_characters = -1
							break
						else:
							effective_speed = continue_skip_speed

					#% 1B. Slow writing:
					elif Input.is_action_just_pressed(input_slow_dialogue) and input_enabled == true:
						if continue_skip_speed < 0:
							pass
						elif continue_slow_speed == 0:
							dialogue_text_node.visible_characters = -1
							break
						else:
							effective_speed = continue_slow_speed

					#% 1C. Skip writing:
					elif Input.is_action_just_pressed(input_skip_dialogue) and input_enabled == true:
						dialogue_text_node.visible_characters = -1
						break

					#@ 2. Time progression:
					var now := Time.get_ticks_msec() / 1000.0
					var delta = now - last_time
					last_time = now
					char_progress += effective_speed * delta

					var chars_to_add = int(char_progress)

					if chars_to_add > 0:
						char_progress -= chars_to_add
						i = min(i + chars_to_add, total_visible)

						#% 3. Update visible characters:
						dialogue_text_node.visible_characters = i

					await get_tree().process_frame

			#. Hook call:
			if dialogue_box.has_method("x_write_finished"):
				await dialogue_box.x_write_finished()
			if portrait_node.has_method("x_write_finished"):
				await portrait_node.x_write_finished()

			await wait_for_player_advance()

			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).end_highlight_speaker(speaker_ref, style)

			voice_player.stop()

			#@ Log spoken line to history:
			if write_dialogue_history == true:
				dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})
				candy_de.general_dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})

			return

		"Bubbles":
			#@ Clear Previous Speech Bubbles:
			var npc_path_node = get_node_or_null(bubbles_npc_path)
			if npc_path_node:
				for actor in npc_path_node.get_children():
					actor.internal_node_dict["Speech_Bubble"].clear()

			var player_path_node = get_node_or_null(bubbles_player_path)
			if player_path_node:
				for actor in player_path_node.get_children():
					actor.internal_node_dict["Speech_Bubble"].clear()

			#@ Get bubble nodes:
			var bubble_node = speaker_node.internal_node_dict["Speech_Bubble"]
			var bubble_text_node = bubble_node.label

			#@ Add end of line string:
			dialogue_text = dialogue_text + bubbles_end_of_line_string

			#@ Dialogue text:
			bubble_text_node.text = ""

			#% Variant layout:
			bubble_text_node.text_direction = TextServer.DIRECTION_LTR
			bubble_text_node.layout_direction = Control.LAYOUT_DIRECTION_LTR

			if direction == "rtl":
				bubble_text_node.text_direction = TextServer.DIRECTION_RTL
				bubble_text_node.layout_direction = Control.LAYOUT_DIRECTION_RTL

			#% Determine text color (priority: Actor → Global → Node default):
			var final_font_color
			var has_override = false

			#% 1. Actor-specific color:
			if candy_de.actors.has(speaker_ref):
				if candy_de.actors[speaker_ref].has("Bubble Text Color") and candy_de.actors[speaker_ref]["Bubble Text Color"] != null:
					final_font_color = candy_de.actors[speaker_ref]["Bubble Text Color"]
					has_override = true
					print("Override text color with actor color.")

			#% 2. UI override color:
			if has_override != true and "enable_text_color" in bubble_node and bubble_node.enable_text_color == true:
				final_font_color = bubble_node.text_color
				has_override = true
				print("Override text color with UI color.")

			#% 3. Global override color:
			if has_override != true and enable_bubble_font_color == true:
				final_font_color = bubble_font_color
				has_override = true
				print("Override text color with general color.")

			#% 4. Apply override if any:
			if has_override:
				bubble_node.override_color = final_font_color
				print("Final Color: " + str(final_font_color))

			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).highlight_speaker(speaker_ref, style)

			#@ Audio handling:
			var voice_player = get_node(media_players_locations["Voice"])
			var use_tts := false
			var tts_mode = text_to_speech
			var tts_output

			#% 1. Check if using TTS:
			#% Default settings:
			if text_to_speech != TtsModes.Off:
				use_tts = true

			#% Actor override:
			if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("TTS"):
				var actor_tts = candy_de.actors[speaker_ref]["TTS"]
				if actor_tts == -1:
					use_tts = false
				elif actor_tts == 1:
					use_tts = true

			#% Line Override:
			if tts == -1:
				use_tts = false
			elif tts == 1:
				use_tts = true

			#% 2. Call TTS query:
			if use_tts:
				tts_output = candy_de.tts(self, tts_mode, speaker_ref, dialogue_text, line_data, chosen_variant)
				if tts_output == null:
					use_tts = false

			#% 3. Use the output:
			if use_tts == true:
				if tts_output is AudioStream:
					voice_player.stream = tts_output
				elif typeof(tts_output) == TYPE_STRING and ResourceLoader.exists(tts_output):
					var stream = load(tts_output)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("TTS output is not a valid AudioStream: ", tts_output)
				else:
					#% TTS failed to provide usable data → fallback:
					use_tts = false

			#% 4. If TTS failed or disabled, try pre-recorded file:
			if use_tts == false:
				if voice_file != "" and ResourceLoader.exists(voice_file):
					var stream = load(voice_file)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("Audio file is not a valid stream: ", voice_file)

				#% 5. No valid file found → stop or clear:
				else:
					if voice_player.playing:
						voice_player.stop()
					voice_player.stream = null

			#@ Apply lexicon tags to dialogue text (if BBCode enabled):
			var bbcode_text = dialogue_text
			if lexicon_bubbles_mode == true:
				if bubble_text_node is RichTextLabel and bubble_text_node.bbcode_enabled and candy_de.lexicon != null:
					bbcode_text = apply_lexicon_tags(dialogue_text, candy_de.lexicon, chosen_variant)

			#@ Start voice file playback:
			if enable_voice and voice_player.stream != null:
				voice_player.play()

			#@ Dialogue writing speed logic:
			bubble_node.caller = self
			var total_visible := bbcode_strip_tags(bbcode_text).length()

			#% 1. Instant writing (no typewriter):
			if writing_speed <= 0:
				await bubble_node.show_text(bbcode_text)

			#% 2. Typewriter writing:
			elif writing_speed > 0:
				var effective_speed = writing_speed
				var i := 0
				var char_progress = 0.0
				var last_time = Time.get_ticks_msec() / 1000.0

				#% Set full text immediately for correct word wrapping:
				bubble_text_node.visible_characters = 0
				await bubble_node.show_text(bbcode_text)
				#await get_tree().process_frame
				#bubble_node.sprite.visible = true

				#% Synchronize writing speed with voice playback:
				if sync_write_speed_voice == true:
					if enable_voice and voice_player.stream != null:
						var voice_length = voice_player.stream.get_length()	#/ Duration in seconds
						if voice_length > 0.1 and total_visible > 0:
							effective_speed = float(total_visible) / voice_length

				#§ Hook call:
				if bubble_node.has_method("x_write_begun"):
					await bubble_node.x_write_begun()

				#% Write text:
				while i < total_visible:
					#@ 0. Suspension check:
					#% If dialogue is suspended, pause typewriter and all media players:
					if dialogue_suspended == true:
						while dialogue_suspended == true:
							await get_tree().process_frame
						last_time = Time.get_ticks_msec() / 1000.0		#/ Prevent time jump
						continue

					#@ 1. Skip/Slow/Skip:
					#% 1A. Speed writing:
					if Input.is_action_just_pressed(input_speed_dialogue) and input_enabled == true:
						if continue_skip_speed < 0:
							pass
						elif continue_skip_speed == 0:
							bubble_text_node.visible_characters = -1
							break
						else:
							effective_speed = continue_skip_speed

					#% 1B. Slow writing:
					elif Input.is_action_just_pressed(input_slow_dialogue) and input_enabled == true:
						if continue_skip_speed < 0:
							pass
						elif continue_slow_speed == 0:
							bubble_text_node.visible_characters = -1
							break
						else:
							effective_speed = continue_slow_speed

					#% 1C. Skip writing:
					elif Input.is_action_just_pressed(input_skip_dialogue) and input_enabled == true:
						bubble_text_node.visible_characters = -1
						break

					#@ 2. Time progression:
					var now := Time.get_ticks_msec() / 1000.0
					var delta = now - last_time
					last_time = now

					char_progress += effective_speed * delta
					var chars_to_add = int(char_progress)
					if chars_to_add > 0:
						char_progress -= chars_to_add
						i = min(i + chars_to_add, total_visible)

						#@ 3. Update text safely (with balanced BBCode tags):
						bubble_text_node.visible_characters = i

					await get_tree().process_frame

			#. Hook call:
			if bubble_node.has_method("x_write_finished"):
				await bubble_node.x_write_finished()

			await wait_for_player_advance()

			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).end_highlight_speaker(speaker_ref, style)

			voice_player.stop()

			#bubble_node.clear()

			#@ Log spoken line to history:
			if write_dialogue_history == true:
				dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})
				candy_de.general_dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})

			return


		"VN_Bubbles":
			#@ Validate VN-style bubble node:
			if vn_bubble_node == null or vn_bubble_text_node == null:
				style = DialogueModes.keys()[bubble_exempt_mode]
				return

			vn_bubble_node.visible = false		#/ Hide the bubble, and let the bubble_node make it visible to avoid shrunk bubble visual glitch.

			#@ Add end-of-line symbol:
			dialogue_text = dialogue_text + bubbles_end_of_line_string

			#@ Dialogue text:
			vn_bubble_text_node.text = ""

			#% Variant layout:
			vn_bubble_text_node.text_direction = TextServer.DIRECTION_LTR
			vn_bubble_text_node.layout_direction = Control.LAYOUT_DIRECTION_LTR

			if direction == "rtl":
				vn_bubble_text_node.text_direction = TextServer.DIRECTION_RTL
				vn_bubble_text_node.layout_direction = Control.LAYOUT_DIRECTION_RTL

			#% Determine text color (priority: Actor → Global → Node default):
			var final_font_color
			var has_override = false

			#% 1. Actor-specific color:
			if candy_de.actors.has(speaker_ref):
				if candy_de.actors[speaker_ref].has("Bubble Text Color") and candy_de.actors[speaker_ref]["Bubble Text Color"] != null:
					final_font_color = candy_de.actors[speaker_ref]["Bubble Text Color"]
					has_override = true
					print("Override text color with actor color.")

			#% 2. UI override color:
			if has_override != true and "enable_text_color" in vn_bubble_node and vn_bubble_node.enable_text_color == true:
				final_font_color = vn_bubble_node.text_color
				has_override = true
				print("Override text color with UI color.")

			#% 3. Global pverride color:
			if has_override != true and enable_bubble_font_color == true:
				final_font_color = bubble_font_color
				has_override = true
				print("Override text color with general color.")

			#% 4. Apply override if any:
			if has_override:
				vn_bubble_node.override_color = final_font_color
				print("Final Color: " + str(final_font_color))

			#@ VN Mode::
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).highlight_speaker(speaker_ref, style)

			#@ Audio handling:
			var voice_player = get_node(media_players_locations["Voice"])
			var use_tts := false
			var tts_mode = text_to_speech
			var tts_output

			#% 1. Check if using TTS:
			#% Default settings:
			if text_to_speech != TtsModes.Off:
				use_tts = true

			#% Actor override:
			if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("TTS"):
				var actor_tts = candy_de.actors[speaker_ref]["TTS"]
				if actor_tts == -1:
					use_tts = false
				elif actor_tts == 1:
					use_tts = true

			#% Line Override:
			if tts == -1:
				use_tts = false
			elif tts == 1:
				use_tts = true

			#% 2. Call TTS query:
			if use_tts:
				tts_output = candy_de.tts(self, tts_mode, speaker_ref, dialogue_text, line_data, chosen_variant)
				if tts_output == null:
					use_tts = false

			#% 3. Use the output:
			if use_tts == true:
				if tts_output is AudioStream:
					voice_player.stream = tts_output
				elif typeof(tts_output) == TYPE_STRING and ResourceLoader.exists(tts_output):
					var stream = load(tts_output)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("TTS output is not a valid AudioStream: ", tts_output)
				else:
					#% TTS failed to provide usable data → fallback:
					use_tts = false

			#% 4. If TTS failed or disabled, try pre-recorded file:
			if use_tts == false:
				if voice_file != "" and ResourceLoader.exists(voice_file):
					var stream = load(voice_file)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("Audio file is not a valid stream: ", voice_file)

				#% 5. No valid file found → stop or clear:
				else:
					if voice_player.playing:
						voice_player.stop()
					voice_player.stream = null

			#@ Apply lexicon tags to dialogue text (if BBCode enabled):
			var bbcode_text = dialogue_text
			if lexicon_bubbles_mode == true:
				if vn_bubble_text_node is RichTextLabel and vn_bubble_text_node.bbcode_enabled and candy_de.lexicon != null:
					bbcode_text = apply_lexicon_tags(dialogue_text, candy_de.lexicon, chosen_variant)

			#@ Start voice file playback:
			if enable_voice and voice_player.stream != null:
				voice_player.play()

			#@ Dialogue writing speed logic:
			vn_bubble_node.caller = self
			var total_visible := bbcode_strip_tags(bbcode_text).length()

			#% 1. Instant writing (no typewriter):
			if writing_speed <= 0:
				vn_bubble_node.show_text(bbcode_text)

			#% 2. Typewriter writing:
			elif writing_speed > 0:
				var effective_speed = writing_speed
				var i := 0
				var char_progress = 0.0
				var last_time = Time.get_ticks_msec() / 1000.0

				#% Set full text immediately for correct word wrapping:
				vn_bubble_text_node.visible_characters = 0
				await vn_bubble_node.show_text(bbcode_text)
				#await get_tree().process_frame
				vn_bubble_node.sprite.visible = true

				#% Synchronize writing speed with voice playback:
				if sync_write_speed_voice == true:
					if enable_voice and voice_player.stream != null:
						var voice_length = voice_player.stream.get_length()	#/ Duration in seconds
						if voice_length > 0.1 and total_visible > 0:
							effective_speed = float(total_visible) / voice_length

				#. Hook call:
				if vn_bubble_node.has_method("x_write_begun"):
					await vn_bubble_node.x_write_begun()

				#% Write text:
				while i < total_visible:
					#@ 0. Suspension check:
					#% If dialogue is suspended, pause typewriter and all media players:
					if dialogue_suspended == true:
						while dialogue_suspended == true:
							await get_tree().process_frame
						last_time = Time.get_ticks_msec() / 1000.0		#/ Prevent time jump after resume
						continue

					#@ 1. Skip/Slow/Skip:
					#% 1A. Speed writing:
					if Input.is_action_just_pressed(input_speed_dialogue) and input_enabled == true:
						if continue_skip_speed < 0:
							pass
						elif continue_skip_speed == 0:
							vn_bubble_text_node.visible_characters = -1
							break
						else:
							effective_speed = continue_skip_speed

					#% 1B. Slow writing:
					elif Input.is_action_just_pressed(input_slow_dialogue) and input_enabled == true:
						if continue_skip_speed < 0:
							pass
						elif continue_slow_speed == 0:
							vn_bubble_text_node.visible_characters = -1
							break
						else:
							effective_speed = continue_slow_speed

					#% 1C. Skip writing:
					elif Input.is_action_just_pressed(input_skip_dialogue) and input_enabled == true:
						vn_bubble_text_node.visible_characters = -1
						break

					#@ 2. Time progression:
					var now := Time.get_ticks_msec() / 1000.0
					var delta = now - last_time
					last_time = now

					char_progress += effective_speed * delta
					var chars_to_add = int(char_progress)
					if chars_to_add > 0:
						char_progress -= chars_to_add
						i = min(i + chars_to_add, total_visible)

						#@ 3. Update visible text with balanced BBCode tags:
						vn_bubble_text_node.visible_characters = i

					await get_tree().process_frame

			#. Hook call:
			if vn_bubble_node.has_method("x_write_finished"):
				await vn_bubble_node.x_write_finished()

			await wait_for_player_advance()

			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).end_highlight_speaker(speaker_ref, style)

			voice_player.stop()

			#vn_bubble_node.clear()

			#@ Log spoken line to history:
			if write_dialogue_history == true:
				dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})
				candy_de.general_dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})

			return


		"Bark":
			#@ Get bubble nodes:
			var bark_node = get_node(ui_elements_paths["barks_path"])
			var bark_text_node = bark_node.label

			#@ Add end of line string:
			dialogue_text = dialogue_text + barks_end_of_line_string

			#@ Dialogue text:
			bark_text_node.text = ""

			#% Variant layout:
			bark_text_node.text_direction = TextServer.DIRECTION_LTR
			bark_text_node.layout_direction = Control.LAYOUT_DIRECTION_LTR

			if direction == "rtl":
				bark_text_node.text_direction = TextServer.DIRECTION_RTL
				bark_text_node.layout_direction = Control.LAYOUT_DIRECTION_RTL

			#% Determine text color (priority: Actor → Global → Node default):
			var final_font_color
			var has_override = false

			#% 1. Actor-specific color:
			if candy_de.actors.has(speaker_ref):
				if candy_de.actors[speaker_ref].has("Bark Text Color") and candy_de.actors[speaker_ref]["Bark Text Color"] != null:
					final_font_color = candy_de.actors[speaker_ref]["Bark Text Color"]
					has_override = true
					print("Override text color with actor color.")

			#% 2. UI override color:
			if has_override != true and "enable_text_color" in bark_node and bark_node.enable_text_color == true:
				final_font_color = bark_node.text_color
				has_override = true
				print("Override text color with UI color.")

			#% 3. Global override color:
			if has_override != true and enable_bark_font_color == true:
				final_font_color = bark_font_color
				has_override = true
				print("Override text color with general color.")

			#% 4. Apply override if any:
			if has_override:
				bark_node.override_color = final_font_color
				print("Final Color: " + str(final_font_color))

			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).highlight_speaker(speaker_ref, style)

			#@ Audio handling:
			var voice_player = get_node(media_players_locations["Voice"])
			var use_tts := false
			var tts_mode = text_to_speech
			var tts_output

			#% 1. Check if using TTS:
			#% Default settings:
			if text_to_speech != TtsModes.Off:
				use_tts = true

			#% Actor override:
			if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("TTS"):
				var actor_tts = candy_de.actors[speaker_ref]["TTS"]
				if actor_tts == -1:
					use_tts = false
				elif actor_tts == 1:
					use_tts = true

			#% Line Override:
			if tts == -1:
				use_tts = false
			elif tts == 1:
				use_tts = true

			#% 2. Call TTS query:
			if use_tts:
				tts_output = candy_de.tts(self, tts_mode, speaker_ref, dialogue_text, line_data, chosen_variant)
				if tts_output == null:
					use_tts = false

			#% 3. Use the output:
			if use_tts == true:
				if tts_output is AudioStream:
					voice_player.stream = tts_output
				elif typeof(tts_output) == TYPE_STRING and ResourceLoader.exists(tts_output):
					var stream = load(tts_output)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("TTS output is not a valid AudioStream: ", tts_output)
				else:
					#% TTS failed to provide usable data → fallback:
					use_tts = false

			#% 4. If TTS failed or disabled, try pre-recorded file:
			if use_tts == false:
				if voice_file != "" and ResourceLoader.exists(voice_file):
					var stream = load(voice_file)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("Audio file is not a valid stream: ", voice_file)

				#% 5. No valid file found → stop or clear:
				else:
					if voice_player.playing:
						voice_player.stop()
					voice_player.stream = null

			#@ Apply lexicon tags to dialogue text (if BBCode enabled):
			var bbcode_text = dialogue_text
			if lexicon_bark_mode == true:
				if bark_text_node is RichTextLabel and bark_text_node.bbcode_enabled and candy_de.lexicon != null:
					bbcode_text = apply_lexicon_tags(dialogue_text, candy_de.lexicon, chosen_variant)

			#@ Start voice file playback:
			if enable_voice and voice_player.stream != null:
				voice_player.play()

			#@ Dialogue writing speed logic:
			bark_node.caller = self
			var total_visible := bbcode_strip_tags(bbcode_text).length()

			#% 1. Instant writing (no typewriter):
			if writing_speed <= 0:
				await bark_node.show_text(bbcode_text)

			#% 2. Typewriter writing:
			elif writing_speed > 0:
				var effective_speed = writing_speed
				var i := 0
				var char_progress = 0.0
				var last_time = Time.get_ticks_msec() / 1000.0

				#% Set full text immediately for correct word wrapping:
				bark_text_node.visible_characters = 0
				await bark_node.show_text(bbcode_text)
				#await get_tree().process_frame
				#bubble_node.sprite.visible = true

				#% Synchronize writing speed with voice playback:
				if sync_write_speed_voice == true:
					if enable_voice and voice_player.stream != null:
						var voice_length = voice_player.stream.get_length()	#/ Duration in seconds
						if voice_length > 0.1 and total_visible > 0:
							effective_speed = float(total_visible) / voice_length

				#. Hook call:
				if bark_node.has_method("x_write_begun"):
					await bark_node.x_write_begun()

				#% Write text:
				while i < total_visible:
					#@ 0. Suspension check:
					#% If dialogue is suspended, pause typewriter and all media players:
					if dialogue_suspended == true:
						while dialogue_suspended == true:
							await get_tree().process_frame
						last_time = Time.get_ticks_msec() / 1000.0		#/ Prevent time jump
						continue

					#@ 1. Skip/Slow/Skip:
					#% 1A. Speed writing:
					if Input.is_action_just_pressed(input_speed_dialogue) and input_enabled == true:
						if continue_skip_speed < 0:
							pass
						elif continue_skip_speed == 0:
							bark_text_node.visible_characters = -1
							break
						else:
							effective_speed = continue_skip_speed

					#% 1B. Slow writing:
					elif Input.is_action_just_pressed(input_slow_dialogue) and input_enabled == true:
						if continue_skip_speed < 0:
							pass
						elif continue_slow_speed == 0:
							bark_text_node.visible_characters = -1
							break
						else:
							effective_speed = continue_slow_speed

					#% 1C. Skip writing:
					elif Input.is_action_just_pressed(input_skip_dialogue) and input_enabled == true:
						bark_text_node.visible_characters = -1
						break

					#@ 2. Time progression:
					var now := Time.get_ticks_msec() / 1000.0
					var delta = now - last_time
					last_time = now

					char_progress += effective_speed * delta
					var chars_to_add = int(char_progress)
					if chars_to_add > 0:
						char_progress -= chars_to_add
						i = min(i + chars_to_add, total_visible)

						#@ 3. Update text safely (with balanced BBCode tags):
						bark_text_node.visible_characters = i

					await get_tree().process_frame

			#. Hook call:
			if bark_node.has_method("x_write_finished"):
				await bark_node.x_write_finished()

			await wait_for_player_advance()

			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).end_highlight_speaker(speaker_ref, style)

			voice_player.stop()

			#bark_node.clear()

			#@ Log spoken line to history:
			if write_dialogue_history == true:
				dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})
				candy_de.general_dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})

			return


		"Subtitles":
			#@ Get subtitles nodes:
			var subtitle_node = get_node(ui_elements_paths["subtitles_path"])
			var subtitle_text_node = subtitle_node.dialogue_node

			subtitle_node.visible = true

			#@ Add end-of-line string:
			dialogue_text = dialogue_text + chat_end_of_line_string

			#@ Dialogue text:
			subtitle_text_node.text = ""

			#% Variant layout:
			subtitle_text_node.text_direction = TextServer.DIRECTION_LTR
			subtitle_text_node.layout_direction = Control.LAYOUT_DIRECTION_LTR

			if direction == "rtl":
				subtitle_text_node.text_direction = TextServer.DIRECTION_RTL
				subtitle_text_node.layout_direction = Control.LAYOUT_DIRECTION_RTL

			#% Determine text color (priority: Actor → Global → Node default):
			var final_font_color
			var has_override = false

			#% 1. Actor-specific color:
			if candy_de.actors.has(speaker_ref):
				if candy_de.actors[speaker_ref].has("Subtitle Text Color") and candy_de.actors[speaker_ref]["Subtitle Text Color"] != null:
					final_font_color = candy_de.actors[speaker_ref]["Subtitle Text Color"]
					has_override = true
					print("Override text color with actor color.")

			#% 2. UI override color:
			if has_override != true and "enable_text_color" in subtitle_node and subtitle_node.enable_text_color == true:
				final_font_color = subtitle_node.text_color
				has_override = true
				print("Override text color with UI color.")

			#% 3. Global pverride color:
			if has_override != true and enable_subtitle_font_color == true:
				final_font_color = subtitle_font_color
				has_override = true
				print("Override text color with general color.")

			#% 4. Apply override if any:
			if has_override:
				if subtitle_text_node is RichTextLabel:
					subtitle_text_node.add_theme_color_override("default_color", final_font_color)
				elif subtitle_text_node is Label:
					subtitle_text_node.add_theme_color_override("font_color", final_font_color)

			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).highlight_speaker(speaker_ref, style)

			#@ Audio handling:
			var voice_player = get_node(media_players_locations["Voice"])
			var use_tts := false
			var tts_mode = text_to_speech
			var tts_output

			#% 1. Check if using TTS:
			#% Default settings:
			if text_to_speech != TtsModes.Off:
				use_tts = true

			#% Actor override:
			if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("TTS"):
				var actor_tts = candy_de.actors[speaker_ref]["TTS"]
				if actor_tts == -1:
					use_tts = false
				elif actor_tts == 1:
					use_tts = true

			#% Line Override:
			if tts == -1:
				use_tts = false
			elif tts == 1:
				use_tts = true

			#% 2. Call TTS query:
			if use_tts:
				tts_output = candy_de.tts(self, tts_mode, speaker_ref, dialogue_text, line_data, chosen_variant)
				if tts_output == null:
					use_tts = false

			#% 3. Use the output:
			if use_tts == true:
				if tts_output is AudioStream:
					voice_player.stream = tts_output
				elif typeof(tts_output) == TYPE_STRING and ResourceLoader.exists(tts_output):
					var stream = load(tts_output)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("TTS output is not a valid AudioStream: ", tts_output)
				else:
					#% TTS failed to provide usable data → fallback:
					use_tts = false

			#% 4. If TTS failed or disabled, try pre-recorded file:
			if use_tts == false:
				if voice_file != "" and ResourceLoader.exists(voice_file):
					var stream = load(voice_file)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("Audio file is not a valid stream: ", voice_file)

				#% 5. No valid file found → stop or clear:
				else:
					if voice_player.playing:
						voice_player.stop()
					voice_player.stream = null

			#@ Apply lexicon tags to dialogue text (if BBCode enabled):
			var bbcode_text = dialogue_text
			if lexicon_subtitles_mode == true:
				if subtitle_text_node is RichTextLabel and subtitle_text_node.bbcode_enabled and candy_de.lexicon != null:
					bbcode_text = apply_lexicon_tags(dialogue_text, candy_de.lexicon, chosen_variant)

			#@ Prepare speaker name if enabled:
			if subtitles_show_speaker == true:
				var color_tag_open = ""
				var col: Color
				var has_speaker_override = false

				#% 1. Actor-specific color:
				if candy_de.actors.has(speaker_ref):
					if candy_de.actors[speaker_ref].has("Subtitle Speaker Color") and candy_de.actors[speaker_ref]["Subtitle Speaker Color"] != null:
						col = candy_de.actors[speaker_ref]["Subtitle Speaker Color"]
						has_speaker_override = true
						print("Override text color with actor color.")

				#% 2. UI override color:
				if has_speaker_override != true and "enable_speaker_color" in subtitle_node and subtitle_node.enable_speaker_color == true:
					col = subtitle_node.speaker_color
					has_speaker_override = true
					print("Override text color with UI color.")

				#% 3. Global override color:
				if not has_speaker_override and enable_subtitle_speaker_color == true:
					col = subtitle_speaker_color
					has_speaker_override = true
					print("Override text color with general color.")

				#% 4. Apply override if any:
				if has_speaker_override:
					color_tag_open = "[color=%s,%s,%s,%s]" % [col.r, col.g, col.b, col.a]

				#% Add prefix/suffix and merge with text:
				speaker_display = subtitles_speaker_prefix + speaker_display + subtitles_speaker_suffix

				#% Prepare color tag:
				if color_tag_open != "":
					speaker_display = color_tag_open + speaker_display + "[/color]"

			#@ Start voice file playback:
			if enable_voice and voice_player.stream != null:
				voice_player.play()

			#@ Reassign bbcode_text to include speaker name:
			bbcode_text = dialogue_text
			if lexicon_subtitles_mode == true:
				if subtitle_text_node is RichTextLabel and subtitle_text_node.bbcode_enabled and candy_de.lexicon != null:
					bbcode_text = apply_lexicon_tags(dialogue_text, candy_de.lexicon, chosen_variant)

			#% Assign speaker name to text now, to avoid Lexicon formatting:
			if subtitles_show_speaker == true:
				bbcode_text = speaker_display + " " + bbcode_text

			#@ Dialogue writing speed logic:
			var total_visible := bbcode_strip_tags(bbcode_text).length() - (bbcode_strip_tags(speaker_display).length() + 1 if subtitles_show_speaker else 0)
			subtitle_node.caller = self

			#% 1. Instant writing (no typewriter):
			if writing_speed <= 0:
				subtitle_text_node.text = bbcode_text
				await wait_for_player_advance()
				if vn_mode == true and bust_positions.has(speaker_ref):
					get_node(ui_elements_paths["busts_path"]).end_highlight_speaker(speaker_ref, style)
				dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})
				candy_de.general_dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})

			#% 2. Typewriter writing:
			elif writing_speed > 0:
				var effective_speed = writing_speed
				var i := 0
				var char_progress = 0.0
				var last_time = Time.get_ticks_msec() / 1000.0

				#% Set full text immediately for correct word wrapping:
				subtitle_text_node.text = bbcode_text

				#% Display speaker name immediately if enabled:
				var speaker_offset := 0
				if subtitles_show_speaker == true:
					speaker_offset = bbcode_strip_tags(speaker_display).length() + 1	#/ +1 for the space
				subtitle_text_node.visible_characters = speaker_offset

				#% Synchronize writing speed with voice playback:
				if sync_write_speed_voice == true:
					if enable_voice and voice_player.stream != null:
						var voice_length = voice_player.stream.get_length()	#/ Duration in seconds
						if voice_length > 0.1 and total_visible > 0:
							effective_speed = float(total_visible) / voice_length

				#. Hook call:
				if subtitle_node.has_method("x_write_begun"):
					await subtitle_node.x_write_begun()

				#% Write text:
				while i < total_visible:
					#@ 0. Suspension check:
					#% If dialogue is suspended, pause typewriter and all media players:
					if dialogue_suspended == true:
						while dialogue_suspended == true:
							await get_tree().process_frame
						last_time = Time.get_ticks_msec() / 1000.0		#/ Prevent time jump after resume
						continue

					#@ 1. Skip/Slow/Skip:
					#% 1A. Speed writing:
					if Input.is_action_just_pressed(input_speed_dialogue) and input_enabled == true:
						if continue_skip_speed < 0:
							pass
						elif continue_skip_speed == 0:
							subtitle_text_node.visible_characters = -1
							break
						else:
							effective_speed = continue_skip_speed

					#% 1B. Slow writing:
					elif Input.is_action_just_pressed(input_slow_dialogue) and input_enabled == true:
						if continue_skip_speed < 0:
							pass
						elif continue_slow_speed == 0:
							subtitle_text_node.visible_characters = -1
							break
						else:
							effective_speed = continue_slow_speed

					#% 1C. Skip writing:
					elif Input.is_action_just_pressed(input_skip_dialogue) and input_enabled == true:
						subtitle_text_node.visible_characters = -1
						break

					#@ 2. Time progression:
					var now := Time.get_ticks_msec() / 1000.0
					var delta = now - last_time
					last_time = now

					char_progress += effective_speed * delta
					var chars_to_add = int(char_progress)
					if chars_to_add > 0:
						char_progress -= chars_to_add
						i = min(i + chars_to_add, total_visible)

						#@ 3. Update text safely (with balanced BBCode tags):
						subtitle_text_node.visible_characters = speaker_offset + i

					await get_tree().process_frame

			#. Hook call:
			if subtitle_node.has_method("x_write_finished"):
				await subtitle_node.x_write_finished()

			await wait_for_player_advance()

			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).end_highlight_speaker(speaker_ref, style)

			#@ Clear subtitles after display:
			subtitle_text_node.text = ""

			voice_player.stop()

			#@ Log to history:
			if write_dialogue_history == true:
				dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})
				candy_de.general_dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})

			return


		"Chat":
			#@ Get chat nodes:
			var chat_node = get_node(ui_elements_paths["chat_path"])
			var chat_text_node = chat_node.dialogue_node

			chat_node.visible = true

			#@ Add end-of-line string:
			dialogue_text = dialogue_text + chat_end_of_line_string

			#@ Dialogue text initialization (no clearing for chat):
			if chat_text_node.text == null:
				chat_text_node.text = ""

			#% Determine text color (priority: Actor → Global → Node default):
			var final_font_color
			var has_override = false

			#% 1. Actor-specific color:
			if candy_de.actors.has(speaker_ref):
				if candy_de.actors[speaker_ref].has("Chat Text Color") and candy_de.actors[speaker_ref]["Chat Text Color"] != null:
					final_font_color = candy_de.actors[speaker_ref]["Chat Text Color"]
					has_override = true
					print("Override text color with actor color.")

			#% 2. UI override color:
			if has_override != true and "enable_text_color" in chat_node and chat_node.enable_text_color == true:
				final_font_color = chat_node.text_color
				has_override = true
				print("Override text color with UI color.")

			#% 3. Global pverride color:
			if has_override != true and enable_chat_font_color == true:
				final_font_color = chat_font_color
				has_override = true
				print("Override text color with general color.")

			#% 4. Apply override if any:
			if has_override:
				if chat_text_node is RichTextLabel:
					chat_text_node.add_theme_color_override("default_color", final_font_color)
				elif chat_text_node is Label:
					chat_text_node.add_theme_color_override("font_color", final_font_color)

			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).highlight_speaker(speaker_ref, style)

			#@ Audio handling:
			var voice_player = get_node(media_players_locations["Voice"])
			var use_tts := false
			var tts_mode = text_to_speech
			var tts_output

			#% 1. Check if using TTS:
			#% Default settings:
			if text_to_speech != TtsModes.Off:
				use_tts = true

			#% Actor override:
			if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("TTS"):
				var actor_tts = candy_de.actors[speaker_ref]["TTS"]
				if actor_tts == -1:
					use_tts = false
				elif actor_tts == 1:
					use_tts = true

			#% Line Override:
			if tts == -1:
				use_tts = false
			elif tts == 1:
				use_tts = true

			#% 2. Call TTS query:
			if use_tts:
				tts_output = candy_de.tts(self, tts_mode, speaker_ref, dialogue_text, line_data, chosen_variant)
				if tts_output == null:
					use_tts = false

			#% 3. Use the output:
			if use_tts == true:
				if tts_output is AudioStream:
					voice_player.stream = tts_output
				elif typeof(tts_output) == TYPE_STRING and ResourceLoader.exists(tts_output):
					var stream = load(tts_output)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("TTS output is not a valid AudioStream: ", tts_output)
				else:
					#% TTS failed to provide usable data → fallback:
					use_tts = false

			#% 4. If TTS failed or disabled, try pre-recorded file:
			if use_tts == false:
				if voice_file != "" and ResourceLoader.exists(voice_file):
					var stream = load(voice_file)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("Audio file is not a valid stream: ", voice_file)

				#% 5. No valid file found → stop or clear:
				else:
					if voice_player.playing:
						voice_player.stop()
					voice_player.stream = null

			#@ Apply lexicon tags to dialogue text (if BBCode enabled):
			var bbcode_text = dialogue_text
			if lexicon_chat_mode == true:
				if chat_text_node is RichTextLabel and chat_text_node.bbcode_enabled and candy_de.lexicon != null:
					bbcode_text = apply_lexicon_tags(dialogue_text, candy_de.lexicon, chosen_variant)

			#@ Prepare speaker name if enabled:
			if chat_show_speaker == true:
				var color_tag_open = ""
				var col: Color
				var has_speaker_override = false

				#% 1. Actor-specific color:
				if candy_de.actors.has(speaker_ref):
					if candy_de.actors[speaker_ref].has("Chat Speaker Color") and candy_de.actors[speaker_ref]["Chat Speaker Color"] != null:
						col = candy_de.actors[speaker_ref]["Chat Speaker Color"]
						has_speaker_override = true
						print("Override text color with actor color.")

				#% 2. UI override color:
				if has_speaker_override != true and "enable_speaker_color" in chat_node and chat_node.enable_speaker_color is Color:
					col = chat_node.speaker_color
					has_speaker_override = true
					print("Override text color with UI color.")

				#% 3. Global override color:
				if not has_speaker_override and enable_chat_speaker_color == true:
					col = subtitle_speaker_color
					has_speaker_override = true
					print("Override text color with general color.")

				#% 4. Apply override if any:
				if has_speaker_override:
					color_tag_open = "[color=%s,%s,%s,%s]" % [col.r, col.g, col.b, col.a]

				#% Add prefix/suffix and merge with text:
				speaker_display = chat_speaker_prefix + speaker_display + chat_speaker_suffix

				#% Prepare color tag:
				if color_tag_open != "":
					speaker_display = color_tag_open + speaker_display + "[/color]"

				dialogue_text = speaker_display + " " + dialogue_text

			#@ Start voice file playback:
			if enable_voice and voice_player.stream != null:
				voice_player.play()

			#@ Dialogue writing speed logic:
			var total_visible := bbcode_strip_tags(bbcode_text).length()
			chat_node.caller = self

			#% 1. Instant writing (no typewriter):
			if writing_speed <= 0:
				#% Append rather than replace:
				chat_text_node.append_text(dialogue_text + "\n")
				await wait_for_player_advance()
				if vn_mode == true and bust_positions.has(speaker_ref):
					get_node(ui_elements_paths["busts_path"]).end_highlight_speaker(speaker_ref, style)
				dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})
				candy_de.general_dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})

			#% 2. Typewriter writing:
			elif writing_speed > 0:
				var effective_speed = writing_speed
				var i := 0
				var char_progress = 0.0
				var last_time = Time.get_ticks_msec() / 1000.0

				#% Calculate character offset of previous lines:
				var previous_chars = chat_text_node.get_parsed_text().length()

				#% Append speaker name immediately if enabled:
				if chat_show_speaker == true:
					chat_text_node.append_text(speaker_display + " ")
					previous_chars = chat_text_node.get_parsed_text().length()

				#% Append the full spoken text immediately for correct word wrapping:
				chat_text_node.append_text(bbcode_text + "\n")
				chat_text_node.visible_characters = previous_chars

				#% Synchronize writing speed with voice playback:
				if sync_write_speed_voice == true:
					if enable_voice and voice_player.stream != null:
						var voice_length = voice_player.stream.get_length()
						if voice_length > 0.1 and total_visible > 0:
							effective_speed = float(total_visible) / voice_length

				#. Hook call:
				if chat_node.has_method("x_write_begun"):
					await chat_node.x_write_begun()

				#% Write text:
				while i < total_visible:
					#@ 0. Suspension check:
					if dialogue_suspended == true:
						while dialogue_suspended == true:
							await get_tree().process_frame
						last_time = Time.get_ticks_msec() / 1000.0
						continue

					#@ 1. Skip/Slow/Speed:
					#% 1A. Speed writing:
					if Input.is_action_just_pressed(input_speed_dialogue) and input_enabled == true:
						if continue_skip_speed < 0:
							pass
						elif continue_skip_speed == 0:
							chat_text_node.visible_characters = -1
							break
						else:
							effective_speed = continue_skip_speed

					#% 1B. Slow writing:
					elif Input.is_action_just_pressed(input_slow_dialogue) and input_enabled == true:
						if continue_skip_speed < 0:
							pass
						elif continue_slow_speed == 0:
							chat_text_node.visible_characters = -1
							break
						else:
							effective_speed = continue_slow_speed

					#% 1C. Skip writing:
					elif Input.is_action_just_pressed(input_skip_dialogue) and input_enabled == true:
						chat_text_node.visible_characters = -1
						break

					#@ 2. Time progression:
					var now := Time.get_ticks_msec() / 1000.0
					var delta = now - last_time
					last_time = now
					char_progress += effective_speed * delta

					var chars_to_add = int(char_progress)

					if chars_to_add > 0:
						char_progress -= chars_to_add
						i = min(i + chars_to_add, total_visible)

						#% 3. Update visible characters:
						chat_text_node.visible_characters = previous_chars + i

					await get_tree().process_frame

			#. Hook call:
			if chat_node.has_method("x_write_finished"):
				await chat_node.x_write_finished()

			await wait_for_player_advance()

			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).end_highlight_speaker(speaker_ref, style)

			#@ Do NOT clear chat text:
			voice_player.stop()

			#@ Log to history:
			if write_dialogue_history == true:
				dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})
				candy_de.general_dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})

			return


		"Voice":
			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).highlight_speaker(speaker_ref, style)

			#@ Audio handling:
			var voice_player = get_node(media_players_locations["Voice"])
			var use_tts := false
			var tts_mode = text_to_speech
			var tts_output

			#% 1. Check if using TTS:
			#% Default settings:
			if text_to_speech != TtsModes.Off:
				use_tts = true

			#% Actor override:
			if candy_de.actors.has(speaker_ref) and candy_de.actors[speaker_ref].has("TTS"):
				var actor_tts = candy_de.actors[speaker_ref]["TTS"]
				if actor_tts == -1:
					use_tts = false
				elif actor_tts == 1:
					use_tts = true

			#% Line Override:
			if tts == -1:
				use_tts = false
			elif tts == 1:
				use_tts = true

			#% 2. Call TTS query:
			if use_tts:
				tts_output = candy_de.tts(self, tts_mode, speaker_ref, dialogue_text, line_data, chosen_variant)
				if tts_output == null:
					use_tts = false

			#% 3. Use the output:
			if use_tts == true:
				if tts_output is AudioStream:
					voice_player.stream = tts_output
				elif typeof(tts_output) == TYPE_STRING and ResourceLoader.exists(tts_output):
					var stream = load(tts_output)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("TTS output is not a valid AudioStream: ", tts_output)
				else:
					#% TTS failed to provide usable data → fallback:
					use_tts = false

			#% 4. If TTS failed or disabled, try pre-recorded file:
			if use_tts == false:
				if voice_file != "" and ResourceLoader.exists(voice_file):
					var stream = load(voice_file)
					if stream is AudioStream:
						voice_player.stream = stream
					else:
						printerr("Audio file is not a valid stream: ", voice_file)

				#% 5. No valid file found → stop or clear:
				else:
					if voice_player.playing:
						voice_player.stop()
					voice_player.stream = null

			#@ Start voice file playback:
			if voice_player.stream != null:
				await voice_player.playback_starting()
				voice_player.play()
				await voice_player.playback_started()
				await wait_for_player_advance()

			#@ VN Mode:
			if vn_mode == true and bust_positions.has(speaker_ref):
				get_node(ui_elements_paths["busts_path"]).end_highlight_speaker(speaker_ref, style)

			voice_player.stop()

			#@ Log to history:
			if write_dialogue_history == true:
				dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})
				candy_de.general_dialogue_history.append({
					"Speech": {
						"speaker_ref": speaker_ref,
						"display_name": speaker_display,
						"speech": dialogue_text,
						"portrait": portrait_raw,
						"disposition": disposition
					}
				})

			return

#endregion - engine core


#?##############################
#& DIALOGUE PROGRESSION:
#?######################
#region
#* Wait for player input or auto-read timeout to advance dialogue:
func wait_for_player_advance(voice_player = null) -> void:
	print("Waiting for player advance.")

	#@ Wait for advance key to be released before accepting input:
	while Input.is_action_pressed(input_advance_dialogue):
		await get_tree().process_frame

	var timer := 0.0
	var auto_enabled = auto_advance > -1
	var wait_time := float(auto_advance)

	#@ Advance:
	while true:
		await get_tree().process_frame

		#@ Suspension check:
		#% When dialogue_suspended is true, pause everything (no input, no timer)
		if dialogue_suspended == true:
			continue

		#@ Always count time when auto-read is active:
		if auto_enabled:
			timer += get_process_delta_time()

		#@ Manual advance:
		#% - If awaiting voice playback: only allowed after voice ends
		#% - If not awaiting: always allowed
		if Input.is_action_just_pressed(input_advance_dialogue) and input_enabled == true:
			if not await_voice_playback or voice_player == null or not voice_player.playing:
				break		#/ Player manually advances even if timer not finished

		#@ Auto-read advance:
		#% Only if timer done *and* (voice finished or no player)
		if auto_enabled and timer >= wait_time:
			var voice_done = (voice_player == null or not voice_player.playing)
			if voice_done:
				break

	await get_tree().process_frame

#* End the dialogue:
func end_dialogue():
	print("Greenlight = " + str(greenlight))
	#@ §Jump - Skip cleanup.
	if greenlight == false:
		print("end_dialogue(): greenlight false")
		#% Reset greenlight:
		greenlight = true

	#@ End - Cleanup
	elif greenlight == true:
		#% Change game state back to game:
		candy_de.change_game_state(self, "end")

		#% Clear UI:
		await clear_ui()

		#% Reset Mouse Mode:
		if mouse_mode_end != MouseModes.None:
			Input.set_mouse_mode(mouse_mode_end as Input.MouseMode)

		#% Stop any media:
		for path in media_players_locations:
			var media_player = get_node_or_null(media_players_locations[path])
			if media_player is AudioStreamPlayer or media_player is AudioStreamPlayer2D or media_player is AudioStreamPlayer3D or  media_player is VideoStreamPlayer:
				media_player.stop()

		#% Reset greenlight for the next dialogues:
		greenlight = true

		#. Hook call:
		if candy_de.has_method("x_dialogue_end"):
			await candy_de.x_dialogue_end(self)

		#% Disable dialogue_running
		dialogue_running = false

		print("end_dialogue(): Dialogue Ended")


#* Called upon new line to clear previous dialogue:
func clear_previous_dialogue(mode, _speaker):
	#@ Always Clear Speech Bubbles:
	if previous_mode == "Bubbles":
		var npc_path_node = get_node_or_null(bubbles_npc_path)
		if npc_path_node:
			var speaker_node = npc_path_node.get_node_or_null(previous_speaker)
			if speaker_node:
				speaker_node.internal_node_dict["Speech_Bubble"].clear()

		var player_path_node = get_node_or_null(bubbles_player_path)
		if player_path_node and player_path_node != npc_path_node:
			var speaker_node = player_path_node.get_node_or_null(previous_speaker)
			if speaker_node:
				speaker_node.internal_node_dict["Speech_Bubble"].clear()

	#@ Always Clear VN_Bubbles:
	if previous_mode == "VN_Bubbles" and ui_elements_paths.has("busts_path"):
		var bust_scene = get_node_or_null(ui_elements_paths["busts_path"])
		var busts_container = bust_scene.busts_container
		for bust in busts_container.get_children():
			if bust.has_node("SpeechBubble"):
				bust.get_node("SpeechBubble").clear()

	#@ Always Clear Barks:
	if previous_mode == "Bark" and ui_elements_paths.has("barks_path"):
		var bark_root := get_node_or_null(ui_elements_paths["barks_path"])
		if bark_root:
			bark_root.visible = false
			bark_root.dialogue_node.text = ""

	#@ Clear dialogue box if mode changed:
	if previous_mode == "Box" and mode != "Box" and ui_elements_paths.has("dialogue_box_path"):
		var dialogue_box_root := get_node_or_null(ui_elements_paths["dialogue_box_path"])
		if dialogue_box_root:
			dialogue_box_root.visible = false
			dialogue_box_root.speaker_node.text = ""
			dialogue_box_root.dialogue_node.text = ""

		#@ Clear Portraits:
		if ui_elements_paths.has("portrait_path"):
			var portraits_root := get_node_or_null(ui_elements_paths["portrait_path"])
			if portraits_root:
				portraits_root.visible = false
				portraits_root.no_portrait()

	#@ Clear Subtitles if mode changed:
	if previous_mode == "Subtitles" and mode != "Subtitles" and ui_elements_paths.has("subtitles_path"):
		var subtitles_root := get_node_or_null(ui_elements_paths["subtitles_path"])
		if subtitles_root:
			subtitles_root.visible = false
			subtitles_root.dialogue_node.text = ""

	#@ Only clear chat if mode changed and chatbox not persistent:
	if previous_mode == "Chat" and mode != "Chat" and persistent_chat == false and ui_elements_paths.has("dialogue_box_path"):
		var chat_root := get_node_or_null(ui_elements_paths["chat_path"])
		if chat_root:
			chat_root.visible = false
			chat_root.dialogue_node.text = ""


#* Clear all UI elements:
#% Ensures old data doesn't display on screen next time dialogues run.
func clear_ui():
	#@ Clear dialogue box:
	if ui_elements_paths.has("dialogue_box_path"):
		var dialogue_box_root := get_node_or_null(ui_elements_paths["dialogue_box_path"])
		if dialogue_box_root:
			dialogue_box_root.visible = false
			dialogue_box_root.speaker_node.text = ""
			dialogue_box_root.dialogue_node.text = ""

			#% Reset z_index to default:
			dialogue_box_root.z_index = dialogue_box_root.default_z

	#@ Clear Speech Bubbles:
	var npc_path_node = get_node_or_null(bubbles_npc_path)
	if npc_path_node:
		for actor in npc_path_node.get_children():
			actor.internal_node_dict["Speech_Bubble"].clear()

	var player_path_node = get_node_or_null(bubbles_player_path)
	if player_path_node:
		for actor in player_path_node.get_children():
			actor.internal_node_dict["Speech_Bubble"].clear()

	#@ Clear Barks:
	if ui_elements_paths.has("barks_path"):
		var bark_root := get_node_or_null(ui_elements_paths["barks_path"])
		if bark_root:
			bark_root.visible = false
			bark_root.dialogue_node.text = ""

			#% Reset z_index to default:
			bark_root.z_index = bark_root.default_z

	#@ Clear Subtitles:
	if ui_elements_paths.has("subtitles_path"):
		var subtitles_root := get_node_or_null(ui_elements_paths["subtitles_path"])
		if subtitles_root:
			subtitles_root.visible = false
			subtitles_root.dialogue_node.text = ""

			#% Reset z_index to default:
			subtitles_root.z_index = subtitles_root.default_z

	#@ Clear Chat Box:
	if ui_elements_paths.has("chat_path"):
		var chat_root := get_node_or_null(ui_elements_paths["chat_path"])
		if chat_root:
			if chat_hide_on_end:
				chat_root.visible = false
			if chat_clear_on_end:
				chat_root.dialogue_node.text = ""

			#% Reset z_index to default:
			chat_root.z_index = chat_root.default_z

	#@ Clear Portraits:
	if ui_elements_paths.has("portrait_path"):
		var portraits_root := get_node_or_null(ui_elements_paths["portrait_path"])
		if portraits_root:
			portraits_root.visible = false
			portraits_root.no_portrait()

			#% Reset z_index to default:
			portraits_root.z_index = portraits_root.default_z

	#@ Clear VN busts
	#% Only if clear_busts_end = true
	if persistent_busts_on_end == false and ui_elements_paths.has("busts_path"):
		var busts_root := get_node_or_null(ui_elements_paths["busts_path"])
		if busts_root:
			busts_root.visible = false
			await busts_root.clear_bust_nodes([])

		#% Clear dictionary that tracks bust positions:
		bust_positions.clear()

	#@ Clear backgrounds:
	if persistent_bg_on_end == false and ui_elements_paths.has("backgrounds_path"):
		var bg_root = get_node_or_null(ui_elements_paths["backgrounds_path"])
		if bg_root:
			bg_root.visible = false
			bg_root.clear_bg_nodes([])
#endregion


#?##############################
#& DIALOGUE SUSPEND:
#?##################
#region
#* Suspend dialogue:
func suspend_dialogue():
	if suspend_media == true:
		pause_media_players()
	if suspend_portraits == true:
		pause_portraits()
	if suspend_backgrounds == true:
		pause_backgrounds()
	if suspend_vn_busts == true:
		pause_busts()

#* Resume dialogue:
func resume_dialogue():
	if suspend_media == true:
		resume_media_players()
	if suspend_portraits == true:
		resume_portraits()
	if suspend_backgrounds == true:
		resume_backgrounds()
	if suspend_vn_busts == true:
		resume_busts()


#* Pause all currently active media players and record them for later resuming:
func pause_media_players() -> void:
	if not media_players_locations:
		return

	#% Reset the suspended list:
	suspended_media_players = []

	#% Get voice player:
	var voice_player
	if media_players_locations.has("Voice"):
		voice_player = get_node_or_null(media_players_locations["Voice"])

	#@ Iterate through media players:
	for key in media_players_locations.keys():
		if key in media_suspend_immune:
			continue

		var path = media_players_locations[key]
		if not has_node(path):
			continue

		var player = get_node(path)

		#@ Voiced Dialogue:
		if player == voice_player and suspend_voice == true:
			if player.playing and not player.stream_paused:
				player.stream_paused = true
				suspended_media_players.append([key, self])

		#@ AudioStreamPlayer:
		elif (player is AudioStreamPlayer or player is AudioStreamPlayer2D or player is AudioStreamPlayer3D) and player != voice_player and suspend_audio == true:
			if player.playing and not player.stream_paused:
				player.stream_paused = true
				suspended_media_players.append([key, self])

		#@ VideoStreamPlayer:
		elif player is VideoStreamPlayer:
			if player.is_playing() and not player.paused and suspend_video == true:
				player.paused = true
				suspended_media_players.append([key, self])

		#@ AnimationPlayer:
		elif player is AnimationPlayer and suspend_animations == true:
			if player.is_playing():
				player.pause()
				suspended_media_players.append([key, self])

		#@ Image player (TextureRect with Timer):
		elif player is TextureRect and player.has_node("Timer") and suspend_images == true:
			var timer := player.get_node("Timer")
			if timer is Timer and not timer.paused:
				timer.paused = true
				suspended_media_players.append([key, self])


#* Resume all previously paused media players paused by this engine instance:
func resume_media_players() -> void:
	if not suspended_media_players:
		return

	#@ Build a new list to keep entries that are not resumed yet (if any):
	var remaining := []

	for entry in suspended_media_players:
		if entry.size() < 2:
			continue

		var key = entry[0]
		var source = entry[1]
		if source != self:
			remaining.append(entry)
			continue
		if not media_players_locations.has(key):
			continue

		var path = media_players_locations[key]
		if not has_node(path):
			continue

		var player = get_node(path)

		#@ AudioStreamPlayer:
		if player is AudioStreamPlayer or player is AudioStreamPlayer2D or player is AudioStreamPlayer3D:
			player.stream_paused = false

		#@ VideoStreamPlayer:
		elif player is VideoStreamPlayer:
			player.paused = false

		#@ AnimationPlayer:
		elif player is AnimationPlayer:
			player.play()

		#@ Image player (TextureRect with Timer):
		elif player is TextureRect:
			if player.has_method("unpause"):
				player.unpause()
			elif player.has_node("Timer"):
				var timer := player.get_node("Timer")
				if timer is Timer:
					timer.paused = false

	#@ Clear the original list:
	suspended_media_players = remaining


#* Suspend portraits:
func pause_portraits() -> void:
	suspended_portrait_nodes = []
	suspended_portrait_animplayers = []

	if not ui_elements_paths.has("portrait_path"):
		return
	var portrait_scene = get_node_or_null(ui_elements_paths["portrait_path"])
	if not portrait_scene:
		return

	var portrait_node = portrait_scene.portrait_node
	if portrait_node:
		if portrait_node is AnimatedSprite2D or portrait_node is AnimatedSprite3D:
			if portrait_node.is_playing():
				portrait_node.pause()
				suspended_portrait_nodes.append(portrait_node)

		elif portrait_node is Sprite2D or portrait_node is Sprite3D:
			var timer = portrait_scene.get_node_or_null("SpriteAnimTimer")
			if timer is Timer and not timer.paused:
				timer.paused = true
				suspended_portrait_nodes.append(portrait_node)

		elif portrait_node is VideoStreamPlayer:
			if portrait_node.is_playing() and not portrait_node.paused:
				portrait_node.paused = true
				suspended_portrait_nodes.append(portrait_node)

	var all_anim_players = _find_animation_players(portrait_scene)
	for player in all_anim_players:
		if player.is_playing():
			player.pause()
			suspended_portrait_animplayers.append(player)

#* Resume portraits:
func resume_portraits() -> void:
	var portrait_scene = get_node_or_null(ui_elements_paths.get("portrait_path", ""))

	for portrait_node in suspended_portrait_nodes:
		if not is_instance_valid(portrait_node):
			continue

		if portrait_node is AnimatedSprite2D or portrait_node is AnimatedSprite3D:
			portrait_node.play()

		elif portrait_node is Sprite2D or portrait_node is Sprite3D:
			if portrait_scene:
				var timer = portrait_scene.get_node_or_null("SpriteAnimTimer")
				if timer is Timer:
					timer.paused = false

		elif portrait_node is VideoStreamPlayer:
			portrait_node.paused = false

	for player in suspended_portrait_animplayers:
		if is_instance_valid(player):
			player.play()

	suspended_portrait_nodes = []
	suspended_portrait_animplayers = []


#* Pause all active background layers and AnimationPlayers due to dialogue suspension:
func pause_backgrounds() -> void:
	suspended_bg_nodes = []
	suspended_bg_animplayers = []

	#@ Pause animated bg layer nodes:
	var bg_scene = get_node_or_null(ui_elements_paths["backgrounds_path"])
	if not bg_scene:
		return

	var bg_container = bg_scene.bg_container
	if bg_container and suspend_bg_animations == true:
		for bg_node in bg_container.get_children():
			if bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
				if bg_node.is_playing():
					bg_node.pause()
					suspended_bg_nodes.append(bg_node)

			elif bg_node is Sprite2D or bg_node is Sprite3D:
				var timer = bg_node.get_node_or_null("BGAnimTimer")
				if timer is Timer and not timer.paused:
					timer.paused = true
					suspended_bg_nodes.append(bg_node)

			elif bg_node is VideoStreamPlayer:
				if bg_node.is_playing() and not bg_node.paused:
					bg_node.paused = true
					suspended_bg_nodes.append(bg_node)

	#@ Pause all AnimationPlayers anywhere in the background scene:
	if suspend_bg_effects == true:
		var all_anim_players = _find_animation_players(self)
		for player in all_anim_players:
			if player.is_playing():
				player.pause()
				suspended_bg_animplayers.append(player)


#* Resume background layers and AnimationPlayers that were paused by dialogue suspension:
func resume_backgrounds() -> void:
	#@ Resume animated bg layer nodes:
	for bg_node in suspended_bg_nodes:
		if not is_instance_valid(bg_node):
			continue

		if bg_node is AnimatedSprite2D or bg_node is AnimatedSprite3D:
			bg_node.play()

		elif bg_node is Sprite2D or bg_node is Sprite3D:
			var timer = bg_node.get_node_or_null("BGAnimTimer")
			if timer is Timer:
				timer.paused = false

		elif bg_node is VideoStreamPlayer:
			bg_node.paused = false

	#@ Resume AnimationPlayers:
	for player in suspended_bg_animplayers:
		if is_instance_valid(player):
			player.play()

	suspended_bg_nodes = []
	suspended_bg_animplayers = []


#* Pause all active bust nodes and AnimationPlayers due to dialogue suspension:
func pause_busts() -> void:
	suspended_bust_nodes = []
	suspended_bust_animplayers = []

	#@ Pause animated bust nodes:
	var vn_scene = get_node_or_null(ui_elements_paths["busts_path"])
	if not vn_scene:
		return

	var busts_container = vn_scene.busts_container
	if busts_container and suspend_bust_animations == true:
		for bust_node in busts_container.get_children():
			if bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
				if bust_node.is_playing():
					bust_node.pause()
					suspended_bust_nodes.append(bust_node)

			elif bust_node is Sprite2D or bust_node is Sprite3D:
				var timer = bust_node.get_node_or_null("SpriteAnimTimer")
				if timer is Timer and not timer.paused:
					timer.paused = true
					suspended_bust_nodes.append(bust_node)

			elif bust_node is VideoStreamPlayer:
				if bust_node.is_playing() and not bust_node.paused:
					bust_node.paused = true
					suspended_bust_nodes.append(bust_node)

	#@ Pause all AnimationPlayers anywhere in the bust scene:
	if suspend_bust_effects == true:
		var all_anim_players = _find_animation_players(self)
		for player in all_anim_players:
			if player.is_playing():
				player.pause()
				suspended_bust_animplayers.append(player)


#* Resume bust nodes and AnimationPlayers that were paused by dialogue suspension:
func resume_busts() -> void:
	#@ Resume animated bust nodes:
	for bust_node in suspended_bust_nodes:
		if not is_instance_valid(bust_node):
			continue

		if bust_node is AnimatedSprite2D or bust_node is AnimatedSprite3D:
			bust_node.play()

		elif bust_node is Sprite2D or bust_node is Sprite3D:
			var timer = bust_node.get_node_or_null("SpriteAnimTimer")
			if timer is Timer:
				timer.paused = false

		elif bust_node is VideoStreamPlayer:
			bust_node.paused = false

	#@ Resume AnimationPlayers:
	for player in suspended_bust_animplayers:
		if is_instance_valid(player):
			player.play()

	suspended_bust_nodes = []
	suspended_bust_animplayers = []


#* Recursively find all AnimationPlayer nodes under a given node:
func _find_animation_players(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		if child is AnimationPlayer:
			result.append(child)
		result.append_array(_find_animation_players(child))
	return result
#endregion


#?##############################
#& BBCODE PROCESSING:
#?###################
#region
#* Detects if a bracketed section is a valid BBCode tag
func _is_valid_bbcode_tag(tag: String) -> bool:
	if not tag.begins_with("[") or not tag.ends_with("]"):
		return false

	#% Remove brackets:
	var inner = tag.substr(1, tag.length() - 2).strip_edges()
	if inner == "" or inner.begins_with(" "):
		return false

	#% Handle closing tags (e.g. [/b], [/color], [/pulse]):
	var is_closing = false
	if inner.begins_with("/"):
		is_closing = true
		inner = inner.substr(1)		#/ strip the "/"

	#% Extract base name (before '=', ' '):
	var base_name := inner.split("=")[0].split(" ")[0]

	#% Is this even a known tag name?:
	var is_known = (
		candy_de.BBCODE_TAGS_SIMPLE.has(base_name)
		or candy_de.BBCODE_TAGS_EQUALS.has(base_name)
		or candy_de.BBCODE_TAGS_SPACE.has(base_name)
	)
	if not is_known:
		return false

	#% For closing tags, [/name] is always valid if name is known:
	if is_closing:
		return true

	#% Type 1 - simple tags with no parameters:
	if inner == base_name and candy_de.BBCODE_TAGS_SIMPLE.has(base_name):
		return true

	#% Type 2 - tags with "=" parameters:
	if candy_de.BBCODE_TAGS_EQUALS.has(base_name):
		if inner.begins_with(base_name + "="):
			return true

	#% Type 3 - tags with space-delimited params:
	if candy_de.BBCODE_TAGS_SPACE.has(base_name):
		if inner.begins_with(base_name + " "):
			return true

	#% Fallback: known tag name but unusual formatting → still treat as BBCode:
	return true


#* Remove all BBCode tags → only visible characters remain
func bbcode_strip_tags(text: String) -> String:
	var stripped := ""
	var inside_tag := false
	var current := ""

	for ch in text:
		if ch == "[":
			inside_tag = true
			current = "["
		elif ch == "]":
			current += "]"
			if _is_valid_bbcode_tag(current):
				#% Skip valid BBCode tags entirely:
				pass
			else:
				#% Keep literal [something] text:
				stripped += current
			current = ""
			inside_tag = false
		elif inside_tag:
			current += ch
		else:
			stripped += ch

	#% If string ended mid-tag, treat as literal:
	if inside_tag and current != "":
		stripped += current

	return stripped
#endregion


#?##############################
#& VARIABLES:
#?###########
#region
#* Replace Candy variable references (£, $) with resolved literal values:
func _replace_with_values(expr: String) -> String:
	#% Define all your prefix symbols
	var symbols = [
		candy_de.singleton_symbol,
		candy_de.node_symbol,
		candy_de.vardict_symbol
	]

	#% Build regex dynamically to match any symbol followed by valid token chars
	var pattern = "[" + "".join(symbols) + "][A-Za-z0-9_\\.\\/\\[\\]\\'\\\" ]+"
	var regex := RegEx.new()
	regex.compile(pattern)

	#% Find all matches
	for match in regex.search_all(expr):
		var token := match.get_string()

		#% Skip malformed tokens with unbalanced brackets
		if token.count("[") != token.count("]"):
			continue

		#% Resolve value
		var value = resolve_value(token)

		#% Convert to Expression-safe literal
		if typeof(value) == TYPE_STRING:
			value = "\"" + value + "\""
		elif value == null:
			value = "null"

		#% Replace in expression
		expr = expr.replace(token, var_to_str(value))

	return expr


#* Resolve any Candy DE variable, node, or resource reference into its final value:
func resolve_value(raw: Variant) -> Variant:
	if raw == null:
		return null

	#@ Non-string values are returned unchanged:
	if typeof(raw) != TYPE_STRING:
		return raw

	var text = raw.strip_edges()
	if text == "":
		return text

	#@ Declare placeholder before assignment (needed for recursion):
	var _resolve : Callable

	#@ Recursive resolver
	_resolve = func(text_val: String, depth := 0) -> Variant:
		if depth > 10:
			printerr("resolve_value(): exceeded recursion depth while resolving ", text_val)
			return text_val

		#% 1. Variable references - £, $, or vardict:
		if text_val.begins_with(candy_de.vardict_symbol) \
		or text_val.begins_with(candy_de.singleton_symbol) \
		or text_val.begins_with(candy_de.node_symbol):

			var decoded = decode_variable_name(text_val)
			if decoded["base"] == null:
				printerr("resolve_value(): could not find base for ", text_val)
				return null

			var resolved = get_variable_value(decoded, _resolve)	#/ pass resolver for nested keys
			if resolved == null:
				printerr("resolve_value(): variable not found → ", text_val)
				return null

			#% Recursively resolve if the variable itself is another string reference:
			#! Not working at this time - will be reworked later.
			#if typeof(resolved) == TYPE_STRING:
				#return _resolve.call(resolved, depth + 1)
			return resolved

		#% 2. Role references - °role_key → looks up actor in candy_de.roles, then resolves path:
		elif text_val.begins_with(candy_de.role_symbol):
			if not candy_de.roles.has(text_val.split(".")[0].split("[")[0]):
				printerr("resolve_value(): role not found → ", text_val)
				return null

			#% Find where the role key ends and the path begins:
			#% Role key is everything up to the first '.' or '[':
			var role_end := text_val.length()
			var dot_pos := text_val.find(".")
			var bracket_pos := text_val.find("[")
			if dot_pos != -1:
				role_end = dot_pos
			if bracket_pos != -1 and bracket_pos < role_end:
				role_end = bracket_pos

			var role_key := text_val.substr(0, role_end)	#/ e.g. "°role"
			var remainder := text_val.substr(role_end)		#/ e.g. "[key][index]" or ".key"

			#% Look up the actor reference:
			var actor_ref: String = candy_de.roles.get(role_key, "")
			if actor_ref == "":
				printerr("resolve_value(): role maps to empty actor → ", role_key)
				return null

			#% If there's no path remainder, just return the actor reference string:
			if remainder == "":
				return actor_ref

			#% Otherwise, reconstruct as a singleton reference and resolve through existing machinery:
			#% e.g. actor_ref = "actor", remainder = "[key][index]"
			#% → build "£actors.actor" + remainder and resolve normally,
			#% since actors live in candy_de.actors (accessed via singleton_symbol):
			var rebuilt = candy_de.singleton_symbol + "candy_de.actors[\"" + actor_ref + "\"]" + remainder
			return resolve_value(rebuilt)

		#% 3. Resource paths (res://, user://):
		elif text_val.begins_with("res://") or text_val.begins_with("user://"):
			if ResourceLoader.exists(text_val):
				var resource := load(text_val)
				if resource != null:
					return resource
				else:
					return text_val
			else:
				push_warning("resolve_value(): resource path is a folder or has no file specified → ", text_val)
				return text_val

		#% 4. Everything else: literal string:
		return text_val

	#@ Execute the recursive helper:
	return _resolve.call(text)


#* Decode a reference string into { base, path }:
func decode_variable_name(ref: String) -> Dictionary:
	var result := { "base": null, "path": [] }
	if ref.is_empty():
		return result

	var raw := ref.substr(1)
	var dot_index := raw.find(".")
	var base_name := raw if dot_index == -1 else raw.substr(0, dot_index)
	var remainder := "" if dot_index == -1 else raw.substr(dot_index + 1)

	#@ Determine base:
	if ref.begins_with(candy_de.node_symbol):
		result["base"] = get_node_or_null("/root/" + base_name)
	elif ref.begins_with(candy_de.singleton_symbol):
		if Engine.has_singleton(base_name):
			result["base"] = Engine.get_singleton(base_name)
		elif has_node("/root/" + base_name):
			result["base"] = get_node("/root/" + base_name)
		elif get(base_name) != null:
			result["base"] = get(base_name)
	elif ref.begins_with(candy_de.vardict_symbol):
		if candy_de.variables.has(base_name):
			result["base"] = candy_de.variables[base_name]

	if result["base"] == null:
		return result

	#@ Parse path:
	if not remainder.is_empty():
		var regex := RegEx.new()
		regex.compile(r"([^. \[\]]+)|\[['\"]?([^'\"]+)['\"]?\]")
		for match in regex.search_all(remainder):
			var key_str = match.get_string(1) if match.get_string(1) != "" else match.get_string(2)
			#% Resolve if the key is a variable reference:
			if key_str.begins_with(candy_de.singleton_symbol) \
			or key_str.begins_with(candy_de.node_symbol) \
			or key_str.begins_with(candy_de.vardict_symbol):
				key_str = resolve_value(key_str)
				if typeof(key_str) == TYPE_STRING and str(key_str).is_valid_int():
					key_str = int(key_str)
			else:
				if key_str.is_valid_int():
					key_str = int(key_str)
			result["path"].append(key_str)

	return result


#* Read the value of a decoded variable reference, resolving nested Candy keys:
func get_variable_value(decoded: Dictionary, resolver = null) -> Variant:
	if not decoded.has("base") or not decoded.has("path"):
		return null

	var current = decoded["base"]
	for step in decoded["path"]:
		#% Resolve step if it's a nested Candy reference
		if typeof(step) == TYPE_STRING \
		and resolver != null \
		and (step.begins_with(candy_de.singleton_symbol) \
			or step.begins_with(candy_de.node_symbol) \
			or step.begins_with(candy_de.vardict_symbol)):
			step = resolver.call(step)

		match typeof(current):
			TYPE_DICTIONARY:
				current = current.get(step, null)
			TYPE_ARRAY:
				current = current[step] if step is int and step >= 0 and step < current.size() else null
			_:
				if current is Object and current.has_method("get"):
					current = current.get(step)
				else:
					current = null

		if current == null:
			return null

	return current


#* Compute a new value for a variable without setting it directly:
#! We can't guarantee that all these operators work as you might expect.
#! Please test oeprators before committing to using them, and check the code below to make sure you understand their effects!
#TODO Feel free to add your own custom operators and logic if you like.
func calculate_variable_value(decoded: Dictionary, value: Variant, op: String) -> Variant:
	var current = get_variable_value(decoded)

	match op:
		#@ BASIC ASSIGNMENT:
		"=":
			return value

		#@ ARITHMETIC OPERATIONS:
		"+=":
			return current + value
		"-=":
			return current - value
		"*=", "×=":
			return current * value
		"/=", "÷=":
			return current / value
		"//=":
			return int(floor(current / value))
		"%=":
			return current % value
		"^=", "**=", "pow":
			return pow(current, value)

		#@ LOGICAL OPERATORS:
		"toggle_bool":
			return not bool(current)

		#@ STRING OPERATIONS:
		"strip_edges":
			return str(current).strip_edges()
		"to_upper":
			return str(current).to_upper()
		"to_lower":
			return str(current).to_lower()
		"replace":
			if typeof(value) == TYPE_ARRAY and value.size() >= 2:
				return str(current).replace(str(value[0]), str(value[1]))
			return str(current)
		"substr":
			if typeof(value) == TYPE_ARRAY and value.size() >= 2:
				return str(current).substr(value[0], value[1])
			return str(current)
		"split":
			if typeof(current) == TYPE_STRING and typeof(value) == TYPE_STRING:
				return current.split(value)
			return current
		"join":
			if typeof(current) == TYPE_ARRAY and typeof(value) == TYPE_STRING:
				return current.join(value)
			return current
		"path_join":
			if typeof(current) == TYPE_STRING and typeof(value) == TYPE_STRING:
				return current.path_join(value)
			return current

		#@ ARRAY OPERATIONS:
		"append":
			if typeof(current) == TYPE_ARRAY:
				var arr = current.duplicate()
				arr.append(value)
				return arr
			return current
		"append_first":
			if typeof(current) == TYPE_ARRAY:
				var arr = current.duplicate()
				arr.insert(0, value)
				return arr
			return current
		"insert":
			if typeof(current) == TYPE_ARRAY and typeof(value) == TYPE_ARRAY and value.size() >= 2:
				var arr = current.duplicate()
				arr.insert(value[0], value[1])
				return arr
			return current
		"erase":
			if typeof(current) == TYPE_ARRAY:
				var arr = current.duplicate()
				arr.erase(value)
				return arr
			return current
		"remove_at":
			if typeof(current) == TYPE_ARRAY and value is int and value >= 0 and value < current.size():
				var arr = current.duplicate()
				arr.remove_at(value)
				return arr
			return current
		"clear":
			if typeof(current) == TYPE_ARRAY:
				return []
			elif typeof(current) == TYPE_DICTIONARY:
				return {}
			else:
				return current
		"slice":
			if typeof(current) == TYPE_ARRAY and typeof(value) == TYPE_ARRAY and value.size() >= 2:
				return current.slice(value[0], value[1])
			return current
		"reverse":
			if typeof(current) == TYPE_ARRAY:
				var arr = current.duplicate()
				arr.reverse()
				return arr
			return current
		"sort":
			if typeof(current) == TYPE_ARRAY:
				var arr = current.duplicate()
				arr.sort()
				return arr
			return current
		"shuffle":
			if typeof(current) == TYPE_ARRAY:
				var arr = current.duplicate()
				arr.shuffle()
				return arr
			return current
		"unique":
			if typeof(current) == TYPE_ARRAY:
				var arr = []
				for item in current:
					if item not in arr:
						arr.append(item)
				return arr
			return current

		#@ DICTIONARY OPERATIONS:
		"merge":
			if typeof(current) == TYPE_DICTIONARY and typeof(value) == TYPE_DICTIONARY:
				var merged = current.duplicate()
				for k in value.keys():
					merged[k] = value[k]
				return merged
			return current
		"get":
			if typeof(current) == TYPE_DICTIONARY:
				return current.get(value)
			return null
		"set_key":
			if typeof(current) == TYPE_DICTIONARY and typeof(value) == TYPE_ARRAY and value.size() >= 2:
				var dict = current.duplicate()
				dict[value[0]] = value[1]
				return dict
			return current
		"duplicate":
			if value is Array or typeof(value) == TYPE_DICTIONARY:
				return value.duplicate(false)	#/ shallow copy
			return value
		"deep_duplicate":
			if value is Array or typeof(value) == TYPE_DICTIONARY:
				return value.duplicate(true)	#/ deep copy
			return value

		#@ TYPE & CONVERSION HELPERS:
		"typeof":
			return typeof(value)
		"is_array":
			return typeof(value) == TYPE_ARRAY
		"is_dict":
			return typeof(value) == TYPE_DICTIONARY
		"is_object":
			return value is Object
		"to_int":
			return int(value)
		"to_float":
			return float(value)
		"to_string":
			return str(value)
		"to_bool":
			return bool(value)

		#@ MATH FUNCTIONS:
		"abs":
			return abs(value)
		"floor":
			return floor(value)
		"ceil":
			return ceil(value)
		"round":
			return round(value)
		"sqrt":
			return sqrt(value)
		"sign":
			return sign(value)
		"sin":
			return sin(value)
		"cos":
			return cos(value)
		"tan":
			return tan(value)
		"asin":
			return asin(value)
		"acos":
			return acos(value)
		"atan":
			return atan(value)
		"deg_to_rad":
			return deg_to_rad(value)
		"rad_to_deg":
			return rad_to_deg(value)
		"log":
			return log(value)
		"log10":
			return log(value) / log(10.0)
		"log_base":
			if typeof(value) in [TYPE_FLOAT, TYPE_INT] and value != 1:
				return log(current) / log(value)
			return current
		"clamp":
			if typeof(value) == TYPE_ARRAY and value.size() >= 2:
				return clamp(current, value[0], value[1])
			return current
		"min":
			if typeof(value) == TYPE_ARRAY and value.size() > 0:
				return value.min()
			return min(current, value)  #/ fallback for single value
		"max":
			if typeof(value) == TYPE_ARRAY and value.size() > 0:
				return value.max()
			return max(current, value)  #/ fallback for single value
		"lerp":
			if typeof(value) == TYPE_ARRAY and value.size() >= 2:
				return lerp(current, value[0], value[1])
			return current
		"wrap":
			if typeof(value) == TYPE_ARRAY and value.size() >= 2:
				return wrapf(current, value[0], value[1])
			return current

		#@ RANDOM & UTILITY:
		"rand_i":
			if typeof(value) == TYPE_ARRAY and value.size() >= 2:
				return randi_range(int(value[0]), int(value[1]))
			return current
		"rand_f":
			if typeof(value) == TYPE_ARRAY and value.size() >= 2:
				return randf_range(float(value[0]), float(value[1]))
			return current
		"rand_pick":
			if typeof(value) == TYPE_ARRAY and value.size() > 0:
				return value[randi() % value.size()]
			return current

		#@ NODES:
		"get_node":
			if typeof(value) == TYPE_STRING:
				return get_node(value)
			return null
		"get_node_or_null":
			if typeof(value) == TYPE_STRING:
				return get_node_or_null(value)
			return null

		#@ CANDY SPECIALS:
		"candy_to_dict":
			if typeof(value) == TYPE_STRING or typeof(value) == TYPE_ARRAY:
				return candy_to_dict(value)
			return value
		"candy_to_array":
			if typeof(value) == TYPE_STRING or typeof(value) == TYPE_DICTIONARY:
				return candy_to_array(value)
			return value
		"candy_to_string":
			if typeof(value) == TYPE_DICTIONARY or typeof(value) == TYPE_ARRAY:
				return candy_to_string(value)
			return str(value)

		#@ FALLBACK:
		_:
			push_error("Unknown operator in Set Command: " + op)
			return current


#* Write a value to a decoded variable reference:
func set_variable_value(decoded: Dictionary, value: Variant) -> void:
	if not decoded.has("base") or not decoded.has("path"):
		return

	var container = decoded["base"]
	var path: Array = decoded["path"]

	#% Walk down to the parent of the last key:
	for i in range(path.size() - 1):
		var step = path[i]
		if typeof(container) == TYPE_DICTIONARY:
			if not container.has(step) or container[step] == null:
				container[step] = {}
			container = container[step]
		elif container is Object:
			#% Direct field access for autoload/script vars:
			var sub = null
			if container.get(step) != null:
				sub = container.get(step)
			else:
				sub = {}
				container.set(step, sub)
			container = sub
		else:
			return

	#% Final assignment:
	var last_key = path[-1] if path.size() > 0 else null
	if typeof(container) == TYPE_DICTIONARY:
		container[last_key] = value
	elif typeof(container) == TYPE_ARRAY and last_key is int:
		if last_key >= 0 and last_key < container.size():
			container[last_key] = value
		elif last_key == container.size():
			container.append(value)
	elif container is Object:
		container.set(last_key, value)
#endregion - variables


#?##############################
#& CANDY DATA CONVERSION SYSTEM:
#?##############################
#region
#* Convert string or array to dictionary:
func candy_to_dict(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_STRING:
		#% Add outer {} implicitly:
		return _candy_parse_dict("{" + value.strip_edges() + "}")
	elif typeof(value) == TYPE_ARRAY:
		var result := {}
		for item in value:
			if typeof(item) == TYPE_ARRAY and item.size() >= 2:
				result[str(item[0])] = item[1]
			else:
				result[str(item)] = null
		return result
	return value

#* Convert string or dictionary to array
func candy_to_array(value: Variant) -> Array:
	if typeof(value) == TYPE_STRING:
		#% Add outer [] implicitly:
		return _candy_parse_array("[" + value.strip_edges() + "]")
	elif typeof(value) == TYPE_DICTIONARY:
		var result := []
		for k in value.keys():
			var v = value[k]
			if v != null:
				result.append([str(k), v])
			else:
				result.append(str(k))
		return result
	return value

#* Convert a dictionary or array to Candy-readable text (JSON-like style):
#% Does NOT include outer {} or [] by default
func candy_to_string(value: Variant) -> String:
	match typeof(value):
		TYPE_DICTIONARY:
			var parts: Array = []
			for k in value:
				var v = value[k]
				var val_str = _candy_value_to_string(v)
				var key_str = "\"" + str(k).replace("\"", "\\\"") + "\""
				parts.append(key_str + ": " + val_str)
			return ", ".join(parts)

		TYPE_ARRAY:
			var parts: Array = []
			for v in value:
				parts.append(_candy_value_to_string(v))
			return ", ".join(parts)

		_:
			return str(value)


#& INTERNAL HELPERS
#* Helper for candy_to_string():
#% Converts a single value (string, number, bool, etc.) into its Candy-compatible text form.
#% Used only when serializing elements within arrays or dictionaries.
func _candy_value_to_string(v: Variant) -> String:
	if v == null:
		return "null"

	match typeof(v):
		TYPE_STRING, TYPE_STRING_NAME:
			var escaped = v.replace("\\", "\\\\").replace("\"", "\\\"")
			return "\"" + escaped + "\""
		TYPE_BOOL:
			if v:
				return "true"
			else:
				return "false"
		TYPE_INT, TYPE_FLOAT:
			return str(v)
		TYPE_ARRAY:
			return "[" + candy_to_string(v) + "]"
		TYPE_DICTIONARY:
			return "{" + candy_to_string(v) + "}"
		TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_VECTOR3, TYPE_VECTOR3I, TYPE_COLOR, TYPE_RECT2, TYPE_RECT2I, TYPE_QUATERNION, TYPE_PLANE, TYPE_AABB, TYPE_BASIS, TYPE_TRANSFORM2D, TYPE_TRANSFORM3D, TYPE_NODE_PATH:
			return "\"" + str(v) + "\""
		_:
			push_warning("UNSUPPORTED TYPE: " + str(typeof(v)) + "- Will be converted to literal string.")
			return "\"" + str(v) + "\""

#* Parse a Candy string into a Dictionary:
func _candy_parse_dict(s: String) -> Dictionary:
	var result := {}
	s = s.strip_edges()
	if s.begins_with("{") and s.ends_with("}"):
		s = s.substr(1, s.length() - 2)

	var tokens = _candy_split_top_level(s)
	for token in tokens:
		token = token.strip_edges()
		if token == "":
			continue
		var kv = token.split(":", false, 2)
		var raw_key = kv[0].strip_edges()

		if (raw_key.begins_with('"') and raw_key.ends_with('"')) \
		or (raw_key.begins_with("'") and raw_key.ends_with("'")):
			raw_key = raw_key.substr(1, raw_key.length() - 2)

		var key = raw_key
		var val: Variant = null
		if kv.size() > 1:
			val = _candy_parse_value(kv[1].strip_edges())
		result[key] = val
	return result

#* Parse a Candy string into an Array:
func _candy_parse_array(s: String) -> Array:
	var result: Array = []
	s = s.strip_edges()

	#@ Verify that the brackets exist:
	if not (s.begins_with("[") and s.ends_with("]")):
		printerr("§Candy Parse Error: Array must start with '[' and end with ']': ", s)
		return result

	var tokens = _candy_split_top_level(s.substr(1, s.length() - 2))	#/ ← only pass the inside to split, but we don't mutate s itself
	for token in tokens:
		token = token.strip_edges()
		if token == "":
			continue
		result.append(_candy_parse_value(token))

	return result

#* Parse individual values (recursively):
func _candy_parse_value(text: String) -> Variant:
	text = text.strip_edges()
	if text == "":
		return null

	#% Nested dict:
	if text.begins_with("{") and text.ends_with("}"):
		return _candy_parse_dict(text)
	#% Nested array:
	if text.begins_with("[") and text.ends_with("]"):
		return _candy_parse_array(text)
	#% String:
	if (text.begins_with("'") and text.ends_with("'")) or (text.begins_with('"') and text.ends_with('"')):
		var unquoted = text.substr(1, text.length() - 2)
		#% Try Vector2/Vector3/Vector2i/Vector3i
		if unquoted.begins_with("(") and unquoted.ends_with(")"):
			var inner = unquoted.substr(1, unquoted.length() - 2)
			var parts = inner.split(",")
			if parts.size() == 2:
				var p0 = parts[0].strip_edges()
				var p1 = parts[1].strip_edges()
				if p0.is_valid_int() and p1.is_valid_int():
					return Vector2i(int(p0), int(p1))
				elif p0.is_valid_float() and p1.is_valid_float():
					return Vector2(float(p0), float(p1))
			elif parts.size() == 3:
				var p0 = parts[0].strip_edges()
				var p1 = parts[1].strip_edges()
				var p2 = parts[2].strip_edges()
				if p0.is_valid_int() and p1.is_valid_int() and p2.is_valid_int():
					return Vector3i(int(p0), int(p1), int(p2))
				elif p0.is_valid_float() and p1.is_valid_float() and p2.is_valid_float():
					return Vector3(float(p0), float(p1), float(p2))
			elif parts.size() == 4:
				var all_valid = true
				for p in parts:
					if not p.strip_edges().is_valid_float():
						all_valid = false
						break
				if all_valid:
					return Rect2(float(parts[0].strip_edges()), float(parts[1].strip_edges()), float(parts[2].strip_edges()), float(parts[3].strip_edges()))
		#% Try Color
		if unquoted.begins_with(char(35)) or unquoted.to_lower() in ["red", "green", "blue", "white", "black", "yellow", "cyan", "magenta"]:
			return Color(unquoted)
		#% Try NodePath
		if unquoted.begins_with("/") or unquoted.begins_with("..") or unquoted.find("/") != -1:
			return NodePath(unquoted)
		return unquoted
	#% Booleans:
	if text.to_lower() == "true":
		return true
	if text.to_lower() == "false":
		return false
	#% Null:
	if text.to_lower() == "null":
		return null
	#% Number:
	if text.is_valid_int():
		return int(text)
	if text.is_valid_float():
		return float(text)
	#% Fallback literal:
	return text

#* Split a Candy expression string by commas at top-level only:
#% Ignores commas inside {}, [] and inside quoted strings.
func _candy_split_top_level(s: String) -> Array:
	var tokens: Array = []
	var depth_curly := 0
	var depth_square := 0
	var in_string := false
	var string_char := ""
	var escaped := false
	var current := ""

	for i in s.length():
		var c := s[i]
		#@ Handle string mode:
		if in_string:
			current += c
			if escaped:
				escaped = false
				continue
			if c == "\\":
				escaped = true
				continue
			if c == string_char:
				in_string = false
				string_char = ""
			continue

		#@ Not inside string:
		match c:
			"'", "\"":
				in_string = true
				string_char = c
			"{":
				depth_curly += 1
			"}":
				depth_curly -= 1
			"[":
				depth_square += 1
			"]":
				depth_square -= 1
			",":
				if depth_curly == 0 and depth_square == 0:
					tokens.append(current)
					current = ""
					continue

		current += c

	if current.strip_edges() != "":
		tokens.append(current)

	return tokens

#endregion - candy custom


#?##############################
#& MISC FEATURES:
#?###############
#region
#* Apply BBCode lexicon tags with tooltips, clickable URLs, and custom styling:
func apply_lexicon_tags(text: String, lexicon: Dictionary, chosen_variant: String) -> String:
	var chosen_variant_lc := chosen_variant.to_lower()

	#@ Collect all matching variants:
	var matches: Array = []
	var exact_matches: Array = []

	for variant_key in lexicon.keys():
		var vk = variant_key.to_lower()

		if vk == "*":
			matches.append(variant_key)
		elif vk.ends_with("*"):
			var prefix = vk.substr(0, vk.length() - 1)
			if chosen_variant_lc.begins_with(prefix):
				matches.append(variant_key)
		elif vk == chosen_variant_lc:
			matches.append(variant_key)
			exact_matches.append(variant_key)

	#@ Alphabetical baseline:
	matches.sort()

	#@ Move exact matches to the end (highest priority):
	for ex in exact_matches:
		matches.erase(ex)
		matches.append(ex)

	#@ Map each word to its most specific variant:
	var entry_sources: Dictionary = {}
	for key in matches:
		var block: Dictionary = lexicon[key]
		for w in block.keys():
			entry_sources[w] = key

	#@ Apply entries, using the variant that actually defined each word:
	for word in entry_sources.keys():
		var variant_key: String = entry_sources[word]
		var entry: Dictionary = lexicon[variant_key][word]

		#@ Check if word is in text first (case-sensitive search):
		if text.findn(word) < 0:
			continue

		#@ Display word:
		var display_word = word
		if entry.has("Display"):
			var disp_val := str(entry["Display"]).strip_edges()
			if disp_val != "":
				display_word = disp_val

		#@ Tooltip:
		var tooltip_text := ""
		if entry.has("Tooltip"):
			tooltip_text = str(entry["Tooltip"]).strip_edges()

		#@ Clickable handling:
		var clickable: bool = bool(entry.get("Clickable", false))
		var keyword_click_data = entry.get("Click_Data", null)

		var start_tags := ""
		var end_tags := ""

		#@ URL wrapper:
		if clickable:
			var meta_dict = {
				"keyword": word,
				"keyword_data": keyword_click_data,
				"keyword_variant": variant_key,
			}
			start_tags += "[url=%s]" % JSON.stringify(meta_dict)
			end_tags = "[/url]" + end_tags

		#@ Tooltip wrapper:
		if tooltip_text != "":
			start_tags += "[hint=%s]" % tooltip_text
			end_tags = "[/hint]" + end_tags

		#@ Optional BBCode:
		var bb_l := ""
		var bb_r := ""
		if entry.has("BBCode"):
			var bb_val = entry["BBCode"]
			if typeof(bb_val) == TYPE_ARRAY and bb_val.size() >= 2:
				bb_l = str(bb_val[0])
				bb_r = str(bb_val[1])

		#@ Build replacement:
		var replacement := "%s%s%s%s" % [
			start_tags,
			bb_l,
			display_word,
			bb_r + end_tags
		]

		#@ Whole-word replacement:
		var regex := RegEx.new()
		regex.compile("(?<!\\w)" + word + "(?!\\w)")
		text = regex.sub(text, replacement, true)

	return text


#* Translate a value using a translation table.
#% table_raw can be:
#%   - "" or omitted: defaults to candy_de.display_names
#%   - A variable reference (£, $, vardict): resolved via resolve_value()
#%   - A plain string key: looked up as a property on candy_de
#% Returns the translated string, or new_value unchanged if no translation found.
func translate(new_value: String, table_raw: String = "") -> String:
	var language: String = candy_de.language

	#@ Step 1 - Resolve which dictionary to use:
	var translation_dict: Dictionary

	#% If table_raw is empty, abort:
	if table_raw == "":
		push_error("translate(): table_raw was empty value, cannot translate. Aborting.")
		return new_value

	#% Append £candy_de. if new_value has no variable symbol:
	var ref := table_raw
	if not ref.begins_with(candy_de.singleton_symbol) \
	and not ref.begins_with(candy_de.node_symbol) \
	and not ref.begins_with(candy_de.vardict_symbol):
		ref = candy_de.singleton_symbol + "candy_de." + table_raw

	var resolved = resolve_value(ref)
	if typeof(resolved) == TYPE_DICTIONARY:
		translation_dict = resolved
	else:
		push_error("translate(): could not resolve table to a dictionary: " + table_raw)
		return new_value

	#@ Step 2 - Perform the translation:
	#% If translation found, return translated value:
	if translation_dict.has(new_value) and translation_dict[new_value].has(language):
		return translation_dict[new_value][language]

	#% If no translation exists, return the original value unchanged:
	return new_value

#endregion
#endregion
