TestLogging_CommandTree.scd
v0.1.0
MD 2025-09-22 09:52 BST

/*
Purpose
- See file comments for details.
Style
- var-first; lowercase methods; no server.sync; class extensions only.
*/


(
var jsonPath, tree, ok;

MDMiniLogger.get.setverbosity(3); // DEBUG for this test

jsonPath = Platform.userExtensionDir ++ "/MDclasses/LivePedalboardSystem/MagicPedalboardCommandTree.json";
tree = MDCommandTree.new("root");

ok = tree.importJSONFile(jsonPath);
tree.printTreePretty;
tree.assignPayloads;
tree.validateTree;
tree.exportJSONFile(jsonPath ++ ".tmp");
tree.listSavedVersions;
)
