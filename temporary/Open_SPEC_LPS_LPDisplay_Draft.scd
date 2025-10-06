// Open_SPEC_LPS_LPDisplay_Draft.scd
// v1.0.0
// MD 20251006-1530

/*
Purpose
- Open the LPDisplay-focused system SPEC in a SC Document so you can review & save.
*/

(
var nowStamp, lines, doc;
nowStamp = Date.getDate.stamp;

lines = [
"# LivePedalboardSystem + LPDisplay — System Specification",
"**Version:** 1.0 (" ++ nowStamp ++ ")",
"",
"## 1. Purpose",
"LivePedalboardSystem orchestrates **MagicPedalboard** (A/B JITLib chains), **MDMiniLogger**, and the **CommandTree**. The **LPDisplay** UI (controller: `LPDisplayLayoutWindow`) is the *only* user-facing display. The old window code is out of scope.",
"",
"## 2. Architecture Overview",
"- **MagicPedalboard**",
"  - Two chains: **A** and **B** (Ndefs).",
"  - Wiring operator: `Ndef(left) <<> Ndef(right)`; sinks read `\\in.ar(2)`.",
"  - Exclusivity: only one chain audible at a time (A or B), enforced at the source.",
"- **Meters**",
"  - Meters update via `SendPeakRMS` taps **inside** the active chains, publishing to:",
"    - `/peakrmsA` (id **2001**), `/peakrmsB` (id **2002**).",
"  - HUD/UI mapping uses headroom: **top −6 dB**, **floor −60 dB**, **gamma 1.0** (PerfHUD/LPDisplay convention).",
"- **LPDisplay (controller: `LPDisplayLayoutWindow`)**",
"  - Renders: chain labels (processor lists), active chain highlight, status text, meters.",
"  - GUI refresh: **AppClock** only; single window returned by bring‑up (`-> a Window`).",
"- **LivePedalboardSystem**",
"  - Holds references to MagicPedalboard, MDMiniLogger, CommandTree, and (after binding) LPDisplay controller/adapter.",
"  - Provides **one binding entry point** to connect LPDisplay and push a snapshot (see §4).",
"",
"## 3. OSC & IDs",
"- `/peakrmsA` id **2001**, `/peakrmsB` id **2002** (two floats payload: peak + RMS/approx‑amp as used by the HUD).",
"- No alternate paths or “retap” scripts; taps live **inside** the chains.",
"",
"## 4. Binding LPDisplay",
"- System‑led binding (preferred):",
"  - `~livePedalboardSystem.autoBindLPDisplay(displayController)` sets the controller and calls the adapter under the hood.",
"  - On bind (or via `refreshDisplay`), the system must push:",
"    - `setChains(chainA_symbols, chainB_symbols)`",
"    - `setActiveChain(\\A | \\B)`",
"    - `setStatus(\"READY\" | presetName | message)`",
"- Optional: `~livePedalboardSystem.enableAutoMeters` installs taps via the project’s canonical helpers.",
"",
"## 5. Acceptance Criteria",
"1. **Bring‑up** (starter returns `-> a Window`) shows LPDisplay window front.",
"2. **Chain labels** reflect the current processor lists (source → … → sink) for A and B.",
"3. **Active highlight** follows the MagicPedalboard active chain (A/B toggle).",
"4. **Meters** move whenever audio is generated internally (no SoundIn needed).",
"5. On exit, all test resources are cleaned (no stray Ndefs or OSCdefs).",
"",
"## 6. Non‑goals",
"- The old window/UI code is not used for live operation.",
"- No ad‑hoc retap scripts; only `SendPeakRMS` taps inside the chains.",
"",
"## 7. Diagnostics",
"- Starter emits `[Start-LPDisplay] ...` logs at each step.",
"- System binding emits `[LPS↔LPD] bound/updated` logs (adapter/bridge are encouraged to post succinct confirmations)."
];

doc = Document.new("SPEC_LivePedalboardSystem_LPDisplay.md", lines.join(Char.nl.asString));
doc.front;
doc
)
