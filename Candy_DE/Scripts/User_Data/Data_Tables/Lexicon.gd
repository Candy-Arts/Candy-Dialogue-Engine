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


#^ Lexicon:
#? Keywords to highlight, give a tooltip or make clickable in dialogue displays.
#? Sorted by variation, as in Text_Events.gd. The most specific entry holding the keyword wins.

#/ Example:
#/	"*": {				#/ For all variations.
#/	},
#/
#/	"Default": {		#/ Only the "Default" variation. Takes priority over "Default*"
#/	},
#/
#/	"Default*": {		#/ For all variations starting with "Default"
#/		"_June": {
#/			"Display": "June",
#/			"Disabled": "June",
#/			"BBCode": "[b][color=blue]",
#/			"Tooltip": "June is Alice's sister.",
#/			"Clickable": true,
#/			"Click_Data": ["june_profile"],
#/		},
#/	},

var lexicon = {
	"*": {				#/ All
	},
	"Default*": {		#/ Default language
	},
}
