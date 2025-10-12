// Test_LPPedalboard_Minimal.scd
// v1.0.1
// MD 20251011-1652

(
var lpb;

s.waitForBoot {
    lpb = LPPedalboard.new(nil);

    lpb.setSourcesBoth(\testmelodyA);      // affects both chains

    lpb.playCurrent;      // guarantees CURRENT is playing
    lpb.printChains;      // optional: see what’s wired

    "LPPedalboard minimal bring-up complete.".postln;
};
)