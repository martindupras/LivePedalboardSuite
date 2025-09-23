// Queue_AddDelay_DirectCanonical.scd
// v0.1
// MD 20250923-1302

(
var environmentReady, commandManager, commandQueue, statusDisplayRef;
var canonicalPathString, queueListAsText;

environmentReady = (~system.notNil)
  and: { ~system.commandManager.notNil }
  and: { ~system.commandManager.queue.notNil };

if(environmentReady.not) { "⚠️ Bring-up first (Option B).".warn; ^nil };

commandManager       = ~system.commandManager;
commandQueue         = commandManager.queue;
statusDisplayRef     = commandManager.display;
canonicalPathString  = "/add/delay";

commandQueue.clearQueue; "🧹 Queue cleared".postln;
commandQueue.enqueueCommand(canonicalPathString);
("📥 Command added: " ++ canonicalPathString).postln;
("📦 Current queue: " ++ commandQueue.commandList.asString).postln;

AppClock.sched(0.0, {
  if(statusDisplayRef.notNil and: { statusDisplayRef.respondsTo(\updateTextField) }) {
    var listAsText = commandQueue.commandList.collect({ |s| "- " ++ s.asString }).join("\n");
    statusDisplayRef.updateTextField(\state, "Mode: queue (simulated)");
    statusDisplayRef.updateTextField(\queue, "Current Queue:\n" ++ listAsText);
    statusDisplayRef.updateTextField(\lastCommand, "Last Added: " ++ canonicalPathString);
  };
  nil
});
)
