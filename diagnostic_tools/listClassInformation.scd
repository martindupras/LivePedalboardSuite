// listClassInformation.scd
(
// Compact list of methods with *filename only* for a given class

var targetClass, makeShortName, listMethodsShort, listBaseFilesShort;

targetClass = LPDisplayLayoutWindow;  // <-- change as needed

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
    var line, methods, pairs, classMethods, classPairs;

    line = ("==== Instance methods (short) ").padRight(70, "=");
    line.postln;
    methods = targetClass.methods;  // methods defined *on* this class (instance-side)
    pairs = methods.collect({ arg m;
        var fileSym, shortName;
        fileSym = m.filenameSymbol;                    // standard in modern SC builds
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
    {
        var instFiles, metaFiles, hasExt;
        instFiles = pairs.collect({ arg p; p[1] }).as(Set);
        metaFiles = classPairs.collect({ arg p; p[1] }).as(Set);
        hasExt = (instFiles.size > 1) or: { metaFiles.size > 1 };
        if (hasExt) { "Hint: multiple distinct filenames detected → class extensions likely.".postln };
    }.value;
};

listBaseFilesShort.value;
listMethodsShort.value;
)