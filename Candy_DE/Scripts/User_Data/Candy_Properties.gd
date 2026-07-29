#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends "res://Candy_DE/Scripts/Classes/Candy_User_Data.gd"


#^ Language:
#! The original language is always "Default", whatever language it is.
#? Only translations are named after their language.
#+ If you support several languages, let players change this from an option menu.
var language = "Default"			#/ Root name of the variation to use

#^ Voice Language:
#? The language of voice files, when players can choose it apart from the text's.
#?   "":          the voice follows the text's language.
#?   A language:  voice files are looked up in that language, keeping the variation's tags
#?                (French text, "Japanese" voice: "French_S=F" plays the "Japanese_S=F" file).
#? Each engine's voice_language overrides it, and the Engine_Language command can change that.
#! Once set, the voice no longer follows changes to 'language': set it back to "" for that.
#+ Let players change this from an option menu, if your game is voiced in several languages.
var voice_language = ""

#^ General History:
#? History of every engine.
var general_dialogue_history = []

#^ Data Symbols:
#? Symbols that mark types of data in dialogues. Can be several characters.
#! See the Variables guide to avoid conflicts.
#TODO: Replace with symbols that are quick to type.

#? Marks a CandyRef expression, written like GDScript: "¢globals.hp + 1"
#? Doubled for text starting with it: "¢¢50" displays "¢50".
var candy_ref_symbol = "¢"

#? Shortcut into the variables dictionary (Data_Tables/Variables.gd): "¢€score" reads variables["score"].
var vardict_symbol = "€"

#? Roles (Data_Tables/Roles.gd): "¢°npc1" gives the actor assigned to the role,
#? and "¢°npc1["Age"]" or "¢°npc1.Age" reads a property of that actor.
var role_symbol = "°"

#? Text variables (¤Alice¤) and word substitutions (•word¦Alice•) in spoken lines.
#? Double a symbol to display it: "¤¤" displays "¤", "••" displays "•".
var text_var_start_symbol = "¤"
var text_var_end_symbol = "¤"		#/ Can be identical to text_var_start_symbol
var substitution_start_symbol = "•"
var substitution_end_symbol = "•"	#/ Can be identical to substitution_start_symbol
var separator_symbol = "¦"

#? Text event markers: "Wait‡boom‡... what?" runs the line's "boom" text event when written.
#? Double a symbol to display it: "‡‡" displays "‡", in a variable's value too.
#! Markers are read once text variables and substitutions are resolved: a value can bring markers.
var text_event_start_symbol = "‡"
var text_event_end_symbol = "‡"		#/ Can be identical to text_event_start_symbol

#? Lexicon escapes: "¬Alice¬" displays "Alice", never formatted by the lexicon. The symbols aren't displayed.
#? Double a symbol to display it: "¬¬" displays "¬".
var lexicon_escape_start_symbol = "¬"
var lexicon_escape_end_symbol = "¬"		#/ Can be identical to lexicon_escape_start_symbol

#^ Resource Folders:
#? Resource folders Candy DE uses.
#TODO: Edit to fit your folder structure.
var dialogues_folder = "res://Candy_DE/Dialogues"

var portraits_folder = "res://Candy_DE/Media/Actors/Portraits/"
var busts_folder = "res://Candy_DE/Media/Actors/Busts/"
var sprite_folder = "res://Candy_DE/Media/Actors/Sprites/"
var voice_folder = "res://Candy_DE/Media/Actors/Voices/"

var background_folder = "res://Candy_DE/Media/General/Backgrounds"
var image_folder = "res://Candy_DE/Media/General/Images"
var video_folder = "res://Candy_DE/Media/General/Videos"
var audio_folder = "res://Candy_DE/Media/General/Audio"
var effects_folder = "res://Candy_DE/Media/General/Effects"		#/ AnimationLibraries for Effect_Play go in its "Animation_Libraries" sub-folder

