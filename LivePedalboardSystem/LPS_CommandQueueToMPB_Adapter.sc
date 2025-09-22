// LPS_CommandQueueToMPB_Adapter.sc
// v0.1.1
// MD 2025-09-22 22:42 BST

/* Purpose
   - Canonicalize CommandManager's exported path (joined payload segments) to the
     short verb/object grammar that MagicPedalboardNew expects today.
   - Examples:
       "/chain/add/audio/timebased/delay"   -> "/add/delay"
       "/chain/setsource/audio/source/sine" -> "/setSource/sine"
       "/switch(/crossfade|/crossfade_custom)?" -> "/switch"
   - Lives as a class extension to LivePedalboardSystem and is used in
     bringUpCommandSystem via queueExportCallback.

   Style
   - var-first; lowercase; no server.sync; pure string ops; defensive where needed.
*/

+ LivePedalboardSystem {

    canonicalizeCommandPath { |rawPath|
        var parts, clean, has, pickLeaf, trySwitch, first, passList;

        // Split the path into non-empty segments
        parts = rawPath.asString.split($/).reject({ |s| s.isEmpty });
        clean = parts.copy;

        // has(...tokens) -> true if all tokens are present in 'clean'
        has = { |...tokens|
            var ok = true;
            tokens.do({ |t|
                if(clean.includes(t).not, { ok = false });
            });
            ok
        };

        // pickLeaf("audio") -> last segment (e.g., "delay" or "sine") if "audio" exists
        pickLeaf = { |prefix|
            var idx;
            idx = clean.indexOf(prefix);
            if(idx.isNil) { ^nil };
            clean.last
        };

        // Accept "switch", "switch/crossfade", "switch/crossfade_custom"
        trySwitch = {
            if(clean.size > 0 and: { clean[0] == "switch" }) {
                ^"/switch"
            };
            nil
        };

        // 1) /chain/add + /audio/.../<effect> -> /add/<effect>
        if(has.("chain","add") and: { has.("audio") }) {
            var eff = pickLeaf.("audio");
            if(eff.notNil) { ^("/add/" ++ eff) };
        };

        // 2) /chain/setsource + /audio/source/<src> -> /setSource/<src>
        if(has.("chain","setsource") and: { has.("audio","source") }) {
            var src = pickLeaf.("audio");
            if(src.notNil) { ^("/setSource/" ++ src) };
        };

        // 3) switch family -> "/switch"
        { var s = trySwitch.(); if(s.notNil) { ^s } }.value;

        // 4) direct canonical short forms -> pass-through
        passList = ["add","remove","clear","bypass","swap","setSource","switch"];
        first = if(clean.size > 0) { clean[0].asString } { "" };
        if(passList.includes(first)) {
            ^("/" ++ clean.join("/"));
        };

        // 5) fallback: return as-is (you may log a warning here if desired)
        rawPath
    }

    bringUpCommandSystem {
        var cm;

        // Construct and wire the command manager (same as your version, with the adapter in-line)
        cm = CommandManager.new(treeFilePath);
        cm.display = statusDisplay;

        cm.queueExportCallback = { |oscPath|
            var canon;
            canon = this.canonicalizeCommandPath(oscPath);
            pedalboard.handleCommand(canon);
            logger.info("Integration", "Sent command to pedalboard: " ++ canon);
            if(statusDisplay.notNil and: { statusDisplay.respondsTo(\showExpectation) }) {
                statusDisplay.showExpectation("Sent: " ++ canon, 0);
            };
        };

        commandManager = cm;
        logger.info("CommandSystem", "CommandManager initialized and connected.");
    }
}
