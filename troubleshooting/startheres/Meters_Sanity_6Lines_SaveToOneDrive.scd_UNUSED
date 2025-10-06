// Meters_Sanity_6Lines_SaveToOneDrive.scd
// v0.1.0
// MD timestamp: 2025-09-26 16:13 GMT+1

/*
Purpose
- Subscribe to /md/levels taps (A=2001, B=2002), sample 3 times, and print exactly 6 lines:
  "MDMTR: A (L,R)=(x.xx,y.yy)" then "MDMTR: B (L,R)=(x.xx,y.yy)" per sample.
- Save the 6 lines to OneDrive: ~/Library/CloudStorage/OneDrive-TheOpenUniversity/SC_MPB_Test/md_meters_<stamp>.txt
- Finite; auto-stops; cleans responders.

Style / Guard Rails
- Single () block; VAR-FIRST; no non-local returns.
- AppClock used for timing only; finite duration.
*/

(
var aLevels, bLevels, lines, sampleIndex, maxSamples, appTask, startTime;
var dirPath, pathName, filePath, stamp, makeDir;
var oscA, oscB, formatLine, writeFile, printLine;
var levelsUpdatedA, levelsUpdatedB;

aLevels = [0.0, 0.0];
bLevels = [0.0, 0.0];
levelsUpdatedA = false;
levelsUpdatedB = false;

lines = List.new;
sampleIndex = 0;
maxSamples = 3;
startTime = thisThread.seconds;

dirPath = Platform.userHomeDir +/+ "Library/CloudStorage/OneDrive-TheOpenUniversity/SC_MPB_Test";
stamp = Date.getDate.stamp.replace($:, $_); // safe for file names
pathName = PathName(dirPath);
filePath = dirPath +/+ ("md_meters_" ++ stamp ++ ".txt");

makeDir = {
    pathName.isFolder.if({ }, { pathName.mkdirAll; });
};

formatLine = { arg label, lr;
    var l, r;
    l = (lr[0] ? 0.0).asFloat.max(0.0);
    r = (lr[1] ? 0.0).asFloat.max(0.0);
    ("MDMTR: " ++ label ++ " (L,R)=(" ++ l.round(0.001) ++ "," ++ r.round(0.001) ++ ")")
};

printLine = { arg text; text.postln; };

writeFile = {
    var f;
    makeDir.();
    f = File(filePath, "w");
    lines.do { arg ln; f.write(ln ++ Char.nl) };
    f.close;
    ("[MDMTR] wrote " ++ filePath).postln;
    filePath
};

// OSC responders: expect messages like /md/levels, id, ... , L, R.
// We match on reply id and pull the last two floats if present.
oscA = OSCdef(\mdLevelsA, { arg msg, time, addr, recvPort;
    var vals, l, r;
    (msg.size >= 4).if({
        vals = msg.copyRange( (msg.size-2), (msg.size-1) );
        l = vals[0].asFloat;
        r = vals[1].asFloat;
        aLevels = [l, r];
        levelsUpdatedA = true;
    });
}, '/md/levels', recvPort:nil, srcID:nil, argTemplate:[2001]);

oscB = OSCdef(\mdLevelsB, { arg msg, time, addr, recvPort;
    var vals, l, r;
    (msg.size >= 4).if({
        vals = msg.copyRange( (msg.size-2), (msg.size-1) );
        l = vals[0].asFloat;
        r = vals[1].asFloat;
        bLevels = [l, r];
        levelsUpdatedB = true;
    });
}, '/md/levels', recvPort:nil, srcID:nil, argTemplate:[2002]);

appTask = AppClock.sched(0.1, {
    var doOne;
    doOne = {
        var lineA, lineB;
        lineA = formatLine.("A", aLevels);
        lineB = formatLine.("B", bLevels);
        printLine.(lineA);
        printLine.(lineB);
        lines.add(lineA);
        lines.add(lineB);
        sampleIndex = sampleIndex + 1;
        levelsUpdatedA = false;
        levelsUpdatedB = false;
    };

    (sampleIndex < maxSamples).if({
        doOne.();
        0.6
    }, {
        OSCdef(\mdLevelsA).free;
        OSCdef(\mdLevelsB).free;
        writeFile.();
        nil
    })
});
"MDMTR: starting 3× sampling (A=2001, B=2002)…".postln;
filePath
)
