// MagicDisplayGUI_New_Window_AB_v0.3.10.scd
// v0.3.10
// MD 2025-09-25 15:48 BST

/*
Purpose
- Single window "MagicDisplayGUI ..." with 4 bars:
  A-L, A-R (replyID 2001) and B-L, B-R (replyID 2002).
- If A/B are effectively silent, mirror test(1001) into the bars (visual fallback) for the demo.
- HUD top-left; AppClock ticker ~30 Hz; fixed rects; single-window policy.

Style
- var-first in every block; descriptive lowercase names; AppClock-only; no server.sync.
- Known-good SC API only; final expression -> a Window.
*/

(
// === RUN ===
var closeExistingMagicDisplayWindows, ensureReceiver;
var w, rect, pad, barH, labelW, meterW, meterH, lineGap, makeBars;
var aL=0.0, aR=0.0, bL=0.0, bR=0.0, tL=0.0, tR=0.0;
var dAL=0.0, dAR=0.0, dBL=0.0, dBR=0.0; // displayed values after fallback logic
var hud, lblAL, lblAR, lblBL, lblBR, viewAL, viewAR, viewBL, viewBR;
var ticker, makeTicker, killTicker, readLevels, fps, ids, dict;
var fallbackThreshold, uiGamma;

fps = 30;
ids = (test: 1001, A: 2001, B: 2002);
dict = (~md_levelsById ? IdentityDictionary.new);
fallbackThreshold = 0.003;   // sum below this = "effectively zero" for demo
uiGamma = 1.0;               // 1.0 = linear; you can set 0.5 for sqrt visual boost if needed

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
w = Window("MagicDisplayGUI — A/B Meters (v0.3.10)", rect, false, false);
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
        var b, raw, scaled;
        b = v.bounds;
        raw = getLevelFunc.value.clip(0, 1);
        // optional gamma for low-level visibility (uiGamma <= 1 boosts lows)
        scaled = raw.pow(uiGamma);
        Pen.color = Color.gray(0.85);
        Pen.addRect(Rect(0, 0, b.width, b.height)); Pen.fill;
        Pen.color = Color(0.20, 0.70, 0.20);
        Pen.addRect(Rect(0, 0, b.width * scaled, b.height)); Pen.fill;
        Pen.color = Color.gray(0.55);
        Pen.strokeRect(Rect(0.5, 0.5, b.width-1, b.height-1));
    };
    uv
};

viewAL = makeBars.value(pad + labelW + 8, pad+30 + (0*(barH+lineGap)), { dAL });
viewAR = makeBars.value(pad + labelW + 8, pad+30 + (1*(barH+lineGap)), { dAR });
viewBL = makeBars.value(pad + labelW + 8, pad+30 + (2*(barH+lineGap)), { dBL });
viewBR = makeBars.value(pad + labelW + 8, pad+30 + (3*(barH+lineGap)), { dBR });

// read levels and compute display values with fallback
readLevels = {
    var a, b, t, sumAB, sumT, txt, showAL, showAR, showBL, showBR;
    dict = (~md_levelsById ? dict);
    a = dict[ids[\A]] ? [0.0, 0.0];
    b = dict[ids[\B]] ? [0.0, 0.0];
    t = dict[ids[\test]] ? [0.0, 0.0];

    aL = a[0]; aR = a[1];
    bL = b[0]; bR = b[1];
    tL = t[0]; tR = t[1];

    sumAB = (aL + aR + bL + bR).abs;
    sumT  = (tL + tR).abs;

    // Fallback rule: if both A and B effectively zero, mirror test into both A and B displays
    if((sumAB <= fallbackThreshold) and: { sumT > (fallbackThreshold * 0.3) }) {
        showAL = tL; showAR = tR;
        showBL = tL; showBR = tR;
    } {
        showAL = aL; showAR = aR;
        showBL = bL; showBR = bR;
    };

    dAL = showAL.clip(0, 1);
    dAR = showAR.clip(0, 1);
    dBL = showBL.clip(0, 1);
    dBR = showBR.clip(0, 1);

    // HUD with finer precision so quiet values are visible
    txt = "A[" ++ aL.round(0.001) ++ "," ++ aR.round(0.001) ++ "]  " ++
          "B[" ++ bL.round(0.001) ++ "," ++ bR.round(0.001) ++ "]";
    if((sumAB <= fallbackThreshold) and: { sumT > (fallbackThreshold * 0.3) }) {
        txt = txt ++ "  (fallback: test " ++ [tL.round(0.001), tR.round(0.001)] ++ ")";
    };
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
