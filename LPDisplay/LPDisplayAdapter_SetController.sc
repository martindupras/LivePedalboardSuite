// LPDisplayAdapter_SetController.sc
// v0.1.0
// MD 20251004-1820

/* Purpose
- Provide a setter so we can assign the actual LPDisplayLayoutWindow instance to the adapter.
*/

+ LPDisplayAdapter {
    setController { |controllerRef|
        controller = controllerRef;
        ^this
    }
}