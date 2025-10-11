
# LivePedalboardSystem

## Overview
This system integrates the MagicPedalboard audio engine with a hierarchical CommandTree navigated via MIDI guitar input. It is designed for live performance, modular control, and real-time feedback.

## Purpose
The `LivePedalboardSystem` class coordinates the bring-up of:
- MagicPedalboard (audio engine and GUI)
- CommandTree (navigation and command queue)
- MIDI input routing
- Tree loading from JSON

## Directory Structure
```
MDClasses/
  LivePedalboardSystem/
    LivePedalboardSystem.sc         # Main integration class
    Start_LivePedalboardSystem.scd  # Launcher script
    MagicPedalboardCommandTree.json # Command tree definition
```

## Bring-Up Sequence
1. **Initialize MagicPedalboard**
   - Boot server
   - Create pedalboard and GUI/test runner

2. **Load CommandTree**
   - Load `MagicPedalboardCommandTree.json`
   - Build tree structure in memory

3. **Set Up MIDI Input**
   - Initialize MIDI manager
   - Bind guitar and foot controller devices

4. **Connect Tree to Pedalboard**
   - Route queued commands to pedalboard adapter

5. **Enable Feedback Display**
   - Show navigation state, queue, and status

## Class Responsibilities
### `LivePedalboardSystem`
- `.bringUpAll` — Initializes all subsystems
- `.shutdownAll` — Graceful shutdown (optional)
- `.reloadTree` — Reloads tree from JSON
- `.showStatus` — Posts current system state

## Launcher Script
Example: `Start_LivePedalboardSystem.scd`
```supercollider
(
~system = LivePedalboardSystem.new;
~system.bringUpAll;
)
```

## Notes
- Tree file uses preferred frets: 1, 3, 5, 7, 9
- Payloads are OSC-style paths usable by MagicPedalboard
- Class name can be changed later (e.g. `MDPerformanceSystem`)

## Next Steps
- Implement `LivePedalboardSystem.sc` class
- Test launcher script
- Confirm MIDI routing and pedalboard command execution

