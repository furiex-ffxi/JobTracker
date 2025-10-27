# JobTracker

JobTracker is a Windower addon to plan and track job usage for Odyssey Sheol Gaol runs. It shows a 6×3 assignment grid (party slots P1–P6 by three rounds R1–R3) and a clickable palette of all 22 jobs.

<img width="555" height="235" alt="image" src="https://github.com/user-attachments/assets/87838287-ab03-471b-b412-7fccd88a3f26" />

<img width="487" height="58" alt="image" src="https://github.com/user-attachments/assets/ac1e66e2-2fdf-41e9-817f-7bffed1b7688" />

## Features

- 22-job palette (WAR, MNK, WHM, … RUN)
- 6×3 grid for assignments (P1–P6 rows, R1–R3 columns)
- Color coding:
  - Blue: Job not assigned in any round
  - Yellow: Job assigned somewhere in the grid
  - Green: Currently selected job in the palette
- Click to select and assign jobs; right‑click to clear cells
- Draggable handle to move the UI; font size control
- Rename round headers and player rows, and share a summary to party chat
- Player labels show the first three characters in the UI while preserving full names for chat sharing
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
- Left‑click a grid cell with no job selected to clear its assignment.
- Drag the `[JT]` handle to reposition the entire UI.
- Assigned jobs are unique: assigning a job moves it from any previous cell.

## Commands

Use `//jobtracker` or `//jt` followed by one of the commands below:

- Round names
  - `//jt round1 <name>`
  - `//jt round2 <name>`
  - `//jt round3 <name>`
  - Sets the column headers (defaults are R1, R2, R3).

- Player names
  - `//jt player1 <name>` through `//jt player6 <name>`
  - `//jt p1 <name>` through `//jt p6 <name>` (alias for the above)
  - Sets the row labels (defaults are P1–P6).
  - Names are stored with the first letter capitalized and the rest lowercase.
  - Only the first three characters show in the UI; the full name is used for chat output.

- Reset
  - `//jt reset`
  - Clears all assignments and deselects the current job.

- Font size
  - `//jt font` — shows current size
  - `//jt font <8–48>` — sets size and updates layout

- Share to party chat
  - `//jt share` or `//jt party`
  - Prints one line per round, e.g. `Round A: Tank WAR, Support COR, …`

- Debug
  - `//jt debug [on|off|toggle]`
  - Toggles verbose logging to chat for troubleshooting.

- Help
  - `//jt help`
  - Prints the list of available commands to chat.

## Notes

- The UI saves position, font size, round names, player names, and assignments automatically.
- Colors and behavior match the current addon logic; there is no “red” state.

Enjoy and good luck with your runs!
