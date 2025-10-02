// WindowLayoutTest_20250930_Grid.scd
// v1.4 - GridLayout (3x2), crisp borders, coloured labels, correct var placement
// MD 20250930-1210

/*
Purpose:
  - Fix the var-placement syntax error and ensure a proper GridLayout with shared columns.
  - Provide thin (1px) outlines and coloured pane-name bars in debug mode.
  - Draw borders in local coordinates to avoid offsets and “overlap” artifacts.

Style:
  - var-first declarations, descriptive lowercase names, no non-local returns.
  - Returns '-> a Window'.
*/

(
var debugLayout = true;
var outlineContentOnly = false;   // true = border excludes label; false = includes label

// ---- declare ALL vars up front (SuperCollider requirement) ----
var window, grid;

var topLeftText, topLeftMeter, topRightText, topRightMeter;
var systemStateText, diagnosticMessagesText;
var choicesText, receivingCommandsText;

var outerMargin, cellSpacing, paneMargin, paneSpacing, labelFixedHeight, strokeWidth, strokeInset;

var makePane;
var topLeftPane, topRightPane, systemStatePane, diagnosticPane, choicesPane, receivingPane;

// ---- geometry constants ----
outerMargin = 12;       // margins around the entire grid
cellSpacing = 12;       // spacing between grid cells
paneMargin = 8;         // inner padding inside each pane
paneSpacing = 6;        // gap between label and content inside a pane
labelFixedHeight = 22;  // stable label height so borders don't jump
strokeWidth = 1;        // thin outline
strokeInset = strokeWidth * 0.5;

// ---- helper: construct one pane (UserView) with label bar + thin outline ----
makePane = { |contentLayout, labelString, debugColor|
    var strokeColor, labelStringToShow, labelView, innerLayout, containerView;

    strokeColor = if(debugLayout, { debugColor }, { Color.gray(0.55) });
    labelStringToShow = if(debugLayout, { labelString }, { "---" });

    // Label bar
    labelView = StaticText()
        .string_(labelStringToShow)
        .align_(\center)
        .stringColor_(Color.white)
        .background_(strokeColor)
        .fixedHeight_(labelFixedHeight)
        .resize_(3); // fill horizontally

    // Stack label above the content
    innerLayout = VLayout(
        labelView,
        contentLayout
    )
    .margins_(paneMargin)
    .spacing_(paneSpacing);

    // Container: fills its grid cell and draws its own outline in LOCAL coordinates
    containerView = UserView()
        .layout_(innerLayout)
        .resize_(3); // fill both directions

    containerView.drawFunc_({ |view|
        var w, h, rect;
        w = view.bounds.width;
        h = view.bounds.height;

        if(outlineContentOnly, {
            // outline content area only (exclude the label bar)
            rect = Rect(
                paneMargin + strokeInset,
                paneMargin + labelFixedHeight + paneSpacing + strokeInset,
                w - (2 * paneMargin) - (2 * strokeInset),
                h - (2 * paneMargin) - labelFixedHeight - paneSpacing - (2 * strokeInset)
            );
        }, {
            // outline the entire pane (including the label bar)
            rect = Rect(strokeInset, strokeInset, w - (2 * strokeInset), h - (2 * strokeInset));
        });

        Pen.use {
            Pen.color = strokeColor;
            Pen.width = strokeWidth;
            Pen.addRect(rect);
            Pen.stroke;
        };
    });

    containerView
};

// ---- close any existing window with the same name ----
Window.allWindows.do({ |w|
    if(w.name == "Layout Test", { w.close });
});

// ---- create window ----
window = Window("Layout Test", Rect(100, 100, 800, 600))
    .background_(Color.white)
    .front;

// ---- build pane contents ----
topLeftPane = makePane.(
    VLayout(
        HLayout(
            topLeftText = TextView()
                .string_("Top Left Text Area")
                .minWidth_(80)
                .minHeight_(100)
                .resize_(3),
            topLeftMeter = LevelIndicator()
                .numTicks_(10)
                .style_(\led)
                .fixedWidth_(30)  // keep rail width fixed
                .resize_(2)       // vertical stretch only
        )
    ),
    "Top Left Pane",
    Color.red(1.0, 0.55)
);

topRightPane = makePane.(
    VLayout(
        HLayout(
            topRightText = TextView()
                .string_("Top Right Text Area")
                .minWidth_(80)
                .minHeight_(100)
                .resize_(3),
            topRightMeter = LevelIndicator()
                .numTicks_(10)
                .style_(\led)
                .fixedWidth_(30)
                .resize_(2)
        )
    ),
    "Top Right Pane",
    Color.blue(1.0, 0.55)
);

systemStatePane = makePane.(
    VLayout(
        StaticText().string_("System State").align_(\center).resize_(3),
        systemStateText = TextView()
            .string_("System state info here...")
            .minHeight_(100)
            .resize_(3)
    ),
    "System State",
    Color.green(1.0, 0.55)
);

diagnosticPane = makePane.(
    VLayout(
        StaticText().string_("Diagnostic Messages").align_(\center).resize_(3),
        diagnosticMessagesText = TextView()
            .string_("Diagnostic messages here...")
            .minHeight_(100)
            .resize_(3)
    ),
    "Diagnostic Messages",
    Color.yellow(1.0, 0.6)
);

choicesPane = makePane.(
    VLayout(
        StaticText().string_("Choices").align_(\center).resize_(3),
        choicesText = TextView()
            .string_("Choices text here...")
            .minHeight_(100)
            .resize_(3)
    ),
    "Choices",
    Color.magenta(1.0, 0.5)
);

receivingPane = makePane.(
    VLayout(
        StaticText().string_("Receiving Commands").align_(\center).resize_(3),
        receivingCommandsText = TextView()
            .string_("Receiving commands text here...")
            .minHeight_(100)
            .resize_(3)
    ),
    "Receiving Commands",
    Color.cyan(1.0, 0.6)
);

// ---- compose a 3x2 grid and assign to the window ----
// Safer, version-agnostic approach: create the grid and add cells explicitly.
grid = GridLayout()
    .margins_(outerMargin)
    .spacing_(cellSpacing);

// Place panes by (row, col)
grid.add(topLeftPane,     0, 0);
grid.add(topRightPane,    0, 1);
grid.add(systemStatePane, 1, 0);
grid.add(diagnosticPane,  1, 1);
grid.add(choicesPane,     2, 0);
grid.add(receivingPane,   2, 1);

// Optional (if available in your SC build): set column/row stretch to balance space
// (safe to comment out if your SC doesn't support these)
// grid.setColumnStretch(0, 1);
// grid.setColumnStretch(1, 1);
// grid.setRowStretch(0, 2);   // make the top row taller if you wish
// grid.setRowStretch(1, 1);
// grid.setRowStretch(2, 1);

window.layout = grid;

if(debugLayout) {
    "DEBUG ON: GridLayout aligned; coloured labels + crisp thin outlines.".postln;
} {
    "DEBUG OFF: GridLayout aligned; neutral labels + thin grey outlines.".postln;
};

window  // -> a Window
)
