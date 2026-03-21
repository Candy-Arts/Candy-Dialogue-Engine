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


extends "res://Candy_DE/Scripts/Candy_Localizations.gd"


#^ Language:
#! The original language is always named "Default", no matter what language it is.
#? Only translation variants are named after their corresponding language.
#? If you provide multi-language support, let players change this through an option menu.
var language = "Default"		#/ The root name of the variant to use

#^ Data Symbols:
#? Symbols used to help Candy DE identify specific types of data in dialogues.
#? Symbols can be made of multiple characters.
#! Read the Variables guide for the symbol guidelines to avoid conflicts.
#TODO: Replace with symbols suitable for quick writing.
var singleton_symbol = "£"
var node_symbol = "$"
var vardict_symbol = "€"

#? For simplicity, make 'super' symbols double the variable symbols above:
var super_singleton_symbol = "££"
var super_node_symbol = "$$"
var super_vardict_symbol = "€€"

var role_symbol = "°"

var text_var_symbol_start = "{)"
var text_var_symbol_end = "}"
var substitution_symbol = "•"
var separator_symbol = "¦"


#^ Resource Folders:
#? The paths to various resource folders Candy DE uses.
#TODO: Edit folder paths below to fit your own resource folder structure.
var dialogues_folder = "res://Candy_DE/Dialogues"

var portraits_folder = "res://Candy_DE/Media/Characters/Portraits/"
var busts_folder = "res://Candy_DE/Media/Characters/Busts/"
var sprite_folder = "res://Candy_DE/Media/Characters/Sprites/"
var voice_folder = "res://Candy_DE/Media/Characters/Voices/"

var background_folder = "res://Candy_DE/Media/General/Backgrounds"
var image_folder = "res://Candy_DE/Media/General/Images"
var video_folder = "res://Candy_DE/Media/General/Videos"
var audio_folder = "res://Candy_DE/Media/General/Audio"

var bust_scenes_folder = "res://Candy_DE/Scenes/VN Scenes"
var bg_scenes_folder = "res://Candy_DE/Scenes/Background Scenes"

var input_menus_folder = "res://Candy_DE/Scenes/Input Menus"

var choice_menus_folder = "res://Candy_DE/Scenes/Choice Menus"
var choice_categories_folder = "res://Candy_DE/Scenes/Choice Categories"
var choice_buttons_folder = "res://Candy_DE/Scenes/Choice Buttons"

var export_folder = "res://Candy_DE/Exports"


#^ CS Sprite Default FPS:
#? The default FPS value to use for sprites animated with the §CSSprite command.
#? FPS = Frames Per Second, i.e. the animation speed.
var cs_sprite_fps = 30


#^ Default File Extensions:
#? The default extensions used by Candy DE when a media file name with no extension is provided.
#TODO: Edit extensions to match your preferences.
var default_sprite_extension = ".png"				#/ For CS_Sprite
var default_animated_sprite_extension = ".tres"		#/ For CS_Sprite


#^ Animated Image Default FPS:
#? The default FPS value to use for animated images in the §Image command.
#? FPS = Frames Per Second, i.e. the animation speed.
var animated_image_fps = 1


#^ §While Safety Break:
#? Safety feature - prevents accidental infinite loops wit the §While command.
#? Set to a negative value to disable.
#TODO: Change to whatever value suits your needs.
var while_safety_break = 1000


#^ List of all BBCode tags supported by Godot:
#? Used by functions that need to distinguish BBCode tags from regular text.
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
