#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends Node
class_name CandyEngine


#°#########################################################################################
#^
#^										DIALOGUES
#^
#°#########################################################################################
#region

#& Loaded Dialogues
#^ Running Dialogues:
#? The dialogue this engine runs.
#? Fill by hand, with load_scripted_dialogue(), or from code.
var running_dialogue = {}

#^ Running Dialogue File:
#? Source file name, e.g. "Intro". Fills voice_path's {dialogue} tag.
#? Set it when filling running_dialogue yourself.
var running_dialogue_file := ""

#endregion


#°#########################################################################################
#^
#^										 SETTINGS
#^
#°#########################################################################################
#region

#? Configure for your project. See the documentation.
#? TIP: Settings can change at runtime (game code, Engine commands, "Set").

@export_group("Identity")
## An arbitrary value, that can be used to indicate the purpose of an engine instance when needed.[br][br]
## Used only in change_game_state(), can also be used in your own custom code.[br][br]
## "UI" is assigned to Candy UI by default. For future-proofing purposes, we recommend not assigning "UI" to any other instances.[br][br]
## "Barks" is assigned to NPC bark engine instances. You can assign that value to custom instances also used for NPC barks.
@export var engine_mode: String = ""


@export_group("Dialogue Display")
#& DIALOGUE DISPLAY
#? Overridden by the UI element, the actor, then the line (see Classes/Candy_Settings.gd).
## The language to use for this engine instance.[br][br]
## Overrides 'language' in Candy_Properties.gd
@export var engine_language: String = ""
## The language of this engine instance's voice files, when it differs from the text's.[br][br]
## Empty: 'voice_language' in Candy_Properties.gd, else the text's language.
@export var voice_language: String = ""

#^ Dialogue mode:
#? Each mode displays through a node's display(): its UI element or the speaker's bubble.
## How the dialogue is displayed on screen.[br]
## "Box": Classic RPG box, one line displayed at a time.[br]
## "Bubbles": Comic book style speech bubbles above characters.[br]
## "Subtitles": Wide and thin area of text at the bottom of the screen.[br]
## "Chat": Chatbox style dialogue display, with vertically stacked lines.[br]
## "Voice": Voice playback only, no text, speaker labels, or portraits.[br][br]
## Every script in the Dialogue_Modes folder is a mode, named like its file: add one to make a mode of your own.
## Dialogue Mode to use.[br]
## Note: 'Bubbles' defaults to 'VN_Bubbles' automatically when VN Mode is enabled.
@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, "Box,Subtitles,Chat,Bubbles,VN_Bubbles,Barks,Voice") var dialogue_mode: String = "Box"


#& ACTOR DISPLAY
#^ Portrait display:
## Whether to display speaker portraits.[br]
## Typically disabled when character meshes, sprites or VN busts convey expressions.[br]
## "Off": Don't display any portraits ever.[br]
## "All": Display portraits for all characters.[br]
## "Player": Display only a portrait for the player (identified with the player_refs table).[br]
## "NPC": Never display a portrait for the player.[br]
## "VN": Don't display portraits if the speaker has a VN bust node assigned.
enum PortraitModes {Off, All, Player, NPC, VN}
@export_group("Box Mode")
## Portraits in the dialogue box.
@export var box_portrait_mode: PortraitModes = PortraitModes.All
@export_group("Chat Mode")
## Portraits in chat lines.
@export var chat_portrait_mode: PortraitModes = PortraitModes.All

#& VOICED DIALOGUES
@export_group("Voice")
#^ Allow voice:
## Enable voice playback for spoken lines.
@export var enable_voice: bool = true

#^ Default voice file extension:
## Extension given to voice files named without one.[br][br]
## Leave empty to use the same setting in Candy_Properties.gd. The own setting of the voice
## player speaking the line (a UI element's or bubble's voice_node, or the standalone Voice
## player) overrides this.
@export var default_voice_extension: String = ""


#& TEXT-TO-SPEECH (TTS)
#^ TTS mode:
#+ Advanced variation: displayed name + "_TTS", e.g. "English_TTS".
## Use Text-To-Speech.[br]
## "Off": no TTS.[br]
## "Simple": TTS reads the spoken line.[br]
## "Advanced": TTS reads a special variation, with formatting to aid pronunciation and tone.[br][br]
## Any other name is a TTS mode of your own, handled in the tts() hook (Tts.gd).
@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, "Off,Simple,Advanced") var text_to_speech: String = "Off"

#^ TTS fallback:
## TTS mode to use if no "Advanced" line variation exists.[br]
## Can be set to "Off" or "Simple", or to your own custom TTS mode if you made any.
@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, "Off,Simple") var tts_advanced_fallback: String = "Simple"


#& TEXT STYLE
#^ BBCode wraps:
## BBCode tags wrapped around spoken text and speaker names, e.g. "[color=#ff8080][i]".[br]
## Write only the opening tags: Candy DE adds the closing ones. Empty = no wrap.[br][br]
## Overridden by the UI element's wraps, then the speaking actor's, then the line's.
@export_group("Box Mode")
@export var box_text_bbcode: String = ""			#/ Spoken text in the dialogue box
@export var box_speaker_bbcode: String = ""			#/ Speaker name in the dialogue box

@export_group("Subtitles Mode")
@export var subtitles_text_bbcode: String = ""		#/ Spoken text in subtitles mode
@export var subtitles_speaker_bbcode: String = ""	#/ Speaker name in subtitles mode

@export_group("Chat Mode")
@export var chat_text_bbcode: String = ""			#/ Spoken text in the chat box
@export var chat_speaker_bbcode: String = ""		#/ Speaker name in the chat box

@export_group("Speech Bubbles")
@export var bubbles_text_bbcode: String = ""		#/ Spoken text in bubbles

@export_group("Barks")
@export var barks_text_bbcode: String = ""			#/ Spoken text in barks


#^ Speaker name in spoken text:
## Options for displaying speaker name inside spoken text strings.
@export_group("Box Mode")
## Enable speaker in text for "Box" dialogue mode.[br]
## Independent of the dialogue box's own name label (speaker_node), if it has one.
@export var box_show_speaker: bool = false
## Character string to add before speaker name.
@export var box_speaker_prefix: String = ""
## Character string to add after speaker name.
@export var box_speaker_suffix: String = ":"

@export_group("Subtitles Mode")
## Enable speaker in text for "Subtitles" dialogue mode.
@export var subtitles_show_speaker: bool = true
## Character string to add before speaker name.
@export var subtitles_speaker_prefix: String = "("
## Character string to add after speaker name.
@export var subtitles_speaker_suffix: String = ")"

@export_group("Chat Mode")
## Enable speaker in text for "Chat" dialogue mode.
@export var chat_show_speaker: bool = false
## Character string to add before speaker name.
@export var chat_speaker_prefix: String = ""
## Character string to add after speaker name.
@export var chat_speaker_suffix: String = ":"


#& END OF LINE STRING:
#^ End of line character/string:
#? Shown at the end of spoken lines (e.g. a blinking arrow). BBCode if supported. Empty = off.
@export_group("Box Mode")
## Custom string to display at the end of a line in "Box" dialogue mode, [b]before[/b] dialogue advances.[br][br]
## Supports BBCode.
@export var box_end_of_line_string: String = "[pulse freq=1.5 color=black ease=-5.0] ▼[/pulse]"		#/ Dialogue box
## Custom string to display at the end of a line in "Box" dialogue mode, [b]after[/b] dialogue advances.[br][br]
## Leave empty to hide the end_of_line_string, or replace it with something that indicates dialogue has
##  already advanced and the line is not waiting for further input.[br][br]
## Supports BBCode.
@export var box_advance_string: String = " ▼"

@export_group("Speech Bubbles")
## Custom string to display at the end of a line in "Bubbles" dialogue mode, [b]before[/b] dialogue advances.[br]
## Supports BBCode.
@export var bubbles_end_of_line_string: String = ""													#/ Speech Bubbles
## Custom string to display at the end of a line in "Bubbles" dialogue mode, [b]after[/b] dialogue advances.[br][br]
## Leave empty to hide the end_of_line_string, or replace it with something that indicates dialogue has
##  already advanced and the line is not waiting for further input.[br][br]
## Supports BBCode.
@export var bubbles_advance_string: String = ""

@export_group("Subtitles Mode")
## Custom string to display at the end of a line in "Subtitles" dialogue mode, [b]before[/b] dialogue advances.[br][br]
## Supports BBCode.
@export var subtitles_end_of_line_string: String = ""												#/ Subtitles
## Custom string to display at the end of a line in "Subtitles" dialogue mode, [b]after[/b] dialogue advances.[br][br]
## Leave empty to hide the end_of_line_string, or replace it with something that indicates dialogue has
##  already advanced and the line is not waiting for further input.[br][br]
## Supports BBCode.
@export var subtitles_advance_string: String = ""

@export_group("Chat Mode")
## Custom string to display at the end of a line in "Chat" dialogue mode, [b]before[/b] dialogue advances.[br][br]
## Supports BBCode.
@export var chat_end_of_line_string: String = ""													#/ Chat Box
## Custom string to display at the end of a line in "Chat" dialogue mode, [b]after[/b] dialogue advances.[br][br]
## Leave empty to hide the end_of_line_string, or replace it with something that indicates dialogue has
##  already advanced and the line is not waiting for further input.[br][br]
## Supports BBCode.
@export var chat_advance_string: String = ""

@export_group("Barks")
## Custom string to display at the end of a line in "Barks" dialogue mode, [b]before[/b] dialogue advances.[br][br]
## Supports BBCode.
@export var barks_end_of_line_string: String = ""													#/ Barks
## Custom string to display at the end of a line in "Barks" dialogue mode, [b]after[/b] dialogue advances.[br][br]
## Leave empty to hide the end_of_line_string, or replace it with something that indicates dialogue has
##  already advanced and the line is not waiting for further input.[br][br]
## Supports BBCode.
@export var barks_advance_string: String = ""

#& DIALOGUE UI SELF CLEAR:
@export_group("Box Mode")
## Calls the clear() function on the Dialogue Box node when dialogue advances to the next line.[br]
## By default: clears text and hides the Dialogue Box node.
@export var box_self_clear: bool = false
## Calls the clear() function on the Portrait node when dialogue advances to the next line.[br]
## By default: clears portrait and hides the Portrait node.
@export var box_portrait_self_clear: bool = false

