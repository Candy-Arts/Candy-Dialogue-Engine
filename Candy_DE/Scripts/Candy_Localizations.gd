extends Node


#^ Actor display name localizations:
var display_names = {
#/ Example:
#/	"Display Name": {
#/		"Default": "Name"
#/		"French": "Nom"
#/	},

}

#^ Choice Lists localizations:
var choice_menu_titles = {
#/ Example:
#/	"Title": {
#/		"Default": "Title"
#/		"French": "Titre"
#/	},

}

var choice_menu_prompts = {
#/ Example:
#/	"Prompt": {
#/		"Default": "Prompt"
#/		"French": "Commande"
#/	},

}

var choice_category_titles = {
#/ Example:
#/	"Title": {
#/		"Default": "Title"
#/		"French": "Titre"
#/	},

}

var choice_category_prompts = {
#/ Example:
#/	"Prompt": {
#/		"Default": "Prompt"
#/		"French": "Commande"
#/	},

}

var choice_button_labels = {
#/ Example:
#/	"Label": {
#/		"Default": "Label"
#/		"French": "Nom"
#/	},

}

var choice_button_tooltips = {
#/ Example:
#/	"Tooltip": {
#/		"Default": "Tooltip"
#/		"French": "Infobulle"
#/	},

}


#^ Input UI localizations:
var input_instructions = {
#/ Example:
#/	"Instruction": {
#/		"Default": "Instruction"
#/		"French": "Consigne"
#/	},

}

var input_placeholder_texts = {
#/ Example:
#/	"Placeholder": {
#/		"Default": "Placeholder"
#/		"French": "Texte Provisoire"
#/	},

}

var input_default_texts = {
#/ Example:
#/	"Default Text": {
#/		"Default": "Default Text"
#/		"French":  "Texte Par Défaut"
#/	},

}

var input_blacklists = {
#? Array alues must be strings.
#? Unused if arrays are empty.
#? Add '*' suffix for partial matches (e.g. "Start*" will include "Starting" or "Starter")
#/ Example:
#/	"blacklist_1": {
#/		"Default": [word_1, word_2...],
#/		"French": [word_1, word_2...],
#/	},

	"void": {}	#/ Empty → no filtering for any language 
}

var input_whitelists = {
#? Array alues must be strings.
#? Unused if arrays are empty.
#? Add '*' suffix for partial matches (e.g. "Start*" will include "Starting" or "Starter")
#/ Example:
#/	"whitelist_1": {
#/		"Default": [word_1, word_2...],		
#/		"French": [word_1, word_2...],
#/	},

	"void": {}	#/ Empty → no filtering for any language 
}

var input_error_messages = {
#? Be mindful of spaces and punctuation at the start or end of strings!
#/ Example:
#/	"Error Message": {
#/		"Default": [word_1, word_2...],		
#/		"French": [word_1, word_2...],
#/	},

	"Special characters are not allowed.": {

	},

	"Punctuation is not allowed.": {
		
	},

	"Decimal numbers are not allowed.": {
		
	},

	"Numbers are not allowed.": {
		
	},

	"Lowercase letters are not allowed.": {
		
	},

	"Uppercase letters are not allowed.": {
		
	},

	"Spaces are not allowed.": {
		
	},

	"Forbidden word: '": {
		
	},

	"Word not allowed: '": {
		
	},

	"'.": {
		
	},

	"Maximum ": {
		
	},

	"Minimum ": {
		
	},

	" words allowed.": {
		
	},
	
	" words required.": {
		
	},
	

	
	" characters allowed.": {
		
	},
	
	" characters required.": {
		
	},
	
}