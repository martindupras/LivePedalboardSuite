// 02F_HUD_TestContent_StateChoicesIncoming.scd
// v0.1.5
// MD 2025-09-29 13:28 BST

/* Purpose
 - Write demo text to the HUD via overlay helpers created by 02H/02M:
   • STATE line
   • CHOICES multiline
Style
 - var-first; AppClock-only UI; no server.sync; idempotent.
*/

(
var ensureOverlayThenPush;

ensureOverlayThenPush = {
    var host, overlay;

    // Ensure ~gui and overlay exist
    if(~gui.isNil) {
        Window.allWindows
        .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
        .do(_.close);
        ~gui = MagicDisplayGUI_GridDemo.new;
        ~gui.window.front.alwaysOnTop_(true);
    };

    host = ~gui.tryPerform(\window).tryPerform(\view);
    overlay = host.children.detect({ |v| (v.tryPerform(\name) ? "") == "MDG_MINHUD" });

    if(overlay.isNil) {
        // run 02H inline if needed (minimal version)
        var r, panel, title, stateBox, choicesBox;
        var pad, width, height, titleH, stateH;
        r = host.bounds; width = 320; height = 170; pad = 8; titleH = 16; stateH = 18;

        panel = CompositeView(host).name_("MDG_MINHUD");
        panel.background = Color(0,0,0,0.28);
        panel.border = 1; panel.borderColor = Color(1,1,1,0.25);
        panel.bounds = Rect(r.width - (width + 12), 10, width, height);
        panel.front;

        title = StaticText(panel).string_("MIN-HUD").font_(Font("Monaco", 12))
                .stringColor_(Color(1,1,1,0.82))
                .bounds_(Rect(pad, pad, width - 2*pad, titleH));

        stateBox = TextView(panel).string_("(state)").font_(Font("Monaco", 11))
                   .background_(Color(0,0,0,0.10)).stringColor_(Color.white)
                   .bounds_(Rect(pad, pad + titleH + 4, width - 2*pad, stateH));

        choicesBox = TextView(panel).string_("(choices)").editable_(false)
                     .font_(Font("Monaco", 10)).background_(Color(0,0,0,0.10))
                     .stringColor_(Color(0.93,0.93,0.93))
                     .bounds_(Rect(pad, pad + titleH + 4 + stateH + 6, width - 2*pad, height - (titleH + 4 + stateH + 6 + pad)));

        ~hud_setState = { arg textString; AppClock.sched(0.0, { stateBox.string = textString.asString; nil }) };
        ~hud_setChoices = { arg linesArray; var s = (linesArray ? []).collect(_.asString).join("\n");
                            AppClock.sched(0.0, { choicesBox.string = s; nil }) };
    };

    // ——— Actual content push ———
    (~hud_setState !? { ~hud_setState.("Mode: treeNav · A=ACTIVE") });
    (~hud_setChoices !? {
        ~hud_setChoices.([
            "fret 3 → add",
            "fret 5 → timebased",
            "fret 7 → modulation",
            "fret 9 → filter"
        ])
    });
};

AppClock.sched(0.00, { ensureOverlayThenPush.value; nil });
)