@export_group("Subtitles Mode")
## Calls the clear() function on the Subtitle node when dialogue advances to the next line.[br]
## By default: clears text and hides the Subtitle node.
@export var subtitles_self_clear: bool = true


#& CHAT MODE:
#^ Persistent chat:
## Keep chatbox visible even if the dialogue mode changes between spoken lines.
@export_group("Chat Mode")
@export var persistent_chat: bool = true

#^ Clear chatbox:
## Clear chatbox contents when dialogue ends.
@export var chat_clear_on_end: bool = true

#^ Hide chatbox:
## Hide chatbox when dialogue ends.
@export var chat_hide_on_end: bool = true

#^ Clear chatbox when dialogue starts:
## Clear the chat's lines when a dialogue starts.[br]
## When lines are kept (here or at the end), a separator goes between two dialogues' lines.
@export var chat_clear_on_start: bool = false

#^ Chat scenes:
## The scene each chat line is displayed in (a Chat_Line): a path, or a file name in
## chat_lines_folder (Candy_Properties.gd).[br]
## Overridden by the Chat_Channel, the speaking actor and the line.
@export_file("*.tscn") var chat_line_scene: String = "res://Candy_DE/Scenes/Chat_Lines/Default.tscn"
## The scene placed between two dialogues' lines, when they aren't cleared (a Chat_Separator):
## a path, or a file name in chat_separators_folder (Candy_Properties.gd).[br]
## Overridden by the Chat_Channel.
@export_file("*.tscn") var chat_separator_scene: String = "res://Candy_DE/Scenes/Chat_Separators/Default.tscn"

#^ Chat line layout:
#? Which side each line's portrait and name use, and when they show.
## When a line shows the speaker's name label.[br]
## "Every_Line": on every line.[br]
## "Speaker_Change": only on the first of several lines in a row from the same speaker.
enum SpeakerDisplays {Every_Line, Speaker_Change}
@export var chat_speaker_display: SpeakerDisplays = SpeakerDisplays.Speaker_Change
## When a line shows the speaker's portrait (if chat_portrait_mode allows one at all).[br]
## "Every_Line": on every line.[br]
## "Speaker_Change": only on the first of several lines in a row from the same speaker.[br]
## "Speaker_Or_Portrait_Change": also when the same speaker's portrait changes.
enum PortraitDisplays {Every_Line, Speaker_Change, Speaker_Or_Portrait_Change}
@export var chat_portrait_display: PortraitDisplays = PortraitDisplays.Speaker_Or_Portrait_Change
## Which side of the text a line's portrait and name are on; the text aligns to the same side.[br]
## "Left" / "Right": always that side.[br]
## "Alternate": the side opposite the previous line's when the speaker changes, the same side
## while the same speaker continues. A dialogue's first line starts on the left.
enum Alignments {Left, Right, Alternate}
@export var chat_alignment: Alignments = Alignments.Left
## Keep the space of a portrait that isn't shown on this line, so texts line up.
@export var chat_keep_portrait_space: bool = true
## Keep the space of a name label that isn't shown on this line.
@export var chat_keep_speaker_space: bool = false
## Keep the space of the portrait on the other side of the text.
@export var chat_keep_alternate_portrait_space: bool = false
## Keep the space of the name label on the other side of the text.
@export var chat_keep_alternate_speaker_space: bool = false


#& BUBBLES MODE:
#^ Bubble alt mode:
@export_group("Speech Bubbles")
## Dialogue mode to use when the speaker has no speech bubble, or isn't present on screen.
@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, "Box,Subtitles,Chat,Bubbles,VN_Bubbles,Barks,Voice") var bubbles_exempt_mode: String = "Box"


#& WRITING:
@export_group("Writing")
#^ Writing speed:
## Typewriter effect speed.[br][br]
## Set to 0 to disable.
@export var writing_speed: int = 30

#^ Manual speed:
## Typewriter speed when input_speed_dialogue is pressed.
@export var continue_fast_speed: int = 60
## Typewriter speed when input_slow_dialogue is pressed.
@export var continue_slow_speed: int = 15

#^ Auto-advance:
## Time (in seconds) to wait before automatically advancing to the next line.[br]
## -1 to disable (manual advance only).
@export var auto_advance: float = -1.0
## Seconds added to auto_advance for each character the line shows.[br]
## E.g. auto_advance 2 and 0.05 here: a 100-character line waits 2 + 5 seconds.[br]
## Ignored when auto_advance is -1.
@export var auto_advance_per_character: float = 0.0

#^ Synchronize writing speed to voice:
## Synchronize typewriter speed to match voice playback duration.[br]
## Synchronization will break if player speeds, slows or skips the typewriter effect.
@export var sync_write_speed_voice: bool = false

#^ Wait on voice playback:
## Prevent manual and auto advance until voice playback has finished.
@export var await_voice_playback: bool = false


#& CHOICES
@export_group("Choice Menus")
#^ Hide choice lists by default:
## If false, nested choice menus never hide older menus automatically.
@export var hide_choice_lists: bool = true


#& VN MODE
#^ VN Mode enable:
@export_group("Visual Novel Mode")
## Enable VN mode.
@export var vn_mode: bool = true

#^ Persistent busts:
## Keep VN busts on screen when dialogue ends.
@export var persistent_busts_on_end: bool = false

#^ Join/Move/Leave effects:
## Default JML effect when an actor joins (VN_Play command).
@export var vn_join_effect: Array[String] = ["", ""]
## Default JML effect when an actor moves from a bust node (VN_Move command).
@export var vn_move_from_effect: Array[String] = ["", ""]
## Default JML effect when an actor moves to a bust node (VN_Move command).
@export var vn_move_to_effect: Array[String] = ["", ""]
## Default JML effect when an actor leaves (VN_Remove command).
@export var vn_leave_effect: Array[String] = ["", ""]

## Whether to play each actor's Leave effect when busts are cleared at the end of dialogue.[br][br]
## true = play effect[br]
## false = don't play
@export var jml_on_end: bool = true


#& BACKGROUNDS
#^ Persistent backgrounds:
@export_group("Backgrounds")
## Keep Backgrounds on screen when dialogue ends.
@export var persistent_bg_on_end: bool = true


#& LEXICON
#^ Lexicon:
@export_group("Lexicon")
## Enable Lexicon in "Box" dialogue mode.
@export var lexicon_box_mode: bool = true
## Enable Lexicon in "Bubbles" dialogue mode.
@export var lexicon_bubbles_mode: bool = true
## Enable Lexicon in "Subtitles" dialogue mode.
@export var lexicon_subtitles_mode: bool = true
## Enable Lexicon in "Chat" dialogue mode.
@export var lexicon_chat_mode: bool = true
## Enable Lexicon in "Barks" dialogue mode.
@export var lexicon_barks_mode: bool = true
## Enable Lexicon in "Voice" dialogue mode.[br][br]
## For use with TTS Simple mode:[br]
## "Voice" mode doesn't display text. Enabling this ensures that Lexicon keywords
## get replaced with their "Display" value before the line is read by TTS.
@export var lexicon_voice_mode: bool = true


#& MEDIA
@export_group("Media")
#^ Default file extensions for this engine instance:
#? Engine level of each extension chain. An extension on the line always wins.
## Extension given to image files named without one (TextureRect, NinePatchRect,
## TextureButton, Image players).[br][br]
## Leave empty to use the same setting in Candy_Properties.gd. The UI element's or media
## player's own setting overrides this.
@export var default_image_extension: String = ""
## Extension given to spritesheet files named without one (Sprite2D, Sprite3D).[br][br]
## Leave empty to use the same setting in Candy_Properties.gd. The UI element's own
## setting overrides this.
@export var default_sprite_extension: String = ""
## Extension given to SpriteFrames files named without one (AnimatedSprite2D,
## AnimatedSprite3D).[br][br]
## Leave empty to use the same setting in Candy_Properties.gd. The UI element's own
## setting overrides this.
@export var default_animated_sprite_extension: String = ""
## Extension given to video files named without one (VideoStreamPlayer, Video players).[br][br]
## Leave empty to use the same setting in Candy_Properties.gd. The UI element's or media
## player's own setting overrides this.
@export var default_video_extension: String = ""
## Extension given to audio files named without one (Audio players).[br][br]
## Leave empty to use the same setting in Candy_Properties.gd. The media player's own
## setting overrides this.
@export var default_audio_extension: String = ""

#^ Default frame rates for this engine instance:
## Frame rate for frame-folder animations on image nodes and Image players.[br][br]
## Leave at 0 to use the same setting in Candy_Properties.gd.
@export var default_animated_image_fps: float = 0.0
## Frame rate for spritesheets on Sprite2D and Sprite3D nodes.[br][br]
## Leave at 0 to use the same setting in Candy_Properties.gd.
@export var default_sprite_fps: float = 0.0
## Frame rate for SpriteFrames animations saved with no speed of their own
## (AnimatedSprite2D, AnimatedSprite3D).[br][br]
## Leave at 0 to use the same setting in Candy_Properties.gd.
@export var default_animated_sprite_fps: float = 0.0
## Frame rate for videos whose own frame rate can't be read.[br][br]
## Leave at 0 to use the same setting in Candy_Properties.gd.
@export var default_video_fps: float = 0.0
## Frame rate "f=" targets count at on effect and cutscene animations that have no frames
## of their own to count.[br][br]
## Leave at 0 to use the same setting in Candy_Properties.gd.
@export var default_effect_fps: float = 0.0

#^ Animation folders for this engine instance (see Candy_Properties.gd):
## Memory budget of one animation folder, in MB: one whose frames fit in it keeps every frame
## loaded while it plays, one that doesn't is streamed. 0 streams every animation.[br][br]
## Leave at -1 to use the same setting in Candy_Properties.gd. The UI element's or media
## player's own setting, and a config.txt ("cache"), override this.
@export var animation_folder_cache: int = -1
## While an animation folder is streamed, how many frames are loaded ahead.[br][br]
## Leave at -1 to use the same setting in Candy_Properties.gd. The UI element's or media
## player's own setting, and a config.txt ("stream"), override this.
@export var animation_folder_stream: int = -1

