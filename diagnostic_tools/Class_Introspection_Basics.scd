// Class_Introspection_Basics.scd
// v0.4.0
// MD 20251007-1345

/*
Purpose
- Inspect any class to discover: base files (instance+meta), methods, and likely extensions.
- Group methods by source file so extensions stand out immediately.
- Trace where a particular selector is defined (instance/class side, which ancestor, which file).

Style
- var-first; descriptive lowercase names; no server.sync; no GUI or audio ops.
- Safe 'tryPerform' for fields that may not exist in some SuperCollider versions.
*/

(
var targetClass, selectorToTrace;
var printHeader, symbolToPathString, listBaseFiles, listMethodsByFile, listAllMethodsFlat, traceSelectorOrigin;

// ===== configure here =====
targetClass = LPDisplayLayoutWindow;  // <-- change to inspect a different class
selectorToTrace = \sendPaneText;      // <-- change or set to nil to skip
// ==========================

// Pretty header
printHeader = { arg title;
    var line;
    line = ("==== " ++ title ++ " ").padRight(70, $=);
    line.postln;
};

// Convert filenameSymbol (or nil) to a readable string
symbolToPathString = { arg fileSym;
    var s;
    s = fileSym.tryPerform(\asString);
    s = s ? "<unknown>";
    s
};

// 1) Base files (instance-side class and meta-class)
listBaseFiles = {
    var classFile, metaFile;
    printHeader.value("Class base files");
    classFile = targetClass.tryPerform(\filenameSymbol);
    metaFile  = targetClass.class.tryPerform(\filenameSymbol);

    ("instance-side  : " ++ symbolToPathString.value(classFile)).postln;
    ("class-side     : " ++ symbolToPathString.value(metaFile)).postln;
};

// 2) Group methods by file (instance-side); repeat for class-side
listMethodsByFile = {
    var instanceMethods, classMethods, tableInst, tableMeta;

    printHeader.value("Methods by file — instance side");
    instanceMethods = targetClass.tryPerform(\methods) ? Array.new;
    tableInst = IdentityDictionary.new;
    instanceMethods.do({ arg m;
        var fileKey;
        fileKey = symbolToPathString.value(m.tryPerform(\filenameSymbol));
        (tableInst[fileKey] ?? { tableInst[fileKey] = List.new; }).add(m.name);
    });
    tableInst.keysValuesDo({ arg f, names;
        ("→ " ++ f).postln;
        names.asArray.sort.do({ arg sel; ("   - " ++ sel.asString).postln; });
    });

    printHeader.value("Methods by file — class side (meta)");
    classMethods = targetClass.class.tryPerform(\methods) ? Array.new;
    tableMeta = IdentityDictionary.new;
    classMethods.do({ arg m;
        var fileKey;
        fileKey = symbolToPathString.value(m.tryPerform(\filenameSymbol));
        (tableMeta[fileKey] ?? { tableMeta[fileKey] = List.new; }).add(m.name);
    });
    tableMeta.keysValuesDo({ arg f, names;
        ("→ " ++ f).postln;
        names.asArray.sort.do({ arg sel; ("   - " ++ sel.asString).postln; });
    });

    // Quick hint about extensions:
    if ((tableInst.size > 1) or: { tableMeta.size > 1 }) {
        "Hint: multiple files detected — this class likely has extensions.".postln;
    };
};

// 3) Flat, sorted method lists (instance + class side)
listAllMethodsFlat = {
    var instNames, metaNames;
    printHeader.value("Flat method lists (names only)");
    instNames = (targetClass.tryPerform(\methods) ? Array.new).collect(_.name).asArray.sort;
    metaNames = (targetClass.class.tryPerform(\methods) ? Array.new).collect(_.name).asArray.sort;
    ("Instance methods (" ++ instNames.size.asString ++ "):").postln;
    instNames.do({ arg n; ("  " ++ n.asString).postln; });
    ("Class methods (" ++ metaNames.size.asString ++ "):").postln;
    metaNames.do({ arg n; ("  " ++ n.asString).postln; });
};

// 4) Trace where a selector is defined (walks up the inheritance chain)
traceSelectorOrigin = {
    var sel, walk, foundInst, foundMeta;

    sel = selectorToTrace;
    if (sel.isNil) { ^"traceSelectorOrigin: selectorToTrace is nil; skipped".postln };

    printHeader.value("Trace selector origin — " ++ sel.asString);

    // Instance-side walk
    walk = targetClass;
    foundInst = false;
    while({ walk.notNil }, {
        var meth = (walk.tryPerform(\methods) ? Array.new).detect({ arg m; m.name == sel });
        if (meth.notNil) {
            ("Instance-side: defined on " ++ walk.name.asString
                ++ "  file=" ++ symbolToPathString.value(meth.tryPerform(\filenameSymbol))).postln;
            foundInst = true;
            break;
        };
        walk = walk.tryPerform(\superclass);
    });
    if (foundInst.not) { "Instance-side: not found on this class nor its ancestors.".postln };

    // Class-side (meta) walk
    walk = targetClass.class;
    foundMeta = false;
    while({ walk.notNil }, {
        var meth = (walk.tryPerform(\methods) ? Array.new).detect({ arg m; m.name == sel });
        if (meth.notNil) {
            ("Class-side   : defined on " ++ walk.name.asString
                ++ "  file=" ++ symbolToPathString.value(meth.tryPerform(\filenameSymbol))).postln;
            foundMeta = true;
            break;
        };
        walk = walk.tryPerform(\superclass);
    });
    if (foundMeta.not) { "Class-side   : not found on this class nor its meta-ancestors.".postln };
};

// ---- run all ----
listBaseFiles.value;
listMethodsByFile.value;
listAllMethodsFlat.value;
traceSelectorOrigin.value;

// Optional: use built-in dumpers if available in your image:
if (targetClass.respondsTo(\dumpInterface)) {
    printHeader.value("dumpInterface (instance-side, local only)");
    targetClass.dumpInterface;
};
if (targetClass.respondsTo(\dumpFullInterface)) {
    printHeader.value("dumpFullInterface (instance-side, incl. inherited)");
    targetClass.dumpFullInterface;
};
)