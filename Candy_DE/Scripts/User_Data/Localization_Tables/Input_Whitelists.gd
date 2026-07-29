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


#^ Input UI localizations:
#? Each word is a String, or [String, case_sensitive]. Empty arrays are unused.
#? '*' stands for any characters, anywhere: "Start*" matches "Starting", "*ing" matches "Starting", "S*g" matches "String".
#? '**' is a literal '*'. Words are compared case-sensitively; ["mean*", false] makes an entry case-insensitive.

#/ Example:
#/	"whitelist_1": {
#/		"Default": ["yes", "no", ["North*", false]],
#/		"French": ["oui", "non", ["Nord*", false]],
#/	},

var input_whitelists = {

	"void": {}		#/ Empty → no filtering for any language
}
