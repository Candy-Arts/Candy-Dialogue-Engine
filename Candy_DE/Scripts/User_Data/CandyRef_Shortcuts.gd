#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends RefCounted


#^ Shortcut symbols - the symbol followed by a name reads that key from a target:
#? The target is any expression, without the expression symbol.
#?	"¥": "globals.inventory"
#?	"¢¥sword"       ->  globals.inventory["sword"]
#?	"¢¥\"old key\""  ->  globals.inventory["old key"]
const SHORTCUT_SYMBOLS := {
}


#^ Lookup symbols - the name alone reads the "keys" target:
#? Followed by '[' or '.', that value is looked up in the "entries" target.
#?	"¶": {"keys": "globals.equipped", "entries": "globals.items"}
#?	"¢¶hand"            ->  globals.equipped["hand"]               (e.g. "sword")
#?	"¢¶hand[\"damage\"]"  ->  globals.items[globals.equipped["hand"]]["damage"]
#?	"¢¶hand.damage"     ->  the same, with dot access
const LOOKUP_SYMBOLS := {
}
