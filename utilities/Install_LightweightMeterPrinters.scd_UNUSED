// Install_LightweightMeterPrinters.scd
// v0.1
// MD 20250923-1556

/* Purpose
   Quiet console printers for '/ampA' and '/ampB' that print only non-zero-ish values.
*/

(
var threshold, freeIfExists;

threshold = 0.02;

freeIfExists = { |defName|
  var existingDef = OSCdef(defName);
  if(existingDef.notNil) { existingDef.free };
};

freeIfExists.(\_meterA_dbg);
freeIfExists.(\_meterB_dbg);

OSCdef(\_meterA_dbg, { |message|
  var leftVal = message[3].asFloat, rightVal = message[4].asFloat;
  if((leftVal > threshold) or: (rightVal > threshold)) {
    ("[meterA] [" ++ leftVal.asString ++ ", " ++ rightVal.asString ++ "]").postln;
  };
}, '/ampA');

OSCdef(\_meterB_dbg, { |message|
  var leftVal = message[3].asFloat, rightVal = message[4].asFloat;
  if((leftVal > threshold) or: (rightVal > threshold)) {
    ("[meterB] [" ++ leftVal.asString ++ ", " ++ rightVal.asString ++ "]").postln;
  };
}, '/ampB');

"✅ Lightweight printers installed (non-zero only).".postln;
)
