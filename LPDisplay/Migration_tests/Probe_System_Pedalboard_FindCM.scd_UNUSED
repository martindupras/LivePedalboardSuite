// Probe_System_Pedalboard_FindCM.scd
// v0.1.0
// MD 20251003-1613

/* Purpose / Style
- Look for a CommandManager under ~system.pedalboard using common selector names.
- Bind LPDisplayAdapter if found; otherwise print pedalboard zero-arg selectors for inspection.
- Style: tilde vars; var-first; lowercase; descriptive names; no server.sync.
*/

(
var pb, selectorNames, foundSel, cm, adapter, pbZeroArgNames;

// guard
if(~system.isNil) {
    "No ~system present (staying in standalone helpers is fine).".postln;
} {
    pb = ~system.tryPerform(\pedalboard);

    if(pb.isNil) {
        "~system has no zero-arg 'pedalboard' method; accessor will be added next session."
        .postln;
    }{
        selectorNames = [\commandManager, \cmdManager, \cm, \manager, \commandCenter, \commandCentre];

        foundSel = selectorNames.detect({ arg sel;
            pb.respondsTo(sel) and: {
                var candidate = pb.perform(sel);
                candidate.notNil and: { candidate.respondsTo(\updateDisplay) and: { candidate.respondsTo(\builder) } }
            }
        });

        if(foundSel.notNil) {
            cm = pb.perform(foundSel);
            ~cm = cm;  // publish for convenience

            adapter = (~lp_adapter.notNil).if({ ~lp_adapter }, { LPDisplayAdapter.new(~guiLP) });
            ~lp_adapter = adapter;

            cm.display = adapter;
            cm.updateDisplay;

            ("Adapter bound to SYSTEM CommandManager via ~system.pedalboard." ++ foundSel.asString).postln;
            (~md_log.notNil).if({ ~md_log.("Adapter bound via pedalboard selector " ++ foundSel.asString) });
        }{
            "Could not find a CM under ~system.pedalboard with common names.".postln;

            // show pedalboard's zero-arg methods (first 20) to guide a tiny accessor next time
            pbZeroArgNames = pb.class.methods.select({ arg m; m.argNames.size == 0 }).collect(_.name).collect(_.asString);
            "Zero-arg selectors on pedalboard (first 20):".postln;
            pbZeroArgNames.copyRange(0, (pbZeroArgNames.size - 1).min(19)).postln;

            (~md_log.notNil).if({ ~md_log.("Pedalboard zero-arg methods enumerated for CM accessor planning") });
        };
    };
};
)