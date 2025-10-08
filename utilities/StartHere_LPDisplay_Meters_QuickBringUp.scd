// StartHere_LPDisplay_Meters_QuickBringUp.scd
// v0.2
// MD 20251007-1012

/*
Purpose
- Open LPDisplayLayoutWindow and make the top-row meters react to SendPeakRMS
  arriving on '/peakrmsA' and '/peakrmsB'.
- Also (optionally) install safe, pass-through meter taps on Ndef(\chainA/\chainB)
  if you want to drive the meters from those proxies.

Style
- var-first in every block; descriptive lowercase names; no server.sync.
- GUI work only on AppClock; server ops wrapped in Server.default.bind.
- Returns '-> a Window'.
*/

(
var lpDisplay, displayWindow, openDisplay, installMinimalTaps, bringUp;

// 1) Open the LPDisplay controller/window (meters auto-bind to /peakrmsA/B)
openDisplay = {
    var win;
    lpDisplay = LPDisplayLayoutWindow.new;
    win = lpDisplay.open;            // -> a Window; GUI OSCdefs are armed for /peakrmsA/B
    // Optional: mapping and console quieting (safe no-ops if you skip)
    lpDisplay.setHudMap(LPDisplayHudMap.new(-6, -60, 1.0));
    lpDisplay.setConsoleLevelsOn(false);


	// IMPORTANT: disable the built-in sources in LPDisplay:
	lpDisplay.setSourceA(\srcZ);
	lpDisplay.setSourceB(\srcZ);

    win
};


// 3) Bring it up: open the window, install taps (optional), front it, and return the window
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