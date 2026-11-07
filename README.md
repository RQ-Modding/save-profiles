# Save Profiles

A **Save Manager** on the title screen: keep several saves side by side, and bring in your save from
the original game.

## What it changes

- A **Save Manager** button at the top left of the title screen opens a list of your saves. Each one
  shows its progress and the mods it was last played with.
- **Play** switches to the selected save. The game restarts for a moment, because it reads its save
  files at startup.
- **Clone**, **Rename**, **New** and **Delete**. The base save cannot be deleted, and neither can the
  one in use.
- **From vanilla** copies the original game's save (`Documents\AliceSoft\Rance Quest\SaveData`) into
  a new save. The original is only ever read.

Names take letters, digits and kana: the game's font cannot draw other characters. **Enter**
confirms, **Esc** cancels.

## Keys and settings

None beyond the window.

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

1. Open **Save Manager** on the title screen.
2. **From vanilla** copies the original game's save into a new save.
3. Select it and press **Play**.

## Install

Needs [RQ MOD](https://github.com/RQ-Modding/RQ-Mod) with loader **0.3.0** or newer. Extract the
release zip into the game's `mods` folder, so that you have `mods/save-profiles/mod.json`.

## How it works

The file work (list, create, clone, import, rename, delete, switch) is the engine's `rq.saves`. This
mod owns the button and the window.

## License

MIT, see [LICENSE](LICENSE).
