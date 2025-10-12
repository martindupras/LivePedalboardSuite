// NewPedalboard.sc
// v0.1.0
// MD 20251011-2148

/*
Purpose:
- Thin compat shim that forwards NewPedalboard.new(...) to NewPedalboardCandidateA.
- Keeps existing scripts working while we iterate on Candidate A.
*/

NewPedalboard : Object {

    *new { arg source = \internalGenerators;
        ^NewPedalboardCandidateA.new(source)
    }

}
