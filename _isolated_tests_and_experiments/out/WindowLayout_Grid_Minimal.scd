// WindowLayout_Grid_Minimal.scd
// v1.1 - Ultra-simple 3x2 grid with debug outlines + coloured labels
// MD 20250930

(
var debugLayout = true;

var window, grid;
var makePane;

makePane = { |content, label, color|
    var strokeColor = if(debugLayout, { color }, { Color.gray(0.55) });
    var labelText = if(debugLayout, { label }, { "---" });
    var labelView = StaticText()
        .string_(labelText)
        .align_(\center)
        .stringColor_(Color.white)
        .background_(strokeColor)
        .fixedHeight_(22);
    var inner = VLayout(labelView, content).margins_(8).spacing_(6);
    var pane = UserView().layout_(inner);
    pane.drawFunc_({ |v|
        var w = v.bounds.width, h = v.bounds.height, inset = 0.5;
        Pen.use {
            Pen.color = strokeColor;
            Pen.width = 1;
            Pen.addRect(Rect(inset, inset, w - 1, h - 1));
            Pen.stroke;
        };
    });
    pane
};

Window.allWindows.do({ |w| if(w.name == "Layout Test", { w.close }) });

window = Window("Layout Test", Rect(100, 100, 800, 600))
    .background_(Color.white)
    .front;

grid = GridLayout.rows(
    [makePane.(HLayout(TextView(), LevelIndicator().style_(\led).fixedWidth_(30)), "Top Left", Color.blue),
     makePane.(HLayout(TextView(), LevelIndicator().style_(\led).fixedWidth_(30)), "Top Right", Color.blue)],
    [makePane.(TextView(), "System State", Color.green),
     makePane.(TextView(), "Diagnostics", Color.green)],
    [makePane.(TextView(), "Choices", Color.green),
     makePane.(TextView(), "Receiving", Color.green)]
).margins_(12).spacing_(12);

window.layout = grid;
window
)
