# Candy Dialogue Engine - Change Log

**Tags:**
(FIX)       - Bug fix.
(IMPROVE)   - Improvement that isn't a fix to an actual bug.
(CHANGE)    - Neutral change in the code.
(NEW)       - New feature was added
(MISSING)   - Missing feature was added.

-----

## 1.1.2
### Scripts
#### Candy_Engine.gd:
commands():
- (FIX) §Set and §Flag Commands: nested quotes inside expressions could cause conflicts. Typically this likely only happened if you tried combining two strings, for example: **"Wizard's" + " hat"** → was read as a single string: **Wizard's" + " hat**. The fix solves this, and it also makes the escape character (backslash \\) work (it may not have worked in some cases before). If you still encounter issues with Expressions, please let us know.

process_lines():
- (FIX) Fixed an error at Step 4 (variant selection). If random variants were enabled, the code was assuming a random variant in every case, even when none existed. It should work correctly now, but Step 4 is another part of the code where there can be a number of edge cases, so please let us know if you encounter other errors.

-----

## 1.1.1
### Scripts:
#### Candy_Engine.gd:
process_lines():
- (FIX) Fixed random variants with _TTS tag being selected as possible randomness options.
- (IMPROVE) Added logic to reject _TTS variants outright. This is just a precaution: the logic causes variants with the _TTS tag to be rejected for other reasons.

#### Effect_Player.gd:
- (FIX) Fixed the script still using var effect\_player\_path instead of var effect\_player\. This had previously been fixed in our development build, but we forgot to port the change over to the public release build.

-----

## 1.1.0.c
### Scripts:
- (CHANGE) All UI and Media Player scripts now take direct node references instead of string paths for required and optional nodes. **You will need to update your scenes to provide these direct node references!**

#### Candy_Engine.gd:
- (IMPROVE) Renamed the variable 'dialogue\_skip\_speed' to 'dialogue\_fast\_speed' to avoid confusion.
    - **MAKE SURE YOU UPDATE YOUR CODE IF IT REFERRED TO 'dialogue\_skip\_speed'!**
    - If you assigned a custom value to 'dialogue\_skip\_speed' you will need to re-assign that value to 'dialogue\_fast\_speed'.
- (IMPROVE) Added missing types to several exported variables.
- (NEW) Added the variable 'mouse\_mode\_choice' for selecting a default mouse\_mode for choice menus.

commands():
- (FIX) §Role was broken after a previous update, where we allowed roles to be used as variable references. This caused the §Role command to treat roles as variable references to be substituted with their assigned values. This has now been fixed.
- (FIX) §Elif and §Else may not have worked properly when nesting\_depth > 0. Added if\_array padding to solve this. Added if\_array cleanup in various places as well.
- (FIX) §Jump command was crashing when a line reference was provided.
- (FIX) §Bridge command was propagating "Continue" instead of "END" after an §End command.
- (FIX) §Bridge not reactivating §Choice_Lists correctly.
- (NEW) §Choice_List handles the new Menu shield during "Continue" choice select (see Choice Menu scene changes for details) and during timer timeout.
- (FIX) §Choice_List now correctly changes Mouse\_Mode when navigating to other categories.
- (FIX) §Choice_List Mouse\_Mode: "Default" doesn't change Mouse\_Mode (previously, it set to Visible).
- (IMPROVE): §Choice_List Mouse\_Mode: "Default" uses the engine instance's 'mouse\_mode\_choice' setting. Empty string doesn't change Mouse\_Mode. For categories: "Menu" uses the menu's' Mouse\_Mode.
- (NEW): §Mouse: supports 3 new options: "dialogue\_start", "dialogue\_end" and "choice". Each sets Mouse\_Mode to respectively match mouse\_mode\_start, mouse\_mode\_end and mouse\_mode\_choice engine settings.
- (FIX): §Input: fixed arguments order in input_instance.setup() call.
- (FIX): Fixed §Image, §Audio, §Video, §I\_Wait, §A\_Wait, §V\_Wait not handling Wait and Time properly.
- (FIX): Fixed §Video\_Wait trying to get video length by using the get\_length() instead of get\_stream\_length().
- (NEW): §Player\_Advance command: pauses dialogue until the player presses the dialogue\_advance key. Please be mindful that if input_enabled == false in the engine instance, or if there is no action (key) assigned for advancing dialogue, the dialogue will essentially freeze. The lack of safeguards is intentional: in some special cases, users might want to enable input or assign an action at a later point at runtime.
- (FIX): §Effect and §Effect_Wait now correctly handle pausing dialogue as defined by "Time" and "Wait".
- (IMPROVE): §CS\_Scene now supports providing custom names for each scene instance.
- (IMPROVE): §BG\_Stop, §VN\_Stop, §CS\_Anim\_Stop, §CS\_Sprite\_Stop: "Default" data: "0" = stop on current frame, "-1" = stop on last frame, "value above 0" = stop on that specific frame.
- (IMPROVE): §CS\_Anim and CS\_Sprite: removed the "Play" data key. Set "Loop" to "0" to stop on the first frame, or "-1" to play indefinitely.

