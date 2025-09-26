// Quick_SetSource_Testmelody.scd
// v0.1.0  MD 2025-09-26
(
var systemRef, cmRef, cb;
systemRef = ~system; if(systemRef.isNil) { "⚠️ ~system is nil; bring-up first.".warn; ^nil };
cmRef = systemRef.commandManager; if(cmRef.isNil) { "⚠️ CommandManager is nil.".warn; ^nil };
cb = cmRef.queueExportCallback;
if(cb.isKindOf(Function).not) {
    if(systemRef.respondsTo(\installAdapterBridge)) { systemRef.installAdapterBridge };
    cb = cmRef.queueExportCallback;
};
if(cb.isKindOf(Function)) {
    cb.value("/commands/setSource/testmelody");  // from your tree: commands → setSource → testmelody
    "[SetSource] '/commands/setSource/testmelody' sent.".postln;
} {
    "⚠️ queueExportCallback missing.".warn;
};
)
