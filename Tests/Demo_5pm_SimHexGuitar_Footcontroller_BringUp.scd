// Demo_5pm_SimHexGuitar_Footcontroller_BringUp.scd
// v0.1.1
// MD 2025-09-26 16:35 BST

/* Purpose / Style
   Purpose: One-file, sectioned run-sheet for the 5pm demo. Brings up the system, ensures a single
            “MagicDisplayGUI …” window, installs the adapter bridge and robust meter taps, and provides
            simulated footcontroller + hex guitar. Applies canonical commands via the adapter to avoid
            the known queue/display crash path today.
   Style:   SC only; known-good syntax; var-first everywhere; no non-local returns; no try/protect;
            no server.sync; GUI on AppClock; the bring-up section returns → a Window.
*/

// [0] BRING-UP (build once; returns → a Window)
(
var needNew, winList, pickedWindow;

needNew = ~system.isNil;
if(needNew) {
    var treePath;  // nil → LivePedalboardSuite resolver precedence
    treePath = nil;
    ~system = LivePedalboardSystem.new(treePath);                     // resolver inside class
    ~system.bringUpAll;                                               // GUI+MPB+CommandManager+meters staged
} {
    // Refresh GUI only (avoid double full bring-up)
    ~system.closeExistingMagicDisplayWindows;
    ~system.bringUpMagicDisplayGUI;                                   // sets statusDisplay and re-binds if commandManager exists
};

// Return the single MagicDisplayGUI window and front it
winList = Window.allWindows;
pickedWindow = winList.detect({ arg w;
    var titleString;
    titleString = w.tryPerform(\name);
    titleString.notNil and: { titleString.asString.beginsWith("MagicDisplayGUI") }
});
if(pickedWindow.notNil) { pickedWindow.front };
pickedWindow
)

// [1] ADAPTER BRIDGE + STABLE TAPS + INLINE OVERLAY METERS (self-contained)
/* Reason:
   - Your GUI shows the /md/levels OSC listener is installed, but the overlay meters weren't attached in your run.
   - We install stable taps (A=2001, B=2002) and a minimal overlay here so you see movement immediately.  */
(
var ensureBridge, ensureStableTaps, installLevelsListener, attachOverlay;

ensureBridge = {
    ~system.installAdapterBridge;  // routes canonical queue strings through adapter; also toggles active-chain HUD
    nil
};

ensureStableTaps = {
    // Sanitised + smoothed visual taps to /md/levels with IDs 2001 (A) / 2002 (B)
    ~system.installStableMeters;
    nil
};

installLevelsListener = {
    // Minimal HUD-side listener (independent of any external file)
    ~md_levelsById = ~md_levelsById ? IdentityDictionary.new;
    if(OSCdef.all.at(\md_levels_inline).notNil) { OSCdef.all.at(\md_levels_inline).free };
    OSCdef(\md_levels_inline, { arg msg;
        var id, l, r, L, R;
        if(msg.size >= 5) {
            id = msg[2];
            l  = msg[3].asFloat; r = msg[4].asFloat;
            L  = l.isFinite.if({ l.clip(0,1) }, { 0.0 });
            R  = r.isFinite.if({ r.clip(0,1) }, { 0.0 });
            ~md_levelsById.put(id, [L, R]);
        };
        nil
    }, "/md/levels", recvPort: NetAddr.langPort);
    nil
};

attachOverlay = {
    var hudWindow, overlayView, pad, w, h, tick;
    hudWindow = Window.allWindows.detect({ arg ww;
        var n = ww.tryPerform(\name);
        n.notNil and: { n.asString.beginsWith("MagicDisplayGUI") }
    });
    if(hudWindow.isNil) { "⚠️ No MagicDisplayGUI window yet; run [0] first.".warn; ^nil };

    pad = 8; w = 22; h = 86;
    overlayView = UserView(hudWindow, Rect(pad, pad, w, h));
    overlayView.background_(Color.clear);
    overlayView.drawFunc_({ arg v;
        var pairA, pairB, aL, aR, bL, bR, halfH, halfW;
        pairA = ~md_levelsById.at(2001) ? [0, 0];       // A (replyID 2001)
        pairB = ~md_levelsById.at(2002) ? [0, 0];       // B (replyID 2002)
        aL = pairA[0]; aR = pairA[1];
        bL = pairB[0]; bR = pairB[1];
        halfH = v.bounds.height/2; halfW = v.bounds.width/2;

        // A (bottom half): left=green, right=blue
        Pen.fillColor = Color(0.35, 0.9, 0.35);
        Pen.addRect(Rect(0, halfH - (halfH * aL), halfW, (halfH * aL))); Pen.fill;
        Pen.fillColor = Color(0.35, 0.6, 0.95);
        Pen.addRect(Rect(halfW, halfH - (halfH * aR), halfW, (halfH * aR))); Pen.fill;

        // B (top half): lighter tint
        Pen.fillColor = Color(0.35, 0.9, 0.35).blend(Color.white, 0.15);
        Pen.addRect(Rect(0, v.bounds.height - (halfH * bL), halfW, (halfH * bL))); Pen.fill;
        Pen.fillColor = Color(0.35, 0.6, 0.95).blend(Color.white, 0.15);
        Pen.addRect(Rect(halfW, v.bounds.height - (halfH * bR), halfW, (halfH * bR))); Pen.fill;
    });

    // Refresh loop (AppClock only)
    tick = Routine({
        var keep;
        keep = true;
        while({ keep and: { hudWindow.notNil and: { hudWindow.isClosed.not } } }, {
            overlayView.refresh;
            0.15.wait;
        });
    }).play(AppClock);

    "✅ Inline overlay meters attached (top-left)".postln;
    overlayView
};

// Apply fixes
ensureBridge.();
ensureStableTaps.();
installLevelsListener.();
attachOverlay.();
nil
)

