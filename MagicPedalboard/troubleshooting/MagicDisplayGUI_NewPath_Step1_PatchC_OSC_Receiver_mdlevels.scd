// MagicDisplayGUI_NewPath_Step1_PatchC_OSC_Receiver_mdlevels.scd
// v0.2.4
// MD timestamp: 2025-09-25

/* Purpose
   - Bind OSC receiver to '/md/levels' (matches SendReply in the probe SynthDef).
   - Parse values at indices 3..end and update ~levels and ~md_lastLevelAt.
   - No top-level 'var' declarations to avoid parse errors.

   Style
   - var-first inside function bodies; no non-local returns (^).
   - descriptive lowercase variable names; known-good SC syntax.
*/

(
// remove any previous receiver
if (OSCdef(\md_levels).notNil) { OSCdef(\md_levels).free; };

// reset shared state
~levels = [0.0, 0.0];
~md_lastLevelAt = Main.elapsedTime;

// Expected message from SendReply:
// [ '/md/levels', nodeID, replyID, val1, val2, ... ]
OSCdef(
    \md_levels,
    { |msg, time, addr, recvPort|
        var nodeId, replyId, count, i, outArray;

        nodeId = 0;
        replyId = 0;
        count = 0;
        i = 0;
        outArray = nil;

        if (msg.size >= 3) {
            nodeId = msg[1].asInteger;
            replyId = msg[2].asInteger;

            count = msg.size - 3;
            outArray = Array.newClear(count);

            i = 0;
            while { i < count } {
                outArray[i] = msg[3 + i].asFloat.clip(0.0, 1.0);
                i = i + 1;
            };

            ~levels = outArray;
            ~md_lastLevelAt = Main.elapsedTime;
        };
    },
    '/md/levels',
    recvPort: NetAddr.langPort
);
"Patch C installed: listening on /md/levels".postln;
)
