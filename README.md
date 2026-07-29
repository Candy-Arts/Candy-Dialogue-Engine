![Candy Arts Logo](Logo.svg)

# Candy Dialogue Engine
**[Candy Dialogue Engine](https://candy-arts.com/index.php/candy-dialogue-engine) by [Candy Arts](https://candy-arts.com) is an extensive and powerful Dialogue System for Godot. More than that, it's also a Visual Novel Engine, Media Synchronizer, Cutscene Orchestrator, Narrative Manager, and Mod Support Solution.**

![](https://candy-arts.com/wp-content/uploads/2026/02/Cyberpunk-Combat.png)
*<sub>Disclaimer: Images in this document are provided for illustrative purposes. Images were rendered in-engine using Candy DE's capabilities and may include AI-generated art assets.<sub>*

## Table of Contents
- [Features](#features)
- [Compatibility](#compatibility)
- [Instructions](#instructions)
- [Candy Dialogue Creator](#candy-dialogue-creator)
- [Documentation](#documentation)
- [Pricing](#pricing)
- [Bugs and issues](#bugs-and-issues)
- [Feedback](#feedback)

## Features
![](https://candy-arts.com/wp-content/uploads/2026/02/Visual-Novel-Example-2.png)

**Candy Dialogue Engine was designed to achieve five core goals:**
1. Make dialogues fast and simple to write.
2. Adapt to any game type or genre.
3. Provide or support any features developers may need.
4. Make dialogue synchronization with game events easy.
5. Allow full code and UI customization.

**To that end, Candy Dialogue Engine combines the usual tools you need for speech and narrative crafting, plus more:**
- Different dialogue modes with various settings and options: dialogue box with portrait, subtitles, speech bubbles, chat box…
- Voiced dialogue support.
- VN busts and background image display.
- Full UI customization without coding.
- Branching dialogues / Conditions.
- Call functions and emit/detect signals.
- Player choices and input prompts.
![](https://candy-arts.com/wp-content/uploads/2026/02/Choices-Example.png)
- Media playback controls.
- Variable modification and display.
- Cutscene scripting.
- Gender-based word substitution (or other attributes).
- Gendered and random variants (or other attributes).
- Lexicon (Glossary).
![](https://candy-arts.com/wp-content/uploads/2026/08/YourStyleExample2.webp)
- Localization/Translation features.
- Support features for Text-To-Speech and LLM-generated dialogue.
- Dialogue live edit at runtime, parallel dialogues, dialogues as a modding/programming layer.
- Fully accessible and expandable code.
- Standalone dialogue editing GUI with simple ‘click to add line, fill in data, don’t type syntax’ approach.

You can see the extended feature list [here](Feature_List.md).

## Compatibility
Candy Dialogue Engine 1.2 is compatible with Godot 4.7+

## Instructions
### Installation
Candy Dialogue Engine should be installed through the Candy DE Wizard.
1. Download the Wizard [here](https://github.com/Candy-Arts/Candy_DE_Wizard).
2. Place it in your project's 'addons' folder (if you don't have it, create it).
3. Enable the Wizard in Godot: Project > Project Settings > Plugins
4. In the bottom dock, open the 'Candy Dialogue' tab.
5. Follow the prompts to install Candy Dialogue Engine.

### Updates
Updates are performed through the Wizard. The Wizard notifies you when an update is available.

### Upgrades
If you're upgrading from Candy Dialogue Engine 1.1.3, the process is the same as installation, except you will be prompted to upgrade to 1.2.0.

**Note that some things will be incompatible from 1.1 to 1.2 and will need to be edited or remade:**<br>
• This is mostly custom code: hook functions, commands and dialogue modes, UI scripts.<br>
• Custom UI scenes should continue to work but some may need a couple minor modifications. The Chat UI will not work at all.<br>
• Dialogues can be converted to the 1.2 format, but a few commands require minor manual edits in some cases.<br>
• User data will be preserved: the actors dictionary, roles, lexicon, word substitution, translation tables, etc.<br>
• Some engine settings and a couple actor keys have changed and require manual editing to restore the desired dialogue behavior.<br>

The Wizard will give you a more precise list before you upgrade, and a detailed list after upgrading.

## Candy Dialogue Creator
Dialogues are written in Candy Dialogue Creator: a separate, free application.

Download an exported (compiled) build for your operating system [here](https://github.com/Candy-Arts/Candy-Dialogue-Creator).

## Documentation
The documentation can be found [here](https://candy-arts.com/index.php/docs/).

The Wizard can also download and setup our Candy Database plugin, to let you browse the documentation directly inside the Godot editor.

## Pricing
We offer three licensing tiers:

**Free:**<br>
• Free - Pay €0.<br>
• 1-5 project Creators.<br>
• €7'500 budget limit.<br>
• Non-commercial use only.

**Indie:**<br>
• One-time fee - Pay €100 once, make unlimited projects.<br>
• 1-5 project Creators.<br>
• €7'500 budget limit.<br>
• Commercial use allowed.

**Professional:**<br>
• Budget-based - Pay €250 for each budget interval of €25'000.<br>
• No seat limits.<br>
• No budget limits.<br>
• Commercial use allowed.

See our [licensing overview]() and related pages for details.

## Bugs and issues
Bugs should be reported [here](https://github.com/Candy-Arts/Candy-Dialogue-Engine/issues).

## Feedback
Your [feedback](https://github.com/Candy-Arts/Candy-Arts/discussions/categories/candy-de-features) helps us improve Candy Dialogue Engine and add features you need.


