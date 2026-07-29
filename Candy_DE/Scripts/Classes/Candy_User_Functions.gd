#!###########################################################################################
#!																							#
#!       THIS SCRIPT MAY CONTAIN CODE THAT IS THE INTELLECTUAL PROPERTY OF CANDY ARTS       #
#!                             Copyright © 2025-2026 Candy Arts                             #
#!																							#
#!    Such code may only be used in compliance with the appropriate Candy Arts licenses.    #
#!                Any unauthorized use may constitute copyright infringement.               #
#!																							#
#!###########################################################################################


extends "res://Candy_DE/Scripts/User_Data/Candy_Properties.gd"


#& DIALOGUE HISTORY:
#* Show one dialogue engine instance's history:
func open_instance_history(caller) -> void:
	await run_user_function("open_instance_history", [caller])


#* Show the general history:
func open_general_history() -> void:
	await run_user_function("open_general_history", [])


#& CLEAR VN BUSTS:
#* Clear VN busts when dialogue isn't running:
#? 'method' as in UI_Clear: 1 = clear silently, 2 = play each actor's Leave effect first.
func clear_busts_ood(caller, method: int = 1) -> void:
	await run_user_function("clear_busts_ood", [caller, method])


#& CLEAR BG LAYERS:
#* Clear BG layers when dialogue isn't running:
func clear_bg_layers_ood(caller) -> void:
	await run_user_function("clear_bg_layers_ood", [caller])
