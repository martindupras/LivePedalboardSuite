// MagicDisplayGUI_New_Window_AB_Styled_v0.4.4.scd
// v0.4.4
// MD 2025-09-25 16:48 BST

/*
Purpose
- Single window titled "MagicDisplayGUI ..." with a stable, deterministic layout akin to yesterday’s GUI:
  • HUD at top-left
  • Two grouped sections: "Chain A" (A-L, A-R) and "Chain B" (B-L, B-R)
  • Bars read A(2001)/B(2002); if both are effectively zero, mirror test(1001) for demo fallback.

Style
- var-first in every block/closure; descriptive lowercase names; AppClock-only; fixed rects; single-window policy.
- Known-good SC/Qt calls; no server.sync; final expression -> a Window.
*/

(
var closeExistingMagicDisplayWindows, ensureReceiverInstalled;
var windowRef, windowRect;
var paddingX, paddingY, rowGap;
var headerHeight, sectionTitleHeight, barHeight, labelWidth, meterWidth;
var levelIds, levelsDict, framesPerSecond, fallbackThreshold, uiGamma;
var hudLabel;
var meterFrameView;
var chainATitleLabel, chainALabelLeft, chainALabelRight, barViewALeft, barViewARight;
var chainBTitleLabel, chainBLabelLeft, chainBLabelRight, barViewBLeft, barViewBRight;
var chainALevelLeft, chainALevelRight, chainBLevelLeft, chainBLevelRight, testLevelLeft, testLevelRight;
var displayALevelLeft, displayALevelRight, displayBLevelLeft, displayBLevelRight;
var makeFrameView, makeBarView, drawSectionFrames, readLevelsAndUpdateDisplay, startTicker, stopTicker, tickerFlag;
var identityBanner;
var chainATitleY, chainABar1Y, chainABar2Y, chainBTitleY, chainBBar1Y, chainBBar2Y;

// === identity banner (after var-first) ======================================
identityBanner = "=== RUN === MagicDisplayGUI_New_Window_AB_Styled_v0.4.4.scd";
identityBanner.postln;

// --- constants/state ---------------------------------------------------------
framesPerSecond = 30;
levelIds = (test: 1001, A: 2001, B: 2002);
levelsDict = (~md_levelsById ? IdentityDictionary.new);
fallbackThreshold = 0.003;   // if sum(A+B) <= threshold, mirror test(1001) into bars
uiGamma = 1.0;               // 1.0=linear; try 0.7..0.5 to visually boost low levels

// layout constants (fixed) — tweak here to adjust spacing
paddingX = 12; paddingY = 10;
rowGap = 8;
headerHeight = 22;
sectionTitleHeight = 16;
barHeight = 14;
labelWidth = 84;   // wider, more readable
meterWidth = 360;

// init meter values
chainALevelLeft = 0.0; chainALevelRight = 0.0;
chainBLevelLeft = 0.0; chainBLevelRight = 0.0;
testLevelLeft = 0.0;   testLevelRight = 0.0;
displayALevelLeft = 0.0; displayALevelRight = 0.0;
displayBLevelLeft = 0.0; displayBLevelRight = 0.0;

// --- helpers -----------------------------------------------------------------
closeExistingMagicDisplayWindows = {
    var existingWindows;
    existingWindows = Window.allWindows.select({ arg winItem;
        var windowName;
        windowName = winItem.tryPerform(\name);
        windowName.notNil and: { windowName.asString.beginsWith("MagicDisplayGUI") }
    });
    AppClock.sched(0.0, { existingWindows.do({ arg winItem; winItem.close }); nil });
};

ensureReceiverInstalled = {
    var canInstall;
    canInstall = (~md_reinstallReceiver.notNil);
    if(canInstall) { ~md_reinstallReceiver.() };
};

makeFrameView = { arg parentView, frameRect;
    var userView;
    userView = UserView(parentView, frameRect);
    userView.background_(Color(0.95,0.95,0.95));
    userView.drawFunc = { arg uv;
        var bounds;
        bounds = uv.bounds;
        Pen.color = Color.gray(0.70);
        Pen.strokeRect(Rect(0.5, 0.5, bounds.width-1, bounds.height-1));
    };
    userView
};

makeBarView = { arg parentView, left, top, getLevelFunc;
    var userView;
    userView = UserView(parentView, Rect(left, top, meterWidth, barHeight));
    userView.background_(Color(0.92, 0.92, 0.92));
    userView.drawFunc = { arg uv;
        var bounds, raw, scaled;
        bounds = uv.bounds;
        raw = getLevelFunc.value.clip(0, 1);
        scaled = raw.pow(uiGamma);
        Pen.color = Color.gray(0.85);
        Pen.addRect(Rect(0, 0, bounds.width, bounds.height)); Pen.fill;
        Pen.color = Color(0.20, 0.70, 0.20);
        Pen.addRect(Rect(0, 0, bounds.width * scaled, bounds.height)); Pen.fill;
        Pen.color = Color.gray(0.55);
        Pen.strokeRect(Rect(0.5, 0.5, bounds.width-1, bounds.height-1));
    };
    userView
};

drawSectionFrames = { arg uv;
    var bounds, sectionHeight, aBoxTop, bBoxTop;
    bounds = uv.bounds;
    sectionHeight = (sectionTitleHeight + rowGap + (2*barHeight) + rowGap);
    aBoxTop = 6;
    bBoxTop = aBoxTop + sectionHeight + rowGap;
    Pen.color = Color.gray(0.80);
    Pen.addRect(Rect(8,  aBoxTop, bounds.width-16, sectionHeight)); Pen.stroke;
    Pen.color = Color.gray(0.80);
    Pen.addRect(Rect(8,  bBoxTop, bounds.width-16, sectionHeight)); Pen.stroke;
};

readLevelsAndUpdateDisplay = {
    var aVals, bVals, tVals, sumAB, sumT, hudTextString;
    levelsDict = (~md_levelsById ? levelsDict);

    aVals = levelsDict[levelIds[\A]] ? [0.0, 0.0];
    bVals = levelsDict[levelIds[\B]] ? [0.0, 0.0];
    tVals = levelsDict[levelIds[\test]] ? [0.0, 0.0];

    chainALevelLeft  = aVals[0]; chainALevelRight = aVals[1];
    chainBLevelLeft  = bVals[0]; chainBLevelRight = bVals[1];
    testLevelLeft    = tVals[0]; testLevelRight   = tVals[1];

    sumAB = (chainALevelLeft + chainALevelRight + chainBLevelLeft + chainBLevelRight).abs;
    sumT  = (testLevelLeft + testLevelRight).abs;

    // fallback: if both A and B effectively zero, mirror test(1001)
    if((sumAB <= fallbackThreshold) and: { sumT > (fallbackThreshold * 0.3) }) {
        displayALevelLeft  = testLevelLeft.clip(0,1);
        displayALevelRight = testLevelRight.clip(0,1);
        displayBLevelLeft  = testLevelLeft.clip(0,1);
        displayBLevelRight = testLevelRight.clip(0,1);
    } {
        displayALevelLeft  = chainALevelLeft.clip(0,1);
        displayALevelRight = chainALevelRight.clip(0,1);
        displayBLevelLeft  = chainBLevelLeft.clip(0,1);
        displayBLevelRight = chainBLevelRight.clip(0,1);
    };

    // HUD string with fine precision
    hudTextString =
        "A[" ++ chainALevelLeft.round(0.001) ++ "," ++ chainALevelRight.round(0.001) ++ "]  " ++
        "B[" ++ chainBLevelLeft.round(0.001) ++ "," ++ chainBLevelRight.round(0.001) ++ "]";
    if((sumAB <= fallbackThreshold) and: { sumT > (fallbackThreshold * 0.3) }) {
        hudTextString = hudTextString ++ "  (fallback: test " ++ [testLevelLeft.round(0.001), testLevelRight.round(0.001)] ++ ")";
    };
    hudLabel.string = "HUD: " ++ hudTextString;
};

startTicker = {
    var periodSeconds, stepFunc;
    periodSeconds = 1.0 / framesPerSecond;
    stepFunc = {
        readLevelsAndUpdateDisplay.value;
        barViewALeft.refresh;  barViewARight.refresh;
        barViewBLeft.refresh;  barViewBRight.refresh;
        meterFrameView.refresh;
        AppClock.sched(periodSeconds, { if(tickerFlag == true) { stepFunc.value }; nil });
    };
    tickerFlag = true;
    AppClock.sched(0.0, { stepFunc.value; nil });
};

stopTicker = { tickerFlag = nil };

// --- window + precise layout -------------------------------------------------
closeExistingMagicDisplayWindows.value;
ensureReceiverInstalled.value;

// compute total height from fixed metrics
windowRect = Rect(
    60, 60,
    paddingX + labelWidth + 8 + meterWidth + paddingX,
    paddingY + headerHeight + rowGap
    + (sectionTitleHeight + rowGap + (2*barHeight) + rowGap)   // A section
    + rowGap
    + (sectionTitleHeight + rowGap + (2*barHeight) + rowGap)   // B section
    + paddingY
);

// NOTE: resizable=false, border=true -> proper title bar visible
windowRef = Window("MagicDisplayGUI — Status + A/B Meters (v0.4.4)", windowRect, false, true);

// HUD
hudLabel = StaticText(windowRef, Rect(paddingX, paddingY, labelWidth + 8 + meterWidth, headerHeight));
hudLabel.stringColor = Color.black;
hudLabel.string = "HUD: waiting for levels…";

// Frame area that draws section boxes
meterFrameView = makeFrameView.value(windowRef, Rect(
    paddingX,
    paddingY + headerHeight + rowGap,
    (labelWidth + 8 + meterWidth),
    (sectionTitleHeight + rowGap + (2*barHeight) + rowGap) + rowGap
    + (sectionTitleHeight + rowGap + (2*barHeight) + rowGap)
));
meterFrameView.drawFunc = { arg uv; drawSectionFrames.value(uv) };

// Deterministic Y positions (no dependency on .bounds of other views)
chainATitleY = paddingY + headerHeight + rowGap + 6;
chainABar1Y  = chainATitleY + sectionTitleHeight + rowGap;
chainABar2Y  = chainABar1Y + barHeight + rowGap;

chainBTitleY = chainATitleY + (sectionTitleHeight + rowGap + (2*barHeight) + rowGap) + rowGap;
chainBBar1Y  = chainBTitleY + sectionTitleHeight + rowGap;
chainBBar2Y  = chainBBar1Y + barHeight + rowGap;

// Chain A
chainATitleLabel = StaticText(windowRef, Rect(paddingX + 8, chainATitleY, 120, sectionTitleHeight));
chainATitleLabel.string = "Chain A";

chainALabelLeft = StaticText(windowRef, Rect(paddingX + 16, chainABar1Y, labelWidth, barHeight));
chainALabelLeft.string = "A-L";
barViewALeft = makeBarView.value(windowRef, paddingX + 16 + labelWidth + 8, chainABar1Y, { displayALevelLeft });

chainALabelRight = StaticText(windowRef, Rect(paddingX + 16, chainABar2Y, labelWidth, barHeight));
chainALabelRight.string = "A-R";
barViewARight = makeBarView.value(windowRef, paddingX + 16 + labelWidth + 8, chainABar2Y, { displayALevelRight });

// Chain B
chainBTitleLabel = StaticText(windowRef, Rect(paddingX + 8, chainBTitleY, 120, sectionTitleHeight));
chainBTitleLabel.string = "Chain B";

chainBLabelLeft = StaticText(windowRef, Rect(paddingX + 16, chainBBar1Y, labelWidth, barHeight));
chainBLabelLeft.string = "B-L";
barViewBLeft = makeBarView.value(windowRef, paddingX + 16 + labelWidth + 8, chainBBar1Y, { displayBLevelLeft });

chainBLabelRight = StaticText(windowRef, Rect(paddingX + 16, chainBBar2Y, labelWidth, barHeight));
chainBLabelRight.string = "B-R";
barViewBRight = makeBarView.value(windowRef, paddingX + 16 + labelWidth + 8, chainBBar2Y, { displayBLevelRight });

// run
windowRef.onClose_({ stopTicker.value });
windowRef.front;
startTicker.value;
windowRef
) // -> a Window