#^ Count lines skipped by dispositions towards Media_Pause commands:
## Count skipped lines towards Media_Pause decrementation.[br][br]
## When a disposition check fails, the line is skipped.
## This option determines if skipped lines should still decrement the line count for Media_Pause commands.[br][br]
## 'true' will ensure consistent line count whether dispositions fail or pass.[br]
## 'false' will make media resume based on the number of lines that actually displayed on screen.[br][br]
## Tip: for more fine-tuned behavior, consider using a variable reference for line count inside Media_Pause commands.
@export var mp_count_dispositions: bool = false
#^ Count lines skipped by variations towards Media_Pause commands:
## Count skipped lines towards Media_Pause decrementation.[br][br]
## If no suitable variation is found for a line, the line is skipped.
## This option determines if skipped lines should still decrement the line count for Media_Pause commands.[br][br]
## 'true' will ensure consistent line count across languages and variation tags.[br]
## 'false' will make media resume based on the number of lines that actually displayed on screen.[br][br]
## Tip: for more fine-tuned behavior, consider using a variable reference for line count inside Media_Pause commands.
@export var mp_count_variations: bool = false

#& HISTORY LOG
#^ History log:
@export_group("History")
## Log dialogue history.[br]
## Enable recommended, even if you don't expect to use the log.
@export var write_dialogue_history: bool = true


#& LLM (AI-GENERATED SPEECH)
#^ LLM query:
@export_group("LLM Speech")
## Enable LLM mode.
@export var llm_mode: bool = false


#& MOUSE MODE
#^ Mouse mode variables:
@export_group("Mouse Mode")
enum MouseModes {None = -1, Visible, Hidden, Captured, Confined, Confined_Hidden}
## Set Mouse Mode when dialogue starts.[br]
## Set to "NONE" to disable.
@export var mouse_mode_start: MouseModes = MouseModes.None
## Set Mouse Mode when dialogue ends.[br]
## Set to "NONE" to disable.
@export var mouse_mode_end: MouseModes = MouseModes.None
## Default Mouse Mode for Choice_List commands.
## Set to "NONE" to disable.
@export var mouse_mode_choice: MouseModes = MouseModes.None


#& VARIATIONS
#^ Automatic Variation Selection:
@export_group("Variations")
## Use random variations.
@export var random_variations: bool = true
## Custom variation tags for player attributes.[br][br]
## Attribute values are read from the actors dictionary and based on current_player in User_Data/Data_Tables/Player_Refs.gd.[br][br]
## For tags your own code decides, add a script to Scripts/Variation_Tags instead (see CandyVariationTag).[br][br]
## DO NOT use spaces, underscores '_' or '=' inside tags![br]
## DO NOT name tags in player_tags the same as tags in speaker_tags!
@export var player_tags: Dictionary[String, String] = {
	"P": "Gender"
}
## Custom variation tags for speaker attributes.[br][br]
## Attribute values are read from the actors dictionary.[br][br]
## For tags your own code decides, add a script to Scripts/Variation_Tags instead (see CandyVariationTag).[br][br]
## DO NOT use spaces, underscores '_' or '=' inside tags![br]
## DO NOT name tags in speaker_tags the same as tags in player_tags!
@export var speaker_tags: Dictionary[String, String] = {
	"S": "Gender",
}
## Tags that automatically pass regardless of their value.
## These tags will never prevent a variation from being selected.[br][br]
## A bare tag (no value, e.g. "Shout" in "Default_Shout") only passes when it is listed here,
## or in the speaking actor's or the line's passed tags.[br][br]
## Applies to Variation_Tags scripts too: their script isn't run.[br][br]
## Overridden by the speaking actor's PassedTags / DisabledTags, then the line's Passed_Tags / Disabled_Tags.
@export var passed_tags: Array[String] = []
## Disabled tags.[br]
## Variations that feature any of these tags will never be selected.[br][br]
## Applies to Variation_Tags scripts too: their script isn't run.[br][br]
## Overridden by the speaking actor's PassedTags / DisabledTags, then the line's Passed_Tags / Disabled_Tags.
@export var disabled_tags: Array[String] = []


#& DIALOGUE SUSPEND
@export_group("Suspend Dialogue")
#^ Suspend dialogue:
#? Set by suspend_dialogue() / resume_dialogue().
var dialogue_suspended: bool = false

#^ Suspend dialogue elements:
## Suspend portrait animations.
@export var suspend_portraits: bool = true
## Suspend voice playback for spoken lines.
@export var suspend_voice: bool = true

## Suspend background animations and effects.
@export var suspend_backgrounds: bool = true
## Suspend background animations.
@export var suspend_bg_animations: bool = true
## Suspend background effects.
@export var suspend_bg_effects: bool = true

## Suspend VN bust animations and effects.
@export var suspend_vn_busts: bool = true
## Suspend VN bust animations
@export var suspend_bust_animations: bool = true
## Suspend VN bust effects
@export var suspend_bust_effects: bool = true

## Suspend all media (Media_ and Effect commands).[br][br]
## Only the media players this engine sent a command to are suspended: players started
## by your own game code, or last commanded by another engine, are left alone.
@export var suspend_media: bool = true
## Suspend audio players (Media_ commands).
@export var suspend_audio: bool = true
## Suspend video players (Media_ commands).
@export var suspend_video: bool = true
## Suspend image players (Media_ commands).
@export var suspend_images: bool = true
## Suspend visual effects (Effect command).
@export var suspend_animations: bool = true

## Media players exempt from being suspended.[br]
## Add their key from media_players_paths in the array -- e.g. "Music"[br][br]
## "Voice" exempts the voice of spoken lines, whichever player speaks it (as suspend_voice off does).
@export var media_suspend_immune: Array[String] = []	#/ e.g. ["Ambient", "Music"]

## Let this engine override whether it suspends the Public media players it holds.[br][br]
## Overrides Candy_Properties.gd; each player can override this in turn.[br]
## The Private players this engine owns are always suspended with its dialogue.
@export var enable_suspend_held_media: bool = false
## Whether this engine suspends the Public media players it holds along with its dialogue.
@export var suspend_held_media: bool = true
## Let this engine override whether it stops the Public media players it holds when its dialogue ends.[br][br]
## Overrides Candy_Properties.gd; each player can override this in turn.[br]
## The Private players this engine owns are always stopped when its dialogue ends.
@export var enable_end_held_media: bool = false
## Whether this engine stops the Public media players it holds when its dialogue ends.
## If not, they keep playing and this engine lets go of them.
@export var end_held_media: bool = true


#& ENGINE COMMANDS
@export_group("Engine Commands")
## Let this engine override whether the Engine commands' changes are reverted when its dialogue ends.[br][br]
## Overrides Candy_Properties.gd; each command line can override this in turn, with its "Revert" key.
@export var enable_revert_engine_settings: bool = false
## Whether the settings changed by Engine_Language, Dialogue_Mode and Engine_Writing go back to
## their earlier value when the dialogue ends, so the next dialogue starts with this engine's own settings.
@export var revert_engine_settings: bool = true


#& TEXT EVENTS
@export_group("Text Events")
## Let this engine override whether the voice pauses while a text event runs.[br][br]
## Overrides Candy_Properties.gd; each text event can override this in turn, with its "Pause_Voice" key.
@export var enable_text_events_pause_voice: bool = false
## Whether a spoken line's voice pauses until each of its text events is over.
@export var text_events_pause_voice: bool = false
## Let this engine override whether writing synced to the voice is synced again after a text event.[br][br]
## Overrides Candy_Properties.gd; each text event can override this in turn, with its "Resync_Voice" key.
@export var enable_text_events_resync_voice: bool = false
## In a line whose writing speed is synced to its voice (sync_write_speed_voice), work the speed
## out again after each text event, so the text still ends with the voice.[br]
## Not while a Write_Speed is in effect.
@export var text_events_resync_voice: bool = false


#& INPUT
@export_group("Input")
## Enable or disable input.
## Determines if this dialogue engine instance reacts to the inputs above.[br]
## Does not affect dialogue suspension inputs, as these are handled by your own code, unless your code is designed to read this variable.
@export var input_enabled: bool = true

## Name of the input for manually advancing to the next line (Spoken_Lines)
@export var input_advance_dialogue: String = "Dialogue_Advance"
## Name of the input for speeding up the typewriter.
@export var input_speed_dialogue: String = "Dialogue_Speed"
## Name of the input for slowing down the typewriter.
@export var input_slow_dialogue: String = "Dialogue_Slow"
## Name of the input for skipping the typewriter (instant text display).
@export var input_skip_dialogue: String = "Dialogue_Skip"
## Name of the input for manually advancing to the next line (Player_Advance command)
@export var input_player_advance: String = "Dialogue_Advance"

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
## Paths to dialogue UI elements.[br][br]
## Edit paths or remove keys to match your dialogue UI scene;[br]
## Add keys/UI Elements as needed for your custom commands or custom dialogue modes.[br]
## NOTE: Media and effect players are added to media_players_paths.[br][br]
## Each entry is a path, which makes this engine the element's owner, or [code][path, false][/code],
## which only gives the element a name here. Ownership matters for elements with an Access
## setting (the background scene): an owned element set to Private obeys this engine alone,
## and is always suspended and cleared with its dialogue. An element must not be owned by two engines.
@export var ui_elements_paths: Dictionary[String, Variant] = {
	"backgrounds_path":		"BG_Layer/Backgrounds",
	"busts_path":			"VN_Layer/Busts",
	"dialogue_box_path":	"UI_Layer/DialogueBox",
	"subtitles_path":		"UI_Layer/Subtitles",
	"chat_path":			"UI_Layer/ChatBox/Channel",
	"history_display_path":	"UI_Layer/History",
	"choices_path":			"UI_Layer/Choices",
	"input_node_path":		"UI_Layer/Input",
	"barks_path":			"BarkBubble",
	"voice_player_path":	"VoicePlayer"		#/ Standalone voice player ("Voice" mode)
}

