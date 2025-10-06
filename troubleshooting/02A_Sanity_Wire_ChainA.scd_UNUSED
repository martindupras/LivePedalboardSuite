// 02A_Sanity_Wire_ChainA.scd
// v0.1.1
// MD 20250929-0948

(
// Purpose
// - Ensure a real, steady signal reaches Chain A’s bus; keep Chain B silent.
// Style
// - var-first; server ops in Server.default.bind.

var link, start;

link = {
    Ndef(\chainA) <<> Ndef(\testmelody);  // Chain A <- test source
};

start = {
    Server.default.bind({
        Ndef(\chainA).play;   // run A
        Ndef(\chainB).stop;   // keep B off for clarity
    });
    "🔗 Wired: testmelody -> chainA; chainA is playing (B is stopped).".postln;
};

link.value;
start.value;
)
