# save-profiles

Title-screen **Save Manager**: several saves side by side, clone, rename, delete (never the base save), and import the vanilla game's save. Each save shows its progress and the mods it was last written with.

The file work is the engine's `rq.saves.*`; this mod owns the button and window.

## Needs

1. Moru's fork (`RQ_modding_xsystem4`, `-Dmodloader=true`), rebuilt with `rq.saves` (not stock xsystem4 1.0.0)
2. `rqmod` apply into a work copy (`rqmod\apply.ps1`)

## How saves are laid out

```text
<home>\Rance Quest\SaveData             base save (the engine's own folder)
<home>\Rance Quest\Profiles\active.txt  id of the save to open ("" = base)
<home>\Rance Quest\Profiles\base.json   name and mods of the base save
<home>\Rance Quest\Profiles\<id>\save\  full copy of a SaveData folder
<home>\Rance Quest\Profiles\<id>\profile.json
```

A profile is the whole SaveData folder: the game save, the suspend save, CG / music unlocks, and settings. Cloning skips `Backup\`, which belongs to the source. The vanilla game's folder is only ever read.

Playing a save restarts the game for a moment, because the engine reads its save files at startup.

## A friend's first run

1. Open **Save Manager** (top left on the title screen).
2. **From vanilla** copies `Documents\AliceSoft\Rance Quest\SaveData` into a new save.
3. Select it, **Play**. The vanilla save is never written.

Names accept ASCII and kana. The game font cannot draw other characters.

Local-only git. No remote. Do not push until Moru asks.