#^ Media Player paths:
#TODO: Edit paths and add media player path keys as needed.
## Names for the media and effect players dialogue commands refer to, and their paths.[br]
## Edit paths or remove keys to match your dialogue UI scene, or add keys for your custom media/effect players.[br][br]
## Each entry is a path, which makes this engine the player's owner, or [code][path, false][/code],
## which only gives the player a name here. An owned player set to Private obeys this engine
## alone, and is always suspended and stopped with its dialogue. A player must not be owned
## by two engines.[br][br]
## NOTE: The voice player of the "Voice" dialogue mode is a UI element (ui_elements_paths["voice_player_path"]).
@export var media_players_paths: Dictionary[String, Variant] = {
	"Effect":	"UI_Layer/MediaPlayers/EffectPlayer",					#/ AnimationPlayer for UI effects
	"Image":	"UI_Layer/MediaPlayers/ImagePlayer",
	"Splash":	"UI_Layer/MediaPlayers/SplashPlayer",
	"Video":	"UI_Layer/MediaPlayers/VideoPlayer",
	"Sound":	"UI_Layer/MediaPlayers/SoundPlayer",
	"Ambient":	"UI_Layer/MediaPlayers/AmbientPlayer",
	"Music":	"UI_Layer/MediaPlayers/MusicPlayer",
	"Speech":	"UI_Layer/MediaPlayers/SpeechPlayer",					#/ Speech outside Spoken_Lines (Media_Play)
}


#^ Actor paths:
#? Update from game code if actor nodes move.
## Paths to NPC nodes for "Bubbles" dialogue mode.
@export var bubbles_npc_path: String = "/root/Game/NPC"
## Paths to player nodes for "Bubbles" dialogue mode.
@export var bubbles_player_path: String = "/root/Game/Player"


#^ Cutscene Commands paths:
#TODO: Edit paths to fit your game structure, add path keys as needed.
## Paths to nodes used by Cutscene (CS_) commands:
@export var cs_paths: Dictionary[String, String] = {
		"Player":	"/root/Game/Player",
		"Actors":	"/root/Game/Actors",
		"Vehicles":	"/root/Game/Vehicles",
		"Objects":	"/root/Game/Objects",
		"Cameras":	"/root/Game/Cameras",
		"Markers":	"/root/Game/Pins",
		"WP":		"/root/Game/Waypoints",
		"Lights":	"/root/Game/Lights",
}

#endregion


#°#########################################################################################
#^
#^										  DEBUG
#^
#°#########################################################################################
#region
@export_group("DEBUG")
## Enable debug prints during development.[br][br]
## These prints won't occur once your project is compiled.
@export var debug_prints: bool = true

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
#? True while start_dialogue() awaits change_game_state().
var dialogue_starting := false

#^ Language to use:
var use_language = ""

#^ Settings changed by Engine commands:
var default_settings: Dictionary = {}		#/ Every exported setting's value when the engine became ready, for "Reset"
var settings_to_revert: Dictionary = {}		#/ Setting name → the value to put back when the dialogue ends

#^ Progress trackers:
var conversation_tracker = ""
var block_tracker = ""
var line_tracker = ""
var line_data_tracker = {}
var resolved_disp_tracker = ""

var prev_conversation_tracker = ""
var prev_block_tracker = ""
var prev_line_tracker = ""
var prev_line_data_tracker = {}
var prev_resolved_disp_tracker = ""

#^ Command scripts:
#? Script registries are keyed by lowercase file name.
var command_registry: Dictionary = {}
var registries_built := false

#^ Input event scripts:
var input_event_registry: Dictionary = {}

#^ Choice event scripts:
var choice_event_registry: Dictionary = {}

#^ Await event scripts, by signal name:
var await_event_registry: Dictionary = {}

#^ Custom event scripts, by "Command" value:
var custom_event_registry: Dictionary = {}

#^ Move event scripts, by "Movement" value:
var move_event_registry: Dictionary = {}

#^ Variation tag scripts, by tag:
var variation_tag_registry: Dictionary = {}

#^ Dialogue mode scripts, by mode:
var dialogue_mode_registry: Dictionary = {}

#^ CandyRef:
var candy_ref: CandyRef = null

#^ Symbol for empty values:
var empty_symbol = "_"

#^ Last dialogue mode used:
var previous_mode = ""

#^ Last speaker:
var previous_speaker = ""

#^ Awaiting player input:
var waiting_for_input

#^ Dialogue suspension tracking:
#? Choice timers paused by suspension:
var suspended_choice_timers: Array[Timer] = []

#? Keeps media paused while an ending dialogue leaves suspension.
var _keep_media_suspended: bool = false
var suspended_voice: bool = false		#/ Voice paused by the current suspension
var suspended_portrait_nodes = []
var suspended_portrait_animplayers = []
#^ UI elements whose portraits suspension pauses:
const PORTRAIT_ELEMENTS: Array[String] = ["dialogue_box_path", "chat_path"]

#? Private media players this engine owns:
var owned_media_players: Array = []

#? Public media players this engine holds:
var held_media_players: Array = []

#? Private UI elements this engine owns:
var owned_ui_elements: Array = []

#? Public UI elements this engine holds:
var held_ui_elements: Array = []

#? Media players counting down Media_Pause "Lines":
var line_paused_media_players: Array = []

#? Voice player speaking the current line:
var active_voice_player: Node = null

#? Progressive Volume fades:
var active_volume_tweens: Array = []

signal dialogue_resumed

#^ History storage:
var dialogue_history = []


#^ Return:
#? Blocks remaining to return from.
#? 0 = not returning ; -1 = unlimited (unwind to main).
var return_levels: int = 0
#? Return overshooting main: true = end dialogue; false = stop at main.
var return_end_on_overshoot: bool = false

#^ Killswitch:
var killswitch = false
signal killswitch_off
signal killswitch_raised		#/ Wakes commands parked on their own signal (Await)

var greenlight = true

var skip_wait = false				#/ Set Wait timers to 0

#^ Text events:
#? Line whose text event is running, else null:
var text_event_speech: CandySpeech = null

#^ Interrupt dialogue:
var interrupting = false			#/ True while interrupt_dialogue() is tearing down.
var interrupt_mouse_mode := "end"	#/ interrupt_dialogue()'s new_mouse_mode (lowercase), applied by end_dialogue().
signal dialogue_fully_ended			#/ Emitted when end_dialogue() finishes

#^ Nesting, conditions and choices:
var nesting_depth := 0

#? One entry per nesting depth: -1 = no chain, 0 = open (Elif/Else may run), 1 = closed (a branch ran),
#? IF_ERROR = condition failed to evaluate, rest of the chain skipped.
const IF_ERROR: int = 2
var if_array: Array = []

#^ For iterators:
var for_ = {}

#^ command_value of each open choice list, per depth:
var choice_list_data = {
#/	 "0": {
#/		"Choice_List": {...},
#/		}
}

#^ Open choice lists, per depth:
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
#/		},
#/		"Finishing": true		#/ Only while a picked choice's Bridge / Jump / Return / End runs
#/	}
}

#^ Choices → Choice_List command:
signal choice_list_event(depth, event, category, choice, source)

#^ Input scenes → Input command:
signal input_received(depth, event, parameters)

#^ Input scenes opened by this engine:
#? Read through own_input_scenes().
var input_scenes: Array = []

#^ Block events while dialogue is ending:
var dialogue_ending: bool = false


#endregion





#°#########################################################################################
#^
#^										  ENGINE
#^
#°#########################################################################################
#region

#?##############################
#& PREPARATION:
#?#############
#region
func _ready() -> void:
	_setup_candy_ref()

	#@ Step 1 - Record defaults for "Reset":
	CandyEngineSettings.get_shared().record_defaults(self, self)

	#@ Step 2 - Claim UI elements:
	owned_ui_elements.clear()
	for key in ui_elements_paths:
		claim_ui_element(key)

	_claim_media_players()


#* Claim an owned UI element:
func claim_ui_element(key: String) -> void:
	var node := CandyUI.get_shared().get_element(self, self, key)
	if node == null:
		return

	if not ("access" in node):
		if "caller" in node:
			node.caller = self
		return

	if not is_ui_element_owned(key):
		return

	if node.access != 0:
		push_error("Candy DE: '%s' is listed as owned in %s's ui_elements_paths, but it is set to Public. List it as [path, false], or set it to Private." % [key, str(name)])
		return

	if node.owner_engine != null and is_instance_valid(node.owner_engine) and node.owner_engine != self:
		push_error("Candy DE: '%s' is owned by both %s and %s. A Private UI element can only have one owner engine: list it as [path, false] in one of them." % [key, str(node.owner_engine.name), str(name)])
		return

	node.owner_engine = self
	node.caller = self

	#Ł Drop freed entries:
	for element in owned_ui_elements.duplicate():
		if not is_instance_valid(element):
			owned_ui_elements.erase(element)
	if not (node in owned_ui_elements):
		owned_ui_elements.append(node)


#* UI element path, or "":
func ui_element_path(key: String) -> String:
	var entry = ui_elements_paths.get(key, "")
	#% [path, owned]:
	if entry is Array:
		if entry.is_empty():
			return ""
		return str(entry[0])
	return str(entry)


#* Whether this engine owns a UI element:
func is_ui_element_owned(key: String) -> bool:
	var entry = ui_elements_paths.get(key, "")
	if entry is Array and entry.size() >= 2:
		return bool(entry[1])	#/ [path, false] is only a name
	return true	#/ Bare path is owned


#* Claim owned media players:
func _claim_media_players() -> void:
	owned_media_players.clear()

	for key in media_players_paths:
		if not is_media_player_owned(key):
			continue

		var node = get_node_or_null(media_player_path(key))
		if node == null:
			continue

		if not ("access" in node):
			if "caller" in node:
				node.caller = self
			continue

		if node.access != 0:
			push_error("Candy DE: '%s' is listed as owned in %s's media_players_paths, but it is set to Public. List it as [path, false], or set it to Private." % [key, str(name)])
			continue

		if node.owner_engine != null and is_instance_valid(node.owner_engine) and node.owner_engine != self:
			push_error("Candy DE: '%s' is owned by both %s and %s. A Private media player can only have one owner engine: list it as [path, false] in one of them." % [key, str(node.owner_engine.name), str(name)])
			continue

		node.owner_engine = self
		node.caller = self
		if not (node in owned_media_players):
			owned_media_players.append(node)


#* Media player path, or "":
func media_player_path(key: String) -> String:
	var entry = media_players_paths.get(key, "")
	#% [path, owned]:
	if entry is Array:
		if entry.is_empty():
			return ""
		return str(entry[0])
	return str(entry)


