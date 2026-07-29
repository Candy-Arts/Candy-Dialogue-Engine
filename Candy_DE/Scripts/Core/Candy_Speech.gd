#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


class_name CandySpeech
extends RefCounted


#& SPEAKER
#^ Speaker's actor reference (roles resolved):
var speaker_ref: String = ""
#^ Speaker's DisplayName:
var speaker_display: String = ""
#^ Speaker's node in Bubbles mode (null in other modes):
var speaker_node = null


#& TEXT
#^ Final text (variables, substitutions and LLM applied):
var text: String = ""
#^ Chosen variation (e.g. "English_#2"):
var chosen_variation: String = ""
#^ Text direction ("rtl", else left-to-right):
var direction: String = ""
#^ Resolved disposition, for the speech history:
var disposition: String = ""


#& DISPLAY
#^ Resolved dialogue mode:
var style: String = ""
#^ VN_Bubbles - the bust's bubble and its text node:
var vn_bubble_node = null
var vn_bubble_text_node = null
#^ Node displaying the line:
var display_node: Node = null


#& TEXT EVENTS
#^ Text events, in marker order (CandyTextEvents):
#? Each: {"name", "event" (its keys), "prefix" (text before the marker), "placed", "done"}, plus "position" once measured.
#? 'text' holds a CandyTextEvents.MARKER per event until place_events() takes them out.
var text_events: Array = []
#^ Write_Speed speed, in characters per second (-1 = none):
var write_speed: float = -1.0
#^ Writing skipped (text events run without waits):
var write_skipped: bool = false
#^ Characters the line shows, for auto_advance_per_character (-1 = not measured):
#? Set by display(): the text only, without the speaker name or end-of-line symbol.
var displayed_characters: int = -1


#& SETTINGS
#^ Resolved line settings (CandySettings):
#? Keyed by UI element name, e.g. settings["writing_speed"].
#? Only this mode's settings: use CandySettings.get_value() when unsure.
var settings: Dictionary = {}


#& PORTRAIT
#^ Portrait key from the line:
var portrait_raw: String = ""
#^ Line's Sprite_Frames_File ("": the speaker's). Read with CandyPortrait.sprite_frames_path():
var sprite_frames_raw: String = ""
#^ Line's Portrait_Play: loops, 0, -1 or -2:
#? Read with CandyPortrait.loops_of().
var play_portrait: String = "1"
#^ Line's Portrait_Stop: N, 0 (remove) or -1 (last):
#? Read with CandyPortrait.stop_frame_of().
var portrait_stop: String = "1"


#& VOICE
#^ Full path of the voice file:
#? No extension if the line gave none: CandyVoice.resolve_stream() adds the player's default.
var voice_file: String = ""
#^ Variation whose voice file plays: the chosen one, in the voice language (CandyVoice.voice_variation()):
var voice_variation: String = ""
#^ Chosen variation's "_TTS" text, for "Advanced" TTS:
#? "" when none, or no TTS.
var tts_text: String = ""


#& LINE
#^ Line position:
var conversation: String = ""
var block: String = ""
var line_index: int = -1
#^ Full line dictionary:
var line_data: Dictionary = {}
#^ Spoken_Line's own keys:
var speech_data: Dictionary = {}
#^ Custom Data, [[line values], [variation values]], as written:
var custom_data: Array = []
