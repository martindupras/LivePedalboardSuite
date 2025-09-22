// CircularFileSave_SortByMTime.sc
// v1.1 — 2025-09-21 MD

// Purpose
// - Ensure latestVersion() is truly latest by sorting entries (mtime desc).
// Style
// - var-first; lowercase; no server.sync.

+ CircularFileSave {
    refreshFileList {
        var pn, entries;
        pn = PathName(folderPath);
        entries = pn.entries.select { |f|
            f.fileName.beginsWith(prefix ++ "-") and: { f.fileName.endsWith(".json") }
        };
        // sort newest → oldest by modification time
        fileList = entries.sortBy({ |f| File.mtime(f.fullPath) }).reverse;
    }

    saveVersion { |content|
        var timestamp, filename, path;
        timestamp = Date.getDate.stamp;
        filename = "%-%".format(prefix, timestamp) ++ ".json";
        path = folderPath +/+ filename;
        File.use(path, "w", { |fh| fh.write(content) });
        this.refreshFileList; // recompute then prune
        if(fileList.size > maxVersions) {
            fileList.copyRange(maxVersions, fileList.size - 1).do(_.delete);
            fileList = fileList.copyRange(0, maxVersions - 1);
        };
        path.postln;
    }
}
