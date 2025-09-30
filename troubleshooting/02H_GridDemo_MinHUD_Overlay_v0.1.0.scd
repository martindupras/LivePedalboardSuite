// 02H_GridDemo_MinHUD_Overlay.scd
// v0.1.0
// MD 20250929-1310

/* Purpose
   - Add a small overlay HUD panel (STATE + CHOICES) on top of GridDemo,
     without using GridDemo's internal ivars/methods (which are erroring in your build).
   - Export two helpers: ~hud_setState.(textString), ~hud_setChoices.([lines]).
Style
   - var-first; AppClock-only for UI; no server.sync; idempotent; single MagicDisplayGUI window.
*/

(
var ensureGui, killOld, mkOverlay, frontHud;

// 1) Ensure a single MagicDisplayGUI window and that ~gui is the GridDemo controller
ensureGui = {
    if(~gui.isNil) {
        Window.allWindows
        .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
        .do(_.close);
        ~gui = MagicDisplayGUI_GridDemo.new;
    };
    if(~gui.respondsTo(\window)) { ~gui.window.front.alwaysOnTop_(true) };
};

// 2) Remove any previous overlay if re-running
killOld = {
    var host = ~gui.tryPerform(\window).tryPerform(\view);
    if(host.notNil) {
        host.children.select({ |v| (v.tryPerform(\name) ? "") == "MDG_MINHUD" }).do(_.remove);
    };
    ~hud_setState = nil;
    ~hud_setChoices = nil;
};

// 3) Create a small overlay panel at top-right
mkOverlay = {
    var host, r, panel, title, stateBox, choicesBox, titleH, pad, width, height;
    host = ~gui.tryPerform(\window).tryPerform(\view);
    if(host.isNil) { "02H: host view is nil; aborting.".warn; ^nil };

    r = host.bounds; // Rect
    width  = 360; height = 220; pad = 8; titleH = 18;

    panel = CompositeView(host).name_("MDG_MINHUD");
    panel.background = Color(0,0,0,0.30); // transparent dark
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

    // 3a) Export helpers
    ~hud_setState = { arg textString;
        AppClock.sched(0.0, { stateBox.string = textString.asString; nil });
    };
    ~hud_setChoices = { arg linesArray;
        var s = (linesArray ? []).collect(_.asString).join("\n");
        AppClock.sched(0.0, { choicesBox.string = s; nil });
    };
};

// 4) Front and banner
frontHud = {
    if(~gui.respondsTo(\window)) { ~gui.window.front };
    (~hud_setState !? { ~hud_setState.("HUD ready (GridDemo overlay).") });
};

AppClock.sched(0.00, { ensureGui.value; killOld.value; mkOverlay.value; frontHud.value; nil });
)
