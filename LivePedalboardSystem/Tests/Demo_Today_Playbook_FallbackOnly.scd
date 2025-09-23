// Demo_Today_Playbook_FallbackOnly.scd
// v0.1.3
// MD 2025-09-22 23:45 BST

/* Purpose
   - Hardware-independent fallback to demonstrate MagicPedalboardNew.
   - Applies canonical commands in sequence, EVEN IF hardware is connected.
   - If your adapter (~ct_applyOSCPathToMPB) is present, it is used; otherwise
     this script calls MagicPedalboardNew methods directly for /add, /setSource,
/switch, /bypass commands.
   - Uses generated audio only (no SoundIn) and enforces Option A exclusivity.

   Style
   - tilde vars ok at top level; var-first in every function/closure.
   - lowercase method names; no server.sync; Server.default.bind for Ndef ops.
   - AppClock-only UI updates; no caret returns in deferred closures.
*/

(
var gapSeconds, playlistA, playlistB,
    systemReady, pedalboardReady,
    logMessage, showGuiHint,
    ensureGeneratedSources,
    tryEnsureAdapter, adapterAvailable, applyViaAdapter,
    applyDirectToPedalboard, applyOneCommand,
    runPlaylist, stopPlaylist, startGeneration;

// ── settings ─────────────────────────────────────────────────────────────────
gapSeconds = 0.60;
playlistA  = [ "/add/delay", "/switch" ];
playlistB  = [ "/bypass/delay/on", "/bypass/delay/off", "/switch" ];

// ── guards ───────────────────────────────────────────────────────────────────
systemReady     = ~system.notNil;
pedalboardReady = systemReady and: { ~system.pedalboard.notNil };

if(systemReady.not) {
    "⚠️  Bring-up first: evaluate Start_LivePedalboardSystem.scd (Option B)".warn;
    ^nil;
};

// ── logging + GUI hint ───────────────────────────────────────────────────────
logMessage = { |text| ("[FALLBACK] " ++ text).postln };
showGuiHint = { |text|
    var canShow;
    canShow = (~system.notNil)
        and: { ~system.statusDisplay.notNil }
        and: { ~system.statusDisplay.respondsTo(\showExpectation) };
    if(canShow) { ~system.statusDisplay.showExpectation(text, 0) };
};

// ── audio sources + option A exclusivity ─────────────────────────────────────
ensureGeneratedSources = {
    Server.default.bind({
        if(Ndef(\testmelody).source.isNil) {
            Ndef(\testmelody, {
                var trig, frequencySeq, freq, env, pan;
                trig         = Impulse.kr(3.2);
                frequencySeq = Dseq([220,277.18,329.63,392,329.63,277.18,246.94], inf);
                freq         = Demand.kr(trig, 0, frequencySeq);
                env          = Decay2.kr(trig, 0.01, 0.35);
                pan          = ToggleFF.kr(trig).linlin(0,1,-0.6,0.6);
                Pan2.ar(SinOsc.ar(freq) * env * 0.25, pan)
            });
        };
        Ndef(\testmelody).ar(2);

        if(Ndef(\ts0).source.isNil) { Ndef(\ts0, { Silent.ar(2) }) };
        Ndef(\ts0).ar(2);

        // keep sinks alive at audio rate
        Ndef(\chainA).ar(2);
        Ndef(\chainB).ar(2);
    });

    if(~mpb.notNil) {
        ~mpb.setSourceCurrent(\testmelody);
        ~mpb.setSource(\testmelody);
        ~mpb.enforceExclusiveCurrentOptionA(0.1);
    };
};

// ── try to use your adapter (~ct_applyOSCPathToMPB) if available ─────────────
tryEnsureAdapter = {
    var scriptFolderPath, candidateNames, found;
    if(~ct_applyOSCPathToMPB.notNil) { ^true };

    scriptFolderPath = PathName(thisProcess.nowExecutingPath).pathOnly;
    candidateNames = [
        "adapter_CommandTree_to_MagicPedalboard.scd",
        "adapter_commandtree_to_magicpedalboard.scd"
    ];
    found = candidateNames.detect({ |leaf|
        var fullPath = scriptFolderPath +/+ leaf;
        File.exists(fullPath).if({ fullPath.load; true }, { false })
    });

    (~ct_applyOSCPathToMPB.notNil)
};
adapterAvailable = tryEnsureAdapter.();

applyViaAdapter = { |canonicalPath|
    var guiRef;
    guiRef = ~system.statusDisplay;
    // signature from your existing adapter: (path, mpb, gui)
    ~ct_applyOSCPathToMPB.(canonicalPath, ~system.pedalboard, guiRef);
};

// ── direct mapping for the demo verbs if adapter is absent ───────────────────
applyDirectToPedalboard = { |canonicalPath|
    var pathSegments, verbName, effectSymbol, sourceSymbol,
        onOffString, bypassState, pedalboardRef;

    pedalboardRef = ~system.pedalboard;
    if(pedalboardRef.isNil) { logMessage.("pedalboard missing"); ^nil };

    pathSegments = canonicalPath.asString.split($/).reject({ |s| s.size == 0 });
    if(pathSegments.size == 0) { ^nil };
    verbName = pathSegments[0].asString;

    switch(verbName,

        "add", {
            if(pathSegments.size >= 2) {
                effectSymbol = pathSegments[1].asSymbol;
                if(pedalboardRef.respondsTo(\add)) {
                    pedalboardRef.add(effectSymbol);
                }{
                    logMessage.("no pedalboard.add; skipped: " ++ canonicalPath);
                };
            }{
                logMessage.("bad /add path: " ++ canonicalPath);
            };
        },

        "setSource", {
            if(pathSegments.size >= 2) {
                sourceSymbol = pathSegments[1].asSymbol;
                if(pedalboardRef.respondsTo(\setSource)) {
                    pedalboardRef.setSource(sourceSymbol);
                }{
                    logMessage.("no pedalboard.setSource; skipped: " ++ canonicalPath);
                };
            }{
                logMessage.("bad /setSource path: " ++ canonicalPath);
            };
        },

        "switch", {
            if(pedalboardRef.respondsTo(\switchChain)) {
                pedalboardRef.switchChain(0.12);
            }{
                logMessage.("no pedalboard.switchChain; skipped: " ++ canonicalPath);
            };
        },

        "bypass", {
            if(pathSegments.size >= 3) {
                effectSymbol = pathSegments[1].asSymbol;
                onOffString  = pathSegments[2].asString.toLower;
                bypassState  = (onOffString == "on") or: { onOffString == "true" } or: { onOffString == "1" };
                // for demo: act on CURRENT; your adapter usually controls NEXT
                if(pedalboardRef.respondsTo(\bypassCurrent)) {
                    pedalboardRef.bypassCurrent(effectSymbol, bypassState);
                }{
                    if(pedalboardRef.respondsTo(\bypass)) {
                        pedalboardRef.bypass(effectSymbol, bypassState);
                    }{
                        logMessage.("no pedalboard.bypass; skipped: " ++ canonicalPath);
                    };
                };
            }{
                logMessage.("bad /bypass path: " ++ canonicalPath);
            };
        },

        { // default
            logMessage.("unhandled verb: " ++ verbName ++ " (path=" ++ canonicalPath ++ ")");
        }
    );
};

// ── unified apply: prefer adapter; fall back to direct mapping ───────────────
applyOneCommand = { |canonicalPath|
    logMessage.("apply → " ++ canonicalPath);
    if(adapterAvailable) { applyViaAdapter.(canonicalPath) } { applyDirectToPedalboard.(canonicalPath) };
    if(~procHud_update.notNil) { ~procHud_update.() }; // optional HUD refresh
};

// ── sequenced playlist runner (AppClock; cancel-safe via generation id) ──────
runPlaylist = { |listOfCanonicalPaths, gap = 0.6|
    var myGeneration, indexCounter, totalCount, stepOnce, scheduleNext;

    // bump global generation to cancel older chains
    ~fallback_gen = (~fallback_gen ? 0) + 1;
    myGeneration = ~fallback_gen;

    indexCounter = 0;
    totalCount   = listOfCanonicalPaths.size;

    stepOnce = {
        if(~fallback_gen != myGeneration) { ^nil }; // cancelled
        applyOneCommand.( listOfCanonicalPaths[indexCounter] );
        indexCounter = indexCounter + 1;
        if(indexCounter < totalCount) { scheduleNext.() } { logMessage.("done.") };
    };

    scheduleNext = {
        var delaySeconds;
        delaySeconds = gap ? 0.6;
        AppClock.sched(delaySeconds, {
            if(~fallback_gen == myGeneration) { stepOnce.() } { nil }
        });
    };

    AppClock.sched(0.0, {
        if(~fallback_gen == myGeneration) { stepOnce.() } { nil }
    });

    ^myGeneration;
};

// ── hard stop utility ────────────────────────────────────────────────────────
stopPlaylist = {
    ~fallback_gen = (~fallback_gen ? 0) + 1;
    logMessage.("stopped.");
};

// ── go ───────────────────────────────────────────────────────────────────────
showGuiHint.(
    "Fallback-only demo (adapter=" ++ adapterAvailable ++ "):\n" ++
    "A: " ++ playlistA.asString ++ "\n" ++
    "B: " ++ playlistB.asString
);
ensureGeneratedSources.();
startGeneration = runPlaylist.(playlistA, gapSeconds);

// queue playlist B after A with a tail margin
AppClock.sched((playlistA.size * gapSeconds + 1.0).max(1.0), {
    if(~fallback_gen == startGeneration) {
        runPlaylist.(playlistB, gapSeconds);
    };
    nil
});
)
