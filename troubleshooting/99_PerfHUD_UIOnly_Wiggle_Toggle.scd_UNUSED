// 99_PerfHUD_UIOnly_Wiggle_Toggle.scd
// v0.1.0
// MD 2025-09-29 15:22 BST

/* Purpose
 - Pure GUI-side diagnostic: animate two meter bars (A/B) inside the PerfHUD window
   WITHOUT OSC, to prove the window can update; also tint ACTIVE column and show test text.
 - Provides helpers:
     ~hud_wiggle_start.(\A or \B)   // start animation, choose active column
     ~hud_wiggle_stop.()            // stop & remove overlays
     ~hud_text.("state text", ["choice1", "choice2"])  // show sample texts
Style
 - var-first; AppClock-only; idempotent; nil-safe; no server.sync; no caret-returns in closures.
*/

(
var findHudHost, removeOverlays, mkBars, mkTint, mkText, startAnim, stopAnim;

// --- find the MagicDisplayGUI host view (PerfHUD window) ---
findHudHost = {
    var win, host;
    win = Window.allWindows.detect({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") });
    host = win.tryPerform(\view);
    ^host
};

// --- remove our overlays if present (safe to call anytime) ---
removeOverlays = {
    var host = findHudHost.();
    if(host.notNil) {
        host.children.select({ |v|
            var n = v.tryPerform(\name) ? "";
            ["WGL_BAR_A", "WGL_BAR_B", "WGL_TINT_A", "WGL_TINT_B", "WGL_TEXT"].includes(n)
        }).do(_.remove);
    };
    if(~wgl_task.notNil) { ~wgl_task.stop; ~wgl_task = nil };
};

// --- create two bars near the bottom of the window ---
mkBars = {
    var host, r, pad, h, gap, w, yA, yB, barA, barB;

    host = findHudHost.(); if(host.isNil) { "wiggle: HUD host not found.".warn; ^nil };
    r = host.bounds; pad = 12; h = 14; gap = 8; w = (r.width - (2*pad)).max(50);
    yB = (r.height - pad - h).max(10);
    yA = (yB - h - gap).max(10);

    // A
    barA = UserView(host);
    barA.name = "WGL_BAR_A";
    barA.bounds = Rect(pad, yA, w, h);
    barA.background = Color(0,0,0,0.10);
    barA.drawFunc = { |uv|
        var wpx = uv.bounds.width, v = (~wgl_valA ? 0.0).clip(0,1);
        Pen.fillColor = Color(0.20, 0.85, 0.35, 0.95);
        Pen.fillRect(Rect(0, 0, (wpx * v).max(1), h));
    };
    barA.front;

    // B
    barB = UserView(host);
    barB.name = "WGL_BAR_B";
    barB.bounds = Rect(pad, yB, w, h);
    barB.background = Color(0,0,0,0.10);
    barB.drawFunc = { |uv|
        var wpx = uv.bounds.width, v = (~wgl_valB ? 0.0).clip(0,1);
        Pen.fillColor = Color(0.20, 0.55, 0.95, 0.95);
        Pen.fillRect(Rect(0, 0, (wpx * v).max(1), h));
    };
    barB.front;

    // keep re-anchored on resize
    host.window.onResize = {
        var r2 = host.bounds;
        var w2 = (r2.width - (2*pad)).max(50);
        var yB2 = (r2.height - pad - h).max(10);
        var yA2 = (yB2 - h - gap).max(10);
        barA.bounds = Rect(pad, yA2, w2, h);
        barB.bounds = Rect(pad, yB2, w2, h);
        barA.refresh; barB.refresh;
    };
};

// --- tint ACTIVE column (large translucent rect on left or right half) ---
mkTint = { arg which = \A;
    var host, r, leftRect, rightRect, tintA, tintB, midX;

    host = findHudHost.(); if(host.isNil) { ^nil };
    r = host.bounds; midX = r.width * 0.5;

    // clear old tints
    host.children.select({ |v| ["WGL_TINT_A","WGL_TINT_B"].includes(v.tryPerform(\name) ? "") }).do(_.remove);

    tintA = UserView(host); tintA.name = "WGL_TINT_A";
    tintA.bounds = Rect(0, 0, midX, r.height);
    tintA.background = Color(0.85, 1.0, 0.85, 0.18); // soft green

    tintB = UserView(host); tintB.name = "WGL_TINT_B";
    tintB.bounds = Rect(midX, 0, r.width - midX, r.height);
    tintB.background = Color(0.85, 1.0, 0.85, 0.18);

    // show only the chosen one
    tintA.visible = (which == \A);
    tintB.visible = (which == \B);
    tintA.front; tintB.front;

    // keep on resize
    host.window.onResize = {
        var r2 = host.bounds, mx2 = r2.width * 0.5;
        tintA.bounds = Rect(0, 0, mx2, r2.height);
        tintB.bounds = Rect(mx2, 0, r2.width - mx2, r2.height);
        tintA.refresh; tintB.refresh;
    };
};

// --- small text block (state + choices) in top-right as a demo ---
mkText = { arg stateStr = "HUD UI-test", choices = #["choice A","choice B"];
    var host, r, pad, w, h, title, body, panel, s;

    host = findHudHost.(); if(host.isNil) { ^nil };
    r = host.bounds; pad = 8; w = 280; h = 120;

    // clear previous
    host.children.select({ |v| (v.tryPerform(\name) ? "") == "WGL_TEXT" }).do(_.remove);

    panel = CompositeView(host).name_("WGL_TEXT");
    panel.background = Color(0,0,0,0.30);
    panel.bounds = Rect(r.width - (w + 12), 12, w, h);
    panel.front;

    title = StaticText(panel);
    title.string = stateStr.asString;
    title.font = Font("Monaco", 12);
    title.stringColor = Color(1,1,1,0.9);
    title.bounds = Rect(pad, pad, w - 2*pad, 18);

    s = choices.collect(_.asString).join("\n");
    body = StaticText(panel);
    body.string = (s.size > 0).if({ s }, { "—" });
    body.font = Font("Monaco", 10);
    body.stringColor = Color(0.95,0.95,0.95);
    body.align = \topLeft;
    body.bounds = Rect(pad, pad + 22, w - 2*pad, h - (pad + 22 + pad));

    // keep anchored
    host.window.onResize = {
        var r2 = host.bounds;
        panel.bounds = Rect(r2.width - (w + 12), 12, w, h);
        panel.front;
    };
};

// --- animation task (no OSC; just wiggle locally) ---
startAnim = { arg active = \A;
    var host, barA, barB, t = 0.0, dt = 1/30;

    host = findHudHost.(); if(host.isNil) { "wiggle: HUD not found".warn; ^nil };

    // build overlays
    mkBars.();
    mkTint.(active);

    // drive values
    if(~wgl_task.notNil) { ~wgl_task.stop; ~wgl_task = nil };
    ~wgl_task = Task({
        loop {
            // simple triangle → obvious motion
            var a = (t % 1.0);
            var b = 1.0 - a;
            ~wgl_valA = a;
            ~wgl_valB = b;
            // refresh our bars
            host.children.do({ |v|
                var n = v.tryPerform(\name) ? "";
                if(["WGL_BAR_A","WGL_BAR_B"].includes(n)) { v.refresh };
            });
            dt.wait;
            t = t + (dt * 0.5); // slow-ish
        }
    }).play(AppClock);
};

stopAnim = {
    removeOverlays.();
};

// export helpers
~hud_wiggle_start = { arg which = \A; AppClock.sched(0.0, { startAnim.(which); nil }) };
~hud_wiggle_stop  = { AppClock.sched(0.0, { stopAnim.(); nil }) };
~hud_text = { arg state="HUD UI-test", choices = #[]; AppClock.sched(0.0, { mkText.(state, choices); nil }) };

"PerfHUD UI-only wiggle helpers ready: ~hud_wiggle_start.(\\A or \\B), ~hud_wiggle_stop.(), ~hud_text.(state, choices)".postln;
)
