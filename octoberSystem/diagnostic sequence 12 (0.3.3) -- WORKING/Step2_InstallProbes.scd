// Step2_InstallProbes.scd
// v0.3.3
// MD 20251008-2115

(
~probeAcount = 0; ~probeBcount = 0;
~probeAid = IdentitySet.new; ~probeBid = IdentitySet.new;

OSCdef(\probeA, { |msg| ~probeAcount = ~probeAcount + 1; ~probeAid.add(msg[1]) }, '/peakrmsA');
OSCdef(\probeB, { |msg| ~probeBcount = ~probeBcount + 1; ~probeBid.add(msg[1]) }, '/peakrmsB');

"Probes ON (expect IDs: A=2001, B=2002).".postln;
)