#? A scene named by file name alone ("Shop", "Shop.tscn") is looked up in its folder;
#? a res:// / user:// path is used as-is.
#? Folders no setting reads from (dialogue boxes, bubbles...) are for tools like Candy Dialogue Creator.
var bust_scenes_folder = "res://Candy_DE/Scenes/VN_Scenes"
var bg_scenes_folder = "res://Candy_DE/Scenes/Background_Scenes"

var dialogue_ui_folder = "res://Candy_DE/Scenes/Dialogue_UI"		#/ Whole dialogue UIs, holding the UI elements below
var dialogue_boxes_folder = "res://Candy_DE/Scenes/Dialogue_Boxes"
var subtitles_folder = "res://Candy_DE/Scenes/Subtitles"
var speech_bubbles_2d_folder = "res://Candy_DE/Scenes/Speech_Bubbles_2D"
var speech_bubbles_3d_folder = "res://Candy_DE/Scenes/Speech_Bubbles_3D"
var barks_2d_folder = "res://Candy_DE/Scenes/Barks_2D"
var barks_3d_folder = "res://Candy_DE/Scenes/Barks_3D"
var history_menus_folder = "res://Candy_DE/Scenes/History_Menus"
var image_players_folder = "res://Candy_DE/Scenes/Image_Players"

var chat_boxes_folder = "res://Candy_DE/Scenes/Chat_Boxes"
var chat_channels_folder = "res://Candy_DE/Scenes/Chat_Channels"
var chat_lines_folder = "res://Candy_DE/Scenes/Chat_Lines"		#/ Line_Scene, chat_line_scene and a Chat_Channel's line_scene
var chat_separators_folder = "res://Candy_DE/Scenes/Chat_Separators"		#/ chat_separator_scene and a Chat_Channel's separator_scene

var input_menus_folder = "res://Candy_DE/Scenes/Input_Menus"

var choice_menus_folder = "res://Candy_DE/Scenes/Choice_Menus"
var choice_categories_folder = "res://Candy_DE/Scenes/Choice_Categories"
var choice_buttons_folder = "res://Candy_DE/Scenes/Choice_Buttons"

var testing_scenes_folder = "res://Candy_DE/Scenes/Testing_Scenes"		#/ Scenes for trying dialogues out

var export_folder = "user://Candy_DE/Exports"


#^ Voice Files:
#? How a spoken line's "Voice" file name is found.
#? A full res:// or user:// path is used as-is.
#?
#? voice_logic - the method used to find the file:
#?   "Folder": voice_folder, then voice_path, then a folder named like the variation
#?             (every variation but "Default"), then the file name.
#?
#? voice_path - the folders between voice_folder and the file, built from these tags:
#?   {actor}         the speaker's actor key
#?   {dialogue}      the dialogue file's name, as given to load_scripted_dialogue()
#?   {conversation}  the conversation's name
#?   {block}         the block's name
#?   {line}          the line's number in its block, from 0 (as in Jumps)
#? Tags are optional, in any order, and can share a folder name ("{conversation}_{block}").
#? A tag with no value leaves out its folder.
#/ Example: "{actor}/{dialogue}/{conversation}/{block}" →
#/     res://Candy_DE/Media/Actors/Voices/Alice/Intro/Meeting/Start/French/Default.ogg
#TODO: Edit voice_path to fit your voice file structure.
var voice_logic = "Folder"
var voice_path = "{actor}/{dialogue}/{conversation}/{block}"

#? Language whose voice file plays when a line's is missing (e.g. no French recording yet):
#?   "":          the line is displayed without voice.
#?   A language:  that language's file plays instead, if it exists ("Default" for the original).
#? The variation's tags are kept if that file exists ("French_S=F" → "Default_S=F"), else dropped.
var voice_fallback_language = ""


