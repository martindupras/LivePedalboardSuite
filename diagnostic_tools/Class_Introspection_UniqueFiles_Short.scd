// Class_Introspection_UniqueFiles_Short.scd
// v0.3.1
// MD 20251007-1425

/*
Purpose
- Print the *unique* filenames that define methods on a class (instance side) and on its meta-class.
- If more than one filename appears on either side, the class likely has extensions.

Style
- var-first; descriptive lowercase names; no server.sync; no audio/GUI ops.
*/

(
var targetClass, makeShortName, instanceFiles, classFiles;

// ===== configure here =====
targetClass = LPDisplayLayoutWindow;
// =====================================

makeShortName = { arg fileSymbol;
    var fileString, shortName;
    fileString = if (fileSymbol.isNil) { nil } { fileSymbol.asString };
    shortName = if (fileString.isNil) { "<unknown>" } { PathName(fileString).fileName };
    shortName
};

instanceFiles = targetClass.methods.collect({ arg m; makeShortName.value(m.filenameSymbol) }).as(Set);
classFiles    = targetClass.class.methods.collect({ arg m; makeShortName.value(m.filenameSymbol) }).as(Set);

("Instance-side unique files: " ++ instanceFiles.asArray.sort.asString).postln;
("Class-side    unique files: " ++ classFiles.asArray.sort.asString).postln;
)