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


extends "res://Candy_DE/Scripts/Candy_Properties.gd"


#& INFORMATION:
#TODO: This script is intended to be made a singleton (global script), called with the prefix 'candy'.
#?
#+ This script contains various custom data you can provide, to expand the capabilities of Candy DE.
#?
#+ More detailed information can be found in the Database Guide PDF file.


#^ Creator Data Lists:
#? These variables are used by the standalone Candy Dialogue Creator to import data.
#+ For actors and roles, the Creator can import from the 'actors' and 'roles' dictionaries directly;
#+ Use the actor and role lists below to import shorter lists with only the most important actor or role references.
#+ The lists can be either arrays or dictionaries.
var creator_flag_list = ["Flag_1", "Flag_2"]
var creator_disposition_list = ["Like", "Dislike"]
var creator_actor_list = []
var creator_role_list = []


#^ Substitution Table:
#TODO: Entries are provided as templates. You may modify or delete them.
var substitution_table := {
	"*": {

	},
	"Default*": {
		"he, she": [
			"auto",
			{"Gender": {
				"M": "he",
				"F": "she",
			}},
		],
		"him, her": [
			"auto",
			{"Gender": {
				"M": "him",
				"F": "her",
			}},	
		],
		"id": [
			"auto",
			{"Age, Age": {
				">=¦18": "adult",
				"<=¦18, >¦11": "Teenager",
				"<=¦18, <=¦11": "Child",
			}},			
			{"Origins": {
				"France": "French",
				"England": "English",
				"Italy": "Italian",
			}},
			{"Language": {
				"FR": "French",
				"ENG": "English",
				"IT": "Italian",
			}},

		],
		"cl": [
			"auto",
			{"Class, Gender": {
				"Warrior": "Warrior",
				"Sorcer, M": "Sorcerer",
				"Sorcer, F": "Sorceress",
			}},
			{"Gender, Class": {
				"_, Warrior": "Warrior",
				"M, Sorcer": "Sorcerer",
				"F, Sorcer": "Sorceress",
			}},
		],
		"guy": [
			{"Gender": {
				"M": "guy",
				"F": "girl",
			}},
		],
	},
	"Default": {
		"guy": [
			{"Gender": {
				"M": "guy",
				"F": "lady",
			}},
		],		
	},
}


#^ Lexicon:
#? Keywords can be highlighted in dialogue displays, made to show a tooltip, or made clickable.
var lexicon = {
	"*": {				#/ For all variants.
		"Alice": {
			"Display": "",									#/ Text to display -- Optional, will display the entry key as-is if empty.
			"BBCode": ["[b][color=green]", "[/color][/b]"],	#/ BBCode tags for formatting (do not add the Tooltip and URL tags!)
			"Tooltip": "Alice is a student.",				#/ Custom Tooltip
			"Clickable": false,								#/ Is keyword clickable override.
			"Click_Data": [],								#/ Passed to on_lexicon_clicked() as the 'keyword_data' argument
		},
	},
	"Default":{			#/ Only for variant named "Default" exactly. Takes priority over "Default*"
		"Alice": {
			"Display": "",
			"BBCode": ["[b][color=red]", "[/color][/b]"],
			"Tooltip": "Alice is a student.",
			"Clickable": false,
			"Click_Data": [],
		},
	},
	"Default*":{		#/ For all variants starting in "Default"
		"Alice": {
			"Display": "",
			"BBCode": ["[b][color=blue]", "[/color][/b]"],
			"Tooltip": "Alice is a student.",
			"Clickable": false,
			"Click_Data": [],
		},
		"_June": {
			"Display": "June",
			"BBCode": ["[b][color=blue]", "[/color][/b]"],
			"Tooltip": "Alice is a student.",
			"Clickable": false,
			"Click_Data": [],
		},
	},
}


#^ Dialogue Variables
#? Variables that can be read directly inside dialogue lines ("blablabla {)variable} blablabla")
#! Do not use keys starting with the symbols in Candy_Properties.gd
var variables = {
	"variable": "value",
	"player": "John",
}


