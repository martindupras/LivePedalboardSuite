// Quick_Switch_Toggle.scd
// v0.1.0  MD 2025-09-26 15:28 BST
(
var systemRef, commandManagerRef, callbackFunc, didRun;
systemRef = ~system; if(systemRef.isNil) { "⚠️ ~system is nil; bring-up first.".warn; ^nil };
commandManagerRef = systemRef.commandManager; if(commandManagerRef.isNil) { "⚠️ CommandManager is nil.".warn; ^nil };
callbackFunc = commandManagerRef.queueExportCallback;
if(callbackFunc.isKindOf(Function).not) {
    if(systemRef.respondsTo(\installAdapterBridge)) { systemRef.installAdapterBridge };
    callbackFunc = commandManagerRef.queueExportCallback;
};
if(callbackFunc.isKindOf(Function)) { callbackFunc.value("/switch"); "[Switch] '/switch' sent.".postln } { "⚠️ queueExportCallback missing.".warn };
)
