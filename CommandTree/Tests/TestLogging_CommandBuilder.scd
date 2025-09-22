TestLogging_CommandBuilder.scd
v0.1.0
MD 2025-09-22 09:52 BST

/*
Purpose
- See file comments for details.
Style
- var-first; lowercase methods; no server.sync; class extensions only.
*/


(
var jsonPath, tree, builder;

MDMiniLogger.get.setverbosity(3); // DEBUG

jsonPath = Platform.userExtensionDir ++ "/MDclasses/LivePedalboardSystem/MagicPedalboardCommandTree.json";
tree = MDCommandTree.new("root");
tree.importJSONFile(jsonPath);

builder = MDCommandBuilder.new(tree);
builder.printChildren;
builder.navigateByName(nil, "SomeChildName"); // INFO/WARN depending on your tree
builder.resetNavigation;
builder.printfretPath;
)
