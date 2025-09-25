/*
SuperCollider GUI + Meters: Working Pattern & Pitfalls
v1.0
MD 2025-09-25 10:27

============================================================

✅ WHAT MAKES THIS WORK

1) Separate GUI from Audio Boot
   - Build the window and layout first so something is visible immediately.
   - Use s.waitForBoot Ellipsis or a Routine for audio bring‑up; never block the AppClock.
   - Avoid server.sync in GUI paths to prevent freezes and blank windows.

2) Use Layout Managers for Predictability
   - Prefer GridLayout or VLayout/HLayout so panes resize reliably.
   - Avoid manual Rect math unless you need pixel‑perfect control.

3) Draw Borders with UserView.drawFunc
   - CompositeView does not implement drawFunc_.
   - Create a UserView inside the pane to draw colored borders/fills.

4) Var‑first and Descriptive Names
   - Declare all locals at the top of every block (functions, drawFunc, actions).
   - No single‑letter variables; use paneView, meterColumnView, amplitudeBusA, etc.
   - This prevents parser errors like “unexpected VAR”.

5) Atomic Server Operations
   - If you rewire NodeProxies, wrap changes in Server.default.bind Ellipsis.
   - Keep GUI responsive by avoiding synchronous waits.

6) Smooth, Click‑free Level Changes
   - Apply Lag.kr to amplitude controls before multiplying the audio signal.
   - Update LevelIndicator values on AppClock and defer GUI writes with Ellipsis.defer.

7) Clean Meter Updates
   - Use control buses for metering (Out.kr), and read them with .get on AppClock.
   - Always .defer updates to the actual GUI widgets.

8) Deterministic Cleanup
   - In window.onClose_, stop routines, free buses, and stop+clear Ndefs.
   - Also close any previous MagicDisplayGUI windows on start.

------------------------------------------------------------

⚠️ COMMON PITFALLS

• drawFunc_ on CompositeView has no effect → use UserView.
• Multiple assignment to array elements (e.g., #array[i], … = ...) is invalid → assign to locals first, then store.
• server.sync in GUI code blocks the AppClock → freezes or blank windows.
• Non‑var‑first blocks → “unexpected VAR, expecting …” parse errors.
• Updating widgets directly from audio/server callbacks → must .defer GUI writes.
• Leaving old Ndefs and buses running → audio chaos and resource leaks on re‑run.
• Hard‑coded sizes on HiDPI/Sidecar → panes appear tiny; layouts fix scaling.

------------------------------------------------------------

🔍 EASY‑TO‑OVERLOOK DETAILS

• Close prior MagicDisplayGUI windows before building a new one.
• Free control buses used for meters in onClose_.
• Convert dB → linear with .dbamp and clamp to [0, 1] for LevelIndicator.
• Give LevelIndicator a minSize_ (e.g., Size(20, 180)) so layouts don’t collapse it.
• Add small spacers (UserView().minWidth_/minHeight_) in H/V layouts for readable gaps.
• If GUI must appear even when audio fails, build the window first, then boot server.

------------------------------------------------------------

➡️ UPGRADE PATH / NEXT STEPS

1) Keep the proven GUI skeleton (GridLayout or V/HLayout) and slot in top‑row meters.
2) Add one audible Ndef test source; meter its amplitude via a control bus.
3) Layer routing gradually:
   - one source → one effect → one sink;
   - then two sinks with A/B selection (use Lag/XFade2 to avoid clicks);
   - finally expand to 3 sources, 3 effects, 2 sinks, preserving the GUI contract.
4) Only after routing is stable, attach real meters to each chain point as needed.

------------------------------------------------------------

CHEAT SHEET (DO / AVOID)

DO
- window first; audio later (non‑blocking).
- UserView.drawFunc for borders and custom visuals.
- var‑first, descriptive names everywhere.
- AppClock for GUI updates, with .defer inside callbacks.
- Lag.kr for level changes; XFade2 + Lag for A/B.
- onClose_: stop routines, free buses, clear Ndefs.

AVOID
- server.sync in any GUI path.
- drawFunc_ on CompositeView.
- Multiple assignment to array elements.
- Single‑letter variable names; hidden locals mid‑block.
- Direct GUI writes from non‑GUI threads.

============================================================
*/