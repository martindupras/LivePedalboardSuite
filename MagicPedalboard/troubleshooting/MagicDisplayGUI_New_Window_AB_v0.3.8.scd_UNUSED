// MagicDisplayGUI_New_Window_AB_v0.3.8.scd
// v0.3.8
// MD 2025-09-25 15:10 BST

/*
Purpose
- Create one window titled "MagicDisplayGUI ..." with 4 horizontal bars:
  A-L, A-R (replyID 2001); B-L, B-R (replyID 2002).
- HUD at top-left; AppClock ticker ~30 Hz; fallback to test (1001) if A/B absent.
- Enforce single-window policy (close any existing MagicDisplayGUI* windows).
Style
- var-first; AppClock only; fixed rects (no FlowLayout); no non-local returns.
- Final expression returns -> a Window.
*/

(
// === RUN ===
var closeExistingMagicDisplayWindows, ensureReceiver, w, rect, pad, barH, labelW, meterW, meterH, lineGap, makeBars;
var aL=0.0, aR=0.0, bL=0.0, bR=0.0, tL=0.0, tR=0.0;
var hud, lblAL, lblAR, lblBL, lblBR, viewAL, viewAR, viewBL, viewBR;
var ticker, makeTicker, killTicker, readLevels, fps, ids, dict;

fps = 30;
ids = (test: 1001, A: 2001, B: 2002);
dict = { ~md_levelsById ? IdentityDictionary.new }!(); // tolerate cold start

closeExistingMagicDisplayWindows = {
    var wins;
    wins = Window.allWindows.select({ arg wi;
        var nm;
        nm = wi.tryPerform(\name);
        nm.notNil and: { nm.asString.beginsWith("MagicDisplayGUI") }
    });
    AppClock.sched(0.0, { wins.do({ arg wi; wi.close }); nil });
};

ensureReceiver = {
    var have;
    have = (OSCdef(\md_levels) !? { true }) ? false; // just to probe
    ~md_reinstallReceiver !? { ~md_reinstallReceiver.() } // idempotent
};

// layout constants
pad    = 10;
labelW = 72;
meterW = 340;
lineGap= 10;
barH   = 14;
meterH = barH;

closeExistingMagicDisplayWindows.value;
ensureReceiver.value;

rect = Rect(60, 60, pad + labelW + 8 + meterW + pad, pad + 24 + (4*(barH+lineGap)) + pad);
w = Window("MagicDisplayGUI — A/B Meters (v0.3.8)", rect, false, false);
w.alwaysOnTop_(false);

w.drawFunc = { }; // no background drawing; keep it simple

// HUD
hud = StaticText(w, Rect(pad, pad, meterW + labelW, 20));
hud.stringColor = Color.black;
hud.string = "HUD: waiting for levels…";

// Row helpers
lblAL = StaticText(w, Rect(pad,           pad+30 + (0*(barH+lineGap)), labelW, barH)); lblAL.string = "A-L";
lblAR = StaticText(w, Rect(pad,           pad+30 + (1*(barH+lineGap)), labelW, barH)); lblAR.string = "A-R";
lblBL = StaticText(w, Rect(pad,           pad+30 + (2*(barH+lineGap)), labelW, barH)); lblBL.string = "B-L";
lblBR = StaticText(w, Rect(pad,           pad+30 + (3*(barH+lineGap)), labelW, barH)); lblBR.string = "B-R";

makeBars = { arg left, top;
    var v;
    v = UserView(w, Rect(left, top, meterW, meterH)).background_(Color(0.92,0.92,0.92));
    v.drawFunc = { arg uv;
        var b, vNorm;
        b = uv.bounds;
        // caller sets a closure to draw current level (0..1)
        vNorm = uv.userCanDraw.value(uv);
        Pen.color = Color.gray(0.85);
        Pen.addRect(Rect(0, 0, b.width, b.height)); Pen.fill;
        Pen.color = Color(0.20, 0.70, 0.20);
        Pen.addRect(Rect(0, 0, b.width * vNorm.clip(0,1), b.height)); Pen.fill;
        Pen.color = Color.gray(0.55);
        Pen.strokeRect(Rect(0.5, 0.5, b.width-1, b.height-1));
    };
    v
};

viewAL = makeBars.value(pad + labelW + 8, pad+30 + (0*(barH+lineGap)));
viewAR = makeBars.value(pad + labelW + 8, pad+30 + (1*(barH+lineGap)));
viewBL = makeBars.value(pad + labelW + 8, pad+30 + (2*(barH+lineGap)));
viewBR = makeBars.value(pad + labelW + 8, pad+30 + (3*(barH+lineGap)));

viewAL.userCanDraw = { arg v; aL };
viewAR.userCanDraw = { arg v; aR };
viewBL.userCanDraw = { arg v; bL };
viewBR.userCanDraw = { arg v; bR };

// read levels (with fallback to test=1001 if A/B missing)
readLevels = {
    var a, b, t, txt;
    dict = (~md_levelsById ? dict);
    a = dict[ids[\A]] ? [0.0, 0.0];
    b = dict[ids[\B]] ? [0.0, 0.0];
    t = dict[ids[\test]] ? [0.0, 0.0];

    // update 4 numbers
    aL = a[0]; aR = a[1];
    bL = b[0]; bR = b[1];

    // HUD line
    txt = "A[" ++ aL.round(0.01) ++ "," ++ aR.round(0.01) ++ "]  " ++
          "B[" ++ bL.round(0.01) ++ "," ++ bR.round(0.01) ++ "]";
    // Fallback annotate if both A/B are zeros but test moves
    if((aL+aR+bL+bR) <= 0.0001 && (t[0]+t[1]) > 0.0, {
        txt = txt ++ "  (fallback: test " ++ t.collect(_.round(0.01)) ++ ")";
    });
    hud.string = "HUD: " ++ txt;
};

makeTicker = {
    var period, go;
    period = 1.0 / fps;
    go = {
        readLevels.value;
        viewAL.refresh; viewAR.refresh; viewBL.refresh; viewBR.refresh;
        AppClock.sched(period, { ticker !? { go.value } });
        nil
    };
    ticker = true;
    AppClock.sched(0.0, { go.value; nil });
};

killTicker = {
    ticker = nil;
};

// clean close
w.onClose_({
    killTicker.value;
});

// run
w.front;
makeTicker.value;
w
) // -> a Window
