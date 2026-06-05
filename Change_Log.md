# Candy Dialogue Engine - Change Log

**Tags:**
(FIX)       - Bug fix.
(IMPROVE)   - Improvement that isn't a fix to an actual bug.
(CHANGE)    - Neutral change in the code.
(NEW)       - New feature was added
(MISSING)   - Missing feature was added.

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


