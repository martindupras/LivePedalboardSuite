//Fallback_Diag_OneShot_Verbose.scd
//v0.1.3
//MD 20250923-1523

// Purpose
// - Trace exactly where the fallback path stalls, using ONLY known-good SC constructs.
// - Sequence (with logs): /add/delay → /switch → /bypass/delay/on → /bypass/delay/off → /switch
// Style
// - var-first in EVERY block/closure; AppClock for GUI; Server.default.bind for Ndef ops;
// - no server.sync; generated audio only; zero SoundIn; no unknown Server selectors.

(
var logDiag, postKeyVals, describeEnv;
var serverReady, systemReady, pedalboardRef, guiRef;
var ensureGeneratedSources, tryEnsureAdapter, adapterAvailable;
var applyViaAdapter, applyDirectToPedalboard, applyOneCommand;
var runSequence, verifyEnd;

// ----- logger helpers (var-first) -----
logDiag = { |textString|
    var lineText;
    lineText = "[FDIAG] " ++ textString.asString;
    lineText.postln;
};

postKeyVals = { |labelString, dictLike|
    var keys, i, key, line;
    keys = dictLike.keys.asArray;
    (labelString.asString).postln;
    i = 0;
    while({ i < keys.size }, {
        key  = keys[i];
        line = "  " ++ key.asString ++ ": " ++ dictLike[key].asString;
        line.postln;
        i = i + 1;
    });
};

// ----- environment description (no unknown selectors) -----
describeEnv = {
    var s, sysOk, mpbOk, guiOk, env;
    s = Server.default;
    sysOk = (~system.notNil);
    mpbOk = sysOk and: { ~system.pedalboard.notNil };
    guiOk = sysOk and: { ~system.statusDisplay.notNil };
    env = (
        serverRunning: s.serverRunning,
        systemPresent: sysOk,
        pedalboardPresent: mpbOk,
        guiPresent: guiOk,
        adapterFnPresent: (~ct_applyOSCPathToMPB.notNil)
    );
    postKeyVals.("FDIAG: environment", env);
};

// ----- guards (no boot here; we only report) -----
logDiag.("ENTER (one-shot verbose).");
describeEnv.value;

serverReady = Server.default.serverRunning;
if(serverReady.not) {
    logDiag.("⚠️ Server not running. Please run Start/bring-up first; aborting diag.");
    ^nil;
};

systemReady = (~system.notNil) and: { ~system.pedalboard.notNil };
if(systemReady.not) {
    logDiag.("⚠️ ~system or ~system.pedalboard is nil. Run Start_LivePedalboardSystem.scd (Option B).");
    describeEnv.value;
    ^nil;
};

pedalboardRef = ~system.pedalboard;
guiRef        = ~system.statusDisplay;

// ----- 1) ensure generated sources/sinks exist (stereo) -----
ensureGeneratedSources = {
    var didDefine, defineAll;
    didDefine = false;
    logDiag.("ensureGeneratedSources: begin");
    defineAll = {
        var madeAny, needMelody, needSilent;
        madeAny     = false;
        needMelody  = Ndef(\testmelody).source.isNil;
        needSilent  = Ndef(\ts0).source.isNil;

        if(needMelody) {
            Ndef(\testmelody, {
                var trig, sequence, freq, env, pan;
                trig     = Impulse.kr(3.2);
                sequence = Dseq([220,277.18,329.63,392,329.63,277.18,246.94], inf);
                freq     = Demand.kr(trig, 0, sequence);
                env      = Decay2.kr(trig, 0.01, 0.35);
                pan      = ToggleFF.kr(trig).linlin(0, 1, -0.6, 0.6);
                Pan2.ar(SinOsc.ar(freq) * env * 0.25, pan)
            });
            madeAny = true;
        };
        Ndef(\testmelody).ar(2);

        if(needSilent) {
            Ndef(\ts0, { Silent.ar(2) });
            madeAny = true;
        };
        Ndef(\ts0).ar(2);

        // keep sinks alive at audio rate (no source overwrite here)
        Ndef(\chainA).ar(2);
        Ndef(\chainB).ar(2);
        madeAny;
    };
    Server.default.bind({ didDefine = defineAll.value; });
    logDiag.("ensureGeneratedSources: createdAny=" ++ didDefine);

    if(pedalboardRef.respondsTo(\setSourceCurrent)) {
        pedalboardRef.setSourceCurrent(\testmelody);
        logDiag.("setSourceCurrent(\\testmelody) applied.");
    }{
        logDiag.("⚠️ pedalboard.setSourceCurrent missing.");
    };
    if(pedalboardRef.respondsTo(\enforceExclusiveCurrentOptionA)) {
        pedalboardRef.enforceExclusiveCurrentOptionA(0.1);
        logDiag.("enforceExclusiveCurrentOptionA(0.1) applied.");
    }{
        logDiag.("⚠️ pedalboard.enforceExclusiveCurrentOptionA missing.");
    };
    logDiag.("ensureGeneratedSources: end");
};

// ----- 2) adapter detection (prefer adapter) -----
tryEnsureAdapter = {
    var haveAdapter, adapterPath, exists;
    haveAdapter = (~ct_applyOSCPathToMPB.notNil);
    logDiag.("adapter present at entry? " ++ haveAdapter);
    if(haveAdapter) { ^true };
    adapterPath = (Platform.userExtensionDir
        ++ "/LivePedalboardSuite/Magicpedalboard/adapter_CommandTree_to_MagicPedalboard.scd").standardizePath;
    exists = File.exists(adapterPath);
    postKeyVals.("FDIAG: adapter path check", (path: adapterPath, exists: exists));
    if(exists) {
        adapterPath.load;
        haveAdapter = (~ct_applyOSCPathToMPB.notNil);
        logDiag.("adapter loaded from disk → present=" ++ haveAdapter);
        ^haveAdapter;
    }{
        logDiag.("adapter not found on disk; will use direct mapping.");
        ^false;
    };
};

adapterAvailable = tryEnsureAdapter.value;

// ----- 3) application modes (adapter vs direct), both verbose -----
applyViaAdapter = { |canonicalPath|
    var canShow;
    ("[FDIAG] applyViaAdapter → " ++ canonicalPath).postln;
    ~ct_applyOSCPathToMPB.(canonicalPath, pedalboardRef, guiRef);
    canShow = guiRef.notNil and: { guiRef.respondsTo(\showExpectation) };
    if(canShow) { guiRef.showExpectation("Sent: " ++ canonicalPath, 0) };
};

applyDirectToPedalboard = { |canonicalPath|
    var segments, verb, effectKey, sourceKey, onOffStr, stateBool, canShow;
    segments = canonicalPath.asString.split($/).reject({ |s| s.size == 0 });
    if(segments.size == 0) {
        logDiag.("applyDirect: empty path?");
        ^nil;
    };
    verb = segments[0].asString;
    ("[FDIAG] applyDirect → " ++ canonicalPath ++ " (verb=" ++ verb ++ ")").postln;

    switch(verb,
        "add", {
            if(segments.size >= 2 and: { pedalboardRef.respondsTo(\add) }) {
                effectKey = segments[1].asSymbol;
                ("[FDIAG] pedalboard.add(" ++ effectKey ++ ")").postln;
                pedalboardRef.add(effectKey);
            }{
                logDiag.("⚠️ pedalboard.add missing.");
            };
        },
        "setSource", {
            if(segments.size >= 2 and: { pedalboardRef.respondsTo(\setSource) }) {
                sourceKey = segments[1].asSymbol;
                ("[FDIAG] pedalboard.setSource(" ++ sourceKey ++ ")").postln;
                pedalboardRef.setSource(sourceKey);
            }{
                logDiag.("⚠️ pedalboard.setSource missing.");
            };
        },
        "switch", {
            if(pedalboardRef.respondsTo(\switchChain)) {
                "[FDIAG] pedalboard.switchChain(0.12)".postln;
                pedalboardRef.switchChain(0.12);
            }{
                logDiag.("⚠️ pedalboard.switchChain missing.");
            };
        },
        "bypass", {
            if(segments.size >= 3) {
                effectKey = segments[1].asSymbol;
                onOffStr  = segments[2].asString.toLower;
                stateBool = (onOffStr == "on") or: { onOffStr == "true" } or: { onOffStr == "1" };
                if(pedalboardRef.respondsTo(\bypassCurrent)) {
                    ("[FDIAG] pedalboard.bypassCurrent(" ++ effectKey ++ ", " ++ stateBool ++ ")").postln;
                    pedalboardRef.bypassCurrent(effectKey, stateBool);
                }{
                    if(pedalboardRef.respondsTo(\bypass)) {
                        ("[FDIAG] pedalboard.bypass(" ++ effectKey ++ ", " ++ stateBool ++ ")").postln;
                        pedalboardRef.bypass(effectKey, stateBool);
                    }{
                        logDiag.("⚠️ pedalboard.bypass* missing.");
                    };
                };
            }{
                logDiag.("⚠️ bypass path too short: " ++ canonicalPath);
            };
        },
        {
            logDiag.("⚠️ verb not handled in direct mapping: " ++ verb);
        }
    );

    canShow = guiRef.notNil and: { guiRef.respondsTo(\showExpectation) };
    if(canShow) { guiRef.showExpectation("Sent: " ++ canonicalPath, 0) };
    if(~procHud_update.notNil) { ~procHud_update.() };
};

applyOneCommand = { |canonicalPath|
    var useAdapter;
    useAdapter = adapterAvailable;
    ("[FDIAG] applyOneCommand: " ++ canonicalPath ++ " (usingAdapter=" ++ useAdapter ++ ")").postln;
    if(useAdapter) { applyViaAdapter.value(canonicalPath) }{ applyDirectToPedalboard.value(canonicalPath) };
};

// ----- 4) sequencer with AppClock (each hop logged) -----
runSequence = {
    var seq, idx, total, gapSec, scheduleNext, stepOnce;
    seq    = [ "/add/delay", "/switch", "/bypass/delay/on", "/bypass/delay/off", "/switch" ];
    idx    = 0;
    total  = seq.size;
    gapSec = 0.60;

    logDiag.("sequence size=" ++ total ++ " gapSec=" ++ gapSec);

    stepOnce = {
        var pathNow;
        if(idx >= total) {
            logDiag.("sequence complete; scheduling verify …");
            AppClock.sched(0.9, { verifyEnd.value; nil });
            ^nil;
        };
        pathNow = seq[idx];
        logDiag.("STEP " ++ (idx+1) ++ " / " ++ total ++ " → " ++ pathNow);
        applyOneCommand.value(pathNow);
        idx = idx + 1;
        scheduleNext.value;
    };

    scheduleNext = {
        AppClock.sched(gapSec, {
            logDiag.("… tick → next step");
            stepOnce.value;
            nil
        });
    };

    AppClock.sched(0.0, {
        logDiag.("kickoff on AppClock");
        stepOnce.value;
        nil
    });
};

// ----- 5) final verify/summary -----
verifyEnd = {
    var aPlay, bPlay, havePrint;
    aPlay = Ndef(\chainA).isPlaying;
    bPlay = Ndef(\chainB).isPlaying;
    logDiag.("[PLAY] A=" ++ aPlay ++ " B=" ++ bPlay);
    havePrint = pedalboardRef.respondsTo(\printChains);
    if(havePrint) {
        logDiag.("pedalboard.printChains:");
        pedalboardRef.printChains;
    }{
        logDiag.("⚠️ pedalboard.printChains missing.");
    };
};

// ----- go -----
logDiag.("begin run");
ensureGeneratedSources.value;
adapterAvailable = tryEnsureAdapter.value; // log after sources too
logDiag.("adapterAvailable=" ++ adapterAvailable);
runSequence.value;
)
