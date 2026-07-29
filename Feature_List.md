# Candy Dialogue Engine 1.2 — Feature List

## 1. Architecture and extensibility
- **A self-contained Godot 4 addon.** It needs no editor plugin, and every release file lives in the `Candy_DE` folder.
- **Several engines at once.** Each `CandyEngine` node (main UI, NPC barks, a phone chat…) has its own settings, history, menus, language and media. Several can run dialogues side by side.
- **Extend by adding a script.** Nothing needs registering: scripts are found by file name (any case), sub-folders are only for sorting, and each is checked against its base class.
  - New commands (`Scripts/Commands`, `CandyCommand`). A script with a built-in command's name replaces it.
  - New dialogue modes (`Dialogue_Modes`, `CandyDialogueMode`).
  - Input-scene events (`Input_Events`) and choice-menu events (`Choice_Events`).
  - Signal reactions for the Await command (`Await_Events`).
  - Small custom commands through `Custom` (`Custom_Events`).
  - Movement scripts for CS_Move (`Move_Events`).
  - Variation tags decided by your own code (`Variation_Tags`).
  - Data tables, localization tables and hook functions (`User_Data/...`).
- **Script folders can be rescanned at runtime** (`_build_registries()`), which suits mods.
- **Works in exported builds.** Scanning handles `.gdc` and `.gd.remap`, and media lookup handles `.import` and `.remap`.
- **Startup checks report problems:**
  - missing or misspelled required tables and hooks
  - duplicate script names
  - bad voice-path tags
  - a media player owned twice, or owned while it is Public
- **Errors don't stop the dialogue.** An unknown command is reported with its conversation, block and line, then skipped. So is any bad value; the rest of the line still runs.
- **`debug_prints`** turns on logging in debug builds.

## 2. Dialogue files
- **Format:** a GDScript dictionary literal, `Dialogue` → conversations → blocks → a `Text` array of lines.
  - The loader tolerates `#` comments, trailing commas and `<null>`, and takes a bare file or one wrapped in `Meta`/`Dialogue`.
- **Fits Candy Dialogue Creator:** every value is a string, `"null"` means "not set", and every key is always present.
- **One line can hold several commands,** run in key order.
- **Meta and Custom Data:**
  - Every command and every entry inside it carries `Meta` (reference, notes, `Custom_1..n`).
  - Custom Data reaches your code untouched, as nested arrays per level: `[[line],[variation]]`, `[[menu],[category],[choice]]`, and so on.
  - It goes to every hook and to every UI element, player or bubble function a command calls.
- **Room to grow:** entries always sit under their own key (`Players`, `Layers`, `Actors`, `Targets`, `Effects`…), so new keys can be added to a command later.
- **Test dialogues from the inspector:** the Testing scene takes a dialogue, conversation, block and line (an index or a line marker), and has suspend, resume and interrupt buttons.

## 3. Spoken lines
- **Speaker:** an actor key, or a `°role` that resolves to whichever actor holds the role.
- **Variations:**
  - Named `Language_tag=value_bareTag_#N`.
  - Picking: the most specific variation that passes wins; `#N` alternatives are picked at random, weighted by `Weight`; empty variations are ignored; a line with nothing usable is skipped.
  - Tags:
    - `S=` / `P=` tags compare against the speaker's or current player's attributes (`speaker_tags`, `player_tags`).
    - Script-decided tags (`Weather=Rain`) go through `current_value()` or `matches()`.
    - Passed and disabled tag lists sit at engine, actor and line level; the most specific level wins.
  - **`_TTS` variations** give the text TTS reads, separate from the displayed text (SSML is possible).
- **Disposition conditions** on lines, checked against the actor's dispositions:
  - any-of, `+` all, `-` subset, `=` exact, `!` none
  - `(n)` counts, `+(n)` / `-(n)` thresholds, and the negated forms of each
