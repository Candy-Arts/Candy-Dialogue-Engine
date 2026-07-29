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


#^ Substitution Table:
#TODO: Entries are templates. Modify or delete them.
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
		"his": [
			"auto",
			{"Gender": {
				"M": "his",
				"F": "her",
			}},
		],
		"hers": [
			"auto",
			{"Gender": {
				"M": "his",
				"F": "hers",
			}},
		],
		"class": [
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
}
