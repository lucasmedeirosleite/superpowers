# Personal skill routing: Task 1 evaluation

Date: 2026-09-28. Base: `52645a6`. All sessions were fresh and used isolated
empty `/tmp/personal-skill-routing-baseline-*` projects. OMP loaded this checkout
with `--plugin-dir`. Codex CLI used the installed personal skills in
`~/.agents/skills`; this Task 1 checkpoint did not switch Codex to the fork.
Prompts and expected behavior are in `tests/personal-skill-routing/scenarios.md`.

## Baseline, before editing the skill

| Scenario and harness | Actual excerpt | Verdict |
| --- | --- | --- |
| Explicit `design-tokens`, Codex CLI 0.155.0-alpha.16.3 | Command read `/home/lucasmedeiros/.agents/skills/design-tokens/SKILL.md`; final: “I used the design-tokens skill ... Once you approve or adjust that direction, I can draft ... tokens ... I wrote no files.” | Pass. Available skill read; gate held. |
| Explicit `design-tokens`, OMP 18.2.6 | “I will not invoke **design-tokens** or generate tokens yet. The sequence is: approve the design ... use **design-tokens** during implementation.” | **RED.** It deferred reading an explicitly requested available skill. Gate held. |
| Missing named skill, OMP | “`missing-personal-skill` is absent, so I can’t plan the API using your required workflow. I won’t substitute another skill.” | Pass. Unavailability reported. |
| Overlapping `create-prd` and `trd`, Codex CLI | Command read both `create-prd/SKILL.md` and `trd/SKILL.md`; first response: “I’ll use the create-prd and trd guidance to shape one integrated platform plan.” | Pass for skill reading and single response artifact. This did not exercise Superpowers' reviewed-spec gate because the fork was not loaded. |

The ordinary sandbox blocked fresh sessions: Codex reported `Operation not
permitted` for the model endpoint, and OMP could not write its runtime database.
The evaluations above were rerun through approved execution with read-only or
no-write prompts. An isolated OMP home lacked model credentials, so the normal
OMP profile was used with a temporary project.

## After the routing reference and bootstrap pointer

| Scenario and harness | Actual excerpt or trace | Verdict |
| --- | --- | --- |
| Explicit `design-tokens`, first OMP run | “**design-tokens** depends on an agreed visual direction, so token generation must wait.” No skill read was observed in this text-only run. | Still unresolved; bootstrap wording was tightened and the exact prompt rerun with JSON trace. |
| Explicit `design-tokens`, OMP retest | JSON trace includes `read {'path': 'skill://design-tokens'}`. Final: “**design-tokens** generation waits for an approved direction ... No files will be written.” | **GREEN** for immediate named-skill reading and approval gate. The trace did not show a separate read of the routing reference; this remains a coverage concern. |
| Missing named skill, OMP | “`missing-personal-skill` is unavailable in the isolated inventory ... I won’t substitute another skill or claim to have used it.” | Pass. |

The reference contains all nine phase rows, selection rules, and document/stage
boundaries. `node tests/pi/test-pi-extension.mjs` passed 6/6. `git diff --check`
exited 0. These structural checks do not establish behavior for every scenario.

## Coverage limits

The unavailable and unreadable temporary fixtures were specified but not fully
executed in both harnesses. The missing `skillui` command, missing
`ogt-docs-rules` subskill, automatically unavailable skill, user gate override,
and separate-artifact cases remain unrun behavioral scenarios at this checkpoint.
The OMP JSON retest showed a read of `using-superpowers` and `design-tokens`, but
not the routing reference itself. Later phase-checkpoint work should verify
that agents read the shared policy and follow its rules. No claim of full
cross-harness GREEN is made here.