start_dialogue():
- (IMPROVE) Added a warning print if dialogue is set to start at a Line Mark reference that doesn't exist.

process_lines():
- (CHANGE) Variables named 'match' were renamed to match\_num and match\_var to avoid conflicts with the match statement. This is just a good practice precaution: the original name did not seem to cause any issues.
- (NEW): Spoken Lines skipped due to non-matching dispositions can now count towards §Media_Pause line decrementation (var mp\_count\_dispositions)
- (NEW): Spoken Lines skipped due to no valid variant found can now count towards §Media_Pause line decrementation (var mp\_count\_variants)
- (IMPROVE): Improved the variant selection code to allow easy adding of tags (player\_tags and speaker\_tags dictionaries).
- (NEW): In variant selection code: tags can be designated to automatically pass (passed\_tags array) or always disqualify variants that include them (disabled\_tags).

display_line():
- (FIX) Bubbles pre-configuration: now correctly forces the use of speech bubbles based on actor or line override.
- (FIX) Bubbles mode: Now checks that each actor node has the internal\_node\_dict dictionary before clearing bubbles.
- (IMPROVE) When VN_\Bubbles mode is selected, added various checks that a VN scene is also loaded. If not, should default to bubble\_exempt\_mode in all cases as a failsafe.
- (FIX) Fixed Dialogue\_Skip, Dialogue\_Speed and Dialogue\_Slow not working since 1.1.

apply\_lexicon\_tags():
- (FIX) Fixed "Click_Data" from lexicon dictionary breaking the keyword formatting, and fixed issues with how data is formatted and passed when keywords are clicked.


#### Portrait.gd:
- (IMPROVE) The portrait box is now hidden when a portrait file can't be located. This avoids displaying an empty portrait box. Note that normally, if you don't want to show a portrait, you should change the engine settings or set the actor or the line overrides to forbid portraits. An error message will continue to be printed to warn you that a file couldn't be found.

#### Video_Player.gd:
- (IMPROVE) Now extends 'Control' by default (previous: 'VideoStreamPlayer').

#### Image_Player.gd:
- (IMPROVE) Now extends 'Control' by default (previous: 'TextureRect').

#### Audio_Player.gd, Audio_Player_2D.gd, Audio_Player_3D.gd:
- (FIX) In \_on\_finished(), changed 'stream = null' to 'audio_player.stream = null'. This would have caused issues if the script was assigned to a parent of the actual AudioStreamPlayer node.

#### Effect_Player.gd:
- (FIX) unpause(): changed effect\_player.pause = false to effect\_player.play().

#### Choice_Menu.gd:
- (IMPROVE) Node pointer variables are now @export, allowing to directly assign a node to them.
- (NEW) Added 'shield' variable pointer for the menu shield.

