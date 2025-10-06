// MagicDisplayGUI_NewPath_Step2_WindowAndTicker.scd
// v0.2.0
// MD timestamp: 2025-09-25
/* Purpose
   - Build a robust single-window GUI that follows the window patterns you used in MagicPedalboard-WindowDisplayExamples:
     * one window whose name starts with "MagicDisplayGUI"
     * no FlowLayout
     * AppClock-only refresh loop
     * LevelIndicators for meters
   - Buttons call the public Step 1 tilde helpers (~md_startTestSource, ~md_stopTestSource).

   Style
   - var-first in every block; no non-local returns (^).
   - descriptive lowercase variables; LevelIndicator values in [0..1].
*/

(
var closeExistingMagicDisplayWindows, ampToDbString, clampOrDefault, buildWindow, startTicker, stopTicker, mdGuiOpen, mdGuiClose;

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

buildWindow = {
    var window, content, titleString, levelLeft, levelRight, labelLeft, labelRight, labelTitle, buttonRowY, startButton, stopButton, barWidth, barHeight;

    titleString = "MagicDisplayGUI — New Path (Step 2)";

    window = Window.new(titleString, Rect(60, 60, 420, 220), resizable: false);
    content = CompositeView.new(window, window.view.bounds);
    content.background = Color.black;

    // title
    labelTitle = StaticText(content, Rect(16, 12, 388, 22));
    labelTitle.string = "Magic Display (AppClock meters, private bus)";
    labelTitle.stringColor = Color.white;
    labelTitle.background = Color.clear;
    labelTitle.align = \left;

    // level bars
    barWidth = 26;
    barHeight = 140;

    levelLeft = LevelIndicator(content, Rect(40, 44, barWidth, barHeight));
    levelLeft.warning = (-6).dbamp;
    levelLeft.critical = (-3).dbamp;

    levelRight = LevelIndicator(content, Rect(100, 44, barWidth, barHeight));
    levelRight.warning = (-6).dbamp;
    levelRight.critical = (-3).dbamp;

    // db readouts
    labelLeft = StaticText(content, Rect(36, 190, 60, 18));
    labelLeft.string = "-inf dB";
    labelLeft.stringColor = Color.gray(0.85);
    labelLeft.background = Color.clear;
    labelLeft.align = \center;

    labelRight = StaticText(content, Rect(96, 190, 60, 18));
    labelRight.string = "-inf dB";
    labelRight.stringColor = Color.gray(0.85);
    labelRight.background = Color.clear;
    labelRight.align = \center;

    // control buttons (call Step 1 helpers if present)
    buttonRowY = 44;

    startButton = Button(content, Rect(200, buttonRowY, 180, 28));
    startButton.states = [["Start Test Source", Color.white, Color.green(0.6)]];
    startButton.action = {
        var ok;
        ok = true;
        if (~md_startTestSource.notNil) {
            ~md_startTestSource.value;
        } {
            "Start function (~md_startTestSource) not found. Run Step 1 first.".postln;
        };
        ok;
    };

    stopButton = Button(content, Rect(200, buttonRowY + 36, 180, 28));
    stopButton.states = [["Stop Test Source", Color.white, Color.red(0.5)]];
    stopButton.action = {
        var ok;
        ok = true;
        if (~md_stopTestSource.notNil) {
            ~md_stopTestSource.value;
        } {
            "Stop function (~md_stopTestSource) not found. Run Step 1 first.".postln;
        };
        ok;
    };

    // store references for the ticker
    ~mdGui_levelLeft = levelLeft;
    ~mdGui_levelRight = levelRight;
    ~mdGui_labelLeft = labelLeft;
    ~mdGui_labelRight = labelRight;

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

    period = 1 / 30; // ~30 Hz

    tickerRoutine = Routine({
        var running, leftVal, rightVal, leftDb, rightDb, levelArray;

        running = true;

        while { running } {
            levelArray = ~levels;

            leftVal = clampOrDefault.value(levelArray, 0, 0.0);
            rightVal = clampOrDefault.value(levelArray, 1, 0.0);

            leftDb = ampToDbString.value(leftVal);
            rightDb = ampToDbString.value(rightVal);

            if (~mdGui_levelLeft.notNil) {
                ~mdGui_levelLeft.value = leftVal;
            };
            if (~mdGui_levelRight.notNil) {
                ~mdGui_levelRight.value = rightVal;
            };
            if (~mdGui_labelLeft.notNil) {
                ~mdGui_labelLeft.string = leftDb;
            };
            if (~mdGui_labelRight.notNil) {
                ~mdGui_labelRight.string = rightDb;
            };

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
    if (~mdGui_window.notNil) {
        ~mdGui_window.close;
        ~mdGui_window = nil;
    };
    ok;
};

// ---------- run ----------
mdGuiOpen.value;

// Later: mdGuiClose.value;
)
