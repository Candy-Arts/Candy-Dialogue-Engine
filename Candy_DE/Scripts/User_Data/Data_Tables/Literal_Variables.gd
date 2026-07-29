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


#^ Literal variables:
#? Variables whose value is read as written, such as text the player typed: an expression never
#? evaluates a "¢…" stored in them, and wherever a text variable displays them, their text
#? variables, word substitutions, text events, lexicon escapes and BBCode are displayed as written.
#? A variable is matched wherever it's stored, however a line names it: "globals.player_name" also
#? covers ¤¢globals["player_name"]¤. What an expression computes from the value is read as written too.
#? A copy of the value in another variable is only covered if that variable is listed.
#? Each entry is a variable, or [variable, [allowed]] to let the value keep some syntax:
#?   "expressions", "text_variables", "substitutions", "text_events", "lexicon", "bbcode",
#?   "references" (a leading role symbol, where the value names an actor).
#? A key can be a pattern or a filter:
#?   candy_de.actors["Player_*"].DisplayName    keys matching the pattern (* and ?)
#?   candy_de.actors[String].DisplayName        keys of that type
#?   candy_de.actors[globals.slot].DisplayName  the key an expression gives
#? The Input scene's "Default_L" mode adds the variable it stores the player's input in.
#+ List the variables that hold text from outside your dialogues (a player's input, a server's reply...).
#+ Variables added while the game runs are only kept if your game saves this list.

#/ Example:
#/	"globals.player_name",										#/ read as written
#/	["globals.player_motto", ["bbcode", "text_variables"]],		#/ keeps its BBCode and text variables
#/	'candy_de.actors["Player_*"].DisplayName',					#/ every actor whose key starts with "Player_"
#/	"candy_de.actors[String].DisplayName",						#/ every actor with a String key
#/	"globals.saves[globals.slot].hero_name",					#/ the save slot globals.slot names

var literal_variables = [

]
