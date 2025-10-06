// Meters_QuickCheck_And_Enable.scd
// v0.1.0
// MD 2025-09-23 14:10 BST

/* Purpose
   - Ensure meter SynthDefs exist (busMeterA/B).
   - Attach meter readers to Ndef(\chainA/\chainB) buses.
   - Print incoming values to console (quick sanity).
   - Re-enable GUI meters if the display supports it.

   Style
   - var-first; Server.default.bind for server ops; no server.sync.
*/

(
var serverRef, displayRef, chainABusIndex, chainBBusIndex, metersGroup;
var ensureMeterDefsExist, installConsolePrinters;

serverRef  = Server.default;
displayRef = ~system ? nil;

// --- helpers ---
ensureMeterDefsExist = {
  var hasA, hasB;
  hasA = SynthDescLib.global.at(\busMeterA).notNil;
  hasB = SynthDescLib.global.at(\busMeterB).notNil;
  if(hasA.not or: { hasB.not }) {
    "⚠️ Meter SynthDefs missing — defining now via MagicDisplay.ensureMeterDefs(2)".postln;
  };
  MagicDisplay.ensureMeterDefs(2); // idempotent
};

installConsolePrinters = {
  // avoid duplicates
  OSCdef.remove(\_meterA_dbg);
  OSCdef.remove(\_meterB_dbg);
  OSCdef(\_meterA_dbg, { |oscMessage| ("[meterA] " ++ oscMessage[3..].asString).postln }, '/ampA');
  OSCdef(\_meterB_dbg, { |oscMessage| ("[meterB] " ++ oscMessage[3..].asString).postln }, '/ampB');
};

// --- server work ---
Server.default.bind({
  ensureMeterDefsExist.value;

  // ensure both chain proxies are realized at audio-rate
  Ndef(\chainA).ar(2);
  Ndef(\chainB).ar(2);
  chainABusIndex = Ndef(\chainA).bus.index;
  chainBBusIndex = Ndef(\chainB).bus.index;

  metersGroup = Group.head(serverRef.defaultGroup);

  // spawn readers (safe to re