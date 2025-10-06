// Window_FlipY_Guard_Ext.sc
// v0.1.0
// MD 2025-09-26 13:40 BST

/* Purpose
   Temporary dev guard: if any code calls Window.flipY(nil),
   default to Window.screenBounds instead of crashing on .top of nil.
*/

+ Window {
    *flipY { arg rectIn;
        var screenRect, srcRect, left, top, width, height, flippedTop;
        screenRect = Window.screenBounds;
        srcRect    = rectIn ? screenRect;  // safe default
        left   = srcRect.left;
        top    = srcRect.top;
        width  = srcRect.width;
        height = srcRect.height;
        flippedTop = (screenRect.top + screenRect.height) - (top + height);
        ^Rect(left, flippedTop, width, height)
    }
}
