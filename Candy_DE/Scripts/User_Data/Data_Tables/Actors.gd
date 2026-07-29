#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends CandyDataTable


#^ Actor Data:
#? Each actor's data, which some Candy DE features require.
#! Never prefix actor references and dispositions with the data symbols in Candy_Properties.gd
#! Avoid spaces in actor references and disposition names.
#! Keys are case-sensitive: "Alice" and "alice" are different references.

#^ Settings:
#? An actor overrides most engine settings.
#? Keys are the engine setting's name, capitalized, without underscores; per-mode settings start with the mode (BoxEndOfLineString...).
#? null (or a missing key) leaves it to the UI element and engine. A line's own key overrides it.
#? Every setting and its name at each level: Classes/Candy_Settings.gd.

var actors = {
	"Player": {							#/ Actor Reference
		#% Identity:
		"ShortName": "",				#/ Name shown by text variables (¤Player¤). Empty = DisplayName.
		"DisplayName": "",				#/ Name shown on screen. Empty = the actor reference.
		"Gender": "F",					#/ For speaker gendered variations (if enabled).
		"Disposition": "",				#/ For omitted or conditional lines. Comma-separated.

		#% Variation tags - override the engine's passed_tags / disabled_tags:
		"PassedTags": [],				#/ Tags that pass, e.g. ["Shout"] lets "Default_Shout" be picked. A line's own tags override these.
		"DisabledTags": [],				#/ Tags that fail: variations with them are never picked.

		#% All dialogue modes - null = not set (see above):
		"DialogueMode": null,			#/ "Box", "Subtitles", "Chat", "Bubbles", "Barks" or "Voice". Ignored if nothing can display that mode.
		"EnableVoice": null,			#/ true / false.
		"AwaitVoicePlayback": null,		#/ true / false.
		"TTS": null,					#/ "Off", "Simple", "Advanced" or a TTS mode of your own.
		"TTSAdvancedFallback": null,	#/ "Off", "Simple" or a TTS mode of your own.
		"LLM": null,					#/ true / false.
		"WritingSpeed": null,			#/ Characters per second; 0 = instant.
		"ContinueFastSpeed": null,
		"ContinueSlowSpeed": null,
		"SyncWriteSpeedVoice": null,	#/ true / false.
		"AutoAdvance": null,			#/ Seconds; -1 = manual advance only.
		"AutoAdvancePerCharacter": null,	#/ Seconds added to AutoAdvance per character shown.
		"WriteDialogueHistory": null,	#/ true / false.

		#% Box mode:
		"BoxPortraitMode": null,		#/ "Off", "All", "Player", "NPC" or "VN".
		"BoxTextBBCode": null,			#/ BBCode wraps: opening tags only, e.g. "[color=#ff8080][i]": Candy DE adds the closing ones.
		"BoxSpeakerBBCode": null,		#/ "" = no wrap, even if the engine or UI element sets one.
		"BoxShowSpeaker": null,			#/ true / false: the name at the start of the text.
		"BoxSpeakerPrefix": null,
		"BoxSpeakerSuffix": null,
		"BoxEndOfLineString": null,		#/ Supports BBCode.
		"BoxAdvanceString": null,
		"BoxSelfClear": null,			#/ true / false.
		"BoxPortraitSelfClear": null,	#/ true / false.
		"LexiconBoxMode": null,			#/ true / false.

		#% Subtitles mode:
		"SubtitlesTextBBCode": null,
		"SubtitlesSpeakerBBCode": null,
		"SubtitlesShowSpeaker": null,	#/ true / false.
		"SubtitlesSpeakerPrefix": null,
		"SubtitlesSpeakerSuffix": null,
		"SubtitlesEndOfLineString": null,
		"SubtitlesAdvanceString": null,
		"SubtitlesSelfClear": null,		#/ true / false.
		"LexiconSubtitlesMode": null,	#/ true / false.

		#% Chat mode:
		"ChatPortraitMode": null,		#/ "Off", "All", "Player", "NPC" or "VN".
		"ChatLineScene": null,			#/ The Chat_Line scene this actor's lines use, e.g. "res://My_Game/Chat_Lines/Alice.tscn".
		"ChatSpeakerDisplay": null,		#/ "Every_Line" or "Speaker_Change".
		"ChatPortraitDisplay": null,	#/ "Every_Line", "Speaker_Change" or "Speaker_Or_Portrait_Change".
		"ChatAlignment": null,			#/ "Left", "Right" or "Alternate".
		"ChatKeepPortraitSpace": null,	#/ true / false.
		"ChatKeepSpeakerSpace": null,
		"ChatKeepAlternatePortraitSpace": null,
		"ChatKeepAlternateSpeakerSpace": null,
		"ChatTextBBCode": null,
		"ChatSpeakerBBCode": null,
		"ChatShowSpeaker": null,		#/ true / false.
		"ChatSpeakerPrefix": null,
		"ChatSpeakerSuffix": null,
		"ChatEndOfLineString": null,
		"ChatAdvanceString": null,
		"LexiconChatMode": null,		#/ true / false.

		#% Bubbles mode (also VN_Bubbles):
		"BubblesExemptMode": null,		#/ Mode used when this actor has no speech bubble. Same values as DialogueMode.
		"BubblesTextBBCode": null,
		"BubblesEndOfLineString": null,
		"BubblesAdvanceString": null,
		"LexiconBubblesMode": null,		#/ true / false.

		#% Barks mode:
		"BarksTextBBCode": null,
		"BarksEndOfLineString": null,
		"BarksAdvanceString": null,
		"LexiconBarksMode": null,		#/ true / false.

		#% Voice mode:
		"LexiconVoiceMode": null,		#/ true / false.

		#% VN busts:
		"VNJoinEffect": ["", ""],		#/ Played on bust nodes when this actor joins/moves/leaves.
		"VNMoveFromEffect": ["", ""],	#/ Overrides general and VN scene settings unless "".
		"VNMoveToEffect": ["", ""],		#/ ["Method", "Value"], e.g. ["Animation", "Fade Out"].
		"VNLeaveEffect": ["", ""],
	},
}