- **Text features:**
  - BBCode.
  - Text variables `¤Alice¤`, `¤Alice.Age¤`, `¤°role¤`, `¤¢expression¤`. They nest up to 16 passes.
  - Word substitution `•word¦actor[¦rule]•`, driven by the substitution table:
    - Tables are scoped by variation name (`*`, `Prefix*`, exact). The most specific table wins, so each language can follow its own grammar.
    - Keyword groups (`he, she`): write whichever form reads best.
    - Case rules: auto (follows how the keyword is written), lower, upper, cap, custom.
    - Property rules on actor properties:
      - nested properties (`Stats.Age`, `Titles.0`)
      - several properties at once, with `_` to skip one (`Class, Gender` → Sorcerer / Sorceress)
      - comparisons and ranges (`>=¦18`, `<¦18, >¦11`)
      - type hints and type-only checks (`18¦int`, `array¦type`)
      - rules checked in order, with a `_` rule as the fallback
    - Several rule sets per keyword: the line picks one by number or by property name (`•id¦Alice¦Origins•`).
    - The keyword, actor and rule can each be a reference (`€var`, `°role`, `¢expression`).
    - Unmatched substitutions stay as written, with a warning that names the line.
  - Any symbol written twice shows itself literally (`¤¤`, `••`).
  - A text that starts with `¢` is an expression as a whole, its result displayed (`¢¢` for a literal `¢`).
  - Right-to-left lines (`Direction: RtL`).
- **Lexicon:** keywords scoped per variation. Each keyword can have:
  - display text
  - BBCode style
  - a tooltip
  - clickable data (`_on_lexicon_clicked`)
  - a hover hook (`_on_lexicon_hovered`)
  - a `Disabled` text, written instead of the keyword when the lexicon is off (and in the history)

  Text between the lexicon escape symbols (`¬Alice¬`) is never formatted, and the symbols aren't shown. Keywords are found as whole words, by word rules set per variation (`lexicon_word_rules`: word characters as Unicode categories and characters, joiners such as `-`); by default letters of every script, digits and `_` count.

  It's switched on per mode, and in Voice mode it replaces keywords before TTS reads the text.
- **LLM lines:** the `llm_query` hook can generate or rewrite a line. It's given the actor, their dispositions, the text and the position. Toggle it per engine, UI element, actor or line.
- **Settings chain for every line setting:**
  - Order: `Candy_Properties` → engine → UI element (`enable_` switch) → actor → line. The most specific level wins.
  - Values are checked and converted; bad values are reported and passed over.
  - Settings are named per mode (`box_…`, `chat_…`, `bubbles_…`, `barks_…`, `voice_…`, `subtitles_…`).

## 4. Writing, advancing and timing
- **Typewriter** in characters per second (0 = instant). It is frame-rate independent.
- **Hold-to-speed and hold-to-slow keys,** each with its own speed (0 = reveal the line). A hold-to-skip key reveals the whole line.
- **Voice sync** fits the writing speed to the voice clip's length.
- **Auto-advance** after N seconds, counted after the voice ends. **Await voice playback** blocks advancing until the voice finishes.
- **End-of-line and advance indicators** (BBCode, e.g. a pulsing ▼).
- **Speaker name inside the text,** with prefix, suffix and BBCode per mode.
- **Automatic BBCode wraps:** you write only the opening tags and the closing tags are added for you. Extra BBCode tags can be registered.
- **Self-clear:** the box and subtitles can clear when the line ends, and the box portrait can clear on its own.
- **`Player_Advance`** waits for a press. **`Wait`** pauses for a time; it can be skipped and stops counting while the dialogue is suspended.
- **Writing hooks on each UI element:** `x_write_begun`, `x_write_progress` (characters added, written, total), `x_write_finished`, `x_speech_advance`.

## 5. Dialogue modes
- **Box:** dialogue box with name label and portrait.
- **Subtitles:** the name merged into the text.
- **Chat:** scrolling message history (see §8).
- **Bubbles:** 2D or 3D speech bubbles on actor nodes. Speakers without a bubble fall back to `bubbles_exempt_mode`.
- **VN_Bubbles:** bubbles on VN busts; Bubbles lines switch to it automatically in VN mode.
- **Barks:** short lines in bubbles over NPCs.
- **Voice:** audio only, with nothing displayed.
- **Custom modes:** a mode is just a script, with these functions:
  - `is_available()`
  - `prepare()` (can hand the line to another mode)
  - `display_node()`
  - `start_line()`, `clear_line()`
  - `settings_prefix()`

  A custom mode takes its settings from its UI element and can still be overridden per actor and per line.
- **Switching mode:** per line, per actor, or by the `Dialogue_Mode` command. The previous mode's display is cleared automatically.

