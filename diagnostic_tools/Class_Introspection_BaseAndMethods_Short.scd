// Class_Introspection_BaseAndMethods_Short.scd
// v0.6.1
// MD 20251007-1425

/*
Purpose
- Print compact origins (filename only) for:
  1) The class's base file (instance side) and meta-class base file (class side).
  2) All methods defined *on* the class (instance side) and on the meta-class (class side).
- Helps spot class extensions quickly (multiple distinct filenames).

Style
- var-first; descriptive lowercase names; no server.sync; no audio/GUI ops.
- Uses only standard SC selectors (Class:filenameSymbol, Method:filenameSymbol, .methods, .name).
*/

(
var targetClass, makeShortName, listBaseFilesShort, listMethodsShort;

// ===== configure here =====
targetClass = LPDisplayLayoutWindow;  // <- change this to inspect a different class
// =====================================

// Convert Method.filenameSymbol (or class filenameSymbol) into a short basename.
makeShortName = { arg fileSymbol;
    var fileString, shortName;
    fileString = if (fileSymbol.isNil) { nil } { fileSymbol.asString };
    shortName = if (fileString.isNil) { "<unknown>" } { PathName(fileString).fileName };
    shortName
};

listBaseFilesShort = {
    var instSym, metaSym, instShort, metaShort, line;
    instSym = targetClass.filenameSymbol;
    metaSym = targetClass.class.filenameSymbol;
    instShort = makeShortName.value(instSym);
    metaShort = makeShortName.value(metaSym);

    line = ("==== Class base files (short) ").padRight(70, "=");
    line.postln;
    ("instance-side  : " ++ instShort).postln;
    ("class-side     : " ++ metaShort).postln;
};

listMethodsShort = {
    var line, methods, pairs, classMethods, classPairs, instFiles, metaFiles, hasExt;

    line = ("==== Instance methods (short) ").padRight(70, "=");
    line.postln;
    methods = targetClass.methods;  // methods defined on this class (instance-side)
    pairs = methods.collect({ arg m;
        var fileSym, shortName;
        fileSym = m.filenameSymbol;                    // standard Method API
        shortName = makeShortName.value(fileSym);
        [m.name, shortName]
    });
    pairs.sort({ arg a, b; a[0].asString < b[0].asString }).do(_.postln);

    line = ("==== Class methods (short) ").padRight(70, "=");
    line.postln;
    classMethods = targetClass.class.methods;          // methods defined on the meta-class
    classPairs = classMethods.collect({ arg m;
        var fileSym, shortName;
        fileSym = m.filenameSymbol;
        shortName = makeShortName.value(fileSym);
        [m.name, shortName]
    });
    classPairs.sort({ arg a, b; a[0].asString < b[0].asString }).do(_.postln);

    // Quick extension hint
    instFiles = pairs.collect({ arg p; p[1] }).as(Set);
    metaFiles = classPairs.collect({ arg p; p[1] }).as(Set);
    hasExt = (instFiles.size > 1) or: { metaFiles.size > 1 };
    if (hasExt) { "Hint: multiple distinct filenames detected → class extensions likely.".postln };
};

listBaseFilesShort.value;
listMethodsShort.value;
)
