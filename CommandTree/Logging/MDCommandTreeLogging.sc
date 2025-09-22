MDCommandTreeLogging
v1.0.0
MD 2025-09-22 09:52 BST

/*
Purpose
- See file comments for details.
Style
- var-first; lowercase methods; no server.sync; class extensions only.
*/


+ MDCommandTree {

    printTreePretty {
        this.mdlog(3, "CommandTree", "pretty-print follows…");
        root.printTreePretty;
        ^this
    }

    findNodeByName { |name|
        var found;
        found = nodeMap.values.detect { |node| node.name == name };
        if(found.notNil) {
            this.mdlog(2, "CommandTree", "🔎 found '" ++ found.name ++ "' (id " ++ found.id ++ ")");
            ^found
        }{
            this.mdlog(1, "CommandTree", "⚠ node not found: " ++ name);
            ^nil
        }
    }

    getNodeByNamePath { |nameList|
        var found = root.getNodeByNamePath(nameList);
        if(found.notNil) { ^found }{
            this.mdlog(1, "CommandTree", "⚠ path not found: " ++ nameList.join(" → "));
            ^nil
        }
    }

    exportJSONFile { |path|
        var jsonString, file;
        jsonString = JSONlib.convertToJSON(root.asDictRecursively);
        file = File(path, "w");
        if(file.isOpen) {
            file.write(jsonString);
            file.close;
            this.mdlog(2, "CommandTree", "📤 exported to " ++ path);
        }{
            this.mdlog(1, "CommandTree", "⚠ failed to open for write: " ++ path);
        };
        ^this
    }

    importJSONFile { |path|
        var jsonString, dict, newTree;
        if(File.exists(path).not) {
            this.mdlog(0, "CommandTree", "❌ file does not exist: " ++ path);
            ^false;
        };
        jsonString = File(path, "r").readAllString;
        if(jsonString.isNil or: { jsonString.isEmpty }) {
            this.mdlog(1, "CommandTree", "⚠ file is empty/unreadable: " ++ path);
            ^false;
        };
        dict = JSONlib.convertToSC(jsonString);
        if(dict.isNil) {
            this.mdlog(0, "CommandTree", "❌ failed to parse JSON: " ++ path);
            ^false;
        };
        newTree = MDCommandTree.fromDict(dict);
        this.root = newTree.root;
        this.nodeMap = newTree.nodeMap;
        this.nodeCount = newTree.nodeCount;
        this.mdlog(2, "CommandTree", "📥 imported from " ++ path);
        ^true
    }

    saveVersioned {
        var json = JSONlib.convertToJSON(root.asDictRecursively);
        saver.saveVersion(json);
        this.mdlog(2, "CommandTree", "💾 versioned save complete");
        ^this
    }

    loadLatestVersion {
        var json, dict, newTree;
        json = saver.latestVersion;
        if(json.isNil or: { json.isEmpty }) {
            this.mdlog(1, "CommandTree", "⚠ no saved version found");
            ^false;
        };
        dict = JSONlib.convertToSC(json);
        if(dict.isNil) {
            this.mdlog(0, "CommandTree", "❌ failed to parse saved JSON");
            ^false;
        };
        newTree = MDCommandTree.fromDict(dict);
        this.root = newTree.root;
        this.nodeMap = newTree.nodeMap;
        this.nodeCount = newTree.nodeCount;
        this.mdlog(2, "CommandTree", "📥 loaded latest version");
        ^true
    }

    listSavedVersions {
        this.mdlog(2, "CommandTree", "🗂 listing saved versions…");
        saver.listVersions; // CircularFileSave may still post; optional: move it to logger later
        ^this
    }

    validateTree {
        var seen = Set.new, valid = true;
        nodeMap.values.do { |node|
            if(seen.includes(node.name)) {
                this.mdlog(1, "CommandTree", "⚠ duplicate node name: " ++ node.name);
                valid = false;
            };
            seen.add(node.name);
        };
        this.mdlog(valid.if(2,0), "CommandTree", valid.if("✅ validation passed", "❌ validation failed"));
        ^valid
    }

    assignPayloads {
        var assignRecursively;
        assignRecursively = { |node|
            node.payload = node.name;
            node.children.do { |child| assignRecursively.(child) };
        };
        assignRecursively.(this.root);
        this.mdlog(2, "CommandTree", "🧠 payloads assigned");
        ^this
    }

    printPayloads {
        var printRecursively;
        printRecursively = { |node, level = 0|
            var indent = " " ! level;
            this.mdlog(3, "CommandTree", indent.join ++ node.name ++ " → payload: " ++ node.payload);
            node.children.do { |child| printRecursively.(child, level + 1) };
        };
        printRecursively.(this.root);
        ^this
    }
}
