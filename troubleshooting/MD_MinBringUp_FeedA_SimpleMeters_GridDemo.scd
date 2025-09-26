// MD_MinBringUp_FeedA_SimpleMeters_GridDemo.scd
// v0.1.2
// MD 2025-09-26 18:58 BST

/* Purpose / Style
   Purpose:
     • Loud console header + step banners so you can see it ran.
     • Clean-boot bring-up: server, single MagicDisplayGUI GridDemo window, modest-level test source.
     • Feed chain A from testmelody using your operator: Ndef(left) <<> Ndef(right).
     • Install simple raw Amplitude taps to /md/levels (A=2001, B=2002).
     • Print exactly 6 lines (1 Hz) and auto-stop; no console spam.
     • Final expression returns → a Window.
   Style:
     • Single () block; VAR-FIRST in every block/closure; ≥3-char lowercase descriptive names;
       no single-letter locals; no server.sync; AppClock-only for GUI; known-good SC syntax.
*/

(
var postBanner, freeOscIfPresent, stopRoutineIfPresent, findWindowByPrefix, ensureGridDemoWindow;
var serverRef, oscKeyLevels, reporterRoutine, linesRemaining, guiWindow, systemRef, commandManagerRef;

// —— header ————————————————————————————————————————————————————————————————
postBanner = {
    var headerText;
    headerText = "=== MD_MIN_BRINGUP_FEEDA_SIMPLEMETERS_GRIDDEMO ===";
    headerText.postln;
};

// —— helpers (VAR-FIRST inside closures) ————————————————————————————————
freeOscIfPresent = { arg keySymbol;
    var oscRef;
    oscRef = OSCdef.all.at(keySymbol);
    if(oscRef.notNil) { oscRef.free; ("MD: freed OSCdef " ++ keySymbol.asString).postln };
};

stopRoutineIfPresent = { arg routineRef, labelString;
    var canStopRoutine;
    canStopRoutine = routineRef.notNil and: { routineRef.respondsTo(\stop) };
    if(canStopRoutine) { routineRef.stop; (labelString ++ ": stopped").postln };
};

findWindowByPrefix = { arg prefixString;
    var windowsList, indexCount, indexLimit, windowRef, titleString, foundWindow;
    windowsList = Window.allWindows;
    indexCount = 0; indexLimit = windowsList.size; foundWindow = nil;
    while({ indexCount < indexLimit }, {
        windowRef = windowsList[indexCount];
        titleString = windowRef.tryPerform(\name);
        if(titleString.notNil and: { titleString.asString.beginsWith(prefixString) }) {
            foundWindow = windowRef;
            // do not use ^ ; just set foundWindow and let the closure return last expression
            indexCount = indexLimit; // break
        } {
            indexCount = indexCount + 1;
        };
    });
    foundWindow
};

ensureGridDemoWindow = {
    var oldWindow, guiObj, newWindow;
    "STEP GUI: ensuring a single MagicDisplayGUI window (GridDemo)…".postln;

    oldWindow = findWindowByPrefix.("MagicDisplayGUI");
    if(oldWindow.notNil) {
        oldWindow.close;
        "GUI: closed existing MagicDisplayGUI".postln;
    };

    guiObj = MagicDisplayGUI_GridDemo.new; // safe fallback GUI

    systemRef = ~system; // if user has a system object, bind display
    if(systemRef.notNil) {
        commandManagerRef = systemRef.commandManager;
        if(commandManagerRef.notNil and: { commandManagerRef.display.isNil }) {
            commandManagerRef.display = guiObj;
            "GUI: bound CommandManager.display to GridDemo".postln;
        };
    };

    newWindow = findWindowByPrefix.("MagicDisplayGUI");
    if(newWindow.isNil) { "⚠️ GUI: no MagicDisplayGUI window found after creation".warn };
    newWindow
};

// —— run ————————————————————————————————————————————————————————————————
postBanner.();

// Server bring-up (allowed here)
serverRef = Server.default;
"STEP S: booting server…".postln;
serverRef.waitForBoot;
"STEP S: server booted".postln;

// GUI
guiWindow = ensureGridDemoWindow.();

// Source: testmelody (modest level; generated audio only)
"STEP SRC: defining Ndef(\\testmelody)…".postln;
Server.default.bind({
    Ndef(\testmelody, {
        var triggerCtl, freqCtl, envCtl, panCtl, midiScale, indexCtl, pairSig;
        triggerCtl = Impulse.kr(2.0);
        midiScale  = [60, 62, 64, 67, 69];
        indexCtl   = Demand.kr(triggerCtl, 0, Dwhite(0, midiScale.size, inf));
        freqCtl    = Select.kr(indexCtl, midiScale).midicps;
        envCtl     = Decay2.kr(triggerCtl, 0.01, 0.40);
        panCtl     = LFNoise1.kr(0.25).range(-0.6, 0.6);
        pairSig    = Pan2.ar(SinOsc.ar(freqCtl) * envCtl * 0.18, panCtl); // modest level
        pairSig
    });
    Ndef(\testmelody).ar(2);
});

// Feed chain A from testmelody (your operator)
"STEP FEED: using Ndef(left) <<> Ndef(right): A <<> testmelody".postln;
Server.default.bind({
    Ndef(\chainA).ar(2);
    Ndef(\chainB).ar(2);
    Ndef(\chainA) <<> Ndef(\testmelody);
});

// Simple raw amplitude taps to /md/levels
"STEP TAPS: install raw amplitude taps (/md/levels A=2001, B=2002)…".postln;
oscKeyLevels = \md_levels_sniffer_finite;
freeOscIfPresent.(oscKeyLevels);

Server.default.bind({
    var rateHertz, attackSec, releaseSec, floorAmp;

    rateHertz  = 24;
    attackSec  = 0.01;
    releaseSec = 0.20;
    floorAmp   = 1e-5;

    Ndef(\chainA).filter(\mdSimpleTapA, { arg inSig;
        var inputPair, ampLeft, ampRight;
        inputPair = inSig.isArray.if({ inSig }, { [inSig, inSig] });
        ampLeft   = Amplitude.kr(inputPair[0], attackSec, releaseSec).clip(floorAmp, 1.0);
        ampRight  = Amplitude.kr(inputPair[1], attackSec, releaseSec).clip(floorAmp, 1.0);
        SendReply.kr(Impulse.kr(rateHertz), "/md/levels", [ampLeft, ampRight], 2001);
        inSig
    });

    Ndef(\chainB).filter(\mdSimpleTapB, { arg inSig;
        var inputPair, ampLeft, ampRight;
        inputPair = inSig.isArray.if({ inSig }, { [inSig, inSig] });
        ampLeft   = Amplitude.kr(inputPair[0], attackSec, releaseSec).clip(floorAmp, 1.0);
        ampRight  = Amplitude.kr(inputPair[1], attackSec, releaseSec).clip(floorAmp, 1.0);
        SendReply.kr(Impulse.kr(rateHertz), "/md/levels", [ampLeft, ampRight], 2002);
        inSig
    });
});

// Finite 6-line sniffer (auto-free)
"STEP MTR: printing 6 lines (1 Hz) then auto-stop…".postln;
linesRemaining = 6;
OSCdef(oscKeyLevels, { arg oscMessage;
    var replyId, leftVal, rightVal, meterLabel, linesDone;

    if(oscMessage.size >= 5) {
        replyId = oscMessage[2];
        leftVal  = oscMessage[3];
        rightVal = oscMessage[4];

        leftVal  = (leftVal.isNumber  and: { leftVal.isNaN.not })  .if({ leftVal.clip(0,1) }, { 0.0 });
        rightVal = (rightVal.isNumber and: { rightVal.isNaN.not }) .if({ rightVal.clip(0,1) }, { 0.0 });

        meterLabel = if(replyId == 2001) { "A" } { if(replyId == 2002) { "B" } { replyId.asString } };
        ("MDMTR: " ++ meterLabel ++ " (L,R)=(" ++ leftVal.round(0.01) ++ "," ++ rightVal.round(0.01) ++ ")").postln;

        linesRemaining = linesRemaining - 1;
        linesDone = linesRemaining <= 0;
        if(linesDone) {
            var oscRef2;
            oscRef2 = OSCdef.all.at(oscKeyLevels);
            if(oscRef2.notNil) { oscRef2.free; "MDMTR: listener freed.".postln };
        };
    };
    nil
}, "/md/levels", recvPort: NetAddr.langPort);

// Bring GUI front and return → a Window
if(guiWindow.notNil) { guiWindow.front };
guiWindow  // → a Window
)
