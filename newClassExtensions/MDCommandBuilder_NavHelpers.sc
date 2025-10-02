// MDCommandBuilder_NavHelpers.sc
// v1.0 — add robust navigation helpers with fallback to currentNode_
// MD 2025-10-02

+ MDCommandBuilder {

    navigateByNameOrForce { |parentRef, nameString|
        var beforeNode, afterNode, children, targetNode, didSet;
        beforeNode = this.currentNode;
        this.navigateByName(parentRef, nameString.asString);
        afterNode = this.currentNode;

        if (afterNode == beforeNode) {
            children   = beforeNode.children;
            targetNode = children.detect({ |n| n.name.asString == nameString.asString });
            didSet     = false;
            if (targetNode.notNil and: { this.respondsTo(\currentNode_) }) {
                this.perform(\currentNode_, targetNode);
                didSet = true;
            };
            (didSet.if({ ("[Builder] forced to '" ++ nameString.asString ++ "'").postln }, { ("[Builder] could not force '" ++ nameString.asString ++ "'").warn }));
        };
        this.currentNode
    }

    navigateByNamesWithFallback { |nameArray|
        var names;
        names = nameArray.collect(_.asString);
        names.do({ |nm| this.navigateByNameOrForce(nil, nm) });
        this.currentNode
    }
}
