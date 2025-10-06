// 02H_GridDemo_MinHUD_Overlay.scd
// v0.1.1
// MD 2025-09-29 13:20 BST

/* Purpose
 - Add a small overlay HUD (STATE line + CHOICES list) to the GridDemo window,
   without touching GridDemo’s ivars or buggy helpers.
 - Export helpers: ~hud_setState.(string), ~hud_setChoices.([lines]).
Style
 - var-first; AppClock-only for UI; no server.sync; idempotent; single MagicDisplayGUI window.
*/

(
var ensureGui, killOld, mkOverlay, frontHud;

ensureGui = {
    if(~gui.isNil) {
        Window.allWindows
        .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
        .do(_.close);
        ~gui = MagicDisplayGUI_GridDemo.new;
    };
    if(~gui.respondsTo(\window)) { ~gui.window.front.alwaysOnTop_(true) };
};

killOld = {
    var host;
    host = ~gui.tryPerform(\window).tryPerform(\view);
    if(host.notNil) {
        host.children.select({ |v| (v.tryPerform(\name) ? "") == "MDG_MINHUD" }).do(_.remove);
    };
    ~hud_setState = nil;
    ~hud_setChoices = nil;
};

mkOverlay = {
    var host, r, panel, title, stateBox, choicesBox, titleH, pad, width, height;

    host = ~gui.tryPerform(\window).tryPerform(\view);
    if(host.isNil) { "02H: host view is nil; aborting.".warn; ^nil };

    r = host.bounds;
    width = 360; height = 220; pad = 8; titleH = 18;

    panel = CompositeView(host).name_("MDG_MINHUD");
    panel.background = Color(0,0,0,0.30);
    panel.bounds = Rect(r.width - (width + 12), 12, width, height);

    title = StaticText(panel)
        .string_("MIN-HUD")
        .font_(Font("Monaco", 13))
        .stringColor_(Color(1,1,1,0.8))
        .bounds_(Rect(pad, pad, width - 2*pad, titleH));

    stateBox = TextView(panel)
        .string_("(state line)")
        .font_(Font("Monaco", 12))
        .background_(Color(0,0,0,0.10))
        .stringColor_(Color.white)
        .bounds_(Rect(pad, pad + titleH + 4, width - 2*pad, 22));

    choicesBox = TextView(panel)
        .string_("(choices)")
        .editable_(false)
        .font_(Font("Monaco", 11))
        .background_(Color(0,0,0,0.10))
        .stringColor_(Color(0.95,0.95,0.95))
        .bounds_(Rect(pad, pad + titleH + 4 + 22 + 6, width - 2*pad, height - (titleH + 4 + 22 + 6 + pad)));

    ~hud_setState = { arg textString;
        AppClock.sched(0.0, { stateBox.string = textString.asString; nil });
    };
    ~hud_setChoices = { arg linesArray;
        var s;
        s = (linesArray ? []).collect(_.asString).join("\n");
        AppClock.sched(0.0, { choicesBox.string = s; nil });
    };
};

frontHud = {
    if(~gui.respondsTo(\window)) { ~gui.window.front };
    (~hud_setState !? { ~hud_setState.("HUD ready (GridDemo overlay).") });
};

AppClock.sched(0.00, { ensureGui.value; killOld.value; mkOverlay.value; frontHud.value; nil });
)
