/////////////////////////////////////////////////////////////
// SixPanes_Layout_VH.scd
// v0.1.0
// MD 2025-09-25 13:35
//
// Purpose / Style:
// - GUI-only: draw 6 "pane" rectangles (colored borders) arranged with VLayout/HLayout.
// - No audio, no Ndefs, no server. Pure Qt layout.
// - Rules: var-first; descriptive lowercase names; no non-local returns; known-good SC syntax.
/////////////////////////////////////////////////////////////

(
var window, windowRect, windowBg, paneFill, cellPadding;
var titleFont, bodyFont, paneColors, paneTitles;
var makePane, row1, row2, row3, rootLayout;

// ---------- close prior MagicDisplayGUI windows ----------
Window.allWindows.do({ |w|
    var nameString;
    nameString = w.name.asString;
    if(nameString.beginsWith("MagicDisplayGUI"), { { w.close }.defer });
});

// ---------- window & styles ----------
windowRect = Rect(80, 60, 1200, 850);
window = Window("MagicDisplayGUI SixPanes VHLayout", windowRect).alwaysOnTop_(true);
windowBg = Color(0.08, 0.08, 0.09);
paneFill  = Color(0.15, 0.15, 0.18);
window.view.background_(windowBg);
cellPadding = 10;

titleFont = Font("Helvetica-Bold", 16);
bodyFont  = Font("Menlo", 12);

// six distinct colors and titles
paneColors = [Color.red, Color.green, Color.blue, Color.yellow, Color.magenta, Color.cyan];
paneTitles = ["top-left","top-right","middle-left","middle-right","bottom-left","bottom-right"];

// ---------- pane factory: a container with colored border and two text lines ----------
makePane = { |titleString, borderColor|
    var pane, border, titleText, bodyText;
    pane = UserView()  // no parent yet; layout will parent it
        .background_(paneFill)
        .minSize_(Size(500, 230)); // give layout something decent to work with

    border = UserView(pane)
        .resize_(1)
        .drawFunc_({ |v|
            var rect;
            rect = Rect(1, 1, v.bounds.width - 2, v.bounds.height - 2);
            Pen.fillColor = Color(0.11, 0.11, 0.12);
            Pen.strokeColor = borderColor;
            Pen.width = 2;
            Pen.fillRect(rect);
            Pen.strokeRect(rect);
        });

    titleText = StaticText()
        .string_(titleString)
        .font_(titleFont)
        .stringColor_(Color.white);

    bodyText = StaticText()
        .string_("Pane: " ++ titleString ++ "\nGUI-only layout test.")
        .font_(bodyFont)
        .stringColor_(Color(0.85, 0.9, 0.95));

    // inner stack inside each pane (title above body)
    pane.layout_(VLayout(
        // top margin shim
        UserView().minHeight_(6),
        titleText,
        UserView().minHeight_(4),
        bodyText,
        // bottom stretch
        nil
    ));

    pane
};

// ---------- build six panes ----------
row1 = HLayout(
    makePane.(paneTitles[0], paneColors[0]),
    UserView().minWidth_(cellPadding), // spacer
    makePane.(paneTitles[1], paneColors[1])
);

row2 = HLayout(
    makePane.(paneTitles[2], paneColors[2]),
    UserView().minWidth_(cellPadding),
    makePane.(paneTitles[3], paneColors[3])
);

row3 = HLayout(
    makePane.(paneTitles[4], paneColors[4]),
    UserView().minWidth_(cellPadding),
    makePane.(paneTitles[5], paneColors[5])
);

// ---------- root layout: 3 rows stacked, with vertical spacers ----------
rootLayout = VLayout(
    UserView().minHeight_(cellPadding), // top margin
    row1,
    UserView().minHeight_(cellPadding),
    row2,
    UserView().minHeight_(cellPadding),
    row3,
    UserView().minHeight_(cellPadding)  // bottom margin
);

// install the layout on the window
window.layout_(rootLayout);
window.front;
)
