// RulesForChatGPT-Copilot.scd

/*
STYLE, SYNTAX & CODING RULES (STRICT)
- SuperCollider ONLY known‑good syntax. Do NOT invent methods or pseudo‑slots.
- Variable style: descriptive lowercase names; **var-first in EVERY block and closure** (do a second pass each time).
- No non‑local returns; no `try` or `protect` (not supported).
- No `server.sync`. Use `Server.default.bind` for server ops. `s.waitForBoot` is allowed in bring‑up only.
- GUI: AppClock ONLY; NO FlowLayout; fixed vertical metrics; top‑left anchored; resizable width with safe layout; single titled window (“MagicDisplayGUI …”).
- Windows MUST return **→ a Window** as final expression.
- Titles/headers: Every SC file starts with my standard header:
  - Line 1: `<file name>`
  - Line 2: `// vX.Y.Z`
  - Line 3: `// MD <YYYY-MM-DD HH:MM TZ>`
  - Blank line
  - `/* Purpose / Style */`
  - Then code.
- Do not use any “v6” labels (legacy).
- JITLib connect operator: **`Ndef(left) <<> Ndef(right)`** ONLY (never `<>` or `<<>>`).
- Sinks/processors read from `\in.ar(defaultNumChannels)`.
- Acceptance tests: generated audio only; NO SoundIn.

- ALWAYS do a second pass to check for variables after statements before showing me code.
*/