// Rearm_Attach_Probes_AfterBringUp.scd
// v0.1.0  MD 2025-09-26
(
var baseTrouble, runIfExists;
baseTrouble = Platform.userExtensionDir ++ "/LivePedalboardSuite/MagicPedalboard/troubleshooting";
runIfExists = { arg leaf;
    var p = (baseTrouble ++ "/" ++ leaf).standardizePath;
    if(File.exists(p)) { p.load } { ("⚠️ missing " ++ leaf).warn };
};

AppClock.sched(0.10, { runIfExists.("MagicDisplayGUI_Reenable_FilterMeters_V0.3.12.scd"); nil });
AppClock.sched(0.20, { runIfExists.("MagicDisplayGUI_Attach_ProbesAfterNdefs_v0.3.15.scd"); nil });
AppClock.sched(0.30, { runIfExists.("MagicDisplayGUI_ResetReceiver_v0.3.11.scd"); nil });
"[Rearm] bus/probe helpers scheduled.".postln;
)
