// RunBook_20251002-1235.scd
// MD + Copilot
// 20251002

/*
--- > RUN BLOCK BY BLOCK! <---
All UI uses LPDisplay; LivePedalboardSystem runs headless.
This file is self-contained: it includes canonical-path hotfix + a minimal emulator.
*/

// ============================
// 0) Clean up (safe preflight)
// ============================
(
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

// ===============================================
// 1) Open LPDisplay window (silence demo sources)
// ===============================================
(
// Controller and GUI window
~inst = LPDisplayLayoutTestWindow.new(nil);  // nil HUD -> raw meters
~win  = ~inst.open;                          // -> a Window titled "Layout Test"

// Silence any LPDisplay demo sources so meters reflect your chains later
~inst.setSourceA(\srcZ);
~inst.setSourceB(\srcZ);

// Optional: if you added the console gate earlier, keep console quiet
try { ~inst.setConsoleLevelsOn(false) } { };

// Ready check
[ ~inst.notNil, ~win.notNil, ~win.class ].postln;
)

// ======================================
// 2) Bring up LivePedalboardSystem headless
// ======================================
(
~system = LivePedalboardSystem.new(nil);
~system.ensureServerReady;
~system.bringUpPedalboard;      // MagicPedalboardNew
~system.bringUpCommandSystem;   // CommandManager + MIDI
~system.installAdapterBridge;   // routes '/add/delay', '/switch', etc.
"OK: LPS up (headless UI).".postln;

// Sanity
[ ~system.notNil, ~system.pedalboard.notNil, ~system.commandManager.notNil ].postln;

// (Optional) Assert A/B are stereo and playing; retap is not needed for LPDisplay,
// but these two lines help catch a stale server:
Server.default.bind({ Ndef(\chainA).ar(2); Ndef(\chainB).ar(2); });
)

//////////////////////////////
// 3) Confirm core objects and set Quick Hotfix (var-first)
(
var cm, mm, builder;
var longFromBuilder, canonicalize, applyCanonical;
var showChildren, navName;

// --- var-first done; now safe to assign ---
cm = ~system.commandManager;
mm = cm.midiManager;
builder = cm.builder;

// Keep convenience handles (optional)
~cm = cm;
~mm = mm;

// Sanity
[ ~system.notNil, cm.notNil, mm.notNil, (cm.queueExportCallback.notNil) ].postln;

// ---------- Canonical-path Hotfix (no recompile) ----------

// 1) Build a long path from the builder (drop "root"):
longFromBuilder = {
    var names, filtered;
    names = builder.currentNode.getPathToRoot;   // ["root", "audio", ...]
    filtered = (names.size > 1).if({ names.copyRange(1, names.size-1) }, { [] });
    ^("/" ++ filtered.join("/"))
};

// 2) Map long → short (canonical) using your rules:
canonicalize = { |rawPath|
    var parts, first;
    parts = rawPath.asString.split($/).reject({ |s| s.size == 0 });
    if (parts.isEmpty) { ^rawPath.asString };

    first = parts[0].asString;

    // already-canonical verbs: pass-through
    if (#["add","remove","clear","bypass","swap","setSource","switch"].includes(first)) {
        ^("/" ++ parts.join("/"));
    };

    // switch family → "/switch"
    if (first == "switch") { ^"/switch" };

    // chain/* → /add/<proc> or /setSource/<src>
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

// 3) Apply canonical path via LPS adapter (robust to method name):
applyCanonical = { |shortPath|
    var bridge, applied;
    bridge = ~system.tryPerform(\adapterBridge);
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

// 4) Replace the emulator’s queueExportCallback to avoid DNU on missing CM methods:
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

// 6) Expose helpers like your emulator:
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
~navName = navName;
)


(
// 2.5) Fallback adapter + rebind ~toSend  (no recompile)
// Purpose: handle "/add/<proc>", "/switch", "/setSource/<sym>" while LPS has no bridge.
// Style: var-first; lowercase; no server.sync; safe introspection.

var bridge, mpb, have;

// Build a tiny object with .applyPath that calls common pedalboard verbs:
bridge = (
    applyPath: { |self, shortPath|
        var tokens, verb, arg;
        var ok = false;
        tokens = shortPath.asString.split($/).reject({ |s| s.isEmpty }).collect(_.asSymbol);
        verb   = tokens[0] ? \_;
        arg    = tokens.size > 1.if({ tokens[1] }, { nil });

        mpb = ~system.tryPerform(\pedalboard);
        if (mpb.isNil) { "⚠️ No pedalboard on ~system; cannot apply.".warn; ^false };

        ("[FallbackAdapter] " ++ shortPath).postln;

        switch(verb,
            \add, {
                if (mpb.respondsTo(\add)) { mpb.add(arg); ok = true }
                { "⚠️ pedalboard.add not found".warn; }
            },
            \switch, {
                // try a few likely names
                if (mpb.respondsTo(\switchChain)) { mpb.switchChain(); ok = true }
                { if (mpb.respondsTo(\switch)) { mpb.switch(); ok = true } { "⚠️ no switch method".warn; } }
            },
            \setSource, {
                if (mpb.respondsTo(\setSource)) { mpb.setSource(arg); ok = true }
                { "⚠️ setSource not found".warn; }
            },
            {
                ("⚠️ Unknown verb: " ++ verb).warn;
            }
        );

        ok
    }
);

// keep it global so the hotfix code can find it
~adapterBridge = bridge;

// Rebind ~toSend to use the fallback when the system has no bridge:
~toSend = {
    var short, applied, sysBridge;
    short = ( // reuse your hotfix closures
        { var names = ~cm.builder.currentNode.getPathToRoot;
          var filtered = (names.size > 1).if({ names.copyRange(1, names.size-1) }, { [] });
          "/" ++ filtered.join("/") }    // longFromBuilder()
    ).value;
    short = ( // canonicalize
        { |raw|
            var parts = raw.asString.split($/).reject({ |s| s.size == 0 });
            var first; if (parts.isEmpty) { ^raw.asString };
            first = parts[0].asString;
            if (#["add","remove","clear","bypass","swap","setSource","switch"].includes(first)) { ^("/" ++ parts.join("/")) };
            if (first == "switch") { ^"/switch" };
            if (first == "chain") {
                if (parts.size >= 3 and: { parts[1] == "add" } and: { parts[2] == "audio" }) { ^("/add/" ++ parts.last.asString) };
                if (parts.size >= 5
                    and: { parts[1] == "setsource" }
                    and: { parts[2] == "audio" }
                    and: { parts[3] == "source" }) { ^("/setSource/" ++ parts.last.asString) };
            };
            ^raw.asString
        }.value(short)
    );

    sysBridge = ~system.tryPerform(\adapterBridge);
    applied = false;

    // Prefer a real bridge if it appears later; otherwise our fallback
    if (~system.respondsTo(\applyCanonicalPath)) { ~system.applyCanonicalPath(short); applied = true }
    { if (sysBridge.notNil and: { sysBridge.respondsTo(\applyPath) }) { sysBridge.applyPath(short); applied = true }
      { if (~adapterBridge.respondsTo(\applyPath)) { ~adapterBridge.applyPath(short); applied = true } } };

    (applied.if({ "Adapter applied: ".post }, { "Adapter (fallback log only): ".post }); short.postln);
    short
};

// Optional: show which verbs are available on the current pedalboard
mpb = ~system.tryPerform(\pedalboard);
have = [
    \class,   (mpb ? \nil).class,
    \add,     (mpb.respondsTo(\add)),
    \switch,  (mpb.respondsTo(\switch) or: { mpb.respondsTo(\switchChain) }),
    \setSrc,  (mpb.respondsTo(\setSource))
];
("Pedalboard verbs: " ++ have.asString).postln;
)



// =====================================
// 4) Minimal, self-contained emulator
//     (no MIDI; direct builder drive)
// =====================================
(
// Enter/exit "navigation" mode and navigate by (string,fret) or by name.
// These 4 helpers replace the old external emulator file for today's run.

~toProg = {
    ~cm.currentState = \prog;
    ~cm.updateDisplay;
    "Navigation started (mode=prog).".postln;
    ~showChildren.();  // list root children with their frets
};

~nav = { |stringNum, fretNum|
    // You can still use frets; check ~showChildren() to discover the actual mapping
    ~cm.builder.navigateByFret(stringNum, fretNum);
    ~cm.updateDisplay;
    ~showChildren.();
};

~toQueue = ~toQueue;  // already defined in block 3
~toSend  = ~toSend;   // already defined in block 3
)

// =====================================
// 5) Scenario A — Add Delay (by name)
// =====================================
(
~toProg.();                 // enter navigation mode
~navName.("audio");         // step 1
~navName.("timebased");     // step 2
~navName.("delay");         // step 3
~showNav.();                // shows Long + Short
~toQueue.();                // queue canonical (e.g., "/add/delay")
~toSend.();                 // send via adapter -> MagicPedalboardNew
)

// =====================================
// 6) Scenario B — Switch chains (by name)
// =====================================
(
~toProg.();
~navName.("switch");
~showNav.();
~toQueue.();
~toSend.();
)