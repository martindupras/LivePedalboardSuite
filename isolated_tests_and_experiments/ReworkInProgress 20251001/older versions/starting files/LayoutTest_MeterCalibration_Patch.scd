// LayoutTest_MeterCalibration_Patch.scd
// v1.2 - calibrate existing Layout Test meters (dB mapping: top/floor/gamma) + balanced helpers
// MD 20250930

/* Purpose
   - Calibrate the already-running "Layout Test" meters using a perceptual dB mapping.
   - Keep audio graph and console logging untouched; rebind only the GUI meter OSCdefs.
   - Provide helpers to set/inspect mapping and to preview expected UI for a given RMS dB.

   Style
   - var-first declarations in every block/function
   - lowercase method names and descriptive identifiers
   - no non-local returns (^)
   - GUI updates via AppClock.defer
*/

(
var leftPaneName, rightPaneName;
var ensureHudVars, mapLinToUi, valueFromMsg;
var findByPaneLabel, bindLayoutUi, installMappedMeters;
var meterLeft, meterRight;

// --- pane labels (as used in WindowLayout_Grid_WithSigChainsAndMeters_Debug.scd v1.8) ---
leftPaneName  = "Top Left Pane";
rightPaneName = "Top Right Pane";

// --- ensure globals & defaults exist (top = -6 dBFS RMS, floor = -60 dBFS RMS, gamma = 1.0) ---
ensureHudVars = {
    if(~hud_topDb.isNil)   { ~hud_topDb   = -6.0 };
    if(~hud_floorDb.isNil) { ~hud_floorDb = -60.0 };
    if(~hud_gamma.isNil)   { ~hud_gamma   = 1.0 };
};

// --- linear (0..1) -> UI (0..1) via dB headroom + gamma ---
mapLinToUi = { |lin, topDb, floorDb, gamma|
    var v, vdb, tdb, fdb, g, u;
    v   = lin.max(1e-9);     // avoid -inf
    vdb = v.ampdb;           // linear amplitude -> dB
    tdb = topDb.asFloat;
    fdb = floorDb.asFloat;
    g   = gamma.asFloat.max(1e-6);

    vdb = vdb.clip(fdb, tdb);
    u   = (vdb - fdb) / (tdb - fdb);
    u   = u.pow(g);
    u.clip(0.0, 1.0)
};

// --- extract meter value from SendPeakRMS OSC (use last element = final RMS) ---
valueFromMsg = { |msg|
    var v, sz;
    v = 0.0;
    if(msg.notNil) {
        sz = msg.size;
        if(sz >= 4) { v = msg[sz - 1].asFloat; };
    };
    v.clip(0.0, 1.0)
};

// --- locate a LevelIndicator under a pane identified by its label (StaticText string) ---
findByPaneLabel = { |rootView, paneLabelString|
    var foundStatic, result, searchStatic, searchUnderParent;

    foundStatic = nil;
    result = nil;

    searchStatic = { |view|
        var i, n, child;
        i = 0; n = view.children.size;
        while({ i < n }, {
            child = view.children[i];
            if(child.isKindOf(StaticText) and: { child.string == paneLabelString }) {
                foundStatic = child;
            }{
                searchStatic.(child);
            };
            i = i + 1;
        });
    };

    searchUnderParent = { |view|
        var i, n, child;
        i = 0; n = view.children.size;
        while({ i < n }, {
            child = view.children[i];
            if(child.isKindOf(LevelIndicator)) {
                if(result.isNil) { result = child; };
            }{
                searchUnderParent.(child);
            };
            i = i + 1;
        });
    };

    searchStatic.(rootView);
    if(foundStatic.notNil and: { foundStatic.parent.notNil }) {
        searchUnderParent.(foundStatic.parent);
    };
    result
};

// --- find existing "Layout Test" meters and cache them ---
bindLayoutUi = {
    var win, root;
    win = Window.allWindows.detect({ |w| w.name == "Layout Test" });
    if(win.isNil) {
        "Layout Test window not found. Start WindowLayout_Grid_WithSigChainsAndMeters_Debug.scd first.".postln;
    }{
        root = win.view;
        meterLeft  = findByPaneLabel.(root, leftPaneName);
        meterRight = findByPaneLabel.(root, rightPaneName);
        if(meterLeft.isNil or: { meterRight.isNil }) {
            "Could not locate LevelIndicators in the Layout Test panes.".postln;
        }{
            ~lt_meterLeft  = meterLeft;
            ~lt_meterRight = meterRight;
            "Bound meters: left/right found.".postln;
        };
    };
};

// --- rebind only the GUI meter OSCdefs to apply mapping; keep console OSCdefs intact ---
installMappedMeters = {
    var a, b;

    a = OSCdef(\rmsA_toGUI);
    if(a.notNil) { a.free; };

    b = OSCdef(\rmsB_toGUI);
    if(b.notNil) { b.free; };

    OSCdef(\rmsA_toGUI, { |msg|
        var v, ui;
        v  = valueFromMsg.(msg);
        ui = mapLinToUi.(v, ~hud_topDb, ~hud_floorDb, ~hud_gamma);
        { ~lt_meterLeft.value_(ui) }.defer;
    }, '/peakrmsA');

    OSCdef(\rmsB_toGUI, { |msg|
        var v, ui;
        v  = valueFromMsg.(msg);
        ui = mapLinToUi.(v, ~hud_topDb, ~hud_floorDb, ~hud_gamma);
        { ~lt_meterRight.value_(ui) }.defer;
    }, '/peakrmsB');

    ("Mapped meter responders installed (top=" ++ ~hud_topDb
        ++ " dB, floor=" ++ ~hud_floorDb
        ++ " dB, gamma=" ++ ~hud_gamma ++ ").").postln;
};

// --- bring-up for this patch ---
ensureHudVars.();
bindLayoutUi.();
if(~lt_meterLeft.notNil and: { ~lt_meterRight.notNil }) {
    installMappedMeters.();
} {
    "Meter calibration patch not installed (meters not bound).".postln;
};

// --- balanced helpers (set/preview/print) ---
~hud_set = { |key, value|
    var k, v, tmp;
    k = key.asSymbol;
    v = value.asFloat;

    if(k == \top)   { ~hud_topDb   = v };
    if(k == \floor) { ~hud_floorDb = v };
    if(k == \gamma) { ~hud_gamma   = v.max(1e-6) };

    if(~hud_topDb <= ~hud_floorDb) {
        tmp = ~hud_topDb;
        ~hud_topDb = ~hud_floorDb + 0.1;
        ("Adjusted top to floor+0.1 dB (was " ++ tmp ++ ") to keep mapping valid.").postln;
    };

    ("HUD mapping set: top=" ++ ~hud_topDb
        ++ " dB, floor=" ++ ~hud_floorDb
        ++ " dB, gamma=" ++ ~hud_gamma).postln;
};

~hud_preview = { |db|
    var top, floor, gamma, lin, dbClipped, u;
    top = ~hud_topDb.asFloat;
    floor = ~hud_floorDb.asFloat;
    gamma = ~hud_gamma.asFloat.max(1e-6);

    lin = db.dbamp.clip(1e-9, 1.0);
    dbClipped = lin.ampdb.clip(floor, top);
    u = (dbClipped - floor) / (top - floor);
    u = u.pow(gamma);
    ("UI -> " ++ u.round(0.003) ++ " for " ++ db ++ " dBFS RMS").postln;
    u
};

~hud_print = {
    ("HUD: top=" ++ ~hud_topDb ++ " dB, floor=" ++ ~hud_floorDb ++ " dB, gamma=" ++ ~hud_gamma).postln;
};

~hud_print.();
)
