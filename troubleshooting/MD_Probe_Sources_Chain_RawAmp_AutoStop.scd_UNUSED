// MD_Probe_Sources_Chain_RawAmp_AutoStop.scd
// v0.1.0
// MD 2025-09-26 18:22 BST

/* Purpose / Style
   Purpose: Measure raw amplitudes directly at the source Ndef(\testmelody) and at the sink Ndef(\chainA)
            by creating two temporary probe Ndefs that read those proxies and SendReply their raw
            Amplitude.kr values to "/md/probe". A finite OSCdef prints exactly 6 lines and then removes
            itself and frees the probes. No GUI changes, no server.sync, single block.
   Style:   single () block; var-first in every closure; descriptive lowercase variable names (>=3 chars);
            AppClock-safe; returns nil.
*/

(
var ensureProbes, installSpy, startReporterAndCleanup;
var probeKeySource, probeKeyChain, spyKey, reporterRoutine, printCountRemaining;

// ---- configuration
printCountRemaining = 6;
probeKeySource = \md_probe_tm;    // probe for testmelody
probeKeyChain  = \md_probe_chain; // probe for chainA
spyKey         = \md_probe_spy;   // OSCdef key

// ---- 1) Create probes (server-side) that read from existing Ndefs and SendReply raw amplitudes
ensureProbes = {
    var rateHertz, attackSec, releaseSec, floorAmp;

    rateHertz  = 24;
    attackSec  = 0.01;
    releaseSec = 0.20;
    floorAmp   = 1e-5;

    Server.default.bind({
        // Probe source: reads Ndef(\testmelody).ar(2)
        Ndef(probeKeySource, {
            var srcSig, ampLeft, ampRight;
            srcSig   = Ndef(\testmelody).ar(2);  // read directly from the source proxy
            ampLeft  = Amplitude.kr(srcSig[0], attackSec, releaseSec).clip(floorAmp, 1.0);
            ampRight = Amplitude.kr(srcSig[1], attackSec, releaseSec).clip(floorAmp, 1.0);
            SendReply.kr(Impulse.kr(rateHertz), "/md/probe", [ampLeft, ampRight], 51001);
            Silent.ar(2) // silent synth (no audio output)
        }).play;  // ensure it runs on the server

        // Probe chainA: reads Ndef(\chainA).ar(2)
        Ndef(probeKeyChain, {
            var chainSig, ampLeft, ampRight;
            chainSig = Ndef(\chainA).ar(2);  // read directly from the sink proxy
            ampLeft  = Amplitude.kr(chainSig[0], attackSec, releaseSec).clip(floorAmp, 1.0);
            ampRight = Amplitude.kr(chainSig[1], attackSec, releaseSec).clip(floorAmp, 1.0);
            SendReply.kr(Impulse.kr(rateHertz), "/md/probe", [ampLeft, ampRight], 51002);
            Silent.ar(2)
        }).play;
    });

    "MDPROBE: probes created (tm=51001, chainA=51002) → /md/probe".postln;
};

// ---- 2) Spy listener (finite) that prints exactly 6 lines then frees itself and the probes
installSpy = {
    if(OSCdef.all.at(spyKey).notNil) { OSCdef.all.at(spyKey).free };

    OSCdef(spyKey, { arg oscMessage;
        var msgSize, replyId, leftVal, rightVal, lineText;

        msgSize = oscMessage.size;
        if(msgSize >= 5) {
            replyId = oscMessage[2];
            leftVal  = oscMessage[3];
            rightVal = oscMessage[4];

            // guard + clip to [0,1]
            leftVal  = (leftVal.isNumber  and: { leftVal.isNaN.not })  .if({ leftVal.clip(0,1) }, { 0.0 });
            rightVal = (rightVal.isNumber and: { rightVal.isNaN.not }) .if({ rightVal.clip(0,1) }, { 0.0 });

            lineText = case
            { replyId == 51001 } { "SRC \u2192 (L,R)=(" ++ leftVal.round(0.01) ++ "," ++ rightVal.round(0.01) ++ ")" }
            { replyId == 51002 } { "A   \u2192 (L,R)=(" ++ leftVal.round(0.01) ++ "," ++ rightVal.round(0.01) ++ ")" }
            { "ID " ++ replyId.asString ++ " \u2192 (L,R)=(" ++ leftVal.round(0.01) ++ "," ++ rightVal.round(0.01) ++ ")" };

            ("MDPROBE: " ++ lineText).postln;

            printCountRemaining = printCountRemaining - 1;
            if(printCountRemaining <= 0) {
                var spyObj;
                spyObj = OSCdef.all.at(spyKey);
                if(spyObj.notNil) { spyObj.free; "MDPROBE: spy freed".postln };

                // free probes (server-side)
                Server.default.bind({
                    if(Ndef(probeKeySource).isPlaying) { Ndef(probeKeySource).free };
                    if(Ndef(probeKeyChain ).isPlaying) { Ndef(probeKeyChain ).free };
                });
                "MDPROBE: probes freed".postln;
            };
        };
        nil
    }, "/md/probe", recvPort: NetAddr.langPort);
    "MDPROBE: spy armed (6 lines)…".postln;
};

// ---- 3) Go
ensureProbes.();
installSpy.();
nil
)
