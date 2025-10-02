// RunBook_20251002_Diagnostics_1311.scd
// v1.0.0 — diagnostic-first bring-up for LPS (headless) + LPDisplay window
// MD 2025-10-02

/*
Purpose
- Give you a single, self-contained runbook to bring up LivePedalboardSystem (headless)
  while using the new LPDisplay Layout Test window as the UI.
- Add strong diagnostics you can see in the LPDisplay panes: system status, chain info,
  and received canonical commands.
- Provide safe toggles and probes: enable/disable LPDisplay’s demo sources, retap meters
  from LPS chain ends, insert a test tremolo on Chain A (audible), and refresh a HUD summary.
- Provide a robust canonical sender (~sendCanonicalPath) that tries multiple adapter entry
  points and falls back to a safe subset of pedalboard verbs if needed (never calls mpb.switch()).

Style
- var-first in every block/closure; lowercase descriptive names; no server.sync; no ^ returns.
- Server.default.bind for server operations; AppClock only for UI (none scheduled here).
- Single-window policy: closes prior LPDisplay/MagicDisplay windows on cleanup.
*/

//////////////////////////////////////////////////////
// 1) Preflight cleanup (safe, idempotent; no errors)
//////////////////////////////////////////////////////
(
var windowsToClose, demoOscKeys, demoNdefSymbols;

windowsToClose = Window.allWindows.select({ |oneWindow|
    var nameString;
    nameString = (oneWindow.tryPerform(\name) ? "").asString;
    nameString.beginsWith("MagicDisplayGUI") or: { nameString == "Layout Test" }
});
windowsToClose.do(_.close);

// Free LPDisplay demo responders (if they exist)
demoOscKeys = [ \rmsA_toGUI, \rmsB_toGUI, \rmsA_console, \rmsB_console ];
demoOscKeys.do({ |keySym| var def;
    def = OSCdef(keySym);
    if (def.notNil) { def.free };
});

// Stop LPDisplay demo Ndefs (if present)
demoNdefSymbols = [ \srcA, \srcB, \srcC, \srcZ, \outA, \outB ];
demoNdefSymbols.do({ |ndefName|
    var ndefRef;
    ndefRef = Ndef(ndefName);
    if (ndefRef.notNil) { ndefRef.stop };
});

// Remove any prior visualization taps we may have installed
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
var displayController, displayWindow;

// Controller + window (-> a Window titled "Layout Test")
displayController = LPDisplayLayoutTestWindow.new(nil);  // nil HUD => raw meters
displayWindow     = displayController.open;

// Mute LPDisplay’s own demo tail sources (we’ll retap from LPS)
displayController.setSourceA(\srcZ);
displayController.setSourceB(\srcZ);

// Optional: quiet console if your class has the gate
try { displayController.setConsoleLevelsOn(false) } { };

// Export handles
~inst = displayController;
~win  = displayWindow;

// ---- Pane helpers ----
~pane = { |paneKey, paneText|
    var okController, paneKeySymbol, paneTextString;
    okController   = (~inst.notNil) and: { ~inst.respondsTo(\sendPaneText) };
    paneKeySymbol  = paneKey.asSymbol;
    paneTextString = paneText.asString;
    if (okController) {
        ~inst.sendPaneText(paneKeySymbol, paneTextString)
    } {
        paneTextString.postln;  // fallback to console
    };
};

~paneAppend = { |paneKey, lineText|
    var textString;
    textString = lineText.asString;
    ~pane.(paneKey, textString);
};

~statusHUD = { |messageString|
    var msgString;
    msgString = "[HUD] " ++ messageString.asString;
    msgString.postln;
    ~pane.(\system, msgString);
};

// Initial HUD
~pane.(\diag,   "LPDisplay ready @ " ++ Date.getDate.stamp);
~pane.(\system, "System: waiting for LPS…");
~pane.(\left,   "A: (LPDisplay demo source muted)");
~pane.(\right,  "B: (LPDisplay demo source muted)");
~pane.(\choices,"—");
~pane.(\recv,   "—");

// Ready check
[ displayController.notNil, displayWindow.notNil, displayWindow.class ].postln;
"→ a Window".postln;
)

