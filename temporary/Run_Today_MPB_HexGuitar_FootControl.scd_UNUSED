// Run_Today_MPB_HexGuitar_FootControl.scd
// v0.1.0
// MD 20251006-0821

/*
Purpose
- Open LPDisplayLayoutWindow (display-only), bring up LivePedalboardSystem, auto-bind the display,
  install the display-only adapter bridge, and enable AutoMeters so /peakrmsA/B feed LPDisplay.
- Print connected MIDI devices and simple instructions to drive with foot controller + hex guitar.

Style
- One top-level () block; var-first; descriptive lowercase names; no single-letter locals; no non-local returns (^).
- GUI on AppClock only; no server.sync; server ops are allowed inside called classes only.
*/

(
var win, lpController, systemRef;
var openLayoutWindow, makeSystem, bindDisplay, wireAdapterMeters, showMIDIHelp;
var frontWindow, listMIDISources;

// 0) Close any older MagicDisplay windows (idempotent)
AppClock.sched(0.0, {
    Window.allWindows
        .select({ arg w; (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
        .do(_.close);
    nil
});

// 1) Open LPDisplayLayoutWindow (canonical controller)
openLayoutWindow = {
    var created;
    created = LPDisplayLayoutWindow.respondsTo(\open).if({
        LPDisplayLayoutWindow.open
    },{
        LPDisplayLayoutWindow.new
    });
    created.notNil.if({
        created.window.alwaysOnTop_(true);
        created.window.name = "MagicDisplayGUI - LPDisplayLayout";
    });
    created
};

// 2) Bring up the LivePedalboardSystem (headless UI), then auto-bind LPDisplay if present
makeSystem = {
    var lps, jsonPath;
    lps = LivePedalboardSystem.new(nil); // class has resolver for the JSON path
    lps.bringUpAll; // ensure server, MPB, command system, GUI (headless window mgmt)
    lps
};

// 3) Auto-bind the LPDisplay controller to CommandManager via LPDisplayAdapter
bindDisplay = { arg lps, controller;
    // extension expects ~guiLP to exist; set it for the adapter auto-bind helper
    ~guiLP = controller;
    lps.autoBindLPDisplayIfPresent; // extension that binds CM.display = LPDisplayAdapter(controller)
    nil
};

// 4) Wire the display-only adapter bridge + AutoMeters taps (/peakrmsA,/peakrmsB)
wireAdapterMeters = { arg lps;
    // Bridge: forward canonical paths and toggle ACTIVE/NEXT visuals only (no audio policies here)
    lps.installAdapterBridge;
    // AutoMeters: put SendPeakRMS taps inside Ndef(\chainA/\chainB) to /peakrmsA/B; re-arm after /switch
    lps.enableAutoMeters(18, 0.35);
    nil
};

// 5) Convenience: list MIDI sources and show control hints
listMIDISources = {
    var mm;
    mm = systemRef.commandManager.midiManager;
    "🎛  Connected MIDI sources (symbol → uid):".postln;
    mm.listDevices; // prints the dictionary your code builds at init
};

showMIDIHelp = {
    "--- Controls ---".postln;
    "Foot controller: 36=idle, 38=prog (navigate), 40=queue, 41=send".postln;
    "Hex guitar (prog): pluck per-string to select fret per your mapping".postln;
    "Watch 'System'/'Choices' panes; meters are from chain sinks via /peakrmsA/B.".postln;
};

// Bring-up sequence
lpController = openLayoutWindow.();
systemRef   = makeSystem.();
bindDisplay.(systemRef, lpController);
wireAdapterMeters.(systemRef);

// Front the window and print helpers
frontWindow = lpController.tryPerform(\window);
AppClock.sched(0.05, { frontWindow.front; nil });
listMIDISources.();
showMIDIHelp.();

// Return -> a Window (so the IDE shows it)
frontWindow
)
