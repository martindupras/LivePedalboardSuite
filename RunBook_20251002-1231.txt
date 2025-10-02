// RunBook_20251002-1231.scd
// MD
// 20251002-1157

/*
--- > RUN BLOCK BY BLOCK! <--
*/

//////////////////////////////
// 0) Clean up (safe preflight)

(
// Close LPDisplay / MagicDisplay windows
Window.allWindows
 .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI")
        or: { w.tryPerform(\name) == "Layout Test" } })
 .do(_.close);

// Free OSCdefs used by the LPDisplay demo (if present)
[ \rmsA_toGUI, \rmsB_toGUI, \rmsA_console, \rmsB_console ].do { |k|
    var d = OSCdef(k); if(d.notNil) { d.free };
};

// Stop the LPDisplay demo Ndefs if they exist
[ \srcA, \srcB, \srcC, \srcZ, \outA, \outB ].do { |sym|
    var nd = Ndef(sym); if(nd.notNil) { nd.stop };
};
"Cleanup done.".postln;
)


//////////////////////////////
// 1) Open LPDisplay window (silence its internal demo sources)
(
// Controller (instance with setSourceA/B) and GUI window
~inst = LPDisplayLayoutTestWindow.new(nil);  // pass a HUD object if you prefer; nil = raw meters
~win  = ~inst.open;                          // -> a Window titled "Layout Test"

// Silence the LPDisplay demo sources so the meters don't show its noise/tone
~inst.setSourceA(\srcZ);
~inst.setSourceB(\srcZ);

// If you added the console gate previously:
try { ~inst.setConsoleLevelsOn(false) } { };  // optional: keep console quiet

// Ready check
[ ~inst.notNil, ~win.notNil, ~win.class ].postln;
)

//////////////////////////////
// 2) Bring up LivePedalboardSystem (headless UI)
(
~system = LivePedalboardSystem.new(nil);
~system.ensureServerReady;
~system.bringUpPedalboard;      // MagicPedalboardNew
~system.bringUpCommandSystem;   // CommandManager + MIDI
~system.installAdapterBridge;   // routes '/add/delay', '/switch', etc. to MPB
"OK: LPS up (headless UI).".postln;

// Sanity
[ ~system.notNil, ~system.pedalboard.notNil, ~system.commandManager.notNil ].postln;
)

//////////////////////////////
// 3) Confirm core objects and callback exist
(
~cm = ~system.commandManager;
~mm = ~cm.midiManager;
[ ~system.notNil, ~cm.notNil, ~mm.notNil, (~cm.queueExportCallback.notNil) ].postln;
)





//---------------

(
// --- Quick Hotfix for Step 5: canonical path + helpers (no recompile) ---

var cm, builder, longFromBuilder, canonicalize, applyCanonical, showChildren, navName;

cm = ~system.commandManager;
builder = cm.builder;

// 1) Build a “long” path from the builder (drop "root"):
longFromBuilder = {
    var names, filtered;
    names = builder.currentNode.getPathToRoot;          // ["root", "audio", ...]
    filtered = (names.size > 1).if({ names.copyRange(1, names.size-1) }, { [] });
    ^("/" ++ filtered.join("/"))
};

// 2) Map long → short (canonical) using your rules:
canonicalize = { |rawPath|
    var parts, first;
    parts = rawPath.asString.split($/).reject({ |s| s.size == 0 });
    if (parts.isEmpty) { ^rawPath.asString };

    first = parts[0].asString;

    // already-canonical short verbs: pass-through
    if (#["add","remove","clear","bypass","swap","setSource","switch"].includes(first)) {
        ^("/" ++ parts.join("/"))
    };

    // switch family → "/switch"
    if (first == "switch") { ^"/switch" };

    // chain/*: reduce to /add/<proc> or /setSource/<src>
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

    // default: return the original long path
    ^rawPath.asString
};

// 3) Apply canonical path via LPS adapter (robust: try common method names):
applyCanonical = { |shortPath|
    var bridge, applied;
    bridge = ~system.tryPerform(\adapterBridge);
    applied = false;

    // Prefer an explicit method if it exists:
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

// 4) Replace the emulator’s queueExportCallback to avoid the missing CM method:
cm.queueExportCallback = { |cmRef, builderRef|
    var long, short;
    long = longFromBuilder.();
    short = canonicalize.(long);
    cmRef.queue.enqueueCommand(short);
    ("Queued: " ++ short).postln;
    short
};

// 5) Add name-based navigation + a child/fret inspector:
showChildren = {
    var info;
    info = builder.currentNode.children.collect({ |n| [n.name, n.fret] });
    ("Children (name, fret): " ++ info.asString).postln;
    ^info
};

navName = { |nameString|
    builder.navigateByName(nil, nameString.asString);
    cm.updateDisplay;
    showChildren.();
};

// 6) Convenience wrappers mirroring your emulator API (optional):
~showNav = {
    var long = longFromBuilder.();
    var short = canonicalize.(long);
    ("Long:  " ++ long).postln;
    ("Short: " ++ short).postln;
};
~toQueue = {
    var short = canonicalize.( longFromBuilder.() );
    cm.queue.enqueueCommand(short);
    ("Queued: " ++ short).postln;
    short
};
~toSend = {
    var short = canonicalize.( longFromBuilder.() );
    applyCanonical.(short);
    short
};
~showChildren = showChildren;
~navName = navName;   // e.g., ~navName.("audio"); then ~navName.("timebased"); then ~navName.("delay")
)




//--------------




//////////////////////////////
//4) Load the emulator helpers (block [1] in the emulator file)

/*
Open Demo-simulated/Sim_MIDIInput_Emulator_For_TreeNav.scd and evaluate the parenthesized block under [1] Emulation helpers.
That block defines: ~fc, ~toProg, ~toQueue, ~toSend, ~gm, ~nav, ~showNav, etc.
*/
//verify helps exist:
[ ~toProg.isKindOf(Function), ~nav.isKindOf(Function), ~toQueue.isKindOf(Function), ~toSend.isKindOf(Function) ].postln;
// Expect: [ true, true, true, true ]


//////////////////////////////
//5) Scenario A — Add Delay (navigate → queue → send)
(
~toProg.();           // enter navigation mode
~nav.(6, 1);          // "audio"
~nav.(5, 5);          // "timebased"
~nav.(4, 3);          // "delay"
~showNav.();          // optional: prints long/canonical path
~toQueue.();          // queue canonical (e.g. "/add/delay")
~toSend.();           // send via adapter -> MagicPedalboardNew
)

//////////////////////////////
//6) Scenario B — Switch chains
(
~toProg.();
~nav.(6, 5);          // "switch"
~showNav.();
~toQueue.();
~toSend.();
)


//////////////////////////////
//

//////////////////////////////
//

//////////////////////////////
//

//////////////////////////////
//