////////////////////////////////////////////////////////////
// 3) Bring up LivePedalboardSystem (headless) + HUD sanity
////////////////////////////////////////////////////////////
(
var liveSystem, sanityAssoc;

liveSystem = LivePedalboardSystem.new(nil);
liveSystem.ensureServerReady;
liveSystem.bringUpPedalboard;
liveSystem.bringUpCommandSystem;
liveSystem.installAdapterBridge;

~system = liveSystem;

"✔ LPS up (headless).".postln;
~statusHUD.("LPS up (headless)");

// Materialize 2‑ch busses (does not force play state)
Server.default.bind({
    Ndef(\chainA).ar(2);
    Ndef(\chainB).ar(2);
});

// Show core boolean sanity in console AND pane:
sanityAssoc = (
    system: ~system.notNil,
    pedalboard: ~system.pedalboard.notNil,
    commandManager: ~system.commandManager.notNil
);
sanityAssoc.postln;
~pane.(\diag, ("Sanity: " ++ sanityAssoc).asString);
)

///////////////////////////////////////////////////////////////
// 4) Retap meters so LPDisplay follows LPS chain A/B (safe)
///////////////////////////////////////////////////////////////
(
var updateRateHz, oscStateAssoc;

updateRateHz = 20;

Server.default.bind({
    if (Ndef(\chainA).notNil) {
        Ndef(\chainA).filter(\lpdispTapA, { |inSignal|
            var stereoSignal, rmsPair, tick;
            stereoSignal = inSignal.isArray.if({ inSignal }, { [inSignal, inSignal] });
            rmsPair      = RMS.kr(stereoSignal, 500);
            tick         = Impulse.kr(updateRateHz);
            SendReply.kr(tick, "/peakrmsA",   [rmsPair[0], rmsPair[1]], 1);
            SendReply.kr(tick, "/rmsA_toGUI", [rmsPair[0], rmsPair[1]], 1);
            inSignal
        });
    };
    if (Ndef(\chainB).notNil) {
        Ndef(\chainB).filter(\lpdispTapB, { |inSignal|
            var stereoSignal, rmsPair, tick;
            stereoSignal = inSignal.isArray.if({ inSignal }, { [inSignal, inSignal] });
            rmsPair      = RMS.kr(stereoSignal, 500);
            tick         = Impulse.kr(updateRateHz);
            SendReply.kr(tick, "/peakrmsB",   [rmsPair[0], rmsPair[1]], 2);
            SendReply.kr(tick, "/rmsB_toGUI", [rmsPair[0], rmsPair[1]], 2);
            inSignal
        });
    };
});

"✔ LPDisplay retap installed.".postln;

// Confirm which responders are live
oscStateAssoc = (
    rmsA_toGUI:   OSCdef(\rmsA_toGUI).notNil,
    rmsB_toGUI:   OSCdef(\rmsB_toGUI).notNil,
    rmsA_console: OSCdef(\rmsA_console).notNil,
    rmsB_console: OSCdef(\rmsB_console).notNil
);
oscStateAssoc.postln;
~pane.(\diag, ("OSC responders: " ++ oscStateAssoc).asString);
)