#* Whether this engine owns a media player:
func is_media_player_owned(key: String) -> bool:
	var entry = media_players_paths.get(key, "")
	if entry is Array and entry.size() >= 2:
		return bool(entry[1])	#/ [path, false] is only a name
	return true	#/ Bare path is owned


#* Register symbols and functions with CandyRef:
func _setup_candy_ref() -> void:
	candy_ref = CandyRef.get_shared()

	#? "¢€score"  ->  candy_de.variables["score"]
	candy_ref.shortcut_symbols[candy_de.vardict_symbol] = "candy_de.variables"

	#? "¢°npc1"  ->  the actor in the role; "¢°npc1.Age"  ->  a property of that actor
	candy_ref.lookup_symbols[candy_de.role_symbol] = {
		"keys": "candy_de.roles",
		"entries": "candy_de.actors",
	}

	#? "¢file_var('user://save.json').stats.hp"
	candy_ref.constants["file_var"] = Callable(self, "file_var")

	#? Variables whose value is read as written (Data_Tables/Literal_Variables.gd):
	candy_ref.literal_rules_source = func() -> Variant: return candy_de.get("literal_variables")
	CandySanitizer.check_literal_variables()


#* Read a file variable:
func file_var(file_path: String) -> Variant:
	var ext := file_path.get_extension().to_lower()
	if not (ext in FILE_VAR_EXTENSIONS):
		printerr("file_var(): unsupported or missing file extension → ", file_path)
		return null

	if not FileAccess.file_exists(file_path):
		return {}	#/ Missing file

	return CandyFileVars.get_shared().read_file(self, self, file_path, ext)	#/ null if unreadable
#endregion


#?##############################
#& ENGINE CORE:
#?#############
#region
#* Load a .txt dialogue into running_dialogue:
#? file_name without extension.
func load_scripted_dialogue(file_name: String) -> void:
	if dialogue_running == true or dialogue_starting == true or dialogue_ending == true:
		printerr("load_scripted_dialogue(): a dialogue is still running in ", self, " - '", file_name, "' was not loaded.")
		return

	var path = candy_de.dialogues_folder.path_join(file_name + ".txt")

	#@ Step 1 - Open the file:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Candy DE: Could not open dialogue file: " + path)
		return

	var text_data := file.get_as_text()
	file.close()

	#@ Step 2 - Clean syntax:
	text_data = _clean_dialogue_source(text_data)

	#@ Step 3 - Parse:
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

	#@ Step 4 - Store:
	#? Bare or wrapped (Meta/Dialogue keys).
	if result.has("Dialogue"):
		running_dialogue = result["Dialogue"]
	else:
		running_dialogue = result

	running_dialogue_file = file_name


#* Start a dialogue:
func start_dialogue(conversation, start_block, start_line):
	#% One dialogue per engine:
	if dialogue_running == true or dialogue_starting == true:
		printerr("CANNOT START DIALOGUE: Another dialogue is still running in " + str(self))
		return

	#% Check dialogue ended properly:
	if dialogue_ending == true:
		printerr("CANNOT START DIALOGUE: The previous dialogue_end() did not complete. Engine instance " + str(self) + " may be compromised.")
		return

	#% Check previous suspension:
	if dialogue_suspended == true:
		printerr("CANNOT START DIALOGUE: A previous suspension did not completely resume. Engine instance " + str(self) + " may be compromised.")
		return

	#% Validate target first:
	if not running_dialogue.has(conversation) or not running_dialogue[conversation].has(start_block) or not running_dialogue[conversation][start_block].has("Text"):
		printerr("CANNOT START DIALOGUE: target not found → %s > %s (in %s)" % [str(conversation), str(start_block), str(self)])
		return

	#@ Step 1 - Reset per-dialogue state:
	#? Kept after a dialogue ends, for game code.
	previous_mode = ""
	previous_speaker = ""

	conversation_tracker = ""
	block_tracker = ""
	line_tracker = ""
	line_data_tracker = {}
	resolved_disp_tracker = ""

	prev_conversation_tracker = ""
	prev_block_tracker = ""
	prev_line_tracker = ""
	prev_line_data_tracker = {}
	prev_resolved_disp_tracker = ""

	for_.clear()
	if_array.clear()
	choice_lists.clear()
	choice_list_data.clear()
	line_paused_media_players.clear()

	suspended_voice = false
	suspended_portrait_nodes.clear()
	suspended_portrait_animplayers.clear()

	nesting_depth = 0

	CandyFlow.get_shared().reset_return_state(self, self)

	skip_wait = false
	waiting_for_input = null
	killswitch = false
	greenlight = true
	interrupting = false

	#¬ Start dialogue:
	#@ Step 2 - Get language:
	CandyEngineSettings.get_shared().refresh_language(self, self)

	#@ Step 3 - Set game state:
	dialogue_starting = true
	await candy_de.run_hook("change_game_state", {"caller": self, "method": "start"})

	#@ Step 4 - Make UI visible:
	if "visible" in self:
		self.visible = true

	#@ Step 5 - Set Mouse Mode:
	if mouse_mode_start != MouseModes.None:
		Input.set_mouse_mode(mouse_mode_start as Input.MouseMode)

	#. Hook call:
	await candy_de.run_hook("x_dialogue_start", {"caller": self, "conversation": conversation, "block": start_block, "line": start_line})

	#@ Step 6 - Mark dialogue as running:
	dialogue_running = true
	dialogue_starting = false

	#@ Step 7 - Chat:
	var chat := CandyUI.get_shared().get_element(self, self, "chat_path")
	if chat != null and chat.has_method("dialogue_started"):
		chat.dialogue_started(self)

	#@ Step 8 - Run dialogue:
	run_dialogue(conversation, start_block, start_line, "Text", true)


#* Start a new run_dialogue() for Jump:
func jump_start_dialogue(new_conversation, new_block, target_line):
	if OS.is_debug_build() and debug_prints == true:
		print("Jump-starting dialogue.")

	while greenlight == false:
		await get_tree().process_frame

	#% Interrupted during Jump:
	if interrupting == true:
		killswitch = false
		await end_dialogue()
		return

	if OS.is_debug_build() and debug_prints == true:
		print("Jump-start: Greenlight true")

	run_dialogue(new_conversation, new_block, target_line, "Text", true)


#* Run lines:
#? 'nested': synthetic lines (If/For/While, choices, Input "run_lines").
func run_dialogue(current_conversation, current_block, line_index, source, main, nested := false):
	if OS.is_debug_build() and debug_prints == true:
		print("Run_dialogue()")
		print(current_conversation)
		print(current_block)
		print(line_index)

	#Ł Check killswitch and dialogue suspension:
	#% Killswitch:
	if killswitch == true:
		if main == false:
			return "END"
		elif main == true:
			killswitch = false
			emit_signal("killswitch_off")

	#% Suspended Dialogue:
	await _await_suspension()

	#@ Step 1 - Get text array:
	var text_array
	if typeof(source) == TYPE_STRING and source == "Text":
		text_array = running_dialogue[current_conversation][current_block]["Text"]
	else:
		text_array = source

	#@ Step 2 - Resolve Line Mark:
	if typeof(line_index) == TYPE_STRING:
		if line_index.is_valid_int():
			#% Numeric string is a line index:
			line_index = int(line_index)
		else:
			var target_index := CandyFlow.get_shared()._find_line_mark(self, self, text_array, line_index)
			if target_index == -1:
				push_warning("Candy DE: Line Mark '%s' not found in %s > %s. Defaulting to line 0." % [line_index, str(current_conversation), str(current_block)])
				target_index = 0
			line_index = target_index

	#@ Step 3 - Run lines:
	var index = line_index
	while index < text_array.size():
		var feedback = await process_lines(current_conversation, current_block, index, source, main, nested)

		#@ Step 4 - Handle feedback:
		match feedback:
			"END":
				if main == false:
					if OS.is_debug_build() and debug_prints == true:
						print("run_dialogue() - Step 4: main = false, return 'END'.")
					return "END"
				if main == true:
					if OS.is_debug_build() and debug_prints == true:
						print("run_dialogue() - Step 4: main = true, call end_dialogue().")
					break

			"Return":
				#¦ 1. Nested frames pass through:
				var is_block_frame: bool = (typeof(source) == TYPE_STRING and source == "Text")

				if not is_block_frame:
					if OS.is_debug_build() and debug_prints == true:
						print("run_dialogue() - Step 4: 'Return' passing through an inline frame.")
					return "Return"

				#¦ 2. The main Block cannot be returned from:
				if main == true:
					var end_now: bool = return_end_on_overshoot
					CandyFlow.get_shared().reset_return_state(self, self)

					if end_now:
						if OS.is_debug_build() and debug_prints == true:
							print("run_dialogue() - Step 4: 'Return' overshot the main Block with a negative Levels value; ending dialogue.")
						break

					if OS.is_debug_build() and debug_prints == true:
						print("run_dialogue() - Step 4: 'Return' reached the main Block; clamping and continuing.")
					index += 1

				#¦ 3. Bridged Block - consume one level:
				else:
					#% Unlimited (Levels 0):
					if return_levels < 0:
						return "Return"

					if return_levels > 0:
						return_levels -= 1

					#% Levels used up:
					if return_levels <= 0:
						CandyFlow.get_shared().reset_return_state(self, self)
						if OS.is_debug_build() and debug_prints == true:
							print("run_dialogue() - Step 4: 'Return' consumed its last level; returning 'Continue'.")
						return "Continue"

					if OS.is_debug_build() and debug_prints == true:
						print("run_dialogue() - Step 4: 'Return' consumed a level, %d remaining." % return_levels)
					return "Return"

			"Continue":
				index += 1
				if OS.is_debug_build() and debug_prints == true:
					print("run_dialogue() - Step 4: feedback = 'Continue', continue to next line.")

	#@ Step 5 - Dialogue finished:
	if main == false:
		if OS.is_debug_build() and debug_prints == true:
			print("run_dialogue() - Step 5: main = false, return 'Continue'.")
		return "Continue"
	elif main == true:
		if OS.is_debug_build() and debug_prints == true:
			print("run_dialogue() - Step 5: main = true, call end_dialogue().")
		await end_dialogue()


