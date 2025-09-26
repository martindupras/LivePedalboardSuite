// MD_Stop_All_MeterDiagnostics.scd
// v0.1.1
// MD 2025-09-26 18:05 BST

/* Purpose / Style
   Purpose: Quiet the console by freeing known OSCdef listeners and stopping any reporter routines
            we may have created during diagnostics. Safe to run multiple times. Auto-stops.
   Style:   single () block; var-first everywhere; descriptive lowercase names; AppClock-only where used;
            no server.sync; no single-letter locals; returns nil.
*/

(
var freeOscIfPresent, stopRoutineIfPresent, freedCount, oscKeys, indexCount, indexLimit;
var reporterStoppedCount, oscObj, routineRef;

// —— helpers (var-first in closures)
freeOscIfPresent = { arg keySymbol;
    var oscRef;
    oscRef = OSCdef.all.at(keySymbol);
    if(oscRef.notNil) { oscRef.free; ("MDSTOP: freed OSCdef " ++ keySymbol.asString).postln };
};

stopRoutineIfPresent = { arg routineVar, labelString;
    var canStop;
    canStop = routineVar.notNil and: { routineVar.respondsTo(\stop) };
    if(canStop) { routineVar.stop; (labelString ++ ": stopped").postln };
};

// —— free known listeners (only if present)
freedCount = 0;
oscKeys = [
    \md_levels_sniffer_fixed,    // finite/continuous sniffers
    \md_levels_inline,           // overlay listener (if any)
    \md_levels_dbg_sniffer,      // debug taps listener
    \md_levels_gui_listener,     // if we created a GUI-only listener
    \md_levels_hud               // HUD listener (optional – remove if you want it kept)
];
indexCount = 0; indexLimit = oscKeys.size;
while({ indexCount < indexLimit }, {
    var keySym, exists;
    keySym = oscKeys[indexCount];
    exists = OSCdef.all.at(keySym).notNil;
    if(exists) { freeOscIfPresent.(keySym); freedCount = freedCount + 1 };
    indexCount = indexCount + 1;
});

// —— stop known reporter routines (only if present)
reporterStoppedCount = 0;
stopRoutineIfPresent.(~md_levels_dbg_reporter, "md_levels_dbg_reporter"); reporterStoppedCount = reporterStoppedCount + 1;
stopRoutineIfPresent.(~md_simple_reporter,     "md_simple_reporter");     reporterStoppedCount = reporterStoppedCount + 1;

// —— clear diagnostic dictionaries (safe)
~md_levelsById = ~md_levelsById ? IdentityDictionary.new;
~md_levels_dbg = ~md_levels_dbg ? IdentityDictionary.new;

("MDSTOP: freed=" ++ freedCount.asString
 ++ " stopped=" ++ reporterStoppedCount.asString).postln;
nil
)
