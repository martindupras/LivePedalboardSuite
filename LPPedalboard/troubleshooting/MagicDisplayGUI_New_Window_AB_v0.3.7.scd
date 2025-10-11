// MagicDisplayGUI_New_Window_AB_v0.3.7.scd
// v0.3.7
// MD timestamp: 2025-09-25

/* Purpose
   - Open one "MagicDisplayGUI ..." window with FOUR meters:
       A-L, A-R (replyID 2001), B-L, B-R (replyID 2002)
     and fall back to the default test probe (replyID 1001) if A/B not attached.
   - AppClock-only ticker; HUD shows rx age (global heartbeat).

   Style
   - var-first in every block; no non-local returns (^).
   - descriptive lowercase; no FlowLayout; top-left anchored layout.
*/

(
var closeExistingMagicDisplayWindows, ampToDbString, clampOrDefault,
    getLevelsForId, buildWindow, startTicker, stopTicker, mdGuiOpen, mdGuiClose;

closeExistingMagicDisplayWindows = {
    var windows, i, w, nameString;
    windows = Window.allWindows;
    i = 0;
    while { i < windows.size } {
        w = windows[i];
        nameString = w.name.asString;
        if (nameString.beginsWith("MagicDisplayGUI")) {
            w.close;
        };
        i = i + 1;
    };
};

ampToDbString = { |amp|
    var safeAmp, db;
    safeAmp = amp.max(1.0e-6);
    db = safeAmp.ampdb.round(0.1);
    db.asString ++ " dB";
};

clampOrDefault = { |array, index, defaultValue|
    var value;
    value = defaultValue;
    if (array.notNil) {
        if (index >= 0 and: { index < array.size }) {
            value = array[index].clip(0.0, 1.0);
        };
    };
    value;
};

getLevelsForId = { |replyID, fallback|
    var dict, arr;
    dict = ~md_levelsById;
    arr = nil;
    if (dict.notNil) {
        arr = dict[replyID];
    };
    if (arr.isNil) {
        arr = fallback;
    };
    arr;
};

buildWindow = {
    var window, content, titleString,
        labelA, aLeft, aRight, aDbL, aDbR,
        labelB, bLeft, bRight, bDbL, bDbR,
        statusA, statusB,
        startButton, stopButton,
        barWidth, barHeight;

    titleString = "MagicDisplayGUI — A/B Window (v0.3.7)";

    window = Window.new(titleString, Rect(60, 60, 560, 260), resizable: false);
    content = CompositeView.new(window, window.view.bounds);
    content.background = Color.black;

    // A section
    labelA = StaticText(content, Rect(16, 12, 240, 22));
    labelA.string = "Chain A (replyID 2001)";
    labelA.stringColor = Color.white;
    labelA.background = Color.clear;
    labelA.align = \left;

    // B section
    labelB = StaticText(content, Rect(292, 12, 240, 22));
    labelB.string = "Chain B (replyID 2002)";
    labelB.stringColor = Color.white;
    labelB.background = Color.clear;
    labelB.align = \left;

    barWidth = 26;
    barHeight = 160;

    // A meters
    aLeft  = LevelIndicator(content, Rect(40,  44, barWidth, barHeight));
    aRight = LevelIndicator(content, Rect(100, 44, barWidth, barHeight));
    aLeft.warning = (-6).dbamp; aLeft.critical = (-3).dbamp;
    aRight.warning = (-6).dbamp; aRight.critical = (-3).dbamp;

    aDbL = StaticText(content, Rect(32, 210, 60, 18));
    aDbL.string = "-inf dB";
    aDbL.stringColor = Color.gray(0.85);
    aDbL.background = Color.clear;
    aDbL.align = \center;

    aDbR = StaticText(content, Rect(92, 210, 60, 18));
    aDbR.string = "-inf dB";
    aDbR.stringColor = Color.gray(0.85);
    aDbR.background = Color.clear;
    aDbR.align = \center;

    // B meters
    bLeft  = LevelIndicator(content, Rect(316, 44, barWidth, barHeight));
    bRight = LevelIndicator(content, Rect(376, 44, barWidth, barHeight));
    bLeft.warning = (-6).dbamp; bLeft.critical = (-3).dbamp;
    bRight.warning = (-6).dbamp; bRight.critical = (-3).dbamp;

    bDbL = StaticText(content, Rect(308, 210, 60, 18));
    bDbL.string = "-inf dB";
    bDbL.stringColor = Color.gray(0.85);
    bDbL.background = Color.clear;
    bDbL.align = \center;

    bDbR = StaticText(content, Rect(368, 210, 60, 18));
    bDbR.string = "-inf dB";
    bDbR.stringColor = Color.gray(0.85);
    bDbR.background = Color.clear;
    bDbR.align = \center;

    // rx age
    statusA = StaticText(content, Rect(180, 44, 100, 18));
    statusA.string = "A rx: —";
    statusA.stringColor = Color.gray(0.85);
    statusA.background = Color.clear;
    statusA.align = \left;

    statusB = StaticText(content, Rect(456, 44, 100, 18));
    statusB.string = "B rx: —";
    statusB.stringColor = Color.gray(0.85);
    statusB.background = Color.clear;
    statusB.align = \left;

    // test controls (optional)
    startButton = Button(content, Rect(180, 80, 100, 28));
    startButton.states = [["Start Test", Color.white, Color.green(0.6)]];
    startButton.action = {
        var ok;
        ok = true;
        if (~md_startTestSource.notNil) { ~md_startTestSource.value; } { "Run bring-up file first.".postln; };
        ok;
    };

    stopButton = Button(content, Rect(180, 114, 100, 28));
    stopButton.states = [["Stop Test", Color.white, Color.red(0.5)]];
    stopButton.action = {
        var ok;
        ok = true;
        if (~md_stopTestSource.notNil) { ~md_stopTestSource.value; } { "Run bring-up file first.".postln; };
        ok;
    };

    // store refs
    ~mdGui_aLeft = aLeft;     ~mdGui_aRight = aRight;   ~mdGui_aDbL = aDbL;   ~mdGui_aDbR = aDbR;
    ~mdGui_bLeft = bLeft;     ~mdGui_bRight = bRight;   ~mdGui_bDbL = bDbL;   ~mdGui_bDbR = bDbR;
    ~mdGui_statusA = statusA; ~mdGui_statusB = statusB;

    window.onClose_({
        var ok;
        ok = true;
        stopTicker.value;
        ~mdGui_window = nil;
        ok;
    });

    window.front;

    ~mdGui_window = window;

    window;
};

startTicker = {
    var period, tickerRoutine;

    if (~mdGui_ticker.notNil) {
        ~mdGui_ticker.stop;
        ~mdGui_ticker = nil;
    };

    period = 1 / 30;

    tickerRoutine = Routine({
        var running,
            aLevels, bLevels, testLevels,
            aL, aR, bL, bR,
            aDbL, aDbR, bDbL, bDbR,
            age, lastAt;

        running = true;

        while { running } {
            testLevels = getLevelsForId.value(1001, [0.0, 0.0]);
            aLevels = getLevelsForId.value(2001, testLevels);
            bLevels = getLevelsForId.value(2002, testLevels);

            aL = clampOrDefault.value(aLevels, 0, 0.0);
            aR = clampOrDefault.value(aLevels, 1, 0.0);
            bL = clampOrDefault.value(bLevels, 0, 0.0);
            bR = clampOrDefault.value(bLevels, 1, 0.0);

            aDbL = ampToDbString.value(aL);
            aDbR = ampToDbString.value(aR);
            bDbL = ampToDbString.value(bL);
            bDbR = ampToDbString.value(bR);

            if (~mdGui_aLeft.notNil)  { ~mdGui_aLeft.value  = aL; };
            if (~mdGui_aRight.notNil) { ~mdGui_aRight.value = aR; };
            if (~mdGui_bLeft.notNil)  { ~mdGui_bLeft.value  = bL; };
            if (~mdGui_bRight.notNil) { ~mdGui_bRight.value = bR; };

            if (~mdGui_aDbL.notNil) { ~mdGui_aDbL.string = aDbL; };
            if (~mdGui_aDbR.notNil) { ~mdGui_aDbR.string = aDbR; };
            if (~mdGui_bDbL.notNil) { ~mdGui_bDbL.string = bDbL; };
            if (~mdGui_bDbR.notNil) { ~mdGui_bDbR.string = bDbR; };

            lastAt = if (~md_lastLevelAt.notNil) { ~md_lastLevelAt } { 0.0 };
            age = (Main.elapsedTime - lastAt).max(0.0).round(0.01);

            if (~mdGui_statusA.notNil) { ~mdGui_statusA.string = "A rx: " ++ age.asString ++ " s"; };
            if (~mdGui_statusB.notNil) { ~mdGui_statusB.string = "B rx: " ++ age.asString ++ " s"; };

            period.yield;
            running = (~mdGui_window.notNil);
        };
    });

    ~mdGui_ticker = tickerRoutine.play(AppClock);

    true;
};

stopTicker = {
    var ok;
    ok = true;
    if (~mdGui_ticker.notNil) {
        ~mdGui_ticker.stop;
        ~mdGui_ticker = nil;
    };
    ok;
};

mdGuiOpen = {
    var window;
    closeExistingMagicDisplayWindows.value;
    window = buildWindow.value;
    startTicker.value;
    window;
};

mdGuiClose = {
    var ok;
    ok = true;
    stopTicker.value;
    if (~mdGui_window.notNil) { ~mdGui_window.close; ~mdGui_window = nil; };
    ok;
};

// ---------- Open the window (returns -> a Window) ----------
mdGuiOpen.value;
)
