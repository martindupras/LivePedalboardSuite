// Test_LPS_ManualSwitch.scd
// v0.1.0
// MD 20251004-1807

(
var cm;
if(~system.isNil) { "No ~system. Run Start_LivePedalboardSuite_BringUp.scd first.".warn; ^nil };

cm = ~system.commandManager;
if(cm.isNil) { "No commandManager on ~system.".warn; ^nil };
if(cm.queueExportCallback.isNil) { "No queueExportCallback (installAdapterBridge?).".warn; ^nil };

cm.queueExportCallback.value("/switch"); // should swap ACTIVE/NEXT and colors
"Manual /switch invoked via queueExportCallback.".postln;
)
