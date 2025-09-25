// MagicDisplayGUI_New_Window_AB_Styled_v0.4.3.scd
// v0.4.3
// MD 2025-09-25 16:36 BST

/*
Purpose
- Single window titled "MagicDisplayGUI ..." with a stable, deterministic layout akin to yesterday’s GUI:
  • HUD at top-left
  • Two grouped sections: "Chain A" (A-L, A-R) and "Chain B" (B-L, B-R)
  • Bars read A(2001)/B(2002). If both are effectively zero, mirror test(1001) for demo fallback.

Style
- var-first in every block and closure; AppClock-only; fixed rects; single-window policy.
- Known-good SC/Qt calls; no server.sync; final expression -> a Window.
*/

(
var closeExistingMagicDisplayWindows, ensureReceiver;
var w, rect, padX, padY, rowGap;
var headerH, sectionTitleH, barH, labelW, meterW;
var ids, dict, fps, fallbackThreshold, uiGamma;
var hudText;
var viewFrame;
var aTitle, aLblL, aLblR, viewAL, viewAR;
var bTitle, bLblL, bLblR, viewBL, viewBR;
var aL, aR, bL, bR, tL, tR;
var dAL, dAR, dBL, dBR;
var makeFrame, makeBar, drawFrame, readLevels, makeTicker, killTicker, ticker;

// --- constants/state (assignments after var-first) ---------------------------
fps = 30;
ids = (test: 1001, A: 2001, B: 2002);
dict = (~md_levelsById ? IdentityDictionary.new);
fallbackThreshold = 0.003;   // sum(A+B) <= this => mirror test(1001) into bars
uiGamma = 1.0;               // 1.0=linear; try 0.7..0.5 to visually boost low levels

// layout constants (fixed) — tweak here to adjust spacing
padX = 12; padY = 10;
rowGap = 8;
headerH = 22;
sectionTitleH = 16;
barH = 14;
labelW = 64;
meterW = 360;

// init numbers
aL=0.0; aR=0.0; bL=0.0; bR=0.0; tL=0.0; tR=0.0;
dAL=0.0; dAR=0.0; dBL=0.0; dBR=0.0;

// --- helpers -----------------------------------------------------------------
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

makeFrame = { arg parentView, r;
    var v;
    v = UserView(parentView, r);
    v.background_(Color(0.95,0.95,0.95));
    v.drawFunc = { arg uv;
        var b;
        b = uv.bounds;
        Pen.color = Color.gray(0.70);
        Pen.strokeRect(Rect(0.5, 0.5, b.width-1, b.height-1));
    };
    v
};

makeBar = { arg parentView, left, top, getLevelFunc;
    var uv;
    uv = UserView(parentView, Rect(left, top, meterW, barH));
    uv.background_(Color(0.92, 0.92, 0.92));
    uv.drawFunc = { arg v;
        var b, raw, scaled;
        b = v.bounds;
        raw = getLevelFunc.value.clip(0, 1);
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

drawFrame = { arg v;
    var b, sectionH, aBoxTop, bBoxTop;
    b = v.bounds;
    sectionH = (sectionTitleH + rowGap + (2*barH) + rowGap);
    aBoxTop = 6;
    bBoxTop = aBoxTop + sectionH + rowGap;
    Pen.color = Color.gray(0.80);
    Pen.addRect(Rect(8,  aBoxTop, b.width-16, sectionH)); Pen.stroke;
    Pen.color = Color.gray(0.80);
    Pen.addRect(Rect(8,  bBoxTop, b.width-16, sectionH)); Pen.stroke;
};

readLevels = {
    var a, b, t, sumAB, sumT, txt;
    dict = (~md_levelsById ? dict);

    a = dict[ids[\A]] ? [0.0, 0.0];
    b = dict[ids[\B]] ? [0.0, 0.0];
    t = dict[ids[\test]] ? [0.0, 0.0];

    aL = a[0]; aR = a[1];
    bL = b[0]; bR = b[1];
    tL = t[0]; tR = t[1];

    sumAB = (aL + aR + bL + bR).abs;
    sumT  = (tL + tR).abs;

    // fallback: if both A and B effectively zero, mirror test(1001)
    if((sumAB <= fallbackThreshold) and: { sumT > (fallbackThreshold * 0.3) }) {
        dAL = tL.clip(0,1); dAR = tR.clip(0,1);
        dBL = tL.clip(0,1); dBR = tR.clip(0,1);
    } {
        dAL = aL.clip(0,1); dAR = aR.clip(0,1);
        dBL = bL.clip(0,1); dBR = bR.clip(0,1);
    };

    txt = "A[" ++ aL.round(0.001) ++ "," ++ aR.round(0.001) ++ "]  " ++
          "B[" ++ bL.round(0.001) ++ "," ++ bR.round(0.001) ++ "]";
    if((sumAB <= fallbackThreshold) and: { sumT > (fallbackThreshold * 0.3) }) {
        txt = txt ++ "  (fallback: test " ++ [tL.round(0.001), tR.round(0.001)] ++ ")";
    };
    hudText.string = "HUD: " ++ txt;
};

makeTicker = {
    var period, step;
    period = 1.0 / fps;
    step = {
        readLevels.value;
        viewAL.refresh; viewAR.refresh; viewBL.refresh; viewBR.refresh;
        viewFrame.refresh;
        AppClock.sched(period, { if(ticker == true) { step.value }; nil });
    };
    ticker = true;
    AppClock.sched(0.0, { step.value; nil });
};

killTicker = {
    ticker = nil;
};

// --- window + precise layout -------------------------------------------------
closeExistingMagicDisplayWindows.value;
ensureReceiver.value;

// Overall height is computed from independent metrics only.
rect = Rect(
    60, 60,
    padX + labelW + 8 + meterW + padX,
    padY + headerH + rowGap
    + (sectionTitleH + rowGap + (2*barH) + rowGap)   // A section
    + rowGap
    + (sectionTitleH + rowGap + (2*barH) + rowGap)   // B section
    + padY
);

// NOTE: resizable=false, border=true -> proper title bar visible
w = Window("MagicDisplayGUI — Status + A/B Meters (v0.4.3)", rect, false, true);

// HUD
hudText = StaticText(w, Rect(padX, padY, labelW + 8 + meterW, headerH));
hudText.stringColor = Color.black;
hudText.string = "HUD: waiting for levels…";

// Frame region
viewFrame = makeFrame.value(w, Rect(
    padX,
    padY + headerH + rowGap,
    (labelW + 8 + meterW),
    (sectionTitleH + rowGap + (2*barH) + rowGap) + rowGap
    + (sectionTitleH + rowGap + (2*barH) + rowGap)
));
viewFrame.drawFunc = { arg uv; drawFrame.value(uv) };

// Compute deterministic Y positions (no dependency on other views’ bounds)
var a_title_y, a_bar1_y, a_bar2_y, b_title_y, b_bar1_y, b_bar2_y;
a_title_y = padY + headerH + rowGap + 6;
a_bar1_y  = a_title_y + sectionTitleH + rowGap;
a_bar2_y  = a_bar1_y + barH + rowGap;

b_title_y = a_title_y + (sectionTitleH + rowGap + (2*barH) + rowGap) + rowGap;
b_bar1_y  = b_title_y + sectionTitleH + rowGap;
b_bar2_y  = b_bar1_y + barH + rowGap;

// Chain A
aTitle = StaticText(w, Rect(padX + 8, a_title_y, 80, sectionTitleH)); aTitle.string = "Chain A";
aLblL  = StaticText(w, Rect(padX + 16, a_bar1_y, labelW, barH));      aLblL.string = "A-L";
viewAL = makeBar.value(w, padX + 16 + labelW + 8, a_bar1_y, { dAL });
aLblR  = StaticText(w, Rect(padX + 16, a_bar2_y, labelW, barH));      aLblR.string = "A-R";
viewAR = makeBar.value(w, padX + 16 + labelW + 8, a_bar2_y, { dAR });

// Chain B
bTitle = StaticText(w, Rect(padX + 8, b_title_y, 80, sectionTitleH)); bTitle.string = "Chain B";
bLblL  = StaticText(w, Rect(padX + 16, b_bar1_y, labelW, barH));      bLblL.string = "B-L";
viewBL = makeBar.value(w, padX + 16 + labelW + 8, b_bar1_y, { dBL });
bLblR  = StaticText(w, Rect(padX + 16, b_bar2_y, labelW, barH));      bLblR.string = "B-R";
viewBR = makeBar.value(w, padX + 16 + labelW + 8, b_bar2_y, { dBR });

// run
w.onClose_({ killTicker.value });
w.front;
makeTicker.value;
w
) // -> a Window
