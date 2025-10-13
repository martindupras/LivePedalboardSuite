// testNChainsv.0.4.6.7.scd

(
// Initial setup: create chain, insert stages, connect pink noise, play output
s.waitForBoot {
    ~testchain = NChain.new("chaintest");

    Ndef(\pink).source = { PinkNoise.ar(0.1!2) };
    Ndef(\chaintestIn) <<> Ndef(\pink);
    Ndef(\chaintestOut).play;

    //~testchain.printChain;
    "Setup complete. You should hear pink noise.".postln;
};
)

Ndef(\pink).play; // works, I can hear it
Ndef(\pink).stop; // works, sound stops.
Ndef(\chaintestOut).play; // works now
Ndef(\chaintestOut).stop; // works now

Ndef(\chaintestOut).play; // works now
~testchain.insertTest("alice");
~testchain.insertTest("bob");
~testchain.insertTest("clara");

~testchain.printChain;
