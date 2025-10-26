# JobTracker

JobTracker is a Windower addon to plan and track job usage for Odyssey Sheol Gaol runs. It shows a 6×3 assignment grid (party slots P1–P6 by three rounds R1–R3) and a clickable palette of all 22 jobs.

## Features

- 22-job palette (WAR, MNK, WHM, … RUN)
- 6×3 grid for assignments (P1–P6 rows, R1–R3 columns)
- Color coding:
  - Blue: Job not assigned in any round
  - Yellow: Job assigned somewhere in the grid
  - Green: Currently selected job in the palette
- Click to select and assign jobs; right‑click to clear cells
- Draggable handle to move the UI; font size control
- Rename round headers and share a summary to party chat
- Settings persist across sessions (position, font, names, assignments)

## Installation

1. Copy the `JobTracker` folder into your Windower `addons` directory.
2. Load the addon in-game:
   ```
   //lua load JobTracker
   ```

## UI and Interaction

- Left‑click a job in the palette to select/deselect it (turns green).
- With a job selected, left‑click a grid cell (P1–P6 × R1–R3) to assign it.
- Right‑click a grid cell to clear its assignment.
- Drag the `[JT]` handle to reposition the entire UI.
- Assigned jobs are unique: assigning a job moves it from any previous cell.

## Commands

Use `//jobtracker` or `//jt` followed by one of the commands below:

- Round names
  - `//jt round1 <name>`
  - `//jt round2 <name>`
  - `//jt round3 <name>`
  - Sets the column headers (defaults are R1, R2, R3).

- Reset
  - `//jt reset`
  - Clears all assignments and deselects the current job.

- Font size
  - `//jt font` — shows current size
  - `//jt font <8–48>` — sets size and updates layout

- Share to party chat
  - `//jt share` or `//jt party`
  - Prints one line per round, e.g. `R1: P1 WAR, P3 COR, …`

- Debug
  - `//jt debug [on|off|toggle]`
  - Toggles verbose logging to chat for troubleshooting.

## Notes

- The UI saves position, font size, round names, and assignments automatically.
- Colors and behavior match the current addon logic; there is no “red” state.

Enjoy and good luck with your runs!
