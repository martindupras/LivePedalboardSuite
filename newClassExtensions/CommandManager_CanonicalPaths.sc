// CommandManager_CanonicalPaths.sc
// v1.0 — restore canonical path helpers (non-invasive extension)
// MD 2025-10-02

+ CommandManager {

    buildLongPathFromBuilder { |builderRef|
        var names, filtered;
        if (builderRef.isNil or: { builderRef.currentNode.isNil }) { "/" } {
            names    = builderRef.currentNode.getPathToRoot;        // ["root", ...]
            filtered = (names.size > 1).if({ names.copyRange(1, names.size-1) }, { [] });
            "/" ++ filtered.join("/")
        }
    }

    canonicalizeCommandPath { |rawPath|
        var parts, first;
        parts = rawPath.asString.split($/).reject({ |s| s.size == 0 });
        if (parts.isEmpty) { rawPath.asString } {
            first = parts[0].asString;
            if (#["add","remove","clear","bypass","swap","setSource","switch"].includes(first)) {
                "/" ++ parts.join("/")
            } {
                if (first == "switch") { "/switch" } {
                    if (first == "chain") {
                        if (parts.size >= 3 and: { parts[1] == "add" } and: { parts[2] == "audio" }) {
                            "/add/" ++ parts.last.asString
                        } {
                            if (parts.size >= 5
                                and: { parts[1] == "setsource" }
                                and: { parts[2] == "audio" }
                                and: { parts[3] == "source" }) {
                                "/setSource/" ++ parts.last.asString
                            } {
                                rawPath.asString
                            }
                        }
                    } {
                        rawPath.asString
                    }
                }
            }
        }
    }

    canonicalPathFromBuilder { |builderRef|
        var longPath;
        longPath = this.buildLongPathFromBuilder(builderRef);
        this.canonicalizeCommandPath(longPath)
    }
}
