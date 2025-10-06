// Report_ChainPlayFlags.scd
// v0.1.0
// MD 20250923-1032

(
/* Purpose
   - Print whether Ndef(\chainA) and Ndef(\chainB) are playing.
   Style
   - var-first; lowercase; no server.sync; .scd-safe (no caret).
*/

var isChainAPlaying, isChainBPlaying;

isChainAPlaying = Ndef(\chainA).isPlaying;
isChainBPlaying = Ndef(\chainB).isPlaying;

("[PLAY] chainA=" ++ isChainAPlaying ++ "  chainB=" ++ isChainBPlaying).postln;
)
