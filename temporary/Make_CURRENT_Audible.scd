// Make_CURRENT_Audible.scd
// v0.1.0
// MD 20251004-1820

/* Purpose
- Switch CURRENT to \testmelody and start playback (audible).
*/

(
var pb = ~system.tryPerform(\pedalboard);
if(pb.isNil) { "No ~system or pedalboard. Run Start_LivePedalboardSuite_BringUp.scd first.".warn; ^nil };
if(pb.respondsTo(\setSourceCurrent)) { pb.setSourceCurrent(\testmelody) };
if(pb.respondsTo(\playCurrent))      { pb.playCurrent };
"CURRENT set to testmelody (audible).".postln;
)