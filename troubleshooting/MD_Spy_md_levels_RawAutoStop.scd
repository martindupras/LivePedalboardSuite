// MD_Spy_md_levels_RawAutoStop.scd
// v0.1.0
// MD 2025-09-26 18:05 BST

/* Purpose / Style
   Purpose: Print the next 4 OSC messages received on "/md/levels" verbatim (with indices),
            then auto-free the listener so the console stays clean.
   Style:   single () block; var-first everywhere; descriptive lowercase names; no server.sync; returns nil.
*/

(
var spyKey, remainingCount, printOneMessage;

spyKey = \md_levels_spy_once;
remainingCount = 4;

// ensure previous spy is gone
if(OSCdef.all.at(spyKey).notNil) { OSCdef.all.at(spyKey).free };

// print helper (var-first inside closure)
printOneMessage = { arg messageArray;
    var sizeCount, indexPos, indexLimit, lineText;
    sizeCount = messageArray.size;
    ("MDSPY: size=" ++ sizeCount.asString).postln;
    indexPos = 0; indexLimit = sizeCount;
    while({ indexPos < indexLimit }, {
        lineText = ("  [" ++ indexPos.asString ++ "] = " ++ messageArray[indexPos].asString);
        lineText.postln;
        indexPos = indexPos + 1;
    });
};

OSCdef(spyKey, { arg oscMessage;
    var localCount, doneNow;
    localCount = remainingCount;
    printOneMessage.(oscMessage);
    remainingCount = remainingCount - 1;
    doneNow = remainingCount <= 0;
    if(doneNow) {
        var spyObj;
        spyObj = OSCdef.all.at(spyKey);
        if(spyObj.notNil) { spyObj.free; "MDSPY: freed".postln };
    };
    nil
}, "/md/levels", recvPort: NetAddr.langPort);

"MDSPY: armed for 4 messages…".postln;
nil
)