#* Run one line:
func process_lines(current_conversation, current_block, line_index, source, main, nested := false) -> String:
	var feedback = "Continue"

	#Ł Check killswitch and dialogue suspension:
	#% Killswitch:
	if killswitch == true:
		if main == false:
			return "END"
		elif main == true:
			killswitch = false
			emit_signal("killswitch_off")
			return "END"

	#% Suspended Dialogue:
	await _await_suspension()

	#@ Step 1 - Get text array:
	var text_array
	if typeof(source) == TYPE_STRING and source == "Text":
		text_array = running_dialogue[current_conversation][current_block]["Text"]
	else:
		text_array = source

	#% Index out of range:
	if line_index >= text_array.size():
		CandyFlow.get_shared().log_transition(self, self, "End")
		return "END"

	#@ Step 2 - Line data:
	var line_data = text_array[line_index]

	#% Malformed or empty line:
	if typeof(line_data) != TYPE_DICTIONARY or line_data.is_empty():
		push_warning("Candy DE: empty or malformed line in %s > %s, line %s - treated as the end of the Block." % [str(current_conversation), str(current_block), str(line_index)])
		CandyFlow.get_shared().log_transition(self, self, "End")
		return "END"

	#@ Step 3 - Update progress trackers:
	if not nested:
		prev_conversation_tracker = conversation_tracker
		prev_block_tracker = block_tracker
		prev_line_tracker = line_tracker
		prev_line_data_tracker = line_data_tracker

		conversation_tracker = current_conversation
		block_tracker = current_block
		line_tracker = line_index
		line_data_tracker = line_data

	#@ Step 4 - Skip LM and Comment lines:
	#% Only if every key is LM or Comment:
	if _is_marker_only_line(line_data):
		return "Continue"

	var last_cmd := ""
	var line_had_speech := false

	#@ Step 5 - Line context:
	var ctx := CandyContext.new()
	ctx.conversation = current_conversation
	ctx.block = current_block
	ctx.line_index = line_index
	ctx.line_data = line_data
	ctx.main = main
	ctx.nested = nested

	#. Hook call:
	if not nested:
		await candy_de.run_hook("x_new_line", {"caller": self, "line_data": line_data}, CandyCustomData.of_line(line_data))

	#@ Step 6 - Run line commands:
	for raw_key in line_data.keys():
		var value = line_data[raw_key]
		var cmd_name := normalize_command_name(raw_key)

		#. Hook call:
		#% Not for Spoken_Line (own hooks):
		if not nested and cmd_name != "spoken_line":
			await candy_de.run_hook("x_command_start", {"caller": self, "line_data": line_data,
				"command": raw_key, "command_value": value}, CandyCustomData.levels([value]))

		ctx.speech_outcome = ""
		feedback = await commands(raw_key, value, ctx)

		#Ł Track last command and speech:
		if cmd_name == "spoken_line":
			if ctx.speech_outcome == "Displayed" or ctx.speech_outcome == "Counted":
				line_had_speech = true
			if ctx.speech_outcome == "Displayed":
				last_cmd = cmd_name
		else:
			last_cmd = cmd_name

		#% Feedback and killswitch:
		if feedback == "END" or killswitch == true:
			if main == false:
				return "END"
			elif main == true:
				killswitch = false
				emit_signal("killswitch_off")
				return "END"

		#% Return:
		if feedback == "Return":
			return "Return"

		#% Suspended Dialogue:
		await _await_suspension()

	#@ Step 7 - Decrement media pauses:
	#? Not for nested lines (the outer line counts once):
	if not nested:
		for pause_mp in line_paused_media_players.duplicate():
			if not is_instance_valid(pause_mp) or int(pause_mp.get("pause_count")) <= 0 or pause_mp.get("pause_engine") != self:
				line_paused_media_players.erase(pause_mp)
				continue
			if pause_mp.pause_mode == "speech" and not line_had_speech:
				continue

			pause_mp.pause_count -= 1
			if pause_mp.pause_count == 0:
				line_paused_media_players.erase(pause_mp)
				if pause_mp.has_method("unpause"):
					pause_mp.unpause()

	#@ Step 8 - Close If chain:
	if not (last_cmd in ["if", "elif", "else"]):
		if if_array.size() > nesting_depth:
			if_array.remove_at(nesting_depth)

	#@ Step 9 - Killswitch and suspension:
	#% Killswitch:
	if killswitch == true:
		if main == false:
			return "END"
		elif main == true:
			killswitch = false
			emit_signal("killswitch_off")
			return "END"

	#% Suspended Dialogue:
	await _await_suspension()

	#@ Step 10 - Return feedback:
	if feedback == null or feedback == "":
		push_warning("process_lines() ended with feedback = '" + str(feedback) + "'. This should never happen: defaulting to 'Continue' as an assumption. May cause errors. Good luck.")

		feedback = "Continue"

	return feedback

#endregion


#?##############################
#& COMMANDS:
#?###############
#region
#* Run a command:
func commands(command_key, command_value, ctx: CandyContext):
	#% Killswitch:
	if killswitch == true:
		return "END"

	#% Suspended Dialogue:
	await _await_suspension()

	var cmd = normalize_command_name(command_key)

	#Ł Build registries on first use:
	if not registries_built:
		_build_registries()

	#% Reject disallowed text event commands:
	if text_event_speech != null and not CandyTextEvents.get_shared().allows_command(self, self, cmd):
		var event_location := ""
		if ctx != null:
			event_location = " (in a text event of %s > %s, line %s)" % [str(ctx.conversation), str(ctx.block), str(text_event_speech.line_index)]
		printerr("Candy DE: '", command_key, "' can't run in a text event - add it to text_event_commands (Candy_Properties.gd) to allow it", event_location, ". Skipped.")
		return "Continue"

	if command_registry.has(cmd):
		var command_script: CandyCommand = command_registry[cmd]
		@warning_ignore("redundant_await")
		var command_feedback = await command_script.execute(self, command_value, ctx)
		return command_feedback

	#% Script not found:
	var location := ""
	if ctx != null:
		location = " (in %s > %s, line %s)" % [str(ctx.conversation), str(ctx.block), str(ctx.line_index)]
	printerr("Candy DE: unknown command '", command_key, "' - no script of that name in the Commands folder", location, ". Skipped.")
	return "Continue"


#* Normalize command names:
func normalize_command_name(raw_key: String) -> String:
	return raw_key.to_lower()


#* Load standalone command scripts:
func _build_registries() -> void:
	command_registry.clear()
	input_event_registry.clear()
	choice_event_registry.clear()
	await_event_registry.clear()
	custom_event_registry.clear()
	move_event_registry.clear()
	variation_tag_registry.clear()
	dialogue_mode_registry.clear()

	var engine_folder := _get_engine_folder()
	if engine_folder == "":
		printerr("Candy DE: could not find the folder of Candy_Engine.gd - built-in commands not loaded.")
	else:
		_scan_script_folder(engine_folder.path_join("Commands"), CandyCommand, command_registry)
		_scan_script_folder(engine_folder.path_join("Input_Events"), CandyInputEvent, input_event_registry)
		_scan_script_folder(engine_folder.path_join("Choice_Events"), CandyChoiceEvent, choice_event_registry)
		_scan_script_folder(engine_folder.path_join("Dialogue_Modes"), CandyDialogueMode, dialogue_mode_registry)
		_scan_script_folder(engine_folder.path_join("Await_Events"), CandyAwaitEvent, await_event_registry, false)
		_scan_script_folder(engine_folder.path_join("Custom_Events"), CandyCustomEvent, custom_event_registry, false)
		_scan_script_folder(engine_folder.path_join("Move_Events"), CandyMoveEvent, move_event_registry, false)
		_scan_script_folder(engine_folder.path_join("Variation_Tags"), CandyVariationTag, variation_tag_registry, false)

	#% Tags overridden by player_tags / speaker_tags:
	for tag_key in player_tags.keys() + speaker_tags.keys():
		if variation_tag_registry.has(str(tag_key).to_lower()):
			push_warning("Candy DE: the variation tag '%s' is in this engine's player_tags or speaker_tags, so its script in Variation_Tags is never used (%s)." % [tag_key, name])

	registries_built = true


#* Dialogue mode script by name, or null:
func get_dialogue_mode(mode: Variant) -> CandyDialogueMode:
	if not registries_built:
		_build_registries()
	return dialogue_mode_registry.get(str(mode).strip_edges().to_lower())


#* Dialogue mode names:
func dialogue_mode_names() -> Array[String]:
	if not registries_built:
		_build_registries()
	var names: Array[String] = []
	for mode_script in dialogue_mode_registry.values():
		names.append(mode_script.mode_name())
	return names


#* Folder of Candy_Engine.gd:
func _get_engine_folder() -> String:
	var engine_script: Script = get_script()
	while engine_script != null:
		if engine_script.resource_path.get_file() == "Candy_Engine.gd":
			return engine_script.resource_path.get_base_dir()
		engine_script = engine_script.get_base_script()

	return ""


#* Register a folder's scripts extending base_class:
func _scan_script_folder(folder: String, base_class: Script, registry: Dictionary, required := true) -> void:
	if folder == "":
		return

	if not DirAccess.dir_exists_absolute(folder):
		if required == true:
			push_warning("Candy DE: script folder not found → " + folder)
		return

	var found_paths: Dictionary = {}
	_scan_script_subfolder(folder, base_class, registry, found_paths)


#* Recursive part of _scan_script_folder():
func _scan_script_subfolder(folder: String, base_class: Script, registry: Dictionary, found_paths: Dictionary) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		push_warning("Candy DE: could not open script folder → " + folder)
		return

	#@ Step 1 - Scripts in this folder:
	for file_name in dir.get_files():
		#Ł Trim .gd/.gdc suffixes:
		var script_name := ""
		if file_name.ends_with(".gd"):
			script_name = file_name.trim_suffix(".gd")
		elif file_name.ends_with(".gd.remap"):
			script_name = file_name.trim_suffix(".gd.remap")
		elif file_name.ends_with(".gdc"):
			script_name = file_name.trim_suffix(".gdc")

		if script_name == "":
			continue

		var script_path := folder.path_join(script_name + ".gd")
		var loaded_script := load(script_path) as Script
		if loaded_script == null or not loaded_script.can_instantiate():
			printerr("Candy DE: could not load script → ", script_path)
			continue

		#Ł Check base class:
		var ancestor: Script = loaded_script
		while ancestor != null and ancestor != base_class:
			ancestor = ancestor.get_base_script()

		if ancestor == null:
			printerr("Candy DE: '", script_path, "' does not extend ", base_class.resource_path.get_file(), " - skipped.")
			continue

		#% Duplicate name:
		var registry_key := script_name.to_lower()
		if found_paths.has(registry_key):
			push_warning("Candy DE: '%s' and '%s' have the same name - only '%s' is used." % [found_paths[registry_key], script_path, script_path])
		found_paths[registry_key] = script_path

		registry[registry_key] = loaded_script.new()

	#@ Step 2 - Sub-folders:
	for sub_folder in dir.get_directories():
		_scan_script_subfolder(folder.path_join(sub_folder), base_class, registry, found_paths)