#### Choice_Category.gd:
- (IMPROVE) Node pointer variables are now @export, allowing to directly assign a node to them.

#### Choice_Button.gd:
- (IMPROVE) Node pointer variables are now @export, allowing to directly assign a node to them.
- (NEW) Added 'choice_button' pointer variable to point to the Button node.
- (IMPROVE) \_choice\_selected() function now releases focus on the button, to avoid accidentally selecting it when Dialogue_Advance or other input keys are pressed.

#### Input.gd:
- (FIX) check_input(): Fixed errors in print statements (integers not being converted to strings).

#### Backgrounds.gd
- (FIX) §BG_Effect: can now correctly play multiple animations simultaneously.

#### Bust_Scene.gd:
- (IMPROVE) Can now specify a custom name or path for speech bubble nodes in the exported speech\_bubbles\_name variable.
- (CHANGE) highlight\_speaker() and end\_highlight\_speaker(): all dialogue modes are now in the same match case, for out-of-the-box compatibility. Split them in separate match cases if you need different highlight behavior for each mode.
- (FIX) §VN_Effect: can now correctly play multiple animations simultaneously.
- (FIX) §VN_Move: animation not continuing after move for Sprite2D and Sprite3D nodes (missing code).
- (FIX) §VN_Move: sprite not being rescaled after move.
- (FIX) end\_highlight\_speaker() now plays the RESET animation.

#### Speech/Bark Bubble Scripts:
- (CHANGE) Changed override default text color to black.
- (FIX) Added missing code for applying override text color.
- (FIX) Large padding no longer causes additional empty lines.
- (FIX) \_ready(): fixed issues with how the meta\_clicked signal is connected and data is passed to \_on\_lexicon\_clicked().

#### Dialogue_Box.gd:
- (FIX) \_ready(): fixed issues with how the meta\_clicked signal is connected and data is passed to \_on\_lexicon\_clicked().

#### Subtitles.gd:
- (FIX) \_ready(): fixed issues with how the meta\_clicked signal is connected and data is passed to \_on\_lexicon\_clicked().

#### Chat_Box.gd:
- (FIX) \_ready(): fixed issues with how the meta\_clicked signal is connected and data is passed to \_on\_lexicon\_clicked().


### Scenes:
- (NEW) Choice Menu scenes now include a shield.

### 1.0 to 1.1 Patcher:
- (FIX) Patcher now renames 'Candy\_DE/Media/General/Backgrounds/Animation Libraries' to Animation\_Libraries (underscore instead of space).

### Guides:
- (CHANGE) Updated multiple guides.

-----

## 1.1.0.b
### 1.0 to 1.1 Patcher:
- (FIX) Fixed "Chat Speaker Color" in Candy_Databse.gd 'actors' dictionary accidentally changing to "ChatTextColor"
- (MISSING) Patcher wasn't adding 'var file\_var\_symbol = "¬"' to Candy_Properties.gd
- (IMPROVE) Changed the order that the User Data files are modified in, to avoid error messages. The files are now edited in the order they extend each other in, from top to bottom. These error prints weren't causing any actual problems once the patching process was finished. To clarify/for example: after modification, Candy\_Database.gd was looking for Candy\_Properties.gd in the User\_Data folder, before it was actually moved there. By changing the modification order, Candy\_Properties.gd is now already at the new location when Candy\_Database.gd is modified to look for it there.

### Installation Patcher
- (NEW) Created a patcher for installing Candy Dialogue Engine.
- Installation_Instructions.pdf has been updated accordingly.

### Guides:
#### 1. Basic Setup Guide.pdf
- (CHANGE) Removed the contents of the guide, as it is no longer needed.

-----

## 1.1.0.a
### Scripts:
#### Candy_Engine.gd:

