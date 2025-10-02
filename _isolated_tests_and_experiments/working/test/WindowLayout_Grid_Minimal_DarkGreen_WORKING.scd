// THIS IS WORKING, CLEAN AND UNDERSTOOD.


// WindowLayout_Grid_Minimal_DarkGreen.scd
// v1.1 - Minimal 3x2 grid with dark green labels + thin outlines
// MD 20250930

/*
Single-colour (dark green) labels and matching thin outlines for all panes in a 3x2 GridLayout.
*/

(
var window, makePane, paneColor;

// close any existing window with the same name
Window.allWindows.do({ |w| if(w.name == "Layout Test", { w.close }) });

// window
window = Window("Layout Test", Rect(100, 100, 800, 600))
    .background_(Color.white)
    .front;

// single colour (dark green)
paneColor = Color(0.0, 0.35, 0.0);

// helper: pane with coloured label + thin outline (local coords)
makePane = { |content, label|
    var labelView, inner, pane;
    labelView = StaticText()
        .string_(label)
        .align_(\center)
        .stringColor_(Color.white) // text colour
        .background_(paneColor);

    inner = VLayout(labelView, content);
    pane = UserView().layout_(inner);
    pane.drawFunc_({ |v|
        var w = v.bounds.width, h = v.bounds.height, inset = 0.5;
        Pen.use {
            Pen.color = paneColor;
            Pen.addRect(Rect(inset, inset, w - (2 * inset), h - (2 * inset)));
            Pen.stroke;
        };
    });
    pane
};

// grid (3 rows × 2 columns) with shared column boundaries
window.layout = GridLayout.rows(
    [
        makePane.(HLayout(TextView(), LevelIndicator()./*style_(\led).*/fixedWidth_(30)), "Top Left Pane"),
        makePane.(HLayout(TextView(), LevelIndicator().style_(\led).fixedWidth_(30)), "Top Right Pane")
    ],
    [
        makePane.(VLayout(StaticText().align_(\center), TextView()), "System State"),
        makePane.(VLayout(StaticText().align_(\center), TextView()), "Diagnostic Messages")
    ],
    [
        makePane.(VLayout(StaticText().align_(\center), TextView()), "Choices"),
        makePane.(VLayout(StaticText().align_(\center), TextView()), "Receiving Commands")
    ]
);

window  // -> a Window
)