#endregion


#?##############################
#& DIALOGUE PROGRESSION:
#?######################
#region
#* Raise the killswitch:
func raise_killswitch() -> void:
	killswitch = true
	killswitch_raised.emit()


#* Interrupt the running dialogue:
#+ Can be awaited: returns once the dialogue has fully ended.
#! Waits for running hooks, Call methods and Await_Events scripts.
func interrupt_dialogue(new_mouse_mode: String = "End") -> void:
	#@ Step 1 - Nothing to interrupt:
	if dialogue_running == false:
		return

	#@ Step 2 - Already ending:
	if interrupting == true or dialogue_ending == true:
		await dialogue_fully_ended
		return

	interrupting = true

	#Ł Store mouse mode, applied once ended ("End" = mouse_mode_end, "" = leave as is):
	if new_mouse_mode.to_lower() in ["", "end", "visible", "hidden", "captured", "confined", "confined_hidden"]:
		interrupt_mouse_mode = new_mouse_mode.to_lower()
	else:
		push_warning("Candy DE: interrupt_dialogue() - unknown mouse mode '%s' (expected \"Visible\", \"Hidden\", \"Captured\", \"Confined\", \"Confined_Hidden\", \"End\" or \"\"). The mouse is left as it is." % new_mouse_mode)
		interrupt_mouse_mode = ""

	#@ Step 3 - Raise the killswitch:
	raise_killswitch()

	#@ Step 4 - Wake suspended coroutines:
	if dialogue_suspended == true:
		_keep_media_suspended = true
		suspended_voice = false
		resume_dialogue()
		_keep_media_suspended = false

	#@ Step 5 - Wake Input / Choice_List:
	#? Both check the killswitch before the depth, so -1 reaches them.
	input_received.emit(-1, "killswitch", {})
	choice_list_event.emit(-1, "killswitch", "", "", null)

	#@ Step 6 - Wait for cleanup:
	#? A pending Jump ends the dialogue itself.
	if dialogue_running == true:
		await dialogue_fully_ended

	interrupting = false


#* End the dialogue:
func end_dialogue():
	#¦ 1. Jump - Skip cleanup:
	if greenlight == false:
		#Ł Reset greenlight:
		greenlight = true

	#¦ 2. End - Cleanup:
	elif greenlight == true:
		#@ Step 1 - Block events:
		dialogue_ending = true

		#@ Step 2 - Log the end, unless End or Return did:
		if write_dialogue_history == true:
			var last_entry = null
			if not dialogue_history.is_empty():
				last_entry = dialogue_history[-1]
			if typeof(last_entry) != TYPE_DICTIONARY or not last_entry.has("End"):
				CandyFlow.get_shared().log_transition(self, self, "End")

		#@ Step 3 - Unsuspend dialogue:
		if dialogue_suspended == true:
			_keep_media_suspended = true
			suspended_voice = false
			resume_dialogue()
			_keep_media_suspended = false

		#@ Step 4 - Restore game state:
		await candy_de.run_hook("change_game_state", {"caller": self, "method": "end"})

		#@ Step 5 - Clear UI:
		await clear_ui()

		#@ Step 6 - Reset Mouse Mode:
		if interrupting == true:
			match interrupt_mouse_mode:
				"end":
					if mouse_mode_end != MouseModes.None:
						Input.set_mouse_mode(mouse_mode_end as Input.MouseMode)
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
			interrupt_mouse_mode = "end"

		elif mouse_mode_end != MouseModes.None:
			Input.set_mouse_mode(mouse_mode_end as Input.MouseMode)

		#@ Step 7 - Kill Volume fades:
		_kill_volume_tweens()

		#@ Step 8 - Stop owned Private players:
		for media_player in owned_media_players:
			if is_instance_valid(media_player):
				media_player.reset()

		#@ Step 9 - Stop or release held Public players:
		for media_player in held_media_players.duplicate():
			if not is_instance_valid(media_player):
				continue
			if CandyPlayback.get_shared().resolve_held_setting(self, self, media_player, "end_held_media"):
				media_player.reset()
			else:
				media_player.release_hold()
		held_media_players.clear()

		#@ Step 10 - Stop owned players outside the Private / Public model:
		for key in media_players_paths:
			if not is_media_player_owned(key):
				continue
			var media_player = get_node_or_null(media_player_path(key))
			if media_player == null or "access" in media_player:
				continue

			#Ł Stop (reset() doesn't stop AnimationPlayers):
			if media_player.has_method("stop"):
				media_player.stop()

			if "stream" in media_player:
				media_player.stream = null

			if "visible" in media_player:
				media_player.visible = false

			#Ł Reset (Video and Image players have no stop()):
			if media_player.has_method("reset") and media_player.get("caller") != null:
				media_player.reset()

			#Ł Clear pause state last:
			if "stream_paused" in media_player:
				media_player.stream_paused = false
			if "paused" in media_player:
				media_player.paused = false

		#@ Step 11 - Clear media tracking arrays:
		line_paused_media_players.clear()

		#@ Step 12 - Drop the last voice player:
		active_voice_player = null

		#@ Step 13 - Clear this engine's Input scenes:
		for input_scene in own_input_scenes():
			if input_scene.has_method("dialogue_ended"):
				await input_scene.dialogue_ended()

		#@ Step 14 - Close this engine's choice menus:
		choice_lists.clear()
		choice_list_data.clear()
		CandyChoices.get_shared().free_menus(self, self)
		await get_tree().process_frame

		#@ Step 15 - Reset if_array:
		if_array.clear()

		#. Hook call:
		await candy_de.run_hook("x_dialogue_end", {"caller": self})

		#@ Step 16 - Revert Engine command settings:
		CandyEngineSettings.get_shared().revert_settings(self, self)

		#@ Step 17 - Reset nesting depth:
		nesting_depth = 0
		CandyFlow.get_shared().reset_return_state(self, self)

		#@ Step 18 - Clear dialogue_running and dialogue_ending:
		dialogue_ending = false
		dialogue_running = false

		#@ Step 19 - Emit end signal:
		dialogue_fully_ended.emit()

		if OS.is_debug_build() and debug_prints == true:
			print("end_dialogue(): Dialogue Ended")


#* Clear the previous line for a new one:
func clear_previous_dialogue(mode: String, speech: CandySpeech = null) -> void:
	var previous_script := get_dialogue_mode(previous_mode)
	if previous_script != null:
		previous_script.clear_line(self, str(previous_speaker), mode)

	var mode_script := get_dialogue_mode(mode)
	if mode_script != null:
		mode_script.start_line(self, speech)


#* Clear all UI elements:
func clear_ui():
	#@ Step 1 - Clear dialogue box:
	var box_root := CandyWriting.get_shared().clear_text_ui(self, self, "dialogue_box_path")
	if box_root != null and box_root.has_method("no_portrait"):
		box_root.no_portrait()

	#@ Step 2 - Clear Speech Bubbles:
	for root in [get_node_or_null(bubbles_npc_path), get_node_or_null(bubbles_player_path)]:
		if root == null:
			continue
		for actor in root.get_children():
			CandyWriting.get_shared().clear_actor_bubble(self, self, actor)

	#@ Step 3 - Clear VN Speech Bubbles:
	CandyWriting.get_shared().clear_vn_bubbles(self, self)

	#@ Step 4 - Clear Barks:
	CandyWriting.get_shared().clear_text_ui(self, self, "barks_path")

	#@ Step 5 - Clear Subtitles:
	CandyWriting.get_shared().clear_text_ui(self, self, "subtitles_path")

	#@ Step 6 - Silence the Voice player:
	var voice_player := CandyVoice.get_shared().get_player(self, self)
	if voice_player != null and voice_player.has_method("reset"):
		voice_player.reset()

	#@ Step 7 - Chat:
	var chat := CandyUI.get_shared().get_element(self, self, "chat_path")
	if chat != null and chat.has_method("dialogue_ended"):
		chat.dialogue_ended(self)
	else:
		CandyWriting.get_shared().clear_text_ui(self, self, "chat_path", chat_hide_on_end, chat_clear_on_end)

	#@ Step 8 - Owned and held UI elements:
	#? Owned: always ended. Held: ended if end_held_media says so, released either way.
	for element in owned_ui_elements:
		if is_instance_valid(element) and element.has_method("end_media"):
			await element.end_media({"caller": self})

	for element in held_ui_elements.duplicate():
		if not is_instance_valid(element):
			continue
		if element.has_method("end_media") and CandyPlayback.get_shared().resolve_held_setting(self, self, element, "end_held_media"):
			await element.end_media({"caller": self})
		element.release_hold()
	held_ui_elements.clear()

#endregion


#?##############################
#& DIALOGUE SUSPEND:
#?##################
#region
#* Suspend dialogue:
func suspend_dialogue(suspend_input = 1):
	#% Already suspended or not running:
	if dialogue_suspended == true or dialogue_ending == true or dialogue_running == false or interrupting == true:
		return

	dialogue_suspended = true

	pause_choice_timers()

	if suspend_media == true:
		pause_media_players()
	if suspend_voice == true:
		_pause_voice()
	if suspend_portraits == true:
		pause_portraits()
	pause_ui_elements()

	#Ł Park Input / Choice_List:
	choice_list_event.emit(nesting_depth, "suspend", "", "", null)

	if suspend_input == 1:
		input_received.emit(nesting_depth, "suspend", {})

	#. Hook call:
	candy_de.run_hook("x_dialogue_suspended", {"caller": self})


