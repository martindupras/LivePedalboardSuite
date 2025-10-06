// System_CM_Nav_Smoke_Fixed.scd
// v0.1.0
// MD 20251003-1613

/* Purpose / Style
- Minimal system CM display smoke: updateDisplay → LPDisplay, then one fret step.
- Style: tilde vars; var-first; lowercase; descriptive names; no server.sync.
*/

(
var cm;

"// System CM nav smoke (optional)".postln;

cm = ~cm ? (
    ~system.tryPerform(\commandManager) ?
    ~system.tryPerform(\cmdManager) ?
    ~system.tryPerform(\cm) ?
    ~system.tryPerform(\manager)
);

cm.notNil.if({
    cm.updateDisplay;                    // should land in LPDisplay via adapter
    cm.builder.tryPerform(\navigateByFret, nil, 3);  // adjust fret per your top-level mapping
    cm.updateDisplay;
},{
    "System CM not available (staying with standalone helpers ~nav6/~nav5/~nav4 is fine).".postln;
});
)