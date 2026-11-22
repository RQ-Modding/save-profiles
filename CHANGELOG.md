# Changelog

Each section is a version of the mod, the `version` in `mod.json`. The release workflow copies the
section of a tagged version into the release notes.

## 1.3.0

Needs loader 2.65.0.

- The custom characters' face screen named the original game's folder
  (`<My Documents>\AliceSoft\Rance Quest\SaveData`), while the game reads the faces from the
  `Face CG` folder of the save in use. Its box now shows that folder, and an **Open folder** button
  beside **NEXT** opens it; its tip gives the whole path.
- As the face screen opens, the pictures in the original game's `Face CG` folder that the save in
  use lacks (by file name) are copied in, and the box says how many. Nothing is overwritten, and the
  original folder is only read. A setting in **Config → Mods → Save Profiles** turns it off.

## 1.2.0

Needs loader 2.44.0.

- **Start Game** with no game in the save in use, while the original game's save is further along (a
  quest cleared), asks whether to copy that save and play from it. Yes copies it, switches to the
  copy and starts it by itself after the restart; No starts the new game.
- The question's **Don't ask again** is ticked from the start. Left ticked, the question does not
  come back; it is listed on Config's Mods tab, **Confirmations**, to turn it back on.

## 1.1.0

Needs loader 2.29.0.

- The button and the Save Manager in the game's look, with the loader's UI kit: the hub's buttons,
  a list with the game's scroll bar, and a page that Esc or a right click closes.
- The arrow keys and Enter move between the buttons and the list.
- Play and Delete ask with the game's own Yes / No question; Delete starts on No.
- The name field has a caret (Left, Right, Home, End, Backspace, Delete) and pastes with Ctrl+V.
- Agents type a name with `rqmod-ctl type`. The controls have the kit's ids (see `TESTING.md`).

## 1.0.0

First version.

- A Save Manager on the title screen: several saves side by side, clone, rename, new, delete (never
  the base save) and import from the original game. Each save shows its progress and its mods.
