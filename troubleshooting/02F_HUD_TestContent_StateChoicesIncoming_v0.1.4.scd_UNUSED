// 02F_HUD_TestContent_StateChoicesIncoming.scd
// v0.1.4
// MD 2025-09-29 13:20 BST

/* Purpose
 - Write demo text to the HUD via the overlay helpers created by 02H:
   • STATE line
   • CHOICES multiline
Style
 - var-first; AppClock-only UI; no server.sync; idempotent.
 - Assumes 02H_GridDemo_MinHUD_Overlay.scd has already run in this session.
*/

(
var ensureOverlayThenPush;

ensureOverlayThenPush = {
    // If overlay is missing for any reason, create it on the fly:
    if(~gui.isNil or: { ~gui.tryPerform(\window).isNil }) {
        // fall back to GridDemo and create overlay
        Window.allWindows
        .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
        .do(_.close);
        ~gui = MagicDisplayGUI_GridDemo.new;
        ~gui.window.front.alwaysOnTop_(true);
    };

    // If helper funcs don’t exist yet, synthesize the minimal overlay now:
    if(~hud_setState.isNil or: { ~hud_setChoices.isNil }) {
        // create a tiny overlay inline (same as 02H but shorter)
        var host, r, panel, stateBox, choicesBox, pad = 8, width = 360, height = 220, titleH = 18;

        host = ~gui.tryPerform(\window).tryPerform(\view);
        r = host.bounds;

        panel = CompositeView(host).name_("MDG_MINHUD");
        panel.background = Color(0,0,0,0.30);
        panel.bounds = Rect(r.width - (width + 12), 12, width, height);

        StaticText(panel).string_("MIN-HUD").font_(Font("Monaco", 13))
            .stringColor_(Color(1,1,1,0.8))
            .bounds_(Rect(pad, pad, width - 2*pad, titleH));

        stateBox = TextView(panel).string_("(state line)").font_(Font("Monaco", 12))
            .background_(Color(0,0,0,0.10))
            .stringColor_(Color.white)
            .bounds_(Rect(pad, pad + titleH + 4, width - 2*pad, 22));

        choicesBox = TextView(panel).string_("(choices)").editable_(false)
            .font_(Font("Monaco", 11))
            .background_(Color(0,0,0,0.10))
            .stringColor_(Color(0.95,0.95,0.95))
            .bounds_(Rect(pad, pad + titleH + 4 + 22 + 6, width - 2*pad, height - (titleH + 4 + 22 + 6 + pad)));

        ~hud_setState = { arg textString; AppClock.sched(0.0, { stateBox.string = textString.asString; nil }) };
        ~hud_setChoices = { arg linesArray; var s = (linesArray ? []).collect(_.asString).join("\n");
                            AppClock.sched(0.0, { choicesBox.string = s; nil }) };
    };

    // ——— Actual demo content push ———
    ~hud_setState.("Mode: treeNav · A=ACTIVE");
    ~hud_setChoices.([
        "fret 3 → add",
        "fret 5 → timebased",
        "fret 7 → modulation",
        "fret 9 → filter"
    ]);
};

AppClock.sched(0.00, { ensureOverlayThenPush.value; nil });
)
