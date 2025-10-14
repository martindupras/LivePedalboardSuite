// RunBook_20251002_Diagnostics.scd
// MD + Copilot 2025-10-02
// --- > RUN BLOCK BY BLOCK! <---
// Goal: Diagnosable bring-up of LPS headless + LPDisplay window.
// Adds pane writers, source toggles, retaps, chain probes, and robust adapter send.

//////////////////////////////////////////////////////
// 1) Preflight cleanup (safe, idempotent; no errors)
//////////////////////////////////////////////////////
(
var wins, demoKeys, demoSyms;

wins = Window.allWindows.select({ |w|
    (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI")
    or: { w.tryPerform(\name) == "Layout Test" }
});
wins.do(_.close);

// Free LPDisplay demo responders (if they exist)
demoKeys = [ \rmsA_toGUI, \rmsB_toGUI, \rmsA_console, \rmsB_console ];
demoKeys.do({ |k| var d = OSCdef(k); if(d.notNil) { d.free } });

// Stop LPDisplay demo Ndefs (if present)
demoSyms = [ \srcA, \srcB, \srcC, \srcZ, \outA, \outB ];
demoSyms.do({ |sym| var nd = Ndef(sym); if(nd.notNil) { nd.stop } });

// Remove any prior visualization taps we may have installed in an earlier run
Server.default.bind({
    if (Ndef(\chainA).notNil) { Ndef(\chainA).clear(\lpdispTapA) };
    if (Ndef(\chainB).notNil) { Ndef(\chainB).clear(\lpdispTapB) };
});

"✔ Cleanup done.".postln;
)


//////////////////////////////////////////////////////////
// 2) Open the LPDisplay window + install PANE HELPERS
//////////////////////////////////////////////////////////
(
var inst, win;

// Controller + window  (-> a Window titled "Layout Test")
inst = LPDisplayLayoutTestWindow.new(nil);  // nil HUD = raw meters
win  = inst.open;                           // -> a Window

// Keep LPDisplay's own demo quiet by default (we'll offer toggles)
inst.setSourceA(\srcZ);
inst.setSourceB(\srcZ);

// Optional console gate (if your class has it)
try { inst.setConsoleLevelsOn(false) } { };

// Export handles
~inst = inst; ~win = win;

// ---- Pane helpers (so we can write quickly) ----
// pane keys seen in LPDisplayLayoutTestWindow: \left \right \system \diag \choices \recv
~pane = { |paneKey, text|
    // failsafe if sendPaneText not present
    var ok = (~inst.notNil and: { ~inst.respondsTo(\sendPaneText) });
    if (ok) { ~inst.sendPaneText(paneKey.asSymbol, text.asString) } { text.postln };
};
~paneAppend = { |paneKey, text|
    // naive append: readback not available, so just post new line
    ~pane.(paneKey, text)
};
~statusHUD = { |msg|  // put important status in the system pane & console
    ("[HUD] " ++ msg).postln;
    ~pane.(\system, msg);
};

// Initial HUD
~pane.(\diag, "LPDisplay ready @ " ++ Date.getDate.stamp);
~pane.(\system, "System: waiting for LPS…");
~pane.(\left,  "A: (LPDisplay demo source muted)");
~pane.(\right, "B: (LPDisplay demo source muted)");
~pane.(\choices, "—");
~pane.(\recv, "—");

// Quick confirmation
[ inst.notNil, win.notNil, win.class ].postln;
"→ a Window".postln;
)


////////////////////////////////////////////////////////////
// 3) Bring up LivePedalboardSystem (headless) + quick HUD
////////////////////////////////////////////////////////////
(
var system;
var san;
system = LivePedalboardSystem.new(nil);
system.ensureServerReady;
system.bringUpPedalboard;
system.bringUpCommandSystem;
system.installAdapterBridge;

~system = system;

"✔ LPS up (headless).".postln;
~statusHUD.("LPS up (headless)");

Server.default.bind({ Ndef(\chainA).ar(2); Ndef(\chainB).ar(2) });  // assert stereo busses

// Show core boolean sanity in console AND pane:
san = [ \system: ~system.notNil, \pedalboard: ~system.pedalboard.notNil, \cm: ~system.commandManager.notNil ];
san.postln;
~pane.(\diag, ("Sanity: " ++ san).asString);
)


///////////////////////////////////////////////////////////////
// 4) LPDisplay RETAP from LPS chain ends (safe pass-through)
///////////////////////////////////////////////////////////////
(
var rateHz;
var r;

rateHz = 20;

Server.default.bind({
    if (Ndef(\chainA).notNil) {
        Ndef(\chainA).filter(\lpdispTapA, { |in|
            var sig = in.isArray.if({ in }, { [in, in] });
            var rms = RMS.kr(sig, 500);
            var t   = Impulse.kr(rateHz);
            SendReply.kr(t, "/peakrmsA",  [rms[0], rms[1]], 1);   // console/legacy path
            SendReply.kr(t, "/rmsA_toGUI",[rms[0], rms[1]], 1);   // GUI path
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
"✔ LPDisplay retap installed.".postln;

// Confirm which responders are live
r = [
    \rmsA_toGUI: (OSCdef(\rmsA_toGUI).notNil),
    \rmsB_toGUI: (OSCdef(\rmsB_toGUI).notNil),
    \rmsA_console: (OSCdef(\rmsA_console).notNil),
    \rmsB_console: (OSCdef(\rmsB_console).notNil)
];
r.postln;
~pane.(\diag, ("OSC responders: " ++ r).asString);
)


///////////////////////////////////////////////////////
// 5) Quick DIAGNOSTIC CONTROLS & INSPECTION HELPERS
///////////////////////////////////////////////////////
(
// A) Toggle LPDisplay’s INTERNAL demo sources (pure UI demo, not LPS):
~lpDemo_on  = { ~inst.setSourceA(\srcA); ~inst.setSourceB(\srcB);
                ~pane.(\left,  "A: LPDisplay demo src = \\srcA");
                ~pane.(\right, "B: LPDisplay demo src = \\srcB");
                ~statusHUD.("LPDisplay demo sources ON") };

~lpDemo_off = { ~inst.setSourceA(\srcZ); ~inst.setSourceB(\srcZ);
                ~pane.(\left,  "A: LPDisplay demo src = \\srcZ (muted)");
                ~pane.(\right, "B: LPDisplay demo src = \\srcZ (muted)");
                ~statusHUD.("LPDisplay demo sources OFF") };

// B) Chain probes (prints + panes)
~probeChains = {
    var aPlay = Ndef(\chainA).isPlaying, bPlay = Ndef(\chainB).isPlaying;
    var busA  = (Ndef(\chainA).bus ? \nil), busB = (Ndef(\chainB).bus ? \nil);
    var msg   = ("A playing="++aPlay++" bus="++busA) ++ " | " ++ ("B playing="++bPlay++" bus="++busB);
    msg.postln;
    ~pane.(\system, "Chains — " ++ msg);
};

// C) Audible test insert/remove on chain A (tremolo) — safe pass-through
~diag_addTremA = {
    Server.default.bind({
        Ndef(\chainA).filter(\diag_tremA, { |in| in * LFTri.kr(1).range(0.25, 1.0) });
    });
    ~statusHUD.("Inserted test tremolo on chain A");
};
~diag_clearTrem = {
    Server.default.bind({
        if (Ndef(\chainA).notNil) { Ndef(\chainA).clear(\diag_tremA) };
    });
    ~statusHUD.("Cleared test tremolo on chain A");
};

// D) Try to describe chains via pedalboard API if present (best-effort)
~describeChains = {
    var pb = ~system.tryPerform(\pedalboard);
    var aTxt = "A: (unknown)", bTxt = "B: (unknown)";
    if (pb.notNil) {
        if (pb.respondsTo(\describe))      { aTxt = pb.describe(\A); bTxt = pb.describe(\B) } {
        if (pb.respondsTo(\chainToString)) { aTxt = pb.chainToString(\A); bTxt = pb.chainToString(\B) } };
    };
    ("ChainDesc: " ++ aTxt ++ " | " ++ bTxt).postln;
    ~pane.(\left,  aTxt.asString);
    ~pane.(\right, bTxt.asString);
};

// E) Minimal HUD refresh bundle
~refreshHUD = {
    ~probeChains.();
    ~describeChains.();
    ~pane.(\choices, "Nav helpers: ~toProg, ~navName(\"…\"), ~navFret(s,f), ~showNav, ~toQueue, ~toSend");
};

"✔ Diagnostics installed. Use: ~lpDemo_on/off, ~probeChains, ~diag_addTremA, ~diag_clearTrem, ~describeChains, ~refreshHUD".postln;
)


/////////////////////////////////////////////////////////////
// 6) Inline Emulator: navigation + robust canonical sender
/////////////////////////////////////////////////////////////
(
// --- var-first: gather references
var cm, mm, builder;
var longFromBuilder, canonicalize, applyCanonical, sendCanonical;
var showChildren, navName, navFret;

cm      = ~system.commandManager;
mm      = cm.midiManager;
builder = cm.builder;

// --- path builders (drop "root")
longFromBuilder = {
    var names = builder.currentNode.getPathToRoot;
    var filtered = (names.size > 1).if({ names.copyRange(1, names.size-1) }, { [] });
    ^("/" ++ filtered.join("/"))
};

canonicalize = { |rawPath|
    var parts = rawPath.asString.split($/).reject({ |s| s.size == 0 });
    if (parts.isEmpty) { ^rawPath.asString };
    var first = parts[0].asString;

    if (#["add","remove","clear","bypass","swap","setSource","switch"].includes(first)) {
        ^("/" ++ parts.join("/"));
    };
    if (first == "switch") { ^"/switch" };

    if (first == "chain") {
        if (parts.size >= 3 and: { parts[1] == "add" } and: { parts[2] == "audio" }) {
            ^("/add/" ++ parts.last.asString);
        };
        if (parts.size >= 5
            and: { parts[1] == "setsource" }
            and: { parts[2] == "audio" }
            and: { parts[3] == "source" }) {
            ^("/setSource/" ++ parts.last.asString);
        };
    };

    ^rawPath.asString
};

// --- ROBUST sender: try bridge method names, then fallback direct to pedalboard if present
applyCanonical = { |shortPath|
    var bridge, applied=false;

    // 1) System-level applyCanonicalPath
    if (~system.respondsTo(\applyCanonicalPath)) {
        ~system.applyCanonicalPath(shortPath); applied=true;
    } {
        // 2) adapterBridge object with .applyPath ?
        bridge = ~system.tryPerform(\adapterBridge);
        if (bridge.notNil and: { bridge.respondsTo(\applyPath) }) {
            bridge.applyPath(shortPath); applied=true;
        } {
            // 3) Sometimes adapterBridge is a Function or symbol-wrapped
            if (bridge.isKindOf(Function)) {
                bridge.value(shortPath); applied=true;
            };
        };
    };

    if (applied) {
        ("Adapter applied: " ++ shortPath).postln;
        ~pane.(\recv, "Applied: " ++ shortPath);
        ^true
    } {
        // 4) Fallback: direct pedalboard verbs if exposed (best-effort)
        var pb = ~system.tryPerform(\pedalboard);
        if (pb.notNil) {
            var toks = shortPath.asString.split($/).reject(_.isEmpty);
            var verb = toks[0].asSymbol;
            var arg  = (toks.size>1).if({ toks[1].asSymbol }, { nil });
            var did  = false;

            switch(verb,
                \add,      { if (pb.respondsTo(\add) and: { arg.notNil }) { pb.add(arg); did=true } },
                \bypass,   { if (pb.respondsTo(\bypass) and: { arg.notNil }) { pb.bypass(arg); did=true } },
                \clear,    { if (pb.respondsTo(\clear)) { pb.clear; did=true } },
                \setSource,{ if (pb.respondsTo(\setSource) and: { arg.notNil }) { pb.setSource(arg); did=true } },
                \switch,   { /* NO direct mpb.switch() (name clashes with Object:switch) */ },
                { } // default
            );

            if (did) {
                ("Fallback MPB applied: " ++ shortPath).postln;
                ~pane.(\recv, "Fallback applied: " ++ shortPath);
                ^true
            };
        };

        ("⚠ Adapter not available for: " ++ shortPath).warn;
        ~pane.(\recv, "⚠ No adapter for: " ++ shortPath);
        ^false
    };
};

sendCanonical = { |shortPath|
    var ok = applyCanonical.(shortPath);
    ~refreshHUD.();  // update panes after any change
    ok
};

// --- Navigation helpers
showChildren = {
    var info = builder.currentNode.children.collect({ |n| [n.name, n.fret] });
    ("Children: " ++ info).postln;
    ~pane.(\choices, info.asString);
    ^info
};

navName = { |nameString|
    builder.navigateByName(nil, nameString.asString);
    cm.updateDisplay;
    showChildren.();
};
navFret = { |stringNum, fretNum|
    builder.navigateByFret(stringNum, fretNum);
    cm.updateDisplay;
    showChildren.();
};

// --- Top-level API (like the old emulator)
~toProg = {
    cm.currentState = \prog;
    cm.updateDisplay;
    "Navigation started (prog).".postln;
    ~pane.(\system, "Mode: prog (nav)");
    showChildren.();
};

~showNav  = {
    var long = longFromBuilder.(), short = canonicalize.(long);
    ("Long:  " ++ long).postln;  ("Short: " ++ short).postln;
    ~pane.(\diag, "Long="++long++"  Short="++short);
};

~toQueue  = {
    var short = canonicalize.( longFromBuilder.() );
    cm.queue.enqueueCommand(short);
    ("Queued: " ++ short).postln;
    ~pane.(\recv, "Queued: " ++ short);
    short
};

~toSend   = {
    var short = canonicalize.( longFromBuilder.() );
    sendCanonical.(short);
};

~navName  = navName;
~navFret  = navFret;
"✔ Emulator online. Use: ~toProg, ~navName(\"…\"), ~navFret(s,f), ~showNav, ~toQueue, ~toSend".postln;
)


//////////////////////////////////////////////////////
// 7) Scenarios — first by NAME, then direct CANONICAL
//////////////////////////////////////////////////////

// 7A) NAME-based Add Delay
(
~toProg.();
~navName.("audio");
~navName.("timebased");
~navName.("delay");
~showNav.();               // expect Short: /add/delay
~toSend.();                // robust adapter call or fallback
)

// 7B) Direct CANONICAL (no nav) — prove the path independently
(
~sendCanonical.("/add/delay");
)

// 7C) Switch chains — ALWAYS via adapter (no direct mpb.switch())
(
~toProg.();
~navName.("switch");
~showNav.();               // expect Short: /switch
~toSend.();                // robust adapter call
// OR direct canonical:
// ~sendCanonical.("/switch");
)

//////////////////////////////////////////////////////
// 8) Quick audible checks (optional, reversible)
//////////////////////////////////////////////////////

// 8A) Turn LPDisplay demo sources ON (just to see UI move), then OFF
// ~lpDemo_on.();
// ~lpDemo_off.();

// 8B) Insert tremolo on A (you should hear amplitude wobble), then clear
// ~diag_addTremA.();
// ~diag_clearTrem.();

// 8C) Refresh HUD summary
// ~refreshHUD.();