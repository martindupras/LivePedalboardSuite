// MDCommandBuilder_Compat_Ext.sc
// v0.1.0
// MD 20250924-1048

/*
Purpose
- Keep older .scd tests running unchanged by mapping legacy selector names to current API.
Style
- class extension; var-first; lowercase; no server.sync.
*/

+ MDCommandBuilder {

  // Old: listChildren -> New: printChildren (returns names)
  listChildren {
    ^this.printChildren
  }

  // Old: navigateToChild(fret) OR navigateToChild(string, fret)
  navigateToChild { arg legacyArgA, legacyArgB = nil;
    var stringLevel, fretNumber;

    if (legacyArgB.isNil) {
      stringLevel = nil;
      fretNumber  = legacyArgA;
    } {
      stringLevel = legacyArgA;
      fretNumber  = legacyArgB;
    };

    ^this.navigateByFret(stringLevel, fretNumber)
  }

  // Old: printCurrentPath -> New: printPathToRoot
  printCurrentPath {
    ^this.printPathToRoot
  }

  // Old: getCurrentCommand -> New: getCurrentPayload
  getCurrentCommand {
    ^this.getCurrentPayload
  }

  // Old: reset -> New: resetNavigation
  reset {
    ^this.resetNavigation
  }

}
