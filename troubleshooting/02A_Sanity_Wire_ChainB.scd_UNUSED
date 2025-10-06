// 02A_Sanity_Wire_ChainB.scd
// v0.1.0
// MD 20250929-1010

(
// Purpose
// - Route the same centered pulse source to chainB and play B (A can remain on).
// Style
// - var-first; server ops in Server.default.bind.

var link, start;

link = {
    Ndef(\chainB) <<> Ndef(\testmelody);   // Chain B <- test source
};

start = {
    Server.default.bind({
        Ndef(\chainB).play;                // run B
        // (leave A as-is; you can stop it if you want: Ndef(\chainA).stop)
    });
    "🔗 Wired: testmelody -> chainB; chainB is playing.".postln;
};

link.value;
start.value;
)
