// Disable_LPDisplay_DemoAudio.scd
// v0.1.0
// MD 20251005-1633

/*
Purpose
- Stop/silence LPDisplay's internal demo audio so only MagicPedalboard audio is heard.
- Targets common demo Ndefs used by LPDisplay layout/test: \srcA \srcB \srcC \srcZ \outA \outB.
Style
- var-first; lowercase; no server.sync; Server.default.bind for proxy ops.
*/

(
var demoNames, stopNdefs, ensureSilence;

demoNames = [\srcA, \srcB, \srcC, \srcZ, \outA, \outB];

stopNdefs = {
    Server.default.bind({
        demoNames.do { |sym|
            var nd = Ndef(sym);
            if(nd.notNil, { nd.stop; });
        };
    });
};

ensureSilence = {
    Server.default.bind({
        if(Ndef(\ts0).source.isNil) { Ndef(\ts0, { Silent.ar(2) }) };
        Ndef(\ts0).ar(2);
    });
};

// do it
stopNdefs.();
ensureSilence.();

"🛑 LPDisplay demo audio stopped; \\ts0 is available for silence. Use MagicPedalboard for audio.".postln;
)
