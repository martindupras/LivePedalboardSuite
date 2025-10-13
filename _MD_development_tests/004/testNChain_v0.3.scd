// testNChain.scd
// v0.3
// MD 20251013-1006

().play;
b = NChain.new(\bob);
r = NChain.new(\rita);

Ndef(\sig2, {PinkNoise.ar(0.1)!2});
Ndef(\sig1, {PinkNoise.ar(0.1)!1});
Ndef(\sig0, {Silent.ar(6)});

Ndef(\sig2).play;
Ndef(\sig2).stop;

Ndef(\bob).play;
Ndef(\bob) <<> Ndef(\sig2);
Ndef(\bob) <<> Ndef(\sig1);
Ndef(\bob) <<> Ndef(\sig0);

Ndef(\rita).play;
Ndef(\rita) <<> Ndef(\sig2);
Ndef(\rita) <<> Ndef(\sig1);
Ndef(\rita) <<> Ndef(\sig0);

b.insert("something");
r.insert("somethingelse");
