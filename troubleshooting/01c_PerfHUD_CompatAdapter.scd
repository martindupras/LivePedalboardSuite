//////////////////////////////////////////////////////////////
// 01c_PerfHUD_CompatAdapter.scd
// v0.9.0  MD 2025-09-29 12:35
//
// Purpose
// - Add a minimal, GridDemo-compatible layer on top of the existing
//   PerfHUD window (meters/layout unchanged).
// - Provide these helpers for test scripts:
//     ~hud_highlightCurrentColumn.(\chainA | \chainB)  // solid, no pulse
//     ~hud_showExpectation.("text", secs?)             // top status line
//     ~hud_updateTextField.(\state, "text")            // compat alias
//     ~hud_setOperations.([ "fret 3 → add", "fret 5 → …" ])
//
// Style
// - var-first; descriptive names; AppClock-only for UI; no server.sync.
// - Nil-safe: aborts cleanly if no PerfHUD window is found.
// - Does NOT modify PerfHUD's own ticker; simply draws opaque overlays.
//
(
var win, host, hasWindow, ensureOverlays, relayoutOverlays;
var overlayLeft, overlayRight, statusLabel, choicesText;
var drawSolidA, drawSolidB, setStatus, setChoices, attachResize;

////////////////////////////////////////////////////////////
// 0) Find the PerfHUD window synchronously
win = ~gui;   // you already set this in 01b; it prints as a Window
hasWindow = win.notNil and: { win.isKindOf(Window) };
if(hasWindow.not) {
    "PerfHUD_CompatAdapter: ~gui is not a Window; aborting adapter.".warn;
    ^nil;
};

// Root view of the window
host = win.tryPerform(\view);
if(host.isNil) {
    "PerfHUD_CompatAdapter: window has no .view; aborting adapter.".warn;
    ^nil;
};

////////////////////////////////////////////////////////////
// 1) Create overlays (idempotent)
ensureOverlays = {
    var b, halfW, pad, topY, colH, rightX, rightW;
    b = host.bounds;  // Rect in UI coords (origin at top-left in View)
    pad = 8;
    halfW = (b.width / 2).asInteger;

    // reserve a small top bar for status
    topY = pad;
    // columns height = full minus top/status area and a small bottom pad
    colH = (b.height - (pad*3) - 180).max(40);

    // LEFT column overlay (Chain A)
    overlayLeft = overlayLeft ?? { CompositeView(host) };
    overlayLeft.bounds = Rect(pad, topY + 28, halfW - (pad*1.5), colH);
    overlayLeft.background = Color(0.85, 1.0, 0.85, 1.0);  // ACTIVE-green
    overlayLeft.visible = false; // default off; we turn it on in highlight
    overlayLeft.front;

    // RIGHT column overlay (Chain B)
    rightX = halfW + (pad * 0.5);
    rightW = b.width - rightX - pad;
    overlayRight = overlayRight ?? { CompositeView(host) };
    overlayRight.bounds = Rect(rightX, topY + 28, rightW, colH);
    overlayRight.background = Color(0.85, 1.0, 0.85, 1.0);
    overlayRight.visible = false;
    overlayRight.front;

    // STATUS label at very top (compatible with showExpectation / updateTextField(\state))
    statusLabel = statusLabel ?? { StaticText(host) };
    statusLabel.bounds = Rect(pad, pad, b.width - (pad*2), 22);
    statusLabel.align = \center;
    statusLabel.stringColor = Color.black;
    statusLabel.string = "Ready";
    statusLabel.front;

    // CHOICES text (right side, under the status bar)
    choicesText = choicesText ?? { TextView(host) };
    choicesText.bounds = Rect(halfW + (pad * 0.5), overlayRight.bounds.top - 22, rightW, 160);
    choicesText.editable = false;
    choicesText.hasVerticalScroller = true;
    choicesText.background = Color(0.97, 0.97, 0.97);
    choicesText.string = ""; // empty until setOperations call
    choicesText.front;
};

relayoutOverlays = {
    AppClock.sched(0.0, { ensureOverlays.value; nil });
};

////////////////////////////////////////////////////////////
// 2) Small helpers used by the tests (GridDemo-compatible)

drawSolidA = { // solid ACTIVE on A
    AppClock.sched(0.0, {
        ensureOverlays.value;
        overlayLeft.visible = true;
        overlayRight.visible = false;
        statusLabel.string = (statusLabel.tryPerform(\string) ? "Ready").asString;
        nil
    });
};

drawSolidB = { // solid ACTIVE on B
    AppClock.sched(0.0, {
        ensureOverlays.value;
        overlayLeft.visible = false;
        overlayRight.visible = true;
        statusLabel.string = (statusLabel.tryPerform(\string) ? "Ready").asString;
        nil
    });
};

setStatus = { |textString = "Ready", seconds = 0|
    AppClock.sched(0.0, {
        ensureOverlays.value;
        statusLabel.string = textString.asString;
        nil
    });
};

setChoices = { |itemsArray|
    var s;
    s = (itemsArray ? []).collect(_.asString).join("\n");
    AppClock.sched(0.0, {
        ensureOverlays.value;
        choicesText.string = (s.size > 0).if({ s }, { "—" });
        choicesText.scrollToTop;
        nil
    });
};

////////////////////////////////////////////////////////////
// 3) Public tilde helpers (what your 02B / 02F will call if ~gui lacks methods)

~hud_highlightCurrentColumn = { |which|
    var w = (which ? \chainA).asSymbol;
    if(w == \chainA) { drawSolidA.value } { drawSolidB.value };
};

~hud_showExpectation = { |text, secs = 0| setStatus.value(text, secs) };

~hud_updateTextField = { |keySym, valueText|
    var k = keySym.asSymbol;
    if(k == \state) { setStatus.value(valueText.asString, 0) }
    { /* ignore other keys for now; extend later if needed */ };
};

~hud_setOperations = { |itemsArray| setChoices.value(itemsArray) };

////////////////////////////////////////////////////////////
// 4) Keep overlays in place on window resize
attachResize = {
    var resizeFunc;
    resizeFunc = {
        relayoutOverlays.value;
        nil
    };
    win.onResize = { resizeFunc.value };
};

////////////////////////////////////////////////////////////
// 5) Go
ensureOverlays.value;
attachResize.value;
"PerfHUD_CompatAdapter installed: uses ~hud_* helpers (solid A/B + status + choices).".postln;
)
