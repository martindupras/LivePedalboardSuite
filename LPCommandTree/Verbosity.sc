// Verbosity.sc
// MD 20250819

// used to manage verbosity levels of my debugging messages

// Verbosity Levels:
// 0 → Errors only
// 1 → Actions
// 2 → Input/Output
// 3 → Object and type reporting
// 4 → Full debug (everything)






// Verbosity.sc
Verbosity {
    classvar <level = 2; // Default level

	*help {
    "Verbosity Levels:".postln;
    "0 → Errors only".postln;
    "1 → Actions".postln;
    "2 → Input/Output".postln;
    "3 → Object and type reporting".postln;
    "4 → Full debug (everything)".postln;
}


    *setLevel { |newLevel|
        level = newLevel;
        ("🔧 Verbosity level set to: " ++ level).postln;
    }

    *shouldPost { |requiredLevel|
        ^level >= requiredLevel;
    }

    *postIf { |requiredLevel, msg|
        if (level >= requiredLevel) {
            msg.postln;
        };
    }
}