#* Resume dialogue:
func resume_dialogue():
	if dialogue_suspended == false:
		return
	dialogue_suspended = false

	if suspend_media == true:
		resume_media_players()

	_resume_voice()

	if suspend_portraits == true:
		resume_portraits()

	resume_ui_elements()

	resume_choice_timers()

	#. Hook call:
	var ending: bool = interrupting == true or dialogue_ending == true
	candy_de.run_hook("x_dialogue_resumed", {"caller": self, "ending": ending})

	dialogue_resumed.emit()





#* Wait while dialogue is suspended:
#+ In a loop, follow with 'continue' (its condition may have changed).
func _await_suspension() -> float:
	if dialogue_suspended == false:
		return 0.0	#/ Not suspended

	var pause_start := Time.get_ticks_msec() / 1000.0

	await dialogue_resumed

	return (Time.get_ticks_msec() / 1000.0) - pause_start	#/ Time spent suspended


#* Pause choice timers at the current depth:
func pause_choice_timers() -> void:
	suspended_choice_timers.clear()
	if not choice_lists.has(nesting_depth) or not choice_list_data.has(nesting_depth):
		return
	var menu_node = choice_lists[nesting_depth].get("Menu")
	if not is_instance_valid(menu_node):
		return

	#Ł Current depth only (Signal Pause paused the others):
	for timer_entry in choice_list_data[nesting_depth].get("Timers", []):
		for timer_key in timer_entry.keys():
			var t_node := CandyChoices.get_shared().get_timer(self, self, menu_node, timer_key)
			if t_node and not t_node.paused and not t_node.is_stopped():
				t_node.set_paused(true)
				suspended_choice_timers.append(t_node)


#* Resume suspended choice timers:
func resume_choice_timers() -> void:
	for t_node in suspended_choice_timers:
		if is_instance_valid(t_node):
			t_node.set_paused(false)
	suspended_choice_timers.clear()


#* Suspend media players:
func pause_media_players() -> void:
	for player in _media_players_to_suspend():
		if _is_suspend_immune(player):
			continue
		if player.has_method("suspend_media"):
			player.suspend_media({"caller": self})

	#Ł Pause progressive volume:
	_pause_volume_tweens()


#* Resume media players:
func resume_media_players() -> void:
	if _keep_media_suspended:
		return

	for player in owned_media_players + held_media_players:
		if is_instance_valid(player) and player.has_method("unsuspend_media"):
			player.unsuspend_media({"caller": self})

	#Ł Resume progressive volume:
	_resume_volume_tweens()


#* Find media players to suspend:
func _media_players_to_suspend() -> Array:
	var players: Array = []

	for player in owned_media_players:
		if is_instance_valid(player):
			players.append(player)

	for player in held_media_players:
		if is_instance_valid(player) and CandyPlayback.get_shared().resolve_held_setting(self, self, player, "suspend_held_media"):
			players.append(player)

	return players


#* Whether a media player is in media_suspend_immune:
func _is_suspend_immune(player: Node) -> bool:
	for key in media_suspend_immune:
		if media_players_paths.has(key) and get_node_or_null(media_player_path(key)) == player:
			return true
	return false


#* Pause voice playback:
func _pause_voice() -> void:
	suspended_voice = false
	#% Voice is suspend immune:
	if "Voice" in media_suspend_immune:
		return

	var voice_player := active_voice_player
	if voice_player == null or not is_instance_valid(voice_player) or not ("stream_paused" in voice_player):
		return

	if voice_player.playing and not voice_player.stream_paused:
		voice_player.stream_paused = true
		suspended_voice = true


#* Resume voice playback:
func _resume_voice() -> void:
	if suspended_voice == false:
		return
	suspended_voice = false

	var voice_player := active_voice_player
	if voice_player != null and is_instance_valid(voice_player) and "stream_paused" in voice_player:
		voice_player.stream_paused = false


#* Pause portraits:
func pause_portraits() -> void:
	suspended_portrait_nodes = []
	suspended_portrait_animplayers = []

	#@ Step 1 - Pause portrait nodes:
	for key in PORTRAIT_ELEMENTS:
		var element := CandyUI.get_shared().get_element(self, self, key)
		if element == null or not element.has_method("portrait_nodes"):
			continue
		for portrait_node in element.portrait_nodes():
			if CandyPortrait.get_shared().pause_portrait(self, self, portrait_node):
				suspended_portrait_nodes.append(portrait_node)

	#@ Step 2 - Pause the dialogue box's portrait AnimationPlayers:
	var portrait_scene := CandyUI.get_shared().get_element(self, self, "dialogue_box_path")
	if portrait_scene == null or not portrait_scene.has_method("portrait_root"):
		return
	var anim_root = portrait_scene.portrait_root()
	if anim_root == null:
		return

	var all_anim_players = _find_animation_players(anim_root)
	for player in all_anim_players:
		if player.is_playing():
			player.pause()
			suspended_portrait_animplayers.append(player)


#* Resume portraits:
func resume_portraits() -> void:
	for portrait_node in suspended_portrait_nodes:
		CandyPortrait.get_shared().resume_portrait(self, self, portrait_node)

	for player in suspended_portrait_animplayers:
		if is_instance_valid(player):
			player.play()

	suspended_portrait_nodes = []
	suspended_portrait_animplayers = []

#* Suspend UI elements:
func pause_ui_elements() -> void:
	for element in _ui_elements_to_suspend():
		if element.has_method("suspend_media"):
			element.suspend_media({"caller": self})


#* Resume UI elements:
func resume_ui_elements() -> void:
	for element in owned_ui_elements + held_ui_elements:
		if is_instance_valid(element) and element.has_method("unsuspend_media"):
			element.unsuspend_media({"caller": self})


#* Find UI Elements to suspend:
func _ui_elements_to_suspend() -> Array:
	var elements: Array = []

	for element in owned_ui_elements:
		if is_instance_valid(element):
			elements.append(element)

	for element in held_ui_elements:
		if is_instance_valid(element) and CandyPlayback.get_shared().resolve_held_setting(self, self, element, "suspend_held_media"):
			elements.append(element)

	return elements


#* Every AnimationPlayer under a node:
func _find_animation_players(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		if child is AnimationPlayer:
			result.append(child)
		result.append_array(_find_animation_players(child))
	return result

#endregion


#?##############################
#& VARIABLES:
#?###########
#region
#^ file_var() extensions:
const FILE_VAR_EXTENSIONS := ["json", "txt", "cfg", "ini", "bin", "b64", "base64", "tres", "res", "csv"]


#* Clean dialogue text for Expression:
func _clean_dialogue_source(text: String) -> String:
	var out := PackedStringArray()
	var n := text.length()
	var i := 0
	var in_quote := ""
	var escaped := false

	while i < n:
		var ch := text[i]

		#¦ 1. Inside a string:
		if in_quote != "":
			out.append(ch)
			if escaped:
				escaped = false
			elif ch == "\\":
				escaped = true
			elif ch == in_quote:
				in_quote = ""
			i += 1
			continue

		#¦ 2. Opening quote:
		if ch == "\"" or ch == "'":
			in_quote = ch
			out.append(ch)
			i += 1
			continue

		#¦ 3. Comment - skip to line end:
		if ch == "\u0023":
			while i < n and text[i] != "\n":
				i += 1
			continue

		#¦ 4. Godot's printed null:
		if ch == "<" and text.substr(i, 6).to_lower() == "<null>":
			out.append("null")
			i += 6
			continue

		#¦ 5. Trailing comma before ] or }:
		if ch == ",":
			var j := i + 1
			while j < n:
				var look := text[j]
				if look == " " or look == "\t" or look == "\n" or look == "\r":
					j += 1
				elif look == "\u0023":
					while j < n and text[j] != "\n":
						j += 1
				else:
					break
			if j < n and (text[j] == "]" or text[j] == "}"):
				i += 1
				continue

		out.append(ch)
		i += 1

	var cleaned := "".join(out).strip_edges()
	if cleaned.ends_with(","):
		cleaned = cleaned.substr(0, cleaned.length() - 1)
	return cleaned

#endregion


#?##############################
#& MEDIA HELPERS:
#?###############
#region
#* Pause Volume fades:
func _pause_volume_tweens() -> void:
	CandyPlayback.get_shared()._prune_volume_tweens(self, self)
	for tween in active_volume_tweens:
		tween.pause()


#* Resume Volume fades:
func _resume_volume_tweens() -> void:
	CandyPlayback.get_shared()._prune_volume_tweens(self, self)
	for tween in active_volume_tweens:
		tween.play()


#* Kill Volume fades:
func _kill_volume_tweens() -> void:
	for tween in active_volume_tweens:
		if tween is Tween and tween.is_valid():
			tween.kill()
	active_volume_tweens.clear()

#endregion


#?##############################
#& Other:
#?#######
#region
#* Whether a line is only Line Marks and Comments:
func _is_marker_only_line(line_data: Dictionary) -> bool:
	var skip_keys := [normalize_command_name("LM"), normalize_command_name("Comment")]
	for key in line_data.keys():
		if typeof(key) != TYPE_STRING:
			return false
		if not (normalize_command_name(key) in skip_keys):
			return false
	return true


#* Apply a language change:
#+ Call after changing candy_de.language.
func refresh_language() -> void:
	CandyEngineSettings.get_shared().refresh_language(self, self)

	#@ Step 1 - Update Choice Menus:
	for depth in choice_lists:
		var menu_node = choice_lists[depth].get("Menu")
		if is_instance_valid(menu_node) and menu_node.has_method("refresh_language"):
			menu_node.refresh_language()

	#@ Step 2 - Update Input Menus:
	for input_scene in own_input_scenes():
		if input_scene.has_method("refresh_language"):
			input_scene.refresh_language()


#* This engine's open Input scenes:
func own_input_scenes() -> Array:
	var kept: Array = []
	#Ł Drop freed and reused ones:
	for input_scene in input_scenes:
		if not is_instance_valid(input_scene) or input_scene.is_queued_for_deletion():
			continue
		if input_scene.get("caller") != self:
			continue
		kept.append(input_scene)
	input_scenes = kept
	return kept.duplicate()	#/ Copy: dialogue_ended() may change the list

#endregion


#endregion
