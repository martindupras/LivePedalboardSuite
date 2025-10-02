// sendTextToWindowLayout_Grid_Minimal_DarkGreen.scd
// v1.0
// MD 20250930-1303

(
// Attach + simple text helpers for "Layout Test"
var win, collect, views;

views = List.new;
win = Window.allWindows.detect({ |w| w.name == "Layout Test" });

// look for window called "Layout Test"
if(win.isNil) { "No window named 'Layout Test'.".warn; } {
    collect = { |v|
        views.add(v);
        v.children.do({ |c| collect.(c) });
    };
    collect.(win.view);

    ~textViews = views.select({ |v| v.isKindOf(TextView) }); // collect the textviews

    // Set ALL panes' TextView to the same string
    ~broadcastText = { |txt|
        ~textViews.do({ |tv| tv.string_(txt) });
    };

    // Set a specific pane's TextView by its header label (green bar text)
    ~setPaneText = { |paneLabel, txt|
        var paneUserView, tv;

        // Find the pane's UserView by looking for a child StaticText whose .string == paneLabel
        paneUserView = views.detect({ |v|
            v.isKindOf(UserView) and: {
                v.children.any({ |c| c.isKindOf(StaticText) and: { c.string == paneLabel } })
            }
        });

        if(paneUserView.isNil) {
            "Pane not found: %".format(paneLabel).warn;
        } {
            // Pick the first TextView inside that pane and set its string
            tv = paneUserView.children.detect({ |c| c.isKindOf(TextView) });
            if(tv.isNil) {
                "No TextView in pane: %".format(paneLabel).warn;
            } {
                tv.string_(txt);
            };
        };
    };

    "Text helpers ready. Use ~broadcastText.(...) or ~setPaneText.(\"System State\", ...).".postln;
};
)

/*
To use:

~setPaneText.("System State","Testing Be-bop-a-lula")
~setPaneText.("Top Left Pane","I was a fiend...")
~broadcastText.("test")  // works

*/