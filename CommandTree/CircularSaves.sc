// circularSaves.sc
// v1.2.1
// MD 20250819

// This allows me to save the last ten trees in a folder, and keep track of the last one. Versions are named after date/time.


CircularFileSave {
    var <>prefix, <>folderPath, <>maxVersions, <fileList;

    *new { |prefix = "myTree", folderPath = "~/TreeSaves", maxVersions = 10|
        ^super.new.init(prefix, folderPath, maxVersions);
    }

    init { |prefix, folderPath, maxVersions|
        this.prefix = prefix;
        this.folderPath = folderPath.standardizePath;
        this.maxVersions = maxVersions;
        this.ensureFolderExists;
        this.refreshFileList;
    }

    ensureFolderExists {
        File.mkdir(folderPath);
    }

/*    refreshFileList {
        fileList = PathName(folderPath).entries.select { |f|
            f.fileName.beginsWith(prefix ++ "-") and: { f.fileName.endsWith(".json") }
        };
    }*/

	// 20250922
refreshFileList {
    var pn, entries;
    pn = PathName(folderPath.standardizePath);
    if (pn.isFolder.not) { File.mkdir(pn.fullPath) };

    entries = pn.entries
        .select(_.isFile)
        .select({ |p| p.fileName.beginsWith(prefix) and: { p.fileName.endsWith(".json") } });

    // robust boolean comparator; no key-function; no .at on PathName
    entries = entries.asArray.sort({ |a, b| a.fileName > b.fileName });

    fileList = entries; // keep PathName objects; callers can use .fullPath / .fileName
    ^this
}



    saveVersion { |content|
        var timestamp = Date.getDate.stamp;
        var filename = "%-%".format(prefix, timestamp) ++ ".json";
        var path = folderPath +/+ filename;

        File.use(path, "w", { |f| f.write(content) });

        fileList.addFirst(PathName(path));

        if(fileList.size > maxVersions) {
            var toDelete = fileList.copyRange(maxVersions, fileList.size - 1);
            toDelete.do(_.delete);
            fileList = fileList.copyRange(0, maxVersions - 1);
        };

        path.postln;
    }

    listVersions {
        fileList.collect(_.fileName).do(_.postln);
    }

    loadVersion { |index|
        var file, content;

        if(index >= fileList.size or: { index < 0 }) {
            "Invalid index: % (available: 0 to %)".format(index, fileList.size - 1).warn;
            ^nil;
        };

        file = fileList[index];
        if(file.isNil) {
            "No file found at index %".format(index).warn;
            ^nil;
        };

        File.use(file.fullPath, "r", { |f|
            content = f.readAllString;
        });
        ^content;
    }

    latestVersion {
        ^this.loadVersion(0);
    }
}

