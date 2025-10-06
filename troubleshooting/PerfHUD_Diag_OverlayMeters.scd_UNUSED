// PerfHUD_Diag_OverlayMeters.scd
// v0.1.0
// MD 2025-09-26 13:12 BST

/* Purpose
   - Prove the meter data path & UI repaint with a non-intrusive overlay.
   - Installs a /md/levels receiver -> ~md_levelsById.
   - Adds a tiny overlay UserView that animates A/B bars (top-left).
   - Very light diagnostics: heartbeat every ~2 seconds.
*/

(
var ensureModel, installReceiver, findHudWindow, attachOverlay, startRefresh;
var hudWindow, overlayView, refreshRoutine, lastBeatTime;

ensureModel = {
    ~md_levelsById = ~md_levelsById ? IdentityDictionary.new;
    ~md_lastMsgStamp = ~md_lastMsgStamp ? SystemClock.seconds.asFloat;
    nil
};

installReceiver = {
    var existing;
    existing = OSCdef.all.at(\md_levels_diag);
    if(existing.notNil) { existing.free };
    OSCdef(\md_levels_diag, { arg msg, time, addr, recvPort;
        var replyId, leftVal, rightVal;
        if(msg.size < 5) { ^nil };
        replyId = msg[2];
        leftVal  = msg[3].asFloat.clip(0, 1);
        rightVal = msg[4].asFloat.clip(0, 1);
        ~md_levelsById.put(replyId, [leftVal, rightVal]);
        ~md_lastMsgStamp = SystemClock.seconds.asFloat;
        nil
    }, "/md/levels", recvPort: NetAddr.langPort);
    "[Diag] /md/levels receiver installed (key=md_levels_diag)".postln;
};

findHudWindow = {
    Window.allWindows.detect({ arg w;
        var nameString;
        nameString = w.tryPerform(\name);
        nameString.notNil and: { nameString.asString.beginsWith("MagicDisplayGUI") }
    })
};

attachOverlay = { arg windowRef;
    var pad, width, height;
    pad = 8; width = 12; height = 80;
    overlayView = UserView(windowRef, Rect(pad, pad, width, height));
    overlayView.background_(Color.clear);
    overlayView.drawFunc_({ arg v;
        var aPair, bPair, aL, aR, bL, bR, h, halfW;
        var aEnergy, bEnergy, leftColor, rightColor;
        aPair = (~md_levelsById.at(2001) ? [0, 0]).collect(_.asFloat);
        bPair = (~md_levelsById.at(2002) ? [0, 0]).collect(_.asFloat);
        aL = aPair[0].clip(0, 1); aR = aPair[1].clip(0, 1);
        bL = bPair[0].clip(0, 1); bR = bPair[1].clip(0, 1);
        h = v.bounds.height; halfW = v.bounds.width/2;

        // A on bottom half, B on top half (thin overlay)
        leftColor  = Color(0.35, 0.9, 0.35);
        rightColor = Color(0.35, 0.6, 0.95);

        // A bars (bottom half)
        Pen.fillColor = leftColor;
        Pen.addRect(Rect(0, h/2 - (h/2 * aL), halfW, (h/2 * aL))); Pen.fill;
        Pen.fillColor = rightColor;
        Pen.addRect(Rect(halfW, h/2 - (h/2 * aR), halfW, (h/2 * aR))); Pen.fill;

        // B bars (top half)
        Pen.fillColor = leftColor.blend(Color.white, 0.15);
        Pen.addRect(Rect(0, h - (h/2 * bL), halfW, (h/2 * bL))); Pen.fill;
        Pen.fillColor = rightColor.blend(Color.white, 0.15);
        Pen.addRect(Rect(halfW, h - (h/2 * bR), halfW, (h/2 * bR))); Pen.fill;
    });
    overlayView.visible = true;
    "[Diag] overlay meters attached (top-left)".postln;
};

startRefresh = {
    var beatInterval;
    beatInterval = 0.15;
    lastBeatTime = SystemClock.seconds.asFloat;

    refreshRoutine = Routine({
        var keepRunning, now;
        keepRunning = true;
        while({ keepRunning and: { hudWindow.notNil and: { hudWindow.isClosed.not } } }, {
            overlayView.refresh;
            now = SystemClock.seconds.asFloat;
            if((now - lastBeatTime) >= 2.0) {
                ("[Diag] meters tick; last /md/levels " ++ (now - (~md_lastMsgStamp ? now)).round(0.01) ++ " s").postln;
                lastBeatTime = now;
            };
            beatInterval.wait;
        });
    }).play(AppClock);
};

// bring it together
ensureModel.();
installReceiver.();
hudWindow = findHudWindow.();
if(hudWindow.notNil) {
    attachOverlay.(hudWindow);
    startRefresh.();
} {
    "⚠️ No MagicDisplayGUI window found; run the HUD first.".warn;
};
)
