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


#^ Player References:
#? Actor references that designate the player(s).
#? Wherever the engine treats NPCs and players differently.
var player_refs = ["Player", "player"]

#^ Player data:
#? The actors entry holding the player's data.
#? For variations based on player properties (e.g. player gender).
var current_player = "Player"
