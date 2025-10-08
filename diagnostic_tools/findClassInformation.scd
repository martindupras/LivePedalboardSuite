// Base file for the instance-side class:
LPDisplayLayoutWindow.filenameSymbol.postln;

// Base file for the *meta* class (class-side):
LPDisplayLayoutWindow.class.filenameSymbol.postln;

// List methods *defined on* this class (instance side), with files:
LPDisplayLayoutWindow.methods.do { |m| [m.name, m.tryPerform(\filenameSymbol)].postln };

// List methods *defined on* the meta-class (class side), with files:
LPDisplayLayoutWindow.class.methods.do { |m| [m.name, m.tryPerform(\filenameSymbol)].postln };

// Dump human-readable interfaces (if available in your build):
LPDisplayLayoutWindow.dumpInterface;     // methods defined *on* this class only
LPDisplayLayoutWindow.dumpFullInterface; // includes inherited
