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


#^ Text Events:
#? Events any spoken line can run at the markers in its text ("Wait‡boom‡... what?").
#? A line's own Text_Events come first: only events it lacks for its variation are looked up here.
#?
#? Sorted by variation, as in the Lexicon:
#?   "*"         every variation
#?   "Default*"  every variation starting with "Default"
#?   "Default"   that variation only
#? The most specific entry holding the event wins.
#?
#? Each event:
#?   "Lines"         lines to run, in order, written as in a dialogue file. Only the commands
#?                   text_event_commands allows (Candy_Properties.gd).
#?   "Run_On_Skip"   "1" (default): when the writing is skipped, run it without its waits; "0": don't run it.
#?   "Pause_Voice"   "1" / "0": pause the voice while it runs. Left out: the engine's, then Candy_Properties.gd's.
#?   "Resync_Voice"  "1" / "0": re-sync voice-synced writing after it. Left out: as above.

#/ Example:
#/	"*": {
#/		"boom": {
#/			"Lines": [
#/				{"Media_Play": {"Players": {"Sound": {"File": "Explosion"}}}},
#/				{"Write_Pause": {"Wait_Time": "0.6"}},
#/			],
#/			"Run_On_Skip": "1",
#/		},
#/	},

var text_events = {
	"*": {				#/ For all variations.
	},
}
