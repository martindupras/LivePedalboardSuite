// GUI_QuickFix_Choices_Contrast.scd
// v0.1.0
// MD 2025-09-23 14:10 BST

/* Purpose
   Improve legibility of the "Choices" panel immediately (runtime).
   Style: var-first; AppClock-only; no server.sync.
*/

(
var displayRef, choicesPanelView, choicesTitleView, choicesTextView, canDo;

displayRef = ~system ? nil;
if(displayRef.isNil or: { ~system.statusDisplay.isNil }) {
  "⚠️ No status display found; bring-up first.".warn; ^nil;
};
displayRef = ~system.statusDisplay;

displayRef.queueUi({
  choicesPanelView = displayRef.tryPerform(\choicesPanel);
  choicesTitleView = displayRef.tryPerform(\choicesTitle);
  choicesTextView  = displayRef.tryPerform(\choicesText);

  if(choicesPanelView.notNil and: { choicesPanelView.respondsTo(\background_) }) {
    choicesPanelView.background_(Color(0.12, 0.12, 0.12));
  };
  if(choicesTitleView.notNil and: { choicesTitleView.respondsTo(\stringColor_) }) {
    choicesTitleView.stringColor_(Color(0.92, 0.92, 0.92));
  };
  if(choicesTextView.notNil and: { choicesTextView.respondsTo(\stringColor_) }) {
    choicesTextView.stringColor_(Color(0.92, 0.92, 0.92));
  };
  nil
});
)
