// Test_LPDisplayLayoutWindow_LayoutSnapshot.scd
// v0.1.1
// MD 20251003-1115

/* Purpose/Style:
- Build a textual snapshot of LPDisplayLayoutWindow's view tree (class, optional name, bounds).
- Writes to <Extensions>/LivePedalboardSuite/reports/LPDisplayLayoutWindow_layout_snapshot.txt
- Known-good SC only: no 'trim', no PathName.mkdir/exists, uses File.mkdir/File.use.
- Returns '-> a Window' so acceptance is visible.
*/

(
var createdWindow, reportDir, reportPath, lines, walkView;

("Running: Test_LPDisplayLayoutWindow_LayoutSnapshot.scd").postln;

reportDir = Platform.userExtensionDir +/+ "LivePedalboardSuite" +/+ "reports";
File.exists(reportDir).if({ }, { File.mkdir(reportDir) });
reportPath = reportDir +/+ "LPDisplayLayoutWindow_layout_snapshot.txt";

lines = List.new;

walkView = { |view, depth=0|
    var indent, clsStr, nameStr, boundsStr, line;
    indent = Array.fill(depth, { "  " }).join;  // two spaces per depth level
    clsStr = view.class.name.asString;
    nameStr = view.respondsTo(\name).if({ view.name.asString }, { "" });
    // If you want trimming, use stripWhiteSpace (not trim):
    nameStr = nameStr.stripWhiteSpace;
    boundsStr = view.bounds.asString;

    line = indent
        ++ clsStr
        ++ (nameStr.size == 0).if({ "" }, { " name:" ++ nameStr })
        ++ " bounds:" ++ boundsStr;

    lines.add(line);

    view.children.do({ |child|
        walkView.(child, depth + 1);
    });
};

createdWindow = LPDisplayLayoutWindow.respondsTo(\open).if({
    LPDisplayLayoutWindow.open
}, {
    LPDisplayLayoutWindow.new
});

createdWindow.front;

walkView.(createdWindow.view, 0);

// write snapshot
File.use(reportPath, "w", { |f|
    f.write(lines.join(Char.nl.asString))
});

("Wrote: " ++ reportPath).postln;

// Return the window so SC prints '-> a Window'
createdWindow
)
