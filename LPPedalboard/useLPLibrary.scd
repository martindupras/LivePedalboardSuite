// useLPLibrary.scd
// v1.0
// MD 20251016-1330

// just simple ways to illustrate how this LPLibrary works.

// NOTE: possible plan to supersede LPLibrary with NdefMaker class which might be simpler to test and maintain.


~lib = LPLibrary.new;

//~lib.inspect
//~lib.class.dumpInterface;
//~lib.get(\tremolo);

~func = ~lib.get(\delay); // works but ONLY MONO -- fix this!

Ndef(\pink).play;
Ndef(\pink,{ PinkNoise.ar(0.2)!2});
Ndef(\pink).stop;

(
Ndef(\passme).reshaping_(\elastic).source = {
			var sig;
			sig = \in.ar(0 ! 2); // 2ch
			sig * 0.5
};
)

Ndef(\passme, ~func);

Ndef(\passme) <<> Ndef(\pink);

Ndef(\passme).play;
Ndef(\passme).play;
Ndef(\passme).stop;