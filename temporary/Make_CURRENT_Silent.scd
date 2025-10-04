// Make_CURRENT_Silent.scd
// v0.1.0
// MD 20251004-1820

/* Purpose
- Switch CURRENT to \ts0 and stop the arpeggio Ndef (silent).
*/

(
var pb = ~system.tryPerform(\pedalboard);
if(pb.isNil) { "No ~system or pedalboard. Run Start_LivePedalboardSuite_BringUp.scd first.".warn; ^nil };
if(pb.respondsTo(\setSourceCurrent)) { pb.setSourceCurrent(\ts0) };
if(pb.respondsTo(\playCurrent))      { pb.playCurrent };
Server.default.bind({ var nd = Ndef(\testmelody); if(nd.notNil) { nd.stop } });
"CURRENT set to ts0 (silent).".postln;
)