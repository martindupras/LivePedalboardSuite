// MD_PerfHUD_LevelSubscriber.scd
// v0.1.0
// MD timestamp: 2025-09-28 10:15 GMT+1

/*
Purpose
- Populate ~md_levelsById (IdentityDictionary) from /md/levels messages so
  MagicDisplayGUI_New_Window_PerfHUD_AB_v0.5.4.scd can render meters.
- Also updates ~md_lastMsgStamp for the "last /md/levels age" display.

Message shapes handled
- Standard: ['/md/levels', nodeID, replyID, L, R]   (preferred)
- Legacy:   ['/md/levels', replyID, L, R]           (fallback)

Reply IDs used by the GUI (per file comments):
- A = 2001, B = 2002, test = 1001
*/

(
var ensureDict, putPair, banner, oscAny;

banner = { arg text; ("[MD_SUB] " ++ text).postln; };

// Ensure the shared dictionary exists (the GUI reads this)
ensureDict = {
    (~md_levelsById.isKindOf(IdentityDictionary)).if({
        // already OK
    }, {
        ~md_levelsById = IdentityDictionary.new;
        banner.("created ~md_levelsById");
    });
    ~md_lastMsgStamp = ~md_lastMsgStamp ? thisThread.seconds;
};

putPair = { arg id, l, r;
    var pair;
    pair = [ (l ? 0.0).asFloat, (r ? 0.0).asFloat ];
    ~md_levelsById[id] = pair;
    ~md_lastMsgStamp = thisThread.seconds;
};

// Clean prior instance (idempotent)
OSCdef(\md_levels_any).free;

ensureDict.();

// One listener that accepts both shapes and writes into ~md_levelsById
oscAny = OSCdef(\md_levels_any, { arg msg, time, addr, port;
    var id, l, r, sz;
    sz = msg.size;
    // Standard
    (sz >= 5).if({
        id = msg[2];
        l  = msg[3];
        r  = msg[4];
        putPair.(id, l, r);
    }, {
        // Legacy
        (sz == 4).if({
            id = msg[1];
            l  = msg[2];
            r  = msg[3];
            putPair.(id, l, r);
        }, {
            // ignore
        });
    });
}, '/md/levels');

banner.("listening on /md/levels → ~md_levelsById (A=2001, B=2002, test=1001)");
"-> MD_PerfHUD_LevelSubscriber ready"
)
