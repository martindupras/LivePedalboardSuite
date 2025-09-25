/////////////////////////////////////////////////////////////
// SixPanes_Layout_Grid.scd
// v0.1.0
// MD 2025-09-25 13:35
//
// Purpose / Style:
// - GUI-only: six colored panes arranged with GridLayout (3 rows x 2 columns).
// - Rules: var-first; descriptive lowercase names; no non-local returns; known-good SC syntax.
/////////////////////////////////////////////////////////////

(
var window, windowRect, windowBg, paneFill;
var titleFont, bodyFont, paneColors, paneTitles, makePane;
var p = Array.newClear(6);

// ---------- close prior MagicDisplayGUI windows ----------
Window.allWindows.do({ |w| var nameString; nameString = w.name.asString; if(nameString.beginsWith("MagicDisplayGUI"), { { w.close }.defer }); });

// ---------- window ----------
windowRect = Rect(80, 60, 1200, 850);
window = Window("MagicDisplayGUI SixPanes GridLayout", windowRect).alwaysOnTop_(true);
windowBg = Color(0.08, 0.08, 0.09);
paneFill = Color(0.15, 0.15, 0.18);
window.view.background_(windowBg);

// ---------- styles ----------
titleFont = Font("Helvetica-Bold", 16);
bodyFont  = Font("Menlo", 12);
paneColors = [Color.red, Color.green, Color.blue, Color.yellow, Color.magenta, Color.cyan];
paneTitles = ["top-left","top-right","middle-left","middle-right","bottom-left","bottom-right"];

// ---------- pane factory ----------
makePane = { |titleString, borderColor|
    var pane, border, titleText, bodyText;
    pane = UserView().background_(paneFill).minSize_(Size(500, 230));
    border = UserView(pane).resize_(1).drawFunc_({ |v|
        var rect; rect = Rect(1, 1, v.bounds.width - 2, v.bounds.height - 2);
        Pen.fillColor = Color(0.11,0.11,0.12); Pen.strokeColor = borderColor; Pen.width = 2;
        Pen.fillRect(rect); Pen.strokeRect(rect);
    });
    titleText = StaticText().string_(titleString).font_(titleFont).stringColor_(Color.white);
    bodyText  = StaticText().string_("Pane: " ++ titleString ++ "\nGUI-only layout test.").font_(bodyFont).stringColor_(Color(0.85,0.9,0.95));
    pane.layout_(VLayout(UserView().minHeight_(6), titleText, UserView().minHeight_(4), bodyText, nil));
    pane
};

// ---------- build array of six panes ----------
6.do({ |i| p[i] = makePane.(paneTitles[i], paneColors[i]) });

// ---------- grid layout: 3 rows × 2 columns ----------
window.layout_(GridLayout.rows(
    [ p[0], p[1] ],
    [ p[2], p[3] ],
    [ p[4], p[5] ]
));

window.front;
)
