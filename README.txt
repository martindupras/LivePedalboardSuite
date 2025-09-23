
README.txt — LivePedalboardSuite Overview
========================================

LivePedalboardSuite is a modular, scriptable, and extensible live audio processing environment for SuperCollider. It is designed for rapid prototyping, testing, and demonstration of pedalboard-style audio effect chains, with or without hardware integration.

Project Structure
-----------------
- **Scripts/** — Demo scripts, playbooks, and acceptance tests (e.g., Demo_Today_Playbook_FallbackOnly.scd)
- **LivePedalboardSystem/** — Core system classes, adapters, and utilities
- **MagicPedalboardNew.scd** — Main pedalboard engine (chain management, switching, bypass, etc.)
- **Adapters/** — Bridges for hardware or OSC-based control (e.g., CommandTree adapter)
- **Processors/** — Effect definitions (delay, chorus, drive, etc.)
- **GUI/** — MagicDisplayGUI and related visual components
- **Utilities/** — Helper scripts, test utilities, and fallback routines

Main Components
---------------
- **LivePedalboardSystem**: Top-level system manager. Handles bring-up, shutdown, and coordination of pedalboard, GUI, and adapters.
- **MagicPedalboardNew**: The core pedalboard class. Manages two chains (CURRENT and NEXT), supports adding/removing/bypassing effects, switching with crossfade, and enforcing Option A (exclusive audio path).
- **Adapters**: Optional bridges (e.g., ~ct_applyOSCPathToMPB) that translate high-level commands (like /add/delay) to pedalboard actions, supporting both hardware and software control.
- **Processors**: Individual effect modules (delay, chorus, reverb, etc.), defined as SynthDefs or Ndefs, and added to chains by symbolic name.
- **GUI**: MagicDisplayGUI provides a visual overview of chain state, effect status, and demo progress. Level meters and HUDs may be included.

How It Works
------------
- **Bring-up**: Start_LivePedalboardSystem.scd initializes the system, pedalboard, GUI, and (optionally) adapters.
- **Demo Scripts**: Scripts like Demo_Today_Playbook_FallbackOnly.scd apply a sequence of canonical commands (e.g., /add/delay, /switch) to demonstrate effect switching, bypass, and chain management.
- **Audio Sources**: Uses generated sources (e.g., Ndef(\testmelody)) for hardware-independent testing. Option A ensures only one chain is audible at a time.
- **Adapters**: If present, adapters handle OSC or hardware commands; otherwise, scripts call pedalboard methods directly.
- **GUI**: The GUI updates in response to commands, showing current/next chain, effect status, and demo progress.

Customization & Extensibility
-----------------------------
- Add new effects by defining new SynthDefs/Ndefs and registering them as processors.
- Extend adapters for new hardware or OSC protocols.
- Write new demo scripts/playbooks for custom test scenarios.

Troubleshooting & Support
-------------------------
- See StartHere.txt for step-by-step instructions and troubleshooting tips.
- Check the SuperCollider console for errors and warnings.
- For advanced debugging, inspect ~system, ~system.pedalboard, and GUI state.


Happy patching!
