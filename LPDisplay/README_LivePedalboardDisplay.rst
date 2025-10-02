LivePedalboardDisplay - README (reStructuredText)
=================================================

Overview
--------
LivePedalboardDisplay is a small toolkit for SuperCollider. It provides:

- LPDisplayLayoutTestWindow - a 6-pane grid window with two meters (A/B) driven by SendPeakRMS, plus simple control methods.
- LPDisplaySigChain - a helper to wire a symbol chain [sink, ..., source] using Ndef(left) <<> Ndef(right) with stereo pre-arming.
- LPDisplayHudMap - an optional mapper converting linear RMS (0..1) to UI (0..1) using a dB window (top/floor) and gamma.

Install
-------
Place the .sc files under this path (copy exactly):

::
    .../PhD_projects/LivePedalboardSuite/LivePedalboardDisplay/Classes/

Ensure the LivePedalboardSuite root is scanned by SuperCollider (usually symlinked into Extensions). Then recompile the class library:

::
    Language -> Recompile Class Library

When loaded, you should see lines like:

::
    LPDisplayHudMap vX.Y.Z loaded (LivePedalboardDisplay)
    LPDisplaySigChain vX.Y.Z loaded (LivePedalboardDisplay)
    LPDisplayLayoutTestWindow vX.Y.Z loaded (LivePedalboardDisplay)

Quick Start
-----------
SuperCollider snippet (copy/paste into the IDE):

::
    (
        var hud = LPDisplayHudMap.new(-6, -60, 1.0);  // top/floor/gamma
        ~inst = LPDisplayLayoutTestWindow.new(hud);
        ~win  = ~inst.open;  // -> a Window
    )

    // Swap tail sources and write a status line
    ~inst.setSourceA(\srcC);
    ~inst.setSourceB(\srcA);
    ~inst.sendPaneText(\diag, "Ready @ " ++ Date.getDate.stamp);

    // HUD on/off
    ~inst.setHudMap(nil);                             // raw 0..1 meters
    ~inst.setHudMap(LPDisplayHudMap.new(-9, -60, 1.0)).printHud;

    // Close
    ~inst.close;

    // Or class-side open (raw meters):
    LPDisplayLayoutTestWindow.open(nil);

Classes
-------
LPDisplayLayoutTestWindow
^^^^^^^^^^^^^^^^^^^^^^^^^^
- Builds a 6-pane grid with top-left/right meters (LevelIndicator).
- Wires two chains: [\outA, \srcA] and [\outB, \srcB] using LPDisplaySigChain.
- Updates meters from SendPeakRMS via OSCdef(\rmsA_toGUI) and OSCdef(\rmsB_toGUI).
- Prints decimated console levels via OSCdef(\rmsA_console) and OSCdef(\rmsB_console).
- Optional HUD mapping via an LPDisplayHudMap instance (or nil for raw values).

Why replyID?
^^^^^^^^^^^^
We keep replyID as A=1 and B=2 in SendPeakRMS.kr(..., '/peakrmsA', 1) and (..., '/peakrmsB', 2) to preserve continuity with older dumps/tools. The OSC addresses already differ; replyID is kept for backward compatibility.

Key instance methods
^^^^^^^^^^^^^^^^^^^^^
- open -> Window, close
- setSourceA(\sym), setSourceB(\sym)
- sendPaneText(\left|\right|\system|\diag|\choices|\recv, "text")
- setHudMap(instanceOrNil), printHud

Class-side utilities
^^^^^^^^^^^^^^^^^^^^^
- .help, .apihelp, .test

LPDisplaySigChain
^^^^^^^^^^^^^^^^^^
- Wires a chain [sink, ..., source] using Ndef(left) <<> Ndef(right).
- Ensures stereo busses and plays the sink.
- Key methods: rebuild, size, symbols (copy), setTailSource(\srcX), chainToString.
- Class-side utilities: .help, .apihelp, .test

LPDisplayHudMap
^^^^^^^^^^^^^^^^
- Maps linear RMS (0..1) to UI (0..1) using a dB window (top/floor) and gamma.
- Pass nil to the window's setHudMap to bypass mapping and show raw values.
- Key methods: set(\top|\floor|\gamma, value), mapLinToUi(linearRms), preview(rmsDb), print.
- Class-side utilities: .help, .apihelp, .test

Smoke Tests
------------
Run these in SuperCollider:

::
    LPDisplaySigChain.test;         // PASS/FAIL (wire/play sink)
    LPDisplayHudMap.test;           // PASS (monotonicity/bounds)
    LPDisplayLayoutTestWindow.test; // opens, checks OSCdefs, flips sources, closes

Troubleshooting
---------------
- Meters not moving:
    OSCdef(\rmsA_toGUI).notNil;  OSCdef(\rmsB_toGUI).notNil.
    Sinks must read ``\in.ar(2)``. Chains should be playing (sink Ndef is .play'ed by LPDisplaySigChain.rebuild).
    If you changed sink OSC addresses, update the OSCdef addresses accordingly.

- string_ DNU on nil:
    The window pre-creates views. If you extend it, create views first, then compose the layout; update UI via ``{ ... }.defer`` with notNil guards.

- Compile errors after edits:
    Class-side methods (*help, *apihelp, *test) must be at class scope (not nested).
    Symbol literals use a single backslash: ``\symbol`` (not ``\\symbol``).

Style and Conventions
----------------------
- *new { ^super.new.init(...) }
- var-first in method bodies; clear names
- No non-local returns inside inner Functions
- GUI updates via ``{ ... }.defer``
- JITLib wiring strictly ``Ndef(left) <<> Ndef(right)``
- Sinks read ``\in.ar(2)``

Versioning
----------
Each class defines classVersion and prints a banner at class load time. You should see lines like these after a recompile:

::
    LPDisplayHudMap vX.Y.Z loaded (LivePedalboardDisplay)
    LPDisplaySigChain vX.Y.Z loaded (LivePedalboardDisplay)
    LPDisplayLayoutTestWindow vX.Y.Z loaded (LivePedalboardDisplay)

Optional: One-button regression
--------------------------------
Save as this path (copy exactly):

::
    LivePedalboardDisplay/Tests/LPDisplay_Smoke_All.scd

SuperCollider script:

::
    (
        var hudPass, sigPass, win, posted;
        hudPass = LPDisplayHudMap.test;
        sigPass = { LPDisplaySigChain.test; true }.value;
        win = LPDisplayLayoutTestWindow.test;
        AppClock.sched(2.0, {
            var allGreen = hudPass and: sigPass;
            ("LivePedalboardDisplay SMOKE: " ++ (allGreen.if("PASS", "WARN/FAIL"))).postln;
            nil
        });
    )