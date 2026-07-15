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


extends AudioStreamPlayer

#^ Default extension for voice files:
@export var default_voice_extension = ".ogg"


var caller: Node



#* Hook function, called when writing begins:
func write_begun():
	pass


#* Hook function, called when writing finishes:
func write_finished():
	pass