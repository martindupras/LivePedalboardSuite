// LivePedalboardSystem-Pathing.sc
// v0.3.0
// MD 2025-09-22 10:44 BST

/*
Purpose
- Make LivePedalboardSystem default to a JSON tree INSIDE the repo so a fresh clone runs.
- Allow optional, per-user overrides in Extensions/MDclasses or UserState.
- Preserve explicit constructor path as the highest priority.

Style
- var-first; lowercase method names; no server.sync.
- Class extension only; pure path logic here.
*/

+ LivePedalboardSystem {

    // 1) Repo default (shipped in Git)
    *defaultTreePath {
        ^Platform.userExtensionDir
        ++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";
    }

    // 2) Optional per-user override in MDclasses (not in Git)
    *userOverrideMDclasses {
        ^Platform.userExtensionDir
        ++ "/MDclasses/LivePedalboardSystem/MagicPedalboardCommandTree.json";
    }

    // 3) Optional per-user override alongside the code (normally .gitignored)
    *userOverrideUserState {
        ^Platform.userExtensionDir
        ++ "/LivePedalboardSuite/LivePedalboardSystem/UserState/MagicPedalboardCommandTree.json";
    }

    // Resolution: explicit → MDclasses → UserState → repo default
    *resolveTreePath { |maybePath|
        var p, mdOverride, usOverride, repoDefault;

        p = maybePath;
        if (p.notNil) { ^p }; // caller took responsibility

        mdOverride   = this.userOverrideMDclasses;
        usOverride   = this.userOverrideUserState;
        repoDefault  = this.defaultTreePath;

        if (File.exists(mdOverride)) { ^mdOverride };
        if (File.exists(usOverride)) { ^usOverride };
        if (File.exists(repoDefault)) { ^repoDefault };

        // Nothing found → helpful message
        ("[LPS] No CommandTree JSON found.\n"
        ++ "Tried:\n  1) " ++ mdOverride
        ++ "\n  2) " ++ usOverride
        ++ "\n  3) " ++ repoDefault
        ++ "\nCreate one of these files or pass a path to LivePedalboardSystem.new(path)."
        ).warn;

        ^repoDefault  // return something to avoid nil crashes; caller can handle missing file
    }

    // Ensure the constructor honours the resolver
    *new { |maybePath|
        ^super.newCopyArgs(
            this.resolveTreePath(maybePath)
        ).init;
    }
}
