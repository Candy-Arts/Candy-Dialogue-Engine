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


#^ Lexicon Word Rules:
#? Which characters may touch a lexicon keyword, by variation (sorted like the Lexicon).
#?   "Word"     characters a keyword can't touch: "Alice" isn't found in "Malice".
#?   "Joiners"  characters a keyword can't touch when a word character follows them: with "-",
#?              "Jean" isn't found in "Jean-Luc", but is in "-Jean-".
#? "Categories" are Unicode categories or scripts ("L" letters, "N" digits, "Han"...), "Characters"
#? one character per item. The most specific variation key giving a rule wins.

#/ Example - "Jean" isn't found in "Jean-Luc" in French, and keywords are found anywhere in Japanese:
#/	"French*": {
#/		"Joiners": {"Categories": [], "Characters": ["-"]},
#/	},
#/	"Japanese*": {
#/		"Word": {"Categories": [], "Characters": [], "Excluded": []},
#/	},

var lexicon_word_rules = {
	"*": {
		"Word": {"Categories": ["L", "N"], "Characters": ["_"], "Excluded": []},
		"Joiners": {"Categories": [], "Characters": []},
	},
}
