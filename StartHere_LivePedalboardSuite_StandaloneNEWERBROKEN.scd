// StartHere_LivePedalboardSuite_Standalone.scd
// v0.1.0
// MD 20250929-1024

/* Purpose / Style
   - Standalone bring-up for LivePedalboardSuite with a single MagicDisplayGUI window.
   - Shows Chain A/B contents (active chain highlighted in green).
   - Meters show end-of-chain levels at the sinks (stereo mixdown from multi-ch).
   - Other panes: System State, Choices, Incoming Commands.
   - Generated audio only (no SoundIn).
   - Sinks and processors must read from \in.ar(numChConst).
   - Exclusivity Option A: silence inactive chain at source.
   - AppClock GUI only; one window; last expression returns '-> a Window'.
   - SC style: var-first; lowercase method names; no server.sync; use Server.default.bind for server ops.
*/
//////////////////////////////////////////////////////////////

(
var numChConst, s, banner, greenActive, greyInactive;

// server / groups / busses / synths
var grpSources, grpSinks, busAin, busBin, srcA, srcB, sinkA, sinkB;

// state
var chainA, chainB, activeChain; // \A or \B
var incomingLog, choicesList;

// meters (SendPeakRMS) and GUI update
var meterA, meterB, meterOscDef, meterUpdateRateHz;
var win, viewRoot;
var txtChainA, txtChainB, viewA, viewB, metersL, metersR;
var txtSystem, txtChoices, txtIncoming;
var refreshRoutine;
var closeExistingMagicDisplayWindows, rebuildServerTree, setActiveChain, updateGuiOnce, makeWindow, cleanup, postState;

// constants / colors
numChConst = 6;
s = Server.default;

banner = {
    "====================================================".postln;
    " LIVE PEDALBOARD SUITE — STANDALONE STARTER".postln;
    " v0.1.0 — MD 2025-09-29".postln;
    "====================================================".postln;
};

greenActive = Color.fromHexString("#2ecc71"); // green
greyInactive = Color.fromHexString("#2c3e50"); // dark grey

// ---------- helpers ----------

closeExistingMagicDisplayWindows = {
    var toClose;
    toClose = Window.allWindows.select({ |w| w.name.asString.beginsWith("MagicDisplayGUI") });
    toClose.do({ |w| w.close });
};

postState = {
    var msg;
    msg = [
        "serverRunning: " ++ s.serverRunning,
        "activeChain: " ++ activeChain,
        "grpSources: " ++ (grpSources.notNil),
        "grpSinks:   " ++ (grpSinks.notNil),
        "busAin:     " ++ (busAin ? "nil"),
        "busBin:     " ++ (busBin ? "nil")
    ].join(" | ");
    msg.postln;
};

// Build or rebuild the server tree safely
rebuildServerTree = {
    var aAmp, bAmp;

    // defaults on first call
    activeChain = activeChain ? \A;

    // ensure server boot + init
    s.waitForBoot({
        s.initTree;
        s.defaultGroup.freeAll; // known state
    });

    // allocate groups in known order
    grpSources = Group.head(s);
    grpSinks   = Group.after(grpSources);

    // allocate chain input busses
    busAin = busAin ?? { Bus.audio(s, numChConst) };
    busBin = busBin ?? { Bus.audio(s, numChConst) };

    // define synthdefs (compile-time)
    SynthDef(\testHexSource, { |out = 0, amp = 0.08, base = 110|
        var sig, freqs;
        freqs = Array.fill(numChConst, { |i| base * (i + 1) });
        sig = Mix.fill(numChConst, { |i| SinOsc.ar(freqs[i]) * (amp / numChConst) });
        // spread to numChConst lines with slight variations to visualize meters
        Out.ar(out, Array.fill(numChConst, { |i| SinOsc.ar(freqs[i], 0, amp / numChConst) }));
    }).add;

    // sink: read from \in.ar(numChConst), compute meters, mix to stereo
    SynthDef(\sinkStereo, { |in = 0, amp = 1.0, replyID = 100|
        var ins, mix, left, right;
        ins = In.ar(in, numChConst);                   // REQUIRED: read from \in.ar(numChConst)
        mix = (ins.sum / numChConst) * amp;            // mono sum
        left  = mix;
        right = mix;
        //SendPeakRMS.kr([left, right], 20, 3, 0.5, replyID); // ~20 fps, window 3, decay-ish

		SendPeakRMS.kr([left, right], 20, 3, "/sendPeakRMS", replyID); // match OSCdef route

        Out.ar(0, [left, right]);                      // to hardware out (stereo)
    }).add;

    // instantiate sources and sinks in proper order + exclusivity at source
    Server.default.bind({
        // clean existing
        [srcA, srcB, sinkA, sinkB].do({ |node| node.notNil.if({ node.free; }) });

        // exclusivity
        aAmp = if(activeChain == \A, { 0.09 }, { 0.0 });
        bAmp = if(activeChain == \B, { 0.09 }, { 0.0 });

        srcA = Synth.tail(grpSources, \testHexSource, [\out, busAin, \amp, aAmp]);
        srcB = Synth.tail(grpSources, \testHexSource, [\out, busBin, \amp, bAmp]);

        sinkA = Synth.tail(grpSinks, \sinkStereo, [\in, busAin, \replyID, 100]);
        sinkB = Synth.tail(grpSinks, \sinkStereo, [\in, busBin, \replyID, 101]);
    });

    postState.value;
};

// switch active chain: Option A (silence inactive at source)
setActiveChain = { |which = \A|
    activeChain = which;
    // Update amps
    srcA.notNil.if({ srcA.set(\amp, (activeChain == \A).if(0.09, 0.0)) });
    srcB.notNil.if({ srcB.set(\amp, (activeChain == \B).if(0.09, 0.0)) });
};

// ---------- meter handling (SendPeakRMS -> GUI arrays) ----------

meterA = [0.0, 0.0];  // [L, R] end-of-chain A
meterB = [0.0, 0.0];  // [L, R] end-of-chain B
meterUpdateRateHz = 20;

meterOscDef = OSCdef(\metersStandalone, { |msg, time, addr, recvPort|
    // format: ['/sendPeakRMS', nodeID, replyID, numChannels, peak..., rms...]
    var replyID, numChannels, peakStart, rmsStart, peaks, rms, l, r;
    replyID = msg[2];
    numChannels = msg[3];
    peakStart = 4;
    rmsStart = peakStart + numChannels;
    peaks = msg.copyRange(peakStart, peakStart + numChannels - 1);
    rms   = msg.copyRange(rmsStart,  rmsStart  + numChannels - 1);
    // we meter the stereo outputs; expect numChannels == 2 here
    l = peaks[0].clip(0, 1);
    r = peaks[1].clip(0, 1);

    if(replyID == 100, { meterA = [l, r]; });
    if(replyID == 101, { meterB = [l, r]; });
}, '/sendPeakRMS', s.addr);

// ---------- GUI ----------

makeWindow = {
    var w, margin, rowH, colW, font, label;

    closeExistingMagicDisplayWindows.value;

    w = Window("MagicDisplayGUI - StartHere Standalone v0.1.0", Rect(60, 60, 780, 480)).front;
    w.alwaysOnTop_(true);
    w.view.background_(Color.fromHexString("#1e272e")); // dark
    margin = 10;
    rowH = 40;
    colW = (w.bounds.width - margin * 3) / 2;
    font = Font("Monaco", 13);

    viewRoot = UserView(w, Rect(0, 0, w.bounds.width, w.bounds.height));

    // Chain A view
    viewA = CompositeView(w, Rect(margin, margin, colW, rowH * 3));
    viewA.background_(greyInactive);

    label = StaticText(viewA, Rect(8, 4, colW - 16, 18));
    label.string = "Chain A";
    label.align = \left;
    label.stringColor = Color.white;
    label.font = font;

    txtChainA = StaticText(viewA, Rect(8, 22, colW - 16, rowH * 2 - 24));
    txtChainA.stringColor = Color.white;
    txtChainA.font = font;

    // Chain B view
    viewB = CompositeView(w, Rect(colW + margin * 2, margin, colW, rowH * 3));
    viewB.background_(greyInactive);

    label = StaticText(viewB, Rect(8, 4, colW - 16, 18));
    label.string = "Chain B";
    label.align = \left;
    label.stringColor = Color.white;
    label.font = font;

    txtChainB = StaticText(viewB, Rect(8, 22, colW - 16, rowH * 2 - 24));
    txtChainB.stringColor = Color.white;
    txtChainB.font = font;

    // Meters (end-of-chain stereo)
    metersL = LevelIndicator(w, Rect(margin, margin + rowH * 3 + 10, w.bounds.width - margin * 2, 18))
        .warning_(0.7)
        .critical_(0.9);
    metersR = LevelIndicator(w, Rect(margin, margin + rowH * 3 + 10 + 24, w.bounds.width - margin * 2, 18))
        .warning_(0.7)
        .critical_(0.9);

    // System State
    txtSystem = StaticText(w, Rect(margin, margin + rowH * 3 + 10 + 24 + 30, w.bounds.width - margin * 2, 18));
    txtSystem.stringColor = Color.white;
    txtSystem.font = font;

    // Choices
    txtChoices = StaticText(w, Rect(margin, margin + rowH * 3 + 10 + 24 + 30 + 24, w.bounds.width - margin * 2, 18));
    txtChoices.stringColor = Color.fromHexString("#bdc3c7");
    txtChoices.font = font;

    // Incoming commands
    txtIncoming = StaticText(w, Rect(margin, margin + rowH * 3 + 10 + 24 + 30 + 24 + 24, w.bounds.width - margin * 2, 120));
    txtIncoming.stringColor = Color.fromHexString("#95a5a6");
    txtIncoming.font = font;

    // Keyboard handlers
    w.onKeyDown_({ |view, char, mod, uni, keycode|
        var sChar;
        sChar = char.asString;
        if(sChar == "a") { setActiveChain.value(\A); incomingLog = incomingLog.add("key:a"); };
        if(sChar == "b") { setActiveChain.value(\B); incomingLog = incomingLog.add("key:b"); };
        if(sChar == "r") { rebuildServerTree.value; incomingLog = incomingLog.add("key:r (rebuild)"); };
        if(sChar == "q") { w.close; };
    });

    w.onClose_({
        cleanup.value;
    });

    w;
};

updateGuiOnce = {
    var ca, cb, meters;
    // Chain contents (Phase 1: placeholders; Phase 2: wire real arrays)
    ca = chainA.collect(_.asString).join("  →  ");
    cb = chainB.collect(_.asString).join("  →  ");
    txtChainA.string = ca;
    txtChainB.string = cb;

    // Active chain highlight
    if(activeChain == \A) {
        viewA.background = greenActive;
        viewB.background = greyInactive;
    } {
        viewA.background = greyInactive;
        viewB.background = greenActive;
    };

    // Meters show end-of-chain for active chain
    meters = if(activeChain == \A, { meterA }, { meterB });
    metersL.value = meters[0].clip(0, 1);
    metersR.value = meters[1].clip(0, 1);

    // System State
    txtSystem.string = ("State: serverRunning=" ++ s.serverRunning ++
        " | activeChain=" ++ activeChain ++
        " | groups=(" ++ grpSources.notNil ++ "," ++ grpSinks.notNil ++ ")");

    // Choices
    txtChoices.string = "Choices: [a]→Chain A, [b]→Chain B, [r]→Rebuild, [q]→Close";

    // Incoming
    txtIncoming.string = "Incoming: " ++ incomingLog.join("  •  ");
};

cleanup = {
    // stop GUI refresh
    refreshRoutine.notNil.if({
        refreshRoutine.stop;
        refreshRoutine = nil;
    });
    // remove OSCdef
    OSCdef(\metersStandalone).free;

    // free nodes and busses
    Server.default.bind({
        [srcA, srcB, sinkA, sinkB].do({ |node| node.notNil.if({ node.free }) });
    });
    [busAin, busBin].do({ |b| b.notNil.if({ b.free }) });

    // reset locals
    srcA = nil; srcB = nil; sinkA = nil; sinkB = nil; busAin = nil; busBin = nil;
};

// ---------- bring-up ----------

banner.value;

// default chain contents (Phase 1 placeholders)
chainA = [\guitar, \tremolo, \delay, \destination];
chainB = [\guitar, \flanger, \reverb, \destination];
incomingLog = List.new;
choicesList = ["a:ChainA", "b:ChainB", "r:Rebuild", "q:Close"];

// initial active chain
activeChain = \A;

// server tree
rebuildServerTree.value;

// window
win = makeWindow.value;

// start GUI refresh via AppClock
refreshRoutine = Routine({
    var period;
    period = 1.0 / meterUpdateRateHz;
    loop {
        { updateGuiOnce.value; }.defer;  // always AppClock for GUI
        period.wait;
    }
}).play(AppClock);

// return the window (ensure '-> a Window')
win;
)
