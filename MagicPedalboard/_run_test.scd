(
// Robust test runner for MagicPedalboard.test
var proj = "/Users/martindupras/Library/CloudStorage/OneDrive-TheOpenUniversity/LivePedalboardSuite";
var f, bytes, txt;

// helper to safely interpret a file
var interpretFile = { arg path;
    f = File(path);
    f.open("r");
    bytes = f.readAll;
    f.close;
    txt = bytes.asString;
    Interpreter.interpret(txt);
};

interpretFile.(proj ++ "/MagicPedalboard/MagicPedalboard.sc");
interpretFile.(proj ++ "/MagicPedalboard/MagicPedalboard_docs.sc");

"Invoking MagicPedalboard.test (no runtime checks)".postln;
MagicPedalboard.test(false);

// exit when run non-interactively
thisProcess.exit;
)
