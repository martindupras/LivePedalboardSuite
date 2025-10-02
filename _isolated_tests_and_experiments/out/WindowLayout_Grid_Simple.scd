// WindowLayout_Grid_Simple.scd
// v1.0 - Minimal grid with debug outlines + coloured labels
// MD 20250930-1216

/*
Purpose:
  - Minimal 3x2 GridLayout with thin outlines and coloured pane labels controlled by debugLayout.

Style:
  - var-first declarations, descriptive names, no non-local returns.
  - Returns '-> a Window'.
*/

(
var debugLayout = true;

var window, grid;

var topLeftText, topLeftMeter, topRightText, topRightMeter;
var systemStateText, diagnosticMessagesText;
var choicesText, receivingCommandsText;

var outerMargin, cellSpacing, paneMargin, paneSpacing, labelFixedHeight, strokeWidth;

var makePane;
var topLeftPane, topRightPane, systemStatePane, diagnosticPane, choicesPane, receivingPane;

// geometry
outerMargin = 12;
cellSpacing = 12;
paneMargin = 8;
paneSpacing = 6;
labelFixedHeight = 22;
strokeWidth = 1;

// helper: pane with coloured label + thin outline (local coords)
makePane = { |contentLayout, labelString, debugColor|
    var strokeColor, labelStringToShow, labelView, innerLayout, containerView;

    strokeColor = if(debugLayout, { debugColor }, { Color.gray(0.55) });
    labelStringToShow = if(debugLayout, { labelString }, { "---" });

    labelView = StaticText()
        .string_(labelStringToShow)
        .align_(\center)
        .stringColor_(Color.white)
        .background_(strokeColor)
        .fixedHeight_(labelFixedHeight);

    innerLayout = VLayout(
        labelView,
        contentLayout
    )
    .margins_(paneMargin)
    .spacing_(paneSpacing);

    containerView = UserView()
        .layout_(innerLayout);

    containerView.drawFunc_({ |view|
        var w, h, inset;
        w = view.bounds.width;
        h = view.bounds.height;
        inset = strokeWidth * 0.5;  // crisp 1px

        Pen.use {
            Pen.color = strokeColor;
            Pen.width = strokeWidth;
            Pen.addRect(Rect(inset, inset, w - (2 * inset), h - (2 * inset)));
            Pen.stroke;
        };
    });

    containerView
};

// close any existing window named "Layout Test"
Window.allWindows.do({ |w| if(w.name == "Layout Test", { w.close }) });

// window
window = Window("Layout Test", Rect(100, 100, 800, 600))
    .background_(Color.white)
    .front;

// panes
topLeftPane = makePane.(
    VLayout(
        HLayout(
            topLeftText = TextView(),
            topLeftMeter = LevelIndicator().style_(\led).fixedWidth_(30)
        )
    ),
    "Top Left Pane",
    Color.red(1.0, 0.55)
);

topRightPane = makePane.(
    VLayout(
        HLayout(
            topRightText = TextView(),
            topRightMeter = LevelIndicator().style_(\led).fixedWidth_(30)
        )
    ),
    "Top Right Pane",
    Color.blue(1.0, 0.55)
);

systemStatePane = makePane.(
    VLayout(
        StaticText().string_("System State").align_(\center),
        systemStateText = TextView()
    ),
    "System State",
    Color.green(1.0, 0.55)
);

diagnosticPane = makePane.(
    VLayout(
        StaticText().string_("Diagnostic Messages").align_(\center),
        diagnosticMessagesText = TextView()
    ),
    "Diagnostic Messages",
    Color.yellow(1.0, 0.6)
);

choicesPane = makePane.(
    VLayout(
        StaticText().string_("Choices").align_(\center),
        choicesText = TextView()
    ),
    "Choices",
    Color.magenta(1.0, 0.5)
);

receivingPane = makePane.(
    VLayout(
        StaticText().string_("Receiving Commands").align_(\center),
        receivingCommandsText = TextView()
    ),
    "Receiving Commands",
    Color.cyan(1.0, 0.6)
);

// grid (3 rows x 2 columns) with shared column boundaries
grid = GridLayout.rows(
    [topLeftPane,     topRightPane],
    [systemStatePane, diagnosticPane],
    [choicesPane,     receivingPane]
)
.margins_(outerMargin)
.spacing_(cellSpacing);

window.layout = grid;

window  // -> a Window
)
