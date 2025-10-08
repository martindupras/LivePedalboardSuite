// Class_Introspection_TraceSelector_Short.scd
// v0.4.1
// MD 20251007-1425

/*
Purpose
- Trace where a selector is defined (instance side and class side):
  → which class in the inheritance chain defines it, and which file (basename only).

Style
- var-first; descriptive lowercase names; no server.sync; no audio/GUI ops.
*/

(
var targetClass, selectorSym, makeShortName, traceInstance, traceClass;

// ===== configure here =====
targetClass = LPDisplayLayoutWindow;  // class to inspect
selectorSym = \sendPaneText;          // selector to trace (change as needed)
// =====================================

makeShortName = { arg fileSymbol;
    var fileString, shortName;
    fileString = if (fileSymbol.isNil) { nil } { fileSymbol.asString };
    shortName = if (fileString.isNil) { "<unknown>" } { PathName(fileString).fileName };
    shortName
};

traceInstance = {
    var line, walk, found;
    line = ("==== Trace (instance side) for " ++ selectorSym.asString ++ " ").padRight(70, "=");
    line.postln;
    walk = targetClass; found = false;
    while ({ walk.notNil }, {
        var meth;
        meth = walk.methods.detect({ arg m; m.name == selectorSym });
        if (meth.notNil) {
            ("Defined on " ++ walk.name.asString
                ++ "  file=" ++ makeShortName.value(meth.filenameSymbol)).postln;
            found = true;
            walk = nil; // stop
        }{
            walk = walk.superclass;
        };
    });
    if (found.not) { "Not found on this class nor its ancestors.".postln };
};

traceClass = {
    var line, walk, found;
    line = ("==== Trace (class side) for " ++ selectorSym.asString ++ " ").padRight(70, "=");
    line.postln;
    walk = targetClass.class; found = false;
    while ({ walk.notNil }, {
        var meth;
        meth = walk.methods.detect({ arg m; m.name == selectorSym });
        if (meth.notNil) {
            ("Defined on " ++ walk.name.asString
                ++ "  file=" ++ makeShortName.value(meth.filenameSymbol)).postln;
            found = true;
            walk = nil; // stop
        }{
            walk = walk.superclass;
        };
    });
    if (found.not) { "Not found on this meta-class nor its ancestors.".postln };
};

traceInstance.value;
traceClass.value;
)