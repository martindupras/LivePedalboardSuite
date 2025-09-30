// 98_PerfHUD_Triage_UIOnly.scd
// v0.1.0
// MD 2025-09-29 15:30 BST

/* Purpose
 - ZERO-OSC triage: prove we can paint + animate inside the PerfHUD window.
 - Draws a top RED banner, two wide bars near bottom; animates bars via AppClock.
 - Helpers:
     ~ui_wiggle_start.(\A or \B)   // start animation, tint active half
     ~ui_wiggle_stop.()            // stop + remove our overlays
Style
 - var-first; AppClock-only; idempotent; no server.sync; known-good SC API only.
*/

(
var findHudWin, findHost, debugPrintWindows, removeOverlays, makeBanner, makeBars, makeTint, startAnim, stopAnim;

// 0) enumerate windows for sanity
debugPrintWindows = {
    var names;
    names = Window.allWindows.collect({ |w| w.tryPerform(\name) ? "<unnamed>" });
    ("[triage] Windows: " ++ names).postln;
};

// 1) find the MagicDisplayGUI window and its host view
findHudWin = {
    var win;
    win = Window.allWindows.detect({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") });
    win
};

findHost = {
    var win, host, r;
    win = findHudWin.();
    if(win.isNil) { "[triage] MagicDisplayGUI window not found.".warn; ^nil };
    host = win.tryPerform(\view);
    r = host.tryPerform(\bounds);
    ("[triage] Host bounds: " ++ (r ? "<nil>")).postln;
    host
};

// 2) remove our overlays if present
removeOverlays = {
    var host;
    host = findHost.();
    if(host.notNil) {
        host.children.select({ |v|
            var n = v.tryPerform(\name) ? "";
            ["TRI_BANNER","TRI_BAR_A","TRI_BAR_B","TRI_TINT_A","TRI_TINT_B"].includes(n)
        }).do(_.remove);
    };
    if(~tri_task.notNil) { ~tri_task.stop; ~tri_task = nil };
    ~tri_valA = 0.0;
    ~tri_valB = 0.0;
};

// 3) big red banner at top (instant visual proof)
makeBanner = {
    var host, r, banner;
    host = findHost.(); if(host.isNil) { ^nil };
    r = host.bounds;
    banner = UserView(host);
    banner.name = "TRI_BANNER";
    banner.bounds = Rect(0, 0, r.width, 18);
    banner.background = Color(1.0, 0.2, 0.2, 0.75); // red translucent
    banner.front;
    host.window.onResize = {
        var r2 = host.bounds;
        banner.bounds = Rect(0, 0, r2.width, 18);
        banner.refresh;
    };
    "[triage] Banner shown (top).".postln;
};

// 4) two wide bars near bottom (A green, B blue)
makeBars = {
    var host, r, pad, h, gap, w, yA, yB, barA, barB;
    host = findHost.(); if(host.isNil) { ^nil };
    r = host.bounds; pad = 12; h = 16; gap = 10;
    w = (r.width - (2*pad)).max(50);
    yB = (r.height - pad - h).max(30);
    yA = (yB - h - gap).max(10);

    barA = UserView(host);
    barA.name = "TRI_BAR_A";
    barA.bounds = Rect(pad, yA, w, h);
    barA.background = Color(0,0,0,0.12);
    barA.drawFunc = { |uv|
        var wpx, v;
        wpx = uv.bounds.width;
        v = (~tri_valA ? 0.0).clip(0,1);
        Pen.fillColor = Color(0.20, 0.85, 0.35, 0.95);
        Pen.fillRect(Rect(0, 0, (wpx * v).max(1), h));
    };
    barA.front;

    barB = UserView(host);
    barB.name = "TRI_BAR_B";
    barB.bounds = Rect(pad, yB, w, h);
    barB.background = Color(0,0,0,0.12);
    barB.drawFunc = { |uv|
        var wpx, v;
        wpx = uv.bounds.width;
        v = (~tri_valB ? 0.0).clip(0,1);
        Pen.fillColor = Color(0.20, 0.55, 0.95, 0.95);
        Pen.fillRect(Rect(0, 0, (wpx * v).max(1), h));
    };
    barB.front;

    host.window.onResize = {
        var r2, w2, yA2, yB2;
        r2 = host.bounds;
        w2 = (r2.width - (2*pad)).max(50);
        yB2 = (r2.height - pad - h).max(30);
        yA2 = (yB2 - h - gap).max(10);
        barA.bounds = Rect(pad, yA2, w2, h);
        barB.bounds = Rect(pad, yB2, w2, h);
        barA.refresh; barB.refresh;
    };
    "[triage] Bars created (bottom).".postln;
};

// 5) translucent tint on left or right half to mark ACTIVE
makeTint = { arg which = \A;
    var host, r, midX, tintA, tintB;
    host = findHost.(); if(host.isNil) { ^nil };
    r = host.bounds; midX = r.width * 0.5;

    // clear old
    host.children.select({ |v|
        var n = v.tryPerform(\name) ? "";
        ["TRI_TINT_A","TRI_TINT_B"].includes(n)
    }).do(_.remove);

    tintA = UserView(host);
    tintA.name = "TRI_TINT_A";
    tintA.bounds = Rect(0, 0, midX, r.height);
    tintA.background = Color(0.85, 1.0, 0.85, 0.18);

    tintB = UserView(host);
    tintB.name = "TRI_TINT_B";
    tintB.bounds = Rect(midX, 0, r.width - midX, r.height);
    tintB.background = Color(0.85, 1.0, 0.85, 0.18);

    tintA.visible = (which == \A);
    tintB.visible = (which == \B);
    tintA.front; tintB.front;

    host.window.onResize = {
        var r2 = host.bounds, mx = r2.width * 0.5;
        tintA.bounds = Rect(0, 0, mx, r2.height);
        tintB.bounds = Rect(mx, 0, r2.width - mx, r2.height);
        tintA.refresh; tintB.refresh;
    };
    ("[triage] Active tint → " ++ which.asString).postln;
};

// 6) animation (triangle wave) — no OSC, UI-only
startAnim = { arg which = \A;
    var host, dt, t;
    host = findHost.(); if(host.isNil) { ^nil };

    removeOverlays.();
    makeBanner.();
    makeBars.();
    makeTint.(which);

    dt = 1/30; t = 0.0;
    ~tri_task = Task({
        loop {
            var a = (t % 1.0);   // 0..1 triangle
            var b = 1.0 - a;
            ~tri_valA = a;
            ~tri_valB = b;
            // refresh our bars only
            host.children.do({ |v|
                var n = v.tryPerform(\name) ? "";
                if((n == "TRI_BAR_A") or: { n == "TRI_BAR_B" }) { v.refresh };
            });
            dt.wait;
            t = t + (dt * 0.6);
        }
    }).play(AppClock);

    "[triage] UI-only animation started.".postln;
};

stopAnim = {
    removeOverlays.();
    "[triage] UI-only animation stopped.".postln;
};

// Export helpers
~ui_wiggle_start = { arg which = \A; AppClock.sched(0.0, { debugPrintWindows.value; startAnim.(which); nil }) };
~ui_wiggle_stop  = { AppClock.sched(0.0, { stopAnim.(); nil }) };

"[triage] Ready: use ~ui_wiggle_start.(\\A) / ~ui_wiggle_stop.()".postln;
)
