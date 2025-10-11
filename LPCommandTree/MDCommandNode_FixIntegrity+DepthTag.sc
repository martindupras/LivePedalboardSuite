// MDCommandNode_FixIntegrity+DepthTag.sc
// v1.0 — 2025-09-21 MD

// Purpose
// - Accept SortedList in checkIntegrity.
// - Add tagByDepth(depth) used by MDCommandTree.tagDepths.
// Style
// - var-first; lowercase; no server.sync.

+ MDCommandNode {
    // Accept List OR SortedList
    checkIntegrity {
        var failedChild;
        if( (this.children.isKindOf(List).not) && (this.children.isKindOf(SortedList).not) ) {
            ("❌ Integrity check failed at node '" ++ this.name ++ "': children is " ++ children.class).postln;
            ^false;
        };
        failedChild = this.children.detect { |c| c.checkIntegrity.not };
        if(failedChild.notNil) {
            ("❌ Integrity failed in child: " ++ failedChild.name).postln;
            ^false;
        };
        ^true
    }

    // annotate nodes with a 'depth' entry in payload (non-destructive)
    tagByDepth { |depth|
        var nextDepth = (depth ? 0).asInteger.max(0);
        // if payload is nil or a String, wrap in a simple Event to attach depth safely
        if(this.payload.isNil or: { this.payload.isKindOf(String) }) {
            this.payload = (name: this.name, depth: nextDepth);
        }{
            // if payload is e.g., an Event/Dict, set depth if slot exists
            this.payload.put(\depth, nextDepth);
        };
        this.children.do { |child| child.tagByDepth(nextDepth + 1) };
        ^this
    }
}
