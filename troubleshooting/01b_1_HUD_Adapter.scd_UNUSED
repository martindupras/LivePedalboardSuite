// 01b_1_HUD_Adapter.scd
// v0.1.0
// MD 2025-09-29 13:05

/* Purpose
   - Provide a stable HUD API regardless of which GUI is up:
        ~hud_highlightCurrent.(\chainA | \chainB)
        ~hud_showExpectation.("text", seconds=0)
        ~hud_setOperations.(["line1", "line2", ...])
   - If GridDemo is up, forward to its native methods.
   - If PerfHUD is up (meters!), create lightweight overlays on top of the window:
       • a solid A/B highlight (masks the pulsing)
       • a small text panel for status + choices
Style
   - var-first; AppClock for UI; no server.sync; nil-safe; idempotent.
*/

(
var findHudWindow, isGridDemo, adoptGridDemo, adoptPerfHUD, ensureOverlayBag;
var mkOrGetView, setSolidHighlight, setStatusText, setChoicesText;

findHudWindow = {
    Window.allWindows.detect { |w|
        (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI")
    }
};

isGridDemo = {
    // If ~gui is a GridDemo controller, prefer it
    (~gui.notNil)
    and: { ~gui.class.asString == "MagicDisplayGUI_GridDemo" }
    and: { ~gui.respondsTo(\highlightCurrentColumn) }
};

// ---- GridDemo path: forwarders to class methods -----------------------------
adoptGridDemo = {
    ~hud_highlightCurrent = { |which|
        AppClock.sched(0.0, {
            ~gui.highlightCurrentColumn(which);
            nil
        })
    };
    ~hud_showExpectation = { |text, secs = 0|
        AppClock.sched(0.0, {
            if(~gui.respondsTo(\showExpectation)) { ~gui.showExpectation(text, secs ? 0) };
            nil
        })
    };
    ~hud_setOperations = { |lines|
        AppClock.sched(0.0, {
            if(~gui.respondsTo(\setOperations)) { ~gui.setOperations(lines ? []) };
            nil
        })
    };
    "HUD adapter: GridDemo forwarders installed.".postln;
};

// ---- PerfHUD path: overlays on top of the window ----------------------------
ensureOverlayBag = { |win|
    var dict;
    dict = Library.at(\HUD_Overlay, win.identityHash);
    if(dict.isNil) {
        dict = IdentityDictionary.new;
        Library.put(\HUD_Overlay, win.identityHash, dict);
    };
    dict
};

mkOrGetView = { |win, key, makeFunc|
    var bag, v;
    bag = ensureOverlayBag.(win);
    v = bag[key];
    if(v.isNil or: { v.wasRemoved ? false }) {
        v = makeFunc.value(win.view);
        bag[key] = v;
    };
    v
};

setSolidHighlight = { |win, which|
    var host, w, h, half, rect, color, key;
    host = win.view;
    w = host.bounds.width; h = host.bounds.height;
    half = (w * 0.5).round(1);
    rect = (which == \chainA)
        .if({ Rect(0, 0, half, h) }, { Rect(half, 0, w - half, h) });
    color = Color(0.85, 1.0, 0.85, 0.90);   // same tint as GridDemo "active"
    key = \highlightView;

    mkOrGetView.(win, key, { |parent|
        var v = CompositeView(parent);
        v.background = color;
        v
    }).bounds = rect;
    mkOrGetView.(win, key, { |parent| CompositeView(parent) }).background = color;
    mkOrGetView.(win, key, { |parent| CompositeView(parent) }).front;
};

setStatusText = { |win, string|
    var host, rect, key;
    host = win.view;
    rect = Rect(8, 6, (host.bounds.width - 16).max(120), 22);
    key = \statusText;

    mkOrGetView.(win, key, { |parent|
        var tv = StaticText(parent);
        tv.stringColor = Color.black;
        tv.background = Color(1, 1, 0.6, 0.8);
        tv.align = \left;
        tv
    }).bounds = rect;

    mkOrGetView.(win, key, { |parent| StaticText(parent) }).string = string.asString;
    mkOrGetView.(win, key, { |parent| StaticText(parent) }).front;
};

setChoicesText = { |win, lines|
    var host, x, y, w, h, key, text;
    host = win.view;
    x = (host.bounds.width - 360).clip(8, host.bounds.width - 120);
    y = 40;
    w = 352;
    h = 220;
    text = (lines ? []).collect(_.asString).join("\n");
    key = \choicesText;

    mkOrGetView.(win, key, { |parent|
        var box = TextView(parent);
        box.string = text.size > 0.if({ text }, { "—" });
        box.background = Color(0.95, 0.98, 1.0, 0.85);
        box.editable = false;
        box.hasVerticalScroller = true;
        box
    }).bounds = Rect(x, y, w, h);

    mkOrGetView.(win, key, { |parent| TextView(parent) }).string = text.size > 0.if({ text }, { "—" });
    mkOrGetView.(win, key, { |parent| TextView(parent) }).front;
};

adoptPerfHUD = {
    var win;
    win = findHudWindow.();
    if(win.isNil) {
        "HUD adapter: no MagicDisplayGUI window found (PerfHUD expected).".warn;
        ^nil
    };

    ~hud_highlightCurrent = { |which|
        AppClock.sched(0.0, {
            setSolidHighlight.(win, which);
            nil
        })
    };
    ~hud_showExpectation = { |text, secs = 0|
        AppClock.sched(0.0, {
            setStatusText.(win, text.asString);
            nil
        })
    };
    ~hud_setOperations = { |lines|
        AppClock.sched(0.0, {
            setChoicesText.(win, lines ? []);
            nil
        })
    };
    "HUD adapter: PerfHUD overlays installed (solid A/B, status, choices).".postln;
};

// ---- Install adapter ---------------------------------------------------------
AppClock.sched(0.00, {
    var win;
    win = findHudWindow.();

    // Prefer GridDemo if controller is present and methods exist
    if(isGridDemo.()) {
        adoptGridDemo.();
    }{
        // Otherwise, adopt PerfHUD (overlays) if its window exists
        if(win.notNil) {
            adoptPerfHUD.();
        }{
            "HUD adapter: no GUI found yet; will try again shortly.".warn;
            AppClock.sched(0.10, {
                var win2 = findHudWindow.();
                if(isGridDemo.()) { adoptGridDemo.() } { if(win2.notNil) { adoptPerfHUD.() } };
                nil
            });
        };
    };
    nil
});
)
