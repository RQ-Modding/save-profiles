# Save Profiles

A **Save Manager** on the title screen: keep several saves side by side, and bring in your save from
the original game.

## What it changes

- A **Save Manager** button at the top left of the title screen opens a list of your saves. Each one
  shows its progress and the mods it was last played with.
- **Play** switches to the selected save, after the game's own Yes / No question. The game restarts
  for a moment, because it reads its save files at startup.
- **Clone**, **Rename**, **New empty** and **Delete**. The base save cannot be deleted, and neither
  can the one in use. Delete asks with the game's question, with the cursor on No.
- **From vanilla** copies the original game's save (`Documents\AliceSoft\Rance Quest\SaveData`) into
  a new save. The original is only ever read.
- **Start Game** with no game in the save in use, while the original game's save is further along
  (at least one quest cleared), asks with the game's own question whether to copy that save and play
  from it. **Yes** makes the copy (named "Vanilla copy"), switches to it and starts it. **No** starts
  the new game. **Don't ask again** is ticked from the start: answered with it ticked, the question
  does not come back and Start Game starts the new game. Turn it back on in **Config → Mods →
  Confirmations**. Once the save in use has a game, Start Game never asks.

Names take letters, digits and kana: the game's font cannot draw other characters. The name field
has a caret: **Left**, **Right**, **Home** and **End** move it, **Backspace** and **Delete** erase,
**Ctrl+V** pastes. **Enter** is OK, **Esc** cancels.

## Keys and settings

The window looks and works like the game's own: the arrow keys and **Enter** move between its buttons
and the list, and **Esc** or a right click closes it. No settings.

## Saves

A save here is the whole save folder: the game save, the suspend save, CG and music unlocks, and
settings. They live beside the game's own save folder:

```text
<home>\Rance Quest\SaveData             the base save (the game's own folder)
<home>\Rance Quest\Profiles\active.txt  the save to open ("" = base)
<home>\Rance Quest\Profiles\base.json   name and mods of the base save
<home>\Rance Quest\Profiles\<id>\save\  a full copy of a save folder
<home>\Rance Quest\Profiles\<id>\profile.json
```

A clone skips `Backup\`, which belongs to the source. Switch back to the base save before you remove
the mod; the other saves stay in `Profiles` until you delete them.

## Your first run

Press **Start Game**: if your original game's save is further along, the game asks whether to copy it
and play from it. Or by hand:

1. Open **Save Manager** on the title screen.
2. **From vanilla** copies the original game's save into a new save.
3. Select it and press **Play**.

## Install

Needs [RQ MOD](https://github.com/RQ-Modding/RQ-Mod) with loader **2.44.0** or newer. Extract the
release zip into the game's `mods` folder, so that you have `mods/save-profiles/mod.json`.

## How it works

The file work (list, create, clone, import, rename, delete, switch) is the engine's `rq.saves`. This
mod owns the button and the window, drawn with the loader's UI kit (`rq.uikit`) in the look of the
game's hub.

## License

MIT, see [LICENSE](LICENSE).
