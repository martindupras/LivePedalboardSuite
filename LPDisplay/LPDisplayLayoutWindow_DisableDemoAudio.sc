// LPDisplayLayoutWindow_DisableDemoAudio.sc
// v0.1.0
// MD 20251005-1633

/*
Purpose
- Add a convenience method to LPDisplayLayoutWindow to silence its demo sources.
Style
- var-first; lowercase; no server.sync.
*/

+ LPDisplayLayoutWindow {
    disableDemoAudio {
        var demoNames;
        demoNames = [\srcA, \srcB, \srcC, \srcZ, \outA, \outB];
        Server.default.bind({
            demoNames.do { |sym|
                var nd = Ndef(sym);
                if(nd.notNil, { nd.stop; });
            };
            if(Ndef(\ts0).source.isNil) { Ndef(\ts0, { Silent.ar(2) }) };
            Ndef(\ts0).ar(2);
        });
        "[LPDisplay] Demo audio disabled and \\ts0 materialized.".postln;
        ^this
    }
}