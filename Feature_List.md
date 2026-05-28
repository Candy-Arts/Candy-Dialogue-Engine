![Candy Arts Logo](Logo.png)

# Candy Dialogue Engine
**[Candy Dialogue Engine](https://candy-arts.com/index.php/candy-dialogue-engine) by [Candy Arts](https://candy-arts.com) is an extensive and powerful Dialogue System for Godot 4. More than that, it's also a Visual Novel Engine, Media Synchronizer, Cutscene Orchestrator, Narrative Manager, and Mod Support Solution.**

## Feature List

### Dialogue Display:
- Multiple modes:
  - Dialogue box + Portrait
  - Subtitles
  - Chat box
  - Speech bubbles
  - NPC barks
  - Voice only
  - Create and add custom modes.
- Mode switching:
  - Automatic switch from speech bubbles to any other mode for off-screen characters.
  - Switch at any time while dialogue is running.
- Text Display Options:
  - Auto-advance at the end of each Spoken Line, with configurable timer.
  - Typewriter effect with configurable speed.
  - Player input to skip/speed up/slow down typewriter, with configurable speed.
  - Display variable values in text (see 'Variables & Functions' further below).
  - Auto-format / clickable keywords (see 'Lexicon' further below).
  - Change words based on actor gender or other attributes (see 'Word Substitution' further below).
- Speaker Roles:
  - Assign Roles as speaker to Spoken Lines.
  - Dynamically assign actors to roles at runtime.
- Dispositions:
  - Display/skip Spoken Lines according to speaker disposition.
  - Disposition is user-defined: relationship status, mood, attribute, etc.
  - Advanced settings:
    - Display/skip line based on multiple dispositions.
    - Display/skip line if all/some/no dispositions match.
- Speaker Portraits:
  - Line-specific portrait assignment.
  - Automatic use of a default portrait if none assigned to a Line.
  - Supports animated portraits.
  - Multiple portrait display modes:
    - Display portraits for all characters.
    - Display only for player-characters.
    - Display only for NPCs.
    - Disable portraits for all characters.
  - Multiple supported nodes:
    - TextureRect.
    - NinePatchRect.
    - TextureButton.
    - Sprite2D/Sprite3D.
    - AnimatedSprite2D/AnimatedSprite3D.
    - VideoStreamPlayer.
- Voice Options:
  - Play pre-recorded voice files.
  - Prevent advance until voice playback is finished.
  - Synchronize typewriter speed to voice duration.
  - Text-To-Speech (TTS) support:
    - TTS query at runtime.
    - Automatic BBCode stripping.
    - Optional 'TTS' text for accurate pronunciation/tone/rhythm.
    - Customizable hook function: personalize querying logic.
    - Line-specific TTS settings.
    - Compatible with any TTS tool/solution that can be implemented in your Godot project.
    - *Users must implement TTS into their game. Candy DE only provides compatibility/support features.*
- LLM/AI-Generated Speech:
  - Automatically query a connected LLM at runtime to generate character speech at runtime.
  - Customizable hook function to personalize the querying logic:
    - Craft/edit prompts based on Line data and game variables before query.
    - Review/correct/re-query LLM outputs before display.
  - Compatible with any LLM that can be implemented in your Godot project, including local or cloud-hosted.
  - *Users must design their game to connect to an LLM API. Candy DE only provides compatibility/support features.*
- Actor Options:
  - Modifiable display names.
  - Custom colors for speaker name or spoken text for each dialogue mode.
  - Custom actor settings for TTS, speech bubbles and portrait display.

### Visual Novels:
- Practical architecture:
  - Create 'VN Scenes' with nodes for displaying character busts.
  - Customize bust node amount, position, size, node type, etc.
  - Load/swap VN Scenes at runtime for maximum flexibility.
  - Use dialogue commands to control the scene:
    - Assign character busts to bust nodes.
    - Change and/or animate bust images.
    - Move actors to other bust nodes
      - Optional: Preserve ongoing animation state when moving.
    - Remove actors from the scene.
    - Mirror (flip) busts.
    - Play visual effects on busts with AnimationPlayer nodes.
  - Multiple supported bust nodes:
    - TextureRect.
    - NinePatchRect.
    - TextureButton.
    - Sprite2D/Sprite3D.
    - AnimatedSprite2D/AnimatedSprite3D.
    - VideoStreamPlayer.
- Join/Move/Leave Animations:
  - Automatically play custom animations when characters enter the scene, move from/to another bust node or leave the scene.
  - Actor-specific animation settings available.
- Speaker Highlights:
  - Automatically trigger special effects to highlight the speaker's bust.
  - Various ready-made effects: display label or icon, change bust scale, etc.
  - Easily code custom effects.
  - Automatic effect cancellation/reversal when character finishes speaking.

### Backgrounds
- Practical architecture:
  - Create 'Background Scenes' with nodes for displaying background layers.
  - Customize layer node amount, position, size, node type, etc.
  - Load/swap Background Scenes at runtime for maximum flexibility.
  - Use dialogue commands to control background display:
    - Assign background images to layer nodes.
    - Change and/or animate layer images.
    - Remove layers.
    - Mirror (flip) layers.
    - Play visual effects on layers with AnimationPlayer nodes.
  - Multiple supported layer nodes:
    - TextureRect.
    - NinePatchRect.
    - TextureButton.
    - Sprite2D/Sprite3D.
    - AnimatedSprite2D/AnimatedSprite3D.
    - VideoStreamPlayer.

### Dialogue navigation
- Multi-level, user-defined dialogue structure: Dialogue > Conversations > Blocks > Lines.
- Two Line types: Spoken Lines for displaying speech, Command Lines for engine instructions.
- Transition commands allow free and reliable dialogue navigation:
  - 'Jump' command to permanently jump to Conversations/Blocks/Lines.
  - 'Bridge' command to momentarily bridge.
  - 'Return' command to return early from a bridge at any time.
  - 'End' command to end dialogue at any time.
  - Special 'Line Mark' command with unique reference name or code, to avoid relying on fragile line indexes.

### Branching / Conditions
- Special command Lines emulate If/Elif/Else + For and While loops.
- Write conditions like in GDScript: comparative operators, OR/ELSE/XOR, parentheses.
- Trigger any dialogue command if condition is fulfilled, or transition anywhere in the dialogue.
- Includes the ability to integrate conditions directly into spoken lines.

### Choices
- Display custom choice lists, from basic to elaborate.
- Sort choices into navigatable categories.
- Setup timers to trigger events or auto-select choices.
- Reconfigure choices at runtime based on game events.
- Choice can modify choices and timers when selected.
- Fully customizable choice UI, from choice menu to individual choice buttons.
- Scaling complexity: basic choice lists are easy, elaborate menus are more work.

### Player Input:
- Display standard input prompt UIs: "enter name", "type code", etc.
- Input UIs communicate with dialogue via signals to trigger effects:
  - Run Lines, continue dialogue and close Input UI, continue without closing...
  - Custom effects can be added via match statement.
- Anything can be an Input UI that communicates with the dialogue: keypads, machines, vehicle controls, even mini-games or the main game itself.
- Dialogue can 'disconnect' from Input UI, continue while UI remains open, then reconnect later.
- *Input UIs must be designed by users. Custom code must be written. Candy DE only provides limited, basic templates.*

### Media Controls
- Play and control image, video or audio media from dialogues.
- Pause dialogue until a specific timestamp, frame, or number of replays.
- Pause media until a specific number of dialogue lines have run.
  - Can count all lines or only Spoken Lines (exclude commands).
- Hide or show the dialogue UI below/above the playing media at any time.
- Modify volume:
  - Absolute modification (change volume to V)
  - Relative modification (increase/decrease/divide/multiply by V)
  - Optional, configurable progressive modification (modify volume over S seconds)
- Enables perfect dialogue vs. media synchronization.

### Cutscene Scripting
- Modify any nodes through dialogue commands in various ways:
  - Move/rotate nodes
  - Make nodes look at other nodes.
  - Change active camera.
  - Modify lights.
  - Animate nodes (e.g. characters).
  - Set characters in motion *(requires writing custom code - movement logic is project-specific)*
  - Instantiate scenes.
  - Change/toggle properties on nodes *(requires writing custom code - requirements are project-specific)*
  - Display/animate sprites.
  - Play visual effects on sprites with AnimationPlayer.
  - Pause or stop sprite animations, in sync with dialogue.
- Adapts to any porject's node tree.
- Customizable dialogue commands to fulfill all your requirements.
- Works in both 2D and 3D.
- Ideal for scripting live cutscenes in sync with dialogue.

### Lexicon (Glossary)
- Display keywords in spoken text with unique BBCode styling.
- Hover keywords to display tooltips.
- Clickable keywords with programmable custom behavior.
- Make keywords display different text entirely: shorten typing or differentiate between synonyms.
- Optional language/variant-specific Lexicon keywords and settings.

### Word substitution:
- Highly intuitive method: •he¦npc_1• → "she"
- Syntax symbols can be customized for convenience.
- Supports any values: 'Male', 'Female', 'M', 'F', '1', '2', '3', etc.
- Works with any character property, not just gender.
- Easy setup: substitution rules are just dictionaries. Templates provided.
- Advanced abilities:
  - Substitute based on multiple properties: e.g. class + gender → "Sorcerer"/"Sorceress"
  - Substitute based on numeric comparisons: e.g. age > 18 → "adult"
- Optional language/variant-specific substitution rules.

### Dialogue History
- Automatic logging of dialogue history:
  - Per-instance logging: logs the history of dialogue engine instances individually.
  - General logging: second log, combining history from all engine instances.
- Display previous dialogue history to the player.
- Use history for debugging purposes.
- Customize which data is logged and the logging format.
- Customize the History UI, including how dialogue is formatted.

### Languages & Variants
- Write translations and alternative speech variants directly into Spoken Lines.
- Skip Lines with missing languages:
  - Allows splitting longer text over multiple Lines for specific languages.
  - No crashes if translation was forgotten for a Line.
- Parallel dialogues can use different languages. 
- Modular variant resolution based on speaker or player gender.
  - Cleanly handle non-existant or non-applicable variants.
  - Supports any values: 'Male', 'Female', 'M', 'F', 'X', 'Y', 'Z', etc.
  - Code can be expanded to add any arbitrary criteria: class, faction, moral alignment, etc.
- Randomized variants with weights (selection probabilities).
- Automatic voice file resolution for languages & variants:
  - Place files in a folder matching the language/variant name.
  - Name files the same as the defaults.
- Translation features available for actor names, UI texts, Lexicon, Word Substitution feature.

### Full UI customization
- Dialogue UI is split in standalone elements: dialogue box, backgrounds, videos, etc.
- Very easy design process:
  1. Create UI scenes any way you like (design, nodes, etc.)
  2. Add 1-2 required nodes anywhere in the hierarchy.
  3. Attach a script to the root (working base script is provided).
  4. Store the required nodes in variables in the script.
- Design multiple UI variations and swap at runtime.
- Naturally supports custom node hierarchy for UI scenes.
- Required nodes are just nodes the dialogue engine reasonably needs - e.g. RichTextLabel to display spoken text.
- No scripting required:
  - Provided base scripts are fully functional for standard use.
  - Code only needs to be written for custom special/advanced purposes.

### Variables & Functions
- Read/modify any variable, call any function, or emit/await any signal in your entire project from the root, including Godot natives.
- Display variable values in spoken text.
- Save variables to external files for unlimited variable declaration at runtime.
- Substitute any piece of dialogue data with variable references, to be resolved at runtime.
- Substitute dialogue data with res:// or user:// file references.
- Basic save/load system:
  - Export multiple variables to external files (save).
  - Import multiple variables from external files (load).
    - Restore variables directly from the file.
    - Optional: import variables to a dictionary for processing of values before actually restoring.
- Export dialogues from your game as dialogue files that the dialogue engine can load and run.
  - Mostly useful for games that create dialogues at runtime:
    - Backup dialogue created in-game.
    - Let users clone dialogues across multiple installations of the game.
    - Share dialogues with other players.
    - Debugging purposes.

### Parallel Dialogues
- Create multiple 'dialogue engine instances'.
- Each instance can use its own UI.
- Each instance can run its own dialogue, at the same time, without conflict.
- Highly useful for a variety of situations:
  - Using different UI or settings for different contexts - exploration, combat, cutscenes, etc.
  - Dialogues running in parallel - groups having separate conversations, multiplayer, TV/Radio channels, background NPC comments ('barks'), etc.

### Modding
- Dialogues can be used as a modding layer:
  - Design your game to load and run player-created dialogue files in different engine instances.
  - Player-made dialogues can call functions, read and modify variables, use conditions, etc. to essential mod any part of your game.
- Can be implement with little effort, with only surface additions (no deep code changes).
- Works with any game:
  - Works with games not specifically designed for modding.
  - Works even in games that don't use Candy Dialogue Engine for their normal dialogues.

### Dialogue Live Editing
- Dialogues can be modified while they run.
- Made possible by the engine reading only one line at a time. Nothing is cached.
- Can be leveraged to implement procedural dialogue generation.

### Programming
- Dialogues are Turing-complete:
  - Can create variables and store data.
  - Can use conditions and loops.
  - Can call functions, emit/await signals.
- Dialogues can therefore be used as logic scripts (functions), similar to code:
- Less efficient than GDScript, but with several important advantages:
  - Runtime programming: modify the logic while the game and even the dialogues run.
  - Meta-programming: program dialogues that program other dialogues or modify themselves.
  - Paired with the Candy Dialogue Creator, dialogues are also a visual/node-based programming language.
- These are capabilities that emerge naturally from the core architecture: not scope-creep, bloat or patched-in features.
- Invaluable for modders, or the rare projects that can leverage these abilities.

### Full Code Access
- The code is fully accessible, like all scripts or scenes in your project.
- Intermediate users: customize the code easily with match statements and hook data in strategic places.
- Advanced users: modify any part of the code.
- Reasonably simple, straight-forward code architecture makes it easy to understand and follow the code logic.

### Candy Dialogue Creator
- Standalone dialogue editing GUI:
  - Reliable performance.
  - Separate writers and translators from code.
  - Not constrained within the Godot Editor.
  - Convenient for multiple-monitor setups.
- "Click to add lines, fill-in data, don’t type syntax" approach.
- Read project files to create selectable lists of data.
- Media file preview on hover.
- Two-click testing: "Test" → Alt+Tab to Godot → "Run"
- Convenient translation features.
- Click to insert BBCode.
- Custom inserts.
- Custom presets: add lines with pre-set data in one click.
- Drag-and-drop dialogue re-ordering.
- User & project profiles.
- Various dialogue export/import options: overwrite, merge, update, ignore specific Conversations/Blocks, etc.
- Made in Godot.
- Can be integrated into Godot projects to act as in-game dialogue editor (Godot 4.5+).
- Compiled executables provided for Linux, Windows, MacOS.
- Completely free, source code/raw project files available, MIT License.