## 6. Voice and text-to-speech
- **Voice file lookup:**
  - "Folder" logic: `voice_path` built from `{actor}{dialogue}{conversation}{block}{line}` tags.
  - Each language variation gets its own sub-folder.
  - Absolute paths and `¢` expressions are accepted.
  - A voice language separate from the text's (`voice_language`), per project or engine.
  - Falls back to another language's file (`voice_fallback_language`). A missing file just plays the line without voice.
- **Each UI element or bubble has its own voice player** (non-positional, 2D or 3D); there's also a standalone Voice player.
- **TTS modes:**
  - Off.
  - Simple: reads the displayed text.
  - Advanced: reads the `_TTS` variation, with a fallback.
  - Your own modes.

  The `tts()` hook returns an AudioStream or a file path. If it returns nothing, the recorded file plays.
- **Runtime loading** of `user://` ogg, mp3 and wav files.

## 7. Choices
- **Menu structure:** Menu → Categories → Choices. Each level can use its own scene, and several looks ship (Blue, Green, Pink).
- **Titles, prompts, labels and tooltips** are all localized, and update live on a language change.
- **Per-choice state:**
  - `Enabled` (no button at all)
  - `Active` (shown but can't be picked)
  - `Invisible`

  These accept `¢` expressions.
- **Categories:** choices can `Navigate` between categories. Each category sets its own mouse mode.
- **Finish types:** Continue (back to the still-open menu), Bridge, Jump, Return (`Levels`), End, Close.
- **Setup transitions** run before the menu, a category, a choice or a timer is built.
- **Timers:**
  - countdown, loops, auto-start or on hold
  - a Timeout transition
  - a choice picked automatically on timeout (`Timer_Choices`)
- **Changing open menus:**
  - `Choice_Status`: enable, disable, (de)activate, show, hide, relabel or retooltip, targeted by Last/Tags/All at menu, category and choice level.
  - `Timer_Status`: set or change time and loops relatively, plus Start, Pause, Stop and Restart/Update behaviour.
- **Nested menus:**
  - Menus can open inside menus; older ones can be hidden (`hide_choice_lists`, `never_hide`).
  - Opening, nesting, reopening and closing can each play an animation the dialogue waits for: `x_initialization_finished`, `deactivate()`, `reactivate()`, `x_menu_closing`.
- **Safe input:** a shield blocks clicks and focus while a pick is being handled, so the advance key can't pick twice.
- **`x_choice_selected` hook,** and new menu events can be added as scripts.

## 8. Chat
- **Structure:** a Chat_Box lays out one or more Chat_Channels, and is visible while any of its channels is.
- **Virtualised history:** every line is kept, but only the visible ones get nodes, which are reused as the chat scrolls.
- **Scrolling:** mouse wheel and scroll bar. The chat follows new lines, stops following when you scroll up, and resumes near the bottom.
- **Layout per line:**
  - Left, Right or Alternate alignment.
  - Speaker name and portrait on each side, shown on every line or only on a speaker/portrait change.
  - Empty name and portrait space can be kept so lines stay aligned.
  - Each line can use its own Chat_Line scene.
- **Between dialogues:**
  - The chat can clear on start, clear on end and hide on end; kept dialogues are split by a separator scene.
  - Chat can persist when the dialogue mode changes.
- **Portraits** animate only while their line is being written. A `-2` portrait keeps playing.

## 9. Portraits
- **Node types:** TextureRect, NinePatchRect, TextureButton (state textures), Sprite2D/3D (spritesheets), AnimatedSprite2D/3D (SpriteFrames files) and VideoStreamPlayer.
- **Portrait modes:** Off, All, Player, NPC, or VN (only speakers without a bust).
- **`Portrait_Play`:** N loops, still, loop until advance, loop until replaced, or loop until the voice ends. **`Portrait_Stop`** picks the frame it stops on, or removes the portrait.
- **Box portrait extras:** a portrait area, background, foreground and effect player.

## 10. Media, effects and the shared playback system
- **One set of `Media_` commands** for audio (non-positional, 2D, 3D), video and image players: Play, Wait, Pause, Resume, Stop, Volume, Skip. One line can drive many players, each with its own settings.
- **Effect players** (AnimationPlayer): `Effect_` commands. Animation libraries are loaded from a folder, a path or a `¢` resource.
- **Shared playback controls** for media, effects, backgrounds, busts and cutscenes:
  - `Loops`: N times, hold on the first frame, or forever.
  - `Duration`: stop part-way through a loop.
  - `Stop_Frame`: current, last, frame N, or Clear.
  - Scheduled stops (`Loops` / `Duration` on a `_Stop`).
  - `Wait_Loops` + `Wait_Time` block the dialogue until playback reaches them.
  - Time formats: seconds, `HH:MM:SS.xx`, `f=` frames, relative `+`/`-`, and `f+N` / `f-N`.
  - Pause for N lines (only spoken lines, or all lines).
  - Pause loops: a segment keeps playing while paused, with 4 resume styles and a volume dip and recovery.
- **Volume:** absolute or relative dB, fades, and fades the dialogue waits for (`!`).
- **Z-order:** the `Box` key and the `UI_Z` command move the whole dialogue overlay above or below a video or image, or move any node.
- **Frame-folder animations:**
  - The first frame loads at once; the rest stream on background threads.
  - Each animation has a memory budget, with a look-ahead option. Late frames are skipped so the timing stays exact.
  - Frames are shared between users, and TextureButton state folders play in step with the main animation.
- **Spritesheets:** the grid comes from the file name (`Fire_4x3-2.png`). SpriteFrames play at their saved speed.
- **Folder `config.txt`:** extension, fps, cache and stream, plus per-file overrides.
- **Default extensions and frame rates:** set per kind of media at each level: properties → engine → element or player → folder → the line's `FPS`.
- **File lookup:**
  - `Default.<ext>` is used when a file is missing.
  - An `Animated/` sub-folder is checked.
  - `res://` and `user://` paths and `¢` expressions are accepted.
  - `user://` images, audio and video load at runtime.
- **Who controls a player:**
  - **Private** players obey only the engine that owns them.
  - **Public** players obey any engine. The engine that starts playback **holds** the player, and Exclusive / Semi-Exclusive / Free decide what other engines may do meanwhile.
  - `Take_Hold` on a line overrides this; command lists are configurable per player.
- **Playback hooks:**
  - `x_playback_starting` and `x_playback_started`.
  - `x_playback_finished`, which tells a natural end from a stop.
- **Custom players:** any node with the right `x_media()` functions can be listed as a player and read keys of its own.

## 11. Backgrounds
- **Layered background scene:**
  - Layer node types: TextureRect, NinePatchRect, TextureButton, Sprite2D/3D, AnimatedSprite2D/3D, VideoStreamPlayer.
  - `BG_` commands: Play, Wait, Pause, Resume, Stop, Skip, Mirror, Remove.
  - Several effects per layer (`BG_Effect_*`), on pooled AnimationPlayers.
- **`BG_Scene`** swaps the whole background scene.
- **Persistence:** backgrounds can stay up after the dialogue ends. `clear_bg_layers_ood()` clears them outside a dialogue.
- **Shared scene:** the same Private/Public, holding and suspension rules as media players.

## 12. Visual-novel busts
- **`VN_` commands:** Play, Wait, Pause, Resume, Stop, Skip, Mirror, Remove.
  - **Move** and **Swap** keep what the bust is playing, its effects, pause loops and scheduled stops.
  - Bust effects: `VN_Effect_*`.
- **Join/Move/Leave effects:**
  - Set per line → actor → scene → engine.
  - Played as an animation, a tween or your own method.
  - `JML_Order` groups actors that enter, move or leave together.
- **Speaker highlight:** name tag, outline, scale, animation or billboard.
- **The bust scene tracks which actor is on which bust,** for every engine that uses it.
- **`VN_Scene`** swaps the bust scene.
- **End of dialogue:** busts can stay up afterwards; Leave effects can play when they're cleared. `clear_busts_ood()` clears them outside a dialogue.

## 13. Cutscene (game-world) commands
- **Targets** are given through `cs_paths` containers (with `°role` names), node paths or `¢` expressions.
- **Animations:** `CS_Anim_*` on AnimationPlayers, and AnimationTree state machines travelled to a state.
- **Sprites:** `CS_Sprite_*` on Sprite2D/3D sheets and AnimatedSprites.
- **Other commands:**
  - `CS_Cam`: make a camera current.
  - `CS_Light`: color and energy, with operators, at once or progressively (optionally waited for).
  - `CS_Position`: move nodes onto markers, at once or progressively, within a time or at a speed (optionally waited for); the turn follows the move or has its own time or speed.
  - `CS_Look`: face markers, with axis choice and an ignore-height option, at once or progressively, within a time or at a speed (optionally waited for).
  - `CS_Move`: your movement scripts; all targets move at once.
  - `CS_Scene`: add scene instances.
  - `CS_Toggle`: calls the target's `candy_toggle()`.
  - `CS_Visible`: show, hide or toggle.
- **Cutscene playback belongs to the game world:** it isn't suspended or stopped when the dialogue ends.

## 14. Flow control and logic
- **Transitions:**
  - Jump.
  - Bridge (a call that returns).
  - Return with levels (N, -N to end the dialogue, 0 for all the way back).
  - End.
  - Line markers (`LM`) as named targets.
- **Conditions and loops:** If, Elif, Else, For (arrays, dictionaries or ranges, with a loop variable) and While, which has an infinite-loop guard. A broken condition is an error, never a quiet false.
- **Variables:**
  - `Set` and `Flag`, with about 100 operators: arithmetic, string, array, dictionary, type, math, random, node and Candy-literal.
  - Writes reach nested members (`position.x`), object properties and file variables.
- **Calls and signals:**
  - `Call` any method (awaited or not), with arguments and its return value stored.
  - `Await` a signal and store its arguments, with an Await_Events script reacting to each emission.
  - `Emit` a signal.
- **Actors:** `Name` (rename an actor, still localized), `Role` (assign or clear), `Disposition`.
- **Other:** `Mouse` (mouse mode), `Comment`, and `Custom` (your own small commands).
- **Engine commands:** `Engine_Language`, `Dialogue_Mode`, `Engine_Writing`.
  - They change engine settings mid-dialogue.
  - `"Reset"` restores the inspector value.
  - Changes are undone automatically at dialogue end, configurable per line.

## 15. CandyRef expression language (`¢`)
- **Syntax:** GDScript-like.
  - Literals in every base; strings with escapes, StringName and NodePath literals; arrays and dictionaries.
  - Every operator, ternary, `in` / `not in`, `is` / `as`.
- **Access:**
  - Chained `.`, `[ ]` and calls; dot access works on dictionaries too.
  - Built-in methods, GDScript global functions and engine constants.
  - Engine classes and `class_name` scripts, including static members and `.new()`.
  - Node paths `$UI/Box`, `%Unique`, quoted paths.
- **Shortcut symbols:**
  - `€` (variables), `°role` lookups (`¢°npc.Age`).
  - Your own symbols in `CandyRef_Shortcuts.gd`.
  - A `constants` dictionary of values and Callables visible to every expression.
- **Write targets:** for Set, Variable keys and Input results; indirect targets are supported.
- **`file_var(path)`** reads and writes values in a file, saving automatically on write.
- **Performance:** parsed expressions are cached.
- **Errors:** they point at the exact character, failures are told apart from a real null, and circular references are guarded.

## 16. Data, save and localization
- **Data tables:**
  - Actors: names, gender, dispositions, tags, and per-actor overrides of every line setting and VN effect.
  - Flags, Variables, Roles, Player refs and the current player.
  - Lexicon, Substitution table, Hook arguments.
  - New tables are just new scripts, readable at once as `candy_de.<name>`.
- **Localization:**
  - Language-named variations.
  - Localized display names, choice texts and input texts (instructions, placeholders, defaults, blacklists and whitelists, error messages).
  - Per-engine `engine_language`, and `refresh_language()` for live switching.
- **Export and Import commands:** json, txt, csv, cfg/ini, bin, base64, tres/res, and dialogue files.
  - If the file exists: Overwrite, Skip, Duplicate or Timestamp.
  - Nodes and Resources are kept as references.
- **History:**
  - Kept per engine and globally across engines.
  - Records speech, portraits and dispositions, plus jump, bridge, return and end markers.
  - Can be switched off per line, actor, element or engine.
  - History menu UI with `open_instance_history()` and `open_general_history()`.

## 17. Input scenes
- **Any scene can be an Input scene.** It reports back through the `finish`, `close`, `run_lines` and `suspend` events, and you can add your own.
- **Sanitized input:** the template stores what the player types sanitized (`CandySanitizer`): Candy DE symbols, BBCode, lexicon keywords and a leading `¢` are neutralized, each step an option. Any code can sanitize a value with the same functions.
- **The `Input_UI` template:**
  - Character and word limits.
  - Allow or forbid case, numbers, decimals, punctuation, special characters and spaces.
  - Per-language blacklists and whitelists with wildcards.
  - Localized error messages.
  - Enter submits or adds a line break.
  - The result is stored in any variable.

## 18. Hooks (all take `candy_args`, `user_args`, `custom_data`)
- **Dialogue:** `x_dialogue_start`, `x_dialogue_end`, `x_dialogue_suspended`, `x_dialogue_resumed`, `change_game_state`.
- **Lines and commands:** `x_new_line`, `x_command_start`, `x_new_speech_start`, `x_new_speech_display`, `x_speech_advance`.
- **Flow:** `x_jump`, `x_bridge`, `x_return`, `x_end`, `x_choice_selected`, `x_flag_changed`.
- **Services:** `tts`, `llm_query`, `_on_lexicon_clicked`, `_on_lexicon_hovered`.
- **Per node:** writing hooks, playback hooks, and menu hooks (`x_initialization_finished`, `x_menu_closing`).
- **How hooks run:**
  - The `hook_arguments` table supplies your own arguments, literal or evaluated live through `¢`.
  - When several files implement the same hook, they all run.
  - Hooks are awaited, except where nothing can wait for them.

## 19. Dialogue lifecycle
- **Engine API:**
  - `load_scripted_dialogue()`, `start_dialogue(conv, block, line|LM)`.
  - `suspend_dialogue()` / `resume_dialogue()`.
  - `interrupt_dialogue()` (can be awaited).
  - `end_dialogue()`, `raise_killswitch()`.
- **Suspension can freeze:**
  - lines and the typewriter
  - choice timers and menus, and Input scenes
  - voice and portraits
  - media players (each media kind separately, with immune players)
  - background and bust animations and effects

  Resuming lifts only what the suspension paused.
- **The killswitch** stops a dialogue cleanly, even mid-Await, mid-Input or mid-menu.
- **Signals:** `dialogue_fully_ended`, `dialogue_resumed`, `killswitch_raised`, `killswitch_off`, `choice_list_event`, `input_received`.
- **Readable state:** running, starting, ending and suspended flags, the conversation/block/line position, and the nesting depth.
- **Mouse modes** for dialogue start, dialogue end and choices.
- **Input actions are configurable:** advance, speed, slow, skip, and player-advance.

## 20. Scenes shipped
- **UI element templates** (`Default.tscn` to edit, `Candy_Default.tscn` as a reference):
  - dialogue box, subtitles
  - chat box, channel, line and separator
  - choice menu, category and button
  - history, input
  - background and VN scenes
  - 2D/3D speech bubbles, 2D/3D barks
  - image player
- **Also shipped:** the `Candy_UI.tscn` dialogue UI and a testing scene.

## 21. Installing and releases (Candy Wizard, a separate plugin)
- **"Candy Dialogue" dock:** shows what's installed, and opens an install wizard.
  - Release source: the latest GitHub release or a zip.
  - Optional project backup, streamed and zipped outside the project.
  - The release's setup questions, with live previews.
  - Summary, then install.
- **Release checks:** the manifest is validated; paths must stay inside `Candy_DE`; Godot and Wizard minimum versions; SHA-256 check of every file. A failed install rolls back.
- **What it installs:** the files, the `candy_de` and `candy_ui` autoloads and the four input actions (actions you already have are left alone). It records everything in `Install_Record.json`.
- **Update wizard:**
  - It replaces engine files, and lists the ones you edited first.
  - It never overwrites templates (`User_Data`, `Default.tscn` scenes, animation libraries); the new version is saved beside them.
  - It backs up and reports every change, and applies cumulative update steps:
    - add, set or rename a variable
    - replace text
    - move a file
    - rename an input action
    - manual steps
- **Release builder** (not shipped): runs headless, signs the release, sorts files into categories, checks that shipped scenes only use shipped files, and checks the update steps. BBCode pre- and post-install notes come with a live preview scene.

