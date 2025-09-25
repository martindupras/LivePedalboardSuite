// MagicDisplayGUI_New_Window_AB_v0.3.9.scd
// v0.3.9
// MD 2025-09-25 15:34 BST

/*
Purpose
- Create one window titled "MagicDisplayGUI ..." with 4 horizontal bars:
  A-L, A-R (replyID 2001) and B-L, B-R (replyID 2002).
- HUD top-left; AppClock ticker ~30 Hz; fallback shows test(1001) hint if A/B are zero.
- Enforce single-window policy (close any existing MagicDisplayGUI* windows).

Style
- var-first in every block; descriptive lowercase names; AppClock only for GUI.
- Known-good SC syntax only; no custom slots on views; no server.sync.
- Final expression returns -> a Window.
*/

(
// === RUN ===
var closeExistingMagicDisplayWindows, ensureReceiver;
var w, rect, pad, barH, labelW, meterW, meterH, lineGap, makeBars;
var aL=0.0, aR=0.0, bL=0.0, bR=0.0, tL=0.0, tR=0.0;
var hud, lblAL, lblAR, lblBL, lblBR, viewAL, viewAR, viewBL, viewBR;
var ticker, makeTicker, killTicker, readLevels, fps, ids, dict;

fps = 30;
ids = (test: 1001, A: 2001, B: 2002);
dict = (~md_levelsById ? IdentityDictionary.new); // tolerate cold start

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
    var can;
    can = (~md_reinstallReceiver.notNil);
    if(can) { ~md_reinstallReceiver.() };
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
w = Window("MagicDisplayGUI — A/B Meters (v0.3.9)", rect, false, false);
w.alwaysOnTop_(false);

// HUD
hud = StaticText(w, Rect(pad, pad, meterW + labelW, 20));
hud.stringColor = Color.black;
hud.string = "HUD: waiting for levels…";

// row labels
lblAL = StaticText(w, Rect(pad,           pad+30 + (0*(barH+lineGap)), labelW, barH)); lblAL.string = "A-L";
lblAR = StaticText(w, Rect(pad,           pad+30 + (1*(barH+lineGap)), labelW, barH)); lblAR.string = "A-R";
lblBL = StaticText(w, Rect(pad,           pad+30 + (2*(barH+lineGap)), labelW, barH)); lblBL.string = "B-L";
lblBR = StaticText(w, Rect(pad,           pad+30 + (3*(barH+lineGap)), labelW, barH)); lblBR.string = "B-R";

// Meter factory: pass a getter closure that the drawFunc will capture
makeBars = { arg left, top, getLevelFunc;
    var uv;
    uv = UserView(w, Rect(left, top, meterW, meterH)).background_(Color(0.92,0.92,0.92));
    uv.drawFunc = { arg v;
        var b, vNorm;
        b = v.bounds;
        vNorm = getLevelFunc.value.clip(0, 1);
        Pen.color = Color.gray(0.85);
        Pen.addRect(Rect(0, 0, b.width, b.height)); Pen.fill;
        Pen.color = Color(0.20, 0.70, 0.20);
        Pen.addRect(Rect(0, 0, b.width * vNorm, b.height)); Pen.fill;
        Pen.color = Color.gray(0.55);
        Pen.strokeRect(Rect(0.5, 0.5, b.width-1, b.height-1));
    };
    uv
};

viewAL = makeBars.value(pad + labelW + 8, pad+30 + (0*(barH+lineGap)), { aL });
viewAR = makeBars.value(pad + labelW + 8, pad+30 + (1*(barH+lineGap)), { aR });
viewBL = makeBars.value(pad + labelW + 8, pad+30 + (2*(barH+lineGap)), { bL });
viewBR = makeBars.value(pad + labelW + 8, pad+30 + (3*(barH+lineGap)), { bR });

// read levels from shared dict (set by /md/levels receiver)
// fallback shows test=1001 if both A and B sum to ~0
readLevels = {
    var a, b, t, txt;
    dict = (~md_levelsById ? dict);
    a = dict[ids[\A]] ? [0.0, 0.0];
    b = dict[ids[\B]] ? [0.0, 0.0];
    t = dict[ids[\test]] ? [0.0, 0.0];

    aL = a[0]; aR = a[1];
    bL = b[0]; bR = b[1];
    tL = t[0]; tR = t[1];

    txt = "A[" ++ aL.round(0.01) ++ "," ++ aR.round(0.01) ++ "]  " ++
          "B[" ++ bL.round(0.01) ++ "," ++ bR.round(0.01) ++ "]";

    if(((aL+aR+bL+bR) <= 0.0001) and: { (tL+tR) > 0.0 }, {
        txt = txt ++ "  (fallback: test " ++ [tL.round(0.01), tR.round(0.01)] ++ ")";
    });
    hud.string = "HUD: " ++ txt;
};

// AppClock ticker
makeTicker = {
    var period, step;
    period = 1.0 / fps;
    step = {
        readLevels.value;
        viewAL.refresh; viewAR.refresh; viewBL.refresh; viewBR.refresh;
        AppClock.sched(period, { if(ticker == true) { step.value }; nil });
    };
    ticker = true;
    AppClock.sched(0.0, { step.value; nil });
};

killTicker = {
    ticker = nil;
};

w.onClose_({
    killTicker.value;
});

// run
w.front;
makeTicker.value;
w
) // -> a Window
