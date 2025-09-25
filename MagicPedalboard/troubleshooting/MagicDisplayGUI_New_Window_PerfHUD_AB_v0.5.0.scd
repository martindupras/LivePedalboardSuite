// MagicDisplayGUI_New_Window_PerfHUD_AB_v0.5.0.scd
// v0.5.0
// MD 2025-09-25 17:35 BST

/*
Purpose
- Performance HUD window for live use (single, resizable "MagicDisplayGUI ..." window).
- Top row: Chain A (left) and Chain B (right) panels.
  * Active chain panel shows a green background (CURRENT inferred from Ndef.isPlaying).
  * Per-chain vertical meters (L/R) at each panel’s outer edge (A: left; B: right).
- Second row: full-width yellow status box (“system read” by default).
- Bottom-left: Choices pane (safe: reads CommandManager builder if present).
- Bottom-right: Messages/Next pane (safe: shows md/levels rate & last values; optional queued canonical).

Style
- var-first in every block/closure; descriptive lowercase names; known-good SC/Qt GUI only.
- GUI uses AppClock only; no server.sync; avoids destructive operations.
- Final expression returns -> a Window. Title starts with "MagicDisplayGUI".
*/

(
var closeExistingMagicDisplayWindows, ensureReceiverInstalled;
var windowRef, windowRect;
var paddingX, paddingY, rowGap, columnGap;
var topRowHeight, statusRowHeight, bottomRowHeight;
var borderWidth, minTextWidth, minMeterWidth;
var headerString;
var levelIds, levelsDict, framesPerSecond, fallbackThreshold, uiGamma;
var statusLabel;
var chainAPanel, chainBPanel, chainAMeterView, chainBMeterView;
var choicesTitle, choicesText, messagesTitle, messagesText;
var chainALevelLeft, chainALevelRight, chainBLevelLeft, chainBLevelRight, testLevelLeft, testLevelRight;
var displayALevelLeft, displayALevelRight, displayBLevelLeft, displayBLevelRight;
var isAActive, isBActive;
var makePanelView, makeVerticalMeterView, drawVerticalMeters, setPanelActiveColor, setPanelNeutralColor;
var readLevelsAndUpdate, refreshChoicesFromBuilder, refreshMessages;
var computeAndApplyLayout, lastWidth, lastHeight;
var startTicker, stopTicker, tickerFlag;
var identityBanner;

// === console identity (var-first ensured) ====================================
identityBanner = "=== RUN === MagicDisplayGUI_New_Window_PerfHUD_AB_v0.5.0.scd";
identityBanner.postln;

// --- constants / state -------------------------------------------------------
framesPerSecond = 30;
levelIds = (test: 1001, A: 2001, B: 2002);
levelsDict = (~md_levelsById ? IdentityDictionary.new);

// visual shaping
fallbackThreshold = 0.003;   // if A+B quiet, mirror test for display continuity (demo-safe)
uiGamma = 1.0;               // 1.0 linear; 0.7..0.5 boosts low levels

// layout metrics (tuned for iPad side-screen; adjust as needed)
paddingX = 10;
paddingY = 10;
rowGap   = 8;
columnGap= 10;

topRowHeight    = 120;       // Chain A/B row height
statusRowHeight = 26;        // yellow status row
bottomRowHeight = 160;       // bottom panes row height
borderWidth     = 1;
minTextWidth    = 180;       // minimal inner text panel width per side
minMeterWidth   = 18;        // slim vertical meter (two bars drawn inside this view)

// init values
chainALevelLeft = 0.0; chainALevelRight = 0.0;
chainBLevelLeft = 0.0; chainBLevelRight = 0.0;
testLevelLeft = 0.0;  testLevelRight  = 0.0;

displayALevelLeft = 0.0; displayALevelRight = 0.0;
displayBLevelLeft = 0.0; displayBLevelRight = 0.0;

isAActive = false; isBActive = false;

// --- helpers -----------------------------------------------------------------
closeExistingMagicDisplayWindows = {
    var existing;
    existing = Window.allWindows.select({ arg w;
        var title;
        title = w.tryPerform(\name);
        title.notNil and: { title.asString.beginsWith("MagicDisplayGUI") }
    });
    AppClock.sched(0.0, { existing.do({ arg w; w.close }); nil });
};

ensureReceiverInstalled = {
    var can;
    can = (~md_reinstallReceiver.notNil);
    if(can) { ~md_reinstallReceiver.() };
};

// simple panel with border whose background we can recolor for "active"
makePanelView = { arg parent, rect;
    var v;
    v = UserView(parent, rect);
    v.background_(Color(0.94,0.94,0.94)); // neutral; greener when active
    v.drawFunc = { arg uv;
        var b;
        b = uv.bounds;
        Pen.color = Color.gray(0.65);
        Pen.strokeRect(Rect(0.5, 0.5, b.width-1, b.height-1));
    };
    v
};

// slim vertical meter container; draw two vertical bars (L/R)
makeVerticalMeterView = { arg parent, rect;
    var v;
    v = UserView(parent, rect);
    v.background_(Color(0.92,0.92,0.92));
    v.drawFunc = { arg uv;
        drawVerticalMeters.value(uv);
    };
    v
};

drawVerticalMeters = { arg uv;
    var b, gap, barCount, oneWidth, leftVal, rightVal, leftH, rightH;
    b = uv.bounds;
    gap = 2;
    barCount = 2;
    oneWidth = ((b.width - gap) / barCount).max(3);

    // A or B values are injected by caller through display* variables
    // Decide which pair to draw by reading a tag on the view name (set below)
    if(uv.name == \metersA) {
        leftVal  = displayALevelLeft.clip(0,1).pow(uiGamma);
        rightVal = displayALevelRight.clip(0,1).pow(uiGamma);
    } {
        leftVal  = displayBLevelLeft.clip(0,1).pow(uiGamma);
        rightVal = displayBLevelRight.clip(0,1).pow(uiGamma);
    };

    leftH  = (b.height * leftVal).clip(0, b.height);
    rightH = (b.height * rightVal).clip(0, b.height);

    // backgrounds
    Pen.color = Color(0.86,0.86,0.86); Pen.addRect(Rect(0, 0, oneWidth, b.height)); Pen.fill;
    Pen.color = Color(0.86,0.86,0.86); Pen.addRect(Rect(oneWidth + gap, 0, oneWidth, b.height)); Pen.fill;

    // dynamic fills (bottom-up)
    Pen.color = Color(0.20, 0.70, 0.20); // green-ish for visibility
    Pen.addRect(Rect(0, b.height - leftH, oneWidth, leftH)); Pen.fill;
    Pen.addRect(Rect(oneWidth + gap, b.height - rightH, oneWidth, rightH)); Pen.fill;

    // borders
    Pen.color = Color.gray(0.55);
    Pen.strokeRect(Rect(0.5, 0.5, oneWidth-1, b.height-1));
    Pen.strokeRect(Rect(oneWidth + gap + 0.5, 0.5, oneWidth-1, b.height-1));
};

setPanelActiveColor = { arg uv;
    uv.background = Color(0.86, 0.97, 0.86); // soft green for "active"
};

setPanelNeutralColor = { arg uv;
    uv.background = Color(0.94, 0.94, 0.94);
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

    // demo-safe fallback: if A/B are effectively zero but test is alive, mirror test
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

    // active chain (CURRENT) visual
    isAActive = Ndef(\chainA).isPlaying; // safe, non-blocking check
    isBActive = Ndef(\chainB).isPlaying;

    if(chainAPanel.notNil and: { chainBPanel.notNil }) {
        if(isAActive) { setPanelActiveColor.value(chainAPanel) } { setPanelNeutralColor.value(chainAPanel) };
        if(isBActive) { setPanelActiveColor.value(chainBPanel) } { setPanelNeutralColor.value(chainBPanel) };
    };

    // lightweight HUD text
    statusLabel.string = "system read"; // change to "system ready" if you prefer
};

// bottom-left: print current navigation choices if CommandManager is present
refreshChoicesFromBuilder = {
    var haveSystem, cm, builder, lines, text;
    haveSystem = (~system.notNil);
    if(haveSystem.not) {
        text = "Choices:\n(n/a — no ~system)";
    } {
        cm = ~system.commandManager;
        builder = (cm.notNil).if({ cm.builder }, { nil });
        if(builder.notNil and: { builder.currentNode.notNil }) {
            lines = builder.currentNode.children.collect({ arg ch;
                ("fret " ++ ch.fret.asString ++ " → " ++ ch.name.asString)
            });
            text = "Choices:\n" ++ lines.join("\n");
        } {
            text = "Choices:\n(n/a — no builder or no node)";
        };
    };
    choicesText.string = text;
};

// bottom-right: last A/B values + optional canonical “next”
refreshMessages = {
    var cm, canonicalPath, base;
    base = "A[L=" ++ chainALevelLeft.round(0.01) ++ ",R=" ++ chainALevelRight.round(0.01) ++ "]  " ++
           "B[L=" ++ chainBLevelLeft.round(0.01) ++ ",R=" ++ chainBLevelRight.round(0.01) ++ "]";
    cm = (~system.notNil).if({ ~system.commandManager }, { nil });
    if(cm.notNil and: { cm.respondsTo(\canonicalPathFromBuilder) }) {
        canonicalPath = cm.canonicalPathFromBuilder(cm.builder);
        messagesText.string = base ++ "\nNext: " ++ canonicalPath.asString;
    } {
        messagesText.string = base;
    };
};

// --- layout ------------------------------------------------------------------
computeAndApplyLayout = {
    var w, h, contentW, contentH;
    var halfW, meterW, textW, panelY, statusY, bottomY;

    // guard window bounds
    w = windowRef.bounds.width; h = windowRef.bounds.height;
    if((w.isNumber.not) or: { h.isNumber.not }) {
        AppClock.sched(0.03, { computeAndApplyLayout.value; nil });
    } {
        contentW = (w - (paddingX * 2)).max(320);
        contentH = (h - (paddingY * 2)).max(topRowHeight + statusRowHeight + bottomRowHeight + rowGap*3);

        halfW = ((contentW - columnGap) / 2).max(minTextWidth + minMeterWidth + 20);
        meterW = minMeterWidth;                    // fixed slim meter strip
        textW  = (halfW - meterW - 10).max(minTextWidth);

        // y anchors
        panelY  = paddingY;
        statusY = panelY + topRowHeight + rowGap;
        bottomY = statusY + statusRowHeight + rowGap;

        // ---- Chain A (left) ----
        chainAPanel.bounds     = Rect(paddingX, panelY, halfW, topRowHeight);
        chainAMeterView.bounds = Rect(paddingX + 4, panelY + 8, meterW, topRowHeight - 16); // left edge (outer)
        // A text area (inside panel, to the right of meter) — if you later want chain text, add a StaticText here.

        // ---- Chain B (right) ----
        chainBPanel.bounds     = Rect(paddingX + halfW + columnGap, panelY, halfW, topRowHeight);
        chainBMeterView.bounds = Rect(paddingX + halfW + columnGap + halfW - 4 - meterW, panelY