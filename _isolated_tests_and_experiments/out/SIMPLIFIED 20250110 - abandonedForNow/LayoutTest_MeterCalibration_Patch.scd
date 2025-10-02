// LayoutTest_MeterCalibration_Patch.scd
// v1.3 — simpler bind + HUD mapper; only GUI responders are replaced
// MD 20251001

/* Purpose
 - Calibrate existing "Layout Test" meters using a perceptual dB mapping (top/floor/gamma).
 - Rebind only the GUI OSCdefs to apply mapping; preserve console OSCdefs untouched.
 - Provide ~hud_set/~hud_preview/~hud_print and a reusable ~hud_map_linear_to_ui.
 Style
 - var-first declarations; lowercase names; no non-local returns; AppClock.defer for GUI.
*/

(
var win, root, meter_left, meter_right;
var find_window_by_name, find_level_by_pane_label;
var install_mapped_gui, value_from_msg;

// Defaults (RMS dB): top = -6 dB, floor = -60 dB, gamma = 1.0
if(~hud_topDb.isNil)  { ~hud_topDb  = -6.0 };
if(~hud_floorDb.isNil){ ~hud_floorDb = -60.0 };
if(~hud_gamma.isNil)  { ~hud_gamma  = 1.0 };

// Linear (0..1) -> UI (0..1) using dB window and gamma
~hud_map_linear_to_ui = { |lin|
    var v, vdb, top, floor, g, u;
    v = lin.max(1e-9);
    vdb = v.ampdb;
    top = ~hud_topDb.asFloat;
    floor = ~hud_floorDb.asFloat;
    g = ~hud_gamma.asFloat.max(1e-6);
    vdb = vdb.clip(floor, top);
    u = (vdb - floor) / (top - floor);
    u = u.pow(g);
    u.clip(0.0, 1.0)
};

// Small HUD helpers
~hud_set = { |key, value|
    var k, v, tmp;
    k = key.asSymbol; v = value.asFloat;
    if(k == \top)   { ~hud_topDb = v };
    if(k == \floor) { ~hud_floorDb = v };
    if(k == \gamma) { ~hud_gamma = v.max(1e-6) };
    if(~hud_topDb <= ~hud_floorDb) {
        tmp = ~hud_topDb; ~hud_topDb = ~hud_floorDb + 0.1;
        ("Adjusted top to floor+0.1 dB (was " ++ tmp ++ ")").postln;
    };
    ("HUD mapping set: top=" ++ ~hud_topDb ++ " dB, floor=" ++ ~hud_floorDb ++ " dB, gamma=" ++ ~hud_gamma).postln;
};

~hud_preview = { |db|
    var top, floor, gamma, lin, db_clip, u;
    top = ~hud_topDb.asFloat; floor = ~hud_floorDb.asFloat;
    gamma = ~hud_gamma.asFloat.max(1e-6);
    lin = db.dbamp.clip(1e-9, 1.0);
    db_clip = lin.ampdb.clip(floor, top);
    u = (db_clip - floor) / (top - floor);
    u = u.pow(gamma);
    ("UI -> " ++ u.round(0.003) ++ " for " ++ db ++ " dBFS RMS").postln;
    u
};

~hud_print = {
    ("HUD: top=" ++ ~hud_topDb ++ " dB, floor=" ++ ~hud_floorDb ++ " dB, gamma=" ++ ~hud_gamma).postln;
};

// --- Locate meters in the existing window ---
find_window_by_name = { |name| Window.allWindows.detect({ |w| w.name == name }) };

find_level_by_pane_label = { |root_view, pane_label|
    var found_static, result, search_static, search_under_parent;
    found_static = nil; result = nil;

    search_static = { |view|
        var i, n, child;
        i = 0; n = view.children.size;
        while({ i < n }, {
            child = view.children[i];
            if(child.isKindOf(StaticText) and: { child.string == pane_label }) {
                found_static = child;
            }{
                search_static.(child);
            };
            i = i + 1;
        });
    };

    search_under_parent = { |view|
        var i, n, child;
        i = 0; n = view.children.size;
        while({ i < n }, {
            child = view.children[i];
            if(child.isKindOf(LevelIndicator)) {
                if(result.isNil) { result = child };
            }{
                search_under_parent.(child);
            };
            i = i + 1;
        });
    };

    search_static.(root_view);
    if(found_static.notNil and: { found_static.parent.notNil }) {
        search_under_parent.(found_static.parent);
    };
    result
};

// Bind window + meters
win = find_window_by_name.("Layout Test");
if(win.isNil) {
    "Layout Test window not found. Open the window script first.".postln;
}{
    root = win.view;
    meter_left  = find_level_by_pane_label.(root, "Top Left Pane");
    meter_right = find_level_by_pane_label.(root, "Top Right Pane");
};

// --- Rebind only GUI OSCdefs to insert mapping ---
value_from_msg = { |msg|
    var v, sz;
    v = 0.0;
    if(msg.notNil) {
        sz = msg.size;
        if(sz >= 4) { v = msg[sz - 1].asFloat };
    };
    v.clip(0.0, 1.0)
};

install_mapped_gui = {
    var a, b;
    a = OSCdef(\rmsA_toGUI); if(a.notNil) { a.free };
    b = OSCdef(\rmsB_toGUI); if(b.notNil) { b.free };

    OSCdef(\rmsA_toGUI, { |msg|
        var v, ui;
        v = value_from_msg.(msg);
        ui = ~hud_map_linear_to_ui.(v);
        { meter_left.value_(ui) }.defer;
    }, '/peakrmsA');

    OSCdef(\rmsB_toGUI, { |msg|
        var v, ui;
        v = value_from_msg.(msg);
        ui = ~hud_map_linear_to_ui.(v);
        { meter_right.value_(ui) }.defer;
    }, '/peakrmsB');

    ("Mapped meter responders installed (top=" ++ ~hud_topDb
        ++ " dB, floor=" ++ ~hud_floorDb ++ " dB, gamma=" ++ ~hud_gamma ++ ").").postln;
};

if(meter_left.notNil and: { meter_right.notNil }) {
    install_mapped_gui.();
}{ "Meter calibration patch not installed (meters not bound).".postln };

~hud_print.();
)