#^ Default File Extensions:
#? Extension added to media files named without one, by what displays or plays them.
#?
#? Each level overrides the previous:
#?   1. This setting.
#?   2. The same setting on the engine node (empty = use this one).
#?   3. The same setting on the UI element or media player (empty = use the engine's).
#?   4. "extension = <ext>" in the file's folder's config.txt (see Media Folder Settings).
#? An extension written on the line always wins.
#TODO: Edit to match your preferences.
var default_image_extension = ".png"				#/ TextureRect, NinePatchRect, TextureButton, Image players
var default_sprite_extension = ".png"				#/ Sprite2D, Sprite3D (spritesheets)
var default_animated_sprite_extension = ".tres"		#/ AnimatedSprite2D, AnimatedSprite3D (SpriteFrames files)
var default_video_extension = ".ogv"				#/ VideoStreamPlayer, Video players
var default_audio_extension = ".ogg"				#/ Audio players
var default_voice_extension = ".ogg"				#/ Voice files of spoken lines (Voice players)


#^ Default Media FPS:
#? Frame rate of each kind of animated media, in every command (Media_, Effect_, BG_, VN_,
#? CS_Sprite_, CS_Anim_) and in portraits. "f=" frame targets count at it too.
#?
#? Each level overrides the previous:
#?   1. This setting, always above 0.
#?   2. The same setting on the engine node (0 = use this one).
#?   3. The same setting on the UI element or media player (0 = use the engine's).
#?   4. The file's folder's config.txt: the file's "Files" entry, else "fps" (see Media Folder Settings).
#?   5. The media's own rate: "fps = <number>" in a frame folder's config.txt, a video's rate,
#?      a SpriteFrames animation's saved speed.
#?   6. The line's "FPS" key, which always wins - except on SpriteFrames, which keep their speed.
#TODO: Change to suit your needs.
var default_animated_image_fps = 30		#/ Frame folders on TextureRect, NinePatchRect and Image players
var default_sprite_fps = 30				#/ Spritesheets on Sprite2D, Sprite3D
var default_animated_sprite_fps = 30	#/ SpriteFrames animations saved with no speed of their own
var default_video_fps = 30				#/ Videos whose own frame rate can't be read
var default_effect_fps = 30				#/ Effect / CS_Anim: what "f=" counts at when they have no frames


#^ Animation Folders (frame folders):
#? Numbered images in a folder, shown on a TextureRect, NinePatchRect or TextureButton (Image
#? players, background layers, busts, portraits). The first frame loads when the line starts,
#? the rest in the background once it plays.
#? TextureButton: state folders ("pressed", "hover", "disabled", "focused") inside the animation
#? folder hold each state's frames, played in step; a "mask" folder holds its click mask.
#? Each state folder is measured on its own.
#?
#? animation_folder_cache - memory budget of one animation, in MB. One that fits keeps every frame
#?     loaded. One that doesn't is streamed: a few frames ahead, each let go once shown (little
#?     memory, but frames reload on every loop). 0 streams every animation.
#?     Size is estimated uncompressed: width x height x 4 bytes x frames (1920 x 1080: ~8 MB per frame).
#? animation_folder_stream - frames loaded ahead while streaming. More is smoother on slow disks and
#?     large frames, but uses more memory. A frame not loaded in time is skipped, keeping the timing.
#?
#? Each level overrides the previous:
#?   1. This setting.
#?   2. The same setting on the engine node (-1 = use this one).
#?   3. The same setting on the UI element or media player (-1 = use the engine's).
#?   4. "cache = <MB>" / "stream = <frames>" in the parent folder's config.txt, or its "Files" entry.
#TODO: Change to suit your needs.
var animation_folder_cache = 256
var animation_folder_stream = 8


#^ Media Folder Settings (config.txt):
#? Any folder media plays from (a media player's, a background layer's, an actor's busts, portraits,
#? sprites or voices, Sprite_Frames, Animation_Libraries) may hold a "config.txt" of defaults
#? for its files, over the settings above:
#?
#?     extension = png
#?     fps = 12
#?
#?     Files: {
#?     sprite_sheet_4x2-1.png: {fps = 8}
#?     Fire: {fps = 4}
#?     }
#?
#? "extension" - the extension of a file of this folder named without one.
#? "fps"       - the frame rate of the files of this folder.
#? "cache"     - animation folders: animation_folder_cache for the ones in this folder (MB).
#? "stream"    - animation folders: animation_folder_stream for the ones in this folder.
#? "Files"     - one line per file (or animation folder), by name: its "fps", "cache" and "stream"
#?               override the folder's: "Fire: {fps = 4, cache = 0, stream = 12}".
#?               The closing "}" goes on its own line.
#? Every setting is optional, and only read where it applies: audio ignores "fps", and a video
#? or SpriteFrames animation keeps its own frame rate when it has one.
#? Lines starting with "#" are comments. Mistakes are reported with their line.
#?
#? A frame folder's own config.txt sets its frame rate, over its parent folder's. On a TextureButton,
#? it also sets its state folders' "cache" and "stream" ("Files" entries by state: "hover: {cache = 0}").
#+ Add "*.txt" to your export filters (Project > Export > Resources > Filters to export
#+ non-resource files) so exported games can read config.txt.


