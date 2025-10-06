// TempGUIChoicesWindows.scd
// MD 20250922-1653
(
// Floating "Choices" window (always-on-top, readable)
var titleColor = Color(0.12, 0.12, 0.12);
var textColor = Color(0.10, 0.10, 0.10);
var bgColor = Color(0.98, 0.98, 0.98, 0.98);

if(~choicesWin.notNil and: { ~choicesWin.isClosed.not }) { ~choicesWin.close };
~choicesWin = Window("Choices", Rect(30, 120, 380, 220))
    .alwaysOnTop_(true);
~choicesWin.view.background_(bgColor);

~choicesWin_title = StaticText(~choicesWin, Rect(8, 6, 364, 16))
    .string_("Choices")
    .stringColor_(titleColor);

~choicesWin_text = TextView(~choicesWin, Rect(8, 26, 364, 186))
    .string_("—")
    .editable_(false)
    .hasVerticalScroller_(true)
    .background_(bgColor)
    .stringColor_(textColor)
    .font_(Font("Menlo", 12));

~choicesSet = { |items|
    var s = (items ? []).collect(_.asString).join("\n");
    AppClock.sched(0.0, {
        if(~choicesWin_text.notNil) {
            ~choicesWin_text.string_((s.size > 0).if({ s }, { "—" }));
        };
        nil
    });
};

~choicesWin.front;
~choicesSet.([
    "fret 7 → delay",
    "fret 9 → tremolo",
    "fret 11 → switch"
]);
"✅ Floating Choices window ready (stop watcher: ~choicesWatcher.stop; close: ~choicesWin.close).".postln;
)