///////////////////////////////////////////////////////
// 5) Diagnostic controls (pane writers, toggles, probes)
///////////////////////////////////////////////////////
(
var chainInfoString;

// A) Toggle LPDisplay’s INTERNAL demo sources (UI-only; does not touch LPS)
~lpDemo_on = {
    var ok;
    ok = (~inst.notNil);
    if (ok) {
        ~inst.setSourceA(\srcA);
        ~inst.setSourceB(\srcB);
    };
    ~pane.(\left,  "A: LPDisplay demo src = \\srcA");
    ~pane.(\right, "B: LPDisplay demo src = \\srcB");
    ~statusHUD.("LPDisplay demo sources ON");
};

~lpDemo_off = {
    var ok;
    ok = (~inst.notNil);
    if (ok) {
        ~inst.setSourceA(\srcZ);
        ~inst.setSourceB(\srcZ);
    };
    ~pane.(\left,  "A: LPDisplay demo src = \\srcZ (muted)");
    ~pane.(\right, "B: LPDisplay demo src = \\srcZ (muted)");
    ~statusHUD.("LPDisplay demo sources OFF");
};

// B) Chain probes (prints + panes)
~probeChains = {
    var aPlaying, bPlaying, busA, busB, summaryText;
    aPlaying    = Ndef(\chainA).isPlaying;
    bPlaying    = Ndef(\chainB).isPlaying;
    busA        = (Ndef(\chainA).bus ? \nil);
    busB        = (Ndef(\chainB).bus ? \nil);
    summaryText = "A playing=" ++ aPlaying ++ " bus=" ++ busA
        ++ " | B playing=" ++ bPlaying ++ " bus=" ++ busB;
    summaryText.postln;
    ~pane.(\system, "Chains — " ++ summaryText);
};

// C) Audible test insert/remove on chain A (tremolo) — safe pass-through
~diag_addTremA = {
    Server.default.bind({
        Ndef(\chainA).filter(\diag_tremA, { |inSignal|
            var lfo;
            lfo = LFTri.kr(1).range(0.25, 1.0);
            inSignal * lfo
        });
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
    var pedalboardRef, leftText, rightText, canDescribe, canChainToString;

    pedalboardRef   = ~system.tryPerform(\pedalboard);
    leftText        = "A: (unknown)";
    rightText       = "B: (unknown)";
    canDescribe     = pedalboardRef.notNil and: { pedalboardRef.respondsTo(\describe) };
    canChainToString= pedalboardRef.notNil and: { pedalboardRef.respondsTo(\chainToString) };

    if (canDescribe) {
        leftText  = pedalboardRef.describe(\A);
        rightText = pedalboardRef.describe(\B);
    } {
        if (canChainToString) {
            leftText  = pedalboardRef.chainToString(\A);
            rightText = pedalboardRef.chainToString(\B);
        };
    };

    chainInfoString = "ChainDesc: " ++ leftText.asString ++ " | " ++ rightText.asString;
    chainInfoString.postln;
    ~pane.(\left,  leftText.asString);
    ~pane.(\right, rightText.asString);
};

// E) HUD refresh bundle
~refreshHUD = {
    ~probeChains.();
    ~describeChains.();
    ~pane.(\choices, "Nav helpers: ~toProg, ~navName(\"…\"), ~navFret(s,f), ~showNav, ~toQueue, ~toSend");
};

"✔ Diagnostics installed. Use: ~lpDemo_on/off, ~probeChains, ~diag_addTremA, ~diag_clearTrem, ~describeChains, ~refreshHUD".postln;
)

/////////////////////////////////////////////////////////////
// 6) Inline emulator + robust canonical sender (no mpb.switch)
/////////////////////////////////////////////////////////////
(
var commandManagerRef, midiManagerRef, builderRef;
var buildLongPathFromBuilder, canonicalizePath, applyCanonicalPath, sendCanonicalPath;
var showChildrenList, navigateByName, navigateByFret;

// gather references (var-first)
commandManagerRef = ~system.commandManager;
midiManagerRef    = commandManagerRef.midiManager;
builderRef        = commandManagerRef.builder;

// Build long path (drop "root")
buildLongPathFromBuilder = {
    var nameList, filteredNames, builtPath;
    nameList      = builderRef.currentNode.getPathToRoot;     // ["root", ...]
    filteredNames = (nameList.size > 1).if({ nameList.copyRange(1, nameList.size-1) }, { [] });
    builtPath     = "/" ++ filteredNames.join("/");
    builtPath
};

// Map long -> short canonical
canonicalizePath = { |rawPath|
    var parts, firstToken, resultString;

    parts = rawPath.asString.split($/).reject({ |s| s.size == 0 });
    if (parts.isEmpty) { resultString = rawPath.asString } {
        firstToken = parts[0].asString;

        // already-canonical verbs are pass-through
        if (#["add","remove","clear","bypass","swap","setSource","switch"].includes(firstToken)) {
            resultString = "/" ++ parts.join("/");
        } {
            if (firstToken == "switch") {
                resultString = "/switch";
            } {
                if (firstToken == "chain") {
                    if (parts.size >= 3 and: { parts[1] == "add" } and: { parts[2] == "audio" }) {
                        resultString = "/add/" ++ parts.last.asString;
                    } {
                        if (parts.size >= 5
                            and: { parts[1] == "setsource" }
                            and: { parts[2] == "audio" }
                            and: { parts[3] == "source" }) {
                            resultString = "/setSource/" ++ parts.last.asString;
                        } {
                            resultString = rawPath.asString;
                        };
                    };
                } {
                    resultString = rawPath.asString;
                };
            };
        };
    };

    resultString
};

// Apply canonical via adapter bridge (robust; avoids mpb.switch name clash)
applyCanonicalPath = { |shortPath|
    var adapterAny, appliedFlag, pedalboardRef, tokenList, verbSymbol, argSymbol, didFallback;

    appliedFlag = false;

    // 1) System-level applyCanonicalPath
    if (~system.respondsTo(\applyCanonicalPath)) {
        ~system.applyCanonicalPath(shortPath);
        appliedFlag = true;
    } {
        // 2) adapterBridge object with .applyPath ?
        adapterAny = ~system.tryPerform(\adapterBridge);
        if (adapterAny.notNil and: { adapterAny.respondsTo(\applyPath) }) {
            adapterAny.applyPath(shortPath);
            appliedFlag = true;
        } {
            // 3) Sometimes adapterBridge is a Function
            if (adapterAny.isKindOf(Function)) {
                adapterAny.value(shortPath);
                appliedFlag = true;
            } {
                // 4) Sometimes adapterBridge is a Symbol that names another entry point
                if (adapterAny.isKindOf(Symbol)) {
                    var maybeMethodName;
                    maybeMethodName = adapterAny.asSymbol; // attempt ~system.perform on that symbol
                    if (~system.respondsTo(maybeMethodName)) {
                        ~system.perform(maybeMethodName, shortPath);
                        appliedFlag = true;
                    };
                };
            };
        };
    };

    if (appliedFlag) {
        ("Adapter applied: " ++ shortPath).postln;
        ~pane.(\recv, "Applied: " ++ shortPath);
        true
    } {
        // Fallback: direct pedalboard verbs if exposed (safe subset only)
        pedalboardRef = ~system.tryPerform(\pedalboard);
        didFallback   = false;

        if (pedalboardRef.notNil) {
            tokenList = shortPath.asString.split($/).reject(_.isEmpty);
            verbSymbol = tokenList[0].asSymbol;
            argSymbol  = (tokenList.size > 1).if({ tokenList[1].asSymbol }, { nil });

            switch(verbSymbol,
                \add, {
                    if (pedalboardRef.respondsTo(\add) and: { argSymbol.notNil }) {
                        pedalboardRef.add(argSymbol); didFallback = true;
                    };
                },
                \bypass, {
                    if (pedalboardRef.respondsTo(\bypass) and: { argSymbol.notNil }) {
                        pedalboardRef.bypass(argSymbol); didFallback = true;
                    };
                },
                \clear, {
                    if (pedalboardRef.respondsTo(\clear)) {
                        pedalboardRef.clear; didFallback = true;
                    };
                },
                \setSource, {
                    if (pedalboardRef.respondsTo(\setSource) and: { argSymbol.notNil }) {
                        pedalboardRef.setSource(argSymbol); didFallback = true;
                    };
                },
                \switch, {
                    // never call mpb.switch(); Object:switch is a control construct
                    // switching should be handled by the adapter
                },
                { } // default: do nothing
            );
        };

        if (didFallback) {
            ("Fallback MPB applied: " ++ shortPath).postln;
            ~pane.(\recv, "Fallback applied: " ++ shortPath);
            true
        } {
            ("⚠ No adapter for: " ++ shortPath).warn;
            ~pane.(\recv, "⚠ No adapter for: " ++ shortPath);
            false
        };
    };
};

sendCanonicalPath = { |shortPath|
    var okApply;
    okApply = applyCanonicalPath.(shortPath);
    ~refreshHUD.();
    okApply
};

// Navigation helpers
showChildrenList = {
    var items, shownText;
    items = builderRef.currentNode.children.collect({ |childNode| [childNode.name, childNode.fret] });
    shownText = "Children: " ++ items.asString;
    shownText.postln;
    ~pane.(\choices, items.asString);
    items
};

navigateByName = { |nameString|
    var nameStr;
    nameStr = nameString.asString;
    builderRef.navigateByName(nil, nameStr);
    commandManagerRef.updateDisplay;
    showChildrenList.();
};

navigateByFret = { |stringNumber, fretNumber|
    builderRef.navigateByFret(stringNumber, fretNumber);
    commandManagerRef.updateDisplay;
    showChildrenList.();
};

// Top-level aliases (emulator-like)
~toProg = {
    commandManagerRef.currentState = \prog;
    commandManagerRef.updateDisplay;
    "Navigation started (prog).".postln;
    ~pane.(\system, "Mode: prog (nav)");
    showChildrenList.();
};

~showNav = {
    var longPath, shortPath;
    longPath  = buildLongPathFromBuilder.();
    shortPath = canonicalizePath.(longPath);
    ("Long:  " ++ longPath).postln;
    ("Short: " ++ shortPath).postln;
    ~pane.(\diag, "Long=" ++ longPath ++ "  Short=" ++ shortPath);
};

~toQueue = {
    var shortPath;
    shortPath = canonicalizePath.( buildLongPathFromBuilder.() );
    commandManagerRef.queue.enqueueCommand(shortPath);
    ("Queued: " ++ shortPath).postln;
    ~pane.(\recv, "Queued: " ++ shortPath);
    shortPath
};

~toSend  = {
    var shortPath;
    shortPath = canonicalizePath.( buildLongPathFromBuilder.() );
    sendCanonicalPath.(shortPath);
};

~navName = navigateByName;
~navFret = navigateByFret;

"✔ Emulator online. Use: ~toProg, ~navName(\"…\"), ~navFret(s,f), ~showNav, ~toQueue, ~toSend".postln;
)

//////////////////////////////////////////////////////
// 7) Scenarios (NAME-based first; then direct CANONICAL)
//////////////////////////////////////////////////////
(
var unused;
~toProg.();
~navName.("audio");
~navName.("timebased");
~navName.("delay");
~showNav.();               // expect Short: /add/delay
~toSend.();                // robust adapter call (or safe fallback)
unused = nil; // keep var-first pattern satisfied
)

(
var unused;
~sendCanonicalPath.("/add/delay");
unused = nil;
)

(
var unused;
~toProg.();
~navName.("switch");
~showNav.();               // expect Short: /switch
~toSend.();                // apply via adapter (or try: ~sendCanonicalPath.("/switch"))
unused = nil;
)

//////////////////////////////////////////////////////
// 8) Fast audible checks (optional, reversible)
//////////////////////////////////////////////////////
// ~lpDemo_on.();       // UI demo ON: bars should move immediately
// ~lpDemo_off.();      // UI demo OFF: back to LPS retap
// ~diag_addTremA.();   // audible wobble on Chain A proves we are in LPS path
// ~diag_clearTrem.();  // remove wobble
// ~refreshHUD.();      // panes: status/chain text