Class variables:
- (NEW) Added the 'engine_language' exported variable:
    - Leave empty to use the main language (in Candy_Properties.gd)
    - Provide a value in the inspector to assign a specific language to a specific engine instance.
    - This new feature enables parallel dialogues in different languages.

§Flag command:
- (MISSING) Now calls a hook function (e.g. to update quest trackers).

§Export command:
- (NEW) Can now export dialogues as .txt files, using the standard dialogue format. Use "Dialogue" for the 'Format' data key.

§Import command:
- (NEW) Can now load dialogue .txt files to a dictionary.

§Jump command:
- (IMPROVE) Command no longer deletes Input UIs. This was inconsistent with our philosophy that Input UIs can be permanent in the background.
- (IMPROVE) Command deletes choice lists as a precaution.

§Input command:
- (FIX) Update var caller and var depth on the input UI if the UI already exists. This allows later §Input commands to properly reconnect with the UI no matter their depth or the engine instance they're in.
- (NEW) Added 5 custom data keys to §Input command, for additional configuration options.
- (NEW) Added "run\_lines" signal case to §Input command: runs a 'fake' Block. The input\_received signal's 'parameters' argument should be an array with dialogue lines.
- (NEW) Added "close" signal case to §Input command: exits the §Input command (like 'finished') but also deletes the input UI.

§CS_Visibility command:
- (FIX) Use the "Visibility" data key instead of "Status". This was a discrepancy between Candy DE and DC in 1.0, preventing the command from working.
- (IMPROVE) Added some extra possible values for "Status" for writer convenience - 'unhidden', 'invisible', 'swap' and 'switch'.

§CS_Look command:
- (NEW) Added §CS_Look command: makes Target nodes rotate to face towards Marker nodes.
    - If only one Marker provided: Targets all face the Marker
    - If multiple Markers provided: Targets and Markers are paired in order they are listed. Excess Targets are not rotated.

Various commands:
- (CHANGE) Updated commands to look for folders with underscores instead of spaces, where relevant (e.g. 'Sprite_Frames' instead of 'Sprite Frames').
- (CHANGE) All commands should now expect strings for all data keys.

load\_scripted\_dialogue():
- (CHANGE) Updated to work with the new 1.1 dialogue format.

start_dialogue():
- (IMPROVE) Now includes some safety measures to prevent running multiple simultaneous dialogues in the same engine instance:
    - Return if another dialogue is running,
    - If that fails, kill any dialogue still running.
    - Reset engine variables in case a previous dialogue didn't end properly.<br>
    *NOTE: the reset may not be enough to reset everything properly; but if the reset is required in the first place, something is wrong regardless.*
- (New) Set the engine instance language or the general language.

display_line():
- (FIX) Fixed "Chat" mode using subtitle_speaker_color instead of chat_speaker_color in one place.
- (FIX) Fixed a missing 'await' in "VN\_Bubbles" mode when calling show\_text() on the VN\_Bubble. Probably isn't needed as the text would display instantly, but it's there as a precaution.
- (CHANGE) Updated function to read "ForceBubbles" instead of "BubbleExempt" data key.
- (CHANGE) Updated function to make adding Dialogue\_Skip, Dialogue\_Speed and Dialogue\_Slow to the Input Map optional.

end_dialogue():
- (IMPROVE) now resets various engine variables as a precaution. Those variables should normally reset before end_dialogue() is called.

resolve\_value() and \_set\_file\_variable():
- (NEW) Updated to allow using v\_res:// and v\_user:// in line data. These methods save/read variables to/from external files.

decode\_variable\_name():
- (NEW) Allow referencing 'self' as an autoload.

