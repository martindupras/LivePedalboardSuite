// aSingleWindowPane.scd
// v1.0 -- WORKING
// MD 20250930

// Let's try to pain a single outlined window pane.


/*
Purpose:
  - Show a minimal example: one window with one pane that has a thin contrasting outline.
*/


(
var debugLayout = true; // shows outline and pane name

var window, paneContainer, paneLayout;
var labelView, contentView;
var strokeColor;

strokeColor = if(debugLayout, { Color.red(1.0, 0.6) }, { Color.gray(0.55) });

// Close any previous window with the same name
Window.allWindows.do({ |w| if(w.name == "First Principles", { w.close }) });

// Create the window
window = Window("First Principles", Rect(150, 150, 420, 260))
    .background_(Color.white)
    .front;

// Minimal pane content: a label bar + a text area
labelView = StaticText()
    .string_(if(debugLayout, { "Pane" }, { "---" }))
    .align_(\center)
    .stringColor_(Color.white)
    .background_(strokeColor)
    .fixedHeight_(22);

contentView = TextView()
    .string_("Content goes here…")
    .minHeight_(140);

// Stack the label above the content
paneLayout = VLayout(
    labelView,
    contentView
)
.margins_(8)      // inner padding
.spacing_(6);

// The pane container that draws its own outline
paneContainer = UserView()
    .layout_(paneLayout);

// Draw a thin outline around the whole pane in **local** coordinates
paneContainer.drawFunc_({ |view|
    var b, rect;
    b = view.bounds;  // we only use width/height — origin is local (0, 0)
    rect = Rect(0.5, 0.5, b.width - 1, b.height - 1);
    Pen.use {
        Pen.color = strokeColor;
        Pen.width = 1;
        Pen.addRect(rect);
        Pen.stroke;
    };
});

// Put the single pane into the window, with some outer margin
window.layout = VLayout(
    paneContainer
)
.margins_(12)
.spacing_(12);

window  // -> a Window
)
