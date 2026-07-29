# Candy Dialogue Engine 1.2.0 — Upgrade Log

Everything that changed between Candy Dialogue Engine 1.1.3 and 1.2.0: new features, changed features and bug fixes.

Candy Dialogue Engine 1.2 requires **Godot 4.7 or newer**.

Dialogues written for 1.1.3 use a different format and must be converted before 1.2 can run them. The Dialogue Converter of the Wizard or Candy Dialogue Creator rewrites them, and lists every Line whose behaviour it couldn't preserve. The format changes it handles are listed under [Changes](#changes) for reference.

- [New Features](#new-features)
- [Changes](#changes)
- [Bug Fixes](#bug-fixes)

---

## New Features

### Candy Database
Candy Database is a new plugin we created: it allows displaying documentation inside the Godot Editor in a database format.
It's separate from Candy Dialogue Engine, but it's worth mentioning because the user documentation is now accessible there.

Note that Candy Database is published under MIT license, in case other addon creators wish to use it for their own documentation. Users only need to add Candy Database once in their Godot project, and documentation databases can be added by dropping them in a folder.


### Candy DE Wizard
The Candy DE Wizard is a plugin for Godot: like a regular plugin, it goes in your addons folder and is enabled in the editor settings. It's then accessed in the bottom dock of the Godot editor.

- **Installation:** the Wizard downloads and installs Candy Dialogue Engine from the latest GitHub release or from a zip file, with an optional backup of the project, and sets up the autoloads and input actions. It can also install from a zip file you manually downloaded.

- **Updates:** the Wizard can download and update Candy Dialogue Engine to newer versions, including 1.1.3 to 1.2.0. It replaces the engine files, lists the ones you modified before overwriting them, and never overwrites the files meant to be customized: your settings, data tables, hooks, `Default.tscn` scenes, `Candy_UI.tscn` and animation libraries.

- **Self-Updating:** the Wizard is also capable of updating itself when we release a new version.

- **Safety:** every release is signed, and the Wizard verifies every file before installing it. The installation/update process features reminders and prompts to back up your project. An installation that fails is rolled back. Everything is downloaded from our GitHub repositories, not from our own website or servers.

- **No dependency:** after installation, Candy Dialogue Engine runs without the Wizard. We don't recommend removing the Wizard as it provides helpful features and has no downsides, but Candy Dialogue Engine won't break if you do.

- **Documentation:** the Wizard can download Candy Database to your project, then download and update the documentation for Candy Dialogue Engine and Candy Dialogue Creator. This ensures you always have the latest version available.

- **Dialogue Testing:** Candy Dialogue Creator's "Test" button now not only exports a test dialogue to your project, but also runs the test immediately, in your chosen testing scene, through the Wizard. The Wizard UI also provides a feature to configure and run tests in any testing scene, without having to open the scene in the Godot editor.

- **Data and hooks at hand:** the Wizard lists your data tables, Localization Tables, hook arguments and hook functions, and opens any of them in the script editor in one click.

- **Folder generation:** the Wizard can creates the media folders your project needs from your data: Actors, media player and background layer names in your Background scenes. It can also generate voice folders based on your chosen hierarchy (see the Voice section further down), and move your existing voice files when you change the hierarchy.

- **Symbol changes:** change Candy Dialogue Engine's syntax symbols without breaking your Dialogues: the Wizard displays every symbol with a description and examples, and when you change one, it rewrites that symbol in your Dialogue files.

- **Dialogue conversion:** the Wizard can convert 1.1.3 Dialogues to the 1.2 format, and lists every Line whose behaviour it couldn't preserve.

- **News:** the Wizard displays news from Candy Arts, such as new releases, downloaded from our GitHub repositories.



### Extensibility
A big part of 1.2.0 was making the code more modular, so that additions or modifications would be easier to make and would be better preserved between updates.

- **Persistent customizations:** add your own Commands, dialogue modes and events without modifying a single Candy Dialogue Engine file, so your additions survive every update. Each addition is a script placed in its folder, found automatically, with nothing to register:
  - Commands (`Scripts/Commands`).
  - Dialogue modes (`Scripts/Dialogue_Modes`).
  - Events of Input scenes (`Scripts/Input_Events`) and of choice menus (`Scripts/Choice_Events`).
  - Reactions to the signals an Await command waits for (`Scripts/Await_Events`).
  - Values of the Custom command (`Scripts/Custom_Events`).
  - Movements of the CS\_Move command (`Scripts/Move_Events`).
  - Variation tags decided by your game code (`Scripts/Variation_Tags`).
  - Data tables, Localization Tables and hook functions (`Scripts/User_Data`).

- **Overriding Commands:** replace a built-in Command with your own version: a Command script with the same name as a built-in Command is used instead of it.

- **Several scripts per hook:** separate systems of your game can each respond to the same hook in a script of their own, instead of sharing one function: for example, an achievements script and an analytics script can both implement `x_new_line`, and both run.

- **Custom media players:** create your own media players, such as a music player that crossfades between tracks or a TV screen in a 3D scene, and control them with the `Media_` commands: any node whose script has the player functions can be listed as a media player. A player's entry in a `Media_` command can also contain settings of your own, which Candy Dialogue Engine passes on to your player, such as the length of a crossfade.

- **Custom Line data:** attach your own data to any Line, or to any entry inside it (a media player, a choice, a Variation), for your code to read: a camera angle, an analytics tag, a controller vibration. Candy Dialogue Engine never reads it, and passes it to every hook and to every UI Element and media player function the Line calls.

- **Hook arguments:** add your own arguments to hook functions without editing the calls, and without risk of conflict when a future update adds or removes Candy Dialogue Engine's own arguments. Arguments are sorted in 1 dictionary and 2 arrays: Candy Dialogue Engine's arguments, your arguments, and custom data you added to a Line. Your arguments for each hook are listed in a dictionary, and hooks are called through a function that passes them.

- **Startup checks:** setup mistakes are reported when the game starts, instead of failing silently later: a misspelled data table or hook, two scripts with the same name, a media player owned by two Engines.

- **Mod support:** mods can add Commands, dialogue modes and other scripts while the game runs, since script folders can be scanned again at runtime.


### Expressions and Variables
CandyRef, Candy Dialogue Engine's new expression language, replaces the variable reference/expression parsing system of 1.1.3. Like its predecessor, it allows Candy Dialogue Engine to reference variables or parse expressions at runtime, but now with more power, ease of use and reliability!

- **One symbol:** a single symbol, `¢`, written once at the start of an expression, replaces the reference symbols of 1.1.3 (`£`, `$`, `v_res://`, `v_user://`...). References inside an expression no longer need a symbol each: `£globals.gold > 5 and £globals.day == 2` is now written `¢globals.gold > 5 and globals.day == 2`.

- **No more super symbols:** the super symbols (`££`, `$$`...) are gone: they're now unnecessary and this makes things simpler for users.

- **Recursive parsing:** when a variable reference resolves to another expression, that expression is now evaluated in turn, and so on until reaching a value that isn't an expression. Circular references are detected and reported.

- **Function and method calls:** expressions can call functions and methods, which 1.1.3 couldn't: `¢globals.inventory.count("Potion") >= 3`.

- **GDScript syntax:** expressions are written as in GDScript, even more closely than in 1.1.3: nodes are written `$UI/Box` or `%Unique`, dictionary entries can be read with a dot (`actor.Age`), and engine classes and `class_name` scripts are written by name. And as mentioned previously, variable references don't need to be prefixed systematically.

- **Shortcut & lookup symbols:** assign your own *shortcut symbols* to the variables you reference most, similar to the vardict symbol (`€`). For example, with `¥` assigned to `globals.inventory`, `¢¥sword` reads `globals.inventory["sword"]`. If you want behavior similar to the role symbol (`°`), assign a *lookup symbol* instead. Just like `¢°companion.Age` reads the age of the Actor assigned to the `companion` Role, `¢¶hand.damage` could read the damage of the item equipped in the hand.

- **Literal variables:** add a variable to the `literal_variables` list, and its value is always displayed literally: syntax symbols in it are displayed as written, never read as expressions, text variables or formatting. This is useful for text typed by the player, such as a name.

- **Operators without a value:** `Set` and `Flag` operators that need no value, such as toggling a boolean, can now be written without one.

- **Errors:** a broken expression is found quickly: the error points at the exact character, and names the Conversation, Block and Line.


### Settings
- **Overrides at every level:** nearly every Engine setting where an override is relevant can now be overridden at several levels: UI Elements and media players, Actors, media files and Lines. In 1.1.3, most settings existed only on the Engine, and Actors and Lines could only override portraits, bubbles, TTS and LLM.

- **New Engine settings:**
  - Speech display: the speaker's name in the dialogue box text (`box_show_speaker`, with a prefix and a suffix), self-clearing dialogue boxes, portraits and subtitles (`box_self_clear`, `box_portrait_self_clear`, `subtitles_self_clear`), and the auto-advance character multiplier (`auto_advance_per_character`).
  - Chat: alignment, name and portrait display, portrait mode, reserved name and portrait space, Chat\_Line and separator scenes, and clearing when a Dialogue starts.
  - Lexicon: Lexicon keywords replaced before TTS reads a Line in Voice mode (`lexicon_voice_mode`).
  - Text Events: whether a Text Event pauses the voice, and whether writing synchronized to the voice is synchronized again after it (`text_events_pause_voice`, `text_events_resync_voice`).
  - Media: a default file extension and frame rate for each kind of media, the memory budget of image-sequence animations (`animation_folder_cache`, `animation_folder_stream`), and whether the Engine suspends and stops the Public players it holds (`suspend_held_media`, `end_held_media`).
  - Busts: Leave effects played when busts are cleared at the end of a Dialogue (`jml_on_end`).
  - Engine Commands: whether their changes are reverted when the Dialogue ends (`revert_engine_settings`).
  - Debugging: step-by-step logging in debug builds (`debug_prints`).


### Spoken Lines
- **Text Events:** Spoken Lines can now run Commands while they are written: insert markers in the text, like `‡boom‡`, which run Dialogue Commands when the typewriter effect reaches them. For example, a sound effect on a word. Three new 'hidden' Commands, which only work inside Spoken Line events, allow you to change the speed or pause the typewriter, and to alter portraits mid-sentence: `Write_Speed`, `Write_Pause` and `Line_Portrait`.

- **Bare tags:** switch Variations on and off with a tag that needs no value: a tag written alone (`Default_Shout`) is picked when it is passed.

- **Passed and disabled tags:** force or forbid Variations for a single Actor or Line: Actors and Lines can override the Engine's passed and disabled tags.

- **Expressions as text:** generate a Line's whole text from your game code: spoken text starting with `¢` is evaluated by CandyRef, and its result is displayed.

- **Escaped symbols:** syntax symbols can now be escaped, to display them as literal text, by writing them twice (`¤¤`, `••`, `‡‡`, `¬¬`).

- **Lexicon escapes:** exclude part of a text from the Lexicon with new symbols, such as a name that matches a glossary term: text between the Lexicon escape symbols (`¬Alice¬`) is never formatted, and the symbols aren't displayed.

- **Lexicon word rules:** the characters that count as part of a word, which decide where a keyword starts and ends, can now be set per language. In 1.1.3 they were fixed to ASCII letters, digits and `_`.

- **Disabled Lexicon text:** keywords can now display substitute text when the Lexicon is turned off. This is useful if you used a keyword like `c_June` to avoid mixing up the month and an NPC of the same name: it can now display as "June" even with the Lexicon disabled.

- **Auto-advance character multiplier:** auto-advance now has two duration settings: a fixed duration, as in 1.1.3, and an extra multiplier duration added for every character displayed on screen: `base duration + multiplier duration * characters`. Spoken Lines can now stay on screen relative to the length of their text.

- **Dialogue box in-line speaker:** dialogue boxes can now display the speaker's name in-line with the spoken text, like Subtitles.

- **End-of-line string:** the string displayed at the end of a Spoken Line can now be replaced once the player advances, for example to stop it blinking or to hide it. It is also placed outside the text's formatting, so it no longer takes the text's color.

- **Sanitization:** display player-provided text, such as the player's name, safely: values from outside the Dialogue can be automatically sanitized, so that any syntax symbols they contain are escaped and displayed as literal text instead of being read as expressions, text variables, word substitutions or text events. BBCode tags can also be sanitized, and values can be Lexicon-escaped to avoid unintended formatting if they accidentally happen to match a keyword.


### Dialogue Modes
- **Modes as scripts:** dialogue modes are now individual scripts, so a mode you add is a file of its own and is no longer overwritten when you update to a newer version of Candy Dialogue Engine.


### Engine Commands
A new category of Commands changes the settings of the Engine running the Dialogue, from inside the Dialogue. In 1.1.3, this required a Set command on the Engine's properties.

- **Engine\_Language:** changes the Engine's language. Choice menus and Input scenes that are open switch to it as well.

- **Dialogue\_Mode:** changes the Engine's dialogue mode and bubbles exempt mode.

- **Engine\_Writing:** changes the Engine's writing speed, its fast and slow continue speeds, its auto-advance durations, and its voice synchronization settings.

- **Reset:** Each of these commands allow resetting the settings to the Engine's original value when Dialogue started.

- **Automatic revert:** Each of these commands provides the option to revert the changes it made when Dialogue ends, so that one Dialogue doesn't alter the settings for the next one.


### Chat
The Chat mode and UI have been completely remade, to provide a proper Chat-style experience:

- **Modular UI:** the Chat UI is made of multiple scenes, each designed freely. A *Chat\_Box* contains one or more *Chat\_Channels*. Each channel displays its respective Engine's Spoken Lines, and every Spoken Line in a *Chat\_Line* scene: the text, with optional speaker label and portrait - like mini dialogue boxes. A *Chat\_Separator* scene can be inserted between the Lines of two Dialogues displayed in the same channel.

- **Full history:** players can scroll back through all previous Chat Lines.

- **Layout:** Chat Lines can be aligned left, right or alternate, with speaker label and portrait on either side. Portraits can be displayed on every Line or only when the speaker changes.

- **Per-Line scenes:** style individual Lines differently, such as a system message or different background colors for Actors: each Actor or Spoken Line can be made to use its own Chat\_Line scene.


### Portraits
Animated portraits are now configured per Spoken Line, through data fields of the Line.

- **Chat portraits:** Chat Lines display portraits, with their own portrait mode.

- **Loops:** an animated portrait can now play a set number of times. In 1.1.3, it either played forever or displayed its first frame, depending on the node displaying it.

- **Play duration:** an animated portrait can also play until the Spoken Line's voice ends, until the player advances, or until another Spoken Line replaces it. An alternate value can be provided in case the Spoken Line can't find a voice file to play.

- **Stop frame:** the frame an animated portrait stops on can be chosen, such as a closed-mouth expression, or the portrait can be removed when it stops.

- **Several SpriteFrames per Actor:** an Actor can have several SpriteFrames files (moods, outfits), and each Spoken Line selects the one its portrait plays.


### Voice
- **Positional voices:** each dialogue box, subtitles, chat channel and speech bubble now has its own voice player. Among other things, it enables playing voice from the speaker's position in 2D or 3D environments.

- **Configurable voice paths:** organize voice files in whatever folder hierarchy suits your project: by Actor, Dialogue, Conversation, Block and/or Line. For example:
  - `{actor}/{dialogue}/{conversation}/{block}`
  - `{conversation}/{actor}`
  - `{conversation}_{block}/{line}`
  - Or any other combination you want, with each tag optional.

- **Voice language:** the voice language can now be set apart from the text's, so players can choose, for example, Japanese voices with French text.

- **Fallback language:** a Line whose voice file is missing in one language can play another language's file instead, so a translation can be released before all of its voices are recorded.

- **Custom TTS modes:** connect any TTS solution, with modes of its own, through the `tts` hook. The TTS text resolves text variables and Word Substitutions like the displayed text.


### Choices
- **Hiding during transitions:** a `Choice_List` menu can now be hidden while the Lines of a Continue choice or a timer run, revealing the scene behind it. In 1.1.3, the menu remained on screen, blocked, until those Lines were over.

- **Animated menus:** a `Choice_List` menu can now play an animation each time it is hidden or shown again, such as when a nested menu opens over it, and the Dialogue waits for the animation to finish. In 1.1.3, only the menu's opening could be animated.

- **Live translation:** open menus now update their texts when the language changes. In 1.1.3, a menu remained in the language it was opened in.

- **Return levels:** a Return choice now returns from Bridges, and Return choices and the `Return` command can return from several nested sub-conversations in one step.

- **Menu events:** the events a menu sends to its Dialogue are now individual scripts, like Commands, so you can add your own. A new event, *suspend*, lets a menu suspend the Dialogue, for example to open an inventory screen.

- **Parallel menus:** Dialogues running in parallel can now each display their own menus at the same time. In 1.1.3, ending one Engine's Dialogue closed the menus of every Engine.


### Player Input
- **Input events:** the events an Input scene sends to its Dialogue (finish, close, run Lines) are now individual scripts, like Commands, so you can add your own. A new event, *suspend*, lets an Input scene suspend the Dialogue.

- **Input location:** the `Input` command can now instantiate its scene under any node, such as inside the game world. In 1.1.3, it was always a child of the Engine's input node.

- **Input scenes from any folder:** the `Input` command accepts a full scene path, not only the name of a scene in the input menus folder.

- **Sanitized text input:** the text input template now sanitizes what the player types before storing it, so a name or any other text is never read as Candy Dialogue Engine syntax. It has three modes: sanitized, literal (stored as typed, and always displayed as written) and unsanitized.

- **Live translation:** open Input scenes now update their texts when the language changes.

- **Parallel Input scenes:** Dialogues running in parallel can each have their own Input scenes open. Each Engine only closes its own when its Dialogue ends.


### Media and Effects
Audio, video, images, effects, backgrounds, VN busts and cutscene animations now share one playback system, so they are controlled the same way and gained the same features.

- **Media commands:** the `Audio_`, `Video_` and `Image_` commands were merged into the `Media_` commands (Play, Wait, Pause, Resume, Stop, Volume, Skip), which control every kind of media player.

- **Several targets per Command:** the Media, Effect, BG, VN and CS commands can now act on several players, layers, Actors or nodes at once, each with its own settings. In 1.1.3, the media and effect commands, `BG`, `VN_Bust` and `VN_Move` took a single target, and the other BG, VN and CS commands applied the same settings to every target.

- **Pause, resume and skip everywhere:** effects, backgrounds, VN busts and cutscene animations can now be paused, resumed and skipped, like audio and video, through new `_Pause`, `_Resume` and `_Skip` commands in the `Effect_`, `BG_`, `BG_Effect_`, `VN_`, `VN_Effect_`, `CS_Anim_` and `CS_Sprite_` families.

- **Skipping images:** `Media_Skip` now works on animated images too.

- **Pause loops:** media paused by a `_Pause` command can now continue to loop a segment of itself (a few bars of music, a breathing animation) instead of freezing, for example to let cutscenes or such continue to feel alive while waiting on player input or other commands. Audio and video can also play at a different volume while paused.

- **Playback controls:** through the `_Play` and `_Stop` commands, media playback can now stop part-way through a loop, end on a chosen frame, or be scheduled to stop after a number of loops or a duration.

- **Reset on stop:** an effect stopped by its `_Stop` command can now return to its rest pose, by playing its `RESET` animation. In 1.1.3, it remained in whatever pose it had reached.

- **Frame-accurate times:** times written in frames now count the media's own frames, for every kind of media, and every skip can move by a number of frames from the current one. In 1.1.3, only videos counted their own frames; everything else counted 30 per second.

- **Private and Public players:** media players are now defined as Private or Public, so Dialogues running in parallel can safely share players without fighting each other. A Private player obeys only the Engine that owns it. A Public player is available to any Engine, and can have rules set to determine what other Engines can do with it while it's already in use. Background and bust scenes follow the same rules.

- **Shared animation libraries:** the `Effect_Play`, `BG_Effect_Play` and `VN_Effect_Play` commands can now load animation libraries from a shared folder, from a path or from an expression, so the same effect animations can be reused on every player.

- **Frame rates and extensions:** each kind of media now has its own default file extension and frame rate, set once for the project and overridable down to the Line. In 1.1.3, each scene had its own defaults, which differed from one scene to another.

- **Streamed image sequences:** We finally got around to improving the performance of our custom Animated Folder feature: instead of loading all frames at once in memory, frames are now loaded in the background as the animation plays. Settings allow you to configure how many frames to load at once, or how much memory to use.

- **Folder settings:** a `config.txt` file in a media folder can now set the default extension and frame rate of its files, how Animated Folders are loaded, and settings for individual files. In 1.1.3, it only set the frame rate of an Animated Folder.

- **Animated button states:** an Animated Folder displayed on a TextureButton can now hold an Animated Folder for each button state (pressed, hover, disabled, focused), played in sync with the main one. In 1.1.3, button states could only be still images.

- **Loaded textures:** backgrounds, busts and portraits can now display a texture returned by an expression, not only a file name or a path.

- **Scene changes:** `BG_Scene` and `VN_Scene` accept a scene returned by an expression, and an empty value removes the scene. A scene that fails to load no longer removes the current one.

- **Default files:** a missing media file now displays the folder's `Default` file instead of nothing.

- **External files:** images, audio and video can now be loaded from outside the build (`user://`), for DLC, patches or mods. In 1.1.3, only files inside the project were found.

- **Z-order control:** the new `UI_Z` command sets the z-order of any node (a UI Element, a media player or any other node) to a fixed value, or relative to another node, such as one step above a video. It replaces `Hide`, `V_Show` and `I_Show`, which could only place the dialogue box, subtitles and chat one step above a video or image, or back to their default.


### Visual Novel Busts
- **Swapping Actors:** the new `VN_Swap` command makes two Actors swap busts in a single Line.

- **Grouped entrances and exits:** Actors joining, moving or leaving through `VN_Play`, `VN_Move`, `VN_Swap` and `VN_Remove` can now play their effects together or in sequence, in customizable order.

- **Uninterrupted busts:** moving or swapping a bust no longer restarts it: its animation, effects, pause loops and scheduled stops continue.

- **Effects per Line:** a Line can play its own Join, Move or Leave effect for an Actor, instead of the Actor's usual one, on `VN_Play`, `VN_Move`, `VN_Swap` and `VN_Remove`.

- **Clearing with Leave effects:** `UI_Clear` can now play each Actor's Leave effect before clearing the busts.


### Cutscenes
- **Progressive changes:** the `CS_Light`, `CS_Position` and `CS_Look` commands can now change lights, positions and rotations over time or at a set speed, without creating animations, and the Dialogue can wait for the change to finish.

- **Separate rotation:** when the `CS_Position` command moves nodes to a position, their rotation can now have its own time or speed instead of following the movement.

- **Level looks:** nodes rotated by the `CS_Look` command to face a target can now ignore the height difference, making them turn without tilting up or down.

- **Movement scripts:** `CS_Move` now runs your game's own movement code (pathfinding, walk animations), as one script per kind of movement, and every target moves at once. In 1.1.3, `CS_Move` was an empty case in the Engine's code, to fill in.


### Data and Localization
- **Translated names:** Actor names are now translated each time they are displayed, so a language change applies to them immediately. In 1.1.3, the Name command translated a name only once, when it ran.

- **Saving Nodes and Resources:** `Export` now saves Nodes and Resources as references, which `Import` restores. In 1.1.3, they were saved as text that couldn't be read back.

- **History markers:** the text the dialogue history inserts when a Dialogue ends, jumps, bridges or returns can now be customized.


### Engine
- **Interrupting:** game code can now stop a running Dialogue cleanly, for example when combat starts, and wait until it has ended (`interrupt_dialogue()`). A second function stops it at once, even while it waits for a signal, an Input scene or a choice (`raise_killswitch()`).

- **Language refresh:** a language change made by game code during a Dialogue now applies at once, to the running Engine and to its open menus and Input scenes (`refresh_language()`).

- **New hooks:** new hooks run your code when a Dialogue starts, is suspended or resumed, when it jumps, bridges, returns or ends, when the player advances a Spoken Line, when a choice is selected or a choice menu closes, when a Lexicon keyword is hovered, on every character the typewriter writes, and when media starts or finishes playing, including backgrounds, busts and cutscene animations.

- **New signals:** new signals are emitted when a Dialogue has fully ended and when it resumes from suspension. Game code can connect to them to react to these moments, for example to give the player control back once a Dialogue is over.

- **Unknown Commands:** a misspelled or unknown Command is now reported with its Conversation, Block and Line, then skipped. In 1.1.3, it was ignored silently.

- **Debug logging:** each Engine can now log what it runs, step by step, in debug builds.

- **Testing scene:** the testing scene now has buttons to suspend, resume and interrupt the running Dialogue.

---

## Changes
Changes to existing features, which can affect a project upgraded from 1.1.3. The Dialogue Converter applies the changes to Dialogue files.

### Installation and Project Structure
- **User data split into folders:** each data table, Localization Table and hook is a script of its own, in `User_Data/Data_Tables`, `User_Data/Localization_Tables` and `User_Data/Functions`, so updates can add new ones without touching yours. They replace `Candy_Database.gd`, `Candy_Localizations.gd` and `Candy_Functions.gd`. `Candy_Properties.gd` remains.

- **Renamed media folder:** `Media/Characters` is now `Media/Actors` for consistency across Candy Dialogue Engine.

- **Renamed scripts:** `Dialogue_Box.gd` is now `Box_UI.gd`, `Subtitles.gd` is `Subtitles_UI.gd`, `Backgrounds.gd` is `BG_UI.gd`, `Bust_Scene.gd` is `VN_UI.gd`, `History_Display.gd` is `History_UI.gd` and `Input.gd` is `Input_UI/Input_Text.gd`.

- **Portrait merged into the dialogue box:** the separate portrait scene is gone, and the portrait nodes are part of the dialogue box. It should still be possible to make portraits work separately from the dialogue box, but it's no longer the default.

- **Scene folders:** `Candy_UI.tscn` moved to `Scenes/Dialogue_UI`, and the testing scene to `Scenes/Testing_Scenes`.

- **Export folder:** the default export folder, for the `Export` command, is now `user://Candy_DE/Exports`, which remains writable in exported games.

- **Text nodes:** the text and speaker name nodes of UI Elements must be RichTextLabels. A Label assigned in 1.1.3 loses its assignment.

- **Voice nodes:** dialogue boxes, subtitles and bubbles each need a voice player node, or they play no voice.

- **Default z-order:** the background scene's default z-order is now 25, and the bust scene's 50. In 1.1.3, both were 100, which changes the layering of an upgraded project that kept the defaults.

- **Moved data:** the general dialogue history moved to `Candy_Properties.gd`, and the current player to the Player References table. The lists used by Candy Dialogue Creator 1.1 are removed.


### Dialogue Files
- **Renamed Commands:**
Commands lose the `§` prefix and various commands were renamed for consistency or accuracy:
  - `Spoken Line` → `Spoken_Line`
  - `Clear` → `UI_Clear`; `Hide`, `V_Show` and `I_Show` → `UI_Z`.
  - `Audio`, `Video` and `Image` and their helpers → the `Media_` commands.
  - `Effect` → `Effect_Play`, `BG` → `BG_Play`, `BG_Effect` → `BG_Effect_Play`.
  - `VN_Bust` → `VN_Play`, `VN_Bust_Wait` → `VN_Wait`, `VN_Bust_Stop` → `VN_Stop`, `VN_Effect` → `VN_Effect_Play`.
  - `CS_Anim` → `CS_Anim_Play`, `CS_Sprite` → `CS_Sprite_Play`, `CS_Loc` → `CS_Position`.

- **Underscores in keys:** keys written with a space are written with an underscore (`Menu Scene` → `Menu_Scene`, `Mouse Mode` → `Mouse_Mode`).

- **Renamed keys:** `Wait` → `Wait_Loops` and `Time` → `Wait_Time` wherever they decide when the Dialogue continues, `Loop` → `Loops`, and `Default` → `Stop_Frame` on the `_Stop` commands.

- **Entries under their own key:** the players, layers, Actors and targets of a Command are listed under a key (`Players`, `Layers`, `Actors`, `Targets`), and their effects under `Effects`, so future versions can add settings to these Commands.

- **Meta:** every Command and every entry has a `Meta` key, containing its reference, notes and Custom Data. Choice\_List's `Custom` and Input's `Custom1`…`Custom5` keys are replaced by Custom Data.

- **Every key present:** every Line contains every key of its Command, and `"null"` means that a setting is not set.

- **Variations:** a Spoken Line's `Variants` are now `Variations`, and tags are written `tag=value` instead of `tag:value`.

- **Values not trimmed:** spaces at the start or end of a value are preserved.


### Expressions and Variables
- **One expression symbol:** only a value starting with `¢` is evaluated, so text starting with `$`, `€` or `£` is no longer misread as a reference. The `£`, `$`, super symbols and `v_res://` / `v_user://` references of 1.1.3 are replaced by CandyRef expressions.

- **Node paths:** `$` paths are relative to the Engine node; 1.1.3 read them from `/root/`.

- **Conditions:** the conditions of If, Elif and While must start with `¢`. A condition that fails to evaluate is reported as an error instead of being read as false, so a broken condition no longer silently takes the wrong branch.

- **Stored references:** when a variable reference is resolved by CandyRef, a value starting with `¢` is evaluated as an expression by CandyRef as well and resolved.

- **File variables:** a file variable is read with the `file_var()` function, inside an expression: `v_res://data/stats.json¬player.hp` is now written `¢file_var('res://data/stats.json').player.hp`. The file path can be computed by an expression (`¢file_var('user://' + €slot).gold`), which replaces the `sv_res://` / `sv_user://` prefixes.

- **Call arguments:** the arguments of a Call command are now written as one expression returning an Array, in square brackets: `£globals.gold, 2, 'sword'` is now written `¢[globals.gold, 2, 'sword']`. In 1.1.3, they were a comma-separated list, each item read as one argument.

- **Write targets:** the `Variable` keys of Set, Call, Await and Input are written without `¢`. With `¢`, the expression is evaluated first and its result names the variable.

- **Paths stay paths:** a `res://` or `user://` value is no longer loaded as a resource. To pass the resource itself, load it in an expression: `¢load('res://items/sword.tres')`.

- **Values without a symbol are text:** a value without `¢` is always text. In 1.1.3, `"5"` and `"true"` became a number and a boolean, and a quoted `'hello'` lost its quotes. To write a number, use `¢5`.

- **Adding text numbers:** `+=` between a number and a text containing a number now adds them.

- **Export keys:** the variables listed by `Export` and `Import` are written without a symbol, so the keys of files exported by 1.1.3 change (`£globals.hp` → `globals.hp`).


### Spoken Lines
- **Line overrides by name:** `ForcePortrait` is now `Portrait_Mode`, `ForceBubbles` is `Dialogue_Mode` and `AI` is `LLM`. Their values are mode names and on/off values instead of `-1`, `0` and `1`.

- **TTS per Line:** a Line's TTS setting now selects the TTS mode, instead of only switching TTS on or off.

- **Actor overrides by name:** in the `actors` dictionary, `PortraitOverride` is now `BoxPortraitMode` and `BubblesOverride` is `DialogueMode`, and `TTS` and `LLM` accept a mode name and `true` / `false`.

- **Colors replaced by BBCode:** any formatting, not only a color, can be applied to the text and the speaker's name. The color settings of the Engine, UI Elements and Actors are replaced by BBCode wraps (`[color=#ff0000][b]`), written as opening tags only.

- **Text color:** UI Elements no longer force their text to white, or black in bubbles and barks. Text now takes its label's theme color.

- **No "never bubbles" option:** 1.1.3's `-1` for bubbles is gone. To keep a Line or Actor out of bubbles, set its dialogue mode explicitly.

- **Text variables:** written between `¤` symbols by default (1.1.3: `{)` and `}`). `¤Alice¤` displays the Actor's ShortName, else DisplayName, translated. An unresolved text variable is displayed as written, with an error, instead of nothing, so the mistake is visible.

- **Word Substitution:** a numeric category counts properties only, so it no longer counts the case rule. A token without a category checks only the first property. A rule with more values than properties no longer matches, and a type hint also checks the property's type.

- **Capitalized substitutions:** the "capitalized" case rule of Word Substitutions now capitalizes only the first letter. In 1.1.3, it capitalized every word and replaced underscores with spaces.

- **Substitution end symbol:** `substitution_end_symbol` is new, and defaults to the start symbol.

- **Dispositions:** several Dispositions are separated by commas only. A speaker who isn't in the `actors` dictionary is treated as having no Dispositions.

- **Empty alternatives:** an `#N` alternative with no text is left out of the random pick instead of skipping the Line.

- **Case-sensitive tables:** the language and Variation keys of the Lexicon and of the Substitution Table are case-sensitive.

- **Lexicon BBCode:** a keyword's `BBCode` is a wrap of opening tags, instead of an opening and closing pair.

- **Lexicon priority:** when several wildcard keys of the Lexicon or the Substitution Table match, the most specific one is used. In 1.1.3, the first in alphabetical order was used.

- **History entries:**
  - The speaker's name is saved without the Actor's formatting.
  - Dialogue box text is saved without its end-of-line string.
  - A Return is recorded differently.

- **LLM order:** the `llm_query` hook runs after the dialogue mode and the UI Element are chosen, so a UI Element can override the LLM setting. It now runs after `x_new_speech_display`.

- **Optional speaker label:** a dialogue box without a speaker label displays Lines without a name. 1.1.3 refused to display them.


### Dialogue Modes
- **Modes by name:** `dialogue_mode` and `bubbles_exempt_mode` are names instead of numbers, so modes you add can be selected anywhere.

- **Unavailable modes:** a mode that no UI Element can display is passed over, and the next level's mode applies, instead of the Line failing to display.

- **Subtitles clearing:** subtitles clear when the Dialogue advances (`subtitles_self_clear`, on by default). 1.1.3 left them on screen until the next Line.

- **Bubbles per Engine:** each Engine clears only the bubbles it wrote in last, so Dialogues running in parallel no longer clear each other's bubbles. `UI_Clear`'s `Bubbles` `"2"` clears every bubble.

- **Chat speaker:** `chat_show_speaker` is off by default, since Chat Lines have their own name labels.

- **Portrait mode:** the Engine's `portrait_mode` is now `box_portrait_mode`, next to the new `chat_portrait_mode`.


### Voice
- **Variation folders with absolute paths:** an absolute `Voice` path is looked up in the Variation's folder for every Variation but Default, so translated voices are found automatically.

- **Voice mode player:** the player of the Voice mode is listed in the Engine's UI Elements (`voice_player_path`) instead of its media players. `"Voice"` is no longer a media player name.

- **Default voice path:** the default voice path adds a folder for the Dialogue, so voice files from 1.1.3 must move, or `voice_path` must be set to the 1.1.3 layout.

- **Variation folders:** voice folders named after a Variation use `=` instead of `:`, as tags do (`Default_S:F` → `Default_S=F`).


### Choices
- **Return:** a Return choice now returns from Bridges (see Return levels, under New Features). In 1.1.3, it closed the menu, like Close.

- **Tag matching:** `Choice_Status` and `Timer_Status` match whole tags, case-insensitive, so `shop` no longer matches `workshop`.

- **Finished timers:** `Timer_Status` no longer restarts a timer with no loops left. In 1.1.3, it ran once more.

- **Relative timer loops:** a relative change by `Timer_Status` now stops at zero loops, and leaves an infinite timer infinite. In 1.1.3, a large enough decrease made the timer infinite.

- **Disabled choices:** the `Setup` of a disabled choice runs when `Choice_Status` enables it, not when the menu opens.

- **First category:** a menu whose `Main` category is empty or unknown displays its first category.


### Flow Control
- **Return levels:** `Return` accepts `Levels`: a number of levels, a negative number to end the Dialogue past the main Block, or `0` to return all the way. Return no longer ends only the body of an If, For or While.

- **Missing targets:** a Jump or Bridge to a Conversation, Block or Line Mark that doesn't exist ends the Dialogue, with an error, so a broken link is noticed instead of the Dialogue continuing in the wrong place. 1.1.3 skipped it, or went to the first Line.

- **Role keys:** the keys of the `roles` dictionary are written without the Role symbol.

- **Name command:** the `Table` key is removed. Names are translated through `display_names` when displayed.

- **Custom command:** the code for your Custom command values goes in scripts of your own instead of `Candy_Engine.gd`, so updates no longer overwrite it.


### Media and Effects
- **Loops:** `Loops` `"-1"` plays forever and `"0"` holds the first frame, for every kind of media.

- **Relative volume:** in `Media_Volume`, a relative volume is written `+=N` / `-=N`, so a value with only a sign, such as `-6`, can set an absolute volume.

- **Relative frames:** in the `_Skip` commands, a skip by frames is written `f+N` / `f-N`, counted from the frame displayed.

- **Effect libraries:** background effects load their libraries from a single `Animation_Libraries` folder, instead of one folder per layer.

- **Layer, Actor and effect lists:** BG and VN commands name every layer, Actor and effect they act on. An empty list no longer means all of them.

- **Waits:** a wait counts from the start of playback, and covers every entry given a wait, not only the first.

- **Finished playback:** a finished background or bust playback remains on its last frame.

- **Ownership:** a player the Engine doesn't own ignores its commands, unless the player is Public.

- **Audio frames:** `f=` times on an audio player are reported and ignored.

- **Layering:** the `Box` key of the Media commands moves the barks as well as the dialogue box, subtitles and chat.

- **Images:** `Media_Play` decides from the file whether an image is animated, unless told otherwise, its frame rate is set by `FPS`, and its `Duration` is the total display time, which `Loops` no longer multiplies. In 1.1.3, images were static by default, and `Duration` was the frame rate of an animated image, or the length of one loop of a static one.

- **Effects play once:** `BG_Effect_Play` and `VN_Effect_Play` play once and don't wait by default. In 1.1.3, they looped forever, and `BG_Effect` waited one second.

- **Removed waits:** `VN_Wait` without a wait time no longer waits for the bust's playback to end, and the "until the loops are done" wait of `BG_Wait`, `BG_Effect_Wait` and `VN_Effect_Wait` is removed.

- **Cutscene waits:** `CS_Anim_Wait` and `CS_Sprite_Wait` given both a number of loops and a time now count both from the start of playback. In 1.1.3, the time counted from the end of the loops.

- **Skip positions:** a `_Skip` time returned by an expression as a number is now an offset from the current position. In 1.1.3, it was an absolute position. To go to a position computed by an expression, return it as text, such as `¢str(globals.checkpoint)`.

- **Portrait effects:** the portrait effect player is gone, along with the portrait scene, so `Effect` Lines aimed at it lose their target.


### Visual Novel Busts
- **Shared bust positions:** any Engine can move or remove an Actor placed by another Engine, since the bust scene records which Actor is on which bust for every Engine using it.

- **VN\_Remove:** Actors leave in groups, by the order set for each Actor, instead of one after another.

- **Leave effects at the end:** playing the Actors' Leave effects when busts are cleared at the end of a Dialogue is now optional, and off by default. 1.1.3 always played them, one Actor after another.


### Engine
- **Engine settings:** `dialogue_suspended` is no longer exported. `media_players_locations` is now `media_players_paths`, and `cs_locations` is `cs_paths`.

- **Folder settings:** `Candy_Properties.gd` names every scene folder, and the per-Engine `custom_commands_folder` is removed: custom Commands go in `Scripts/Commands`.

- **Suspension:** `suspend_dialogue()` now suspends the whole Dialogue: Lines, the typewriter, choice timers, voice, menus and Input scenes. In 1.1.3, it only paused media, portraits, backgrounds and busts, and Lines continued to run unless the Engine's suspended setting was set as well.

- **Renamed settings:**
  - `lexicon_bark_mode` is now `lexicon_barks_mode`.
  - `mp_count_variants` is now `mp_count_variations`.
  - `random_variants` is now `random_variations`.
  - `text_to_speech` and `tts_advanced_fallback` take mode names instead of numbers.

- **Hooks called from game code:** hooks are now separate scripts instead of functions of the `candy_de` autoload, so game code that called a hook directly must call it through the autoload's hook functions instead. The `candy_de` autoload also points to a new script, which the Wizard sets up automatically.

---

## Bug Fixes
### Spoken Lines and Dialogue Modes
- Barks were never displayed.
- A text variable naming an Actor (`{)Alice}`) displayed the whole Actor dictionary instead of its name.
- A tag written without a value never matched.
- The Lexicon formatted keywords that touched an accented or non-Latin letter (`ric` inside `Éric`).
- A Word Substitution's numeric category pointed at the case rule, one position too early.
- The `_TTS` Variation was read without its text variables and Word Substitutions resolved.
- Bubbles were cleared by any Engine's Lines and by the end of any Dialogue, including Dialogues running in parallel.


### Portraits
- AnimatedSprite portraits never played.
- AnimatedSprite portraits ignored the speed saved in their SpriteFrames.
- Video portraits set to stop on their first frame continued to play.
- SpriteFrames animations saved with a speed of 0 never advanced.


### Choices and Input
- A choice without an `Invisible` key was hidden.
- A Return, End or Close choice without a target left the menu open and its timers paused.
- Ending one Engine's Dialogue closed the choice menus of every Engine, leaving the other Dialogues waiting indefinitely.
- An Input scene opened over a choice menu couldn't be clicked.
- An unknown `Category_Mode` or `Choice_Mode` changed every category or choice.
- A timer counted its timeout only after its `Timeout` transition, so a `Timer_Status` in that transition received the wrong number of loops.


### Flow Control
- A `Role` command without the Role symbol created a Role that could never be read.
- A Return followed by another Command on the same Line was ignored.
- An `Await` waiting on a node deleted before it emitted the signal left the Dialogue waiting forever.


### Media, Backgrounds and Busts
- `Clear`'s `Backgrounds` and `Busts` keys did nothing.
- Static images played by the Image command were never displayed.
- A static image without a `Duration` remained on screen for the previous image's duration.
- An image `Duration` with decimals was truncated to whole seconds.
- Voice files with an absolute `user://` path were never found.
- A negative absolute volume couldn't be set, and `-=` volumes didn't work.
- Stopping a frame-folder layer or bust on a given frame returned it to the first frame, and stopping a video on a frame seeked to the wrong position.


### Cutscenes
- `CS_Light` failed on `Light2D` nodes.
- `CS_Anim`, `CS_Anim_Wait` and `CS_Anim_Stop` didn't resolve Roles in target names.
- `CS_Anim_Stop` with a frame seeked to the wrong position.


### Engine
- The Wait command continued to count while the Dialogue was suspended.
