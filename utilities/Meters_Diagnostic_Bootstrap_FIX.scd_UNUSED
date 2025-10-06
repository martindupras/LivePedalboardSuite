// Meters_Diagnostic_Bootstrap_FIX.scd
// v0.1.1
// MD 20250923-1543

/* Purpose
   - Ensure bus meter SynthDefs exist (defines them via MagicDisplay.ensureMeterDefs(2) if needed).
   - Instantiate meter readers on Ndef(\chainA) and Ndef(\chainB) buses.
   - Install console debug printers for '/ampA' and '/ampB' using correct OSCdef.free pattern.

   Style
   - var-first; Server.default.bind for server ops; AppClock-safe UI; no server.sync.
*/

(
var serverRef, statusDisplayRef, chainABusIndex, chainBBusIndex, metersGroupId;
var ensureMeterDefsExist, installDebugPrinters, freeIfExists;

serverRef        = Server.default;
statusDisplayRef = (~system ? nil).notNil.if({ ~system.statusDisplay }, { nil });

ensureMeterDefsExist = {
  var hasA, hasB;
  hasA = SynthDescLib.global.at(\busMeterA).notNil;
  hasB = SynthDescLib.global.at(\busMeterB).notNil;
  if(hasA.not or: { hasB.not }) {
    "ℹ️ Defining meter synths (busMeterA/busMeterB).".postln;
    MagicDisplay.ensureMeterDefs(2); // should be idempotent in your codebase
  };
};

freeIfExists = { |defName|
  var existingDef;
  existingDef = OSCdef(defName);
  if(existingDef.notNil) { existingDef.free };
};

installDebugPrinters = {
  // Avoid duplicates by