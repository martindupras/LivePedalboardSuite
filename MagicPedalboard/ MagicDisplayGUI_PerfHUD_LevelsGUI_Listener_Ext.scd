// MagicDisplayGUI_PerfHUD_LevelsGUI_Listener_Ext.scd
// v0.1.0
// MD 2025-09-26 16:10 BST

/* Purpose
   Listen to /md/levels_gui (GA=32001, GB=32002), fill ~md_gui_levelsById,
   and provide a tiny overlay + helpers that read from that dict.
   Style: var-first; descriptive lowercase; AppClock-only; no server.sync.
*/

(
~md_gui_levelsById  = ~md_gui_levelsById  ? IdentityDictionary.new;
~md_gui_lastStamp   = ~md_gui_lastStamp   ? SystemClock.seconds.asFloat;

~md_installGuiLevelsListener = {
    var key, existing;
    key = \md_levels_gui_listener;

    existing = OSCdef.all.at(key);
    if(existing.notNil) { existing.free };

    OSCdef(key, { arg msg;
        var replyId, l, r, safeL, safeR, now;
        if(msg.size < 5) { ^nil };
        replyId = msg[2];
        l = msg[3].asFloat; r = msg[4].asFloat;
        safeL = l.isFinite.if({ l.clip(0, 1) }, { 0.0 });
        safeR = r.isFinite.if({ r.clip(0, 1) }, { 0.0 });
        ~md_gui_levelsById.put(replyId, [safeL, safeR]);
        now = SystemClock.seconds.asFloat;
        ~md_gui_lastStamp = now;
        nil
    }, "/md/levels_gui", recvPort: NetAddr.langPort);

    "[HUD] /md/levels_gui listener installed (key=md_levels_gui_listener)".postln;
    nil
};

~md_attachGuiOverlayMeters = {
    var hudWindow, overlayView, barWidth, pad, height, refreshRoutine;

    // robust window search
    hudWindow = Window.allWindows.detect({ arg w;
        var n = w.tryPerform(\name);
        n.notNil and: { n.asString.contains("MagicDisplayGUI") or: { n.asString.contains("PerfHUD") } }
    });
    if(hudWindow.isNil) { "⚠️ No MagicDisplayGUI/PerfHUD window found.".warn; ^nil };

    pad = 8; barWidth = 12; height = 84;
    overlayView = UserView(hudWindow, Rect(pad, pad, barWidth, height));
    overlayView.background_(Color.clear);

    overlayView.drawFunc_({ arg v;
        var aPair, bPair, aL, aR, bL, bR, h, halfW;
        aPair = ~md_gui_levelsById.at(32001) ? [0, 0];
        bPair = ~md_gui_levelsById.at(32002) ? [0, 0];

        aL = aPair[0]; aR = aPair[1];
        bL = bPair[0]; bR = bPair[1];

        h = v.bounds.height; halfW = v.bounds.width/2;

        // A bottom half
        Pen.fillColor = Color(0.35, 0.9, 0.35);
        Pen.addRect(Rect(0, h/2 - (h/2 * aL), halfW, (h/2 * aL))); Pen.fill;
        Pen.fillColor = Color(0.35, 0.6, 0.95);
        Pen.addRect(Rect(halfW, h/2 - (h/2 * aR), halfW, (h/2 * aR))); Pen.fill;

        // B top half
        Pen.fillColor = Color(0.35, 0.9, 0.35).blend(Color.white, 0.15);
        Pen.addRect(Rect(0, h - (h/2 * bL), halfW, (h/2 * bL))); Pen.fill;
        Pen.fillColor = Color(0.35, 0.6, 0.95).blend(Color.white, 0.15);
        Pen.addRect(Rect(halfW, h - (h/2 * bR), halfW, (h/2 * bR))); Pen.fill;
    });

    refreshRoutine = Routine({
        var keepRunning;
        keepRunning = true;
        while({ keepRunning and: { hudWindow.notNil and: { hudWindow.isClosed.not } } }, {
            overlayView.refresh;
            0.15.wait;
        });
    }).play(AppClock);

    "[HUD] overlay meters (GUI) attached (top-left)".postln;
    overlayView  // return view
};

~md_currentChain = ~md_currentChain ? \A;
~md_attachActiveOverlay = {  // reuse name, returns a UserView
    var hudWindow, overlayView, barHeight, refreshRoutine;
    hudWindow = Window.allWindows.detect({ arg w;
        var n = w.tryPerform(\name);
        n.notNil and: { n.asString.contains("MagicDisplayGUI") or: { n.asString.contains("PerfHUD") } }
    });
    if(hudWindow.isNil) { "⚠️ No MagicDisplayGUI/PerfHUD window found.".warn; ^nil };

    barHeight = 8;
    overlayView = UserView(hudWindow, Rect(0, 0, hudWindow.bounds.width, barHeight));
    overlayView.background_(Color.clear);

    overlayView.drawFunc_({ arg v;
        var isA, color;
        isA = (~md_currentChain ? \A) == \A;
        color = isA.if({ Color(0.18, 0.8, 0.18) }, { Color(0.18, 0.45, 0.95) });
        Pen.fillColor = color; Pen.addRect(Rect(0, 0, v.bounds.width, v.bounds.height)); Pen.fill;
    });

    refreshRoutine = Routine({
        var keepRunning;
        keepRunning = true;
        while({ keepRunning and: { hudWindow.notNil and: { hudWindow.isClosed.not } } }, {
            overlayView.bounds = Rect(0, 0, hudWindow.bounds.width, barHeight);
            overlayView.refresh;
            0.20.wait;
        });
    }).play(AppClock);

    "[HUD] active overlay attached (top bar)".postln;
    overlayView
};
)
