// RunBook_20251002-Now.scd
// MD + Copilot
// 2025-10-02

/*
--- > RUN BLOCK BY BLOCK! <---
Goal:
- LivePedalboardSystem up (headless)
- LPDisplay Layout Test window as the only UI
- Name-based navigation -> canonical paths -> adapter bridge -> MPB
- Retap meters so LPDisplay shows chain A/B from LPS (not demo sources)

Style:
- var-first; Server.default.bind for server ops; AppClock-only for UI; no ^ returns.
*/


// =======================================
// 0) Preflight cleanup (safe, idempotent)
// =======================================
(
var wins, keys, syms;

wins = Window.allWindows.select({ |w|
    (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI")
    or: { w.tryPerform(\name) == "Layout Test" }
});
wins.do(_.close);

// Free LPDisplay demo responders (if they exist)
keys = [ \rmsA_toGUI, \rmsB_toGUI, \rmsA_console, \rmsB_console ];
keys.do({ |k| var d = OSCdef(k); if(d.notNil) { d.free } });

// Stop LPDisplay demo Ndefs (if present)
syms = [ \srcA, \srcB, \srcC, \srcZ, \outA, \outB ];
syms.do({ |sym| var nd = Ndef(sym); if(nd.notNil) { nd.stop } });

// Remove any prior visualization taps we may have installed
Server.default.bind({
    if (Ndef(\chainA).notNil) { Ndef(\chainA).clear(\lpdispTapA) };
    if (Ndef(\chainB).notNil) { Ndef(\chainB).clear(\lpdispTapB) };
});

"Cleanup done.".postln;
)


// ====================================================
// 1) Bring up LPDisplay window (quiet its demo sources)
// ====================================================
(
var inst, win;

// Create controller + open one window (-> a Window)
inst = LPDisplayLayoutTestWindow.new(nil);   // nil HUD -> raw meters
win  = inst.open;

// Silence LPDisplay’s own demo tail sources so visual feed will come from LPS retaps
inst.setSourceA(\srcZ);
inst.setSourceB(\srcZ);

// Optional console gate (only if you added it earlier)
try { inst.setConsoleLevelsOn(false) } { };

// Export convenience
~inst = inst; ~win = win;

// Ready check
[ inst.notNil, win.notNil, win.class ].postln;

// Final expression (shows “-> a Window”)
win
)


// ========================================
// 2) Bring up LivePedalboardSystem headless
// ========================================
(
var system;

system = LivePedalboardSystem.new(nil);
system.ensureServerReady;
system.bringUpPedalboard;      // MagicPedalboardNew
system.bringUpCommandSystem;   // CommandManager + MIDI
system.installAdapterBridge;   // routes canonical paths to MPB

~system = system;

"OK: LPS up (headless UI).".postln;
[ ~system.notNil, ~system.pedalboard.notNil, ~system.commandManager.notNil ].postln;

// (Optional) Assert 2ch & materialize buses (does not force play/stop)
Server.default.bind({ Ndef(\chainA).ar(2); Ndef(\chainB).ar(2); });
)


// ============================================================
// 3) Retap meters so LPDisplay follows LPS chain ends (A & B)
//    - Safe pass-through filters, idempotent, no rewiring.
//    - Sends to BOTH address families LPDisplay likely uses.
// ============================================================
(
var rateHz;
rateHz = 20;

Server.default.bind({
    if (Ndef(\chainA).notNil) {
        Ndef(\chainA).filter(\lpdispTapA, { |in|
            var sig = in.isArray.if({ in }, { [in, in] });
            var rms = RMS.kr(sig, 500);  // [L,R] linear 0..1
            var t   = Impulse.kr(rateHz);
            SendReply.kr(t, "/peakrmsA",  [rms[0], rms[1]], 1);   // console/legacy
            SendReply.kr(t, "/rmsA_toGUI",[rms[0], rms[1]], 1);   // GUI direct
            in
        });
    };
    if (Ndef(\chainB).notNil) {
        Ndef(\chainB).filter(\lpdispTapB, { |in|
            var sig = in.isArray.if({ in }, { [in, in] });
            var rms = RMS.kr(sig, 500);
            var t   = Impulse.kr(rateHz);
            SendReply.kr(t, "/peakrmsB",  [rms[0], rms[1]], 2);
            SendReply.kr(t, "/rmsB_toGUI",[rms[0], rms[1]], 2);
            in
        });
    };
});

"LPDisplay retap installed.".postln;

// Quick confirm: which responders are alive in the window?
[ OSCdef(\rmsA_toGUI).notNil, OSCdef(\rmsB_toGUI).notNil,
  OSCdef(\rmsA_console).notNil, OSCdef(\rmsB_console).notNil ].postln;
)


// ==================================================================
// 4) Inline emulator (no MIDI): name-based navigation + canonical IO
//     - Avoids the old external emulator file.
//     - Avoids calling mpb.switch() (problematic).
// ==================================================================
(
var cm, mm, builder;
var longFromBuilder, canonicalize, applyCanonical;
var showChildren, navName, navFret;

// --- var-first assignments
cm      = ~system.commandManager;
mm      = cm.midiManager;
builder = cm.builder;

~cm = cm; ~mm = mm;

// Sanity line: queue callback presence (we don't rely on the old one)
[ ~system.notNil, cm.notNil, mm.notNil, (cm.queueExportCallback.notNil) ].postln;

// Build long path from builder (“/a/b/c”, without “/root”)
longFromBuilder = {
    var names, filtered;
    names    = builder.currentNode.getPathToRoot;           // ["root", ...]
    filtered = (names.size > 1).if({ names.copyRange(1, names.size-1) }, { [] });
    ^("/" ++ filtered.join("/"))
};

// Map long -> short canonical expected by adapter
canonicalize = { |rawPath|
    var parts, first;
    parts = rawPath.asString.split($/).reject({ |s| s.size == 0 });
    if (parts.isEmpty) { ^rawPath.asString };
    first = parts[0].asString;

    // canonical verbs are pass-through
    if (#["add","remove","clear","bypass","swap","setSource","switch"].includes(first)) {
        ^("/" ++ parts.join("/"));
    };

    if (first == "switch") { ^"/switch" };

    if (first == "chain") {
        if (parts.size >= 3 and: { parts[1] == "add" } and: { parts[2] == "audio" }) {
            ^("/add/" ++ parts.last.asString)
        };
        if (parts.size >= 5
            and: { parts[1] == "setsource" }
            and: { parts[2] == "audio" }
            and: { parts[3] == "source" }) {
            ^("/setSource/" ++ parts.last.asString)
        };
    };

    ^rawPath.asString
};

// Apply canonical via adapter bridge (robust)
applyCanonical = { |shortPath|
    var bridge, applied;
    bridge  = ~system.tryPerform(\adapterBridge);
    applied = false;

    if (~system.respondsTo(\applyCanonicalPath)) {
        ~system.applyCanonicalPath(shortPath); applied = true;
    } {
        if (bridge.notNil and: { bridge.respondsTo(\applyPath) }) {
            bridge.applyPath(shortPath); applied = true;
        };
    };

    (applied.if({ "Adapter applied: ".post; }, { "Adapter (fallback log only): ".post; });
     shortPath.postln);

    ^shortPath
};

// Helpers
showChildren = {
    var info = builder.currentNode.children.collect({ |n| [n.name, n.fret] });
    ("Children (name, fret): " ++ info.asString).postln;
    ^info
};

navName = { |nameString|
    builder.navigateByName(nil, nameString.asString);
    cm.updateDisplay;
    showChildren.();
};

// Optional: still support fret navigation if you want to match current JSON mapping
navFret = { |stringNum, fretNum|
    builder.navigateByFret(stringNum, fretNum);
    cm.updateDisplay;
    showChildren.();
};

// Expose top-level aliases
~toProg = {
    cm.currentState = \prog;
    cm.updateDisplay;
    "Navigation started (prog).".postln;
    showChildren.();
};
~navName       = navName;
~navFret       = navFret;
~showChildren  = showChildren;
~showNav       = {
    var long = longFromBuilder.();
    var short = canonicalize.(long);
    ("Long:  " ++ long).postln;
    ("Short: " ++ short).postln;
};
~toQueue       = {
    var short = canonicalize.( longFromBuilder.() );
    cm.queue.enqueueCommand(short);
    ("Queued: " ++ short).postln;
    short
};
~toSend        = {
    var short = canonicalize.( longFromBuilder.() );
    applyCanonical.(short);
    short
};
)


// ========================================
// 5) Scenario A — Add Delay (name-based)
// ========================================
(
~toProg.();                 // enter navigation
~navName.("audio");
~navName.("timebased");
~navName.("delay");
~showNav.();                // should print Short: /add/delay
~toQueue.();                // queue "/add/delay"
~toSend.();                 // apply via adapter (listen for "Adapter applied: /add/delay")
)


// =======================================
// 6) Scenario B — Switch chains (adapter)
// =======================================
(
~toProg.();
~navName.("switch");
~showNav.();                // should print Short: /switch
~toQueue.();
~toSend.();                 // apply via adapter (no direct mpb.switch calls)
)


// ===================================================
// 7) If nothing changes: run these micro-diagnostics
//    (Paste one block at a time and post the output)
// ===================================================

// 7A: Adapter bridge presence + method
(
[ \hasBridge: ~system.respondsTo(\adapterBridge),
  \bridgeClass: (~system.tryPerform(\adapterBridge) ? \nil).class,
  \applyPathMethod: (~system.tryPerform(\adapterBridge).respondsTo(\applyPath) ? true : false)
].postln;
)

// 7B: Which responders are live in LPDisplay window?
(
[ \rmsA_toGUI: OSCdef(\rmsA_toGUI).notNil,
  \rmsB_toGUI: OSCdef(\rmsB_toGUI).notNil,
  \rmsA_console: OSCdef(\rmsA_console).notNil,
  \rmsB_console: OSCdef(\rmsB_console).notNil
].postln;
)

// 7C: Are chains alive and stereo?
(
Server.default.bind({ Ndef(\chainA).ar(2); Ndef(\chainB).ar(2); });
[
  \chainA_isPlaying: Ndef(\chainA).isPlaying,
  \chainB_isPlaying: Ndef(\chainB).isPlaying,
  \busA: (Ndef(\chainA).bus ? \nil),
  \busB: (Ndef(\chainB).bus ? \nil)
].postln;
)
