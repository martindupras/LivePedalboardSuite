// Diag_MeterWiring_Inspector.scd
(
var wantedPaths, allDefs, summary, listForPath, printEntry;
wantedPaths = ["/md/levels", "/ampA", "/ampB"];
allDefs = OSCdef.all;
listForPath = { arg pathString;
    var matches;
    matches = List.new;
    allDefs.keysValuesDo({ arg keySym, defObj;
        var pathValue, portValue;
        pathValue = defObj.tryPerform(\path);
        if(pathValue == pathString) {
            portValue = defObj.tryPerform(\recvPort) ? NetAddr.langPort;
            matches.add([keySym, portValue])
        };
    });
    matches
};
printEntry = { arg pathString, entries;
    (pathString ++ ": " ++ entries.size.asString ++ " listener(s)").postln;
    entries.do({ arg one;
        var keySym, portValue;
        keySym = one[0]; portValue = one[1];
        ("  key=" ++ keySym.asString ++ " port=" ++ portValue.asString).postln;
    });
};
"=== Meter Wiring Inspector ===".postln;
summary = wantedPaths.collect({ arg p; [p, listForPath.(p)] });
summary.do({ arg pair;
    var pathString, entries;
    pathString = pair[0]; entries = pair[1];
    printEntry.(pathString, entries);
});
)
