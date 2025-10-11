// MagicDisplayGUI_New_Window_PerfHUD_AB_v0.5.1.scd
// v0.5.1
// MD 2025-09-25 17:56 BST

/*
Purpose
- Performance HUD window (single, resizable "MagicDisplayGUI …").
- Top row: Chain A (left) and Chain B (right). The ACTIVE one is highlighted (soft green).
  • Vertical meters are BETWEEN the chains (to the right of A, to the left of B).
- Second row: full-width yellow status row with "system ready".
- Bottom-left: Choices pane (safe; reads from ~system.commandManager.builder if present).
- Bottom-right: Messages / Next pane (safe; last A/B values and optional canonical next).
- Non-intrusive: reads /md/levels A=2001 B=2002 (fallback mirrors test=1001 when A/B quiet).

Style
- var-first in every block/closure; descriptive lowercase names; known-good SC/Qt GUI only.
- AppClock-only; no server.sync; avoids destructive server actions.
- Final expression returns -> a Window. Title starts with "MagicDisplayGUI".
*/

(
var closeExistingMagicDisplayWindows, ensureReceiverInstalled;
var windowRef, windowRect;
var paddingX, paddingY, rowGap, columnGap;
var topRowHeight, statusRowHeight, bottomRowHeight;
var minPanelTextWidth, meterStripWidth, panelBorder;
var levelIds, levelsDict, framesPerSecond, fallbackThreshold, uiGamma;

var chainAPanel, chainBPanel;
var meterViewBetweenA, meterViewBetweenB; // A's meters (at A right edge), B's meters (at B left edge)
var statusLabel;
var choicesTitleLabel, choicesTextView, messagesTitleLabel, messagesTextView;

var chainALevelLeft, chainALevelRight, chainBLevelLeft, chainBLevelRight, testLevelLeft, testLevelRight;
var displayALevelLeft, displayALevelRight, displayBLevelLeft, displayBLevelRight;
var isAActive, isBActive;

var makePanelView, makeVerticalMeterViewForA, makeVerticalMeterViewForB;
var drawVerticalMetersA, drawVerticalMetersB;
var setPanelActiveColor, setPanelNeutralColor;

var readLevelsAndUpdate, refreshChoicesPane, refreshMessagesPane;
var computeAndApplyLayout, lastWidth, lastHeight;
var startTicker, stopTicker, tickerFlag;

var identityBanner;

// === console identity (after var-first) =====================================
identityBanner = "=== RUN === MagicDisplayGUI_New_Window_PerfHUD_AB_v0.5.1.scd";
identityBanner.postln;

// --- constants/state ---------------------------------------------------------
framesPerSecond = 30;
levelIds = (test: 1001, A: 2001, B: 2002);
levelsDict = (~md_levelsById ? IdentityDictionary.new);

// visual shaping
fallbackThreshold = 0.003;   // if A+B near zero, mirror test into display for demo continuity
uiGamma = 1.0;               // 1.0 linear; lower (0.7..0.5) visually boosts quiet levels

// layout metrics (kept steady vertically for predictability on iPad)
paddingX = 10;
paddingY = 10;
rowGap   = 8;
columnGap= 12;

topRowHeight    = 124;       // Chain A/B row height
statusRowHeight = 26;        // "system ready" row
bottomRowHeight = 168;       // bottom panes row height

minPanelTextWidth = 220;     // minimal inner text area width per chain panel
meterStripWidth   = 18;      // width of each slim vertical meter (2 bars drawn inside)
panelBorder       = 1;

// init values
chainALevelLeft = 0.0; chainALevelRight = 0.0;
chainBLevelLeft = 0.0; chainBLevelRight = 0.0;
testLevelLeft   = 0.0; testLevelRight   = 0.0;

displayALevelLeft = 0.0; displayALevelRight = 0.0;
displayBLevelLeft = 0.0; displayBLevelRight = 0.0;

isAActive = false; isBActive = false;

// --- helpers -----------------------------------------------------------------
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

makePanelView = { arg parent, rect;
    var panelView;
    panelView = UserView(parent, rect);
    panelView.background_(Color(0.94, 0.94, 0.94)); // neutral; will be greener when active
    panelView.drawFunc = { arg uv;
        var b;
        b = uv.bounds;
        Pen.color = Color.gray(0.65);
        Pen.strokeRect(Rect(0.5, 0.5, b.width-1, b.height-1));
    };
    panelView
};

drawVerticalMetersA = { arg uv;
    var b, gap, barCount, oneWidth, leftVal, rightVal, leftH, rightH;
    b = uv.bounds;
    gap = 2;
    barCount = 2;
    oneWidth = ((b.width - gap) / barCount).max(3);

    leftVal  = displayALevelLeft.clip(0,1).pow(uiGamma);
    rightVal = displayALevelRight.clip(0,1).pow(uiGamma);

    leftH  = (b.height * leftVal).clip(0, b.height);
    rightH = (b.height * rightVal).clip(0, b.height);

    Pen.color = Color(0.86,0.86,0.86); Pen.addRect(Rect(0, 0, oneWidth, b.height)); Pen.fill;
    Pen.color = Color(0.86,0.86,0.86); Pen.addRect(Rect(oneWidth + gap, 0, oneWidth, b.height)); Pen.fill;

    Pen.color = Color(0.20, 0.70, 0.20);
    Pen.addRect(Rect(0, b.height - leftH, oneWidth, leftH)); Pen.fill;
    Pen.addRect(Rect(oneWidth + gap, b.height - rightH, oneWidth, rightH)); Pen.fill;

    Pen.color = Color.gray(0.55);
    Pen.strokeRect(Rect(0.5, 0.5, oneWidth-1, b.height-1));
    Pen.strokeRect(Rect(oneWidth + gap + 0.5, 0.5, oneWidth-1, b.height-1));
};

drawVerticalMetersB = { arg uv;
    var b, gap, barCount, oneWidth, leftVal, rightVal, leftH, rightH;
    b = uv.bounds;
    gap = 2;
    barCount = 2;
    oneWidth = ((b.width - gap) / barCount).max(3);

    leftVal  = displayBLevelLeft.clip(0,1).pow(uiGamma);
    rightVal = displayBLevelRight.clip(0,1).pow(uiGamma);

    leftH  = (b.height * leftVal).clip(0, b.height);
    rightH = (b.height * rightVal).clip(0, b.height);

    Pen.color = Color(0.86,0.86,0.86); Pen.addRect(Rect(0, 0, oneWidth, b.height)); Pen.fill;
    Pen.color = Color(0.86,0.86,0.86); Pen.addRect(Rect(oneWidth + gap, 0, oneWidth, b.height)); Pen.fill;

    Pen.color = Color(0.20, 0.70, 0.20);
    Pen.addRect(Rect(0, b.height - leftH, oneWidth, leftH)); Pen.fill;
    Pen.addRect(Rect(oneWidth + gap, b.height - rightH, oneWidth, rightH)); Pen.fill;

    Pen.color = Color.gray(0.55);
    Pen.strokeRect(Rect(0.5, 0.5, oneWidth-1, b.height-1));
    Pen.strokeRect(Rect(oneWidth + gap + 0.5, 0.5, oneWidth-1, b.height-1));
};

makeVerticalMeterViewForA = { arg parent, rect;
    var v;
    v = UserView(parent, rect);
    v.background_(Color(0.92,0.92,0.92));
    v.drawFunc = { arg uv;
        var dummy;
        dummy = nil; // var-first placeholder
        drawVerticalMetersA.value(uv);
    };
    v
};

makeVerticalMeterViewForB = { arg parent, rect;
    var v;
    v = UserView(parent, rect);
    v.background_(Color(0.92,0.92,0.92));
    v.drawFunc = { arg uv;
        var dummy;
        dummy = nil; // var-first placeholder
        drawVerticalMetersB.value(uv);
    };
    v
};

setPanelActiveColor = { arg panelView;
    panelView.background = Color(0.86, 0.97, 0.86);
};

setPanelNeutralColor = { arg panelView;
    panelView.background = Color(0.94, 0.94, 0.94);
};

// --- data refresh ------------------------------------------------------------
readLevelsAndUpdate = {
    var aVals, bVals, tVals, sumAB, sumT;

    levelsDict = (~md_levelsById ? levelsDict);
    aVals = levelsDict[levelIds[\A]] ? [0.0, 0.0];
    bVals = levelsDict[levelIds[\B]] ? [0.0, 0.0];
    tVals = levelsDict[levelIds[\test]] ? [0.0, 0.0];

    chainALevelLeft  = aVals[0]; chainALevelRight = aVals[1];
    chainBLevelLeft  = bVals[0]; chainBLevelRight = bVals[1];
    testLevelLeft    = tVals[0]; testLevelRight   = tVals[1];

    sumAB = (chainALevelLeft + chainALevelRight + chainBLevelLeft + chainBLevelRight).abs;
    sumT  = (testLevelLeft + testLevelRight).abs;

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

    isAActive = Ndef(\chainA).isPlaying;
    isBActive = Ndef(\chainB).isPlaying;

    if(chainAPanel.notNil) { if(isAActive) { setPanelActiveColor.value(chainAPanel) } { setPanelNeutralColor.value(chainAPanel) } };
    if(chainBPanel.notNil) { if(isBActive) { setPanelActiveColor.value(chainBPanel) } { setPanelNeutralColor.value(chainBPanel) } };

    statusLabel.string = "system ready";
};

// bottom-left: Choices (safe; optional)
refreshChoicesPane = {
    var sysObj, cm, builder, textLines, s;
    sysObj = ~system;
    if(sysObj.isNil) {
        s = "Choices:\n(n/a — no ~system)";
    } {
        cm = sysObj.tryPerform(\commandManager);
        builder = cm.tryPerform(\builder);
        if(builder.notNil and: { builder.tryPerform(\currentNode).notNil }) {
            textLines = builder.currentNode.children.collect({ arg child;
                var nm, fr;
                nm = child.tryPerform(\name) ? child.asString;
                fr = child.tryPerform(\fret);
                (fr.notNil).if({ ("fret " ++ fr.asString ++ " → " ++ nm) }, { nm });
            });
            s = "Choices:\n" ++ textLines.join($\n);
        } {
            s = "Choices:\n(n/a — no builder or no node)";
        };
    };
    choicesTextView.string = s;
};

// bottom-right: Messages / Next (safe; optional)
refreshMessagesPane = {
    var sysObj, cm, nextPath, base;
    base = "A[L=" ++ chainALevelLeft.round(0.01) ++ ", R=" ++ chainALevelRight.round(0.01) ++ "]   " ++
           "B[L=" ++ chainBLevelLeft.round(0.01) ++ ", R=" ++ chainBLevelRight.round(0.01) ++ "]";
    sysObj = ~system;
    cm = sysObj.tryPerform(\commandManager);
    if(cm.notNil and: { cm.respondsTo(\canonicalPathFromBuilder) }) {
        nextPath = cm.canonicalPathFromBuilder(cm.builder);
        messagesTextView.string = base ++ "\nNext: " ++ nextPath.asString;
    } {
        messagesTextView.string = base;
    };
};

// --- layout (always fit; meters between chains) ------------------------------
computeAndApplyLayout = {
    var winBounds, contentW, contentH;
    var halfW, panelY, statusY, bottomY;
    var aX, aW, bX, bW;
    var meterAX, meterBX, meterY, meterH;

    winBounds = windowRef.bounds;
    if(winBounds.isKindOf(Rect).not) {
        AppClock.sched(0.03, { computeAndApplyLayout.value; nil });
    } {
        contentW = (winBounds.width - (paddingX * 2)).max(520);
        contentH = (winBounds.height - (paddingY * 2)).max(topRowHeight + statusRowHeight + bottomRowHeight + (rowGap*3));

        halfW = ((contentW - columnGap) / 2).max(minPanelTextWidth + meterStripWidth + 16);

        panelY  = paddingY;
        statusY = panelY + topRowHeight + rowGap;
        bottomY = statusY + statusRowHeight + rowGap;

        // panel bounds
        aX = paddingX;                  aW = halfW;
        bX = paddingX + halfW + columnGap; bW = halfW;

        chainAPanel.bounds = Rect(aX, panelY, aW, topRowHeight);
        chainBPanel.bounds = Rect(bX, panelY, bW, topRowHeight);

        // meters BETWEEN chains
        meterY = panelY + 8;
        meterH = topRowHeight - 16;

        // A meters at RIGHT edge (inside A panel)
        meterAX = aX + aW - 8 - meterStripWidth;
        meterViewBetweenA.bounds = Rect(meterAX, meterY, meterStripWidth, meterH);

        // B meters at LEFT edge (inside B panel)
        meterBX = bX + 8;
        meterViewBetweenB.bounds = Rect(meterBX, meterY, meterStripWidth, meterH);

        // status row
        statusLabel.bounds = Rect(paddingX, statusY, contentW, statusRowHeight);
        statusLabel.background = Color(1.0, 0.95, 0.6); // yellow

        // bottom panes
        choicesTitleLabel.bounds  = Rect(paddingX, bottomY, halfW, 16);
        choicesTextView.bounds    = Rect(paddingX, bottomY + 18, halfW, bottomRowHeight - 20);

        messagesTitleLabel.bounds = Rect(paddingX + halfW + columnGap, bottomY, halfW, 16);
        messagesTextView.bounds   = Rect(paddingX + halfW + columnGap, bottomY + 18, halfW, bottomRowHeight - 20);
    };
};

// --- ticker ------------------------------------------------------------------
startTicker = {
    var periodSeconds, stepFunc, slowCounter;
    periodSeconds = 1.0 / framesPerSecond;
    lastWidth  = windowRef.bounds.width;
    lastHeight = windowRef.bounds.height;
    slowCounter = 0;

    stepFunc = {
        var w, h;
        readLevelsAndUpdate.value;

        // lighter updates ~5 Hz
        slowCounter = slowCounter + 1;
        if(slowCounter >= (framesPerSecond / 5)) {
            refreshChoicesPane.value;
            refreshMessagesPane.value;
            slowCounter = 0;
        };

        w = windowRef.bounds.width; h = windowRef.bounds.height;
        if((w != lastWidth) or: { h != lastHeight }) {
            computeAndApplyLayout.value;
            lastWidth = w; lastHeight = h;
        };

        meterViewBetweenA.refresh;
        meterViewBetweenB.refresh;

        AppClock.sched(periodSeconds, { if(tickerFlag == true) { stepFunc.value }; nil });
    };
    tickerFlag = true;
    AppClock.sched(0.03, { computeAndApplyLayout.value; nil });
    AppClock.sched(0.0, { stepFunc.value; nil });
};

stopTicker = { tickerFlag = nil };

// --- bring-up + construct ----------------------------------------------------
closeExistingMagicDisplayWindows.value;
ensureReceiverInstalled.value;

// start with proportions that fit on first open
windowRect = Rect(
    70, 70,
    paddingX + (minPanelTextWidth + meterStripWidth + columnGap + minPanelTextWidth + meterStripWidth) + paddingX + 40,
    paddingY + topRowHeight + rowGap + statusRowHeight + rowGap + bottomRowHeight + paddingY
);

// resizable=true, border=true -> proper title + resizable
windowRef = Window("MagicDisplayGUI — Performance HUD (v0.5.1)", windowRect, true, true);

// top row
chainAPanel       = makePanelView.value(windowRef, Rect(0,0,10,10));
chainBPanel       = makePanelView.value(windowRef, Rect(0,0,10,10));
meterViewBetweenA = makeVerticalMeterViewForA.value(windowRef, Rect(0,0,10,10));
meterViewBetweenB = makeVerticalMeterViewForB.value(windowRef, Rect(0,0,10,10));

// status row
statusLabel = StaticText(windowRef, Rect(0,0,10,10));
statusLabel.stringColor = Color.black;
statusLabel.align = \left;

// bottom row
choicesTitleLabel   = StaticText(windowRef, Rect(0,0,10,10)); choicesTitleLabel.string = "Choices"; choicesTitleLabel.stringColor = Color.black;
choicesTextView     = TextView(windowRef, Rect(0,0,10,10));  choicesTextView.editable = false; choicesTextView.background = Color(0.97,0.97,0.97);

messagesTitleLabel  = StaticText(windowRef, Rect(0,0,10,10)); messagesTitleLabel.string = "Messages / Next"; messagesTitleLabel.stringColor = Color.black;
messagesTextView    = TextView(windowRef, Rect(0,0,10,10));  messagesTextView.editable = false; messagesTextView.background = Color(0.97,0.97,0.97);

// run
windowRef.onClose_({ stopTicker.value });
windowRef.front;
startTicker.value;
windowRef
) // -> a Window
