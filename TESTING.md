# Testing Save Profiles

For people and agents who test the mod in the game. Read it before you use anything the mod adds. If
`button-saves-open` is not in `rqmod-ctl ui`, the Save Manager is not there.

## When the controls exist

`button-saves-open` exists only on the title screen while it waits for a choice (`rq.saves.title()`).
The manager's controls exist only while it is open. While the name prompt shows, the manager's
buttons and rows are disabled (`enabled` false); the prompt's controls are on top.

All controls are `rq.uikit` widgets (`section` "kit" in `rqmod-ctl ui`): `press` clicks them and
sends no Enter to the game.

## Typing a name

The prompt's field types as soon as it shows, with the default name and the caret at its end. Type
with `rqmod-ctl type "<text>"` (UTF-8; characters the game's font cannot draw are dropped). Hold
`backspace` with `rqmod-ctl hold backspace` / `release backspace` to clear the default name: it
repeats after 250 ms, then every 50 ms. `key left`, `right`, `home`, `end` and `delete` move the caret
and erase at it; Ctrl+V pastes the system clipboard. `key enter` is OK (when the name is not blank),
`key esc` is Cancel. `input-saves-name`'s `value` is the name as typed so far (no `value` while it is
empty), and `selected` is true while it types.

## Control ids

| id | when | role |
| --- | --- | --- |
| `button-saves-open` | title screen | opens the manager |
| `page-saves` | manager open | the manager; Esc or a right click closes it |
| `button-close-saves` | manager open | closes it |
| `row-saves-<name>` | manager open | selects a save; `label` is its name (`(in use)` after the save in use), `value` its place in the list, `selected` the one picked |
| `button-saves-play` | the picked save is not in use | asks with the game's dialog, then restarts on that save |
| `button-saves-clone`, `button-saves-rename`, `button-saves-new` | manager open | open the name prompt |
| `button-saves-import` | a vanilla save was found | opens the name prompt, then imports it |
| `button-saves-delete` | the picked save is not the base save or the one in use | asks with the game's dialog (cursor on No) |
| `page-saves-name` | name prompt | the prompt; its close, Esc or a right click cancel |
| `input-saves-name` | name prompt | the name field |
| `button-saves-ok`, `button-saves-cancel` | name prompt | OK is disabled while the name is blank |

A row's id is the kit's slug of `saves-` and its text, cut to 28 characters: find a row by its
`label` rather than by its id. The list has the game's scroll bar when the saves do not fit.

Play and Delete open the game's dialog: `rq.ui.get` shows the screen `select` with `yes` and `no`.
After `yes` on Play the process exits and a new one starts. The pipe belongs to the new process once
it is up. Only keep one game instance open, or the pipe may answer from the wrong one.

Do not test Delete or Play on the base save or on a save you did not make. Work on a clone, and
delete only the saves you made.

## The Test Lab

The Lab's `save-profiles` scenario runs on the title screen before a save loads: it opens the
manager, clones, renames and makes saves with typed names, deletes them through the game's dialog
(No, then Yes), and checks that the save in use and the saves it found are unchanged. It never
presses Play's Yes.
