// MessagingToLPDisplay_Attempts.scd
// v0.2.1
// MD 20251007-1442

/*
Purpose
- Open LPDisplayLayoutWindow and make the top-row meters react to SendPeakRMS
  arriving on '/peakrmsA' and '/peakrmsB'.
- Expose the controller instance and its GUI window to environment variables so you can
  call display methods later: ~displayWindow (controller), ~win (actual Window).

Style
- var-first in every block; descriptive lowercase names; no server.sync.
- GUI work only on AppClock; server ops wrapped in Server.default.bind.
- Returns '-> a Window'.
*/

(
var lpDisplay, displayWindow, openDisplay, installMinimalTaps, bringUp;

// keep references in the environment (persist across evaluations)
~displayWindow = nil; // controller (LPDisplayLayoutWindow instance)
~win = nil;           // GUI Window instance

// 1) Open the LPDisplay controller/window (meters auto-bind to /peakrmsA/B)
openDisplay = {
    var win;
    lpDisplay = LPDisplayLayoutWindow.new;
    win = lpDisplay.open; // -> a Window; GUI OSCdefs are armed for /peakrmsA/B

    // Optional: mapping and console quieting
    lpDisplay.setHudMap(LPDisplayHudMap.new(-6, -60, 1.0));
    lpDisplay.setConsoleLevelsOn(false);

    // IMPORTANT: disable the built-in sources in LPDisplay
    lpDisplay.setSourceA(\srcZ);
    lpDisplay.setSourceB(\srcZ);

    // --- expose to environment for later interactive control ---
    ~displayWindow = lpDisplay; // use this for sendPaneText, setSourceA/B, etc.
    ~win = win;                 // use this if you need Window methods like .front

    win
};

// 3) Bring it up: open the window, (optionally install taps), front it, and return the window
bringUp = {
    var win;
    win = openDisplay.value;
    // If your graph already emits /peakrmsA/B, comment out the line below.
    //installMinimalTaps.value;
    AppClock.sched(0.0, { win.front; nil });
    win
};

// Run and return -> a Window
displayWindow = bringUp.value;
displayWindow
)



 ~displayWindow.sendPaneText(\left,"hello topleft");
 ~displayWindow.sendPaneText(\right,"hello topright");
~displayWindow.sendPaneText(\diag, "Hello diagnostics");
 ~displayWindow.sendPaneText(\choices,"hello choices");
 ~displayWindow.sendPaneText(\system,"hello system");
 ~displayWindow.sendPaneText(\recv,"hello receive");




// Send text to a pane (controller API lives on ~displayWindow)


// Toggle console meter prints, HUD, sources, etc.
~displayWindow.setConsoleLevelsOn(true);
~displayWindow.setHudMap(LPDisplayHudMap.new(-9, -60, 1.0));


