// Step2_Disable_AutoMeters_ifPresent.scd
// v0.3.2
// MD 20251008-2106

(
~lpbSystem.tryPerform(\disableAutoMeters);   // if implemented
~lpbSystem.tryPerform(\enableAutoMeters, false);  // if implemented as toggle
"[Meters] Requested AutoMeters OFF; using in-sink meters only.".postln;
)