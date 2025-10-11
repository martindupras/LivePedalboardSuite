// MagicDisplayGUI_New_Window_PerfHUD_AB_v0.5.4.scd  / v0.5.4-p1 (safe background) / MD 2025-09-28
//
// Purpose
// - Performance HUD window (single, resizable "MagicDisplayGUI …").
// - Same layout and features as v0.5.4, but with SAFE deferred background color
//   assignment for TextView widgets to avoid 'base_' on nil during early layout.
//
// Style
// - var-first in every block/closure; AppClock-only; no server.sync; known-good SC/Qt calls.
// - Final expression returns -> a Window.

(
var closeExistingMagicDisplayWindows, ensureReceiverInstalled;
// window + metrics
var windowRef, windowRect;
var paddingX, paddingY, rowGap, columnGap;
var topRowHeight, systemTitleHeight, systemBodyHeight, bottomRowHeight;
var minPanelTextWidth, meterStripWidth;
// ids + levels + shaping
var levelIds, levelsDict, framesPerSecond, fallbackThreshold, uiGamma;
// top row views
var chainAPanel, chainBPanel;
var chainATitleLabel, chainBTitleLabel;
var meterViewBetweenA, meterViewBetweenB;
// system row views
var systemStateTitleLabel, systemStateTextView;
// bottom row views
var choicesTitleLabel, choicesTextView;
var processorsTitleLabel, processorsTextView;
// live state
var chainALevelLeft, chainALevelRight, chainBLevelLeft, chainBLevelRight, testLevelLeft, testLevelRight;
var displayALevelLeft, displayALevelRight, displayBLevelLeft, displayBLevelRight;
var isAActive, isBActive;
// helpers
var makePanelView, makeTitleLabel, makeVerticalMeterViewForA, makeVerticalMeterViewForB;
var drawVerticalMetersA, drawVerticalMetersB, setPanelActiveColor, setPanelNeutralColor;
var safeSetBackground; // NEW: safe, deferred TextView background setter
// refresh + layout + ticker
var readLevelsAndUpdate, refreshChoicesPane, refreshProcessorsPane;
var computeAndApplyLayout, layoutInitialized;
var startTicker, stopTicker, tickerFlag, stepFunc;
var lastWidth, lastHeight;
// identity banner
var identityBanner;

// === console identity =========================================================
identityBanner = "=== RUN === MagicDisplayGUI_New_Window_PerfHUD_AB_v0.5.4.scd";
identityBanner.postln;

// --- constants/state ----------------------------------------------------------
framesPerSecond = 30;
levelIds = (test: 1001, A: 2001, B: 2002);
levelsDict = (~md_levelsById ? IdentityDictionary.new);
fallbackThreshold = 0.003; // if A+B near zero, mirror test for visual continuity
uiGamma = 1.0; // 1.0 linear; try 0.7..0.5 to boost quiet levels

// layout metrics (steady verticals)
paddingX = 10;
paddingY = 10;
rowGap = 8;
columnGap= 12;
topRowHeight = 140;       // Chain A/B panels
systemTitleHeight = 18;   // "System State"
systemBodyHeight = 78;    // ~triple height
bottomRowHeight = 180;    // Choices + Processors
minPanelTextWidth = 220;
meterStripWidth = 18;

// init values
chainALevelLeft = 0.0; chainALevelRight = 0.0;
chainBLevelLeft = 0.0; chainBLevelRight = 0.0;
testLevelLeft = 0.0; testLevelRight = 0.0;
displayALevelLeft = 0.0; displayALevelRight = 0.0;
displayBLevelLeft = 0.0; displayBLevelRight = 0.0;
isAActive = false; isBActive = false;
layoutInitialized = false;

// --- helpers (views) ----------------------------------------------------------
closeExistingMagicDisplayWindows = {
    var existingWindows;
    existingWindows = Window.allWindows.select({ arg w;
        var nm;
        nm = w.tryPerform(\name);
        nm.notNil and: { nm.asString.beginsWith("MagicDisplayGUI") }
    });
    AppClock.sched(0.0, { existingWindows.do({ arg w; w.close }); nil });
};

ensureReceiverInstalled = {
    var canInstall;
    canInstall = (~md_reinstallReceiver.notNil);
    if(canInstall) { ~md_reinstallReceiver.() };
};

// NEW: safe, deferred setter for TextView backgrounds (prevents 'base_' on nil)
safeSetBackground = { |view, color, delay=0.03|
    AppClock.sched(delay, {
        if(view.notNil and: { view.isClosed.not }) {
            view.background_(color);
        };
        nil
    });
};

makePanelView = { arg parent, r;
    var v;
    v = UserView(parent, r);
    v.background_(Color(0.94, 0.94, 0.94));
    v.drawFunc = { arg uv;
        var b;
        b = uv.bounds;
        Pen.color = Color.gray(0.65);
        Pen.strokeRect(Rect(0.5, 0.5, b.width-1, b.height-1));
    };
    v
};

makeTitleLabel = { arg parent, r, titleString;
    var label;
    label = StaticText(parent, r);
    label.string_(titleString);
    label.stringColor_(Color.black);
    label.align_(\left);
    label
};

drawVerticalMetersA = { arg uv;
    var b, gap, oneWidth, leftVal, rightVal, leftH, rightH;
    b = uv.bounds;
    gap = 2;
    oneWidth = ((b.width - gap) / 2).max(3);
    leftVal  = displayALevelLeft.clip(0,1).pow(uiGamma);
    rightVal = displayALevelRight.clip(0,1).pow(uiGamma);
    leftH  = (b.height * leftVal).clip(0, b.height);
    rightH = (b.height * rightVal).clip(0, b.height);
    Pen.color = Color(0.86,0.86,0.86); Pen.addRect(Rect(0, 0, oneWidth, b.height)); Pen.fill;
    Pen.color = Color(0.86,0.86,0.86); Pen.addRect(Rect(oneWidth + gap, 0, oneWidth, b.height)); Pen.fill;
    Pen.color = Color(0.20, 0.70, 0.20);
    Pen.addRect(Rect(0,              b.height - leftH,  oneWidth, leftH));  Pen.fill;
    Pen.addRect(Rect(oneWidth + gap, b.height - rightH, oneWidth, rightH)); Pen.fill;
    Pen.color = Color.gray(0.55);
    Pen.strokeRect(Rect(0.5, 0.5, oneWidth-1, b.height-1));
    Pen.strokeRect(Rect(oneWidth + gap + 0.5, 0.5, oneWidth-1, b.height-1));
};

drawVerticalMetersB = { arg uv;
    var b, gap, oneWidth, leftVal, rightVal, leftH, rightH;
    b = uv.bounds;
    gap = 2;
    oneWidth = ((b.width - gap) / 2).max(3);
    leftVal  = displayBLevelLeft.clip(0,1).pow(uiGamma);
    rightVal = displayBLevelRight.clip(0,1).pow(uiGamma);
    leftH  = (b.height * leftVal).clip(0, b.height);
    rightH = (b.height * rightVal).clip(0, b.height);
    Pen.color = Color(0.86,0.86,0.86); Pen.addRect(Rect(0, 0, oneWidth, b.height)); Pen.fill;
    Pen.color = Color(0.86,0.86,0.86); Pen.addRect(Rect(oneWidth + gap, 0, oneWidth, b.height)); Pen.fill;
    Pen.color = Color(0.20, 0.70, 0.20);
    Pen.addRect(Rect(0,              b.height - leftH,  oneWidth, leftH));  Pen.fill;
    Pen.addRect(Rect(oneWidth + gap, b.height - rightH, oneWidth, rightH)); Pen.fill;
    Pen.color = Color.gray(0.55);
    Pen.strokeRect(Rect(0.5, 0.5, oneWidth-1, b.height-1));
    Pen.strokeRect(Rect(oneWidth + gap + 0.5, 0.5, oneWidth-1, b.height-1));
};

makeVerticalMeterViewForA = { arg parent, r;
    var v;
    v = UserView(parent, r);
    v.background_(Color(0.92,0.92,0.92));
    v.drawFunc = { arg uv; var dummy; dummy=nil; drawVerticalMetersA.value(uv) };
    v
};

makeVerticalMeterViewForB = { arg parent, r;
    var v;
    v = UserView(parent, r);
    v.background_(Color(0.92,0.92,0.92));
    v.drawFunc = { arg uv; var dummy; dummy=nil; drawVerticalMetersB.value(uv) };
    v
};

setPanelActiveColor  = { arg panelView;  panelView.background_(Color(0.86, 0.97, 0.86)) };
setPanelNeutralColor = { arg panelView;  panelView.background_(Color(0.94, 0.94, 0.94)) };

// --- data + UI refresh (DEFENSIVE) -------------------------------------------
readLevelsAndUpdate = {
    var aVals, bVals, tVals, sumAB, sumT;
    var sumAEnergy, sumBEnergy, epsilon, ageSeconds;
    var getPairSafe;

    getPairSafe = { arg dict, key;
        var arr;
        arr = (dict.respondsTo(\at)).if({ dict.at(key) }, { nil });
        (arr.isArray and: { arr.size >= 2 and: { arr[0].isNumber and: { arr[1].isNumber } } })
        .if({ arr }, { [0.0, 0.0] })
    };

    levelsDict = (~md_levelsById.isKindOf(IdentityDictionary)).if({ ~md_levelsById }, { IdentityDictionary.new });

    aVals = getPairSafe.value(levelsDict, levelIds[\A]);
    bVals = getPairSafe.value(levelsDict, levelIds[\B]);
    tVals = getPairSafe.value(levelsDict, levelIds[\test]);

    chainALevelLeft = aVals[0]; chainALevelRight = aVals[1];
    chainBLevelLeft = bVals[0]; chainBLevelRight = bVals[1];
    testLevelLeft   = tVals[0]; testLevelRight   = tVals[1];

    sumAB = (chainALevelLeft + chainALevelRight + chainBLevelLeft + chainBLevelRight).abs;
    sumT  = (testLevelLeft + testLevelRight).abs;

    if((sumAB <= fallbackThreshold) and: { sumT > (fallbackThreshold * 0.3) }) {
        displayALevelLeft  = testLevelLeft.clip(0,1);
        displayALevelRight = testLevelRight.clip(0,1);
        displayBLevelLeft  = testLevelLeft.clip(0,1);
        displayBLevelRight = testLevelRight.clip(0,1);
    }{
        displayALevelLeft  = chainALevelLeft.clip(0,1);
        displayALevelRight = chainALevelRight.clip(0,1);
        displayBLevelLeft  = chainBLevelLeft.clip(0,1);
        displayBLevelRight = chainBLevelRight.clip(0,1);
    };

    sumAEnergy = ((displayALevelLeft.isNumber.if({ displayALevelLeft }, { 0.0 })) +
                  (displayALevelRight.isNumber.if({ displayALevelRight }, { 0.0 })));
    sumBEnergy = ((displayBLevelLeft.isNumber.if({ displayBLevelLeft }, { 0.0 })) +
                  (displayBLevelRight.isNumber.if({ displayBLevelRight }, { 0.0 })));
    epsilon = 0.001;

    isAActive = (sumAEnergy > (sumBEnergy + epsilon));
    isBActive = (sumBEnergy > (sumAEnergy + epsilon));

    if(chainAPanel.notNil) { if(isAActive) { setPanelActiveColor.value(chainAPanel) } { setPanelNeutralColor.value(chainAPanel) } };
    if(chainBPanel.notNil) { if(isBActive) { setPanelActiveColor.value(chainBPanel) } { setPanelNeutralColor.value(chainBPanel) } };

    // System State with last /md/levels age
    ageSeconds = (Main.elapsedTime - (~md_lastMsgStamp ? 0)).round(0.01);
    systemStateTextView.string_("system ready\n(last /md/levels: " ++ ageSeconds ++ " s ago)");
};

refreshChoicesPane = {
    var sysObj, cm, builder, textLines, s;
    sysObj = ~system;
    if(sysObj.isNil) {
        s = "(n/a — no ~system)";
    }{
        cm = sysObj.tryPerform(\commandManager);
        builder = cm.tryPerform(\builder);
        if(builder.notNil and: { builder.tryPerform(\currentNode).notNil }) {
            textLines = builder.currentNode.children.collect({ arg child;
                var nm, fr;
                nm = child.tryPerform(\name) ? child.asString;
                fr = child.tryPerform(\fret);
                (fr.notNil).if({ ("fret " ++ fr.asString ++ " → " ++ nm) }, { nm });
            });
            s = textLines.join($\n);
        }{
            s = "(n/a — no builder or no node)";
        };
    };
    choicesTextView.string_(s);
};

refreshProcessorsPane = {
    var providerFunc, s;
    providerFunc = ( ~md_cmdTextProvider.isKindOf(Function) ).if({ ~md_cmdTextProvider }, { nil });
    if(providerFunc.notNil) {
        s = providerFunc.value;
    }{
        s = "Processors / Queue:\n"
        ++ "(no provider)\n"
        ++ "Set ~md_cmdTextProvider to a function that returns a string.\n\n"
        ++ "Example (temporary):\n"
        ++ "~md_cmdTextProvider = {\n"
        ++ " var cm, next;\n"
        ++ " cm = (~system.tryPerform(\\commandManager));\n"
        ++ " next = (cm.notNil and: { cm.respondsTo(\\canonicalPathFromBuilder) })\n"
        ++ " .if({ cm.canonicalPathFromBuilder(cm.builder) }, { \"(n/a)\" });\n"
        ++ " \"Next: \" ++ next.asString\n"
        ++ "};";
    };
    processorsTextView.string_(s);
};

// --- layout (GUARDED; never writes nil Rect) ----------------------------------
computeAndApplyLayout = {
    var wb, contentW, halfW;
    var panelY, systemTitleY, systemBodyY, bottomY;
    var aX, aW, bX, bW;
    var meterAX, meterBX, meterY, meterH;
    var titleH;

    wb = windowRef.bounds;
    if(wb.isKindOf(Rect).not) {
        AppClock.sched(0.03, { computeAndApplyLayout.value; nil });
    }{
        contentW = (wb.width - (paddingX * 2)).max(560);
        halfW    = (((contentW - columnGap) / 2)).max(minPanelTextWidth + meterStripWidth + 16);
        panelY = paddingY;
        systemTitleY = panelY + topRowHeight + rowGap;
        systemBodyY  = systemTitleY + systemTitleHeight + 4;
        bottomY = systemBodyY + systemBodyHeight + rowGap;

        aX = paddingX; aW = halfW;
        bX = paddingX + halfW + columnGap; bW = halfW;
        titleH = 16;

        chainAPanel.bounds_(Rect(aX, panelY, aW, topRowHeight));
        chainBPanel.bounds_(Rect(bX, panelY, bW, topRowHeight));
        chainATitleLabel.bounds_(Rect(aX + 8, panelY + 6, 120, titleH));
        chainBTitleLabel.bounds_(Rect(bX + 8, panelY + 6, 120, titleH));

        meterY = panelY + 8 + titleH + 4;
        meterH = topRowHeight - (meterY - panelY) - 8;
        meterAX = aX + aW - 8 - meterStripWidth; // A: right edge
        meterBX = bX + 8; // B: left edge
        meterViewBetweenA.bounds_(Rect(meterAX, meterY, meterStripWidth, meterH));
        meterViewBetweenB.bounds_(Rect(meterBX, meterY, meterStripWidth, meterH));

        systemStateTitleLabel.bounds_(Rect(paddingX, systemTitleY, contentW, systemTitleHeight));
        systemStateTextView.bounds_(Rect(paddingX, systemBodyY, contentW, systemBodyHeight));

        // SAFE: defer TextView background (prevents 'base_' on nil)
        safeSetBackground.(systemStateTextView, Color(1.0, 0.95, 0.6));

        choicesTitleLabel.bounds_(Rect(paddingX, bottomY, halfW, 16));
        choicesTextView.bounds_(Rect(paddingX, bottomY + 18, halfW, bottomRowHeight - 20));
        processorsTitleLabel.bounds_(Rect(paddingX + halfW + columnGap, bottomY, halfW, 16));
        processorsTextView.bounds_(Rect(paddingX + halfW + columnGap, bottomY + 18, halfW, bottomRowHeight - 20));
    };
};

// --- ticker (GUARDED sequencing; layout first, then step loop) ----------------
startTicker = {
    var periodSeconds;
    periodSeconds = 1.0 / framesPerSecond;

    AppClock.sched(0.05, {
        layoutInitialized = true;
        computeAndApplyLayout.value;
        nil
    });

    AppClock.sched(0.10, {
        lastWidth  = windowRef.bounds.width;
        lastHeight = windowRef.bounds.height;

        stepFunc = {
            var w, h;
            readLevelsAndUpdate.value;
            if(layoutInitialized) {
                w = windowRef.bounds.width;  h = windowRef.bounds.height;
                if((w != lastWidth) or: { h != lastHeight }) {
                    computeAndApplyLayout.value;
                    lastWidth = w; lastHeight = h;
                };
            };
            meterViewBetweenA.refresh;
            meterViewBetweenB.refresh;
            AppClock.sched(periodSeconds, { if(tickerFlag == true) { stepFunc.value }; nil });
        };

        tickerFlag = true;
        stepFunc.value;
        nil
    });
};

stopTicker = { tickerFlag = nil };

// --- construct + run ----------------------------------------------------------
closeExistingMagicDisplayWindows.value;
ensureReceiverInstalled.value;

// Initial size (fits on first open)
windowRect = Rect(
  70, 70,
  paddingX + (minPanelTextWidth + meterStripWidth + columnGap + minPanelTextWidth + meterStripWidth) + paddingX + 60,
  paddingY + topRowHeight + rowGap + systemTitleHeight + systemBodyHeight + rowGap + bottomRowHeight + paddingY
);

// Resizable=true, border=true -> proper title + resizable
windowRef = Window("MagicDisplayGUI — Performance HUD (v0.5.4)", windowRect, true, true);

// top row
chainAPanel       = makePanelView.value(windowRef, Rect(0,0,10,10));
chainBPanel       = makePanelView.value(windowRef, Rect(0,0,10,10));
chainATitleLabel  = makeTitleLabel.value(windowRef, Rect(0,0,10,10), "Chain A");
chainBTitleLabel  = makeTitleLabel.value(windowRef, Rect(0,0,10,10), "Chain B");
meterViewBetweenA = makeVerticalMeterViewForA.value(windowRef, Rect(0,0,10,10));
meterViewBetweenB = makeVerticalMeterViewForB.value(windowRef, Rect(0,0,10,10));

// system state row
systemStateTitleLabel = makeTitleLabel.value(windowRef, Rect(0,0,10,10), "System State");
systemStateTextView   = TextView(windowRef, Rect(0,0,10,10));
systemStateTextView.editable_(false);
// SAFE: defer initial background too
safeSetBackground.(systemStateTextView, Color(1.0, 0.95, 0.6));
systemStateTextView.string_("system ready");

// bottom row
choicesTitleLabel   = makeTitleLabel.value(windowRef, Rect(0,0,10,10), "Choices");
choicesTextView     = TextView(windowRef, Rect(0,0,10,10));
choicesTextView.editable_(false);
safeSetBackground.(choicesTextView,    Color(0.97,0.97,0.97));

processorsTitleLabel = makeTitleLabel.value(windowRef, Rect(0,0,10,10), "Processors");
processorsTextView   = TextView(windowRef, Rect(0,0,10,10));
processorsTextView.editable_(false);
safeSetBackground.(processorsTextView, Color(0.97,0.97,0.97));

// run
windowRef.onClose_({ stopTicker.value });
windowRef.front;
startTicker.value;
windowRef
) // -> a Window
