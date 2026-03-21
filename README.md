![Candy Arts Logo](Logo.png)

# Candy Dialogue Engine
**[Candy Dialogue Engine](https://candy-arts.com/index.php/candy-dialogue-engine) by [Candy Arts](https://candy-arts.com) is an extensive and powerful Dialogue System for Godot 4. More than that, it's also a Visual Novel Engine, Media Synchronizer, Cutscene Orchestrator, Narrative Manager, and Mod Support Solution.**

Candy Dialogue Engine was designed to achieve five core goals:
- Make dialogues fast and simple to write.
- Adapt to any game type or genre.
- Provide or support any features developers may need.
- Make dialogue synchronization with game events easy.
- Allow full code and UI customization.

To put it simply: we want it to be the last dialogue system you'll ever need, capable of fulfilling all your dialogue-related requirements.

## Table of Contents
- [Features](#features)
- [Usage](#usage)
- [Pricing](#pricing)
- [Licensing](#licensing)
- [Compatibility](#compatibility)
- [Bugs and issues](#bugs-and-issues)
- [Feedback](#feedback)

## Features
### Simple to Advanced
Despite its impressive breadth of features, Candy Dialogue Engine remains easy to use and get into: it's simple for basic use, and only requires learning the more advanced options that you actually need. Documentation is provided for every feature in the form of individual PDF guides.

When you just need to display text and maybe the occasional player choices, it's all straightforward. When you need more, it delivers. Complexity scales with your project, so you're never overwhelmed.

### Extensive display options
Candy Dialogue Engine provides many options to display and format dialogues.
- Multiple dialogue modes are offered: RPG-style box with speaker portrait, speech bubbles, subtitles, chatbox, or voice only.
- Format text or speaker names with BBCode, assign custom colors to different actors, add keywords to the Lexicon to give them custom styling (and make them display tooltips or clickable), etc.
- Display text instantly or use a typewriter effect, with options to configure keys that make text write faster, slower, or instant. And configure dialogues to automatically advance once a line has fully displayed.
- Display a custom string or single character at the end of line, to prompt the player to continue - supports BBCode for styling or visual effects (e.g. blinking).
- Assign lines to actor roles when the speaker isn't a specific actor, make lines conditional based on the speaker's disposition, display variations based on the player or the speaker's gender, or let the engine randomly select between multiple line variants (with optional weights).
- Assign voice files to lines, with an option to sync the typewriter effect with the speech duration.
- Display variables in spoken text. Includes support for actor roles, for when you want to display a property of whichever actor is assigned a specific role at runtime.
- Easy and intuitive word substitution system, with automatic case matching and customizable tag symbols, for gendered language or other purposes: **"•He¦npc1• is nice, isn't •he¦npc1•?" → "She is nice, isn't she?"**
- Configure special portrait rules: display portraits only for NPCs, player characters, off-screen actors, or give specific lines or actors their own rules.
- Simple to advanced choice lists: display a few choices with straightforward effects, or sort choices into browsable categories, setup timers to trigger choices, nest choice menus, and make choices modify themselves or other choices when selected.
- Conditional branching: if/elif/else statements, and for/while loops.

### Simple dialogue navigation
Dialogues follow a simple structure: they're split into Conversations, which are split into Blocks, which contain Spoken Lines or Command Lines. There are no hard rules to what Conversations and Blocks mean, so you are free to split dialogues as you see fit.

Transition commands allow you to permanently jump or momentarily bridge to other Blocks in any Conversation (and even to specific Lines in a Block), or to return from a bridge at any time.

A special 'Line Mark' command, with a unique reference name or code, can be inserted anywhere in a Block and be jumped or bridged to directly, to avoid relying on line indexes that may change during editing or even at runtime.

### More than dialogue
Candy Dialogue Engine goes beyond just displaying dialogue text. Insert commands in your dialogue script to do the following:
- Change and animate layered backgrounds, or display, animate or move Visual Novel character busts.
- Play visual effects on screen: fade, shake, flash, or any other animation you can create in an AnimationPlayer.
- Synchronize image, audio or video media with dialogue: play, stop, pause media or dialogue, skip, or adjust volume.
- Move and alter nodes: change the location or rotation of objects, make characters play animations or set them in movement with the pathing logic of your choice, change the active camera or alter scene lights, instantiate or delete nodes or scenes...
- Use the powerful 'Input' command to display interactive UIs that can communicate with the dialogue itself. Any UI of your own design is compatible: text input UIs, keypads with buttons, machines with dials, musical instruments, even mini-games.
- Use dialogues as a scripting layer: modify any variables, call any functions or emit/await any signals in your code, and use conditions including 'for' and 'while' loops. This can be leveraged to make your game moddable by just letting it read and run player-created dialogue files.

### UI Customization
If you're suspicious of dialogue systems that claim easy or complete UI customization but fail to deliver, Candy Dialogue Engine won't disappoint you.

UI elements are easy to customize: create them however you want them to be - size, position on screen, even the node structure. Just be sure to attach the provided (customizable) scripts, and make sure they feature one or two nodes that the dialogue engine needs (e.g. a dialogue box needs a RichTextLabel to display text). Even these required nodes are flexible in terms of type: e.g. portraits can be TextureRect, NinePatchRect, TextureButton, (Animated)Sprite2D/3D, or even VideoStreamPlayer nodes.

Templates are provided to guide you, and for quick testing or setup. UI customization doesn't get easier or more complete than that!

### Localization
Localization isn't an afterthought: Candy Dialogue Engine includes several features to translate dialogues.
- Translation variants can be written directly in spoken lines, and the engine will select the right one based on language settings.
- Voice files for alternate languages are automatically matched to their corresponding lines by the engine, saving you potentially dozens of hours of work!
- Localization dictionaries can be used by the engine to translate text inside UIs that it interacts with, and even to translate the names of actors where relevant.
- The Lexicon and the Word Substitution dictionaries can include entries exclusive to specific languages.
- This doesn't prevent you from letting your own code and logic handle localization if you prefer.

### Technical capabilities
For advanced users, Candy Dialogue Engine offers tremendous power:
- Built-in support for game state tracking: game state can be automatically changed when dialogues start and end, to block player inputs or pause game events.
- Use variable references in place of data pieces anywhere in dialogues, to fetch values updated at runtime.
- Run simultaneous parallel dialogues, each in their own engine instance and with their own UI: perfect for NPC barks, groups having their own conversations, radio or TV channels, or multiplayer games.
- If your game implements or connects to an LLM (AI) or TTS (text-to-speech) API, the dialogue engine can make use of it: it can query the LLM to generate spoken text, or use the TTS system to voice lines. Various options are built-in for both: specific lines and actors can be excluded or forced to use LLM or TTS, and you can provide lines with special 'TTS' variants where the text can be formatted or modified specifically for TTS reading, so as to achieve perfect tone, timing and pronunciation. You can also include your own logic in the process, for example to craft LLM prompts from line data, or to check and edit LLM outputs before displaying them on screen.
- Modify dialogues live, even while they are being processed: not required by any features, but useful if you want more flexibility in controlling the dialogue script. This can be leveraged for procedural dialogues.
- Add code to UI element scripts to extend features, or to implement custom logic and behavior.
- Create your own custom dialogue modes or custom commands, by just adding code for them to match statements.
- And for very advanced uses, the full code is accessible and can be modified.

Importantly, Candy Dialogue Engine is self-contained: it doesn't secretly leave things in your code or alter variables or project settings. It's just scenes and scripts that you drop-in, call upon when needed, and which you can remove at any time (it's a true asset, not a plugin). It's also flexible enough to adapt to your game, instead of forcing your game to be designed around it.

It's meant to feel as comfortable as your own code, with straightforward logic you can understand and tinker with, not an obscure blackbox or convoluted machinery.

## Usage
Candy Dialogue Engine is intended to be used in conjunction with the [Candy Dialogue Creator](https://github.com/Candy-Arts/Candy-Dialogue-Creator): a free standalone GUI for creating and editing dialogues.

Integrating the dialogue engine to your project is easy and can be done in a couple of minutes:
1. Download the official release.
2. Unpack the compressed file.
3. Copy the Candy_DE folder to your project folder.
4. Open your project in Godot. Go to project settings. In the 'Globals' tab, add two autoloads: Candy_UI.tscn (in Candy_DE/Scenes) with the prefix 'candy_ui', and Candy_Functions.gd (in Candy_DE/Scripts) with the prefix 'candy_de'.
5. In the project settings, go to the 'Input Map' tab. Add a new input, named "Dialogue_Advance" and assign it a key or button of your choice (e.g. spacebar or left mouse button)
6. Done. It's now ready to use with the basic (default) setup.

To learn more about settings and configuration, features, and writing dialogues, see the various guides in the Candy_DE/Documents/Guides folder. We recommend starting with the numbered guides ('1. Basic Setup Guide.pdf' to '7. Translations,pdf') as they cover general information and features you'll probably need to know for any project.

The other guides cover more specialized features: we suggest taking a quick glance to see what Candy Dialogue Engine can do, but only read them more closely when you want to use specific features.

Be sure to also read the 'Important.pdf' document in Candy_DE, as it contains important information you should be aware of early.

## Pricing
We want to encourage game creation, support indie developers, and be fair to studios:

Candy Dialogue Engine is free for non-commercial use, under either the Free Indie License or the Studio License.

Commercial use requires payment under the Starter Indie License, Pro Indie License, or Studio License:
- For indie projects, this is a one-time fee of €100 (Starter Indie) or €500 (Pro Indie) (currently discounted to €50 and €400 until July 2026).
- For other projects (Studio), payment is royalty-based, at a rate of 2.5% on your project's direct revenue.

All licenses provide access to the full features.

Starter and Pro Indie Licenses are valid for life, and can be used for any number of projects without additional payment. 

Free and Starter Indie Licenses have a budget limit of €5000 (per project), while Pro Indie Licenses provide a budget limit of €25000. The budget is the amount of money spent on development, it does not include revenue.

Considering the capabilities of Candy Dialogue Engine, we believe these prices are affordable and generous to indie projects, while studios will likely appreciate the strong return-on-investment value. Importantly, these prices allow us to continue working full-time on improving our assets and developing new ones.

For more information, see our [Licensing](https://candy-arts.com/index.php/licensing/) page.

Certificates to use the Starter and Pro Indie Licenses can be purchased on our [Gumroad](https://candyarts.gumroad.com/) page.

The Free Indie and Studio Licenses don't require purchase, and the certificates to use them are provided with Candy Dialogue Engine directly.

We encourage you to download and test it for free before committing to any purchases, so that you can best decide if it will fit your project's requirements. We're confident that if you give it a fair chance, you'll be persuaded of its ease-of-use, and you'll find many of its features invaluable to your projects and a boost to your productivity.

## Licensing
You can find our licenses on [our website](https://candy-arts.com/index.php/licenses/).

They're quite a long read, but they have the merit of being specific enough to cover even most edge cases. This hopefully makes the conditions clear: you can know exactly how you may use Candy Dialogue Engine, while we remain protected against loopholes created by unusual software distribution or commercialization practices. No ambiguity and unanswered questions.

That said, if you just want to get the bottomline or don't want to deal with lawyer-speak, our [Licensing](https://candy-arts.com/index.php/licensing/) page provides a general overview of our license terms in human form.

We want to especially mention that our licenses protect your from retroactive changes: once you assign a license to a project, we can't force you to accept new terms if you don't want to. The license is 'locked', and you can continue to develop, publish and sell your game under those original terms. We can't even ask that you stop using Candy Dialogue Engine if you don't accept the new license terms.

The only exception are changes that don't negatively impact you, such as updating our brand name in the license text if we ever change it.

We hope this gives you confidence that your projects are safe with us in the long-term.

## Compatibility
Candy Dialogue Engine should work with any version of Godot 4.

It should also work with any operating system that Godot can compile for.

## Bugs and issues
Bugs should be reported here on Github.

We really don't expect security issues considering the nature of Candy Dialogue Engine, but if you find any, please [report them directly to us](https://candy-arts.com/index.php/contact/) (don't report them publicly: someone could exploit them).

## Feedback
We're looking forward to [user feedback](https://github.com/Candy-Arts/Candy-Arts/discussions/categories/candy-de-features) to help us improve Candy Dialogue Engine!

We certainly don't know everything about Godot, or all the different ways game devs might want to use Candy Dialogue Engine, so please let us know if a particular feature, dialogue mode or command could help you.

When adding requested features, we weigh several factors: whether it could serve many users or only a few rare cases, whether it's actually a 'proper' method of achieving something or if there are objectively better methods of doing the same thing, and how much more complex it might make Candy Dialogue Engine to use.
