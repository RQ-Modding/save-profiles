# Changelog

Each section is a version of the mod, the `version` in `mod.json`. The release workflow copies the
section of a tagged version into the release notes.

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
