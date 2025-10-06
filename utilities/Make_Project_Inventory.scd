// Make_Project_Inventory.scd
// v0.2.2
// MD 20251006-0849

/*
Purpose
- Scan the LivePedalboardSuite tree (default depth = 2), list files, and
  include the first N header lines from each .sc / .scd file.
- Write to a new IDE Document (no file I/O). The FIRST line is the intended
  filename for manual save.

Style
- var-first; descriptive lowercase names; no single-letter locals.
- STRICT: no non-local returns (^) in this script; only final-expression returns.
- Known-good sclang only. Cross-platform paths via PathName. No server.sync.
*/

(
var nowStamp, userExtDir, suiteRoot, maxDepth, headerLines, ignoreNames;
var isScFile, takeFirstNLines, toRelPath, sorter, collectFiles, buildDocText;
var entries, lines, doc, intendedName, divider;

// ----- configuration -----
nowStamp    = Date.getDate.stamp;
userExtDir  = Platform.userExtensionDir;
suiteRoot   = (userExtDir ++ "/LivePedalboardSuite").standardizePath; // canonical
maxDepth    = 2;          // directory recursion depth
headerLines = 3;          // first N lines from .sc/.scd headers
ignoreNames = [".DS_Store", ".git", ".cache", "build", "out", "node_modules", "_archived"];

// ----- helpers -----
isScFile = { arg path;
    var p;
    p = path.asString;
    (p.endsWith(".sc") or: { p.endsWith(".scd") })
};

takeFirstNLines = { arg pathString, n = 3;
    var text, parts, firstN;
    text = "";
    parts = #[];
    firstN = #[];
    File.use(pathString, "r", { arg f;
        text = f.readAllString;
    });
    parts = (text ? "").split(Char.nl);
    firstN = if(parts.size == 0) {
        #[]
    } {
        parts.copyRange(0, (n-1).clip(0, parts.size-1))
    };
    firstN
};

// safer relative path (no unknown selectors)
toRelPath = { arg fullPath, rootPath;
    var norm, root, rel;
    norm = fullPath.standardizePath;
    root = rootPath.standardizePath;
    rel = if(norm.beginsWith(root)) {
        norm.copyRange(root.size, norm.size - 1)
    } {
        norm
    };
    rel
};

// simple “by-string” sorter that works on Arrays and PathName lists
sorter = { arg coll, keyFunc;
    var arr;
    arr = coll.asArray.copy;
    arr.sort({ arg a, b;
        var ka, kb;
        ka = keyFunc.value(a).asString.toLower;
        kb = keyFunc.value(b).asString.toLower;
        ka < kb
    });
    arr
};

collectFiles = { arg rootPath, depthLimit = 2;
    var out, walk;
    out = List.new;

    walk = { arg pn, level;
        var name, okToEnter, children;
        name = pn.fileName.asString;
        okToEnter = ignoreNames.any({ arg bad; name == bad }).not;

        if(okToEnter) {
            if(pn.isFile) {
                out.add(pn.fullPath);
            } {
                if(level < depthLimit) {
                    // sort children by fileName with only known-good calls
                    children = sorter.value(pn.entries, { arg x; x.fileName.asString });
                    children.do({ arg child; walk.value(child, level + 1) });
                };
            };
        };
        nil // explicit last expression; no ^ in scripts
    };

    walk.value(PathName(rootPath), 0);
    sorter.value(out, { arg p; p.asString })
};

buildDocText = { arg rootPath, filesArray;
    var linesOut, div;
    linesOut = List.new;
    div = String.fill(88, $-);

    // header metadata
    linesOut.add("Make_Project_Inventory.scd - Project Inventory");
    linesOut.add("Generated: " ++ nowStamp);
    linesOut.add("UserExtensionDir: " ++ userExtDir);
    linesOut.add("Chosen suite root: " ++ rootPath);
    linesOut.add(div);
    linesOut.add("===== Directory tree (depth " ++ maxDepth + ") =====");
    linesOut.add("ROOT: " ++ rootPath);
    linesOut.add(div);

    // flat listing
    filesArray.do({ arg fullPath;
        var rel;
        rel = toRelPath.value(fullPath, rootPath);
        linesOut.add("- " ++ rel);
    });

    linesOut.add(div);
    linesOut.add("===== File headers (.sc / .scd; first " ++ headerLines + " line(s)) =====");

    // file header previews
    filesArray.do({ arg fullPath;
        var rel, previewLines, blockSep;
        if(isScFile.value(fullPath)) {
            rel = toRelPath.value(fullPath, rootPath);
            previewLines = takeFirstNLines.value(fullPath, headerLines);
            blockSep = String.fill(72, $=);
            linesOut.add(blockSep);
            linesOut.add(rel);
            linesOut.addAll(previewLines);
        };
    });

    linesOut.join(Char.nl.asString) // final expression return
};

// ----- run -----
divider = String.fill(88, $-);
intendedName = "Project_Inventory_" ++ nowStamp.replace($:, $_) ++ ".txt";

// collect & sort
entries = collectFiles.value(suiteRoot, maxDepth);

// build text & open a Document (first line = intended filename)
lines = List.new;
lines.add(intendedName);
lines.add(buildDocText.value(suiteRoot, entries));

doc = Document.new("Project Inventory (" ++ nowStamp ++ ")", lines.join(Char.nl.asString));
doc.front;

// tidy locals (optional)
lines = nil; entries = nil; doc = nil;
)