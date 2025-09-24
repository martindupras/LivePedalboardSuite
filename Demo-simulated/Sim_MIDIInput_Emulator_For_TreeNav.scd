// Sim_MIDIInput_Emulator_For_TreeNav.scd
// v0.1.2
// MD 20250924-1510
/*
Purpose
- Emulate hardware control of your system:
  • FOOT controller: mode changes (idle/prog/queue/send).
  • MIDI GUITAR: string/fret → channel/pitch → tree navigation.
- Keep everything in ONE file; evaluate section-by-section.

Style
- var-first in every block/closure; lowercase methods; no server.sync.
- Works with your current LivePedalboardSystem, CommandManager, and adapter bridge.
- Generated audio only (no SoundIn); Option A exclusivity remains enforced by your bring-up.
*/

// ───────────────────────────────────────────────────────────────────────────
// [0] Bring-up (idempotent): system + GUI + MagicPedalboard + adapter bridge
//    Evaluate once after a fresh compile (or re-run to refresh).
// ───────────────────────────────────────────────────────────────────────────
(
var needNew, systemRef;

// If an older system exists, shut it down cleanly.
if(~system.notNil and: { ~system.respondsTo(\shutdownAll) }) {
    ~system.shutdownAll;
};

// Create (or reuse) the LivePedalboardSystem and bring everything up.
needNew = (~system.isNil);
if(needNew) {
    systemRef = LivePedalboardSystem.new(nil); // nil → class default JSON path resolver
    ~system = systemRef;
};

~system.bringUpAll;          // server + GUI + pedalboard + command system + meters
~system.installAdapterBridge; // queueExportCallback routes SHORT canonicals to MPB via adapter

// Convenience handles
~cm  = ~system.commandManager;
~mm  = ~cm.midiManager;
~mpb = ~system.pedalboard;
~gui = ~system.statusDisplay;

"✅ System is up. (~system, ~cm, ~mm, ~mpb, ~gui)".postln;
)

// ───────────────────────────────────────────────────────────────────────────
// [1] Emulation helpers (define once)
//    These call your actual handlers—no MIDI devices required.
//    FOOT MAPPING (noteOn): 36→\idle, 38→\prog, 40→\queue, 41→\send
//    GUITAR MAPPING (channels 0..5 → strings 6..1) with bases [40,45,50,55,59,64]
// ───────────────────────────────────────────────────────────────────────────
(
var ensure, bases;

// Basic guard so we don't call handlers before bring-up.
ensure = {
    var ok;
    ok = ~system.notNil
     and: { ~system.commandManager.notNil }
     and: { ~system.commandManager.midiManager.notNil };
    if(ok.not) { "⚠️ Run section [0] (bring-up) first.".warn };
    ok
};

// E A D G B E (low→high), per your GuitarMIDIHandler
bases = IdentityDictionary[
    0 -> 40,  // chan 0 → string 6 (E2)
    1 -> 45,  // chan 1 → string 5 (A2)
    2 -> 50,  // chan 2 → string 4 (D3)
    3 -> 55,  // chan 3 → string 3 (G3)
    4 -> 59,  // chan 4 → string 2 (B3)
    5 -> 64   // chan 5 → string 1 (E4)
];

// FOOT: emulate pressing a foot button (note number).
~fc = { arg noteNumber;
    var mmLocal;
    if(ensure.().not) { ^nil };
    mmLocal = ~system.commandManager.midiManager;
    // channel is irrelevant for FootControllerHandler; value = note number.
    mmLocal.footControllerHandler.handleMessage(0, \noteOn, noteNumber.asInteger);
};

// Foot shortcuts
~toIdle  = { ~fc.(36) };  // idle
~toProg  = { ~fc.(38) };  // prog (tree navigation)
~toQueue = { ~fc.(40) };  // queue (enqueue current canonical)
~toSend  = { ~fc.(41) };  // send  (export & apply queue via bridge)

// GUITAR: emulate “play fret” on given string (1..6).
// Computes channel = 6 - string, pitch = base + fret; calls your GuitarMIDIHandler.
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

// Convenience alias for navigation (string,fret)
~nav = { arg s, f; ~gm.(s, f) };

// Peek: print the builder’s path and the canonical short form (e.g., "/add/delay").
~showNav = {
    var cm, b, long, short;
    if(ensure.().not) { ^nil };
    cm = ~system.commandManager;
    b  = cm.builder;
    b.printPathToRoot;
    long  = cm.buildLongPathFromBuilder(b);
    short = cm.canonicalPathFromBuilder(b);
    ("• long=" ++ long ++ "  |  canonical=" ++ short).postln;
};

// Optional: show available choices in GUI (if present)
~refreshChoices = {
    if(~system.notNil) { ~system.commandManager.updateDisplay };
};
)

// ───────────────────────────────────────────────────────────────────────────
// [2] Scenario A — Add delay to NEXT via guitar nav, then switch
//    Top-level/children/grandchildren frets per your mapping:
//    string 6 fret 1 → "audio", string 5 fret 5 → "timebased", string 4 fret 3 → "delay"
//    Then queue (note 40) and send (note 41) → adapter applies "/add/delay"
// ───────────────────────────────────────────────────────────────────────────
(
var done;
~toProg.();           // enter navigation mode
~refreshChoices.();   // optional UI refresh
~nav.(6, 1);          // 6/1 → audio
~nav.(5, 5);          // 5/5 → timebased
~nav.(4, 3);          // 4/3 → delay
~showNav.();          // should report canonical "/add/delay"
~toQueue.();          // enqueue
~toSend.();           // apply via adapter
done = true;
"✅ Scenario A complete (add delay, then you can use Scenario B to switch).".postln;
)

// ───────────────────────────────────────────────────────────────────────────
// [3] Scenario B — Switch chain from top-level “switch”
//    string 6 fret 5 → "switch" → queue → send
// ───────────────────────────────────────────────────────────────────────────
(
var done;
~toProg.();
~nav.(6, 5);      // top-level "switch"
~showNav.();      // should be "/switch"
~toQueue.();
~toSend.();
done = true;
"✅ Scenario B complete (switch with guarded crossfade).".postln;
)

// ───────────────────────────────────────────────────────────────────────────
// [4] Scenario C — Bypass: chain → bypass → delay → on
//    Adjust frets if your JSON uses slightly different grandchildren numbers.
//    Example: 6/3="chain", 5/9="bypass", 4/3="delay", 3/3="on"
// ───────────────────────────────────────────────────────────────────────────
(
var done;
~toProg.();
~nav.(6, 3);   // "chain"
~nav.(5, 9);   // "bypass"
~nav.(4, 3);   // "delay"
~nav.(3, 3);   // "on"    // change to actual fret if needed
~showNav.();
~toQueue.();
~toSend.();
done = true;
"✅ Scenario C complete (bypass delay ON).".postln;
)

// ───────────────────────────────────────────────────────────────────────────
// [5] Quick extras
//    • Re-run [2] then [3] to hear the effect.
//    • To bypass OFF, redo [4] but pick “…/off” as per your tree’s leaf fret.
//    • Inspect the current queue at any time:
//        ~system.commandManager.midiManager.queue.commandList.postln;
// ───────────────────────────────────────────────────────────────────────────
