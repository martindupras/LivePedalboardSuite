// LPS_CommandQueueToMPB_Adapter.sc
// v0.1.3
// MD 2025-09-22 23:08 BST

/* Purpose
   - Canonicalize CommandManager's exported path to short verb/object grammar
     for MagicPedalboardNew today.
   Examples:
     "/chain/add/audio/timebased/delay"    -> "/add/delay"
     "/chain/setsource/audio/source/sine"  -> "/setSource/sine"
     "/switch" or "/switch/crossfade*"     -> "/switch"
   Style
   - var-first; lowercase; no server.sync; flat control flow (no nested ^).
*/

+ LivePedalboardSystem {

    canonicalizeCommandPath { |rawPath|
        var parts, first;

        // Tokenize into non-empty segments
        parts = rawPath.asString.split($/).reject({ |s| s.size == 0 });
        if(parts.size == 0) { ^rawPath.asString };

        first = parts[0].asString;

        // 1) switch family → "/switch"
        if(first == "switch") {
            ^"/switch";
        };

        // 2) chain/* positional mappings
        if(first == "chain") {
            // Guard against short arrays
            if(parts.size >= 3) {
                var second = parts[1].asString;

                // 2a) /chain/add/audio/.../<effect> -> /add/<effect>
                if(second == "add" and: { parts[2].asString == "audio" }) {
                    ^("/add/" ++ parts.last.asString);
                };

                // 2b) /chain/setsource/audio/source/<src> -> /setSource/<src>
                if(second == "setsource"
                   and: { parts.size >= 5 }
                   and: { parts[2].asString == "audio" }
                   and: { parts[3].asString == "source" }) {
                    ^("/setSource/" ++ parts.last.asString);
                };

                // (Extend here for remove/clear/bypass/swap later)
            };

            // If we get here and didn't match any chain rule, fall through to raw.
            ^rawPath.asString;
        };

        // 3) Already-canonical short forms — pass through
        if(#["add","remove","clear","bypass","swap","setSource","switch"].includes(first)) {
            ^("/" ++ parts.join("/"));
        };

        // 4) Fallback: return unchanged
        ^rawPath.asString;
    }

    bringUpCommandSystem {
        var cm;
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
