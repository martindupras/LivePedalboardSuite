// 02H_GridDemo_MinHUD_Overlay.scd
// v0.1.2
// MD 2025-09-29 13:28 BST

/* Purpose
 - Add a compact overlay HUD (STATE line + CHOICES list) to the GridDemo window,
   without touching GridDemo’s private ivars or its buggy helpers.
 - Export helpers: ~hud_setState.(string), ~hud_setChoices.([lines]),
   and ~hud_moveTopRight.(marginInt) to re-anchor after resize.
Style
 - var-first; AppClock-only for UI; no server.sync; idempotent; single MagicDisplayGUI window.
*/

(
var ensureGui, killOld, mkOverlay, positionTopRight, hookResize, frontHud;

/* Ensure a single MagicDisplayGUI window and that ~gui is the GridDemo controller */
ensureGui = {
    if(~gui.isNil) {
        Window.allWindows
        .select({ |w| (w.tryPerform(\name) ? "").asString.beginsWith("MagicDisplayGUI") })
        .do(_.close);
        ~gui = MagicDisplayGUI_GridDemo.new;
    };
    if(~gui.respondsTo(\window)) { ~gui.window.front.alwaysOnTop_(true) };
};

/* Remove any previous overlay if re-running */
killOld = {
    var host;
    host = ~gui.tryPerform(\window).tryPerform(\view);
    if(host.notNil) {
        host.children.select({ |v| (v.tryPerform(\name) ? "") == "MDG_MINHUD" }).do(_.remove);
    };
    ~hud_setState = nil;
    ~hud_setChoices = nil;
    ~hud_moveTopRight = nil;
};

/* Create overlay at top-right (compact; draws above other widgets) */
mkOverlay = {
    var host, r, panel, title, stateBox, choicesBox;
    var pad, width, height, titleH, stateH;

    host = ~gui.tryPerform(\window).tryPerform(\view);
    if(host.isNil) { "02H: host view is nil; aborting.".warn; ^nil };

    r = host.bounds;
    width = 320;          // narrower to avoid covering A/B headers
    height = 170;         // shorter; room for 5–7 lines
    pad = 8;
    titleH = 16;
    stateH = 18;

    panel = CompositeView(host).name_("MDG_MINHUD");
    panel.background = Color(0,0,0,0.28);         // translucent dark
    panel.decorator = FlowLayout(panel.bounds, 0@0, 0@0); // keeps children stable
    panel.bounds = Rect(r.width - (width + 12), 10, width, height);
    panel.border = 1;
    panel.borderColor = Color(1,1,1,0.25);
    panel.front; // ensure on top
    title = StaticText(panel)
        .string_("MIN-HUD")
        .font_(Font("Monaco", 12))
        .stringColor_(Color(1,1,1,0.82))
        .bounds_(Rect(pad, pad, width - 2*pad, titleH));

    stateBox = TextView(panel)
        .string_("(state)")
        .font_(Font("Monaco", 11))
        .background_(Color(0,0,0,0.10))
        .stringColor_(Color.white)
        .bounds_(Rect(pad, pad + titleH + 4, width - 2*pad, stateH));

    choicesBox = TextView(panel)
        .string_("(choices)")
        .editable_(false)
        .font_(Font("Monaco", 10))
        .background_(Color(0,0,0,0.10))
        .stringColor_(Color(0.93,0.93,0.93))
        .bounds_(Rect(
            pad,
            pad + titleH + 4 + stateH + 6,
            width - 2*pad,
            height - (titleH + 4 + stateH + 6 + pad)
        ));

    // Export helpers:
    ~hud_setState = { arg textString;
        AppClock.sched(0.0, { stateBox.string = textString.asString; nil });
    };
    ~hud_setChoices = { arg linesArray;
        var s;
        s = (linesArray ? []).collect(_.asString).join("\n");
        AppClock.sched(0.0, { choicesBox.string = s; nil });
    };

    positionTopRight = { arg margin = 10;
        var rb = host.bounds;
        AppClock.sched(0.0, {
            panel.bounds = Rect(rb.width - (width + margin), margin, width, height);
            panel.front;
            nil
        });
    };
    ~hud_moveTopRight = positionTopRight;
    positionTopRight.value(10);
};

/* Re-anchor overlay on window resize */
hookResize = {
    var win;
    win = ~gui.tryPerform(\window);
    if(win.notNil) {
        win.onResize = {
            (~hud_moveTopRight !? { ~hud_moveTopRight.(10) });
        };
    };
};

/* Bring to front and seed banner */
frontHud = {
    if(~gui.respondsTo(\window)) { ~gui.window.front };
    (~hud_setState !? { ~hud_setState.("HUD ready (GridDemo overlay)") });
};

AppClock.sched(0.00, { ensureGui.value; killOld.value; mkOverlay.value; hookResize.value; frontHud.value; nil });
)
