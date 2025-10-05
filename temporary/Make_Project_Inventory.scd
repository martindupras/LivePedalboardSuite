// Make_Project_Inventory.scd
// v0.1.0
// MD 20251005-2017

/*
Purpose
- Produce a concise, readable manifest of the LivePedalboardSuite:
  • Top-level tree (depth 2) for quick orientation
  • List all .sc / .scd files with their first 3 header lines (filename/version/MD stamp)
  • Confirm the adapter file path: adapter_CommandTree_to_MagicPedalboard.scd (if present)
- Writes a single text file in temporary/ so you can share or paste.

Style
- var-first; lowercase; no server.sync; conservative file reads.
*/

(
var rootDir, outDir, outPath;
var lines, nl, nowStamp;
var treeDepth, add, addSep, addLine, addSection, isCodeFile;
var relPathOf, printTreeL2, collectHeaders;

nl = Char.nl;
nowStamp = Date.getDate.stamp;  // e.g. 251005_2017

rootDir = (Platform.userExtensionDir ++ "/LivePedalboardSuite").standardizePath;
outDir  = (rootDir ++ "/temporary").standardizePath;
outPath = (outDir ++ "/Project_Inventory_" ++ nowStamp ++ ".txt").standardizePath;

lines = List.new;

add = { |s| lines.add(s); };
addSep = { lines.add("----------------------------------------"); };
addLine = { |k, v| lines.add((k ++ ": " ++ v.asString)); };
addSection = { |title|
    lines.add("");
    lines.add("===== " ++ title ++ " =====");
};

isCodeFile = { |pn|
    var ext;
    ext = pn.extension ? "";
    [ "sc", "scd" ].includes(ext.asString.toLower)
};

relPathOf = { |full|
    var base = PathName.new(rootDir).pathOnly;
    var s = full.asString;
    s.replace(base, "").replace("//", "/")
};

treeDepth = 2;  // depth for quick tree

printTreeL2 = { |dirPath|
    var pn, level1Dirs;

    pn = PathName.new(dirPath);
    if(pn.exists.not) {
        add("[!] Directory does not exist: " ++ dirPath);
        ^this;
    };

    add("ROOT: " ++ dirPath);
    addSep.();

    // level 0 files
    pn.files.do { |f|
        add("· " ++ relPathOf.(f.fullPath));
    };

    // level 1 folders and their files (depth 2 total)
    level1Dirs = pn.folders;
    level1Dirs.do { |d1|
        add("▸ " ++ relPathOf.(d1.fullPath));
        // files in d1
        PathName.new(d1.fullPath).files.do { |f1|
            add("  · " ++ relPathOf.(f1.fullPath));
        };
        // subfolders one level deeper
        PathName.new(d1.fullPath).folders.do { |d2|
            add("  ▸ " ++ relPathOf.(d2.fullPath));
            PathName.new(d2.fullPath).files.do { |f2|
                add("    · " ++ relPathOf.(f2.fullPath));
            };
        };
    };
};

collectHeaders = {
    var walk, pnRoot;

    pnRoot = PathName.new(rootDir);

    addSection.("Code files with headers (.sc / .scd)");
    add("(first 3 lines per file, if present: filename/version/MD stamp)");
    addSep.();

    walk = { |pn|
        // files at this level
        pn.files.do { |f|
            var p, contents, heads, head1, head2, head3;
            if(isCodeFile.(f)) {
                p = f.fullPath;
                // read first few KB to avoid loading huge files
                contents = "";
                File.use(p, "r", { |fh|
                    contents = fh.readAllString;  // ok for typical SC files; adjust if needed
                });
                heads = contents.split(Char.nl);
                head1 = heads.size > 0.if({ heads[0] }, { "" });
                head2 = heads.size > 1.if({ heads[1] }, { "" });
                head3 = heads.size > 2.if({ heads[2] }, { "" });

                add(relPathOf.(p));
                add("  " ++ head1);
                add("  " ++ head2);
                add("  " ++ head3);
                add("");
            };
        };
        // recurse folders
        pn.folders.do { |fd| walk.(PathName.new(fd.fullPath)) };
    };

    walk.(pnRoot);
};

// ---------------------------------------------------------------------
// Build the manifest
add("LPDisplay ↔ MagicPedalboard — Project Inventory");
addLine.("Generated", nowStamp);
addLine.("UserExtensionDir", Platform.userExtensionDir);
addLine.("Suite root", rootDir);
addSep.();

addSection.("Directory tree (depth 2)");
printTreeL2.(rootDir);

addSection.("Adapter file");
{
    var adapterPath = (rootDir ++ "/MagicPedalboard/adapter_CommandTree_to_MagicPedalboard.scd").standardizePath;
    addLine.("adapter_CommandTree_to_MagicPedalboard.scd", (File.exists(adapterPath).if({adapterPath}, {"[missing]"})));
};

collectHeaders.();

// ---------------------------------------------------------------------
// Write to file
File.mkdir(outDir);  // ensure temporary/ exists
{
    var f, txt;
    f = File(outPath, "w");
    txt = String.join(lines, nl);
    f.write(txt);
    f.close;
};

("📄 Inventory written to: " ++ outPath).postln;
// End
)