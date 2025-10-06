// CommandManager-CanonicalPath.sc
// v0.1.1
// MD 20251006-1701

/*
Purpose
- Return simple canonical paths (e.g. "/switch") from the *builder*'s current node.
Style
- var-first; lowercase; no server.sync; no non-local returns.
*/

+ CommandManager {

    canonicalPathFromBuilder { arg builder;
        var node, names, leaf, tail;

        // Guard: must be an MDCommandBuilder with a currentNode
        if(builder.isNil or: { builder.respondsTo(\currentNode).not } or: { builder.currentNode.isNil }) {
            ^"/noop"
        };

        node  = builder.currentNode;
        names = node.getPathToRoot.asArray;          // e.g. [ "root", "switch" ]
        leaf  = names.last.asString.toLower;         // -> "switch"

        switch(leaf,
            "switch",   { ^"/switch" },
            "audio",    { ^"/audio"  },
            "chain",    { ^"/chain"  },
            "preset",   { ^"/preset" },
            "system",   { ^"/system" },
            "commands", { ^"/commands" },

            // Default: join path from root down (exclude leading "root")
            {
                tail = names.copyRange(1, names.size - 1).collect(_.asString).join("/");
                ^("/" ++ tail)
            }
        );
    }
}