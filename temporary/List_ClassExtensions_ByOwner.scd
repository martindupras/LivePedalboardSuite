// List_ClassExtensions_ByOwner.scd
// v1.0.0
// MD 20251006-1530

/*
Purpose
- List all class extension files that add methods to key classes using the +ClassName { ... } form.
- Targets: LivePedalboardSystem, MagicPedalboard, LPDisplayLayoutWindow, LPDisplayAdapter.
- Opens a Document with grouped results.

Style
- STRICT: var-first; descriptive lowercase names; no single-letter locals; no non-local returns (^).
- Known-good sclang only.

Notes
- We avoid deep parsing; we just detect lines that begin with "+ClassName" and contain "{".
- If you want to add more classes, edit targetClasses below.
*/

(
var nowStamp, suiteRoot, targetClasses;
var listFiles, readText, toRel, scanForExtensions;
var allFiles, scFiles, hitsByClass, docLines, doc;

// ----- config -----
nowStamp     = Date.getDate.stamp;
suiteRoot    = (Platform.userExtensionDir ++ "/LivePedalboardSuite").standardizePath;
targetClasses = ["LivePedalboardSystem", "MagicPedalboard", "LPDisplayLayoutWindow", "LPDisplayAdapter"];

// ----- helpers -----
listFiles = { arg rootPath;
    var out, walk, skip;
    out = List.new;
    skip = [".git", ".cache", "_archived"];
    walk = { arg pn;
        var name, stopHere;
        name = pn.fileName.asString;
        stopHere = skip.any({ arg s; name == s });
        if(stopHere) {
            nil
        } {
            if(pn.isFile) { out.add(pn.fullPath) } { pn.entries.do({ arg c; walk.value(c) }) };
        };
        nil
    };
    walk.value(PathName(rootPath));
    out.asArray
};

readText = { arg fullPath;
    var text;
    text = "";
    File.use(fullPath, "r", { arg f; text = f.readAllString; });
    text ? ""
};

toRel = { arg fullPath;
    var norm;
    norm = fullPath.standardizePath;
    if(norm.beginsWith(suiteRoot)) {
        norm.copyRange(suiteRoot.size + 1, norm.size - 1)
    } {
        norm
    }
};

scanForExtensions = { arg fullPath;
    var text, lines, results, idx, line, stripped;
    text    = readText.value(fullPath);
    lines   = text.split(Char.nl);
    results = List.new;

    idx = 0;
    while({ idx < lines.size }, {
        line = lines[idx];
        if(line.notNil) {
            stripped = line.stripWhiteSpace;
            targetClasses.do({ arg cls;
                var key = "+" ++ cls;
                if(
                    (stripped.beginsWith(key))
                    and: { stripped.contains("{") }
                ) {
                    results.add(cls);
                };
            });
        };
        idx = idx + 1;
    });
    results.asArray
};

// ----- scan -----
allFiles = listFiles.value(suiteRoot);
scFiles  = allFiles.select({ arg p; p.endsWith(".sc") });

hitsByClass = IdentityDictionary.new;
targetClasses.do({ arg cls; hitsByClass[cls] = List.new });

scFiles.do({ arg f;
    var extHits;
    extHits = scanForExtensions.value(f);
    extHits.do({ arg cls; hitsByClass[cls].add(f) });
});

// ----- report -----
docLines = List.new;
docLines.add("List_ClassExtensions_ByOwner — " ++ nowStamp);
docLines.add("Root: " ++ suiteRoot);
docLines.add(String.fill(88, $-));

targetClasses.do({ arg cls;
    var rows;
    docLines.add("== Extensions for +" ++ cls ++ " ==");
    rows = (hitsByClass[cls] ? List.new).asArray.sort;
    if(rows.size == 0) {
        docLines.add(" (none found)");
    } {
        rows.do({ arg full;
            docLines.add(" - " ++ toRel.value(full));
        });
    };
    docLines.add(String.fill(88, $-));
});

doc = Document.new("Class Extensions (" ++ nowStamp ++ ")", docLines.join(Char.nl.asString));
doc.front;
doc
)