// [2] SIMULATED CONTROLLERS (foot + hex guitar → nav); AVOID queue/send crash today
(
var ensure, bases;

// Guard
ensure = {
    var ok;
    ok = ~system.notNil
      and: { ~system.commandManager.notNil }
      and: { ~system.commandManager.midiManager.notNil };
    if(ok.not) { "⚠️ Run section [0] first.".warn };
    ok
};

// Channel→string base pitches (E A D G B E) as per GuitarMIDIHandler
bases = IdentityDictionary[
    0 -> 40, 1 -> 45, 2 -> 50, 3 -> 55, 4 -> 59, 5 -> 64
];

// FOOT: emulate a foot button press (note number)
~fc = { arg noteNumber;
    var mmLocal;
    if(ensure.().not) { ^nil };
    mmLocal = ~system.commandManager.midiManager;
    mmLocal.footControllerHandler.handleMessage(0, \noteOn, noteNumber.asInteger);  // 36 idle, 38 prog, 40 queue, 41 send
};

// Shortcuts
~toIdle  = { var n; n = 36; ~fc.(n) };
~toProg  = { var n; n = 38; ~fc.(n) };

// GUITAR: emulate “string s @ fret f”
~gm = { arg stringNum, fret;
    var mmLocal, chan, base, pitch;
    if(ensure.().not) { ^nil };
    mmLocal = ~system.commandManager.midiManager;
    chan = (6 - stringNum.asInteger).clip(0, 5);
    base = bases[chan];
    if(base.isNil) { "⚠️ Invalid string number.".warn; ^nil };
    pitch = base + fret.asInteger;
    mmLocal.guitarHandler.handleMessage(chan, \noteOn, pitch);
};

// Helper: print current and canonical path
~showNav = {
    var cm, b, long, short;
    if(ensure.().not) { ^nil };
    cm = ~system.commandManager;
    b  = cm.builder;
    b.printPathToRoot;
    long  = cm.buildLongPathFromBuilder(b);
    short = cm.canonicalPathFromBuilder(b);         // "/add/delay", "/switch", etc.
    ("• long=" ++ long ++ "  canonical=" ++ short).postln;
    short
};
nil
)

// [3] DEMO SCENARIOS (canonical applied via adapter to avoid queue/display crash path)

// Scenario A — Add delay to NEXT via guitar nav, then apply canonical via adapter (no queue/send today)
(
var path;
~toProg.();      // enter navigation mode
~gm.(6, 1);      // "audio"    (string 6 fret 1)  [1](https://openuniv-my.sharepoint.com/personal/md24538_open_ac_uk/Documents/Microsoft%20Copilot%20Chat%20Files/consoleout_20250926-1515.txt)
~gm.(5, 5);      // "timebased"(string 5 fret 5)  [1](https://openuniv-my.sharepoint.com/personal/md24538_open_ac_uk/Documents/Microsoft%20Copilot%20Chat%20Files/consoleout_20250926-1515.txt)
~gm.(4, 3);      // "delay"    (string 4 fret 3)  [1](https://openuniv-my.sharepoint.com/personal/md24538_open_ac_uk/Documents/Microsoft%20Copilot%20Chat%20Files/consoleout_20250926-1515.txt)
path = ~showNav.();           // should be "/add/delay"
if(~ct_applyOSCPathToMPB.notNil) {
    ~ct_applyOSCPathToMPB.(path, ~system.pedalboard, ~system.statusDisplay);  // apply via adapter
} {
    "⚠️ Adapter not loaded.".warn;
};
"✅ Scenario A applied (add delay to NEXT).".postln;
nil
)

// Scenario B — Navigate to top-level “switch” and apply canonical via adapter
(
var path;
~toProg.();
~gm.(6, 5);      // "switch" (string 6 fret 5)  [1](https://openuniv-my.sharepoint.com/personal/md24538_open_ac_uk/Documents/Microsoft%20Copilot%20Chat%20Files/consoleout_20250926-1515.txt)
path = ~showNav.();           // "/switch"
if(~ct_applyOSCPathToMPB.notNil) {
    ~ct_applyOSCPathToMPB.(path, ~system.pedalboard, ~system.statusDisplay);  // guarded crossfade + post-audit
} {
    "⚠️ Adapter not loaded.".warn;
};
"✅ Scenario B applied (switch).".postln;
nil
)