calculate_variable_value():
- (NEW) Added new operators: randi\_range, randf\_range, var\_to\_str, str\_to\_var, json\_to\_str, str\_to\_json, var\_to\_bytes, bytes\_to\_var, type\_string, is\_nan, is\_inf, split\_to_array (like split() but convert to a regular array directly).
- (IMPROVE) Added zero-guard or negative guards to some operators, to avoid divide by 0 or other crashes:
- (IMPROVE) Renamed rand\_i and rand\_f to 'randi' and 'randf' (the old spelling still works: older dialogues are fine)
- (NEW) randi and randf used to require the value to be a range. Now, if value is empty, they pick any number at random like GDScript randi() and randf() do. The new randi\_range and randf\_range should be used from now on; randi and randf continue to work with ranges for backward compatibility so old dialogues don't break.
- (NEW) Added randi\_range and randf\_range, the new 'correct' operator for picking a value at random from a range.
- (IMPROVE) 'get' will now accept two values: the variable whose value to get, and a default value to use if the variable doesn't exist. Previously, it couldn't be given a default value and defaulted to null.
- (IMPROVE) Modified most operators to work with or without a value. If a value is provided, the operator works on the value before it's assigned to current. If no value is provided, the operator works on current's value directly.
For example, if you use to_int with a value, the value is converted to int then assigned to current. If the value is empty, current's value is converted to int. This lets you modify variables in ways that GDScript doesn't do.
This shouldn't break old dialogues: previously, you wouldn't have used these operators without values as they wouldn't do anything.

NOTE: Always test any operators before using them, to make sure they work as expected. They should work, everything appears fine, but it's one of these places where edge-cases can never be ruled out with 100% confidence.

NOTE: We don't recommend using the 'candy_' operators at this time. We want to give them further testing before we are confident they work consistently. They may be modified in the future and could yield different results than expected. To discourage their use, these operators are not listed in Candy DC.

#### Candy_Database.gd
- (CHANGE) Edited the path the script extends from to include "User_Data".

- (CHANGE) - Renamed several actor keys in the 'actors' dictionary: If you used those keys in your own code, you must rename them!
    - "Bubble Exempt" → "BubblesOverride" (also changed values: true → -1, false → 0)
    - "Portrait" → "PortraitOverride"
    - The following keys were modified to have spaces removed: "Short Name", "Display Name", "Speaker BBCode", "VN Join Effect", "VN Move From Effect", "VN Move To Effect", "VN Leave Effect", "Box Text Color", "Box Speaker Color", "Subtitle Text Color", "Subtitle Speaker Color", "Bubble Text Color", "Chat Text Color", "Chat Speaker Color". 

WARNING: If you referenced these keys in your code or in dialogue lines, you must rename them.

NOTE: We expect all keys in the actors dictionary are now future-proof and we will never need to modify them again.

#### Candy_Functions.gd
- (CHANGE) Edited the path the script extends from to include "User_Data".
Added the x_flag_changed() hook function for the §Flag command.

#### Candy_Properties.gd
- (CHANGE) Edited the path the script extends from to include "User_Data".
- (CHANGE) Edited the resource path variables to replace spaces with underscores (e.g. 'Background_Scenes' instead of 'Background Scenes').

#### Backgrounds.gd
- (CHANGE) Replaced spaces with underscores in Media folders (e.g. 'Button_Textures' instead of 'Button Textures').
- (CHANGE) Fixed the TextureButton image logic to match the documentation.

#### Bust_Scene.gd
- (CHANGE) Replaced spaces with underscores in Media folders (e.g. 'Button_Textures' instead of 'Button Textures').
- (CHANGE) Fixed the TextureButton image logic to match the documentation.

#### Portrait.gd
- (CHANGE) Replaced spaces with underscores in Media folders (e.g. 'Button_Textures' instead of 'Button Textures').
- (CHANGE) Fixed the TextureButton image logic to match the documentation.

#### Input.gd
- (NEW) Added the new 5 custom data keys as arguments to the setup() function.

### Media Folders
- (CHANGE) All folders have been renamed to replace spaces with underscores.
    - This is a precaution to avoid bugs on different Operating Systems and for future-proofing.
    - It is not required that you modify your own custom folders in this manner.


