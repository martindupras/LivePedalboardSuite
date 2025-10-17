// testNdefMaker.scd
// for v0.5

// Create the maker
~maker = LPNdefMaker.new;

// Create a new Ndef from the tremolo recipe


~maker.create(\testpink, \mytestpink);
Ndef(\mytestpink).play;
Ndef(\mytestpink).stop;


~maker.create(\tremolo, \mynewtremolo);
Ndef(\mynewtremolo) <<> Ndef(\mytestpink);

Ndef(\mynewtremolo).play;

// Free it // not sure it's needed but would allow deleting from a running lost of created Ndefs.
~maker.free(\mynewtremolo);


