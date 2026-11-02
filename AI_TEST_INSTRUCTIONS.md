# Save Manager — agent notes

Optional file, read only because this mod is installed. If `saves-open` is not in `rqmod-ctl ui`, the Save Manager is not there.

## When the controls exist

`saves-open` exists only on the title screen while it waits for a choice (`rq.saves.title()`). The window controls exist only while the manager is open. Prompt and confirm dialogs hide the list controls.

Typed text needs a real keyboard event. `rqmod-ctl key` only sets key state, so it cannot type a name. Prompts start with a default name, so `saves-ok` still works. `press` also sends Enter, which confirms a prompt that is already open.

## Control ids

| id | when | role |
| --- | --- | --- |
| `saves-open` | title screen | opens the manager |
| `saves-close` | manager open | closes it |
| `saves-row-N` | manager open | selects the Nth save (1 = base) |
| `saves-play` | selected save is not active | confirm, then restart on that save |
| `saves-clone`, `saves-rename`, `saves-new` | manager open | open the name prompt |
| `saves-import` | vanilla save found | imports it (name prompt) |
| `saves-delete` | selected save is not base or active | confirm dialog |
| `saves-ok`, `saves-cancel` | name prompt | |
| `saves-confirm`, `saves-cancel` | confirm dialog | |
| `saves-scroll-up`, `saves-scroll-down` | more than six saves | |

All are HUD rectangles. After `saves-confirm` on Play the process exits and a new one starts. The pipe belongs to the new process once it is up. Only keep one game instance open, or the pipe may answer from the wrong one.

Do not test delete or Play on the base save. Work on a clone.
