// LivePedalboardSystem-Pathing.sc
// v0.3.1
// MD 20250923-0959

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

  *resolveTreePath { arg maybePath;
    var candidateUserState, candidateRepoDefault, candidateMdLegacy, resolvedPath;

    // 0) explicit path (caller responsibility)
    resolvedPath = maybePath;
    if (resolvedPath.notNil) { ^resolvedPath };

    // 1) per-user override alongside the code (usually .gitignored)
    candidateUserState   = Platform.userExtensionDir
      ++ "/LivePedalboardSuite/LivePedalboardSystem/UserState/MagicPedalboardCommandTree.json";

    // 2) repo default (shipped in Git / symlinked into Extensions)
    candidateRepoDefault = Platform.userExtensionDir
      ++ "/LivePedalboardSuite/LivePedalboardSystem/MagicPedalboardCommandTree.json";

    // 3) legacy (deprecated) MDclasses location
    candidateMdLegacy    = Platform.userExtensionDir
      ++ "/MDclasses/LivePedalboardSystem/MagicPedalboardCommandTree.json";

    if (File.exists(candidateUserState))   { ^candidateUserState };
    if (File.exists(candidateRepoDefault)) { ^candidateRepoDefault };
    if (File.exists(candidateMdLegacy)) {
      MDMiniLogger.get.warn("Pathing",
        "[deprecated] Using MDclasses copy: " ++ candidateMdLegacy);
      ^candidateMdLegacy
    };

    // Last resort: return repoDefault even if missing; importer will warn gracefully.
    ^candidateRepoDefault;
  }

}
