# LivePedalboardSystem + LPDisplay — System Specification (v1.1)
**Date:** 2025‑10‑06

## 1. Purpose
LivePedalboardSystem orchestrates **MagicPedalboard** (A/B JITLib chains), **MDMiniLogger**, and the **CommandTree**. **LPDisplay** (controller class: `LPDisplayLayoutWindow`) is the **only** user-facing UI. Legacy window code is **out of scope**.

## 2. Core Concepts
### 2.1 Audio Pedalboard Engine
- **Signal Chains (A/B).** Two parallel chains, each `[sink, ..., source]`, dynamically reconfigurable. Sinks read `\in.ar(2)`; wiring uses `Ndef(left) <<> Ndef(right)`.
- **Processors.** Modular effects (delay, chorus, etc.) operating on stereo unless specified.
- **Exclusivity.** Exactly one chain is audible at a time (A **xor** B), except during intentional crossfades (Option A: silence NEXT at source).

### 2.2 Hierarchical Command Navigation
- **Command Tree.** All actions are nodes in a hierarchical tree navigated by the hex guitar (string → level, fret → branch).
- **Queue.** Completed (or explicitly accepted) paths are queued for execution.

### 2.3 Execution & Feedback
- Executed commands mutate chains (add/bypass/remove processors, set sources, switch chains).
- LPDisplay reflects: chain labels (source→…→sink), **active chain highlight**, status text, and meters.

## 3. Architecture
### 3.1 MagicPedalboard
- Maintains A/B chains as Ndefs; supports rebuilds/crossfades; enforces channel consistency.

### 3.2 LivePedalboardSystem
- Holds references to MagicPedalboard, MDMiniLogger, CommandTree, and (after binding) **LPDisplay** controller/adapter.
- **Binding entry point (preferred):** `autoBindLPDisplay(displayController)` — sets the controller, calls the adapter, and pushes an initial snapshot (see §4).

### 3.3 LPDisplay (LPDisplayLayoutWindow)
- Single window; GUI updates via AppClock; starter must return **`-> a Window`** and bring it front.
- Renders **chain labels**, **active chain highlight**, **status text**, and **meters**.

### 3.4 Meters (SendPeakRMS inside chains)
- **Paths/IDs:** `/peakrmsA` (id **2001**), `/peakrmsB` (id **2002**).
- **Mapping:** HUD scale uses top −6 dB, floor −60 dB, gamma 1.0.
- **Policy:** No retap scripts; taps live inside the Ndefs.

### 3.5 Command Tree Path Resolution (Runtime)
When no explicit path is provided to `LivePedalboardSystem.new(path)`, resolve in this order:
1. `Platform.userExtensionDir/LivePedalboardSuite/LivePedalboardSystem/UserState/MagicPedalboardCommandTree.json`
2. `Platform.userExtensionDir/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json` *(repo default)*
3. *(Legacy, deprecated; warning emitted)* `Platform.userExtensionDir/MDclasses/LivePedalboardSystem/MagicPedalboardCommandTree.json`

## 4. LPDisplay Binding & Snapshot
- **Bind:** `~livePedalboardSystem.autoBindLPDisplay(displayController)` *(preferred)* or adapter-led equivalent.
- **On bind (or via `refreshDisplay`):** push
  - `setChains(chainA_symbols, chainB_symbols)`
  - `setActiveChain(\A | \B)`
  - `setStatus("READY" | presetName | message)`

## 5. Acceptance Criteria
1. Starter bring‑up returns **`-> a Window`** and fronts LPDisplay.
2. Chain labels in LPDisplay reflect the current processor lists (source → … → sink) for A/B.
3. **Active highlight** follows the MagicPedalboard active chain on A/B toggles.
4. **Meters** move under generated audio (no SoundIn). `SendPeakRMS` taps publish to `/peakrmsA`/`/peakrmsB` with ids 2001/2002.
5. Clean exit (no stray Ndefs/OSCdefs from tests).

## 6. Non‑Goals
- Any legacy/alternate window UI for live operation.
- Ad‑hoc meter retap scripts.

## 7. Diagnostics & Logging
- Starter emits `[Start-LPDisplay] ...` messages per step (boot/init/close/open/bind/front).
- Binding emits succinct confirmations (e.g., `[LPS↔LPD] bound`, `[LPS↔LPD] snapshot pushed`).

## 8. Test & Demo Constraints
- Generated audio only for acceptance tests.
- Exclusivity Option A: NEXT silenced at source; crossfade when intentionally switching.

## 9. Future Work
- Fold stable class extensions into base classes (e.g., `autoBindLPDisplay`, system accessors) with acceptance tests.
- Add a minimal `refreshDisplay` entry point if not already present.