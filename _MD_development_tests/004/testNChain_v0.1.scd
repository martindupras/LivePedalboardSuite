// testNChain.scd
// v0.1
// MD 20251013-1006

().play;
NChain.new;
Ndef(\sig2, {PinkNoise.ar(0.1)!2});
Ndef(\sig1, {PinkNoise.ar(0.1)!1});
Ndef(\sig0, {Silent.ar(6)});
Ndef(\sig).play;
Ndef(\sig).stop;

Ndef(\testChain).play;
Ndef(\testChain) <<> Ndef(\sig2);
Ndef(\testChain) <<> Ndef(\sig1);
Ndef(\testChain) <<> Ndef(\sig0);