#^ Public Media Players held by an engine:
#? A Public player is held by the engine that started its playback. These decide whether that
#? engine suspends it with its dialogue and stops it when the dialogue ends (if not, it keeps
#? playing and is let go).
#? Private players are always suspended and stopped by their owner.
#? Overridden by each engine, then each media player.
var suspend_held_media = true
var end_held_media = true


#^ Engine commands:
#? Whether Engine_Language, Dialogue_Mode and Engine_Writing changes are undone when the dialogue
#? ends (if not, they last until changed again).
#? Overridden by each engine, then the line's "Revert" key.
var revert_engine_settings = true


#^ Text events:
#? Lines run at a spoken line's text event markers (see Data Symbols, and "Text events" under
#? Spoken_Line in the command reference).
#?
#? text_event_commands - commands a text event may run. Case-insensitive; "*" at the end covers
#?     every command starting with it ("Media_*"). Others are reported and skipped.
#?     Comment and LM are always allowed.
#! Spoken_Line, Choice_List, Input, transitions, Dialogue_Mode and UI_Clear are left out on
#! purpose: they would display, wait for the player or clear the line being written.
#TODO: Add your own commands if text events should run them.
var text_event_commands = [
	"Set", "Flag", "Call", "Emit", "Await", "Name", "Role", "Disposition", "Export", "Import",
	"If", "Elif", "Else", "For", "While",
	"Wait", "Custom", "Mouse", "UI_Z",
	"Media_*", "Effect_*", "BG_*", "VN_*", "CS_*",
	"Write_Speed", "Write_Pause", "Line_Portrait",
]

#? When a text event runs while the line's voice plays:
#?   text_events_pause_voice:  the voice pauses until the event is over (e.g. a Write_Pause).
#?   text_events_resync_voice: writing synced to the voice (sync_write_speed_voice) is re-synced after
#?                             the event, so the text still ends with the voice. Not under a Write_Speed.
#? Overridden by each engine, then each text event ("Pause_Voice" and "Resync_Voice" keys).
var text_events_pause_voice = false
var text_events_resync_voice = true


#^ While Safety Break:
#? Stops accidental infinite While loops. Negative = disabled.
#TODO: Change to suit your needs.
var while_safety_break = 1000


#^ List of all BBCode tags supported by Godot:
#? Tells BBCode tags from regular text.
#TODO: Add your own custom tags if you have any.

#? Type 1 - Single-word tags (no parameters):
const BBCODE_TAGS_SIMPLE = [
	"b", "i", "u", "s", "code",
	"url", "img",
	"center", "left", "right", "fill", "indent",
	"ul", "ol", "li", "hr", "br", "p",
	"sub", "sup", "lb", "rb",
	"pulse", "wave", "tornado", "shake", "fade", "rainbow"
]

#? Type 2 - Tags followed by '=' syntax:
const BBCODE_TAGS_EQUALS = [
	"color", "bgcolor", "fgcolor",
	"font", "font_size",
	"outline_size", "outline_color",
	"url", "hint", "img",
	"table", "cell", "dropcap",
	"lang", "opentype_features",
	"char"
]

#? Type 3 - tags followed by space-delimited parameters:
const BBCODE_TAGS_SPACE = [
	"pulse", "shake", "wave", "tornado", "fade", "rainbow",
	"font", "img", "table", "cell", "dropcap", "p", "ul", "ol", "hr", "url",
]