#^ Progression Flags:
#? Dictionary for all your dialogue flags
var flags = {
	"flag_1": 0,
	"flag_2": "",
	"quest_started": false,
}


#^ Roles:
#? Roles are used instead of actors when you don't know in advance who the speaker will be,
#? or who should be the target of a command.
#! Always prefix actor roles with the role_symbol (Default: '°')
#+ Make your game assign role values dynamically as appropriate.
var roles = {
	"°civilian_1": "",
}


#^ Player References:
#? Actor references that designate the player(s).
#? Used wherever the engine displays different behavior for NPC vs player characters.
var player_refs = ["Player", "player"]


#^ Actor Data:
#? Contains important personalized data for each actor, which Candy DE may require depending on the features you use.
#! Never prefix actor references and dispositions with the data symbols in Candy_Properties.gd
#! Avoid spaces in actor references and disposition names.
#! Keys are case-sentitive. "Alice" and "alice" are treated as different references by Candy DE.
var actors = {
	"Player": {								#/ Reference used in dialogue lines.
		"Short Name": "",					#/ Optional key, has no built-in use. A value may be assigned and used or displayed in text or anywhere in the game.
		"Display Name": "",					#/ Name as displayed on screen (displays the actor reference if empty)
		"Speaker BBCode": ["", ""],			#/ Optional BBCode formatting added to the Display Name when actor speaks.
		"Gender": "F",						#/ Used for speaker gendered variants (if enabled).
		"Age": 18,
		"Disposition": "",					#/ Disposition, for omitting or making lines conditional. Separate multiple dispositions with a comma (,).
		"Portrait": 0,						#/ -1 = never show portrait; 0 = use default settings; 1 = always show portrait.
		"Bubble Exempt": false,				#/ true = never use speech bubbles for this actor; false = default settings.
		"VN Join Effect": ["", ""],			#/ VN Mode: The animation to play on bust nodes when this actor joins/moves/leaves;
		"VN Move From Effect": ["", ""],	#/ Overrides general and VN scene settings if value is not "".
		"VN Move To Effect": ["", ""],		#/ ["Method", "Value"] (e.g. ["Animation", "Fade Out"])
		"VN Leave Effect": ["", ""],
		"LLM": 0,							#/ -1 = never use LLM for this actor; 0 = default settings; 1 = always use LLM for this actor.
		"TTS": 0,							#/ -1 = never use TTS for this actor; 0 = default settings; 1 = always use TTS for this actor.
		"Box Text Color": null,				#/ Color of the spoken text for this actor in Box mode. Uses BBCode tags. Overrides all other settings.
		"Box Speaker Color": null,			#/ Color of the speaker label for this actor in Box mode. Uses BBCode tags. Overrides all other settings.
		"Bubble Text Color": null,			#/ → Same, in Bubbles mode.
		"Subtitle Text Color": null,		#/ → Same, in Subtitles mode.
		"Subtitle Speaker Color": null,
		"Chat Text Color": null,			#/ → Same, in Chat mode.
		"Chat Speaker Color": null,
		"Bark Text Color": null,			#/ → Same, in Bark mode.
	},
	"Alice": {
		"Short Name": "Alice",
		"Display Name": "Alice Turner",
		"Speaker BBCode": ["", ""],
		"Gender": "F",
		"Age": 18,
		"Disposition": "",
		"Portrait": 0,
		"Bubble Exempt": false,
		"VN Join Effect": ["", ""],
		"VN Move From Effect": ["", ""],
		"VN Move To Effect": ["", ""],
		"VN Leave Effect": ["", ""],
		"LLM": 0,
		"TTS": 0,
		"Box Text Color": null,
		"Box Speaker Color": null,
		"Bubble Text Color": null,
		"Subtitle Text Color": null,
		"Subtitle Speaker Color": null,
		"Chat Text Color": null,
		"Chat Speaker Color": null,
		"Bark Text Color": null,
	},
	"John": {
		"Display Name": "John",
		"Gender": "M",
	},
	"construction_worker": {
		"Display Name": "Construction Worker",
		"Gender": "F",
	},
}

#^ General History:
#? Stores history for all nodes running Candy DE
var general_dialogue_history = []

